module SvgMouse exposing (onClick, onClickPreventBubble)

import Html
import Html.Events exposing (on, onWithOptions, Options)
import Json.Decode as Json exposing (field, int)
import Mouse exposing (Position)


{- The aim of this module is to work around the fact, that click events fired
   from SVG elements don't have target.offsetLeft/offsetTop unlike Html DOM elements.

   The workaround is based on https://github.com/fredcy/elm-svg-mouse-offset
-}


onClick : (Position -> a) -> Html.Attribute a
onClick tagger =
    onWithOptions "click" options (Json.map tagger offsetPosition)


options : Options
options =
    { stopPropagation = True
    , preventDefault = True
    }


offsetPosition : Json.Decoder Position
offsetPosition =
    Json.map2 Position
        (field "offsetX" int)
        (field "offsetY" int)



{- Workaround to prevent clicks on canvas nodes triggering click events on canvas itself -}


onClickPreventBubble : a -> Html.Attribute a
onClickPreventBubble noopMsg =
    onWithOptions "click" options (Json.succeed noopMsg)
