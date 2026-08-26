module SpreeApi
  class Config
    attr_reader :endpoint, :api_key, :api_version

    def initialize(env: ENV)
      @endpoint = env["SPREE_API_ENDPOINT"]
      @api_key = env["SPREE_API_KEY"]
      @api_version = env.fetch("SPREE_API_VERSION", "v1")
    end

    def require_config!
      missing = []
      missing << "SPREE_API_ENDPOINT" if endpoint.to_s.empty?
      missing << "SPREE_API_KEY" if api_key.to_s.empty?
      raise ConfigurationError, "Missing configuration: #{missing.join(', ')}" unless missing.empty?

      true
    end
  end
end
