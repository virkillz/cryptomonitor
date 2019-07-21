defmodule CryptomonitorWeb.PageController do
  use CryptomonitorWeb, :controller


  def index(conn, _params) do
    render(conn, "index.html")
  end

  def api_coin_detail(conn, %{"coin" => coin, "convertion" => convertion, "exchange" => exchanges}) when is_list(exchanges) do
    if Cryptomonitor.is_coin_supported?(coin) do
      coin_info = Cryptomonitor.get_coin_info(coin)

      arbit_info =
        coin
        |> Cryptomonitor.get_arbitrage_pair() # If BTC, pair to usd, otherwise, BTC
        |> Cryptomonitor.get_arbitrage_info(exchanges, convertion) # Get price and convert to chosen convertion.

      results = arbit_info |> Cryptomonitor.put_details() 

      info = %{
        "coin" => coin_info,
        "detail" => %{
          "buy_from" => arbit_info.lowest_ask.exchange |> String.capitalize(),
          "sell_to" => arbit_info.highest_bid.exchange |> String.capitalize(),
          "summary" =>
            "Buy from #{arbit_info.lowest_ask.exchange |> String.capitalize()}, Sell at #{
              arbit_info.highest_bid.exchange |> String.capitalize()
            }",
          "deal_percentage" => "#{(arbit_info.gain * 100) |> Float.ceil(2)}",
          "buy_price" => arbit_info.min_ask,
          "sell_price" => arbit_info.max_bid,
          "currency" => convertion
        },
        "results" => results
      }

      conn
      |> json(info)
    else
      conn |> put_status(400) |> json(%{"message" => "Bad parameter sini"})
    end
  end

  defp get_base(pair) do
    [a, b] = String.split(pair, "_")
    String.upcase(b)
  end

  def api_coin_detail(conn, params) do
    conn |> put_status(400) |> json(%{"message" => "bad parameter sana"})
  end

  def api_coins(conn, _params) do
    coins = Cryptomonitor.list_coins() |> Enum.filter(fn x -> x.symbol != "BTC" end)
    json(conn, coins)
  end

  def api_exchanges(conn, _params) do
    exchanges = Cryptomonitor.list_exchanges()
    json(conn, exchanges)
  end

  def api_combined(conn, _params) do
    coins = Cryptomonitor.list_coins() |> Enum.filter(fn x -> x.symbol != "BTC" end)
    exchanges = Cryptomonitor.list_exchanges()
    json(conn, %{"coins" => coins, "exchanges" => exchanges})
  end

end
