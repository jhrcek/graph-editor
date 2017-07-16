module GraphUtil exposing (updateNodeInContext, updateLabelInNode)

import Graph exposing (Node, NodeContext)


updateNodeInContext : (Node n -> Node n) -> NodeContext n e -> NodeContext n e
updateNodeInContext nodeUpdater ({ node } as ctx) =
    { ctx | node = nodeUpdater node }


updateLabelInNode : (lab -> lab) -> Node lab -> Node lab
updateLabelInNode labelUpdater node =
    { node | label = labelUpdater node.label }
