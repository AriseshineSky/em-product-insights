require "concurrent"

module ProductAudit
  # Deletes merchant products identified by a BigQuery issue query.
  #   A dry-run estimate gates execution: auto-runs only when the estimated
  #   query stays under the configured threshold (1 GiB by default).
  #   Above it the caller must pass force: true after manual review.
  #   Deletes run concurrently on a fixed thread pool.
  class MerchantProductCleanup
    DEFAULT_CONCURRENCY = 8
    PROGRESS_INTERVAL = 100

    Result = Struct.new(:issue_code, :estimated_bytes, :auto_run, :offer_count,
                        :deleted_count, :already_gone_count, :errors, :concurrency,
                        keyword_init: true) do
      def needs_review?
        !auto_run
      end

      def summary
        { issue_code: issue_code, estimated_bytes: estimated_bytes,
          auto_run: auto_run, offers: offer_count, deleted: deleted_count,
          already_gone: already_gone_count, errors: errors.size, concurrency: concurrency }
      end
    end

    attr_reader :issue_code, :max_estimated_bytes, :concurrency, :issues, :merchant_service

    # @param issues [#estimate, #offer_ids] BigQuery adapter
    # @param merchant_service [#delete] the merchant integration adapter
    def initialize(issue_code: MerchantIssues::DEFAULT_ISSUE_CODE,
                   max_estimated_bytes: BigQuery.config.max_estimated_bytes,
                   concurrency: DEFAULT_CONCURRENCY,
                   issues: MerchantIssues.new,
                   merchant_service: GoogleMerchant::ProductService.new)
      @issue_code = issue_code
      @max_estimated_bytes = max_estimated_bytes
      @concurrency = concurrency
      @issues = issues
      @merchant_service = merchant_service
    end

    # @param offer_ids [Array<String>] if given, skips BigQuery and deletes these directly
    def run(force: false, limit: nil, offer_ids: nil)
      estimate = issues.estimate(issue_code: issue_code)
      return review_result(estimate) if estimate[:bytes] > max_estimated_bytes && !force && offer_ids.nil?

      offer_ids ||= issues.offer_ids(issue_code: issue_code, limit: limit,
                                     maximum_bytes_billed: billed_cap(estimate))
      delete_offers(offer_ids, auto_run: true, estimate: estimate)
    end

    private

    def billed_cap(estimate)
      [estimate[:maximum_bytes_billed].to_i, max_estimated_bytes].min
    end

    def review_result(estimate)
      Result.new(issue_code: issue_code, estimated_bytes: estimate[:bytes], auto_run: false,
                 offer_count: 0, deleted_count: 0, already_gone_count: 0, errors: [],
                 concurrency: concurrency)
    end

    def delete_offers(offer_ids, auto_run:, estimate:)
      return empty_result(auto_run, estimate) if offer_ids.empty?

      offer_ids = offer_ids.to_a
      progress_mutex = Mutex.new
      done = 0

      existing_concurrency = [ concurrency, offer_ids.length ].min
      pool = Concurrent::FixedThreadPool.new(existing_concurrency,
                                             name: "merchant-cleanup-%d" % Process.pid)
      outcomes = offer_ids.map do |offer_id|
        Concurrent::Promises.future_on(pool) do
          result = record_delete(offer_id)
          completed = progress_mutex.synchronize { done += 1 }
          print_progress(completed, offer_ids.length)
          result
        rescue StandardError => e
          { status: :error, error: { offer_id: offer_id, error: e.message } }
        end
      end.map(&:value!)

      pool.shutdown
      pool.wait_for_termination

      Result.new(issue_code: issue_code, estimated_bytes: estimate[:bytes], auto_run: auto_run,
                 offer_count: offer_ids.length,
                 deleted_count: outcomes.count { |o| o[:status] == :deleted },
                 already_gone_count: outcomes.count { |o| o[:status] == :already_gone },
                 errors: outcomes.filter_map { |o| o[:error] if o[:status] == :error },
                 concurrency: concurrency)
    end

    def empty_result(auto_run, estimate)
      Result.new(issue_code: issue_code, estimated_bytes: estimate[:bytes], auto_run: auto_run,
                 offer_count: 0, deleted_count: 0, already_gone_count: 0, errors: [],
                 concurrency: concurrency)
    end

    def print_progress(done, total)
      return unless (done % PROGRESS_INTERVAL).zero? || done == total

      puts "  deleted #{done}/#{total}..."
    end

    def record_delete(offer_id)
      merchant_service.delete(offer_id: offer_id)
      { status: :deleted }
    rescue GoogleMerchant::NotFoundError
      { status: :already_gone }
    rescue GoogleMerchant::Error => e
      { status: :error, error: { offer_id: offer_id, error: e.message } }
    end
  end
end