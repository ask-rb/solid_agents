# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "dummy/config/environment"
require "rails/test_help"
require "solid_agents"

ActiveJob::Base.queue_adapter = :test

db_config = ActiveRecord::Base.connection_db_config
if db_config&.adapter == "sqlite3"
  db_path = db_config.database
  db_path = Rails.root.join(db_path).to_s unless File.absolute_path?(db_path)
  ActiveRecord::Base.connection_pool.disconnect!
  FileUtils.rm_f(db_path)
  ActiveRecord::Base.establish_connection
end

migration_paths = [File.expand_path("dummy/db/migrate", __dir__)]
ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(migration_paths).migrate

class ActiveSupport::TestCase
  include ActiveJob::TestHelper

  fixtures :all
end
