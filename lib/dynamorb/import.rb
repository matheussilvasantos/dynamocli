require "thor"
require "csv"
require "aws-sdk-dynamodb"

class Dynamorb::Import
  SUPPORTED_FILE_FORMATS = ["CSV"]

  def initialize(file:, table:)
    @file = file
    @table = table
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
      STDERR.puts "ERROR: Not supported file format. Only supported file formats are: #{SUPPORTED_FILE_FORMATS}"
      exit(42)
    end
  end

  def records_from_csv(csv)
    csv_options = { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all }
    records_csv = CSV.read(csv, csv_options)
    records_csv.map(&:to_hash)
  end

  def write_records_to_dynamodb_table(records)
    dynamodb = Aws::DynamoDB::Client.new

    slice_items_to_attend_batch_write_limit(records).each do |items|
      dynamodb.batch_write_item(request_items: format_request_items(items))
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
