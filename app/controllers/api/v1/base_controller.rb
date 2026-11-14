module Api
  module V1
    class BaseController < ApplicationController
      # 60 requests a minute per IP across the API.
      rate_limit to: 60, within: 1.minute,
                 with: -> { render_error(:too_many_requests, "Too many requests, slow down.") }

      rescue_from Tmdb::Client::NotFound, with: -> { render_error(:not_found, "Title not found") }
      rescue_from Tmdb::Client::Unavailable, with: -> { render_error(:bad_gateway, "Upstream data source unavailable") }
      rescue_from ActionController::ParameterMissing, with: ->(e) { render_error(:bad_request, e.message) }

      private

      def tmdb
        @tmdb ||= Tmdb::Client.new
      end

      def render_error(status, message)
        render json: { error: message }, status: status
      end
    end
  end
end
