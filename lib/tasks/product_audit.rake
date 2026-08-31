namespace :product_audit do
  desc "Rewrite merchant product check offer_ids to the em_{product_id}_{variant_id} convention (clears offer_ids that cannot be resolved)"
  task :sync_offer_ids => :environment do
    rows = ProductAudit::MerchantProductCheck.all
    expected = ProductAudit::MerchantOfferIds.new.build_by_product_id(rows.pluck(:product_id).uniq)

    cleared = 0
    rewritten = 0
    rows.find_in_batches do |batch|
      batch.each do |row|
        next if row.offer_id == expected[row.product_id]

        if expected[row.product_id].nil? && row.offer_id
          cleared += 1
        elsif expected[row.product_id]
          rewritten += 1
        end
        row.update_columns(offer_id: expected[row.product_id])
      end
    end

    puts "offer_ids rewritten=#{rewritten} cleared=#{cleared} (rows without a resolvable spree master variant)"
  end
  desc "Check Merchant status of products sourced from tracked catalog sources (or a specific source) and persist/print the report"
  task :merchant_status, %i[source limit] => :environment do |_task, args|
    sources = args[:source].present? ? [ args[:source] ] : MerchantSource.order(:name).pluck(:name)

    raise "No source specified and no tracked sources configured" if sources.empty?

    sources.each do |source|
      report = ProductAudit::MerchantStatusReport.new(source: source)
      result = report.run(limit: args[:limit]&.to_i)

      puts "Merchant status report for source=#{result.source}"
      puts "checked=#{result.total} found=#{result.found} not_found=#{result.not_found} errors=#{result.errors}"
      result.db_errors.first(20).each { |e| puts "  db error product=#{e[:product_id]}: #{e[:error]}" }
    end

    limit = args[:limit]&.to_i
    rows = ProductAudit::MerchantProductCheck.where(source: sources).order(checked_at: :desc)
    rows = rows.limit(limit) if limit

    rows.each do |row|
      puts [ row.source, row.product_id, row.offer_id, row.state, row.availability, row.currency,
            row.price_micros.to_s, row.title || row.error_message ].join("\t")
    end
  end

  desc "List offer_ids with a merchant issue code via BigQuery (dry-run cost estimate, then enforced max bytes)"
  task :merchant_issues, %i[issue_code limit] => :environment do |_task, args|
    issue_code = args.fetch(:issue_code, ProductAudit::MerchantIssues::DEFAULT_ISSUE_CODE)
    issues = ProductAudit::MerchantIssues.new
    est = issues.estimate(issue_code: issue_code)
    puts "issue=#{issue_code} estimate bytes=#{est[:bytes]} " \
         "gib=#{est[:gib].round(3)} estimated_cost=$#{est[:estimated_cost].round(4)} " \
         "max_bytes_billed=#{est[:maximum_bytes_billed]}"

    ids = issues.offer_ids(issue_code: issue_code, limit: args[:limit]&.to_i)
    puts "count: #{ids.length}"
    ids.first(50).each { |id| puts id }
    puts "... (#{ids.length - 50} more)" if ids.length > 50
  end

  desc "Delete merchant products by BigQuery issue code. Auto-runs only when the dry-run estimate is under 1GiB; pass force=1 after manual review above that"
  task :clear_merchant_products, %i[issue_code limit force] => :environment do |_task, args|
    issue_code = args.fetch(:issue_code, ProductAudit::MerchantIssues::DEFAULT_ISSUE_CODE)
    force = args[:force] == "1"
    result = ProductAudit::MerchantProductCleanup.new(issue_code: issue_code)
      .run(limit: args[:limit]&.to_i, force: force)

    if result.needs_review?
      puts "issue=#{result.issue_code} estimate=%d bytes (%.3f GiB) exceeds the auto-run threshold" \
           % [ result.estimated_bytes, result.estimated_bytes.to_f / (1024**3) ]
      puts "review required: no products were deleted. Rerun with force=1 only after inspecting the query and estimates."
    else
      puts "issue=#{result.issue_code} estimate_bytes=#{result.estimated_bytes} " \
           "offers=#{result.offer_count} deleted=#{result.deleted_count} " \
           "already_gone=#{result.already_gone_count} errors=#{result.errors.size}"
      result.errors.first(20).each { |e| puts "  delete error offer=#{e[:offer_id]}: #{e[:error]}" }
    end
  end
end
