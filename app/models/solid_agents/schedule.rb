# frozen_string_literal: true

module SolidAgents
  class Schedule < Record
    self.table_name = "solid_agents_schedules"

    validates :key, :cron, :prompt, presence: true
    validates :key, uniqueness: true

    scope :enabled, -> { where(enabled: true) }
  end
end
