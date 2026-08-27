class MerchantSourcesController < ApplicationController
  layout "dashboard"

  def index
    @sources = MerchantSource.order(:name)
    @available_sources = available_catalog_sources
  end

  def create
    source = MerchantSource.find_or_create_by!(name: source_params[:name])
    redirect_to merchant_sources_path, notice: "#{source.name} added"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    redirect_to merchant_sources_path, alert: e.record&.errors&.full_messages&.to_sentence || e.message
  end

  def destroy
    source = MerchantSource.find(params[:id])
    source.destroy
    redirect_to merchant_sources_path, notice: "#{source.name} removed"
  end

  private

  def source_params
    params.require(:merchant_source).permit(:name)
  end

  def available_catalog_sources
    Catalog::ProductSource.distinct.pluck(:source).compact - MerchantSource.pluck(:name)
  end
end
