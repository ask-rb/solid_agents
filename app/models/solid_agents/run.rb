# frozen_string_literal: true

module SolidAgents
  class Run < Record
    self.table_name = "solid_agents_runs"

    STATUSES = {
      queued: "queued",
      running: "running",
      succeeded: "succeeded",
      failed: "failed",
      canceled: "canceled"
    }.freeze

    has_many :events, class_name: "SolidAgents::RunEvent", foreign_key: :run_id, dependent: :delete_all
    has_many :artifacts, class_name: "SolidAgents::Artifact", foreign_key: :run_id, dependent: :delete_all

    enum :status, STATUSES

    validates :source_type, :status, presence: true

    scope :sessions, -> { where(source_type: "chat_session") }
    scope :recent, -> { order(created_at: :desc).limit(50) }

    def append_event!(event_type, message:, payload: nil, actor: nil)
      next_sequence = (events.maximum(:sequence) || 0) + 1
      events.create!(
        event_type: event_type,
        message: message,
        payload: payload || {},
        actor: actor || "system",
        event_time: Time.current,
        sequence: next_sequence
      )
    end

    def complete!(output:)
      update!(status: :succeeded, finished_at: Time.current, result_payload: {output: output})
      append_event!("run_completed", message: "Run completed", actor: "system")
    end

    def fail!(error:)
      update!(status: :failed, finished_at: Time.current, error_payload: {error: error})
      append_event!("run_failed", message: "Run failed: #{error}", actor: "system")
    end
  end
end
