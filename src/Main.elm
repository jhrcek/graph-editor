module Main exposing (..)

import Graph exposing (Graph, NodeContext, NodeId)
import GraphUtil exposing (updateLabelInNode, updateNodeInContext)
import Html exposing (Html)
import Html.Attributes
import IntDict
import Mouse exposing (Position)
import Svg exposing (Svg)
import SvgMouse
import Types exposing (..)
import View


type alias Model =
    { graph : ModelGraph
    , newNodeId : Int
    , draggedNode : Maybe Drag
    }


type alias ModelGraph =
    Graph NodeLabel ()


type alias GraphNode =
    Graph.Node NodeLabel


init : ( Model, Cmd Msg )
init =
    ( { graph = Graph.empty, newNodeId = 0, draggedNode = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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

        NodeDrag dragMsg ->
            ( processDragMsg dragMsg model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


processDragMsg : DragMsg -> Model -> Model
processDragMsg msg model =
    case msg of
        DragStart nodeId xy ->
            { model | draggedNode = Just (Drag nodeId xy xy) }

        DragAt xy ->
            { model | draggedNode = Maybe.map (\{ nodeId, start } -> Drag nodeId start xy) model.draggedNode }

        DragEnd _ ->
            let
                newGraph =
                    Maybe.map (\drag -> updateDraggedNode drag model.graph) model.draggedNode
                        |> Maybe.withDefault model.graph
            in
                { model | graph = newGraph, draggedNode = Nothing }


updateDraggedNode : Drag -> ModelGraph -> ModelGraph
updateDraggedNode drag graph =
    Graph.update drag.nodeId (updateDraggedNodeInContext drag) graph


updateDraggedNodeInContext : Drag -> Maybe (NodeContext NodeLabel e) -> Maybe (NodeContext NodeLabel e)
updateDraggedNodeInContext drag =
    Maybe.map (updateNodeInContext (updateLabelInNode (getDraggedNodePosition drag)))


getDraggedNodePosition : Drag -> NodeLabel -> NodeLabel
getDraggedNodePosition { nodeId, start, current } nodeLabel =
    { nodeLabel
        | x = nodeLabel.x + current.x - start.x
        , y = nodeLabel.y + current.y - start.y
    }


insertNode : GraphNode -> ModelGraph -> ModelGraph
insertNode node =
    Graph.insert
        { node = node
        , incoming = IntDict.empty
        , outgoing = IntDict.empty
        }


view : Model -> Html Msg
view { graph, draggedNode } =
    Html.div []
        [ viewCanvas graph draggedNode
        , debugView graph draggedNode
        ]


debugView : ModelGraph -> Maybe Drag -> Html Msg
debugView graph draggedNode =
    Html.ul []
        [ Html.li [] [ Html.text <| "Nodes: " ++ toString (Graph.nodes graph) ]
        , Html.li [] [ Html.text <| "Dragged node: " ++ toString draggedNode ]
        ]


viewCanvas : ModelGraph -> Maybe Drag -> Html Msg
viewCanvas graph draggedNode =
    Svg.svg
        [ Html.Attributes.style [ ( "width", "100%" ), ( "height", "100%" ), ( "position", "fixed" ) ]
        , SvgMouse.onCanvasMouseDown CanvasClicked
        ]
        (Graph.nodes graph |> List.map (viewNode draggedNode))


viewNode : Maybe Drag -> GraphNode -> Svg Msg
viewNode mDrag node =
    let
        labelMaybeAffectedByDrag =
            case mDrag of
                Just drag ->
                    if drag.nodeId == node.id then
                        getDraggedNodePosition drag node.label
                    else
                        node.label

                Nothing ->
                    node.label
    in
        View.boxedText node.id labelMaybeAffectedByDrag


makeNode : Int -> Int -> Int -> String -> GraphNode
makeNode id x y nodeText =
    { id = id
    , label =
        { nodeText = nodeText
        , x = x
        , y = y
        }
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.draggedNode of
        Nothing ->
            Sub.none

        Just _ ->
            Sub.batch
                [ Mouse.moves (NodeDrag << DragAt)
                , Mouse.ups (NodeDrag << DragEnd)
                ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
