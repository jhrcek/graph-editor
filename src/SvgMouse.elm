module SvgMouse exposing
    ( onCanvasMouseDown
    , onClickStopPropagation
    , onDoubleClickStopPropagation
    , onMouseDownGetPosition
    , onMouseDownStopPropagation
    , onMouseUpUnselectStartNode
    )

import Html exposing (Attribute)
import Html.Events exposing (on, stopPropagationOn)
import Json.Decode as Json exposing (field, int)
import Types exposing (MousePosition, Msg(..), mousePositionDecoder)



{- The aim of this module is to work around the fact, that click events fired
   from SVG elements don't have target.offsetLeft/offsetTop unlike Html DOM elements.
   This means that packages like Elm-Canvas/element-relative-mouse-events don't work
   with SVG elements.

   The workaround is based on https://github.com/fredcy/elm-svg-mouse-offset

   The use of stopPropagationOn  is to prevent clicks on canvas nodes triggering click events on canvas itself

-}


onCanvasMouseDown : (MousePosition -> msg) -> Html.Attribute msg
onCanvasMouseDown tagger =
    on "mousedown" <| Json.map tagger offsetPosition


offsetPosition : Json.Decoder MousePosition
offsetPosition =
    Json.map2 MousePosition
        (field "offsetX" int)
        (field "offsetY" int)


onClickStopPropagation : Msg -> Attribute Msg
onClickStopPropagation msg =
    stopPropagationOn "click" <| Json.succeed ( msg, True )


onMouseDownGetPosition : (MousePosition -> Msg) -> Attribute Msg
onMouseDownGetPosition tagger =
    stopPropagationOn "mousedown" <| Json.map (\pos -> ( tagger pos, True )) mousePositionDecoder


onMouseDownStopPropagation : Msg -> Attribute Msg
onMouseDownStopPropagation msg =
    stopPropagationOn "mousedown" <| Json.succeed ( msg, True )


onDoubleClickStopPropagation : Msg -> Attribute Msg
onDoubleClickStopPropagation msg =
    stopPropagationOn "dblclick" <| Json.succeed ( msg, True )


onMouseUpUnselectStartNode : Attribute Msg
onMouseUpUnselectStartNode =
    stopPropagationOn "mouseup" <| Json.succeed ( UnselectStartNodeOfEdge, True )
