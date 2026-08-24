require "google/shopping/merchant/products/v1"

module GoogleMerchant
  class Client
    V1 = Google::Shopping::Merchant::Products::V1

    attr_reader :config

    def initialize(config: GoogleMerchant.config)
      @config = config
    end

    def products_api
      @products_api ||= build_client(V1::ProductsService::Rest::Client)
    end

    def product_inputs_api
      @product_inputs_api ||= build_client(V1::ProductInputsService::Rest::Client)
    end

    def get_product(name)
      with_error_handling do
        products_api.get_product(V1::GetProductRequest.new(name: name))
      end
    end

    def list_products(page_size: nil, page_token: nil)
      with_error_handling do
        products_api.list_products(
          V1::ListProductsRequest.new(
            parent: config.accounts_root, page_size: page_size, page_token: page_token
          )
        )
      end
    end

    def insert_product(parent, product_input, data_source:)
      with_error_handling do
        product_inputs_api.insert_product_input(
          V1::InsertProductInputRequest.new(
            parent: parent, product_input: product_input, data_source: data_source
          )
        )
      end
    end

    def update_product(product_input, data_source:, update_mask:)
      with_error_handling do
        product_inputs_api.update_product_input(
          V1::UpdateProductInputRequest.new(
            product_input: product_input, update_mask: update_mask, data_source: data_source
          )
        )
      end
    end

    def delete_product(name, data_source:)
      with_error_handling do
        product_inputs_api.delete_product_input(
          V1::DeleteProductInputRequest.new(name: name, data_source: data_source)
        )
      end
    end

    private

    def build_client(klass)
      config.require_service_account!

      klass.new do |client_config|
        client_config.credentials = JSON.parse(config.service_account_json)
        client_config.scope = Config::CONTENT_SCOPE
      end
    end

    def with_error_handling
      yield
    rescue Google::Cloud::UnauthenticatedError, Google::Cloud::PermissionDeniedError => e
      raise AuthenticationError, "Merchant API authentication failed: #{e.message}"
    rescue Google::Cloud::NotFoundError => e
      raise NotFoundError, e.message
    rescue Google::Cloud::Error => e
      raise RequestError, e.message
    end
  end
end
