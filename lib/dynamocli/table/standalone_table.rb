# frozen_string_literal: true

require "aws-sdk-dynamodb"
require "tty-logger"

module Dynamocli::Table
  class StandaloneTable
    def initialize(table_name:, table:, dynamodb: nil, logger: nil)
      @table_name = table_name
      @table = table
      @dynamodb = dynamodb || DYNAMODB.new
      @logger = logger || LOGGER.new
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

    LOGGER = TTY::Logger
    DYNAMODB = Aws::DynamoDB::Client
    private_constant :LOGGER, :DYNAMODB

    attr_reader :table_name, :table, :dynamodb, :logger

    def delete_table
      logger.info("Deleting the #{table_name} table")

      table.delete

      logger.success("#{table_name} table deleted")
    end

    def wait_for_deletion_to_complete
      waiting_seconds = 0
      while table.deleting?
        logger.info("Waiting for deletion to complete")
        sleep waiting_seconds += 1
      end
    end

    def create_table
      logger.info("Creating the #{table_name} table")

      dynamodb.create_table(table.schema)

      logger.success("#{table_name} table created")
    end
  end
end
