module Main exposing (..)

import Browser
import Html exposing (Html, text, br, div, h1, button, input, label, img, li, ul, a, i, span, p, h4, h2, h6, h3, h5, h4, table, thead, td, tr, th, tbody)
import Html.Attributes exposing (src, placeholder, class, href, name, type_, attribute, id, alt, checked)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field, string, float, map3, map5, map7, map8, int, list, decodeString, at)
import Debug exposing (log)



---- MODEL ----


type alias Model =
    {activemenu: ActiveMenu, bestPrice : BestPrice, priceconversion: PriceConvertion, odd: Bool, loadcoin: LoadingStatus, loadBestPrice : LoadingStatus, availableExchange: (List String), allExchange: (List Exchange), activeCoin: String, resources: Resources, raw: String, error: Http.Error}


init : ( Model, Cmd Msg )
init =
    ( {activemenu= Home, bestPrice = {coin = initBestCoin, detail = initBestInfoDetail, results = []}, priceconversion = USD, odd = True, loadcoin = Loading, loadBestPrice = Loading, availableExchange = [], allExchange = [], activeCoin = "", resources = {coins = [], exchanges = []}, raw = "", error = Http.Timeout}, initResources )


initBestInfoDetail =
                        { buyFrom = ""
                        , buyPrice = 0.0 
                        , currency = "USD"
                        , percentage = ""
                        , sellPrice = 0.0
                        , sellTo = ""
                        , summary = ""
                        }


initBestCoin = 
                  { logo = ""
                  , name = ""
                  , symbol = ""
                  }    

---- TYPE ----


type ActiveMenu = 
                Home 
                | Coins 
                | Exchanges
                | Settings
                | CoinDetail


type LoadingStatus = Failure Http.Error
                | Loading
                | Success


type alias Coin =
                  { logo : String
                  , name : String
                  , symbol: String
                  }

type alias Exchange =
                  { description : String
                  , id : Int                  
                  , logo : String
                  , name: String
                  , symbol: String
                  , url: String                  
                  , year : Int
                  }


type alias BestInfoResults =
                        { exchange : String
                        , floatAsk : Float
                        , floatBid : Float 
                        , logo : String
                        , url : String
                        , name : String                        
                        , bidVolume : String
                        , askVolume : String
                        }

type alias BestInfoDetail =
                        { buyFrom : String
                        , buyPrice : Float 
                        , currency : String
                        , percentage : String                          
                        , sellPrice : Float                      
                        , sellTo : String
                        , summary : String
                        }

type alias BestPrice = 
                    { coin : Coin, detail : BestInfoDetail, results : List BestInfoResults }


type alias Resources = 
                    { coins : List Coin
                    , exchanges : List Exchange
                    }

type Msg
    = GoTo ActiveMenu
    | SwitcePriceConvertion PriceConvertion
    | GotResources (Result Http.Error String)  
    | GotBestPrice (Result Http.Error String)
    | GotBestBTC (Result Http.Error String)            
    | ToggleExchange String
    | GoDetail String

type PriceConvertion
    = USD
    | BTC
    | EUR
    | THB  


---- DECODER ----


decoder : String -> Resources
decoder input =
    case decodeString decodeResources input of
        Ok resource -> resource
        Err err -> {coins = [], exchanges = []}


decodeResources : Decoder Resources
decodeResources =
    Json.Decode.map2 Resources
        (field "coins" <| list decodeCoin)
        (field "exchanges" <| list decodeExchange)


decodeBestInfo : String -> BestPrice
decodeBestInfo input =
    case decodeString decodeBestPrice input of
        Ok resource -> resource
        Err err -> {coin = initBestCoin, detail = initBestInfoDetail, results = []}   


decodeBestPrice : Decoder BestPrice
decodeBestPrice =
    Json.Decode.map3 BestPrice
        (field "coin" <| decodeCoin)
        (field "detail" <| decodeBestInfoDetail)
        (field "results" <| list decodeBestInfoResult) 

decodeCoin : Decoder Coin
decodeCoin = 
    map3 Coin
        (field "logo" string)
        (field "name" string)
        (field "symbol" string)

decodeExchange : Decoder Exchange
decodeExchange = 
    map7 Exchange
        (field "description" string)
        (field "id" int)
        (field "logo" string)
        (field "name" string)
        (field "symbol" string)
        (field "url" string)
        (field "year" int) 

decodeBestInfoResult : Decoder BestInfoResults
decodeBestInfoResult = 
    map8 BestInfoResults
        (field "exchange" string)
        (field "float_ask" float)
        (field "float_bid" float)
        (field "logo" string)
        (field "url" string)
        (field "name" string)        
        (field "ask_volume" string)
        (field "bid_volume" string)

decodeBestInfoDetail : Decoder BestInfoDetail
decodeBestInfoDetail = 
    map7 BestInfoDetail
        (field "buy_from" string)
        (field "buy_price" float)
        (field "currency" string)        
        (field "deal_percentage" string)
        (field "sell_price" float)           
        (field "sell_to" string)     
        (field "summary" string)                

---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoTo menu -> 
            if menu == Home then
                ( {model | activemenu = menu, odd = not model.odd, activeCoin = "" }, getBestBTC )
            else
                ( {model | activemenu = menu, odd = not model.odd, activeCoin = "" }, Cmd.none )

        SwitcePriceConvertion cur -> 
            ( {model | priceconversion = cur }, Cmd.none )  

        ToggleExchange exchange ->
            ( {model | availableExchange = (toggleExchange model exchange)}, Cmd.none )

        GoDetail coin ->
            ( {model | activemenu = CoinDetail, loadBestPrice = Loading, odd = not model.odd, activeCoin = coin}, getBestPrice coin model)       

        GotBestBTC result ->
              case result of
                Ok rawString ->
                  ( {model | loadBestPrice = Success, raw = rawString, bestPrice = decodeBestInfo rawString}, Cmd.none)

                Err error ->
                  ( {model | loadBestPrice = Failure error, error = error}, Cmd.none) 

        GotBestPrice result ->
              case result of
                Ok rawString ->
                  ( {model | loadBestPrice = Success, raw = rawString, bestPrice = decodeBestInfo rawString}, Cmd.none)

                Err error ->
                  ( {model | loadBestPrice = Failure error, error = error}, Cmd.none) 

        GotResources result ->
              case result of
                Ok rawString ->
                    let 
                        resource = decoder rawString
                    in
                  ( {model | loadcoin = Success, resources = resource, availableExchange = activateAllExchange resource.exchanges}, getBestBTC)

                Err error ->
                  ( {model | loadcoin = Failure error, error = error}, Cmd.none) 


---- HELPER ----


activateAllExchange: List Exchange -> List String
activateAllExchange exchanges =
    List.map (\n -> n.symbol) exchanges



toggleExchange : Model -> String -> (List String)
toggleExchange model exchange =
    if List.member exchange model.availableExchange then
        List.filter (\x -> x /= exchange) model.availableExchange
    else
        exchange :: model.availableExchange


tagActiveMenu : Model -> ActiveMenu -> String 
tagActiveMenu model menu =
    if model.activemenu == menu then
        "active"
    else
        if (model.activemenu == CoinDetail) && (menu == Coins) then
            "active"
        else
            ""

checkCurrentCurrency: Model -> PriceConvertion -> Bool
checkCurrentCurrency model cur =
    if model.priceconversion == cur then
        True
    else
        False

isExchangeEnabled: Model -> String -> Bool
isExchangeEnabled model exchange =
    List.member exchange model.availableExchange


getBestBTC : Cmd Msg
getBestBTC = Http.get
      { url = "http://cryptominitor.xyz/api/best?coin=BTC&convertion=USD&exchange[]=binance&exchange[]=coinbene&exchange[]=okex&exchange[]=coineal&exchange[]=tokenomy&exchange[]=bitfinex&exchange[]=indodax&exchange[]=kucoin"
      , expect = Http.expectString GotBestBTC
      }


initResources : Cmd Msg
initResources = Http.get
      { url = "http://cryptomonitor.xyz/api/resources"
      , expect = Http.expectString GotResources
      }

getBestPrice : String -> Model -> Cmd Msg
getBestPrice coin model = 
    let
        params = "?coin=" ++ coin ++ stringifyExchanges model
        conversion = stringifyConversion model
    in
        Http.get
          { url = "http://cryptomonitor.xyz/api/best" ++ params ++ conversion
          , expect = Http.expectString GotBestPrice
          }


stringifyExchanges : Model -> String
stringifyExchanges model =
    List.map (\x -> "&exchange[]=" ++ x) model.availableExchange |> String.concat


stringifyConversion : Model -> String
stringifyConversion model =
    case model.priceconversion of
        USD -> "&convertion=USD" 
        BTC -> "&convertion=BTC"
        EUR -> "&convertion=EUR"
        THB -> "&convertion=THB"


---- VIEW ----


view : Model -> Html Msg
view model =
    div [] [
            viewHeader
            , div [ class "slim-navbar" ]
                [ div [ class "container" ]
                    [ ul [ class "nav" ]
                        [ li [ class ("nav-item " ++ tagActiveMenu model Home) ]
                            [ a [ class "nav-link", href "#", onClick (GoTo Home) ]
                                [ i [ class "icon ion-ios-home-outline" ]
                                    []
                                , span []
                                    [ text "Home" ]
                                ]
                            ]
                        , li [ class ("nav-item " ++ tagActiveMenu model Coins) ]
                            [ a [ class "nav-link", href "#coins", onClick (GoTo Coins) ]
                                [ i [ class "icon ion-ios-analytics-outline" ]
                                    []
                                , span []
                                    [ text "Coins" ]
                                ]
                            ]
                        , li [ class ("nav-item " ++ tagActiveMenu model Exchanges) ]
                            [ a [ class "nav-link", href "#exchange", onClick (GoTo Exchanges) ]
                                [ i [ class "icon ion-ios-shuffle" ]
                                    []
                                , span []
                                    [ text "Exchanges" ]
                                ]
                            ]
                        , li [ class ("nav-item " ++ tagActiveMenu model Settings) ]
                            [ a [ class "nav-link", href "#setting", onClick (GoTo Settings) ]
                                [ i [ class "icon ion-ios-gear-outline" ]
                                    []
                                , span []
                                    [ text "Settings" ]
                                ]
                            ]
                        ]
                    ]
                ]
            , viewContent model
            , viewFooter
        ]


viewContent : Model -> Html Msg
viewContent model =
    case model.activemenu of
        Home -> viewHome model
        Coins -> viewCoins model
        Exchanges -> viewExchanges model
        Settings -> viewSettings model
        CoinDetail -> viewCoinDetail model


viewHome : Model -> Html Msg
viewHome model = 
  let
    fadeClass = 
      if model.odd then "slim-mainpanel a1" else "slim-mainpanel a2" 
  in    
    div [ class fadeClass ]
        [ div [ class "container pd-t-50" ]
            [ div [ class "dash-headline-X", attribute "style" "margin-top: 20px;" ]
                [ div [ class "row" ]
                        [ div [ class "col-lg-6" ]
                            [ h3 [ class "tx-inverse mg-b-15" ]
                                [ text "Welcome to Cryptomonitor" ]
                            , p [ class "mg-b-40" ]
                                [ text "We are fetching data to multiple Cryptoexchanges to find the cheapest price and market arbitrage potential. The data fetch in realtime in concurrent connection to give you the latest price." ]
                            , h6 [ class "slim-card-title mg-b-15" ]
                                [ text "BITCOIN PRICES" ]
                            , div [ class "row no-gutters" ]
                                [ div [ class "col-sm-6" ]
                                    [ div [ class "card card-earning-summary" ]
                                        [ h6 []
                                            [ text "Lowest Ask" ]
                                        , h1 []
                                            [ text <| "$ " ++ (String.fromFloat <| model.bestPrice.detail.buyPrice)  ]
                                        , span []
                                            [ text <| "from " ++  model.bestPrice.detail.buyFrom ]
                                        ]
                                    ]
                                , div [ class "col-sm-6" ]
                                    [ div [ class "card card-earning-summary mg-sm-l--1 bd-t-0 bd-sm-t" ]
                                        [ h6 []
                                            [ text "Highest Bid" ]
                                        , h1 []
                                            [ text <| "$" ++ (String.fromFloat <| model.bestPrice.detail.sellPrice)]
                                        , span []
                                            [ text <| "to " ++  model.bestPrice.detail.sellTo ]
                                        ]
                                    ]
                                ]
                            ]
                        , div [ class "col-lg-6 mg-t-20 mg-sm-t-30 mg-lg-t-0" ]
                            [ div [ class "card card-dash-headline" ]
                                [ h4 []
                                    [ text "Get the latest Price Summary" ]
                                , p []
                                    [ text "Currently we connect to 10 Crypto exchange and monitoring 36 Top Cryptocurrency. The amount of supported exchanges and cryptocurrency/token will be increased overtime." ]
                                , div [ class "row row-sm" ]
                                    [ div [ class "col-sm-6" ]
                                        [ a [ class "btn btn-primary btn-block", href "#", onClick (GoTo Home) ]
                                            [ text "Refresh Price" ]
                                        ]
                                    , div [ class "col-sm-6 mg-t-10 mg-sm-t-0" ]
                                        [ a [ class "btn btn-success btn-block", href "#", onClick (GoTo Coins) ]
                                            [ text "Other Coins" ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
            , div [ class "row mg-t-20" ]
                [ div [ class "col-lg-12" ]
                    [ div [ class "card card-table" ]
                        [ div [ class "card-header" ]
                            [ h6 [ class "slim-card-title" ]
                                [ img [ alt  model.bestPrice.coin.name, src  model.bestPrice.coin.logo, attribute "style" "max-height: 30px; margin-right: 30px;" ]
                                    []
                                , text <|  model.bestPrice.coin.name ++ " Market"
                                ]
                            ]
                        , div [ class "table-responsive" ]
                            [ table [ class "table mg-b-0 tx-13", id "arbitrage" ]
                                [ thead []
                                    [ tr [ class "tx-10" ]
                                        [ th []
                                            []
                                        , th [ class "pd-y-5" ]
                                            [ text "Exchanges" ]
                                        , th [ class "pd-y-5" ]
                                            [ text "Bid" ]
                                        , th [ class "pd-y-5" ]
                                            [ text "Ask" ]
                                        , th [ class "pd-y-5" ]
                                            [ text "Volume Bid" ]
                                        , th [ class "pd-y-5" ]
                                            [ text "Volume Ask" ]                                                                
                                        ]
                                    ]
                                , tbody [] ([] ++ List.map viewCoinDetailList model.bestPrice.results)
                                ]
                            ]
                        , div [ class "card-footer tx-12 pd-y-15 bg-transparent" ]
                            []
                        ]
                    ]
                ]                        

                ]
            ]
        ]


viewListCoins : Coin -> Html Msg
viewListCoins crypto =
    div [ class "col-lg-3" ]
                    [ a [ class "card-hover", href <| "#COIN-" ++ crypto.symbol, onClick (GoDetail crypto.symbol)]
                        [ div [ class "card card-info mg-t-20" ]
                            [ div [ class "card-body pd-40" ]
                                [ div [ class "d-flex justify-content-center mg-b-30" ]
                                    [ img [ alt "", src crypto.logo ]
                                        []
                                    ]
                                , h3 [ class "tx-inverse" ]
                                    [ text crypto.symbol ]
                                , h5 [ class "tx-inverse mg-b-20" ]
                                    [ text crypto.name ]
                                ]
                            ]
                        ]
                    ]


viewCoins : Model -> Html Msg
viewCoins model =
  let
    fadeClass = 
      if model.odd then "slim-mainpanel a1" else "slim-mainpanel a2" 
  in 
    case model.loadcoin of
        Loading -> viewLoader
        Failure _ -> viewError
        Success ->   
            div [ class fadeClass ]
                [ div [ class "container" ]
                    [ div [ class "row row-sm mg-t-20" ] ([] ++ List.map viewListCoins model.resources.coins)
                    ]
                ]


viewExchanges : Model -> Html Msg
viewExchanges model =
  let
    fadeClass = 
      if model.odd then "slim-mainpanel a1" else "slim-mainpanel a2" 
  in
    case model.loadcoin of
        Loading -> viewLoader
        Failure _ -> viewError
        Success ->   
            div [ class fadeClass ]
                        [ div [ class "container" ]
                            [ div [ class "row row-sm mg-t-20" ]
                                [ div [ class "col-lg-12 mg-t-20 mg-lg-t-0" ]
                                    [ div [ class "card card-table" ]
                                        [ div [ class "card-header" ]
                                            [ h6 [ class "slim-card-title" ]
                                                [ text "Exchanges" ]
                                            ]
                                        , div [ class "table-responsive" ]
                                            [ table [ class "table mg-b-0 tx-13" ]
                                                [ thead []
                                                    [ tr [ class "tx-10" ]
                                                        [ th [ class "wd-10p pd-y-5" ]
                                                            [ text " " ]
                                                        , th [ class "pd-y-5" ]
                                                            [ text "Name" ]
                                                        , th [ class "pd-y-5" ]
                                                            [ text "Year Established" ]
                                                        , th [ class "pd-y-5" ]
                                                            [ text "Description" ]
                                                        ]
                                                    ]
                                                , tbody []
                                                    ([] ++ List.map viewListExchange model.resources.exchanges)
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]    


viewListExchange : Exchange -> Html Msg
viewListExchange exchange = 
             tr []
                [ td [ class "pd-l-20" ]
                    [ img [ alt "Image", class "wd-36 rounded-circle", src exchange.logo ]
                        []
                    ]
                , td []
                    [ a [ class "tx-inverse tx-14 tx-medium d-block", href exchange.url ]
                        [ text exchange.name ]
                    , span [ class "tx-11 d-block" ]
                        [ text exchange.url ]
                    ]
                , td [ class "tx-12" ]
                    [ p []
                        [ text (String.fromInt <| exchange.year) ]
                    ]
                , td [ class "tx-12" ]
                    [ p []
                        [ text exchange.description ]
                    ]
                ]
            


viewCoinDetail : Model -> Html Msg
viewCoinDetail model = 
              let
                fadeClass = 
                  if model.odd then "slim-mainpanel a1" else "slim-mainpanel a2" 
              in
                case model.loadBestPrice of
                    Loading -> viewLoader
                    Failure _ -> viewError
                    Success -> 
                        div [ class fadeClass ]
                            [ div [ class "container" ]
                                [ div [ class "dash-headline-two mg-t-20" ]
                                    [ div []
                                        [ h4 [ class "tx-inverse mg-b-5" ]
                                            [ text ("Best Deal: " ++ model.bestPrice.detail.percentage ++ "%") ]
                                        , p [ class "mg-b-0" ]
                                            [ text model.bestPrice.detail.summary ]
                                        ]
                                    , div [ class "d-h-t-right" ]
                                        [ div [ class "summary-item" ]
                                            [ h1 []
                                                [ text <| model.bestPrice.detail.currency ++ " " ++ (String.fromFloat <| model.bestPrice.detail.buyPrice) ]
                                            , span []
                                                [ text "BUY"
                                                , br []
                                                    []
                                                , text <| "from " ++  model.bestPrice.detail.buyFrom
                                                ]
                                            ]
                                        , div [ class "summary-item" ]
                                            [ h1 []
                                                [ text  <| model.bestPrice.detail.currency ++ " " ++ (String.fromFloat <| model.bestPrice.detail.sellPrice) ]
                                            , span []
                                                [ text "SELL"
                                                , br []
                                                    []
                                                , text <| "to " ++  model.bestPrice.detail.sellTo
                                                ]
                                            ]
                                        ]
                                    ]
                                , div [ class "row row-sm mg-t-20" ]
                                    [ div [ class "col-lg-12" ]
                                        [ div [ class "card card-table" ]
                                            [ div [ class "card-header" ]
                                                [ h6 [ class "slim-card-title" ]
                                                    [ img [ alt  model.bestPrice.coin.name, src  model.bestPrice.coin.logo, attribute "style" "max-height: 30px; margin-right: 30px;" ]
                                                        []
                                                    , text <|  model.bestPrice.coin.name ++ " Market"
                                                    ]
                                                ]
                                            , div [ class "table-responsive" ]
                                                [ table [ class "table mg-b-0 tx-13", id "arbitrage" ]
                                                    [ thead []
                                                        [ tr [ class "tx-10" ]
                                                            [ th []
                                                                []
                                                            , th [ class "pd-y-5" ]
                                                                [ text "Exchanges" ]
                                                            , th [ class "pd-y-5" ]
                                                                [ text "Bid" ]
                                                            , th [ class "pd-y-5" ]
                                                                [ text "Ask" ]
                                                            , th [ class "pd-y-5" ]
                                                                [ text "Volume Bid" ]
                                                            , th [ class "pd-y-5" ]
                                                                [ text "Volume Ask" ]                                                                
                                                            ]
                                                        ]
                                                    , tbody [] ([] ++ List.map viewCoinDetailList model.bestPrice.results)
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]


viewCoinDetailList : BestInfoResults -> Html Msg
viewCoinDetailList result =
                    tr []
                        [ td [ class "pd-l-20" ]
                            [ img [ alt "Image", class "wd-36 rounded-circle", src result.logo ]
                                []
                            ]
                        , td []
                            [ a [ class "tx-inverse tx-14 tx-medium d-block", href "" ]
                                [ text result.name ]
                            , span [ class "tx-11 d-block" ]
                                [ text result.url ]
                            ]
                        , td [ class "tx-12" ]
                            [ p []
                                [ text <| String.fromFloat result.floatBid ]
                            ]
                        , td [ class "tx-12" ]
                            [ p []
                                [ text <| String.fromFloat result.floatAsk ]
                            ]
                        , td [ class "tx-12" ]
                            [ p []
                                [ text result.bidVolume ]
                            ]
                        , td [ class "tx-12" ]
                            [ p []
                                [ text result.askVolume ]
                            ]                            
                        ]


viewSettings : Model -> Html Msg
viewSettings model =
  let
    fadeClass = 
      if model.odd then "slim-mainpanel a1" else "slim-mainpanel a2" 
  in  
    case model.loadcoin of
        Loading -> viewLoader
        Failure _ -> viewError
        Success ->     
            div [ class fadeClass ]
                        [ div [ class "container" ]
                            [ div [ class "row row-sm mg-t-20" ]
                                [ div [ class "col-lg-12 mg-t-20 mg-lg-t-0" ]
                                    [ div [ class "card card-table" ]
                                        [ div [ class "card-header" ]
                                            [ h6 [ class "slim-card-title" ]
                                                [ text "Price conversion" ]
                                            ]
                                        , div [ class "row mg-t-10 mg-20" ]
                                            [ div [ class "col-lg-3" ]
                                                [ label [ class "rdiobox" ]
                                                    [ input [ checked <| checkCurrentCurrency model USD, id "USD", name "rdio", type_ "radio", onClick (SwitcePriceConvertion USD) ]
                                                        []
                                                    , span []
                                                        [ text "USD" ]
                                                    ]
                                                ]
                                            , div [ class "col-lg-3" ]
                                                [ label [ class "rdiobox" ]
                                                    [ input [ checked <| checkCurrentCurrency model THB, id "THB", name "rdio", type_ "radio", onClick (SwitcePriceConvertion THB) ]
                                                        []
                                                    , span []
                                                        [ text "THB" ]
                                                    ]
                                                ]
                                            , div [ class "col-lg-3" ]
                                                [ label [ class "rdiobox" ]
                                                    [ input [ checked <| checkCurrentCurrency model EUR, id "EUR", name "rdio", type_ "radio", onClick (SwitcePriceConvertion EUR)]
                                                        []
                                                    , span []
                                                        [ text "EUR" ]
                                                    ]
                                                ]
                                            , div [ class "col-lg-3" ]
                                                [ label [ class "rdiobox" ]
                                                    [ input [ checked <| checkCurrentCurrency model BTC, id "BTC", name "rdio", type_ "radio", onClick (SwitcePriceConvertion BTC) ]
                                                        []
                                                    , span []
                                                        [ text "BTC" ]
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            , div [ class "row row-sm mg-t-20" ]
                                [ div [ class "col-lg-12 mg-t-20 mg-lg-t-0" ]
                                    [ div [ class "card card-table" ]
                                        [ div [ class "card-header" ]
                                            [ h6 [ class "slim-card-title" ]
                                                [ text "Exchanges" ]
                                            ]
                                        , div [ class "table-responsive" ]
                                            [ table [ class "table mg-b-0 tx-13" ]
                                                [ thead []
                                                    [ tr [ class "tx-10" ]
                                                        [ th [ class "wd-10p pd-y-5" ]
                                                            [ text " " ]
                                                        , th [ class "pd-y-5" ]
                                                            [ text "Name" ]
                                                        , th [ class "pd-y-5" ]
                                                            [ text "Visibility" ]
                                                        ]
                                                    ]
                                                , tbody [] ([] ++ List.map (\n -> viewExchangeSetting n model) model.resources.exchanges)
                                                    
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                


viewExchangeSetting : Exchange -> Model -> Html Msg
viewExchangeSetting exchange model=
                            tr []
                                [ td [ class "pd-l-20" ]
                                    [ img [ alt "Image", class "wd-36 rounded-circle", src exchange.logo ]
                                        []
                                    ]
                                , td []
                                    [ a [ class "tx-inverse tx-14 tx-medium d-block", href exchange.url ]
                                        [ text exchange.name ]
                                    , span [ class "tx-11 d-block" ]
                                        [ text exchange.url ]
                                    ]
                                , td [ class "tx-12" ]
                                    [ label [ class "switch float-left" ]
                                        [ input [ checked <| isExchangeEnabled model exchange.symbol, class "primary", type_ "checkbox", onClick (ToggleExchange exchange.symbol) ]
                                            []
                                        , span [ class "slider round" ]
                                            []
                                        ]
                                    ]
                                ]  


viewHeader : Html Msg
viewHeader = 
    div [ class "slim-header" ]
        [ div [ class "container" ]
            [ div [ class "slim-header-left" ]
                [ h2 [ class "slim-logo" ]
                    [ a [ href "index.html" ]
                        [ text "cryptomonitor"
                        , span []
                            [ text "." ]
                        ]
                    ]
                , div [ class "search-box" ]
                    [ 
                    ]
                ]
            ]
        ]

viewFooter : Html Msg
viewFooter =
    div [ class "slim-footer" ]
        [ div [ class "container" ]
            [ p []
                [ text "Copyright 2019 © " ]
            ]
        ]    

viewLoader : Html Msg
viewLoader =
    div [ class "text-center bg-white mg-t-20 mg-b-30 pd-40"]
    [ i [ class "fa fa-spinner fa-spin fa-3x fa-fw" ]
        []
    , span [ class "sr-only" ]
        [ text "Loading..." ]
    ]

viewError : Html Msg
viewError =
    div [ class "page-error-wrapper" ]
        [ div []
            [ h1 [ class "error-title" ]
                [ text "503" ]
            , h5 [ class "tx-sm-24 tx-normal" ]
                [ text "The api server is unreachable" ]
            , p [ class "mg-b-50" ]
                [ text "We are working on it." ]
            , p [ class "mg-b-50" ]
                [ a [ class "btn btn-error", href "/" ]
                    [ text "Back to Home" ]
                ]
            , p [ class "error-footer" ]
                [ text "© Copyright 2018. All Rights Reserved. Devmite" ]
            ]
        ]   

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
