module Main exposing (..)

import Graph exposing (Graph, NodeContext, NodeId)
import GraphUtil exposing (updateLabelInNode, updateNodeInContext)
import Html exposing (Html)
import IntDict
import Mouse exposing (Position)
import Types exposing (..)
import View


init : ( Model, Cmd Msg )
init =
    ( { graph = Graph.empty
      , newNodeId = 0
      , draggedNode = Nothing
      , editorMode = NodeEditMode Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CanvasClicked { x, y } ->
            let
                newNode =
                    makeNode model.newNodeId x y ""

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

        NodeEditStart nodeId nodeText ->
            ( { model | editorMode = NodeEditMode (Just ( nodeId, nodeText )) }, Cmd.none )

        NodeEditConfirm nodeId newLabel ->
            ( { model | graph = updateNodeLabel nodeId newLabel model.graph, editorMode = NodeEditMode Nothing }, Cmd.none )

        NodeLabelEdit nodeId newLabel ->
            ( { model | editorMode = NodeEditMode (Just ( nodeId, newLabel )) }, Cmd.none )

        DeleteNode nodeId ->
            ( { model | graph = Graph.remove nodeId model.graph, editorMode = NodeEditMode Nothing }, Cmd.none )

        SetMode mode ->
            ( { model | editorMode = mode }, Cmd.none )


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
    Maybe.map (updateNodeInContext (updateLabelInNode (Types.getDraggedNodePosition drag)))


updateNodeLabel : NodeId -> String -> ModelGraph -> ModelGraph
updateNodeLabel nodeId newNodeText graph =
    Graph.update nodeId (Maybe.map (updateNodeInContext (updateLabelInNode (\lbl -> { lbl | nodeText = newNodeText })))) graph


insertNode : GraphNode -> ModelGraph -> ModelGraph
insertNode node =
    Graph.insert
        { node = node
        , incoming = IntDict.empty
        , outgoing = IntDict.empty
        }


debugView : ModelGraph -> Maybe Drag -> EditorMode -> Html Msg
debugView graph draggedNode editorMode =
    Html.ul []
        [ Html.li [] [ Html.text <| "Nodes: " ++ toString (Graph.nodes graph) ]
        , Html.li [] [ Html.text <| "Dragged node: " ++ toString draggedNode ]
        , Html.li [] [ Html.text <| "Editor mode: " ++ toString editorMode ]
        ]


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
        , view = View.view
        }
