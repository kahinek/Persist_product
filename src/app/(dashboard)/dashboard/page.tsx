export default function DashboardPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
      <p className="mt-2 text-sm text-gray-600">
        Welcome to Persist. Get started by setting up your organization.
      </p>

      <div className="mt-8 grid grid-cols-1 gap-6 md:grid-cols-3">
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h3 className="text-sm font-medium text-gray-500">Step 1</h3>
          <p className="mt-1 text-lg font-semibold text-gray-900">
            Upload your org structure
          </p>
          <p className="mt-2 text-sm text-gray-600">
            Go to Settings &rarr; Organization to upload a CSV of your team.
          </p>
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h3 className="text-sm font-medium text-gray-500">Step 2</h3>
          <p className="mt-1 text-lg font-semibold text-gray-900">
            Connect Slack
          </p>
          <p className="mt-2 text-sm text-gray-600">
            Go to Settings &rarr; Slack to connect your workspace.
          </p>
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h3 className="text-sm font-medium text-gray-500">Step 3</h3>
          <p className="mt-1 text-lg font-semibold text-gray-900">
            Send your first survey
          </p>
          <p className="mt-2 text-sm text-gray-600">
            Go to Surveys to send the AI Impact Assessment.
          </p>
        </div>
      </div>
    </div>
  );
}
