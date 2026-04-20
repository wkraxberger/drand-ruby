# frozen_string_literal: true

require_relative "lib/drand/version"

Gem::Specification.new do |spec|
  spec.name = "drand"
  spec.version = Drand::VERSION
  spec.authors = ["Walter Kraxberger"]
  spec.email = ["wkrax@hotmail.com"]

  spec.summary = "Ruby client for drand, the public randomness beacon."
  spec.homepage = "https://github.com/wkraxberger/drand-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
end
