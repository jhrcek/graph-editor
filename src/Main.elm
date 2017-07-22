module Main exposing (..)

import Graph exposing (Graph, NodeContext, NodeId)
import GraphUtil exposing (crashIfNodeNotInGraph, setNodeText, updateLabelInNode, updateNodeInContext)
import Html exposing (Html)
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
                    GraphUtil.insertNode newNode model.graph
            in
                ( { model | graph = newGraph, newNodeId = model.newNodeId + 1 }
                , Cmd.none
                )

        NodeDrag dragMsg ->
            ( processDragMsg dragMsg model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        NodeEditStart nodeId ->
            let
                editedNode =
                    GraphUtil.getNode nodeId model.graph
            in
                ( { model | editorMode = NodeEditMode (Just editedNode) }, Cmd.none )

        NodeEditConfirm nodeId newLabel ->
            ( { model | graph = updateNodeLabel nodeId newLabel model.graph, editorMode = NodeEditMode Nothing }, Cmd.none )

        NodeLabelEdit nodeId newNodeText ->
            let
                newEditorMode =
                    case model.editorMode of
                        NodeEditMode (Just node) ->
                            NodeEditMode <| Just <| setNodeText newNodeText node

                        _ ->
                            model.editorMode
            in
                ( { model | editorMode = newEditorMode }, Cmd.none )

        StartNodeOfEdgeSelected nodeId ->
            ( { model | editorMode = EdgeEditMode (FromSelected nodeId) }, Cmd.none )

        EndNodeOfEdgeSelected endNodeId ->
            let
                newGraph =
                    case model.editorMode of
                        EdgeEditMode (FromSelected startNodeId) ->
                            GraphUtil.insertEdge startNodeId endNodeId model.graph

                        _ ->
                            model.graph
            in
                ( { model | graph = newGraph, editorMode = EdgeEditMode NothingSelected }, Cmd.none )

        UnselectStartNodeOfEdge ->
            ( { model | editorMode = EdgeEditMode NothingSelected }, Cmd.none )

        DeleteNode nodeId ->
            ( { model | graph = Graph.remove nodeId model.graph }, Cmd.none )

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
    Graph.update nodeId (Maybe.map (updateNodeInContext (GraphUtil.setNodeText newNodeText))) graph


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
