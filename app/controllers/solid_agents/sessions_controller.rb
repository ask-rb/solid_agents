# frozen_string_literal: true

module SolidAgents
  class SessionsController < ApplicationController
    def index
      @sessions = Run.sessions.recent
    end

    def show
      @session = Run.find(params[:id])
    end

    def create
      @session = Run.new(
        source_type: "chat_session",
        external_key: SecureRandom.uuid,
        environment: Rails.env,
        status: :queued,
        prompt: params[:message]
      )
      @session.save!
      redirect_to session_path(@session), notice: "Session created."
    end

    def destroy
      @session = Run.find(params[:id])
      @session.update!(status: :canceled)
      redirect_to sessions_path, notice: "Session canceled."
    end
  end
end
