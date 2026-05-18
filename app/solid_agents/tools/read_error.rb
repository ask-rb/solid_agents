# frozen_string_literal: true

module SolidAgents
  module Tools
    class ReadError < Base
      description "Reads errors from the application's error tracker. Supports solid_errors, or inspects latest error by fingerprint."

      param :id, type: "integer", desc: "Error record ID", required: false
      param :fingerprint, type: "string", desc: "Error fingerprint to search for", required: false
      param :limit, type: "integer", desc: "Number of recent errors to return", required: false

      def execute(id: nil, fingerprint: nil, limit: 5)
        if defined?(SolidErrors::Error)
          errors = SolidErrors::Error.order(created_at: :desc)
          errors = errors.where(id: id) if id
          errors = errors.where(fingerprint: fingerprint) if fingerprint
          errors = errors.limit(limit)

          errors.map { |e|
            {
              id: e.id,
              exception_class: e.exception_class,
              message: e.message&.truncate(200),
              fingerprint: e.fingerprint,
              backtrace: e.backtrace&.lines&.first(10)&.join("\n"),
              occurred_at: e.created_at,
              context: e.context&.slice("params", "method", "path", "ip")
            }
          }
        else
          { info: "solid_errors gem not detected. Install it to track and inspect application errors." }
        end
      end
    end
  end
end
