# frozen_string_literal: true

require "aws-sdk-cloudformation"
require "tty-logger"

module Dynamocli::Table
  class CloudformationTable
    def initialize(table_name:, stack:, cloudformation: nil, logger: nil)
      @table_name = table_name
      @stack = stack
      @cloudformation = cloudformation || CLOUDFORMARTION.new
      @logger = logger || LOGGER.new
    end

    def alert_message_before_continue
      "You're going to deploy and redeploy your #{stack.name} stack to drop and recreate the #{@table_name} table!"
    end

    def erase
      deploy_stack_without_the_table
      wait_for_deployment_to_complete
      deploy_stack_with_the_original_template
    end

    private

    CLOUDFORMARTION = Aws::CloudFormation::Client
    LOGGER = TTY::Logger
    private_constant :CLOUDFORMARTION, :LOGGER

    attr_reader :table_name, :stack, :cloudformation, :logger

    def deploy_stack_without_the_table
      logger.info("Deploying the stack without the #{table_name} table")

      cloudformation.update_stack(
        stack_name: stack.name,
        template_body: stack.template_without_table.to_json,
        parameters: stack.parameters.map(&:to_h),
        capabilities: stack.capabilities,
        role_arn: stack.role_arn,
        rollback_configuration: stack.rollback_configuration.to_h,
        stack_policy_body: stack.policy_body,
        notification_arns: stack.notification_arns,
        tags: stack.tags.map(&:to_h)
      )

      logger.success("Stack deployed without the #{table_name} table")
    end

    def wait_for_deployment_to_complete
      waiting_seconds = 0
      while stack.deploying?
        logger.info("Waiting for deployment to complete")
        sleep waiting_seconds += 1
      end
    end

    def deploy_stack_with_the_original_template
      logger.info("Deploying the stack with the #{table_name} table")

      cloudformation.update_stack(
        stack_name: stack.name,
        template_body: stack.original_template.to_json,
        parameters: stack.parameters.map(&:to_h),
        capabilities: stack.capabilities,
        role_arn: stack.role_arn,
        rollback_configuration: stack.rollback_configuration.to_h,
        stack_policy_body: stack.policy_body,
        notification_arns: stack.notification_arns,
        tags: stack.tags.map(&:to_h)
      )

      logger.success("Stack deployed with the #{table_name} table")
    end
  end
end
