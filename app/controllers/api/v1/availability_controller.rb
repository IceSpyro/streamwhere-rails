module Api
  module V1
    # GET /api/v1/titles/:media_type/:id/availability            -> every country
    # GET /api/v1/titles/:media_type/:id/availability?country=GB -> one country
    class AvailabilityController < BaseController
      before_action :validate_params

      def show
        providers = Rails.cache.fetch([ "providers", title_type, title_id ], expires_in: 6.hours) do
          tmdb.watch_providers(title_type, title_id)
        end
        normalizer = Availability::Normalizer.new(providers)

        payload = { id: title_id, media_type: title_type }
        if (country = params[:country].presence)
          payload[:country] = country.upcase
          payload[:offers] = normalizer.for_country(country)
        else
          payload[:countries] = normalizer.all_countries
        end

        expires_in 1.hour, public: true
        render json: payload
      end

      private

      def title_type = params[:media_type]
      def title_id = params[:id].to_i

      def validate_params
        unless Tmdb::Client::MEDIA_TYPES.include?(title_type)
          return render_error(:bad_request, "media_type must be movie or tv")
        end
        unless params[:id].to_s.match?(/\A\d{1,9}\z/)
          return render_error(:bad_request, "id must be a TMDB numeric id")
        end
        if params[:country].present? && !params[:country].to_s.match?(/\A[A-Za-z]{2}\z/)
          render_error(:bad_request, "country must be a 2-letter ISO code")
        end
      end
    end
  end
end
