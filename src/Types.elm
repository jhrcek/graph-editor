module Types
    exposing
        ( Model
        , ModelGraph
        , GraphNode
        , Msg(..)
        , DragMsg(..)
        , NodeLabel
        , Drag
        , EditorMode(..)
        , isNodeEditMode
        , isEdgeEditMode
        , EdgeEditState(..)
        , getDraggedNodePosition
        )

import Mouse exposing (Position)
import Graph exposing (NodeId, Graph)


type alias Model =
    { graph : ModelGraph
    , newNodeId : Int
    , draggedNode : Maybe Drag
    , editorMode : EditorMode
    }


type alias ModelGraph =
    Graph NodeLabel ()


type alias GraphNode =
    Graph.Node NodeLabel


type Msg
    = CreateNode Position
    | NodeDrag DragMsg
      -- Node creation
    | NodeEditStart NodeId
    | NodeEditConfirm NodeId String
    | NodeLabelEdit NodeId String
      -- Edge creation
    | StartNodeOfEdgeSelected NodeId
    | EndNodeOfEdgeSelected NodeId
    | UnselectStartNodeOfEdge
    | PreviewEdgeEndpointPositionChanged Mouse.Position
      --
    | DeleteNode NodeId
      -- Changing modes
    | SetMode EditorMode
    | NoOp


type DragMsg
    = DragStart NodeId Position
    | DragAt Position
    | DragEnd Position


type alias Drag =
    { nodeId : NodeId
    , start : Position
    , current : Position
    }


type alias NodeLabel =
    { nodeText : String
    , x : Int
    , y : Int
    }


type EditorMode
    = BrowsingMode
    | NodeEditMode (Maybe GraphNode)
    | EdgeEditMode EdgeEditState
    | DeletionMode


isNodeEditMode : EditorMode -> Bool
isNodeEditMode mode =
    case mode of
        NodeEditMode _ ->
            True

        _ ->
            False


isEdgeEditMode : EditorMode -> Bool
isEdgeEditMode mode =
    case mode of
        EdgeEditMode _ ->
            True

        _ ->
            False


type EdgeEditState
    = NothingSelected
    | FromSelected NodeId Mouse.Position


getDraggedNodePosition : Drag -> NodeLabel -> NodeLabel
getDraggedNodePosition { nodeId, start, current } nodeLabel =
    { nodeLabel
        | x = nodeLabel.x + current.x - start.x
        , y = nodeLabel.y + current.y - start.y
    }
