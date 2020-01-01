require "dynamocli/table/cloudformation_table"

RSpec.describe Dynamocli::Table::CloudformationTable do
  let(:cloudformation) { instance_double(described_class::CLOUDFORMARTION) }
  let(:logger) { instance_double(described_class::LOGGER) }

  describe "#erase" do
    context "when CloudFormation library raises an Aws::CloudFormation::Errors::ValidationError exception" do
      subject do
        described_class.new(
          table_name: "users",
          table_resource: double("AWS::DynamoDB::Table"),
          cloudformation: cloudformation,
          logger: logger
        )
      end

      before do
        allow(cloudformation).to receive(:describe_stacks).and_raise(Aws::CloudFormation::Errors::ValidationError.new("foo", "bar"))
      end

      it "logs the error" do
        allow(subject).to receive(:exit)

        expect(logger).to receive(:error)
        subject.erase
      end

      it "exists with an error code greater than 0" do
        allow(logger).to receive(:error).with(String)
        expect { subject.erase }.to raise_exception(SystemExit)
      end
    end
  end
end
