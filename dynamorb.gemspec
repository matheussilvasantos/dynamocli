lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dynamorb/version"

Gem::Specification.new do |spec|
  spec.name          = "dynamorb"
  spec.version       = Dynamorb::VERSION
  spec.authors       = ["Matheus Silva Santos de Oliveira"]
  spec.email         = ["oliveira.matheussilvasantos@gmail.com"]

  spec.summary       = %q{Utilities for interaction with AWS DynamoDB}
  spec.homepage      = "https://github.com/matheussilvasantos/dynamorb"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.20"
  spec.add_dependency "aws-sdk-dynamodb", "~> 1.28"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
