# frozen_string_literal: true

module SolidAgents
  module Tools
    class RunCommand < Base
      description "Run a shell command in a sandboxed environment. Useful for running tests, linters, generators."

      param :command, type: "string", desc: "Command to run", required: true
      param :timeout, type: "integer", desc: "Timeout in seconds", required: false
      param :workdir, type: "string", desc: "Working directory relative to Rails root", required: false

      def execute(command:, timeout: 30, workdir: nil)
        dir = workdir ? Rails.root.join(workdir) : Rails.root
        output, error, status = Open3.capture3(
          { "RAILS_ENV" => Rails.env }, command,
          chdir: dir.to_s,
          timeout: timeout
        )

        {
          exit_code: status.exitstatus,
          stdout: output.truncate(5000),
          stderr: error.truncate(2000)
        }
      end
    end
  end
end
