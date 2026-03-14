import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Sidebar } from "@/components/layout/sidebar";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  // Get user's org
  const { data: membership } = await supabase
    .from("organization_members")
    .select("org_id, role, organizations(id, name, slug)")
    .eq("user_id", user.id)
    .single();

  if (!membership) {
    redirect("/signup");
  }

  const org = membership.organizations as unknown as {
    id: string;
    name: string;
    slug: string;
  };

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar
        orgName={org.name}
        userName={user.user_metadata?.full_name || user.email || "User"}
      />
      <main className="flex-1 overflow-auto p-8">{children}</main>
    </div>
  );
}
