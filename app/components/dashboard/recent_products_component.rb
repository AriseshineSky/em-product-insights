# frozen_string_literal: true

module Dashboard
  class RecentProductsComponent < ViewComponent::Base
    attr_reader :products

    def initialize(products:)
      @products = products
    end
  end
end
