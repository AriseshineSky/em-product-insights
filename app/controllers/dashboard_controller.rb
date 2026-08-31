class DashboardController < ApplicationController
  layout "dashboard"

  def index
    @source_stats = MerchantSource.order(:name).map do |merchant_source|
      source = merchant_source.name
      checks = ProductAudit::MerchantProductCheck.where(source: source)
      {
        merchant_source: merchant_source,
        sourced_count: Catalog::ProductSource.where(source: source).count,
        checked_count: checks.count,
        state_counts: checks.group(:state).count,
        last_checked: checks.maximum(:checked_at)
      }
    end
    @recent_products = ProductAudit::MerchantProductCheck.where(source: MerchantSource.pluck(:name))
      .order(checked_at: :desc).limit(6)
  end

  def products
    @sources = MerchantSource.order(:name)
    @selected_source = params[:source].presence
    @selected_state = params[:state].presence
    scope = ProductAudit::MerchantProductCheck
    scope = scope.where(source: @selected_source) if @selected_source
    scope = scope.where(state: @selected_state) if @selected_state
    @products = scope.order(checked_at: :desc).limit(50)
  end
end
