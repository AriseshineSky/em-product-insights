module Catalog
  class Record < ApplicationRecord
    self.abstract_class = true
    connects_to database: { writing: :catalog, reading: :catalog }
  end
end
