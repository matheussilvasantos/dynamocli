# frozen_string_literal: true

require "aws-sdk-cloudformation"
require "tty-logger"
require "json"
require "yaml"

module Dynamocli::Table
  class CloudformationTable
    LOGGER = TTY::Logger.new

    def initialize(table_name:, table_resource:, cloudformation: nil)
      @table_name = table_name
      @table_resource = table_resource
      @cloudformation = cloudformation ||= Aws::CloudFormation::Client.new
    end

    def alert_message_before_continue
      "You're going to deploy and redeploy your #{@stack_name} stack to drop and recreate the #{@table_name} table!"
    end

    def erase
      set_all_stack_information_before_we_change_it
      deploy_stack_without_the_table
      wait_for_deployment_to_complete
      deploy_stack_with_the_original_template
    rescue Aws::CloudFormation::Errors::ValidationError => e
      LOGGER.error(e.message)
      exit(42)
    end

    private

    attr_reader :table_name, :table_resource, :cloudformation, :stack, :stack_name,
                :stack_resources, :template_body, :original_template, :template_without_table,
                :stack_policy_body

    def set_all_stack_information_before_we_change_it
      set_stack
      set_stack_name
      set_stack_resources
      set_template_body
      set_original_template
      set_template_without_table
      set_stack_policy_body
    end

    def deploy_stack_without_the_table
      LOGGER.info("Deploying the stack without the #{table_name} table")

      cloudformation.update_stack(
        stack_name: stack_name,
        template_body: template_without_table.to_json,
        parameters: stack.parameters.map(&:to_h),
        capabilities: stack.capabilities,
        role_arn: stack.role_arn,
        rollback_configuration: stack.rollback_configuration.to_h,
        stack_policy_body: stack_policy_body,
        notification_arns: stack.notification_arns,
        tags: stack.tags.map(&:to_h)
      )

      LOGGER.success("Stack deployed without the #{table_name} table")
    end

    def wait_for_deployment_to_complete
      waiting_seconds = 0
      while get_stack_status != "UPDATE_COMPLETE"
        LOGGER.info("Waiting for deployment to complete")
        sleep waiting_seconds += 1
      end
    end

    def get_stack_status
      cloudformation.describe_stacks(stack_name: stack_name)[0][0].stack_status
    end

    def deploy_stack_with_the_original_template
      LOGGER.info("Deploying the stack with the #{table_name} table")

      cloudformation.update_stack(
        stack_name: stack_name,
        template_body: original_template.to_json,
        parameters: stack.parameters.map(&:to_h),
        capabilities: stack.capabilities,
        role_arn: stack.role_arn,
        rollback_configuration: stack.rollback_configuration.to_h,
        stack_policy_body: stack_policy_body,
        notification_arns: stack.notification_arns,
        tags: stack.tags.map(&:to_h)
      )

      LOGGER.success("Stack deployed with the #{table_name} table")
    end

    def set_stack
      @stack ||= cloudformation.describe_stacks(stack_name: stack_name)[0][0]
    end

    def set_stack_name
      @stack_name ||= table_resource[:stack_name]
    end

    def set_stack_resources
      @stack_resources ||= cloudformation.describe_stack_resources(physical_resource_id: table_name).to_h
    end

    def set_template_body
      @template_body ||= @cloudformation.get_template(stack_name: @stack_name).to_h[:template_body]
    end

    def set_original_template
      @original_template ||= parse_template(template_body)
    end

    def set_template_without_table
      @template_without_table ||= parse_template(template_body).tap do |template_without_table|
        tables = original_template["Resources"].select { |_, v| v["Type"] == "AWS::DynamoDB::Table" }
        table = tables.find { |_, v| v["Properties"]["TableName"] == @table_name }

        if tables.nil?
          LOGGER.error("table #{@table_name} not found in the #{@stack_name} stack")
          exit(42)
        end

        logical_resource_id = table.first
        template_without_table["Resources"].delete(logical_resource_id)
      end
    end

    def parse_template(template)
      JSON.parse(template)
    rescue JSON::ParserError
      YAML.load(template)
    end

    def set_stack_policy_body
      @stack_policy_body ||= cloudformation.get_stack_policy(stack_name: stack_name).stack_policy_body
    end
  end
end
