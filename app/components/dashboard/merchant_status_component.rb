# frozen_string_literal: true

module Dashboard
  class MerchantStatusComponent < ViewComponent::Base
    LEGEND = [
      { key: "found", label: "Found", color: "#22c55e" },
      { key: "not_found", label: "Not Found", color: "#ef4444" },
      { key: "error", label: "Error", color: "#f59e0b" }
    ].freeze

    attr_reader :stats, :total

    def initialize(stats:, total:)
      @stats = stats
      @total = total
    end

    def legend
      LEGEND.map do |item|
        item.merge(count: stats.fetch(item[:key], 0), percent: percent(stats.fetch(item[:key], 0)))
      end
    end

    def donut_style
      segments = legend.each_with_index.map do |item, index|
        start = legend.first(index + 1).sum { |i| i[:percent] } - item[:percent]
        "#{item[:color]} #{start}% #{start + item[:percent]}%"
      end
      "background: conic-gradient(from 0deg, #{segments.join(', ')})"
    end

    private

    def percent(count)
      return 0 if total.zero?

      (count.to_f / total * 100).round(1)
    end
  end
end
