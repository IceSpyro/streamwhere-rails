module Availability
  # Turns TMDB watch-provider data into plain answers per country:
  #   stream: subscription services, free: free or with ads,
  #   rent / buy: digital stores.
  # A port of StreamWhere's JavaScript availability module.
  class Normalizer
    # Same service, tidier name.
    RENAME = {
      "Amazon Prime Video" => "Prime Video",
      "Amazon Prime Video with Ads" => "Prime Video",
      "Amazon Video" => "Amazon",
      "Apple TV Store" => "Apple TV",
      "Disney Plus" => "Disney+",
      "Paramount Plus" => "Paramount+",
      "Paramount Plus Premium" => "Paramount+",
      "Paramount Plus Essential" => "Paramount+",
      "Netflix Standard with Ads" => "Netflix",
      "Netflix basic with Ads" => "Netflix",
      "Now TV" => "NOW",
      "Now TV Cinema" => "NOW",
      "Tubi TV" => "Tubi",
      "Google Play Movies" => "Google Play"
    }.freeze

    CHANNEL_SUFFIX = / (Amazon|Apple TV|Roku Premium) Channel\z/

    # Strongest markets first, then everything else A to Z.
    PRIORITY = %w[GB US CA AU IE NZ DE FR ES IT NL].freeze

    def initialize(provider_data)
      @results = provider_data.fetch("results", {})
    end

    # Offers in one country, or nil if there's nothing there.
    def for_country(code)
      offers(@results[code.to_s.upcase])
    end

    # Every country with at least one offer.
    def all_countries
      @results.keys
              .sort_by { |code| [ PRIORITY.index(code) || PRIORITY.size, code ] }
              .filter_map { |code| (o = offers(@results[code])) && { country: code, **o } }
    end

    def self.clean_name(name)
      RENAME.fetch(name) { name.sub(CHANNEL_SUFFIX, "") }
    end

    private

    def offers(region)
      return nil if region.blank?

      stream = names(region["flatrate"])
      free = names(Array(region["free"]) + Array(region["ads"])) - stream
      rent = names(region["rent"])
      buy = names(region["buy"])
      return nil if [ stream, free, rent, buy ].all?(&:empty?)

      { stream: stream, free: free, rent: rent, buy: buy, link: region["link"] }
    end

    def names(list)
      Array(list).map { |p| self.class.clean_name(p["provider_name"]) }.uniq
    end
  end
end
