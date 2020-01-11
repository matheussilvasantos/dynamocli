require "dynamocli/table/cloudformation_table"

RSpec.describe Dynamocli::Table::CloudformationTable do
  let(:stack) { double("Dynamocli::AWS::Stack").as_null_object }
  let(:cloudformation) { instance_double("Aws::CloudFormation::Client").as_null_object }
  let(:logger) { instance_double("TTY::Logger").as_null_object }

  subject do
    described_class.new(
      table_name: "users",
      stack: stack,
      cloudformation: cloudformation,
      logger: logger
    )
  end

  describe "#erase" do
    context "when deploying the stack without the table" do
      let(:template_without_table) { "Pretend I am the template without the table." }

      before do
        allow(stack).to receive(:current_status).and_return(described_class::DEPLOY_COMPLETED_KEY)
        allow(stack).to receive(:template_without_table).and_return(template_without_table)
      end

      it "calls the update_stack method in the cloudformation library with the template without the table" do
        expect(cloudformation).to receive(:update_stack).with(hash_including(template_body: template_without_table.to_json))
        subject.erase
      end
    end

    context "when deploying the stack again with the table" do
      let(:original_template) { "Pretend I am the original template." }

      before do
        allow(subject).to receive(:sleep)
        allow(stack).to receive(:current_status).and_return("foobar", described_class::DEPLOY_COMPLETED_KEY)
        allow(stack).to receive(:original_template).and_return(original_template)
      end

      it "waits the first deployment to finish before calling update_stack method in the cloudformation library" do
        expect(subject).to receive(:sleep)
        subject.erase
      end

      it "calls the update_stack method in the cloudformation library with the original template" do
        expect(cloudformation).to receive(:update_stack).with(hash_including(template_body: original_template.to_json))
        subject.erase
      end
    end
  end
end
