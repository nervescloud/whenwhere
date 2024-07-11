# Whenwhere

A small library for Nerves devices to check in with a Nerves Project hosted endpoint to help get IP address, rough geo-location and time information. It can also be used to detect if you are online or within a captive portal for hotel WiFi, probably.

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