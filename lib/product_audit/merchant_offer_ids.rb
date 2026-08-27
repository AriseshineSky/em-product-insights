module ProductAudit
  # Resolves catalog product_ids to Google Merchant offer_ids using the
  # everymarket convention: "{store_code}_{product_id}_{master_variant_id}".
  class MerchantOfferIds
    def initialize(store_code: Spree::Store.default_store&.code)
      @store_code = store_code
    end

    # @param product_ids [Array<Integer>]
    # @return [Hash{Integer => String}] product_id => offer_id
    def build_by_product_id(product_ids)
      product_ids = Array(product_ids).map(&:to_i).uniq
      return {} if product_ids.empty? || store_code.to_s.empty?

      master_variant_ids(product_ids).each_with_object({}) do |(product_id, variant_id), hash|
        hash[product_id] = "#{store_code}_#{product_id}_#{variant_id}"
      end
    end

    private

    attr_reader :store_code

    def master_variant_ids(product_ids)
      Spree::Variant.unscoped.select(:id, :product_id)
        .where(product_id: product_ids, is_master: true)
        .index_by(&:product_id)
        .transform_values(&:id)
    end
  end
end
