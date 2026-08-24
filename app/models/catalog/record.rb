module Catalog
  class Record < ApplicationRecord
    self.abstract_class = true
    connects_to database: { reading: :catalog }
  end
end