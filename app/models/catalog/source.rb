module Catalog
  class Source < Record
    has_many :source_prefixes
  end
end
