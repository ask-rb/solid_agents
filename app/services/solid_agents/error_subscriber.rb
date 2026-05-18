# frozen_string_literal: true

module SolidAgents
  class ErrorSubscriber
    def report(error, handled:, severity:, context:, source: nil)
      return unless SolidAgents.auto_fix_enabled
      return if severity == :info

      SolidAgents::Run.create!(
        source_type: "solid_errors",
        source_id: nil,
        external_key: SecureRandom.uuid,
        environment: Rails.env,
        status: :queued,
        prompt: build_prompt(error, context),
        prompt_payload: {
          exception_class: error.class.name,
          message: error.message.truncate(500),
          severity: severity,
          source: source,
          backtrace: error.backtrace&.first(20),
          context: context
        },
        repo_path: Rails.root.to_s,
        base_branch: "main"
      ).tap do |run|
        SolidAgents::RunJob.perform_later(run.id)
      end
    rescue StandardError => e
      Rails.logger.warn "[SolidAgents] Error subscriber failed: #{e.message}"
    end

    private

    def build_prompt(error, context)
      <<~PROMPT
        A #{error.class.name} occurred in #{Rails.env}:

        #{error.message}

        Analyze this error and:
        1. Identify the root cause from the backtrace
        2. Find the relevant source code
        3. Propose a fix
        4. If confident, create a pull request with the fix

        Backtrace:
        #{error.backtrace&.first(10)&.join("\n")}
      PROMPT
    end
  end
end
