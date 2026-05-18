# frozen_string_literal: true

ActiveRecord::Schema[7.1].define do
  create_table :solid_agents_runs, force: :cascade do |t|
    t.string :external_key
    t.string :source_type, null: false
    t.bigint :source_id
    t.string :status, null: false, default: "queued"
    t.string :runtime, null: false, default: "ruby_llm"
    t.string :environment, null: false
    t.string :repo_path
    t.string :base_branch
    t.string :work_branch
    t.string :commit_sha
    t.string :pr_url
    t.integer :pr_number
    t.integer :attempt_count, null: false, default: 0
    t.text :prompt
    t.text :output
    t.json :prompt_payload, default: {}
    t.json :result_payload, default: {}
    t.json :error_payload, default: {}
    t.datetime :started_at
    t.datetime :finished_at
    t.timestamps
  end

  add_index :solid_agents_runs, :external_key, unique: true
  add_index :solid_agents_runs, :status
  add_index :solid_agents_runs, [:source_type, :source_id]

  create_table :solid_agents_run_events, force: :cascade do |t|
    t.references :run, null: false, foreign_key: {to_table: :solid_agents_runs}
    t.string :event_type, null: false
    t.datetime :event_time, null: false
    t.text :message, null: false
    t.string :actor
    t.json :payload, default: {}
    t.integer :sequence, null: false
    t.timestamps
  end

  add_index :solid_agents_run_events, [:run_id, :sequence], unique: true
  add_index :solid_agents_run_events, :event_type

  create_table :solid_agents_artifacts, force: :cascade do |t|
    t.references :run, null: false, foreign_key: {to_table: :solid_agents_runs}
    t.string :kind, null: false
    t.string :label
    t.string :storage_type, null: false
    t.text :content_text
    t.json :content_json, default: {}
    t.timestamps
  end

  add_index :solid_agents_artifacts, :kind

  create_table :solid_agents_schedules, force: :cascade do |t|
    t.string :key, null: false
    t.string :cron, null: false
    t.text :prompt, null: false
    t.string :model
    t.boolean :enabled, null: false, default: true
    t.timestamps
  end

  add_index :solid_agents_schedules, :key, unique: true

  create_table :solid_agents_configs, force: :cascade do |t|
    t.string :key, null: false
    t.string :environment
    t.json :value_json, default: {}
    t.timestamps
  end

  add_index :solid_agents_configs, [:key, :environment], unique: true
end
