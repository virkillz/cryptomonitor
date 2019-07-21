defmodule Monitrage.Kraken do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://api.kraken.com"


  def depth(symbol) do
    case HTTPoison.get(@domain <> "/0/public/Depth?pair=#{symbol}", [], [timeout: 3_000, recv_timeout: 3_000]) do
      {:ok, %{body: body, status_code: 200}} -> 
        hasil = Jason.decode(body)
            case hasil do
              {:ok, %{"result" => result}} ->
                [depth] = Enum.map(result, fn {k,v} -> v end)
                {:ok, depth}
              _other -> {:error, "Cannot get depth"}
            end
      _err -> {:error, "Cannot get depth"}
    end
  end

  def decode_symbol(monitrage_symbol) do
    [base, quoted] = String.split(monitrage_symbol, "_")
    newquoted = if quoted == "btc", do: "XBT", else: quoted
    String.upcase(base) <> String.upcase(newquoted)
  end

  def best_offer(monitrage_symbol) do
    case depth(monitrage_symbol |> decode_symbol) do
      {:ok, %{"asks" => asks, "bids" => bids}} ->
      if bids != nil and asks != nil do
        [a,b,c] = List.first(bids)
        [d,e,f] = List.first(asks)
        %{highest_bid: [a,b], lowest_ask: [d,e]}
      else
        %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
      end

      _err -> %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
    end
  end
end
