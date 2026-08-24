namespace :merchant do
  desc "Check Merchant status of products sourced from a catalog source (default Cyp) and persist/print the report"
  task :cyp_status, %i[source limit] => :environment do |_task, args|
    report = GoogleMerchant::CypStatusReport.new(source: args.fetch(:source, "Cyp"))
    result = report.run(limit: args[:limit]&.to_i)

    puts "Merchant status report for source=#{result.source}"
    puts "checked=#{result.total} found=#{result.found} not_found=#{result.not_found} errors=#{result.errors}"
    result.db_errors.first(20).each { |e| puts "  db error product=#{e[:product_id]}: #{e[:error]}" }

    limit = args[:limit]&.to_i
    rows = MerchantProductCheck.where(source: result.source).order(checked_at: :desc)
    rows = rows.limit(limit) if limit

    rows.each do |row|
      puts [ row.product_id, row.offer_id, row.state, row.availability, row.currency,
            row.price_micros.to_s, row.title || row.error_message ].join("\t")
    end
  end
end
