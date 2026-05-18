# frozen_string_literal: true

require "ruby_llm"
require "ruby_llm/conductor"
require_relative "solid_agents/version"
require_relative "solid_agents/engine"

module SolidAgents
  mattr_accessor :discovered_tools, default: []
  mattr_accessor :base_controller_class, default: "::ActionController::Base"
  mattr_accessor :default_model, default: "gpt-4o"
  mattr_accessor :default_provider, default: :openrouter
  mattr_accessor :max_turns, default: 25
  mattr_accessor :system_prompt
  mattr_accessor :auto_fix_enabled, default: false

  class << self
    def discover_tools!
      self.discovered_tools = SolidAgents::Tools::Base.descendants
    end

    def conductor_session(**extra)
      tools = self.discovered_tools.map(&:new) + (extra.delete(:extra_tools) || [])
      RubyLLM::Conductor::Session.new(
        model: default_model,
        max_turns: max_turns,
        system_prompt: system_prompt,
        provider: default_provider,
        parallel_tools: true,
        tools: tools,
        **extra
      )
    end
  end
end

require_relative "solid_agents/tools/base"
require_relative "../app/models/solid_agents/record"
require_relative "../app/models/solid_agents/run"
require_relative "../app/models/solid_agents/run_event"
require_relative "../app/models/solid_agents/artifact"
require_relative "../app/models/solid_agents/schedule"
require_relative "../app/models/solid_agents/config"
