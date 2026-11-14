module Api
  module V1
    # GET /api/v1/search?q=dune&page=1
    class SearchController < BaseController
      def index
        query = params.require(:q).to_s.strip
        return render_error(:bad_request, "q must be 2-100 characters") unless query.length.between?(2, 100)

        page = params.fetch(:page, 1).to_i.clamp(1, 500)

        data = Rails.cache.fetch([ "search", query.downcase, page ], expires_in: 10.minutes) do
          tmdb.search(query, page: page)
        end

        render json: {
          page: data[:page],
          total_pages: data[:total_pages],
          results: data[:results].map { |r| serialize(r) }
        }
      end

      private

      def serialize(r)
        date = r["release_date"].presence || r["first_air_date"].presence
        {
          id: r["id"],
          media_type: r["media_type"],
          title: r["title"] || r["name"],
          year: date&.first(4),
          poster_url: r["poster_path"] && "https://image.tmdb.org/t/p/w342#{r['poster_path']}"
        }
      end
    end
  end
end
