module GraphUtil
    exposing
        ( updateNodeInContext
        , updateLabelInNode
        , setNodeText
        , insertNode
        , insertEdge
        , removeEdge
        , getNode
        )

import Graph exposing (Node, NodeContext, NodeId)
import IntDict
import Types exposing (GraphNode, ModelGraph, NodeLabel, NodeText(..))


updateNodeInContext : (Node n -> Node n) -> NodeContext n e -> NodeContext n e
updateNodeInContext nodeUpdater ({ node } as ctx) =
    { ctx | node = nodeUpdater node }


updateLabelInNode : (lab -> lab) -> Node lab -> Node lab
updateLabelInNode labelUpdater node =
    { node | label = labelUpdater node.label }


setNodeText : NodeText -> GraphNode -> GraphNode
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


removeEdge : NodeId -> NodeId -> ModelGraph -> ModelGraph
removeEdge from to gr =
    let
        removeOutgoingEdge : NodeId -> NodeContext NodeLabel () -> NodeContext NodeLabel ()
        removeOutgoingEdge toId oldContext =
            { oldContext
                | outgoing = IntDict.remove toId oldContext.outgoing
            }
    in
        Graph.update from (Maybe.map (removeOutgoingEdge to)) gr


getNode : NodeId -> ModelGraph -> GraphNode
getNode nodeId graph =
    Graph.get nodeId graph |> Maybe.map (.node) |> crashIfNodeNotInGraph nodeId


crashIfNodeNotInGraph : NodeId -> Maybe GraphNode -> GraphNode
crashIfNodeNotInGraph nodeId mGraphNode =
    case mGraphNode of
        Nothing ->
            Debug.crash <| "Node with id " ++ toString nodeId ++ " was not in the graph"

        Just node ->
            node
