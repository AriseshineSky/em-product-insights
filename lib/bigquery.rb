require "json"
require "google/cloud/bigquery"

module BigQuery
  class << self
    def config
      @config ||= Config.new
    end

    attr_writer :config
  end
end

require_relative "bigquery/errors"
require_relative "bigquery/config"
require_relative "bigquery/client"
