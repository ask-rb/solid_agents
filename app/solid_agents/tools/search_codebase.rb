# frozen_string_literal: true

module SolidAgents
  module Tools
    class SearchCodebase < Base
      description "Search the codebase for files matching a pattern or containing specific terms. Uses ripgrep when available."

      param :term, type: "string", desc: "Search term (plain text or regex)", required: true
      param :path, type: "string", desc: "Scope search to a subdirectory (e.g. 'app/models', 'app/controllers')", required: false
      param :extension, type: "string", desc: "Filter by file extension (e.g. 'rb', 'erb')", required: false
      param :max_results, type: "integer", desc: "Maximum results to return", required: false

      def execute(term:, path: nil, extension: nil, max_results: 30)
        root = Rails.root
        dir = path ? root.join(path) : root
        return { error: "Directory not found" } unless dir.exist?

        results = if system("which rg > /dev/null 2>&1")
          search_with_rg(dir, term, extension, max_results)
        else
          search_with_grep(dir, term, extension, max_results)
        end

        { count: results.size, results: results }
      end

      private

      def search_with_rg(dir, term, ext, max)
        cmd = ["rg", "--no-heading", "--line-number", "--max-count", "3", "-i", term.to_s, dir.to_s]
        cmd.concat ["--type-add", "ruby:*.{rb,rake}", "--type", "ruby"] if ext == "rb"
        cmd.concat ["--glob", "*.{#{ext}}"] if ext
        cmd.concat ["--max-files", max.to_s] if max

        `#{Shellwords.join(cmd)}`.lines.first(max).map { |l| l.chomp.split(":", 3).then { |parts| { file: parts[0], line: parts[1].to_i, match: parts[2]&.strip } } }
      end

      def search_with_grep(dir, term, ext, max)
        Dir.glob("#{dir}/**/*.#{ext || '{rb,erb,js,css,yml}'}").each_with_object([]) do |file, results|
          next if File.directory?(file) || file.include?("vendor/")
          next if results.size >= max

          File.readlines(file).each_with_index do |line, idx|
            break if results.size >= max
            next unless line.downcase.include?(term.downcase)

            results << { file: file.sub("#{Rails.root}/", ""), line: idx + 1, match: line.strip }
          end
        end
      end
    end
  end
end
