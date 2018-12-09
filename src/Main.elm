module Main exposing (main)

import BoundingBox
import Browser
import Browser.Dom as Dom
import Browser.Events
import Export
import File.Download
import Graph exposing (NodeId)
import GraphUtil
import GraphViz.VizJs
import Json.Decode as Decode
import Ports
import Task
import Types
    exposing
        ( Drag
        , DragMsg(..)
        , EdgeLabel(..)
        , EditState(..)
        , EditorMode(..)
        , GraphNode
        , ModalState(..)
        , Model
        , ModelGraph
        , MousePosition
        , Msg(..)
        , NodeLabel
        , NodeText(..)
        , WindowSize
        , mousePositionDecoder
        , nodeLabelToString
        , setEdgeText
        )
import View


initialGraph : ModelGraph
initialGraph =
    Graph.empty


init : () -> ( Model, Cmd Msg )
init _ =
    ( { graph = initialGraph
      , newNodeId = Graph.size initialGraph
      , draggedNode = Nothing
      , editorMode = EditMode EditingNothing
      , modalState = Hidden
      , windowSize = { width = 800, height = 600 }
      }
    , Cmd.batch
        [ BoundingBox.forAllNodeAndEdgeTexts initialGraph
        , Task.perform GotViewport Dom.getViewport
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
            ( { model
                | graph = GraphUtil.insertNode newNode model.graph
                , newNodeId = model.newNodeId + 1
              }
            , BoundingBox.forNodeText model.newNodeId
            )

        NodeDrag dragMsg ->
            processDragMsg dragMsg model

        NodeLabelEditStart node ->
            ( { model | editorMode = EditMode (EditingNodeLabel node) }
            , View.focusLabelInput
            )

        NodeLabelEdit newNodeText ->
            let
                newEditorMode =
                    case model.editorMode of
                        EditMode (EditingNodeLabel node) ->
                            EditMode <| EditingNodeLabel <| GraphUtil.setNodeText (NodeText Nothing newNodeText) node

                        _ ->
                            model.editorMode
            in
            ( { model | editorMode = newEditorMode }
            , Cmd.none
            )

        NodeLabelEditConfirm ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EditMode (EditingNodeLabel node) ->
                            ( GraphUtil.updateNodeLabel node.id (NodeText Nothing (nodeLabelToString node.label)) model.graph
                            , Graph.get node.id model.graph |> BoundingBox.forNodeContext
                            )

                        _ ->
                            ( model.graph, Cmd.none )
            in
            ( { model | graph = newGraph, editorMode = EditMode EditingNothing }
            , command
            )

        EdgeLabelEditStart edge ->
            ( { model | editorMode = EditMode (EditingEdgeLabel edge) }
            , View.focusLabelInput
            )

        EdgeLabelEdit newText ->
            let
                newEditorMode =
                    case model.editorMode of
                        EditMode (EditingEdgeLabel edge) ->
                            EditMode (EditingEdgeLabel { edge | label = setEdgeText newText edge.label })

                        _ ->
                            model.editorMode
            in
            ( { model | editorMode = newEditorMode }
            , Cmd.none
            )

        EdgeLabelEditConfirm ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EditMode (EditingEdgeLabel edge) ->
                            ( GraphUtil.insertEdge edge model.graph, BoundingBox.forEdgeText edge.from edge.to )

                        _ ->
                            ( model.graph, Cmd.none )
            in
            ( { model | graph = newGraph, editorMode = EditMode EditingNothing }
            , command
            )

        StartNodeOfEdgeSelected nodeId ->
            let
                selectedNodeLabel =
                    GraphUtil.getNode nodeId model.graph |> .label
            in
            ( { model | editorMode = EditMode (CreatingEdge nodeId { x = selectedNodeLabel.x, y = selectedNodeLabel.y }) }
            , Cmd.none
            )

        EndNodeOfEdgeSelected endNodeId ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EditMode (CreatingEdge startNodeId _) ->
                            ( GraphUtil.insertEdge { from = startNodeId, to = endNodeId, label = EdgeLabel Nothing "" } model.graph
                            , BoundingBox.forEdgeText startNodeId endNodeId
                            )

                        _ ->
                            ( model.graph, Cmd.none )
            in
            ( { model | graph = newGraph, editorMode = EditMode EditingNothing }
            , command
            )

        UnselectStartNodeOfEdge ->
            ( { model | editorMode = EditMode EditingNothing }
            , Cmd.none
            )

        PreviewEdgeEndpointPositionChanged mousePosition ->
            ( setMousePositionIfCreatingEdge mousePosition model
            , Cmd.none
            )

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
            ( { model | graph = newGraph, editorMode = newEditorMode }
            , Cmd.none
            )

        DeleteEdge fromId toId ->
            ( { model | graph = GraphUtil.removeEdge fromId toId model.graph }
            , Cmd.none
            )

        SetMode mode ->
            ( { model | editorMode = mode }
            , Cmd.none
            )

        SetNodeBoundingBox nodeId bbox ->
            ( { model | graph = GraphUtil.setNodeBoundingBox nodeId bbox model.graph }
            , Cmd.none
            )

        SetEdgeBoundingBox fromNode toNode bbox ->
            ( { model | graph = GraphUtil.setEdgeBoundingBox fromNode toNode bbox model.graph }
            , Cmd.none
            )

        ModalStateChange newModalState ->
            ( { model | modalState = newModalState }
            , Cmd.none
            )

        GotViewport viewport ->
            ( { model | windowSize = extractWindowSize viewport }
            , Cmd.none
            )

        WindowResized w h ->
            ( { model
                | windowSize =
                    { width = toFloat w
                    , height = toFloat h
                    }
              }
            , Cmd.none
            )

        Download exportFormat ->
            let
                ( graphToString, fileName ) =
                    case exportFormat of
                        Types.Dot ->
                            ( Export.toDot, "graph.dot" )

                        Types.Tgf ->
                            ( Export.toTgf, "graph.tgf" )
            in
            ( model
            , File.Download.string fileName "text/plain" (graphToString model.graph)
            )

        PerformAutomaticLayout layoutEngine ->
            ( model
            , Ports.requestGraphVizPlain layoutEngine model.graph
            )

        ReceiveLayoutInfoFromGraphviz jsonVal ->
            let
                newModel =
                    GraphViz.VizJs.processGraphVizResponse jsonVal model.windowSize
                        |> Result.map (\newNodePositions -> { model | graph = GraphUtil.updateNodePositions newNodePositions model.graph })
                        |> Result.withDefault model
            in
            ( newModel
            , BoundingBox.forAllNodeAndEdgeTexts model.graph
            )

        NoOp ->
            ( model, Cmd.none )


setMousePositionIfCreatingEdge : MousePosition -> Model -> Model
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
            ( { model | draggedNode = Just (Drag nodeId xy xy) }
            , Cmd.none
            )

        DragAt xy ->
            ( { model | draggedNode = Maybe.map (\{ nodeId, start } -> Drag nodeId start xy) model.draggedNode }
            , Cmd.none
            )

        DragEnd _ ->
            let
                ( newGraph, command ) =
                    Maybe.map
                        (\drag ->
                            ( GraphUtil.updateDraggedNode drag model.graph
                              -- After dnd completed, only update bounding boxes of 1. node 2. its incoming and 3. its outgoing edges.
                            , BoundingBox.forNodeContext <| Graph.get drag.nodeId model.graph
                            )
                        )
                        model.draggedNode
                        |> Maybe.withDefault ( model.graph, Cmd.none )
            in
            ( { model | graph = newGraph, draggedNode = Nothing }
            , command
            )


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ nodeDragDropSubscriptions model.draggedNode
        , edgeCreationSubscriptions model.editorMode
        , Ports.receiveGraphVizPlain ReceiveLayoutInfoFromGraphviz
        , Browser.Events.onResize WindowResized
        ]


nodeDragDropSubscriptions : Maybe Drag -> Sub Msg
nodeDragDropSubscriptions maybeDrag =
    case maybeDrag of
        Nothing ->
            Sub.none

        Just _ ->
            Sub.batch
                [ Browser.Events.onMouseMove <|
                    Decode.map (NodeDrag << DragAt) mousePositionDecoder
                , Browser.Events.onMouseUp <|
                    Decode.map (NodeDrag << DragEnd) mousePositionDecoder
                ]


edgeCreationSubscriptions : EditorMode -> Sub Msg
edgeCreationSubscriptions editorMode =
    case editorMode of
        EditMode (CreatingEdge _ _) ->
            Browser.Events.onMouseMove <|
                Decode.map PreviewEdgeEndpointPositionChanged mousePositionDecoder

        _ ->
            Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = View.view
        , update = update
        , subscriptions = subscriptions
        }


extractWindowSize : Dom.Viewport -> WindowSize
extractWindowSize { viewport } =
    { width = viewport.width
    , height = viewport.height
    }
