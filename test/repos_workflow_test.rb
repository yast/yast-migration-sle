require_relative "test_helper"

require "migration_sle/repos_workflow"

describe MigrationSle::ReposWorkflow do

  describe "#select_migration_products" do
    before do
      # avoid SLP network scan
      # note: the scan is done in the constructor, make sure it is mocked
      # *before* calling "subject"
      allow(Registration::UrlHelpers).to receive(:registration_url)

      allow(Yast::OSRelease).to receive(:ReleaseVersion).and_return("15.4")
      allow(subject).to receive(:migrations).and_return(migrations)
    end

    context "only one SLE migration available" do
      let(:migrations) do
        [
          [OpenStruct.new(identifier: "SLES", version: "15.4", arch: "x86_64",
            friendly_name: "SUSE Linux Enterprise Server 15 SP4 x86_64",
            available: true, shortname: "SLES15-SP4")]
        ]
      end

      it "selects the SLE migration automatically" do
        subject.send(:select_migration_products)
        expect(subject.send(:selected_migration)).to eq(migrations.first)
      end

      it "returns :next" do
        expect(subject.send(:select_migration_products)).to eq(:next)
      end
    end

    context "multiple SLE migrations available" do
      let(:migrations) do
        [
          [OpenStruct.new(identifier: "SLES", version: "15.4", arch: "x86_64",
            friendly_name: "SUSE Linux Enterprise Server 15 SP4 x86_64",
            available: true, shortname: "SLES15-SP4")],
          [OpenStruct.new(identifier: "SLED", version: "15.4", arch: "x86_64",
            friendly_name: "SUSE Linux Enterprise Desktop 15 SP4 x86_64",
            available: true, shortname: "SLED15-SP4")]
        ]
      end

      it "displays the selection dialog" do
        expect_any_instance_of(Registration::UI::MigrationSelectionDialog).to receive(:run) \
          .and_return(:abort)
        subject.send(:select_migration_products)
      end
    end

    context "no SLE migration available" do
      let(:migrations) { [] }

      it "displays an error message" do
        expect(Yast::Report).to receive(:Error)
        subject.send(:select_migration_products)
      end

      it "returns :abort" do
        allow(Yast::Report).to receive(:Error)
        expect(subject.send(:select_migration_products)).to eq(:abort)
      end
    end
  end
end
