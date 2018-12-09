module BoundingBox exposing
    ( forAllNodeAndEdgeTexts
    , forEdgeText
    , forNodeContext
    , forNodeText
    )

import Browser.Dom as Dom
import Graph exposing (NodeContext, NodeId)
import IntDict
import Task
import Types exposing (BBox, EdgeLabel, ModelGraph, Msg(..), NodeLabel, elementToBBox)


{-| Request bounding box of svg element with given String id
-}
requestBoundingBox : String -> (BBox -> Msg) -> Cmd Msg
requestBoundingBox elementId bboxToMsg =
    Dom.getElement elementId
        |> Task.attempt (Result.map (elementToBBox >> bboxToMsg) >> Result.withDefault NoOp)


forNodeText : NodeId -> Cmd Msg
forNodeText nodeId =
    requestBoundingBox
        (String.fromInt nodeId)
        (SetNodeBoundingBox nodeId)


forEdgeText : NodeId -> NodeId -> Cmd Msg
forEdgeText fromId toId =
    requestBoundingBox
        (String.fromInt fromId ++ ":" ++ String.fromInt toId)
        (SetEdgeBoundingBox fromId toId)


{-| Request bounding boxes for all node and edges in the entire graph
-}
forAllNodeAndEdgeTexts : ModelGraph -> Cmd Msg
forAllNodeAndEdgeTexts graph =
    let
        nodeBbReqs =
            Graph.nodeIds graph
                |> List.map forNodeText
                |> Cmd.batch

        edgeBbReqs =
            Graph.edges graph
                |> List.map (\e -> forEdgeText e.from e.to)
                |> Cmd.batch
    in
    Cmd.batch [ nodeBbReqs, edgeBbReqs ]


forNodeContext : Maybe (NodeContext NodeLabel EdgeLabel) -> Cmd Msg
forNodeContext =
    Maybe.withDefault Cmd.none << Maybe.map forNodeContextHelper


forNodeContextHelper : NodeContext NodeLabel EdgeLabel -> Cmd Msg
forNodeContextHelper ctx =
    let
        nodeId =
            ctx.node.id
    in
    Cmd.batch
        [ forNodeText nodeId
        , IntDict.keys ctx.outgoing |> List.map (\to -> forEdgeText nodeId to) |> Cmd.batch
        , IntDict.keys ctx.incoming |> List.map (\from -> forEdgeText from nodeId) |> Cmd.batch
        ]
