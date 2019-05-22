defmodule CryptomonitorWeb.Router do
  use CryptomonitorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end


  pipeline :api do
    plug :accepts, ["json"]
    # Only uncomment line below if you separate front end and back end into different server.
    # plug CORSPlug, origin: ["http://localhost:3000", "http://127.0.0.1:3000"]
    plug CORSPlug, origin: ["http://cryptomonitor.xyz", "http://165.22.250.213", "http://localhost:4000"]
  end

  scope "/", CryptomonitorWeb do
    pipe_through :api
     get "/", PageController, :index
  end

  scope "/api", CryptomonitorWeb do
    pipe_through :api

    get "/best", PageController, :api_coin_detail
    get "/resources", PageController, :api_combined
    get "/coins", PageController, :api_coins
    get "/exchanges", PageController, :api_exchanges
  end
end
