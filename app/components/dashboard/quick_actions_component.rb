# frozen_string_literal: true

module Dashboard
  class QuickActionsComponent < ViewComponent::Base
    attr_reader :actions

    def initialize(actions:)
      @actions = actions
    end

    def self.default_actions
      [
        { label: "View Products", path: "/dashboard/products", variant: :default }
      ]
    end
  end
end
