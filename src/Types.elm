module Types exposing (Msg(..), DragMsg(..), NodeLabel, Drag)

import Mouse exposing (Position)
import Graph exposing (NodeId)


type Msg
    = CanvasClicked Position
    | NodeDrag DragMsg
    | NoOp


type DragMsg
    = DragStart NodeId Position
    | DragAt Position
    | DragEnd Position


type alias NodeLabel =
    { nodeText : String
    , x : Int
    , y : Int
    }


type alias Drag =
    { nodeId : NodeId
    , start : Position
    , current : Position
    }
