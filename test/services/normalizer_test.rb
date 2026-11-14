require "test_helper"

class NormalizerTest < ActiveSupport::TestCase
  setup do
    @normalizer = Availability::Normalizer.new(JSON.parse(file_fixture("watch_providers.json").read))
  end

  test "groups one country's offers and tidies service names" do
    gb = @normalizer.for_country("gb")

    assert_equal [ "NOW", "Prime Video" ], gb[:stream]
    assert_equal [ "Amazon" ], gb[:rent]
    assert_empty gb[:buy]
  end

  test "a service already in stream is not repeated as free" do
    assert_equal [ "Tubi" ], @normalizer.for_country("GB")[:free]
  end

  test "returns nil for a country with no offers or no data" do
    assert_nil @normalizer.for_country("XX")
    assert_nil @normalizer.for_country("JP")
  end

  test "lists countries with offers, priority markets first" do
    assert_equal %w[GB US FR], @normalizer.all_countries.map { |c| c[:country] }
  end

  test "strips channel suffixes from unknown names" do
    assert_equal "MUBI", Availability::Normalizer.clean_name("MUBI Amazon Channel")
    assert_equal "Shudder", Availability::Normalizer.clean_name("Shudder")
  end
end
