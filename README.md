# Dynamocli

Utilites for interaction with your DynamoDB tables.

## Installation

```
gem install dynamocli
```

## Usage


You have to configure AWS in your computer first. The program will use the AWS credentials configured in your computer.

- Import data from a CSV file to a DynamoDB table

If you have exported the CSV file you want to import from AWS DynamoDB console, you probaly want to modify the headers before importing the CSV file, because AWS exports the CSV file with a symbol indicating the type of the field in the header. You can pass the option `--exported-from-aws` to do that, the default is false.

```
Usage:
  dynamocli import FILE -t, --table, --to=TABLE

Options:
  -t, --table, --to=TABLE                                  # table you want to import the data
          [--exported-from-aws], [--no-exported-from-aws]  # modify the headers before importing the csv

Description:
  `dynamocli import` will import the data in from a file to a table specified.

  > $ dynamo import users.csv --to users

```

- Erase all the data of a DynamoDB table

```
Usage:
  dynamocli erase TABLE

Options:
  [--with-drift], [--no-with-drift]  # drop the table and
  recreate it directly instead of use deployments

Description:
  `dynamocli erase` will erase all the data of the specified table.

  It will drop the table and recreate it.

  If the table is in a stack it will try to deploy
  the stack without the table and then redeploy the
  stack with the original template. You can change
  this behavior passing the option --with-drift.

  > $ dynamo erase users
```

From the DynamoDB Guidelines for Working with Tables documentation:

> Deleting an entire table is significantly more efficient than removing items one-by-one, which essentially doubles the write throughput as you do as many delete operations as put operations.

## Known Issues

### Importing a CSV file with arrays and objects as values in it

Unfortunately, at this moment, this library cannot properly import array and objects. These values will appear as strings in the DynamoDB table.

## Cross account or multiple profiles usage

You can run `dynamocli` passing the `AWS_PROFILE` environment variable with the profile you want to use, for example: `AWS_PROFILE=nondefaultprofile dynamocli erase users`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matheussilvasantos/dynamocli. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Dynamocli project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/matheussilvasantos/dynamocli/blob/master/CODE_OF_CONDUCT.md).
