require_relative "../test_helper"
require "cwm/rspec"
require "migration_sle/dialogs/registration"

describe MigrationSle::Dialogs::Registration do
  include_examples "CWM::Dialog"

  describe "#help" do
    it "returns a text" do
      expect(subject.help).to be_a(String)
    end
  end

  describe "#contents" do
    context "the system is not registered" do
      before do
        allow(Registration::Registration).to receive(:is_registered?).and_return(false)
      end

      it "displays the registration fields" do
        term = subject.contents.nested_find do |t|
          t.respond_to?(:value) && t.value == :id && t.params.first == :email
        end

        expect(term).to_not be_nil
      end
    end
  end

  context "the system is registered" do
    before do
      allow(Registration::Registration).to receive(:is_registered?).and_return(true)
    end

    it "does not display the registration fields" do
      term = subject.contents.nested_find do |t|
        t.respond_to?(:value) && t.value == :id && t.params.first == :email
      end

      expect(term).to be_nil
    end
  end

  describe "#run" do
    let(:email) { "email@example.com" }
    let(:reg_code) { "MY-REGISTRATION-CODE " }
    before do
      allow(subject).to receive(:cwm_show).and_return(:next)
    end

    it "stores the entered email and registration code" do
      expect(Yast::UI).to receive(:QueryWidget).with(Yast::Term.new(:id, :email),
        :Value).and_return(email)
      expect(Yast::UI).to receive(:QueryWidget).with(Yast::Term.new(:id, :reg_code),
        :Value).and_return(reg_code)

      subject.run

      expect(subject.email).to eq(email)
      expect(subject.reg_code).to eq(reg_code)
    end
  end
end
