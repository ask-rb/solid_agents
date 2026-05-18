# frozen_string_literal: true

module SolidAgents
  class ScheduledRunJob < ActiveJob::Base
    queue_as :default

    def perform(schedule_id)
      schedule = SolidAgents::Schedule.find(schedule_id)
      return unless schedule.enabled?

      run = SolidAgents::Run.create!(
        source_type: "schedule",
        source_id: schedule.id,
        external_key: "sched-#{schedule.id}-#{Time.current.to_i}",
        environment: Rails.env,
        status: :queued,
        prompt: schedule.prompt,
        prompt_payload: { schedule_key: schedule.key, schedule_id: schedule.id },
        repo_path: Rails.root.to_s
      )

      run.update!(status: :running, started_at: Time.current)
      run.append_event!("run_started", message: "Scheduled run: #{schedule.key}")

      session = SolidAgents.conductor_session
      response = session.run(schedule.prompt)
      run.complete!(output: response)
    rescue StandardError => e
      run&.fail!(error: e.message)
    end
  end
end
