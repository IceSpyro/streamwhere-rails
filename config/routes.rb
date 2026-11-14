Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "search", to: "search#index"
      get "titles/:media_type/:id/availability", to: "availability#show", as: :availability
    end
  end
end
