# frozen_string_literal: true

module SolidAgents
  class SchedulesController < ApplicationController
    def index
      @schedules = Schedule.order(:key)
    end

    def create
      @schedule = Schedule.new(schedule_params)
      if @schedule.save
        redirect_to schedules_path, notice: "Schedule created."
      else
        render :index, status: :unprocessable_entity
      end
    end

    def edit
      @schedule = Schedule.find(params[:id])
    end

    def update
      @schedule = Schedule.find(params[:id])
      if @schedule.update(schedule_params)
        redirect_to schedules_path, notice: "Schedule updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @schedule = Schedule.find(params[:id])
      @schedule.destroy!
      redirect_to schedules_path, notice: "Schedule removed."
    end

    private

    def schedule_params
      params.require(:schedule).permit(:key, :cron, :prompt, :model, :enabled)
    end
  end
end
