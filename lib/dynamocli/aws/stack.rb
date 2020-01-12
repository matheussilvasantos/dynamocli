# frozen_string_literal: true

require 'forwardable'

module Dynamocli::AWS
  class Stack
    attr_reader :name, :resources, :template_body, :original_template, :template_without_table, :policy_body

    extend Forwardable
    def_delegators :stack_on_aws,
                   :parameters, :capabilities, :role_arn, :rollback_configuration, :notification_arns, :tags

    def initialize(table_name:, table_resource:, cloudformation: nil, logger: nil)
      @table_name = table_name
      @table_resource = table_resource
      @cloudformation = cloudformation || CLOUDFORMARTION.new
      @logger = logger || LOGGER.new

      set_attributes_now_because_they_will_change
    end

    def deploying?
      current_status != DEPLOY_COMPLETED_KEY
    end

    private

    CLOUDFORMARTION = Aws::CloudFormation::Client
    LOGGER = TTY::Logger
    DEPLOY_COMPLETED_KEY = "UPDATE_COMPLETE"
    private_constant :CLOUDFORMARTION, :LOGGER, :DEPLOY_COMPLETED_KEY

    attr_reader :table_name, :table_resource, :cloudformation, :logger, :stack_on_aws

    def set_attributes_now_because_they_will_change
      set_name
      set_stack_on_aws
      set_resources
      set_template_body
      set_original_template
      set_template_without_table
      set_policy_body
    end

    def set_name
      @name ||= table_resource[:stack_name]
    end

    def set_stack_on_aws
      @stack_on_aws ||= cloudformation.describe_stacks(stack_name: name)[0][0]
    end

    def set_resources
      @resources ||= cloudformation.describe_stack_resources(physical_resource_id: table_name).to_h
    end

    def set_template_body
      @template_body ||= cloudformation.get_template(stack_name: name).to_h[:template_body]
    end

    def set_original_template
      @original_template ||= parse_template(template_body)
    end

    def set_template_without_table
      @template_without_table ||= parse_template(template_body).tap do |template_without_table|
        tables = original_template["Resources"].select { |_, v| v["Type"] == "AWS::DynamoDB::Table" }
        table = tables.find { |_, v| v["Properties"]["TableName"] == table_name }

        if tables.nil?
          logger.error("table #{table_name} not found in the #{@name} stack")
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

    def set_policy_body
      @policy_body ||= cloudformation.get_stack_policy(stack_name: name).stack_policy_body
    end

    def current_status
      cloudformation.describe_stacks(stack_name: name)[0][0].stack_status
    end
  end
end
