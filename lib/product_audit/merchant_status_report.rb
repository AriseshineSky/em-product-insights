module ProductAudit
  class MerchantStatusReport
    DEFAULT_SOURCE = "Cyp".freeze

    Result = Struct.new(:source, :total, :found, :not_found, :errors, :db_errors,
                        keyword_init: true) do
      def summary
        { source: source, total: total, found: found, not_found: not_found, errors: errors }
      end
    end

    attr_reader :source, :merchant_service

    # @param merchant_service [#find_product] the merchant integration adapter
    def initialize(source: DEFAULT_SOURCE,
                   merchant_service: GoogleMerchant::ProductService.new)
      @source = source
      @merchant_service = merchant_service
    end

    def run(limit: nil)
      counted = Hash.new(0)
      db_errors = []
      checked_rows = 0

      scope = Catalog::ProductSource.where(source: source).order(:product_id)
      scope = scope.limit(limit) if limit

      scope.find_in_batches do |batch|
        offer_ids = MerchantOfferIds.new.build_by_product_id(batch.map(&:product_id))

        batch.each do |product_source|
          determined = check_product(product_source, offer_ids[product_source.product_id])
          counted[determined[:state]] += 1
          begin
            persist(product_source, determined)
            checked_rows += 1
          rescue StandardError => e
            db_errors << { product_id: product_source.product_id, error: e.message }
          end
        end
      end

      Result.new(
        source: source,
        total: checked_rows,
        found: counted["found"],
        not_found: counted["not_found"],
        errors: counted["error"],
        db_errors: db_errors
      )
    end

    private

    def check_product(product_source, offer_id)
      if offer_id.to_s.empty?
        return { state: "not_found", offer_id: nil }
      end

      product = merchant_service.find_product(offer_id: offer_id)
      found_result(offer_id, product)
    rescue GoogleMerchant::NotFoundError
      { state: "not_found", offer_id: offer_id }
    rescue GoogleMerchant::Error => e
      { state: "error", offer_id: offer_id, error_message: e.message }
    end

    def found_result(offer_id, product)
      attributes = product.product_attributes
      {
        state: "found",
        offer_id: offer_id,
        title: attributes&.title,
        availability: attributes&.availability&.to_s,
        price_micros: attributes&.price&.amount_micros,
        currency: attributes&.price&.currency_code,
        merchant_product_name: product.name,
        error_message: nil
      }
    end

    def persist(product_source, determined)
      MerchantProductCheck.upsert(
        {
          product_id: product_source.product_id,
          source: product_source.source,
          handle: product_source.handle,
          offer_id: determined[:offer_id],
          state: determined[:state],
          title: determined[:title],
          availability: determined[:availability],
          price_micros: determined[:price_micros],
          currency: determined[:currency],
          merchant_product_name: determined[:merchant_product_name],
          error_message: determined[:error_message],
          checked_at: Time.current
        },
        unique_by: %i[product_id source]
      )
    end
  end
end
