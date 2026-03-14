-- Phase 1: Foundation tables
-- organizations, users (profile mirror), organization_members

-- 1. Organizations table
CREATE TABLE public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  slack_team_id text UNIQUE,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- 2. Users profile table (mirrors auth.users)
CREATE TABLE public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- 3. Organization members (admin <-> org join table)
CREATE TABLE public.organization_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'admin' CHECK (role IN ('owner', 'admin')),
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(org_id, user_id)
);

-- Index for looking up user's orgs
CREATE INDEX idx_org_members_user ON public.organization_members(user_id);
CREATE INDEX idx_org_members_org ON public.organization_members(org_id);

-- 4. Trigger: auto-create user profile on auth signup
-- NOTE: This trigger on auth.users requires running via Supabase Dashboard SQL Editor
-- which executes as the postgres (superuser) role.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. RLS helper function (in public schema, not auth)
CREATE OR REPLACE FUNCTION public.user_org_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT org_id
  FROM public.organization_members
  WHERE user_id = (SELECT auth.uid())
$$;

-- 6. Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies: organizations
CREATE POLICY "org_member_select" ON public.organizations
  FOR SELECT USING (id IN (SELECT public.user_org_ids()));

CREATE POLICY "org_member_update" ON public.organizations
  FOR UPDATE USING (id IN (SELECT public.user_org_ids()));

CREATE POLICY "authenticated_insert" ON public.organizations
  FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

-- 8. RLS Policies: users
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (id = (SELECT auth.uid()));

CREATE POLICY "users_select_org_members" ON public.users
  FOR SELECT USING (
    id IN (
      SELECT user_id FROM public.organization_members
      WHERE org_id IN (SELECT public.user_org_ids())
    )
  );

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (id = (SELECT auth.uid()));

-- 9. RLS Policies: organization_members
CREATE POLICY "org_members_select" ON public.organization_members
  FOR SELECT USING (org_id IN (SELECT public.user_org_ids()));

CREATE POLICY "org_members_insert" ON public.organization_members
  FOR INSERT WITH CHECK (
    -- Allow if user is inserting themselves as owner (org creation)
    (user_id = (SELECT auth.uid()) AND role = 'owner')
    OR
    -- Allow if user is already a member of the org (inviting others)
    (org_id IN (SELECT public.user_org_ids()))
  );

CREATE POLICY "org_members_delete" ON public.organization_members
  FOR DELETE USING (
    org_id IN (
      SELECT org_id FROM public.organization_members
      WHERE user_id = (SELECT auth.uid()) AND role = 'owner'
    )
  );
