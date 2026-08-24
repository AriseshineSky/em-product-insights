module GoogleMerchant
  class CypStatusReport
    DEFAULT_SOURCE = "Cyp".freeze

    Result = Struct.new(:source, :total, :found, :not_found, :errors, :db_errors,
                        keyword_init: true) do
      def summary
        { source: source, total: total, found: found, not_found: not_found, errors: errors.length }
      end
    end

    attr_reader :source, :product_service

    def initialize(source: DEFAULT_SOURCE, product_service: ProductService.new)
      @source = source
      @product_service = product_service
    end

    def run(limit: nil)
      counted = Hash.new(0)
      db_errors = []
      checked_rows = 0

      scope = Catalog::ProductSource.where(source: source).order(:product_id)
      scope = scope.limit(limit) if limit

      scope.find_each do |product_source|
        determined = check_product(product_source)
        counted[determined[:state]] += 1
        begin
          persist(product_source, determined)
          checked_rows += 1
        rescue StandardError => e
          db_errors << { product_id: product_source.product_id, error: e.message }
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

    def check_product(product_source)
      [ product_source.handle, product_source.source_product_id ].compact.each do |offer_id|
        begin
          product = product_service.find_product(offer_id: offer_id)
          return found_result(offer_id, product)
        rescue NotFoundError
          next
        rescue Error => e
          return { state: "error", offer_id: offer_id, error_message: e.message }
        end
      end
      { state: "not_found", offer_id: product_source.handle }
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
