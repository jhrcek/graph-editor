module GraphUtil exposing
    ( getNode
    , insertEdge
    , insertNode
    , removeEdge
    , setEdgeBoundingBox
    , setNodeBoundingBox
    , setNodeText
    , updateDraggedNode
    , updateNodeLabel
    , updateNodePositions
    )

import Graph exposing (Adjacency, Node, NodeContext, NodeId)
import IntDict exposing (IntDict)
import Types exposing (BBox, Drag, EdgeLabel(..), GraphEdge, GraphNode, ModelGraph, NodeLabel, NodeText(..), setBBoxOfEdgeLabel, setBBoxOfNodeText)


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


updateNodeTextInLabel : (NodeText -> NodeText) -> NodeLabel -> NodeLabel
updateNodeTextInLabel f nodeLabel =
    { nodeLabel | nodeText = f nodeLabel.nodeText }


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
    Graph.get nodeId graph |> Maybe.map .node |> crashIfNodeNotInGraph nodeId


crashIfNodeNotInGraph : NodeId -> Maybe GraphNode -> GraphNode
crashIfNodeNotInGraph nodeId mGraphNode =
    case mGraphNode of
        Nothing ->
            crashWorkAround nodeId

        Just node ->
            node


{-| TODO avoid having to use this
-}
crashWorkAround : NodeId -> GraphNode
crashWorkAround nodeId =
    { id = -1
    , label =
        { nodeText = NodeText Nothing ("Node with id " ++ String.fromInt nodeId ++ " was not in the graph")
        , x = 0
        , y = 0
        }
    }


setNodeBoundingBox : NodeId -> BBox -> ModelGraph -> ModelGraph
setNodeBoundingBox nodeId bbox =
    Graph.update nodeId
        (Maybe.map <| updateNodeInContext <| updateLabelInNode <| updateNodeTextInLabel <| setBBoxOfNodeText bbox)


setEdgeBoundingBox : NodeId -> NodeId -> BBox -> ModelGraph -> ModelGraph
setEdgeBoundingBox fromId toId bbox =
    Graph.update fromId
        (Maybe.map <| updateOutgoingAdjacency <| IntDict.update toId <| Maybe.map <| setBBoxOfEdgeLabel bbox)


updateNodePositions : IntDict { x : Float, y : Float } -> ModelGraph -> ModelGraph
updateNodePositions positionDict graph =
    Graph.mapContexts (setNewPositionForNode positionDict) graph


setNewPositionForNode :
    IntDict { x : Float, y : Float }
    -> Graph.NodeContext NodeLabel EdgeLabel
    -> Graph.NodeContext NodeLabel EdgeLabel
setNewPositionForNode positionDict nodeContext =
    case IntDict.get nodeContext.node.id positionDict of
        Just newPos ->
            updateNodeInContext
                (updateLabelInNode (\nodeLabel -> { nodeLabel | x = round newPos.x, y = round newPos.y }))
                nodeContext

        Nothing ->
            nodeContext
