defmodule Monitrage.Okex do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://www.okex.com"


  def depth(symbol) do
    case HTTPoison.get(@domain <> "/api/spot/v3/instruments/#{symbol}/book", [], [timeout: 3_000, recv_timeout: 3_000]) do
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
    monitrage_symbol
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
