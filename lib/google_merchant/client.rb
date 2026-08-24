module GoogleMerchant
  class Client
    attr_reader :config

    def initialize(config: GoogleMerchant.config)
      @config = config
    end

    def api
      @api ||= build_api
    end

    def get_product(name)
      with_error_handling { api.get_account_product(name) }
    end

    def list_products(page_size: nil, page_token: nil)
      with_error_handling do
        api.list_account_products(config.accounts_root, page_size: page_size, page_token: page_token)
      end
    end

    def insert_product(parent, product_input, data_source:)
      with_error_handling do
        api.insert_account_product_input(parent, product_input, data_source: data_source)
      end
    end

    def update_product(name, product_input, data_source:, update_mask:)
      with_error_handling do
        api.patch_account_product_input(
          name, product_input, data_source: data_source, update_mask: update_mask
        )
      end
    end

    def delete_product(name, data_source:)
      with_error_handling { api.delete_account_product_input(name, data_source: data_source) }
    end

    private

    def build_api
      config.require_service_account!

      api = Google::Apis::MerchantapiProductsV1beta::MerchantService.new
      api.authorization = credentials
      api
    end

    def credentials
      key_io = StringIO.new(config.service_account_json)
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: key_io,
        scope: Config::CONTENT_SCOPE
      )
    end

    def with_error_handling
      yield
    rescue Google::Apis::AuthorizationError, Signet::AuthorizationError => e
      raise AuthenticationError, "Merchant API authentication failed: #{e.message}"
    rescue Google::Apis::ClientError => e
      raise NotFoundError, e.message if e.status_code == 404
      raise RequestError, e.message
    rescue Google::Apis::ServerError, Google::Apis::TransmissionError, Google::Apis::RateLimitError => e
      raise RequestError, e.message
    end
  end
end
