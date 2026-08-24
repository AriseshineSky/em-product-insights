require "json"
require "google/shopping/merchant/products/v1"

module GoogleMerchant
  class << self
    def config
      @config ||= Config.new
    end

    attr_writer :config
  end
end

require_relative "google_merchant/errors"
require_relative "google_merchant/config"
require_relative "google_merchant/client"
require_relative "google_merchant/product_service"
require_relative "google_merchant/cyp_status_report"
