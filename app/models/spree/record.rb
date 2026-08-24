module Spree
  class Record < ApplicationRecord
    self.abstract_class = true
    connects_to database: { reading: :spree }
  end
end
