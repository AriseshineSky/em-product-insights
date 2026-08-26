namespace :product_audit do
  desc "Check Merchant status of products sourced from a catalog source (default Cyp) and persist/print the report"
  task :merchant_status, %i[source limit] => :environment do |_task, args|
    report = ProductAudit::MerchantStatusReport.new(source: args.fetch(:source, "Cyp"))
    result = report.run(limit: args[:limit]&.to_i)

    puts "Merchant status report for source=#{result.source}"
    puts "checked=#{result.total} found=#{result.found} not_found=#{result.not_found} errors=#{result.errors}"
    result.db_errors.first(20).each { |e| puts "  db error product=#{e[:product_id]}: #{e[:error]}" }

    limit = args[:limit]&.to_i
    rows = ProductAudit::MerchantProductCheck.where(source: result.source).order(checked_at: :desc)
    rows = rows.limit(limit) if limit

    rows.each do |row|
      puts [ row.product_id, row.offer_id, row.state, row.availability, row.currency,
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
end
