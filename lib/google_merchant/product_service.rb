module GoogleMerchant
  class ProductService
    V1 = Google::Shopping::Merchant::Products::V1

    attr_reader :config, :client

    def initialize(config: GoogleMerchant.config)
      @config = config
      @client = Client.new(config: config)
    end

    def each_product(page_size: 250)
      return enum_for(:each_product, page_size: page_size) unless block_given?

      client.list_products(page_size: page_size).each { |product| yield product }
    end

    def find_product(name: nil, offer_id: nil, content_language: config.content_language,
                     feed_label: config.feed_label)
      name ||= product_name(offer_id, content_language: content_language, feed_label: feed_label)
      client.get_product(name)
    end

    def search(offer_id: nil, sku: nil, page_size: 250, limit: 1000)
      matches = []
      each_product(page_size: page_size) do |product|
        matches << product if product_matches?(product, offer_id: offer_id, sku: sku)
        break if matches.length >= limit
      end
      matches
    end

    def insert(offer_id:, attributes:, content_language: config.content_language,
               feed_label: config.feed_label, data_source: config.data_source)
      config.require_data_source!
      input = build_product_input(
        offer_id: offer_id, attributes: attributes,
        content_language: content_language, feed_label: feed_label
      )
      client.insert_product(config.accounts_root, input, data_source: normalize_data_source(data_source))
    end

    def update(name:, attributes:, update_mask:, data_source: config.data_source)
      config.require_data_source!
      input = build_product_input(name: name, attributes: attributes)
      client.update_product(
        input, data_source: normalize_data_source(data_source), update_mask: update_mask
      )
    end

    def delete(name: nil, offer_id: nil, content_language: config.content_language,
               feed_label: config.feed_label, data_source: config.data_source)
      config.require_data_source!
      name ||= product_input_name(offer_id,
                                  content_language: content_language, feed_label: feed_label)
      client.delete_product(name, data_source: normalize_data_source(data_source))
    end

    def build_product_input(offer_id: nil, name: nil, attributes: {},
                            content_language: config.content_language,
                            feed_label: config.feed_label)
      V1::ProductInput.new(
        name: name || product_input_name(offer_id,
                                         content_language: content_language,
                                         feed_label: feed_label),
        offer_id: offer_id,
        content_language: content_language,
        feed_label: feed_label,
        product_attributes: build_attributes(attributes)
      )
    end

    def build_attributes(hash)
      V1::ProductAttributes.new(**hash) if hash
    end

    def price(amount, currency:)
      Google::Shopping::Type::Price.new(amount_micros: (amount * 1_000_000).to_i,
                                        currency_code: currency)
    end

    def product_name(offer_id, content_language: config.content_language,
                     feed_label: config.feed_label)
      "#{config.accounts_root}/products/#{content_language}~#{feed_label}~#{offer_id}"
    end

    def product_input_name(offer_id, content_language: config.content_language,
                           feed_label: config.feed_label)
      "#{config.accounts_root}/productInputs/#{content_language}~#{feed_label}~#{offer_id}"
    end

    private

    def normalize_data_source(data_source)
      ds = data_source || config.data_source_name
      raise ConfigurationError, "data source is required for product writes" if ds.to_s.empty?
      ds.to_s.match?(%r{\Aaccounts/}) ? ds : "#{config.accounts_root}/dataSources/#{ds}"
    end

    def product_matches?(product, offer_id: nil, sku: nil)
      (offer_id.nil? || product.offer_id == offer_id) &&
        (sku.nil? || product.offer_id.to_s.downcase.include?(sku.to_s.downcase))
    end
  end
end
