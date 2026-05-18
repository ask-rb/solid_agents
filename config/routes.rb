# frozen_string_literal: true

SolidAgents::Engine.routes.draw do
  resources :sessions, only: %i[index show create destroy], controller: :runs do
    collection do
      post :ask
    end
  end

  resources :runs, only: %i[index show] do
    member do
      post :retry
    end
  end

  resources :schedules, only: %i[index create edit update destroy]

  root to: "sessions#index"
end
