module ProductAudit
  # Deletes merchant products identified by a BigQuery issue query.
  #   A dry-run estimate gates execution: auto-runs only when the estimated
  #   query stays under the configured threshold (1 GiB by default).
  #   Above it the caller must pass force: true after manual review.
  class MerchantProductCleanup
    DEFAULT_MAX_ESTIMATED_BYTES = 1 * 1024**3

    Result = Struct.new(:issue_code, :estimated_bytes, :auto_run, :offer_count,
                        :deleted_count, :already_gone_count, :errors,
                        keyword_init: true) do
      def needs_review?
        !auto_run
      end

      def summary
        { issue_code: issue_code, estimated_bytes: estimated_bytes,
          auto_run: auto_run, offers: offer_count, deleted: deleted_count,
          already_gone: already_gone_count, errors: errors.size }
      end
    end

    attr_reader :issue_code, :max_estimated_bytes, :issues, :merchant_service

    # @param issues [#estimate, #offer_ids] BigQuery adapter
    # @param merchant_service [#delete] the merchant integration adapter
    def initialize(issue_code: MerchantIssues::DEFAULT_ISSUE_CODE,
                   max_estimated_bytes: DEFAULT_MAX_ESTIMATED_BYTES,
                   issues: MerchantIssues.new,
                   merchant_service: GoogleMerchant::ProductService.new)
      @issue_code = issue_code
      @max_estimated_bytes = max_estimated_bytes
      @issues = issues
      @merchant_service = merchant_service
    end

    def run(force: false, limit: nil)
      estimate = issues.estimate(issue_code: issue_code)

      return review_result(estimate) if estimate[:bytes] > max_estimated_bytes && !force

      offer_ids = issues.offer_ids(issue_code: issue_code, limit: limit,
                                   maximum_bytes_billed: billed_cap(estimate))
      delete_offers(offer_ids, auto_run: true, estimate: estimate)
    end

    private

    def billed_cap(estimate)
      [estimate[:maximum_bytes_billed].to_i, max_estimated_bytes].min
    end

    def review_result(estimate)
      Result.new(issue_code: issue_code, estimated_bytes: estimate[:bytes], auto_run: false,
                 offer_count: 0, deleted_count: 0, already_gone_count: 0, errors: [])
    end

    def delete_offers(offer_ids, auto_run:, estimate:)
      deleted = 0
      already_gone = 0
      errors = []

      offer_ids.each do |offer_id|
        deleted, already_gone = record_delete(offer_id, deleted, already_gone, errors)
      end

      Result.new(issue_code: issue_code, estimated_bytes: estimate[:bytes], auto_run: auto_run,
                 offer_count: offer_ids.length, deleted_count: deleted,
                 already_gone_count: already_gone, errors: errors)
    end

    def record_delete(offer_id, deleted, already_gone, errors)
      merchant_service.delete(offer_id: offer_id)
      [ deleted + 1, already_gone ]
    rescue GoogleMerchant::NotFoundError
      [ deleted, already_gone + 1 ]
    rescue GoogleMerchant::Error => e
      errors << { offer_id: offer_id, error: e.message }
      [ deleted, already_gone ]
    end
  end
end