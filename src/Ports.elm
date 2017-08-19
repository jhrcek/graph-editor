port module Ports
    exposing
        ( requestBoundingBoxesForContext
        , requestBoundingBoxesForEverything
        , requestEdgeTextBoundingBox
        , requestNodeTextBoundingBox
        , setBoundingBox
        )

import Graph exposing (NodeContext, NodeId)
import IntDict
import Types exposing (BBox, EdgeLabel, ModelGraph, Msg, NodeLabel)


requestNodeTextBoundingBox : NodeId -> Cmd msg
requestNodeTextBoundingBox nodeId =
    requestBoundingBox (toString nodeId)


requestEdgeTextBoundingBox : NodeId -> NodeId -> Cmd msg
requestEdgeTextBoundingBox fromId toId =
    requestBoundingBox (toString fromId ++ ":" ++ toString toId)


requestBoundingBoxesForEverything : ModelGraph -> Cmd Msg
requestBoundingBoxesForEverything graph =
    let
        nodeBbReqs =
            Graph.nodeIds graph
                |> List.map requestNodeTextBoundingBox
                |> Cmd.batch

        edgeBbReqs =
            Graph.edges graph
                |> List.map (\e -> requestEdgeTextBoundingBox e.from e.to)
                |> Cmd.batch
    in
    Cmd.batch [ nodeBbReqs, edgeBbReqs ]


requestBoundingBoxesForContext : Maybe (NodeContext NodeLabel EdgeLabel) -> Cmd Msg
requestBoundingBoxesForContext mctx =
    Maybe.map requestBoundingBoxesForContextHelper mctx
        |> Maybe.withDefault Cmd.none


requestBoundingBoxesForContextHelper : NodeContext NodeLabel EdgeLabel -> Cmd Msg
requestBoundingBoxesForContextHelper ctx =
    let
        nodeId =
            ctx.node.id
    in
    Cmd.batch
        [ requestNodeTextBoundingBox nodeId
        , IntDict.keys ctx.outgoing |> List.map (\to -> requestEdgeTextBoundingBox nodeId to) |> Cmd.batch
        , IntDict.keys ctx.incoming |> List.map (\from -> requestEdgeTextBoundingBox from nodeId) |> Cmd.batch
        ]



-- request bounding box of svg element with given String id


port requestBoundingBox : String -> Cmd msg



-- receive Bounding Box from js


port setBoundingBox : (BBox -> msg) -> Sub msg
