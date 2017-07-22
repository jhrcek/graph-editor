module GraphUtil
    exposing
        ( updateNodeInContext
        , updateLabelInNode
        , setNodeText
        , insertNode
        , insertEdge
        , crashIfNodeNotInGraph
        , getNode
        )

import Graph exposing (Node, NodeContext, NodeId)
import Types exposing (GraphNode, ModelGraph, NodeLabel)
import IntDict


updateNodeInContext : (Node n -> Node n) -> NodeContext n e -> NodeContext n e
updateNodeInContext nodeUpdater ({ node } as ctx) =
    { ctx | node = nodeUpdater node }


updateLabelInNode : (lab -> lab) -> Node lab -> Node lab
updateLabelInNode labelUpdater node =
    { node | label = labelUpdater node.label }


setNodeText : String -> GraphNode -> GraphNode
setNodeText newText node =
    updateLabelInNode (\label -> { label | nodeText = newText }) node


insertNode : GraphNode -> ModelGraph -> ModelGraph
insertNode node =
    Graph.insert
        { node = node
        , incoming = IntDict.empty
        , outgoing = IntDict.empty
        }


insertEdge : NodeId -> NodeId -> ModelGraph -> ModelGraph
insertEdge from to graph =
    let
        insertOutgoingEdge : NodeId -> NodeContext NodeLabel () -> NodeContext NodeLabel ()
        insertOutgoingEdge toId oldContext =
            { oldContext
                | outgoing = IntDict.insert toId () oldContext.outgoing
            }
    in
        Graph.update from (Maybe.map (insertOutgoingEdge to)) graph


crashIfNodeNotInGraph : NodeId -> Maybe GraphNode -> GraphNode
crashIfNodeNotInGraph nodeId mGraphNode =
    case mGraphNode of
        Nothing ->
            Debug.crash <| "Node with id " ++ toString nodeId ++ " was not in the graph"

        Just node ->
            node


getNode : NodeId -> ModelGraph -> GraphNode
getNode nodeId graph =
    Graph.get nodeId graph |> Maybe.map (.node) |> crashIfNodeNotInGraph nodeId
