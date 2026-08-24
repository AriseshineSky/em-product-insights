class MerchantProductCheck < ApplicationRecord
  enum :state, { found: "found", not_found: "not_found", error: "error" }
end
