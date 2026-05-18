# frozen_string_literal: true

module SolidAgents
  module Tools
    class ReadModel < Base
      description "Introspects a Rails model — associations, validations, scopes, enums, columns."

      param :name, type: "string", desc: "Model class name (e.g. 'User', 'Account::Billing')", required: true

      def execute(name:)
        klass = name.safe_constantize
        unless klass && klass < ActiveRecord::Base
          return { error: "Model '#{name}' not found or is not an ActiveRecord model" }
        end

        {
          name: klass.name,
          table_name: klass.table_name,
          primary_key: klass.primary_key,
          columns: klass.columns.map { |c|
            { name: c.name, type: c.type, null: c.null, default: c.default }
          },
          associations: klass.reflect_on_all_associations.map { |a|
            { type: a.macro, name: a.name, class_name: a.class_name, through: a.options[:through], source: a.options[:source] }
          },
          scopes: extract_scopes(klass),
          enums: extract_enums(klass),
          validations: klass.validators.map { |v|
            { type: v.class.name.demodulize, attributes: v.attributes, options: v.options.except(:on) }
          },
          callbacks: extract_callbacks(klass)
        }
      end

      private

      def extract_scopes(klass)
        klass.methods(false).each_with_object([]) do |method, scopes|
          next unless method.to_s.ends_with?("_scope") || klass.respond_to?(method) && klass.try(:scopes)&.key?(method)

          scopes << method
        end
      end

      def extract_enums(klass)
        return {} unless klass.respond_to?(:defined_enums)

        klass.defined_enums.transform_values(&:keys)
      end

      def extract_callbacks(klass)
        %i[before_validation after_validation before_save after_save before_create after_create before_update after_update before_destroy after_destroy after_commit].each_with_object([]) do |callback, result|
          result << callback if klass.respond_to?(:"_#{callback}_callbacks") && klass.send(:"_#{callback}_callbacks").any?
        end
      end
    end
  end
end
