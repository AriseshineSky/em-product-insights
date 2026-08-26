class DashboardController < ApplicationController
  def index
    @cyp_count = Catalog::ProductSource.where(source: "Cyp").count
    @merchant_stats = ProductAudit::MerchantProductCheck.group(:state).count
    @total_checked = ProductAudit::MerchantProductCheck.count
    @last_checked = ProductAudit::MerchantProductCheck.maximum(:checked_at)
  end

  def products
    @products = ProductAudit::MerchantProductCheck.where(source: "Cyp")
      .order(checked_at: :desc).limit(50)
  end
end
