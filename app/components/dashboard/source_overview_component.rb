# frozen_string_literal: true

module Dashboard
  class SourceOverviewComponent < ViewComponent::Base
    LEGEND = [
      { key: "found", label: "Found", color: "#22c55e" },
      { key: "not_found", label: "Not Found", color: "#ef4444" },
      { key: "error", label: "Error", color: "#f59e0b" }
    ].freeze

    attr_reader :merchant_source, :sourced_count, :checked_count, :state_counts, :last_checked

    def initialize(merchant_source:, sourced_count:, checked_count:, state_counts:, last_checked:)
      @merchant_source = merchant_source
      @sourced_count = sourced_count
      @checked_count = checked_count
      @state_counts = state_counts
      @last_checked = last_checked
    end

    def not_found_count
      state_counts.fetch("not_found", 0)
    end

    def legend
      LEGEND.map do |item|
        item.merge(count: state_counts.fetch(item[:key], 0), percent: percent(state_counts.fetch(item[:key], 0)))
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
      return 0 if checked_count.zero?

      (count.to_f / checked_count * 100).round(1)
    end
  end
end
