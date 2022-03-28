require_relative "test_helper"

require "migration_sle/main_workflow"

describe MigrationSle::MainWorkflow do
  let(:base_product) do
    {
      "name"             => "Leap",
      "version_version"  => "15.3",
      "version"          => "15.3-2",
      "arch"             => "x86_64",
      "display_name"     => "openSUSE Leap 15.3",
      "register_target"  => "",
      "register_release" => "",
      "product_line"     => "Leap",
      "flavor"           => "dvd"
    }
  end

  describe "#run" do
    before do
      allow(Yast::Wizard).to receive(:CreateDialog)
      allow(Yast::Wizard).to receive(:CloseDialog)
      allow(subject).to receive(:vendor_cleanup)
    end

    context "running in openSUSE Tumbleweed" do
      before do
        expect(Yast::OSRelease).to receive(:id).and_return("opensuse-tumbleweed")
        allow(Yast::Report).to receive(:Error)
      end

      it "displays an error message" do
        expect(Yast::Report).to receive(:Error)\
          .with(/migration.*is supported only from the openSUSE Leap/mi)

        subject.run
      end

      it "returns :abort" do
        expect(subject.run).to eq(:abort)
      end
    end

    context "running in openSUSE Leap" do
      before do
        expect(Yast::OSRelease).to receive(:id).and_return("opensuse-leap")
        allow(Yast::Report).to receive(:Error)
        allow(Registration::SwMgmt).to receive(:init)
        allow(Registration::SwMgmt).to receive(:find_base_product).and_return(base_product)
        allow(Migration::Restarter.instance).to receive(:restarted).and_return(false)
      end

      context "base product is not found" do
        before do
          expect(Registration::SwMgmt).to receive(:find_base_product).and_return(nil)
          allow(Registration::Helpers).to receive(:report_no_base_product)
        end

        it "displays an error message" do
          expect(Registration::Helpers).to receive(:report_no_base_product)
          subject.run
        end

        it "returns :abort" do
          expect(subject.run).to eq(:abort)
        end
      end

      # TODO: test the real migration case
    end
  end
end
