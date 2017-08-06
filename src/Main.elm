module Main exposing (..)

import Graph exposing (Graph, NodeContext, NodeId, Edge)
import GraphUtil exposing (setNodeText, updateLabelInNode, updateNodeInContext)
import Html exposing (Html)
import Mouse exposing (Position)
import Types exposing (..)
import Ports
import View


initialGraph : ModelGraph
initialGraph =
    Graph.fromNodesAndEdges
        [ makeNode 0 300 300 "a"
        , makeNode 1 400 300 "bb"
        , makeNode 2 400 400 "ccc"
        , makeNode 3 500 200 "dddd"
        ]
        [ makeEdge 0 1 "edge 1"
        , makeEdge 1 2 "edge 2"
        , makeEdge 1 3 "edge 3"
        ]


init : ( Model, Cmd Msg )
init =
    ( { graph = initialGraph
      , newNodeId = Graph.size initialGraph
      , draggedNode = Nothing
      , editorMode = NodeEditMode Nothing
      }
    , Graph.nodeIds initialGraph
        |> List.map Ports.requestNodeTextBoundingBox
        |> Cmd.batch
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CreateNode { x, y } ->
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

        NodeEditStart nodeId ->
            let
                editedNode =
                    GraphUtil.getNode nodeId model.graph
            in
                ( { model | editorMode = NodeEditMode (Just editedNode) }, Cmd.none )

        NodeEditConfirm nodeId newNodeText ->
            ( { model | graph = updateNodeLabel nodeId (UnknownSize newNodeText) model.graph, editorMode = NodeEditMode Nothing }
            , Ports.requestNodeTextBoundingBox nodeId
            )

        NodeLabelEdit nodeId newNodeText ->
            let
                newEditorMode =
                    case model.editorMode of
                        NodeEditMode (Just node) ->
                            NodeEditMode <| Just <| setNodeText (UnknownSize newNodeText) node

                        _ ->
                            model.editorMode
            in
                ( { model | editorMode = newEditorMode }, Cmd.none )

        StartNodeOfEdgeSelected nodeId ->
            let
                selectedNodeLabel =
                    GraphUtil.getNode nodeId model.graph |> .label
            in
                ( { model | editorMode = EdgeEditMode (FromSelected nodeId { x = selectedNodeLabel.x, y = selectedNodeLabel.y }) }, Cmd.none )

        EndNodeOfEdgeSelected endNodeId ->
            let
                newGraph =
                    case model.editorMode of
                        EdgeEditMode (FromSelected startNodeId _) ->
                            GraphUtil.insertEdge startNodeId endNodeId model.graph

                        _ ->
                            model.graph
            in
                ( { model | graph = newGraph, editorMode = EdgeEditMode NothingSelected }, Cmd.none )

        UnselectStartNodeOfEdge ->
            ( { model | editorMode = EdgeEditMode NothingSelected }, Cmd.none )

        PreviewEdgeEndpointPositionChanged mousePosition ->
            ( setMousePositionIfCreatingEdge mousePosition model, Cmd.none )

        DeleteNode nodeId ->
            ( { model | graph = Graph.remove nodeId model.graph }, Cmd.none )

        DeleteEdge fromId toId ->
            ( { model | graph = GraphUtil.removeEdge fromId toId model.graph }, Cmd.none )

        SetMode mode ->
            ( { model | editorMode = mode }, Cmd.none )

        SetBoundingBox bbox ->
            let
                _ =
                    Debug.log "bbox" bbox
            in
                ( { model | graph = updateBoundingBox bbox model.graph }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


updateBoundingBox : BBox -> ModelGraph -> ModelGraph
updateBoundingBox bbox graph =
    case String.split ":" bbox.elementId of
        nodeIdString :: [] ->
            case String.toInt nodeIdString of
                Ok nodeId ->
                    let
                        oldNodeText : String
                        oldNodeText =
                            (GraphUtil.getNode nodeId graph |> .label |> .nodeText |> nodeTextToString)
                    in
                        updateNodeLabel nodeId (Sized bbox oldNodeText) graph

                Err er ->
                    Debug.crash <| "Failed to parse node id from " ++ bbox.elementId

        edgeFromIdStr :: edgeToIdStr :: [] ->
            --TODO updating edge label bounding box
            graph

        _ ->
            graph


setMousePositionIfCreatingEdge : Mouse.Position -> Model -> Model
setMousePositionIfCreatingEdge mousePosition model =
    let
        newEditorMode =
            case model.editorMode of
                EdgeEditMode (FromSelected nodeId _) ->
                    EdgeEditMode (FromSelected nodeId mousePosition)

                _ ->
                    model.editorMode
    in
        { model | editorMode = newEditorMode }


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


updateNodeLabel : NodeId -> NodeText -> ModelGraph -> ModelGraph
updateNodeLabel nodeId newNodeText graph =
    Graph.update nodeId (Maybe.map (updateNodeInContext (GraphUtil.setNodeText newNodeText))) graph


makeNode : NodeId -> Int -> Int -> String -> GraphNode
makeNode id x y nodeText =
    { id = id
    , label = makeNodeLabel x y nodeText
    }


makeNodeLabel : Int -> Int -> String -> NodeLabel
makeNodeLabel x y nodeText =
    { nodeText = UnknownSize nodeText
    , x = x
    , y = y
    }


makeEdge : NodeId -> NodeId -> String -> GraphEdge
makeEdge from to lbl =
    Edge from to (EdgeLabel lbl)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ nodeDragDropSubscriptions model.draggedNode
        , edgeCreationSubscriptions model.editorMode
        , Ports.setBoundingBox SetBoundingBox
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
        EdgeEditMode (FromSelected _ _) ->
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
