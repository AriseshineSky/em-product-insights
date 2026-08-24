module GoogleMerchant
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end
  class NotFoundError < Error; end
  class RequestError < Error; end
end
