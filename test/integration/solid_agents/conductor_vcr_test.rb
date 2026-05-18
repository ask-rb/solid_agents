# frozen_string_literal: true

require "test_helper"
require "vcr"
require "webmock"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<API_KEY>") { |interaction|
    interaction.request.headers["Authorization"]&.first&.sub(/^Bearer\s+/, "")
  }
  config.filter_sensitive_data("<API_KEY>") { |interaction|
    raw = interaction.request.body
    body = raw.respond_to?(:string) ? raw.string : raw.to_s
    body.scan(/sk-[a-zA-Z0-9_-]{15,}/)&.first
  }
  config.filter_sensitive_data("<API_KEY>") { ENV["OPENCODE_API_KEY"] }
  config.default_cassette_options = { record: :once, match_requests_on: [:method, :uri] }
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = false
end

class VcrCalcTool < RubyLLM::Tool
  description "Calculate a math expression"
  param :expr, type: :string, desc: "Expression", required: true
  def execute(expr:)
    { expression: expr, result: eval(expr).to_s }
  rescue => e
    { expression: expr, error: e.message }
  end
end

class VcrExplodeTool < RubyLLM::Tool
  description "Process data input"
  param :data, type: :string, desc: "Data", required: true
  def execute(data:)
    raise "CRASH: processing failed for #{data}"
  end
end

class VcrFlakyTool < RubyLLM::Tool
  description "Fetch weather data for a city"
  param :city, type: :string, desc: "City", required: true
  def execute(city:)
    @count ||= 0
    @count += 1
    if @count <= 1
      raise "Service temporarily unavailable, please retry"
    else
      { city: city, temperature: 22, conditions: "sunny" }
    end
  end
end

class VcrEmptyTool < RubyLLM::Tool
  description "Search the database for records"
  param :q, type: :string, desc: "Query", required: true
  def execute(q:)
    { results: [], message: "No records found" }
  end
end

class ConductorToolTest < ActiveSupport::TestCase
  CASSETTE_DIR = "solid_agents"

  def setup
    @api_key = ENV["OPENCODE_API_KEY"] || "sk-dummy-for-vcr-replay"

    RubyLLM.configure do |config|
      config.opencode_api_key = @api_key
      config.opencode_go_api_key = @api_key
      config.default_model = "deepseek-v4-flash"
    end

    SolidAgents.discover_tools!
  end

  test "conductor session with read_schema tool" do
    VCR.use_cassette("#{CASSETTE_DIR}/read_schema_tool", record: :once) do
      session = RubyLLM::Conductor::Session.new(
        model: "deepseek-v4-flash",
        tools: [SolidAgents::Tools::ReadSchema.new],
        max_turns: 3,
        provider: :opencode_go,
        assume_model_exists: true
      )

      response = session.run("Use the read_schema tool to inspect the 'solid_agents_runs' table")

      assert response.is_a?(String)
      refute_empty response
      assert response.length > 50

      chat_has_tool_result = session.chat.messages.any? { |m| m.role == :tool }
      assert chat_has_tool_result, "Expected at least one tool result to be present"
    end
  end

  test "conductor session with read_model tool" do
    VCR.use_cassette("#{CASSETTE_DIR}/read_model_tool", record: :once) do
      session = RubyLLM::Conductor::Session.new(
        model: "deepseek-v4-flash",
        tools: [SolidAgents::Tools::ReadModel.new],
        max_turns: 3,
        provider: :opencode_go,
        assume_model_exists: true
      )

      response = session.run("Use the read_model tool to get details about the SolidAgents::Run model")

      assert response.is_a?(String)
      refute_empty response

      # Should mention key model details
      assert_match(/table|schema|column|association/i, response)
    end
  end

  test "conductor session with multiple tools" do
    VCR.use_cassette("#{CASSETTE_DIR}/multi_tool_session", record: :once) do
      session = RubyLLM::Conductor::Session.new(
        model: "deepseek-v4-flash",
        tools: [VcrCalcTool.new],
        max_turns: 5,
        provider: :opencode_go,
        assume_model_exists: true
      )

      response = session.run("Calculate 15 * 37 using the calculator tool")

      assert response.is_a?(String)
      refute_empty response
      assert_includes response, "555"
    end
  end

  test "conductor session handles tool errors gracefully" do
    VCR.use_cassette("#{CASSETTE_DIR}/tool_error_handling", record: :once) do
      session = RubyLLM::Conductor::Session.new(
        model: "deepseek-v4-flash",
        tools: [VcrExplodeTool.new],
        max_turns: 5,
        provider: :opencode_go,
        assume_model_exists: true
      )

      response = session.run("Process the data 'crash-test'")

      assert response.is_a?(String)
      refute_empty response
      refute_match(/internal error|exception|stack trace/i, response)
    end
  end

  test "conductor session recovers from intermittent tool failures" do
    VCR.use_cassette("#{CASSETTE_DIR}/intermittent_failure", record: :once) do
      session = RubyLLM::Conductor::Session.new(
        model: "deepseek-v4-flash",
        tools: [VcrFlakyTool.new],
        max_turns: 5,
        provider: :opencode_go,
        assume_model_exists: true
      )

      response = session.run("What is the weather in Nairobi?")

      assert response.is_a?(String)
      refute_empty response
      assert_includes response, "sunny"
      assert_includes response, "22"
    end
  end

  test "conductor session without tools gives honest response" do
    VCR.use_cassette("#{CASSETTE_DIR}/no_tools_honest", record: :once) do
      session = RubyLLM::Conductor::Session.new(
        model: "deepseek-v4-flash",
        max_turns: 3,
        provider: :opencode_go,
        assume_model_exists: true
      )

      response = session.run("Look up the capital of France using a tool")

      assert response.is_a?(String)
      refute_empty response

      refute_match(/I have (access to|tools available)|can look up|using (any )?tool/i, response)
    end
  end

  test "conductor session stops within max turns" do
    VCR.use_cassette("#{CASSETTE_DIR}/max_turns_guard", record: :once) do
      session = RubyLLM::Conductor::Session.new(
        model: "deepseek-v4-flash",
        tools: [VcrEmptyTool.new],
        max_turns: 4,
        provider: :opencode_go,
        assume_model_exists: true
      )

      response = session.run("Search for 'something unlikely to exist'")

      assert response.is_a?(String)
      refute_empty response
    end
  end
end
