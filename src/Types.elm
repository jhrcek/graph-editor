module Types exposing (Msg(..))

import Mouse exposing (Position)


type Msg
    = CanvasClicked Position
    | NoOp
