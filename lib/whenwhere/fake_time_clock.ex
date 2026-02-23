defmodule Whenwhere.FakeTimeClock do
  @moduledoc """
  A `NervesTime.RealTimeClock` implementation that uses Whenwhere to get the time.

  This module acts as a "fake" real-time clock for devices that don't have
  an RTC chip. Instead of reading time from hardware, it fetches the current
  time from a Whenwhere server.

  ## Usage

  Configure `nerves_time` to use this module as its RTC:

      config :nerves_time, rtc: Whenwhere.FakeTimeClock

  By default it uses plain HTTP (which works even when the device clock is
  wrong). To use HTTPS instead, pass the protocol as an argument:

      config :nerves_time, rtc: {Whenwhere.FakeTimeClock, protocol: "https://"}
  """

  @behaviour NervesTime.RealTimeClock

  require Logger

  @impl NervesTime.RealTimeClock
  def init(args) do
    protocol = Keyword.get(args, :protocol, "http://")
    {:ok, %{protocol: protocol}}
  end

  @impl NervesTime.RealTimeClock
  def terminate(_state), do: :ok

  @impl NervesTime.RealTimeClock
  def get_time(%{protocol: protocol} = state) do
    case Whenwhere.ask(protocol) do
      {:ok, %{now: %DateTime{} = dt}} ->
        {:ok, DateTime.to_naive(dt), state}

      {:error, reason} ->
        Logger.warning("Whenwhere.FakeTimeClock failed to get time: #{inspect(reason)}")
        {:unset, state}
    end
  end

  @impl NervesTime.RealTimeClock
  def set_time(state, _naive_date_time) do
    # No hardware clock to set — this is a no-op.
    state
  end
end
