# frozen_string_literal: true

module SolidAgents
  module ApplicationHelper
    def status_badge_class(status)
      case status
      when "succeeded" then "ok"
      when "failed" then "err"
      when "running" then "run"
      when "queued" then "muted"
      else "muted"
      end
    end

    def time_ago_tag(time)
      return "" unless time

      tag.time distance_of_time_in_words_to_now(time) + " ago",
              datetime: time.iso8601,
              title: time.to_fs(:long)
    end
  end
end
