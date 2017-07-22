module GraphUtil
    exposing
        ( updateNodeInContext
        , updateLabelInNode
        , setNodeText
        , insertNode
        )

import Graph exposing (Node, NodeContext)
import Types exposing (GraphNode, ModelGraph)
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
