# frozen_string_literal: true

module SolidAgents
  module Tools
    class ReadSchema < Base
      description "Returns the current database schema — tables, columns, types, indexes."

      param :table, type: "string", desc: "Optional table name to inspect", required: false

      def execute(table: nil)
        pool = ActiveRecord::Base.connection_pool
        pool.with_connection do |conn|
          tables = if table
            Array.wrap(table)
          else
            conn.tables.sort - %w[schema_migrations ar_internal_metadata]
          end

          tables.map do |t|
            columns = conn.columns(t).map { |c|
              { name: c.name, type: c.type, null: c.null, default: c.default, sql_type: c.sql_type }
            }

            indexes = conn.indexes(t).map { |i|
              { name: i.name, columns: i.columns, unique: i.unique }
            }

            { table: t, columns: columns, indexes: indexes }
          end
        end
      end
    end
  end
end
