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

    def default_system_prompt
      tool_descriptions = discovered_tools.map { |t|
        instance = t.new
        lines = instance.description.split("\n")
        "- **#{t.name.demodulize}**: #{lines.first}"
      }.join("\n")

      <<~PROMPT
        You are a Ruby on Rails software engineer integrated into a Rails application.
        You have direct access to the application's code, database, and runtime — use
        your tools to inspect and modify the codebase rather than guessing from memory.

        Available tools:
        #{tool_descriptions}

        When asked to fix a bug, first write a failing test, then implement the fix,
        then verify the test passes. If the project has no test setup, just implement
        the fix directly. If the user explicitly says to skip tests or just implement,
        do only what they ask.

        Use tools freely — read schema, models, routes, code, and data to give
        complete, accurate answers.
      PROMPT
    end

    def conductor_session(**extra)
      tools = self.discovered_tools.map(&:new) + (extra.delete(:extra_tools) || [])
      prompt = extra.delete(:system_prompt) || system_prompt || default_system_prompt
      RubyLLM::Conductor::Session.new(
        model: default_model,
        max_turns: max_turns,
        system_prompt: prompt,
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
