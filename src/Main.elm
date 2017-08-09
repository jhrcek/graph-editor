module Main exposing (..)

import Graph exposing (Graph, NodeContext, NodeId, Edge)
import GraphUtil
import Html exposing (Html)
import Mouse exposing (Position)
import Types exposing (..)
import Ports
import View


initialGraph : ModelGraph
initialGraph =
    Graph.fromNodesAndEdges
        [ makeNode 0 550 300 "Socks"
        , makeNode 1 400 300 "Shoes"
        , makeNode 2 300 400 "Pan"
        , makeNode 3 500 100 "Propagation"
        , makeNode 4 800 50 "Category"
        , makeNode 5 400 500 "Determinism"
        , makeNode 6 700 350 "Conjugation"
        , makeNode 7 250 150 "Infiltration"
        , makeNode 8 50 350 "Joystick"
        , makeNode 9 562 200 "Knife"
        ]
        [ makeEdge 0 1 "edge 1"
        , makeEdge 1 2 "edge 2"
        , makeEdge 1 3 "edge 3"
        , makeEdge 1 5 "edge 4"
        , makeEdge 1 3 "edge 5"
        , makeEdge 8 7 "edge 6"
        , makeEdge 4 3 "edge 7"
        , makeEdge 5 6 "edge 8"
        , makeEdge 1 5 "edge 9"
        , makeEdge 9 3 "edge 10"
        , makeEdge 8 7 "edge 11"
        , makeEdge 9 0 "edge 12"
        , makeEdge 2 8 "edge 13"
        ]


init : ( Model, Cmd Msg )
init =
    ( { graph = initialGraph
      , newNodeId = Graph.size initialGraph
      , draggedNode = Nothing
      , editorMode = NodeEditMode Nothing
      }
    , requestBoundingBoxes initialGraph
    )


requestBoundingBoxes : ModelGraph -> Cmd Msg
requestBoundingBoxes graph =
    let
        nodeBbReqs =
            Graph.nodeIds graph
                |> List.map Ports.requestNodeTextBoundingBox
                |> Cmd.batch

        edgeBbReqs =
            Graph.edges graph
                |> List.map (\e -> Ports.requestEdgeTextBoundingBox e.from e.to)
                |> Cmd.batch
    in
        Cmd.batch [ nodeBbReqs, edgeBbReqs ]


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
            { model | editorMode = NodeEditMode (Just node) } ! []

        NodeLabelEdit newNodeText ->
            let
                newEditorMode =
                    case model.editorMode of
                        NodeEditMode (Just node) ->
                            NodeEditMode <| Just <| GraphUtil.setNodeText (NodeText Nothing newNodeText) node

                        _ ->
                            model.editorMode
            in
                { model | editorMode = newEditorMode } ! []

        NodeLabelEditConfirm ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        NodeEditMode (Just node) ->
                            ( GraphUtil.updateNodeLabel node.id (NodeText Nothing (nodeTextToString node.label.nodeText)) model.graph
                            , Ports.requestNodeTextBoundingBox node.id
                            )

                        _ ->
                            ( model.graph, Cmd.none )
            in
                { model | graph = newGraph, editorMode = NodeEditMode Nothing } ! [ command ]

        EdgeLabelEditStart edge ->
            { model | editorMode = EdgeEditMode (EditingEdgeLabel edge) } ! []

        EdgeLabelEdit newText ->
            let
                newEditorMode =
                    case model.editorMode of
                        EdgeEditMode (EditingEdgeLabel edge) ->
                            EdgeEditMode (EditingEdgeLabel { edge | label = setEdgeText newText edge.label })

                        _ ->
                            model.editorMode
            in
                { model | editorMode = newEditorMode } ! []

        EdgeLabelEditConfirm ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EdgeEditMode (EditingEdgeLabel edge) ->
                            ( GraphUtil.insertEdge edge model.graph, Ports.requestEdgeTextBoundingBox edge.from edge.to )

                        _ ->
                            ( model.graph, Cmd.none )
            in
                { model | graph = newGraph, editorMode = EdgeEditMode NothingSelected } ! [ command ]

        StartNodeOfEdgeSelected nodeId ->
            let
                selectedNodeLabel =
                    GraphUtil.getNode nodeId model.graph |> .label
            in
                { model | editorMode = EdgeEditMode (FromSelected nodeId { x = selectedNodeLabel.x, y = selectedNodeLabel.y }) } ! []

        EndNodeOfEdgeSelected endNodeId ->
            let
                ( newGraph, command ) =
                    case model.editorMode of
                        EdgeEditMode (FromSelected startNodeId _) ->
                            ( GraphUtil.insertEdge { from = startNodeId, to = endNodeId, label = EdgeLabel Nothing "\t" } model.graph
                            , Ports.requestEdgeTextBoundingBox startNodeId endNodeId
                            )

                        _ ->
                            ( model.graph, Cmd.none )
            in
                { model | graph = newGraph, editorMode = EdgeEditMode NothingSelected } ! [ command ]

        UnselectStartNodeOfEdge ->
            { model | editorMode = EdgeEditMode NothingSelected } ! []

        PreviewEdgeEndpointPositionChanged mousePosition ->
            setMousePositionIfCreatingEdge mousePosition model ! []

        DeleteNode nodeId ->
            { model | graph = Graph.remove nodeId model.graph } ! []

        DeleteEdge fromId toId ->
            { model | graph = GraphUtil.removeEdge fromId toId model.graph } ! []

        SetMode mode ->
            { model | editorMode = mode } ! []

        SetBoundingBox bbox ->
            { model | graph = updateBoundingBox bbox model.graph } ! []

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
                EdgeEditMode (FromSelected nodeId _) ->
                    EdgeEditMode (FromSelected nodeId mousePosition)

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
                newGraph =
                    Maybe.map (\drag -> GraphUtil.updateDraggedNode drag model.graph) model.draggedNode
                        |> Maybe.withDefault model.graph
            in
                { model | graph = newGraph, draggedNode = Nothing } ! [ requestBoundingBoxes model.graph ]


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
