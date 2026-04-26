# frozen_string_literal: true

require_relative "lib/tanedb/version"

Gem::Specification.new do |spec|
  spec.name = "tanedb"
  spec.version = Tanedb::VERSION
  spec.authors = ["machida4"]
  spec.email = ["machida@kmc.gr.jp"]

  spec.summary = "🌱 A small relational database written in Ruby for learning"
  spec.homepage = "https://github.com/machida4/tanedb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENSE"
  ]
  spec.require_paths = ["lib"]
end
