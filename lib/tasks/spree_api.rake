namespace :spree_api do
  desc "Delete products on the Spree storefront via the batch_delete endpoint"
  task :delete_products, [ :product_ids ] => :environment do |_task, args|
    raise ArgumentError, "usage: spree_api:delete_products['1,2,3']" if args[:product_ids].to_s.empty?

    product_ids = args[:product_ids].split(",").map(&:strip).reject(&:empty?).map(&:to_i)
    result = SpreeApi::Client.new.delete_products(product_ids)
    puts result.inspect
  end

  desc "Show the default Spree storefront shop"
  task show_shop: :environment do
    shop = SpreeApi::Client.new.get_shop
    puts(shop ? shop.inspect : "no shop configured/reachable")
  end
end
