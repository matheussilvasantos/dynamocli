# frozen_string_literal: true

require "forwardable"
require "aws-sdk-dynamodb"

module Dynamocli::AWS
  class Table
    attr_reader :schema

    extend Forwardable
    def_delegators :table_on_aws, :delete

    def initialize(table_name:, table_on_aws:, dynamodb: nil)
      @table_name = table_name
      @table_on_aws = table_on_aws
      @dynamodb = dynamodb || DYNAMODB.new

      set_schema_before_we_delete_the_table
    end

    def deleting?
      status == DELETION_IN_PROCESSING_KEY
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
      false
    end

    private

    DYNAMODB = Aws::DynamoDB::Client
    DELETION_IN_PROCESSING_KEY = "DELETING"
    private_constant :DYNAMODB, :DELETION_IN_PROCESSING_KEY

    attr_reader :table_name, :table_on_aws, :dynamodb

    def status
      dynamodb.describe_table(table_name: table_name).table.table_status
    end

    def set_schema_before_we_delete_the_table
      @schema ||= dynamodb.describe_table(table_name: table_name).to_h[:table].tap do |schema|
        schema[:table_class] = schema.dig(:table_class_summary, :table_class)
        schema.delete(:table_class_summary)
        schema.delete(:table_status)
        schema.delete(:creation_date_time)
        schema.delete(:table_size_bytes)
        schema.delete(:item_count)
        schema.delete(:table_arn)
        schema.delete(:table_id)
        schema[:provisioned_throughput]&.delete(:number_of_decreases_today)
        schema[:local_secondary_indexes]&.each do |lsi|
          lsi.delete(:index_status)
          lsi.delete(:index_size_bytes)
          lsi.delete(:item_count)
          lsi.delete(:index_arn)
        end
        schema[:global_secondary_indexes]&.each do |gsi|
          gsi.delete(:index_status)
          gsi.delete(:index_size_bytes)
          gsi.delete(:item_count)
          gsi.delete(:index_arn)
          gsi[:provisioned_throughput].delete(:number_of_decreases_today)
        end
      end
    end
  end
end
