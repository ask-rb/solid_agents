# frozen_string_literal: true

module SolidAgents
  class RunJob < ActiveJob::Base
    queue_as :default

    def perform(run_id)
      run = Run.find(run_id)
      return unless run.queued?

      run.update!(status: :running, started_at: Time.current)
      run.append_event!("run_started", message: "Run started")

      response = SolidAgents.conductor_session.run(run.prompt.to_s)
      run.complete!(output: response)
    rescue StandardError => e
      run.fail!(error: e.message) if run.present?
    end
  end
end
