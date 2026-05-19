# frozen_string_literal: true

module SolidAgents
  module Tools
    class WriteFile < Base
      description "Write content to a file in the application codebase. Use this to create new files or modify existing ones."

      param :path, type: "string", desc: "File path relative to Rails root (e.g. 'app/models/user.rb')", required: true
      param :content, type: "string", desc: "File content to write", required: true

      def execute(path:, content:)
        full = Rails.root.join(path)

        unless full.to_s.start_with?(Rails.root.to_s)
          return { error: "File path must be within Rails root", path: path }
        end

        FileUtils.mkdir_p(File.dirname(full))
        was_created = !full.exist?
        File.write(full, content)

        {
          path: path,
          action: was_created ? "created" : "updated",
          size: content.length
        }
      end
    end
  end
end
