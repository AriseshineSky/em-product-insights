require "json"
require "net/http"
require "uri"

module SpreeApi
  class << self
    def config
      @config ||= Config.new
    end

    attr_writer :config
  end
end

require_relative "spree_api/errors"
require_relative "spree_api/config"
require_relative "spree_api/client"
