module Main exposing (..)

import Html exposing (Html)
import Graph exposing (Graph)
import Visualization.Force as Force


type Msg
    = NoOp


type alias Model =
    Graph GraphNode ()


type alias Labeled =
    { label : String }


type alias GraphNode =
    Force.Entity Int Labeled


init : ( Model, Cmd Msg )
init =
    ( Graph.empty, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model
    , Cmd.none
    )


view : Model -> Html Msg
view model =
    Html.div [] [ Html.text "Hi" ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
