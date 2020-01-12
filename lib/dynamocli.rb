require "thor"
require "dynamocli/version"
require "dynamocli/import"
require "dynamocli/erase"

module Dynamocli
  class Client < Thor
    desc "import FILE", "import data from FILE to dynamodb"
    long_desc <<-LONGDESC
      `dynamocli import` will import the data in from a file
      to a table specified.

      > $ dynamo import users.csv --to users
    LONGDESC
    option :to, required: true, desc: "table you want to import the data", banner: "TABLE", aliases: ["-t", "--table"]
    option "exported-from-aws", desc: "modify the headers before importing the csv", type: :boolean
    def import(file)
      Dynamocli::Import.new(file: file, table: options[:to], exported_from_aws: options["exported-from-aws"]).start
    end

    desc "erase TABLE", "erase all the data from the DynamoDB TABLE"
    long_desc <<-LONGDESC
      `dynamocli erase` will erase all the data of the specified table.

      It will drop the table and recreate it.

      If the table is in a stack it will try to deploy the stack without
      the table and then redeploy the stack with the original template.
      You can change this behavior passing the option --with-drift.

      > $ dynamo erase users
    LONGDESC
    option "with-drift", desc: "drop the table and recreate it directly instead of use deployments", type: :boolean
    def erase(table)
      Dynamocli::Erase.new(table_name: table, with_drift: options["with-drift"]).start
    end
  end
end
