module Spree
  class Store < Record
    def self.default_store
      where(default: true).order(:id).first
    end
  end
end
