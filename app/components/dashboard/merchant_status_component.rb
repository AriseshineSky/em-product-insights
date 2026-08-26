# frozen_string_literal: true

module Dashboard
  class MerchantStatusComponent < ViewComponent::Base
    attr_reader :stats, :total

    # @param stats [Hash] { "found" => count, "not_found" => count, "error" => count }
    def initialize(stats:, total:)
      @stats = stats
      @total = total
    end

    def found_count
      stats.fetch("found", 0)
    end

    def not_found_count
      stats.fetch("not_found", 0)
    end

    def error_count
      stats.fetch("error", 0)
    end

    def found_percentage
      return 0 if total.zero?

      (found_count.to_f / total * 100).round(1)
    end

    def not_found_percentage
      return 0 if total.zero?

      (not_found_count.to_f / total * 100).round(1)
    end
  end
end
