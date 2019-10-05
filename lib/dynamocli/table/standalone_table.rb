# frozen_string_literal: true

require "aws-sdk-dynamodb"
require "tty-logger"

module Dynamocli::Table
  class StandaloneTable
    LOGGER = TTY::Logger.new

    def initialize(table_name:, table:, dynamodb: nil)
      @table_name = table_name
      @table = table
      @dynamodb = dynamodb || Aws::DynamoDB::Client.new
    end

    def alert_message_before_continue
      "You're going to drop and recreate your #{@table_name} table!"
    end

    def erase
      delete_table
      wait_for_deletion_to_complete
      create_table
    end

    private

    attr_reader :table_name, :table, :dynamodb, :schema

    def delete_table
      LOGGER.info("Deleting the #{table_name} table")

      set_schema_before_we_delete_the_table
      table.delete

      LOGGER.success("#{table_name} table deleted")
    end

    def wait_for_deletion_to_complete
      waiting_seconds = 0
      while get_table_status == "DELETING"
        LOGGER.info("Waiting for deletion to complete")
        sleep waiting_seconds += 1
      end
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
      true
    end

    def get_table_status
      dynamodb.describe_table(table_name: table_name).table.table_status
    end

    def create_table
      LOGGER.info("Creating the #{table_name} table")

      dynamodb.create_table(schema)

      LOGGER.success("#{table_name} table created")
    end

    def set_schema_before_we_delete_the_table
      @schema ||= dynamodb.describe_table(table_name: table_name).to_h[:table].tap do |schema|
        schema.delete(:table_status)
        schema.delete(:creation_date_time)
        schema.delete(:table_size_bytes)
        schema.delete(:item_count)
        schema.delete(:table_arn)
        schema.delete(:table_id)
        schema[:provisioned_throughput].delete(:number_of_decreases_today)
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
