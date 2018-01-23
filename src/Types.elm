module Types
    exposing
        ( BBox
        , Drag
        , DragMsg(..)
        , EdgeLabel(..)
        , EditState(..)
        , EditorMode(..)
        , GraphEdge
        , GraphNode
        , Model
        , ModelGraph
        , Msg(..)
        , NodeLabel
        , NodeText(..)
        , edgeLabelToString
        , getDraggedNodePosition
        , isEditMode
        , nodeTextToString
        , setBBoxOfEdgeLabel
        , setBBoxOfNodeText
        , setEdgeText
        )

import Graph exposing (Graph, NodeId)
import Mouse exposing (Position)
import Window


type alias Model =
    { graph : ModelGraph
    , newNodeId : Int
    , draggedNode : Maybe Drag
    , editorMode : EditorMode
    , helpEnabled : Bool
    , aboutEnabled : Bool
    , windowSize : Window.Size
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
      -- Editing Node label
    | NodeLabelEditStart GraphNode
    | NodeLabelEdit String
    | NodeLabelEditConfirm
      -- Editing Edge label
    | EdgeLabelEditStart GraphEdge
    | EdgeLabelEdit String
    | EdgeLabelEditConfirm
      -- Creating Edges
    | StartNodeOfEdgeSelected NodeId
    | EndNodeOfEdgeSelected NodeId
    | UnselectStartNodeOfEdge
    | PreviewEdgeEndpointPositionChanged Mouse.Position
      -- Deleting Nodes and Edges
    | DeleteNode NodeId
    | DeleteEdge NodeId NodeId
      -- Switching between modes
    | SetMode EditorMode
    | SetBoundingBox BBox
    | ToggleHelp Bool
    | ToggleAbout Bool
    | WindowResized Window.Size
    | NoOp
    | ExportTGF


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


setBBoxOfNodeText : BBox -> NodeText -> NodeText
setBBoxOfNodeText bbox (NodeText _ text) =
    NodeText (Just bbox) text


nodeTextToString : NodeText -> String
nodeTextToString (NodeText _ string) =
    string


type EdgeLabel
    = EdgeLabel (Maybe BBox) String


setBBoxOfEdgeLabel : BBox -> EdgeLabel -> EdgeLabel
setBBoxOfEdgeLabel bbox (EdgeLabel _ text) =
    EdgeLabel (Just bbox) text


setEdgeText : String -> EdgeLabel -> EdgeLabel
setEdgeText newText (EdgeLabel mbbox _) =
    EdgeLabel mbbox newText


edgeLabelToString : EdgeLabel -> String
edgeLabelToString (EdgeLabel _ string) =
    string



-- | Sized BBox String


type EditorMode
    = MoveMode
    | EditMode EditState
    | DeletionMode


isEditMode : EditorMode -> Bool
isEditMode mode =
    case mode of
        EditMode _ ->
            True

        _ ->
            False


type EditState
    = EditingNothing
    | CreatingEdge NodeId Mouse.Position
    | EditingEdgeLabel GraphEdge
    | EditingNodeLabel GraphNode


getDraggedNodePosition : Drag -> NodeLabel -> NodeLabel
getDraggedNodePosition { start, current } nodeLabel =
    { nodeLabel
        | x = nodeLabel.x + current.x - start.x

        -- Make it impossible to drag node outside of the canvas.
        -- For some reason this is only an issue when dragging past the TOP of viewport
        , y = max 0 (nodeLabel.y + current.y - start.y)
    }


type alias BBox =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    , elementId : String
    }
