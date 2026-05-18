# frozen_string_literal: true

module SolidAgents
  class Engine < ::Rails::Engine
    config.root = File.expand_path("../..", __dir__)
    isolate_namespace SolidAgents

    initializer "solid_agents.discover_tools", after: :eager_load_most do
      Dir[config.root.join("app/solid_agents/tools/*.rb")].each { |f| require_dependency f }
      SolidAgents.discover_tools!
    end

    initializer "solid_agents.error_subscriber" do
      Rails.error.subscribe(SolidAgents::ErrorSubscriber.new) if SolidAgents.auto_fix_enabled
    end

    initializer "solid_agents.configure_llm" do
      key = ENV["OPENROUTER_API_KEY"] || ENV["SOLID_AGENTS_API_KEY"]
      base = ENV["OPENROUTER_API_BASE"] || ENV["SOLID_AGENTS_API_BASE"]
      RubyLLM.configure do |config|
        config.openrouter_api_key = key if key.present?
        config.openrouter_api_base = base if base.present?
      end
    end
  end
end
