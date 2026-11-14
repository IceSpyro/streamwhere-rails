require "net/http"
require "json"

module Tmdb
  # Thin wrapper around the TMDB v3 API. Keeps the API key on the server and
  # turns HTTP failures into errors the controllers can map to status codes.
  class Client
    BASE_URL = "https://api.themoviedb.org/3".freeze
    MEDIA_TYPES = %w[movie tv].freeze

    class Error < StandardError; end
    class NotFound < Error; end
    class Unavailable < Error; end

    def initialize(api_key: ENV.fetch("TMDB_API_KEY", nil), timeout: 5)
      raise ArgumentError, "TMDB_API_KEY is not set" if api_key.blank?

      @api_key = api_key
      @timeout = timeout
    end

    # Films and series matching a query (people are left out).
    def search(query, page: 1)
      body = get("/search/multi", query: query, page: page, include_adult: false)
      results = body.fetch("results", []).select { |r| MEDIA_TYPES.include?(r["media_type"]) }
      { page: body["page"], total_pages: body["total_pages"], results: results }
    end

    def details(media_type, id)
      get("/#{media_type}/#{id}")
    end

    # Raw watch-provider data for every country: { "results" => { "GB" => {...} } }
    def watch_providers(media_type, id)
      get("/#{media_type}/#{id}/watch/providers")
    end

    private

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params.merge(api_key: @api_key))

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                 open_timeout: @timeout, read_timeout: @timeout) do |http|
        http.get(uri.request_uri)
      end

      case response
      when Net::HTTPSuccess then JSON.parse(response.body)
      when Net::HTTPNotFound then raise NotFound, "TMDB has no record at #{path}"
      else raise Unavailable, "TMDB returned #{response.code}"
      end
    rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, JSON::ParserError => e
      raise Unavailable, "TMDB request failed: #{e.class}"
    end
  end
end
