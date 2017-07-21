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
    = CanvasClicked Position
    | NodeDrag DragMsg
    | NodeEditStart NodeId String
    | NodeEditConfirm NodeId String
    | NodeLabelEdit NodeId String
    | DeleteNode NodeId
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
    | NodeEditMode (Maybe ( NodeId, String ))
    | EdgeEditMode


getDraggedNodePosition : Drag -> NodeLabel -> NodeLabel
getDraggedNodePosition { nodeId, start, current } nodeLabel =
    { nodeLabel
        | x = nodeLabel.x + current.x - start.x
        , y = nodeLabel.y + current.y - start.y
    }
