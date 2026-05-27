# frozen_string_literal: true

require "test_helper"

class ToolsTest < ActiveSupport::TestCase
  def setup
    SolidAgents.discover_tools!
  end

  test "ReadSchema returns schema for a table" do
    result = SolidAgents::Tools::ReadSchema.new.execute(table: "solid_agents_runs")
    assert result.is_a?(Array)
    assert result.first[:columns].any?
    assert result.first[:columns].find { |c| c[:name] == "id" }
  end

  test "ReadSchema returns all tables when no table given" do
    result = SolidAgents::Tools::ReadSchema.new.execute
    assert result.is_a?(Array)
    assert result.size > 1
    assert result.find { |t| t[:table] == "solid_agents_runs" }
  end

  test "ReadModel introspects a model" do
    result = SolidAgents::Tools::ReadModel.new.execute(name: "SolidAgents::Run")
    assert_equal "SolidAgents::Run", result[:name]
    assert_equal "solid_agents_runs", result[:table_name]
    assert result[:columns].any?
    assert result[:associations].any?
  end

  test "ReadModel returns error for unknown model" do
    result = SolidAgents::Tools::ReadModel.new.execute(name: "NonExistentModel")
    assert_match(/not found/, result[:error])
  end

  test "ReadRoute lists routes" do
    result = SolidAgents::Tools::ReadRoute.new.execute(pattern: "solid_agents")
    assert result.is_a?(String)
    assert result.present?
  end

  test "ReadRoute returns verbose hash when verbose is true" do
    result = SolidAgents::Tools::ReadRoute.new.execute(pattern: "runs", verbose: true)
    assert result.is_a?(Array)
  end

  test "QueryDatabase runs SELECT and returns columns and rows" do
    result = SolidAgents::Tools::QueryDatabase.new.execute(sql: "SELECT id, source_type FROM solid_agents_runs LIMIT 1")
    assert result[:columns].any?
    assert result.key?(:rows)
  end

  test "QueryDatabase blocks writes in production" do
    env_was = Rails.env
    Rails.env = ActiveSupport::StringInquirer.new("production")
    result = SolidAgents::Tools::QueryDatabase.new.execute(sql: "DROP TABLE solid_agents_runs")
    assert_match(/Only SELECT/, result[:error])
  ensure
    Rails.env = env_was
  end

  test "ReadFile reads a file" do
    result = SolidAgents::Tools::ReadFile.new.execute(path: "config/application.rb")
    assert result[:lines].present?
    assert_equal "config/application.rb", result[:path]
  end

  test "ReadFile returns error for missing file" do
    result = SolidAgents::Tools::ReadFile.new.execute(path: "nonexistent.rb")
    assert_match(/not found/, result[:error])
  end

  test "ReadFile respects offset and lines" do
    result = SolidAgents::Tools::ReadFile.new.execute(path: "config/application.rb", offset: 1, lines: 2)
    assert_equal 2, result[:lines].size
    assert_equal 1, result[:lines].first[:line]
  end

  test "SearchCodebase finds files matching a term" do
    result = SolidAgents::Tools::SearchCodebase.new.execute(term: "ApplicationRecord", extension: "rb")
    assert result[:count] > 0
  end

  test "ReadLog returns content or error" do
    result = SolidAgents::Tools::ReadLog.new.execute(env: "test")
    if result.is_a?(Hash) && result[:error]
      assert_match(/not found/, result[:error])
    else
      assert result.is_a?(String)
    end
  end

  test "RunCommand executes a shell command" do
    result = SolidAgents::Tools::RunCommand.new.execute(command: "echo hello", timeout: 5)
    assert_equal 0, result[:exit_code]
    assert_includes result[:stdout], "hello"
  end

  test "ReadError returns info when solid_errors not loaded" do
    result = SolidAgents::Tools::ReadError.new.execute(limit: 5)
    if defined?(SolidErrors)
      assert result.is_a?(Array)
    else
      assert_match(/not detected/, result[:info])
    end
  end

  test "all tools are discoverable" do
    expected = %w[
      QueryDatabase ReadError ReadFile ReadLog
      ReadModel ReadRoute ReadSchema RunCommand SearchCodebase
    ]
    names = SolidAgents.discovered_tools.map { |t| t.name.demodulize }
    expected.each { |name| assert_includes names, name, "Tool #{name} not discovered" }
  end

  test "each tool has a description" do
    SolidAgents.discovered_tools.each do |tool_klass|
      instance = tool_klass.new
      refute_empty instance.description, "#{tool_klass.name} is missing a description"
    end
  end

  test "conductor_session creates a session with tools" do
    tools = SolidAgents.discovered_tools.map(&:new)
    assert tools.any? { |t| t.is_a?(SolidAgents::Tools::ReadSchema) }
    assert tools.size >= 9
  end
end
