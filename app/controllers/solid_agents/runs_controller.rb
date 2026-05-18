# frozen_string_literal: true

module SolidAgents
  class RunsController < ApplicationController
    def index
      @runs = Run.recent
    end

    def show
      @run = Run.find(params[:id])
      @events = @run.events.order(sequence: :asc)
      @artifacts = @run.artifacts.order(created_at: :desc)
    end

    def retry
      @run = Run.find(params[:id])
      duplicated = @run.dup
      duplicated.status = :queued
      duplicated.started_at = nil
      duplicated.finished_at = nil
      duplicated.error_payload = nil
      duplicated.result_payload = nil
      duplicated.external_key = "retry-#{@run.id}-#{Time.current.to_i}"
      duplicated.save!
      duplicated.append_event!("retried", message: "Run retried from ##{@run.id}")
      RunJob.perform_later(duplicated.id)
      redirect_to run_path(duplicated), notice: "Run retried."
    end

    def create
      @run = Run.new(run_params)
      @run.external_key = SecureRandom.uuid
      @run.environment = Rails.env
      @run.save!
      RunJob.perform_later(@run.id)
      redirect_to run_path(@run), notice: "Run created."
    end

    def ask
      @run = Run.new(
        source_type: "chat_session",
        external_key: SecureRandom.uuid,
        environment: Rails.env,
        status: :queued,
        prompt: params[:message]
      )
      @run.save!

      response = SolidAgents.conductor_session.run(params[:message])
      @run.complete!(output: response)
      redirect_to session_path(@run)
    end

    private

    def run_params
      params.require(:run).permit(:source_type, :source_id, :prompt, :repo_path, :base_branch)
    end
  end
end
