# frozen_string_literal: true

require_relative "lib/solid_agents/version"

Gem::Specification.new do |spec|
  spec.name = "solid_agents"
  spec.version = SolidAgents::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kr@kakaruto.com"]

  spec.summary = "Rails-native AI coding agent engine"
  spec.description = "A Rails engine that brings Claude Code-like AI agent capabilities into your Rails app. Chat with AI about your codebase, auto-fix errors, schedule recurring tasks — all running in your Rails process."
  spec.homepage = "https://github.com/kaka-ruto/solid_agents"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "README.md", "AGENTS.md", "CHANGELOG.md", "Rakefile", "LICENSE.txt"]
  end

  rails_version = ">= 7.1"
  spec.add_dependency "actionpack", rails_version
  spec.add_dependency "actionview", rails_version
  spec.add_dependency "activejob", rails_version
  spec.add_dependency "activerecord", rails_version
  spec.add_dependency "activesupport", rails_version
  spec.add_dependency "railties", rails_version
  spec.add_dependency "ruby_llm", ">= 1.14"
  spec.add_dependency "ruby_llm-conductor", ">= 0.1"

  spec.add_development_dependency "sqlite3", ">= 2.0"
  spec.add_development_dependency "vcr", ">= 6.0"
  spec.add_development_dependency "webmock", ">= 3.0"
end
