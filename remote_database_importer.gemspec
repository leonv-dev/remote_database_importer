# frozen_string_literal: true

require_relative "lib/remote_database_importer/version"

Gem::Specification.new do |spec|
  spec.name = "remote_database_importer"
  spec.version = RemoteDatabaseImporter::VERSION
  spec.authors = ["Leon"]
  spec.email = ["nonick@nonick.ch"]

  spec.summary = "Dump remote database and import locally"
  spec.description = "Dump remote database and import locally. Currently only postgres databases supported"
  spec.homepage = "https://github.com/leon-vogt/remote_database_importer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/leon-vogt/remote_database_importer"
  spec.metadata["changelog_uri"] = "https://github.com/leon-vogt/remote_database_importer/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "tty-config", "~> 0.6.0"
  spec.add_dependency "thor", "~> 1.2.1"
  spec.add_development_dependency "pry", "~> 0.14.1"
end
