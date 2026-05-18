# frozen_string_literal: true

module SolidAgents
  class Record < ActiveRecord::Base
    self.abstract_class = true

    if SolidAgents.respond_to?(:connects_to) && SolidAgents.connects_to.present?
      connects_to(**SolidAgents.connects_to)
    end
  end
end

ActiveSupport.run_load_hooks :solid_agents_record, SolidAgents::Record
