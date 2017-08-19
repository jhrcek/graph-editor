module SvgMouse
    exposing
        ( onCanvasMouseDown
        , onClickStopPropagation
        , onDoubleClickStopPropagation
        , onMouseDownGetPosition
        , onMouseDownStopPropagation
        , onMouseUp
        , onMouseUpUnselectStartNode
        )

import Html exposing (Attribute)
import Html.Events exposing (Options, defaultOptions, on, onWithOptions)
import Json.Decode as Json exposing (field, int)
import Mouse exposing (Position)
import Svg.Events
import Types exposing (Msg(..))


{- The aim of this module is to work around the fact, that click events fired
   from SVG elements don't have target.offsetLeft/offsetTop unlike Html DOM elements.
   This means that packages like Elm-Canvas/element-relative-mouse-events don't work
   with SVG elements.

   The workaround is based on https://github.com/fredcy/elm-svg-mouse-offset
-}


onCanvasMouseDown : (Position -> a) -> Html.Attribute a
onCanvasMouseDown tagger =
    on "mousedown" (Json.map tagger offsetPosition)


offsetPosition : Json.Decoder Position
offsetPosition =
    Json.map2 Position
        (field "offsetX" int)
        (field "offsetY" int)


onClickStopPropagation : Msg -> Attribute Msg
onClickStopPropagation msg =
    onWithOptions "click" stopPropagationOptions (Json.succeed msg)


onMouseDownGetPosition : (Position -> Msg) -> Attribute Msg
onMouseDownGetPosition tagger =
    onWithOptions "mousedown" stopPropagationOptions (Json.map tagger Mouse.position)


onMouseDownStopPropagation : Msg -> Attribute Msg
onMouseDownStopPropagation msg =
    onWithOptions "mousedown" stopPropagationOptions (Json.succeed msg)


onDoubleClickStopPropagation : Msg -> Attribute Msg
onDoubleClickStopPropagation msg =
    onWithOptions "dblclick" stopPropagationOptions (Json.succeed msg)


onMouseUp : Msg -> Attribute Msg
onMouseUp msg =
    Svg.Events.onMouseUp msg


onMouseUpUnselectStartNode : Attribute Msg
onMouseUpUnselectStartNode =
    onWithOptions "mouseup" stopPropagationOptions (Json.succeed UnselectStartNodeOfEdge)


{-| options to prevent clicks on canvas nodes triggering click events on canvas itself
-}
stopPropagationOptions : Options
stopPropagationOptions =
    { defaultOptions | stopPropagation = True }
