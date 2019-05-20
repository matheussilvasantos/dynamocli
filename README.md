# Dynamocli

Utilites for interaction with your DynamoDB tables (only importation of data from a CSV file to a table is available for now).

## Installation

```
gem install dynamocli
```

## Usage

You have to configure AWS in your computer first. The program will use the AWS credentials configured in your computer.

After install the program you will be able to run:

```
dynamocli import your_data.csv --to your_table
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matheussilvasantos/dynamocli. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Dynamocli project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/matheussilvasantos/dynamocli/blob/master/CODE_OF_CONDUCT.md).
