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
    = CanvasClicked Position
    | NodeDrag DragMsg
    | NodeEditStart NodeId String
    | NodeEditConfirm NodeId String
    | NodeEditCancel
    | NodeLabelEdit NodeId String
    | DeleteNode NodeId
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
    | NodeEditMode (Maybe ( NodeId, String ))
    | EdgeEditMode
