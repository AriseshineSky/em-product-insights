module SpreeApi
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RequestError < Error; end
end
