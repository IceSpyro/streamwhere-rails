require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.cache.clear }

  test "returns films and series, not people" do
    body = {
      page: 1, total_pages: 1,
      results: [
        { id: 438631, media_type: "movie", title: "Dune", release_date: "2021-09-15", poster_path: "/d5.jpg" },
        { id: 1399, media_type: "tv", name: "Dune: Prophecy", first_air_date: "2024-11-17", poster_path: nil },
        { id: 1, media_type: "person", name: "Someone" }
      ]
    }.to_json
    stub_request(:get, %r{api\.themoviedb\.org/3/search/multi}).with(query: hash_including(query: "dune"))
                                                               .to_return(status: 200, body: body)

    get "/api/v1/search", params: { q: "dune" }

    assert_response :success
    results = response.parsed_body["results"]
    assert_equal [ 438631, 1399 ], results.map { |r| r["id"] }
    assert_equal "2021", results.first["year"]
    assert_equal "https://image.tmdb.org/t/p/w342/d5.jpg", results.first["poster_url"]
    assert_nil results.last["poster_url"]
  end

  test "requires a sensible query" do
    get "/api/v1/search"
    assert_response :bad_request

    get "/api/v1/search", params: { q: "a" }
    assert_response :bad_request
  end
end
