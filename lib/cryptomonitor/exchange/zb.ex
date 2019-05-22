defmodule Monitrage.Zb do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "http://api.zb.cn/data/v1"


  def depth(symbol) do
    case HTTPoison.get(@domain <> "/depth?market=#{symbol}&size=2") do
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
          [a,b] = List.first(bids)
          [c,d] = List.last(asks)
          %{highest_bid: [c |> Float.to_string,d |> Float.to_string], lowest_ask: [a |> Float.to_string,b |> Float.to_string]}
      else
        %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
      end

      _err -> %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
    end
  end
end
