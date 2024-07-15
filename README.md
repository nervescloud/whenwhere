# Whenwhere

A small utility for fetching data from a Whenwhere server.

The primary task of Whenwhere is to get the rough time.
A more reliable and resilient option to NTP.

As a bonus and due to cheap AWS functionality it also includes some GeoIP
functionality. Best effort information about the location of the device.

You can set up your own using the information
[available here](https://github.com/nerves-networking/whenwhere).
If you do set one up and are willing to share it, let us know.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `whenwhere` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:whenwhere, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
# Secure
Whenwhere.asks()
# Without SSL, no security, but works if your clock is borked
Whenwhere.ask()
```