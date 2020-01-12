# frozen_string_literal: true

require "tty-logger"
require "aws-sdk-dynamodb"
require "aws-sdk-cloudformation"
require "dynamocli/table/cloudformation_table"
require "dynamocli/table/standalone_table"
require "dynamocli/aws/stack"
require "dynamocli/aws/table"

class Dynamocli::Erase
  def initialize(table_name:, with_drift: false)
    @with_drift = with_drift
    @table_name = table_name

    @dynamodb = Aws::DynamoDB::Client.new
    @cloudformation = Aws::CloudFormation::Client.new
    @table_on_aws = Aws::DynamoDB::Table.new(@table_name)

    @stack_resources = @cloudformation.describe_stack_resources(physical_resource_id: @table_name).to_h
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException => e
    LOGGER.error(e.message)
    exit(42)
  rescue Aws::CloudFormation::Errors::ValidationError
    @stack_resources = nil
  end

  def start
    erase_table
  rescue Aws::CloudFormation::Errors::ValidationError => e
    LOGGER.error(e.message)
    exit(42)
  end

  private

  LOGGER = TTY::Logger.new
  private_constant :LOGGER

  attr_reader :table_name, :table_on_aws, :stack_resources

  def erase_table
    check_if_user_wants_to_continue
    dynamocli_table.erase
  end

  def check_if_user_wants_to_continue
    LOGGER.warn(
      "#{dynamocli_table.alert_message_before_continue} " \
      "Do you really want to continue?"
    )
    STDOUT.print("(anything other than 'y' will cancel) > ")

    confirmation = STDIN.gets.strip
    return if confirmation == "y"

    LOGGER.info(abort_message)
    exit(0)
  end

  def abort_message
    "Erase of #{@table_name} table canceled"
  end

  def dynamocli_table
    @dynamocli_table ||=
      if stack_resources.nil? || with_drift?
        table = Dynamocli::AWS::Table.new(table_name: table_name, table_on_aws: table_on_aws)
        Dynamocli::Table::StandaloneTable.new(table_name: table_name, table: table)
      else
        stack = Dynamocli::AWS::Stack.new(table_name: table_name, table_resource: table_resource)
        Dynamocli::Table::CloudformationTable.new(table_name: table_name, stack: stack)
      end
  end

  def with_drift?
    @with_drift
  end

  def table_resource
    @table_resource ||= stack_resources[:stack_resources].find do |resource|
      resource[:physical_resource_id] == @table_name
    end
  end
end
