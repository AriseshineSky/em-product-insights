module BigQuery
  class Client
    attr_reader :config

    def initialize(config: BigQuery.config)
      @config = config
    end

    def client
      @client ||= build_client
    end

    def query(sql, maximum_bytes_billed: config.maximum_bytes_billed)
      config.require_config!
      job = client.query_job(sql, maximum_bytes_billed: maximum_bytes_billed)
      job.wait_until_done!
      raise_failed_job!(job, sql)

      rows(job)
    end

    def estimate(sql)
      config.require_config!
      job = client.query_job(sql, dryrun: true)
      job.wait_until_done!

      bytes = job.bytes_processed.to_i
      {
        bytes: bytes,
        gib: bytes.to_f / (1024**3),
        tib: bytes.to_f / (1024**4),
        estimated_cost: bytes.to_f / (1024**4) * config.price_per_tib,
        cache_hit: job.cache_hit?,
        maximum_bytes_billed: config.maximum_bytes_billed
      }
    end

    private

    def build_client
      config.require_config!

      Google::Cloud::Bigquery.new(
        project: config.project,
        credentials: JSON.parse(config.service_account_json)
      )
    rescue JSON::ParserError
      raise ConfigurationError, "GOOGLE_SHOPPING_SERVICE_ACCOUNT is not valid JSON"
    end

    def raise_failed_job!(job, sql)
      return unless job.failed?

      detail = job.errors&.map { |e| e[:message] }.compact.join("; ")
      message = +"BigQuery query failed"
      message << ": #{detail}" if detail.present?
      message << " (sql: #{sql[0, 200]}...)"
      raise QueryError, message
    end

    def rows(job)
      job.data.each_with_object([]) do |row, acc|
        acc << Hash[row.map { |key, value| [ key.to_s, value ] }]
      end
    end
  end
end
