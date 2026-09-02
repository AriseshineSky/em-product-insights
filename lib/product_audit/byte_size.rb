module ProductAudit
  module ByteSize
    MULTIPLIERS = { "K" => 1024, "M" => 1024**2, "G" => 1024**3, "T" => 1024**4 }.freeze

    # Parses a byte size from "100000000", "100M", "1G", "512K". Empty returns nil.
    def self.parse(value)
      return nil if value.to_s.empty?

      match = /\A(\d+)\s*(K|M|G|T)?(B)?\z/i.match(value)
      raise ArgumentError, "invalid size=#{value}, expected e.g. 100000000, 100M, 1G" unless match

      match[1].to_i * MULTIPLIERS.fetch(match[2]&.upcase, 1)
    end
  end
end