defmodule Monitrage.Bitmart do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://openapi.bitmart.com/v2"


  def depth(symbol) do
    case HTTPoison.get(@domain <> "/symbols/#{symbol}/orders?precision=6", [], [timeout: 3_000, recv_timeout: 3_000]) do
      {:ok, %{body: body, status_code: 200}} -> 
        hasil = Jason.decode(body)
            case hasil do
              {:ok, %{"buys" => _}} -> hasil
              _other -> {:error, "Cannot get depth"}
            end
      _err -> {:error, "Cannot get depth"}
    end
  end

  def decode_symbol(monitrage_symbol) do
    [base, quoted] = String.split(monitrage_symbol, "_")
    String.upcase(base) <> "_" <> String.upcase(quoted)
  end

  def best_offer(monitrage_symbol) do
    case depth(monitrage_symbol |> decode_symbol) do
      {:ok, %{"sells" => asks, "buys" => bids}} ->
      if bids != nil and asks != nil do
          %{"price" => bid_price, "amount" => bid_vol} = List.first(bids)
          %{"price" => ask_price, "amount" => ask_vol} = List.first(asks)
          %{highest_bid: [bid_price,bid_vol], lowest_ask: [ask_price,ask_vol]}
      else
        %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
      end

      _err -> %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
    end
  end
end
