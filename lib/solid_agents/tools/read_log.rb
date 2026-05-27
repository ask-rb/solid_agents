# frozen_string_literal: true

module SolidAgents
  module Tools
    class ReadLog < Base
      description "Reads application logs from the current environment. Supports file-based logs in development, Kamal logs in production."

      param :query, type: "string", desc: "Filter term (grep)", required: false
      param :lines, type: "integer", desc: "Number of lines to read", required: false
      param :env, type: "string", desc: "Environment (development, production)", required: false

      def execute(query: nil, lines: 50, env: nil)
        target_env = env || Rails.env

        case detect_log_source
        when :kamal
          read_kamal_logs(query:, lines:)
        when :heroku
          read_heroku_logs(query:, lines:)
        else
          read_file_logs(query:, lines:, env: target_env)
        end
      end

      private

      def detect_log_source
        if Rails.root.join("config/deploy.yml").exist?
          :kamal
        elsif ENV["HEROKU_APP_NAME"].present?
          :heroku
        else
          :file
        end
      end

      def read_kamal_logs(query:, lines:)
        cmd = "kamal app logs --lines #{lines}"
        cmd += " --grep #{Shellwords.escape(query)}" if query.present?
        `#{cmd}`.lines.last(lines).join
      rescue Errno::ENOENT
        { error: "Kamal CLI not found. Install it or use file-based logs." }
      end

      def read_heroku_logs(query:, lines:)
        app = ENV["HEROKU_APP_NAME"]
        cmd = "heroku logs --app #{app} --tail --num #{lines}"
        cmd += " --grep #{Shellwords.escape(query)}" if query.present?
        `#{cmd}`.lines.last(lines).join
      rescue Errno::ENOENT
        { error: "Heroku CLI not found." }
      end

      def read_file_logs(query:, lines:, env:)
        log_path = Rails.root.join("log/#{env}.log")
        unless log_path.exist?
          return { error: "Log file not found at #{log_path}" }
        end

        content = log_path.read
        if query.present?
          content = content.lines.select { |l| l.include?(query) }
        end
        content.lines.last(lines).join
      end
    end
  end
end
