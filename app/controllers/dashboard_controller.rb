class DashboardController < ApplicationController
  layout "dashboard"

  def index
    @cyp_count = Catalog::ProductSource.where(source: "Cyp").count
    @merchant_stats = ProductAudit::MerchantProductCheck.group(:state).count
    @total_checked = ProductAudit::MerchantProductCheck.count
    @last_checked = ProductAudit::MerchantProductCheck.maximum(:checked_at)
    @recent_products = ProductAudit::MerchantProductCheck.order(checked_at: :desc).limit(6)
  end

  def products
    @products = ProductAudit::MerchantProductCheck.where(source: "Cyp")
      .order(checked_at: :desc).limit(50)
  end
end
