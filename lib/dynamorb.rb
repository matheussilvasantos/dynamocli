require "dynamorb/version"
require "dynamorb/import"

module Dynamorb
  class Client < Thor
    desc "import FILE", "import data from FILE to dynamodb"
    long_desc <<-LONGDESC
      `dynamo import` will import the data in from a file
      to a table specified.

      > $ dynamo import users.csv --to users
    LONGDESC
    option :to, required: true, desc: "table you want to import the data", banner: "TABLE", aliases: ["-t", "--table"]
    def import(file)
      Dynamorb::Import.new(file: file, table: options[:to]).start
    end
  end
end
