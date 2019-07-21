defmodule Monitrage.Rightbtc do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://www.rightbtc.com/api/"


  def depth(symbol) do
    case HTTPoison.get(@domain <> "public/depth/#{symbol}/2", [], [timeout: 3_000, recv_timeout: 3_000]) do
      {:ok, %{body: body, status_code: 200}} -> 
        hasil = Jason.decode(body)
            case hasil do
              {:ok, %{"result" => result}} -> {:ok, result}
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
          [a,b,c] = List.first(bids)
          [d,e,f] = List.first(asks)
          %{highest_bid: [(d / 1.0e8) |> Float.to_string, (e / 1.0e8) |> Float.to_string], lowest_ask: [ (a / 1.0e8) |> Float.to_string, (b / 1.0e8) |> Float.to_string]}
      else
        %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
      end

      _err -> %{highest_bid: ["0.0", "0.0"], lowest_ask: [nil, "0.0"]}
    end
  end
end
