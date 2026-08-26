# frozen_string_literal: true

module Dashboard
  class MetricCardComponent < ViewComponent::Base
    attr_reader :title, :description, :value

    # @param title [String] Card title
    # @param description [String] Card description
    # @param value [String, Integer] Main metric value
    def initialize(title:, description:, value:)
      @title = title
      @description = description
      @value = value
    end
  end
end
