module ProductAudit
  class MerchantIssues
    DEFAULT_ISSUE_CODE = "landing_page_error".freeze
    DEFAULT_DATASET = "google_merchant_center".freeze

    attr_reader :config, :client

    # @param client [#query, #estimate] BigQuery adapter
    def initialize(config: BigQuery.config, client: BigQuery::Client.new(config: config))
      @config = config
      @client = client
    end

    def estimate(issue_code: DEFAULT_ISSUE_CODE)
      client.estimate(products_issues_sql(issue_code: issue_code))
    end

    def offer_ids(issue_code: DEFAULT_ISSUE_CODE, limit: nil,
                  maximum_bytes_billed: config.maximum_bytes_billed)
      rows = client.query(products_issues_sql(issue_code: issue_code, limit: limit),
                          maximum_bytes_billed: maximum_bytes_billed)
      rows.map { |row| (row["offer_id"] || row[:offer_id]).to_s }
    end

    def products_issues_sql(issue_code:, limit: nil)
      sql = <<~SQL
        SELECT p.offer_id
        FROM #{table_ref} p,
        UNNEST(p.issues) AS issue
        WHERE _PARTITIONDATE = CURRENT_DATE()
          AND issue.code = '#{issue_code}'
      SQL
      sql += "LIMIT #{limit.to_i}\n" if limit
      sql
    end

    def table_ref
      "`#{config.project}.#{config.dataset}.Products_#{config.merchant_id}`"
    end
  end
end
