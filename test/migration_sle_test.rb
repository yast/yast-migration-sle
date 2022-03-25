require_relative "test_helper"
require "migration_sle/main_workflow"

describe "migration_sle client" do
  it "runs the main migration workflow" do
    expect(MigrationSle::MainWorkflow).to receive(:run)
    load File.expand_path("../src/clients/migration_sle.rb", __dir__)
  end
end
