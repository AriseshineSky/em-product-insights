module BigQuery
  class Config
    DEFAULT_MAXIMUM_BYTES_BILLED = 10 * 1024**3
    DEFAULT_PRICE_PER_TIB = 6.25
    DEFAULT_DATASET = "google_merchant_center".freeze

    attr_reader :project, :service_account_json, :merchant_id, :dataset,
                :maximum_bytes_billed, :price_per_tib

    def initialize(env: ENV)
      @project = env["GOOGLE_CLOUD_PROJECT"] || env["GCS_PROJECT_ID"]
      @service_account_json = env["GOOGLE_SHOPPING_SERVICE_ACCOUNT"]
      @merchant_id = env["GOOGLE_MERCHANT_ID"]
      @dataset = env.fetch("GOOGLE_BIGQUERY_DATASET", DEFAULT_DATASET)
      @maximum_bytes_billed = (env["GOOGLE_BIGQUERY_MAXIMUM_BYTES_BILLED"] ||
                               DEFAULT_MAXIMUM_BYTES_BILLED).to_i
      @price_per_tib = (env["GOOGLE_BIGQUERY_PRICE_PER_TIB"] || DEFAULT_PRICE_PER_TIB).to_f
    end

    def require_config!
      missing = []
      missing << "GOOGLE_CLOUD_PROJECT" if project.to_s.empty?
      missing << "GOOGLE_SHOPPING_SERVICE_ACCOUNT" if service_account_json.to_s.empty?
      missing << "GOOGLE_MERCHANT_ID" if merchant_id.to_s.empty?
      raise ConfigurationError, "Missing configuration: #{missing.join(', ')}" unless missing.empty?

      true
    end
  end
end
