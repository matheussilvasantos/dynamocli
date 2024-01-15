lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dynamocli/version"

Gem::Specification.new do |spec|
  spec.name          = "dynamocli"
  spec.version       = Dynamocli::VERSION
  spec.authors       = ["Matheus Silva Santos de Oliveira"]
  spec.email         = ["oliveira.matheussilvasantos@gmail.com"]

  spec.summary       = %q{Utilities for interaction with AWS DynamoDB}
  spec.homepage      = "https://github.com/matheussilvasantos/dynamocli"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/dynamocli}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "thor"
  spec.add_dependency "ox"
  spec.add_dependency "aws-sdk-dynamodb"
  spec.add_dependency "aws-sdk-cloudformation"
  spec.add_dependency "tty-logger"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug"
end
