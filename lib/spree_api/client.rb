require "json"
require "net/http"
require "uri"

module SpreeApi
  class Client
    RETRYABLE_STATUSES = [ 429, 500, 502, 503, 504 ].freeze
    MAX_ATTEMPTS = 6
    BACKOFF_FACTOR = 10.0

    attr_reader :config

    def initialize(config: SpreeApi.config)
      @config = config
    end

    def delete_products(product_ids)
      config.require_config!
      path = "/api/#{config.api_version}/products/batch_delete"
      request(:post, path, params: { token: config.api_key },
                           json: { product_ids: Array(product_ids).join(",") })
    end

    def get_shop
      config.require_config!
      response = request(:get, "/api/v1/stores", params: { token: config.api_key })
      stores = response.is_a?(Hash) ? response["stores"] : nil
      return if stores.nil? || stores.empty?

      default = stores.find { |store| store["default"] }
      default || stores.first
    end

    private

    def request(method, path, params: {}, json: nil)
      attempts = 0
      loop do
        attempts += 1
        response = perform_request(method, path, params: params, json: json)

        if retryable?(response, attempts)
          sleep(backoff(attempts))
          next
        end

        return parse(response)
      end
    end

    def perform_request(method, path, params: {}, json: nil)
      uri = build_uri(path, params)
      http_client = Net::HTTP.new(uri.host, uri.port)
      http_client.use_ssl = uri.scheme == "https"
      http_client.open_timeout = 10
      http_client.read_timeout = 30

      request_object = build_request(method, uri, json)
      http_client.request(request_object)
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET,
           SocketError, OpenSSL::SSL::SSLError => e
      raise RequestError, "Spree API request to #{uri} failed: #{e.class}: #{e.message}"
    end

    def build_request(method, uri, json)
      klass = Net::HTTP::Get if method == :get
      klass ||= Net::HTTP::Post if method == :post
      klass ||= Net::HTTP::Put if method == :put
      klass ||= Net::HTTP::Delete if method == :delete
      raise ArgumentError, "unsupported method #{method}" if klass.nil?

      request_object = klass.new(uri)
      if json
        request_object["Content-Type"] = "application/json"
        request_object["Accept"] = "application/json"
        request_object.body = JSON.generate(json)
      end
      request_object
    end

    def build_uri(path, params)
      uri = URI.parse("#{config.endpoint.chomp('/')}#{path}")
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri
    end

    def retryable?(response, attempts)
      RETRYABLE_STATUSES.include?(response.code.to_i) && attempts < MAX_ATTEMPTS
    end

    def backoff(attempt)
      BACKOFF_FACTOR * (2**(attempt - 1))
    end

    def parse(response)
      return nil if response.body.nil? || response.body.empty?

      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end
end
