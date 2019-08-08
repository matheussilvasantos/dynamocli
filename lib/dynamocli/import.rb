# frozen_string_literal: true

require "csv"
require "tty-logger"
require "aws-sdk-dynamodb"

class Dynamocli::Import
  LOGGER = TTY::Logger.new
  SUPPORTED_FILE_FORMATS = ["CSV"]

  def initialize(file:, table:)
    @file = file
    @table = table
    @dynamodb = Aws::DynamoDB::Client.new
  end

  def start
    records = get_records
    write_records_to_dynamodb_table(records)
  end

  private

  def get_records
    extension = File.extname(@file)

    case extension
    when ".csv"
      records_from_csv(@file)
    else
      LOGGER.error("Not supported file format. Only supported file formats are: #{SUPPORTED_FILE_FORMATS}")
      exit(42)
    end
  end

  def records_from_csv(csv)
    set_custom_converter_for_csv
    csv_options = { encoding: "UTF-8", headers: true, converters: :attribute_definitions }
    records_csv = CSV.read(csv, csv_options)
    records_csv.map(&:to_hash)
  end

  ATTRIBUTE_TYPES_CONVERTERS = {
    "S" => :to_s.to_proc,
    "N" => :to_i.to_proc,
    "B" => Proc.new(&StringIO.method(:new))
  }
  def set_custom_converter_for_csv
    attribute_definitions = @dynamodb.describe_table(table_name: @table).table.attribute_definitions
    CSV::Converters[:attribute_definitions] = lambda do |value, info|
      attribute_definition = attribute_definitions.find { |it| it.attribute_name == info.header }
      return value if attribute_definition.nil?
      ATTRIBUTE_TYPES_CONVERTERS[attribute_definition.attribute_type].call(value)
    end
  end

  def write_records_to_dynamodb_table(records)
    slice_items_to_attend_batch_write_limit(records).each do |items|
      @dynamodb.batch_write_item(request_items: format_request_items(items))
    end
  end

  BATCH_WRITE_ITEM_REQUEST_LIMIT = 25
  def slice_items_to_attend_batch_write_limit(items)
    items.each_slice(BATCH_WRITE_ITEM_REQUEST_LIMIT)
  end

  def format_request_items(items)
    { @table => items.map { |item| { put_request: { item: item } } } }
  end
end
