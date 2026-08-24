module GoogleMerchant
  class Config
    CONTENT_READONLY_SCOPE = "https://www.googleapis.com/auth/content.readonly".freeze
    CONTENT_SCOPE = "https://www.googleapis.com/auth/content".freeze

    DEFAULT_CHANNEL = "online".freeze
    DEFAULT_CONTENT_LANGUAGE = "en".freeze
    DEFAULT_FEED_LABEL = "US".freeze

    attr_reader :service_account_json, :merchant_id, :data_source,
                :channel, :content_language, :feed_label

    def initialize(env: ENV)
      @service_account_json = env["GOOGLE_SHOPPING_SERVICE_ACCOUNT"]
      @merchant_id = (env["GOOGLE_MERCHANT_ID"] || derive_merchant_id).to_s
      @data_source = env["GOOGLE_SHOPPING_DATA_SOURCE"] || env["GOOGLE_MERCHANT_DATA_SOURCE"]
      @channel = env.fetch("GOOGLE_MERCHANT_CHANNEL", DEFAULT_CHANNEL)
      @content_language = env.fetch("GOOGLE_MERCHANT_CONTENT_LANGUAGE", DEFAULT_CONTENT_LANGUAGE)
      @feed_label = env["GOOGLE_MERCHANT_FEED_LABEL"] ||
                    env["GOOGLE_SHOPPING_COUNTRY"] || DEFAULT_FEED_LABEL
    end

    def accounts_root
      "accounts/#{merchant_id}"
    end

    def data_source_name
      return data_source if data_source.to_s.match?(%r{\Aaccounts/})
      "#{accounts_root}/dataSources/#{data_source}" if data_source
    end

    def require_service_account!
      if service_account_json.to_s.empty?
        raise ConfigurationError, "GOOGLE_SHOPPING_SERVICE_ACCOUNT is not set"
      end
      true
    end

    def require_data_source!
      return true if data_source_name
      raise ConfigurationError, "GOOGLE_SHOPPING_DATA_SOURCE must be configured for product writes"
    end

    private

    def derive_merchant_id
      raise ConfigurationError, "GOOGLE_SHOPPING_SERVICE_ACCOUNT is not set" if service_account_json.to_s.empty?

      project_id = JSON.parse(service_account_json)["project_id"]
      mca_id = project_id.to_s.match(/\Amerchant-center-(\d+)\z/)&.captures&.first
      return mca_id if mca_id

      raise ConfigurationError,
            "GOOGLE_MERCHANT_ID is not set and could not be derived from the service account"
    rescue JSON::ParserError
      raise ConfigurationError, "GOOGLE_SHOPPING_SERVICE_ACCOUNT is not valid JSON"
    end
  end
end
