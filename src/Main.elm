module Main exposing (..)

import Graph exposing (Graph)
import Html exposing (Html)
import Html.Attributes
import Svg exposing (Svg)
import Types exposing (..)
import SvgMouse
import View
import IntDict


type alias Model =
    { graph : ModelGraph
    , newNodeId : Int
    }


type alias ModelGraph =
    Graph NodeLabel ()


type alias GraphNode =
    Graph.Node NodeLabel


type alias NodeLabel =
    { nodeText : String
    , x : Int
    , y : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { graph = Graph.empty, newNodeId = 0 }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "msg" msg
    in
        case msg of
            CanvasClicked { x, y } ->
                let
                    newNode =
                        makeNode model.newNodeId x y "Test"

                    newGraph =
                        insertNode newNode model.graph
                in
                    ( { model | graph = newGraph, newNodeId = model.newNodeId + 1 }
                    , Cmd.none
                    )

            NoOp ->
                ( model, Cmd.none )


insertNode : GraphNode -> ModelGraph -> ModelGraph
insertNode node =
    Graph.insert
        { node = node
        , incoming = IntDict.empty
        , outgoing = IntDict.empty
        }


view : Model -> Html Msg
view { graph, newNodeId } =
    Svg.svg [ Html.Attributes.style [ ( "width", "100%" ), ( "height", "100%" ), ( "position", "fixed" ) ], SvgMouse.onClick CanvasClicked ]
        (Graph.nodes graph |> List.map viewNode)


viewNode : GraphNode -> Svg Msg
viewNode node =
    let
        lab =
            node.label
    in
        View.boxedText node.id lab.x lab.y lab.nodeText


makeNode : Int -> Int -> Int -> String -> GraphNode
makeNode id x y nodeText =
    { id = id
    , label =
        { nodeText = nodeText
        , x = x
        , y = y
        }
    }


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
