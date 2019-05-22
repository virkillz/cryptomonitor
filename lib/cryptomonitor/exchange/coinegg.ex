defmodule Monitrage.Coinegg do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "http://api.coinegg.im/api/v1"


  def depth(symbol) do
    case HTTPoison.get(@domain <> "/depth/region/#{symbol}") do
      {:ok, %{body: body, status_code: 200}} -> 
        hasil = Jason.decode(body)
            case hasil do
              {:ok, %{"asks" => _}} -> hasil
              _other -> {:error, "Cannot get depth"}
            end
      _err -> {:error, "Cannot get depth"}
    end
  end

  def decode_symbol(monitrage_symbol) do
    [base, quoted] = String.split(monitrage_symbol, "_")
    "#{quoted}?coin=#{base}"
  end

  def best_offer(monitrage_symbol) do
    case depth(monitrage_symbol |> decode_symbol) do
      {:ok, %{"asks" => asks, "bids" => bids}} ->
      if bids != nil and asks != nil do
        highest_bid = List.first(bids)
        lowest_ask = List.first(asks)
        %{highest_bid: highest_bid, lowest_ask: lowest_ask}
      else
        %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
      end

      _err -> %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
    end
  end
end
