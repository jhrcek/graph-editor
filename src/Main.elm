module Main exposing (..)

import Graph exposing (Edge, Graph, NodeContext, NodeId)
import GraphUtil
import Html exposing (Html)
import Mouse exposing (Position)
import Task
import Ports
import Types exposing (..)
import View
import Window


initialGraph : ModelGraph
initialGraph =
    Graph.empty


init : ( Model, Cmd Msg )
init =
    ( { graph = initialGraph
      , newNodeId = Graph.size initialGraph
      , draggedNode = Nothing
      , editorMode = EditMode EditingNothing
      , helpEnabled = False
      , windowSize = { width = 800, height = 600 }
      }
    , Cmd.batch
        [ Ports.requestBoundingBoxesForEverything initialGraph
        , Task.perform WindowResized Window.size
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CreateNode { x, y } ->
            let
                newNode =
                    makeNode model.newNodeId x y ""
            in
                { model
                    | graph = GraphUtil.insertNode newNode model.graph
                    , newNodeId = model.newNodeId + 1
                }
                    ! [ Ports.requestNodeTextBoundingBox model.newNodeId ]

        NodeDrag dragMsg ->
            processDragMsg dragMsg model

        NodeLabelEditStart node ->
            { model | editorMode = EditMode (EditingNodeLabel node) } ! [ View.focusLabelInput ]

        NodeLabelEdit newNodeText ->
            let
                newEditorMode =
                    case model.editorMode of
                        EditMode (EditingNodeLabel node) ->
                            EditMode <| EditingNodeLabel <| GraphUtil.setNodeText (NodeText Nothing newNodeText) node

                        _ ->
                            model.editorMode
            in
                { model | editorMode = newEditorMode } ! []

        NodeLabelEditConfirm ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EditMode (EditingNodeLabel node) ->
                            ( GraphUtil.updateNodeLabel node.id (NodeText Nothing (nodeTextToString node.label.nodeText)) model.graph
                            , Graph.get node.id model.graph |> Ports.requestBoundingBoxesForContext
                            )

                        _ ->
                            ( model.graph, Cmd.none )
            in
                { model | graph = newGraph, editorMode = EditMode EditingNothing } ! [ command ]

        EdgeLabelEditStart edge ->
            { model | editorMode = EditMode (EditingEdgeLabel edge) } ! [ View.focusLabelInput ]

        EdgeLabelEdit newText ->
            let
                newEditorMode =
                    case model.editorMode of
                        EditMode (EditingEdgeLabel edge) ->
                            EditMode (EditingEdgeLabel { edge | label = setEdgeText newText edge.label })

                        _ ->
                            model.editorMode
            in
                { model | editorMode = newEditorMode } ! []

        EdgeLabelEditConfirm ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EditMode (EditingEdgeLabel edge) ->
                            ( GraphUtil.insertEdge edge model.graph, Ports.requestEdgeTextBoundingBox edge.from edge.to )

                        _ ->
                            ( model.graph, Cmd.none )
            in
                { model | graph = newGraph, editorMode = EditMode EditingNothing } ! [ command ]

        StartNodeOfEdgeSelected nodeId ->
            let
                selectedNodeLabel =
                    GraphUtil.getNode nodeId model.graph |> .label
            in
                { model | editorMode = EditMode (CreatingEdge nodeId { x = selectedNodeLabel.x, y = selectedNodeLabel.y }) } ! []

        EndNodeOfEdgeSelected endNodeId ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EditMode (CreatingEdge startNodeId _) ->
                            ( GraphUtil.insertEdge { from = startNodeId, to = endNodeId, label = EdgeLabel Nothing "" } model.graph
                            , Ports.requestEdgeTextBoundingBox startNodeId endNodeId
                            )

                        _ ->
                            ( model.graph, Cmd.none )
            in
                { model | graph = newGraph, editorMode = EditMode EditingNothing } ! [ command ]

        UnselectStartNodeOfEdge ->
            { model | editorMode = EditMode EditingNothing } ! []

        PreviewEdgeEndpointPositionChanged mousePosition ->
            setMousePositionIfCreatingEdge mousePosition model ! []

        DeleteNode nodeId ->
            let
                newGraph =
                    Graph.remove nodeId model.graph

                newEditorMode =
                    --after last node deleted switch back to node creation mode
                    if Graph.isEmpty newGraph then
                        EditMode EditingNothing
                    else
                        model.editorMode
            in
                { model | graph = newGraph, editorMode = newEditorMode } ! []

        DeleteEdge fromId toId ->
            { model | graph = GraphUtil.removeEdge fromId toId model.graph } ! []

        SetMode mode ->
            { model | editorMode = mode } ! []

        SetBoundingBox bbox ->
            { model | graph = updateBoundingBox bbox model.graph } ! []

        ToggleHelp flag ->
            { model | helpEnabled = flag } ! []

        WindowResized sz ->
            { model | windowSize = sz } ! []

        NoOp ->
            model ! []


updateBoundingBox : BBox -> ModelGraph -> ModelGraph
updateBoundingBox bbox graph =
    case String.split ":" bbox.elementId of
        nodeIdString :: [] ->
            case String.toInt nodeIdString of
                Ok nodeId ->
                    let
                        (NodeText _ text) =
                            GraphUtil.getNode nodeId graph |> .label |> .nodeText
                    in
                        GraphUtil.updateNodeLabel nodeId (NodeText (Just bbox) text) graph

                Err er ->
                    Debug.crash <| "Failed to parse node id from " ++ bbox.elementId

        edgeFromIdStr :: edgeToIdStr :: [] ->
            case Result.map2 (,) (String.toInt edgeFromIdStr) (String.toInt edgeToIdStr) of
                Ok ( fromId, toId ) ->
                    let
                        (EdgeLabel _ text) =
                            GraphUtil.getEdgeLabel fromId toId graph
                    in
                        GraphUtil.insertEdge { from = fromId, to = toId, label = (EdgeLabel (Just bbox) text) } graph

                _ ->
                    Debug.crash <| "Failed to parse edge endpoint ids from " ++ bbox.elementId

        _ ->
            graph


setMousePositionIfCreatingEdge : Mouse.Position -> Model -> Model
setMousePositionIfCreatingEdge mousePosition model =
    let
        newEditorMode =
            case model.editorMode of
                EditMode (CreatingEdge nodeId _) ->
                    EditMode (CreatingEdge nodeId mousePosition)

                _ ->
                    model.editorMode
    in
        { model | editorMode = newEditorMode }


processDragMsg : DragMsg -> Model -> ( Model, Cmd Msg )
processDragMsg msg model =
    case msg of
        DragStart nodeId xy ->
            { model | draggedNode = Just (Drag nodeId xy xy) } ! []

        DragAt xy ->
            { model | draggedNode = Maybe.map (\{ nodeId, start } -> Drag nodeId start xy) model.draggedNode } ! []

        DragEnd _ ->
            let
                ( newGraph, command ) =
                    Maybe.map
                        (\drag ->
                            ( GraphUtil.updateDraggedNode drag model.graph
                              -- After dnd completed, only update bounding boxes of 1. node 2. its incoming and 3. its outgoing edges.
                            , Ports.requestBoundingBoxesForContext <| Graph.get drag.nodeId model.graph
                            )
                        )
                        model.draggedNode
                        |> Maybe.withDefault ( model.graph, Cmd.none )
            in
                { model | graph = newGraph, draggedNode = Nothing } ! [ command ]


makeNode : NodeId -> Int -> Int -> String -> GraphNode
makeNode id x y nodeText =
    { id = id
    , label = makeNodeLabel x y nodeText
    }


makeNodeLabel : Int -> Int -> String -> NodeLabel
makeNodeLabel x y nodeText =
    { nodeText = NodeText Nothing nodeText
    , x = x
    , y = y
    }


makeEdge : NodeId -> NodeId -> String -> GraphEdge
makeEdge from to lbl =
    Edge from to (EdgeLabel Nothing lbl)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ nodeDragDropSubscriptions model.draggedNode
        , edgeCreationSubscriptions model.editorMode
        , Ports.setBoundingBox SetBoundingBox
        , Window.resizes WindowResized
        ]


nodeDragDropSubscriptions : Maybe Drag -> Sub Msg
nodeDragDropSubscriptions maybeDrag =
    case maybeDrag of
        Nothing ->
            Sub.none

        Just _ ->
            Sub.batch
                [ Mouse.moves (NodeDrag << DragAt)
                , Mouse.ups (NodeDrag << DragEnd)
                ]


edgeCreationSubscriptions : EditorMode -> Sub Msg
edgeCreationSubscriptions editorMode =
    case editorMode of
        EditMode (CreatingEdge _ _) ->
            Mouse.moves PreviewEdgeEndpointPositionChanged

        _ ->
            Sub.none


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = View.view
        }
