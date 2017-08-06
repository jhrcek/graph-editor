module GraphUtil
    exposing
        ( updateDraggedNode
        , setNodeText
        , updateNodeLabel
        , insertNode
        , insertEdge
        , removeEdge
        , getNode
        , getEdgeLabel
        )

import Graph exposing (Node, NodeContext, NodeId, Adjacency)
import IntDict
import Types exposing (EdgeLabel, EdgeLabel(..), GraphEdge, GraphNode, ModelGraph, NodeLabel, NodeText(..), Drag)


updateNodeInContext : (Node n -> Node n) -> NodeContext n e -> NodeContext n e
updateNodeInContext nodeUpdater ({ node } as ctx) =
    { ctx | node = nodeUpdater node }


updateOutgoingAdjacency : (Adjacency e -> Adjacency e) -> NodeContext n e -> NodeContext n e
updateOutgoingAdjacency adjacencyUpdater ({ outgoing } as ctx) =
    { ctx | outgoing = adjacencyUpdater outgoing }


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


updateNodeLabel : NodeId -> NodeText -> ModelGraph -> ModelGraph
updateNodeLabel nodeId newNodeText graph =
    Graph.update nodeId (Maybe.map (updateNodeInContext (setNodeText newNodeText))) graph


updateDraggedNode : Drag -> ModelGraph -> ModelGraph
updateDraggedNode drag graph =
    Graph.update drag.nodeId (updateDraggedNodeInContext drag) graph


updateDraggedNodeInContext : Drag -> Maybe (NodeContext NodeLabel e) -> Maybe (NodeContext NodeLabel e)
updateDraggedNodeInContext drag =
    Maybe.map (updateNodeInContext (updateLabelInNode (Types.getDraggedNodePosition drag)))


getEdgeLabel : NodeId -> NodeId -> ModelGraph -> EdgeLabel
getEdgeLabel from to graph =
    Graph.get from graph
        |> Maybe.map (.outgoing)
        |> Maybe.andThen (IntDict.get to)
        |> crashIfEdgeNotInGraph from to


insertEdge : GraphEdge -> ModelGraph -> ModelGraph
insertEdge edge graph =
    Graph.update edge.from (Maybe.map (updateOutgoingAdjacency (IntDict.insert edge.to edge.label))) graph


removeEdge : NodeId -> NodeId -> ModelGraph -> ModelGraph
removeEdge from to gr =
    let
        removeOutgoingEdge : NodeId -> NodeContext NodeLabel EdgeLabel -> NodeContext NodeLabel EdgeLabel
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


crashIfEdgeNotInGraph : NodeId -> NodeId -> Maybe EdgeLabel -> EdgeLabel
crashIfEdgeNotInGraph from to mEdgeLabel =
    case mEdgeLabel of
        Nothing ->
            Debug.crash <| "Edge between nodes " ++ toString from ++ " and " ++ toString to ++ " was not in the graph"

        Just edgeLabel ->
            edgeLabel
