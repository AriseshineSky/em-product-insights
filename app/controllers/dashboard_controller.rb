class DashboardController < ApplicationController
  def index
    @cyp_count = Catalog::ProductSource.where(source: "Cyp").count
    @merchant_stats = MerchantProductCheck.group(:state).count
    @total_checked = MerchantProductCheck.count
    @last_checked = MerchantProductCheck.maximum(:checked_at)
  end

  def products
    @products = MerchantProductCheck.where(source: "Cyp")
      .order(checked_at: :desc).limit(50)
  end
end
