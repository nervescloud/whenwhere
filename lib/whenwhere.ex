defmodule Whenwhere do
  @moduledoc """
  A small utility for fetching data from a Whenwhere server.

  The primary task of Whenwhere is to get the rough time.
  A more reliable and resilient option to NTP.

  As a bonus and due to cheap AWS functionality it also includes some GeoIP
  functionality. Best effort information about the location of the device.

  You can set up your own using the information
  [available here](https://github.com/nerves-networking/whenwhere).
  If you do set one up and are willing to share it, let us know.
  """

  require Logger

  @default_whenwhere_url "whenwhere.nerves-project.org/"

  @doc """
  This function requests whenwhere data over plain HTTP by default.
  If switched to https:// it will attempt to verify CA and all that good stuff.
  The convenient way to do HTTPS is with `asks/0`.

  The reason to use plain HTTP is that it will work for embedded devices
  that are out of whack with their clock.

  A nonce is generated and sent to the server to prevent captive portals
  from tricking the device, bust caches and generally increase the likelihood
  that we are talking to the right server.
  """
  @spec ask(protocol :: String.t()) :: {:ok, map()} | {:error, atom()}
  def ask(protocol \\ "http://") do
    urls = Application.get_env(:whenwhere, :servers, [@default_whenwhere_url])

    request_headers = [
      {~c"user-agent", ~c"whenwhere"},
      {~c"content-type", ~c"application/x-erlang-binary"}
    ]

    nonce = make_nonce()

    ssl =
      case protocol do
        "http://" -> [verify: :verify_none]
        "https://" -> [cacerts: :public_key.cacerts_get()]
      end

    Enum.reduce_while(urls, {:error, :no_servers_specified}, fn url, _ ->
      case :httpc.request(
             :get,
             {protocol <> url <> "?nonce=#{nonce}", request_headers},
             [ssl: ssl],
             []
           ) do
        {:ok, {_status, headers, body}} ->
          # Unwrap and check nonce
          got_nonce = Enum.find(headers, &(elem(&1, 0) == ~c(x-nonce)))

          if got_nonce && nonce == to_string(elem(got_nonce, 1)) do
            try do
              data =
                body
                |> :erlang.list_to_binary()
                |> non_executable_binary_to_term()
                |> process_response()

              {:halt, {:ok, data}}
            rescue
              e ->
                Logger.error(
                  "Whenwhere parsing failed for response from #{protocol}#{url}: #{inspect(e)}"
                )

                {:cont, {:error, :exhausted_servers}}
            end
          else
            Logger.error("Whenwhere received bad nonce from #{protocol}#{url}")
            {:cont, {:error, :exhausted_servers}}
          end

        {:error, reason} ->
          Logger.warning("Whenwhere servers #{protocol}#{url} failed: #{inspect(reason)}")
          {:cont, {:error, :exhausted_servers}}
      end
    end)
  end

  @doc """
  Attempts to fetch whenwhere data with HTTPS, so with TLS encryption and CA-checking.

  See `ask/1` for more detail.
  """
  @spec asks() :: {:ok, map()} | {:error, atom()}
  def asks, do: ask("https://")

  @known_keys [
    "address",
    "city",
    "country",
    "country_region",
    "latitude",
    "longitude",
    "now",
    "time_zone"
  ]
  defp process_response(resp) do
    resp
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      if key in @known_keys do
        value =
          case key do
            "longitude" ->
              value
              |> Float.parse()
              |> elem(0)

            "latitude" ->
              value
              |> Float.parse()
              |> elem(0)

            "now" ->
              {:ok, dt, _} = DateTime.from_iso8601(value)
              dt

            _ ->
              value
          end

        Map.put(acc, String.to_atom(key), value)
      else
        unknown =
          acc
          |> Map.get(:extra, %{})
          |> Map.put(key, value)

        Map.put(acc, :extra, unknown)
      end
    end)
  end

  @note """
  Lifted from Plug Crypto
  under Apache License, copyright Plataformatec.
  Modified to reduce options.

  A restricted version of `:erlang.binary_to_term/2` that forbids
  *executable* terms, such as anonymous functions.
  """
  defp non_executable_binary_to_term(binary) when is_binary(binary) do
    # Suppress unused warning
    _ = @note
    term = :erlang.binary_to_term(binary, [:safe])
    non_executable_terms(term)
    term
  end

  defp non_executable_terms(list) when is_list(list) do
    non_executable_list(list)
  end

  defp non_executable_terms(tuple) when is_tuple(tuple) do
    non_executable_tuple(tuple, tuple_size(tuple))
  end

  defp non_executable_terms(map) when is_map(map) do
    folder = fn key, value, acc ->
      non_executable_terms(key)
      non_executable_terms(value)
      acc
    end

    :maps.fold(folder, map, map)
  end

  defp non_executable_terms(other)
       when is_atom(other) or is_number(other) or is_bitstring(other) or is_pid(other) or
              is_reference(other) do
    other
  end

  defp non_executable_terms(other) do
    raise ArgumentError,
          "cannot deserialize #{inspect(other)}, the term is not safe for deserialization"
  end

  defp non_executable_list([]), do: :ok

  defp non_executable_list([h | t]) when is_list(t) do
    non_executable_terms(h)
    non_executable_list(t)
  end

  defp non_executable_list([h | t]) do
    non_executable_terms(h)
    non_executable_terms(t)
  end

  defp non_executable_tuple(_tuple, 0), do: :ok

  defp non_executable_tuple(tuple, n) do
    non_executable_terms(:erlang.element(n, tuple))
    non_executable_tuple(tuple, n - 1)
  end

  defp make_nonce do
    symbols = ~c(0123456789abcdefghijklmnopqrstuvwxyz)
    for _ <- 1..31, into: "", do: <<Enum.random(symbols)>>
  end
end
