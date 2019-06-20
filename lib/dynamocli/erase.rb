# frozen_string_literal: true

require "json"
require "yaml"
require "aws-sdk-dynamodb"
require "aws-sdk-cloudformation"

class Dynamocli::Erase
  def initialize(table_name:, with_drift: false)
    @with_drift = with_drift
    @table_name = table_name

    @dynamodb = Aws::DynamoDB::Client.new
    @cloudformation = Aws::CloudFormation::Client.new
    @table = Aws::DynamoDB::Table.new(@table_name)

    set_schema

    @stack_resources = @cloudformation.describe_stack_resources(physical_resource_id: @table_name).to_h

    set_stack_information
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException => e
    STDERR.puts "ERROR: #{e.message}"
    exit(42)
  rescue Aws::CloudFormation::Errors::ValidationError
    @stack_resources = nil
  end

  def start
    erase_table
  rescue Aws::CloudFormation::Errors::ValidationError => e
    STDERR.puts "ERROR: #{e.message}"
    exit(42)
  end

  private

  def set_schema
    @schema = @dynamodb.describe_table(table_name: @table_name).to_h[:table].tap do |schema|
      schema.delete(:table_status)
      schema.delete(:creation_date_time)
      schema.delete(:table_size_bytes)
      schema.delete(:item_count)
      schema.delete(:table_arn)
      schema.delete(:table_id)
      schema[:provisioned_throughput].delete(:number_of_decreases_today)
    end
  end
  
  def set_stack_information
    return if @stack_resources.nil?

    set_stack_name
    set_stack
    set_templates
  rescue Aws::CloudFormation::Errors::ValidationError => e
    STDERR.puts "ERROR: #{e.message}"
    exit(42)
  end

  def set_stack_name
    table_resource = @stack_resources[:stack_resources].find do |resource|
      resource[:physical_resource_id] == @table_name
    end
    @stack_name = table_resource[:stack_name]
  end

  def set_stack
    @stack = @cloudformation.describe_stacks(stack_name: @stack_name)[0][0]
  end

  def set_templates
    template_body = @cloudformation.get_template(stack_name: @stack_name).to_h[:template_body]
    @original_template = parse_template(template_body)
    @template_without_table = parse_template(template_body)

    tables = @original_template["Resources"].select { |_, v| v["Type"] == "AWS::DynamoDB::Table" }
    table = tables.find { |_, v| v["Properties"]["TableName"] == @table_name }

    if tables.nil?
      STDERR.puts "ERROR: table #{@table_name} not found in the #{@stack_name} stack"
      exit(42)
    end

    logical_resource_id = table.first
    @template_without_table["Resources"].delete(logical_resource_id)
  end

  def parse_template(template)
    JSON.parse(template)
  rescue JSON::ParserError
    YAML.load(template)
  end

  def erase_table
    if @stack_resources.nil? || @with_drift
      check_if_user_wants_to_continue_with_recreation
      delete_and_recreate_the_table
    else
      check_if_user_wants_to_continue_with_deployment
      erase_table_through_cloudformation
    end
  end

  def check_if_user_wants_to_continue_with_recreation
    STDOUT.print(
      "WARNING: You're going to drop and recreate your #{@table_name} table,\n" \
      "do you really want to continue?\n" \
      "(anything other than 'y' will cancel) > "
    )

    confirmation = STDIN.gets.strip
    return if confirmation == "y"

    STDOUT.puts abort_message
    exit(0)
  end

  def abort_message
    "INFO: Erase of #{@table_name} table canceled"
  end

  def delete_and_recreate_the_table
    delete_table
    wait_for_deletion_to_complete
    create_table
  end

  def delete_table
    STDOUT.puts "INFO: Deleting the #{@table_name} table"

    @table.delete

    STDOUT.puts "INFO: #{@table_name} table deleted"
  end

  def wait_for_deletion_to_complete
    waiting_seconds = 0
    while get_table_status == "DELETING"
      STDOUT.puts "INFO: Waiting for deletion to complete"
      sleep waiting_seconds += 1
    end
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    true
  end

  def get_table_status
    @dynamodb.describe_table(table_name: @table_name).table.table_status
  end

  def create_table
    STDOUT.puts "INFO: Creating the #{@table_name} table"

    @dynamodb.create_table(@schema)

    STDOUT.puts "INFO: #{@table_name} table created"
  end
  
  def check_if_user_wants_to_continue_with_deployment
    STDOUT.print(
      "WARNING: You are going to deploy and redeploy your #{@stack_name} stack\n" \
      "to drop and recreate the #{@table_name} table, do you really want to continue?\n" \
      "(anything other than 'y' will cancel) > "
    )

    confirmation = STDIN.gets.strip
    return if confirmation == "y"

    STDOUT.puts abort_message
    exit(0)
  end

  def erase_table_through_cloudformation
    deploy_stack_without_the_table
    wait_for_deployment_to_complete
    deploy_stack_with_the_original_template
  end

  def deploy_stack_without_the_table
    STDOUT.puts "INFO: Deploying the stack without the #{@table_name} table"

    @cloudformation.update_stack(
      stack_name: @stack_name,
      template_body: @template_without_table.to_json,
      parameters: @stack.parameters.map(&:to_h),
      capabilities: @stack.capabilities,
      role_arn: @stack.role_arn,
      rollback_configuration: @stack.rollback_configuration.to_h,
      stack_policy_body: get_stack_policy_body,
      notification_arns: @stack.notification_arns,
      tags: @stack.tags.map(&:to_h)
    )

    STDOUT.puts "INFO: Stack deployed without the #{@table_name} table"
  end

  def get_stack_policy_body
    @cloudformation.get_stack_policy(stack_name: @stack_name).stack_policy_body
  end

  def wait_for_deployment_to_complete
    waiting_seconds = 0
    while get_stack_status != "UPDATE_COMPLETE"
      STDOUT.puts "INFO: Waiting for deployment to complete"
      sleep waiting_seconds += 1
    end
  end

  def get_stack_status
    @cloudformation.describe_stacks(stack_name: @stack_name)[0][0].stack_status
  end

  def deploy_stack_with_the_original_template
    STDOUT.puts "INFO: Deploying the stack with the #{@table_name} table"

    @cloudformation.update_stack(
      stack_name: @stack_name,
      template_body: @original_template.to_json,
      parameters: @stack.parameters.map(&:to_h),
      capabilities: @stack.capabilities,
      role_arn: @stack.role_arn,
      rollback_configuration: @stack.rollback_configuration.to_h,
      stack_policy_body: get_stack_policy_body,
      notification_arns: @stack.notification_arns,
      tags: @stack.tags.map(&:to_h)
    )

    STDOUT.puts "INFO: Stack deployed with the #{@table_name} table"
  end
end
