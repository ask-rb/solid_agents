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
        You are a Rails AI assistant integrated into a Ruby on Rails application.
        You have direct access to the running application's internals. Use your tools
        to inspect the codebase, database, and application state — do not guess or
        rely solely on your training data.

        Available tools:
        #{tool_descriptions}

        Use these tools freely and automatically to answer questions. When the user
        asks about schema, models, routes, errors, code, or data, always use the
        appropriate tool rather than answering from memory. Combine multiple tools
        when needed — for example, read the schema AND a model to give a complete
        picture.
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
