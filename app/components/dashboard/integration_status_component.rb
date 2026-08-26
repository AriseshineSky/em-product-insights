# frozen_string_literal: true

module Dashboard
  class IntegrationStatusComponent < ViewComponent::Base
    attr_reader :integrations

    def initialize(integrations:)
      @integrations = integrations
    end

    def self.default_integrations
      [
        { name: "Google Merchant", configured: true, icon: "green" },
        { name: "BigQuery", configured: ENV["GOOGLE_CLOUD_PROJECT"].present?, icon: "gray" },
        { name: "Spree API", configured: ENV["SPREE_API_ENDPOINT"].present?, icon: "gray" }
      ]
    end
  end
end
