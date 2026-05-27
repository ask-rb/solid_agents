# frozen_string_literal: true

module SolidAgents
  module Tools
    class ReadFile < Base
      description "Read a file from the application codebase."

      param :path, type: "string", desc: "File path relative to Rails root (e.g. 'app/models/user.rb')", required: true
      param :lines, type: "integer", desc: "Number of lines to read", required: false
      param :offset, type: "integer", desc: "Starting line (1-indexed)", required: false

      def execute(path:, lines: nil, offset: 1)
        full = Rails.root.join(path)
        return { error: "File not found: #{path}" } unless full.exist?
        return { error: "Path is a directory" } if full.directory?
        return { error: "File is outside Rails root" } unless full.to_s.start_with?(Rails.root.to_s)

        content = full.readlines

        sliced = if lines
          content[offset - 1, lines]
        else
          content
        end

        {
          path: path,
          size: full.size,
          lines: sliced.map.with_index(offset) { |line, i| { line: i, content: line.chomp } }
        }
      end
    end
  end
end
