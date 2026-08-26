# frozen_string_literal: true

module Dashboard
  class QuickActionsComponent < ViewComponent::Base
    MODIFIERS = {
      primary: "bg-primary text-primary-foreground hover:bg-primary/90",
      outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground"
    }.freeze

    BASE_CLASSES = "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm " \
                   "font-medium ring-offset-background transition-colors focus-visible:outline-none " \
                   "focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 h-9 px-4 py-2"

    attr_reader :actions

    def initialize(actions: [])
      @actions = actions
    end

    def button_classes(variant)
      "#{BASE_CLASSES} #{MODIFIERS.fetch(variant, MODIFIERS[:outline])}"
    end
  end
end
