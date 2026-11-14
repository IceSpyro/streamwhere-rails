ENV["RAILS_ENV"] ||= "test"
ENV["TMDB_API_KEY"] ||= "test-key"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Tests never touch the real TMDB API.
WebMock.disable_net_connect!

module ActiveSupport
  class TestCase
    # Tests share one in-memory cache, so run them one at a time.
    parallelize(workers: 1)
  end
end
