# frozen_string_literal: true

require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  test "creates a schedule with defaults" do
    schedule = SolidAgents::Schedule.create!(
      key: "weekly_review",
      cron: "0 9 * * 1",
      prompt: "Review all open PRs for security issues."
    )

    assert schedule.enabled?
    assert_equal "weekly_review", schedule.key
    assert_equal "0 9 * * 1", schedule.cron
  end

  test "requires key, cron, and prompt" do
    schedule = SolidAgents::Schedule.new
    assert_not schedule.valid?
    assert_includes schedule.errors[:key], "can't be blank"
    assert_includes schedule.errors[:cron], "can't be blank"
    assert_includes schedule.errors[:prompt], "can't be blank"
  end

  test "enforces unique keys" do
    SolidAgents::Schedule.create!(key: "unique", cron: "0 0 * * *", prompt: "Test")
    duplicate = SolidAgents::Schedule.new(key: "unique", cron: "0 0 * * *", prompt: "Test")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "scopes enabled schedules" do
    SolidAgents::Schedule.create!(key: "enabled_sched", cron: "0 0 * * *", prompt: "Enabled", enabled: true)
    SolidAgents::Schedule.create!(key: "disabled_sched", cron: "0 0 * * *", prompt: "Disabled", enabled: false)

    assert_equal 1, SolidAgents::Schedule.enabled.count
    assert_equal "enabled_sched", SolidAgents::Schedule.enabled.first.key
  end
end
