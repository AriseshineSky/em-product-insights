module BigQuery
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class QueryError < Error; end
end
