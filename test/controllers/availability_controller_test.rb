require "test_helper"

class AvailabilityControllerTest < ActionDispatch::IntegrationTest
  PROVIDERS_URL = %r{api\.themoviedb\.org/3/movie/438631/watch/providers}

  setup { Rails.cache.clear }

  test "returns every country's offers" do
    stub_request(:get, PROVIDERS_URL).to_return(status: 200, body: file_fixture("watch_providers.json").read)

    get "/api/v1/titles/movie/438631/availability"

    assert_response :success
    assert_equal %w[GB US FR], response.parsed_body["countries"].map { |c| c["country"] }
  end

  test "returns one country when asked" do
    stub_request(:get, PROVIDERS_URL).to_return(status: 200, body: file_fixture("watch_providers.json").read)

    get "/api/v1/titles/movie/438631/availability", params: { country: "us" }

    assert_response :success
    assert_equal "US", response.parsed_body["country"]
    assert_equal [ "Max" ], response.parsed_body.dig("offers", "stream")
  end

  test "caches TMDB responses" do
    stub = stub_request(:get, PROVIDERS_URL).to_return(status: 200, body: file_fixture("watch_providers.json").read)

    2.times { get "/api/v1/titles/movie/438631/availability" }

    assert_requested stub, times: 1
  end

  test "rejects bad input before calling TMDB" do
    get "/api/v1/titles/person/1/availability"
    assert_response :bad_request

    get "/api/v1/titles/movie/abc/availability"
    assert_response :bad_request

    get "/api/v1/titles/movie/1/availability", params: { country: "GBR" }
    assert_response :bad_request
  end

  test "maps TMDB 404 to 404" do
    stub_request(:get, %r{movie/999999/watch/providers}).to_return(status: 404, body: "{}")

    get "/api/v1/titles/movie/999999/availability"

    assert_response :not_found
  end

  test "maps TMDB outages to 502" do
    stub_request(:get, PROVIDERS_URL).to_return(status: 503, body: "")

    get "/api/v1/titles/movie/438631/availability"

    assert_response :bad_gateway
    assert_equal "Upstream data source unavailable", response.parsed_body["error"]
  end

  test "maps timeouts to 502" do
    stub_request(:get, PROVIDERS_URL).to_timeout

    get "/api/v1/titles/movie/438631/availability"

    assert_response :bad_gateway
  end
end
