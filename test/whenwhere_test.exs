defmodule WhenwhereTest do
  use ExUnit.Case, async: true
  alias ExUnit.CaptureLog
  doctest Whenwhere

  test "do the thing" do
    Application.delete_env(:whenwhere, :servers)

    assert {:ok,
            %{
              address: _,
              city: _,
              country: _,
              country_region: _,
              latitude: lat,
              longitude: lng,
              now: dt,
              time_zone: _
            }} = Whenwhere.asks()

    assert is_float(lat) and is_float(lng)
    assert %DateTime{} = dt
  end

  test "bad servers get exhausted" do
    Application.put_env(:whenwhere, :servers, ["underjord.io", "beambloggers.com"])

    CaptureLog.capture_log(fn ->
      assert {:error, :exhausted_servers} = Whenwhere.asks()
    end)
  end

  test "eventually getting the right server" do
    Application.put_env(:whenwhere, :servers, [
      "underjord.io",
      "beambloggers.com",
      "whenwhere.nerves-project.org"
    ])

    CaptureLog.capture_log(fn ->
      assert {:ok, %{}} = Whenwhere.asks()
    end)
  end
end
