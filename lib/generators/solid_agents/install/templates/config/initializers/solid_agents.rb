# frozen_string_literal: true

Rails.application.configure do
  config.solid_agents.default_model = ENV.fetch("SOLID_AGENTS_DEFAULT_MODEL", "gpt-4o")
  config.solid_agents.default_provider = :openrouter
  config.solid_agents.max_turns = ENV.fetch("SOLID_AGENTS_MAX_TURNS", 25).to_i
  config.solid_agents.system_prompt = ENV["SOLID_AGENTS_SYSTEM_PROMPT"]

  # Define recurring agent tasks:
  # config.solid_agents.schedules = {
  #   monday_pr_review: {
  #     cron: "0 9 * * 1",
  #     prompt: "Review all open PRs for security issues."
  #   }
  # }
end
