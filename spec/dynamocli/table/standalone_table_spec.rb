require "dynamocli/table/standalone_table"

RSpec.describe Dynamocli::Table::StandaloneTable do
  let(:table) { instance_double("Dynamocli::AWS::Table").as_null_object }
  let(:dynamodb) { instance_double("Aws::DynamoDB::Client").as_null_object }
  let(:logger) { instance_double("TTY::Logger").as_null_object }

  subject do
    described_class.new(
      table_name: "users",
      table: table,
      dynamodb: dynamodb,
      logger: logger
    )
  end

  describe "#erase" do
    context "when deleting the table" do
      before do
        allow(table).to receive(:deleting?).and_return(false)
      end

      it "calls the delete method on the table" do
        expect(table).to receive(:delete)
        subject.erase
      end
    end

    context "when creating the table" do
      let(:schema) { "Pretend I am the schema." }

      before do
        allow(subject).to receive(:sleep)
        allow(table).to receive(:deleting?).and_return(true, false)
        allow(table).to receive(:schema).and_return(schema)
      end

      it "waits the table to be deleted before creating it again" do
        expect(subject).to receive(:sleep)
        subject.erase
      end

      it "calls the create_table method in the DynamoDB library passing the schema" do
        expect(dynamodb).to receive(:create_table).with(schema)
        subject.erase
      end
    end
  end

  describe "#alert_message_before_continue" do
    it "returns a message as a String" do
      expect(subject.alert_message_before_continue).to be_a(String)
    end
  end
end
