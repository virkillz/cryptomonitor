# Cryptomonitor

Single Page Application built with Elm and Elixir to fetch cryptocurrency Price from multiple exchanges simultaneously.

This is a simple application to know which Exchange have cheapest price of given cryptocurrency. It also find which one have higest bidder to buy. With this information we calculate potential arbitrage.

The flow is simple as well, since each exchanges provide public API, it's trivial to fetch order book and find the cheapest offer, and calculate with the higest bid.


## Technical Challenges
While fetching order book API from exchanges is trivial, it's harder to do it right. In reality, the price is very time sensitive due to market movement. The key is how to fetch data simultaneously across exchanges, as fast as possible.

Without some workaround, it cannot be done in language such as PHP, Ruby, and Python due its single thread nature. Nodejs can do it faster due to its non blocking architecture.

The real solution must be built in Java, Golang, or Erlang/Elixir. Since multithreading is complex in java and the fact that so many abstraction already built in Elixir, we choose the last one.


## Stack

Elm is a simple functional programming language as a better replacement for react to build single page application. [Official Page](https://elm-lang.org/)

Elixir is functional programming language which run on top of erlang VM. 
[Official Page](https://elixir-lang.org/)

Phoenix is Web Framework for Elixir. [Official Page](https://phoenixframework.org/)


## Installation


To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## How to navigate the codebase

<bold>Front end: </bold>

All the front end logic lives in `assets/src/Main.elm`

All of the images lives in `assets/static/images`

<bold>Back end: </bold>

All the domain logic lives in `lib/cryptomonitor`


