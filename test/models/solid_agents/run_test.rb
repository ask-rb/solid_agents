# frozen_string_literal: true

require "test_helper"

class RunTest < ActiveSupport::TestCase
  test "creates a run with defaults" do
    run = SolidAgents::Run.create!(
      source_type: "chat_session",
      external_key: SecureRandom.uuid,
      environment: "test",
      prompt: "Hello",
      status: :queued
    )

    assert run.queued?
    assert_equal "chat_session", run.source_type
    assert_equal "Hello", run.prompt
  end

  test "transition through status lifecycle" do
    run = create_run

    assert run.queued?

    run.update!(status: :running, started_at: Time.current)
    assert run.running?

    run.complete!(output: "Response text")
    assert run.succeeded?
    assert_equal "Response text", run.result_payload["output"]
  end

  test "failure records error" do
    run = create_run

    run.fail!(error: "Something broke")
    assert run.failed?
    assert_equal "Something broke", run.error_payload["error"]
  end

  test "appends events with auto-incrementing sequence" do
    run = create_run

    run.append_event!("run_started", message: "started")
    run.append_event!("run_completed", message: "done")

    assert_equal 2, run.events.count
    assert_equal [1, 2], run.events.order(:sequence).pluck(:sequence)
  end

  test "returns recent sessions" do
    create_run(source_type: "chat_session", prompt: "Old")
    create_run(source_type: "chat_session", prompt: "Newer")

    sessions = SolidAgents::Run.sessions.recent
    assert_equal 2, sessions.length
  end

  private

  def create_run(attributes = {})
    SolidAgents::Run.create!({
      source_type: "chat_session",
      external_key: SecureRandom.uuid,
      environment: "test",
      prompt: "Test prompt",
      status: :queued
    }.merge(attributes))
  end
end
