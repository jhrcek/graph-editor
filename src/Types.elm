module Types
    exposing
        ( Model
        , ModelGraph
        , GraphNode
        , GraphEdge
        , Msg(..)
        , DragMsg(..)
        , NodeLabel
        , NodeText(..)
        , EdgeLabel(..)
        , nodeTextToString
        , Drag
        , EditorMode(..)
        , isNodeEditMode
        , isEdgeEditMode
        , EdgeEditState(..)
        , getDraggedNodePosition
        , BBox
        )

import Mouse exposing (Position)
import Graph exposing (NodeId, Graph, Edge)


type alias Model =
    { graph : ModelGraph
    , newNodeId : Int
    , draggedNode : Maybe Drag
    , editorMode : EditorMode
    }


type alias ModelGraph =
    Graph NodeLabel EdgeLabel


type alias GraphNode =
    Graph.Node NodeLabel


type alias GraphEdge =
    Graph.Edge EdgeLabel


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
    | DeleteEdge NodeId NodeId
      -- Changing modes
    | SetMode EditorMode
    | SetBoundingBox BBox
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
    { nodeText : NodeText
    , x : Int
    , y : Int
    }


type NodeText
    = NodeText (Maybe BBox) String


type EdgeLabel
    = EdgeLabel (Maybe BBox) String


nodeTextToString : NodeText -> String
nodeTextToString (NodeText _ string) =
    string



-- | Sized BBox String


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


type alias BBox =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    , elementId : String
    }
