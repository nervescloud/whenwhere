defmodule WhenwhereTest do
  use ExUnit.Case
  doctest Whenwhere

  test "do the thing" do
    assert {:ok,
            %{
              "address" => _,
              "city" => _,
              "country" => _,
              "country_region" => _,
              "latitude" => lat,
              "longitude" => lng,
              "now" => dt,
              "time_zone" => _
            }} = Whenwhere.asks()

    assert {_, ""} = Float.parse(lat)
    assert {_, ""} = Float.parse(lng)
    assert {:ok, %DateTime{}, _} = DateTime.from_iso8601(dt)
  end
end
