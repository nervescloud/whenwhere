defmodule Whenwhere do
  @moduledoc """
  Documentation for `NervesGeo`.
  """

  @default_whenwhere_url "whenwhere.nerves-project.org/"
  def ask(protocol \\ "http://") do
    Application.ensure_started(:inets)
    Application.ensure_started(:sasl)

    request_headers = [
      {~c"user-agent", ~c"whenwhere"},
      {~c"content-type", ~c"application/x-erlang-binary"}
    ]

    case :httpc.request(
           :get,
           {protocol <> @default_whenwhere_url, request_headers},
           [ssl: [verify: :verify_none]],
           []
         ) do
      {:ok, {_status, _headers, body}} ->
        data =
          body
          |> :erlang.list_to_binary()
          |> non_executable_binary_to_term()

        {:ok, data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def asks, do: ask("https://")

  @doc """
  Lifted from Plug Crypto
  under Apache License, copyright Plataformatec.
  Modified to reduce options.

  A restricted version of `:erlang.binary_to_term/2` that forbids
  *executable* terms, such as anonymous functions.
  """
  @spec non_executable_binary_to_term(binary()) :: term()
  def non_executable_binary_to_term(binary) when is_binary(binary) do
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
end
