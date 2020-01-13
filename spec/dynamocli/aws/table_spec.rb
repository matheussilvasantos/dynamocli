require "dynamocli/aws/table"

RSpec.describe Dynamocli::AWS::Table do
  let(:table_on_aws) { instance_double("Aws::DynamoDB::Table").as_null_object }
  let(:dynamodb) { instance_double("Aws::DynamoDB::Client").as_null_object }

  subject do
    described_class.new(
      table_name: "users",
      table_on_aws: table_on_aws,
      dynamodb: dynamodb
    )
  end

  describe "#deleting?" do
    context "when table is being deleted" do
      before do
        allow(dynamodb).to receive(:describe_table).and_return(DescribeTableResponse.new(deleted: false))
      end

      it "returns true" do
        expect(subject.deleting?).to be_truthy
      end
    end

    context "when table was deleted" do
      before do
        allow(dynamodb).to receive(:describe_table).and_return(DescribeTableResponse.new(deleted: true))
      end

      it "returns false" do
        expect(subject.deleting?).to be_falsy
      end
    end
  end

  class DescribeTableResponse
    def initialize(deleted:)
      @deleted = deleted
    end

    def table
      raise Aws::DynamoDB::Errors::ResourceNotFoundException.new(nil, nil) if deleted?

      Struct.new(:table_status).new("DELETING")
    end

    def to_h
      { table: {} }
    end

    private

    def deleted?
      @deleted
    end
  end
end
