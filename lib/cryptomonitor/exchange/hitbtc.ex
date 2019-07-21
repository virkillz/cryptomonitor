defmodule Monitrage.Hitbtc do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://api.hitbtc.com"


  def depth(symbol) do
    case HTTPoison.get(@domain <> "/api/2/public/orderbook/#{symbol}", [], [timeout: 3_000, recv_timeout: 3_000]) do
      {:ok, %{body: body, status_code: 200}} -> 
        hasil = Jason.decode(body)
            case hasil do
              {:ok, %{"ask" => _}} -> hasil
              _other -> {:error, "Cannot get depth"}
            end
      _err -> {:error, "Cannot get depth"}
    end
  end

  def decode_symbol(monitrage_symbol) do
    [base, quoted] = String.split(monitrage_symbol, "_")
    String.upcase(base) <> String.upcase(quoted)
  end

  def best_offer(monitrage_symbol) do
    case depth(monitrage_symbol |> decode_symbol) do
      {:ok, %{"ask" => asks, "bid" => bids}} ->
      if bids != nil and asks != nil do
          %{"price" => bid_price, "size" => bid_vol} = List.first(bids)
          %{"price" => ask_price, "size" => ask_vol} = List.first(asks)
          %{highest_bid: [bid_price,bid_vol], lowest_ask: [ask_price,ask_vol]}
      else
        %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
      end

      _err -> %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
    end
  end
end
