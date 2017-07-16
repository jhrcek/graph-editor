module SvgMouse exposing (onCanvasMouseDown, onMouseDown)

import Html exposing (Attribute)
import Html.Events exposing (on, onWithOptions, Options)
import Json.Decode as Json exposing (field, int)
import Mouse exposing (Position)
import Types exposing (Msg)


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


onMouseDown : (Position -> Msg) -> Attribute Msg
onMouseDown tagger =
    onWithOptions "mousedown" stopPropagationOptions (Json.map tagger Mouse.position)


{-| options to prevent clicks on canvas nodes triggering click events on canvas itself
-}
stopPropagationOptions : Options
stopPropagationOptions =
    { stopPropagation = True
    , preventDefault = True
    }
