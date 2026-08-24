require "json"
require "google/apis/merchantapi_products_v1beta"
require "googleauth"
require "stringio"

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
