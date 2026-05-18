# frozen_string_literal: true

module SolidAgents
  module Tools
    class QueryDatabase < Base
      description "Run a SQL query against the database. Read-only in production. Returns rows or error."

      param :sql, type: "string", desc: "SQL query to execute", required: true
      param :limit, type: "integer", desc: "Max rows to return", required: false

      def execute(sql:, limit: 50)
        if Rails.env.production? && !sql.match?(/\A\s*SELECT\b/i)
          return { error: "Only SELECT queries are allowed in production", sql: sql }
        end

        pool = ActiveRecord::Base.connection_pool
        pool.with_connection do |conn|
          result = conn.execute(conn.sanitize_limit(sql, limit))
          columns = result.fields
          rows = result.to_a.first(limit)
          { columns: columns, rows: rows, count: rows.size }
        end
      rescue ActiveRecord::StatementInvalid => e
        { error: e.message, sql: sql }
      end
    end
  end
end
