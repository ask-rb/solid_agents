# frozen_string_literal: true

module SolidAgents
  module Tools
    class ReadRoute < Base
      description "Lists Rails routes matching a pattern, or returns all routes."

      param :pattern, type: "string", desc: "Route path or controller pattern to filter by (e.g. 'cards', 'api/*')", required: false
      param :verbose, type: "boolean", desc: "Show full route details", required: false

      def execute(pattern: nil, verbose: false)
        all_routes = Rails.application.routes.routes.map do |route|
          path = route.path.spec.to_s.sub(/\(\.:format\)\z/, "")
          reqs = route.defaults
          {
            verb: route.verb.is_a?(Regexp) ? route.verb.source.gsub(/[$^]/, "") : route.verb.to_s,
            path: path,
            controller: reqs[:controller],
            action: reqs[:action],
            name: route.name
          }
        end

        filtered = if pattern
          all_routes.select { |r|
            r[:path].include?(pattern) || r[:controller]&.include?(pattern)
          }
        else
          all_routes
        end

        if verbose
          filtered
        else
          filtered.map { |r| "#{r[:verb].ljust(7)} #{r[:path]} → #{r[:controller]}##{r[:action]}" }.join("\n")
        end
      end
    end
  end
end
