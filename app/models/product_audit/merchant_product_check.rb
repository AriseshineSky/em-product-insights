module ProductAudit
  class MerchantProductCheck < ApplicationRecord
    self.table_name = "merchant_product_checks"

    enum :state, { found: "found", not_found: "not_found", error: "error" }
  end
end
