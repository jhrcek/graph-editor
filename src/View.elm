module View exposing (boxedText)

import Svg exposing (Svg, rect, text, text_, g)
import Svg.Attributes exposing (transform, width, height, x, y, rx, ry, stroke, strokeWidth, fill, textAnchor, alignmentBaseline, fontSize, fontFamily, name)
import SvgMouse
import Types exposing (..)
import Graph exposing (NodeId)


-- TODO I'm using monospace font, but I don't like this assumption
-- Is there an "elmy" way to query the width of rendered text?


characterWidthPixels : Int
characterWidthPixels =
    6


boxHeight : Int
boxHeight =
    25


boxedText : NodeId -> Int -> Int -> String -> Svg Msg
boxedText nodeId xCoord yCoord textContent =
    let
        tranformValue =
            "translate(" ++ toString (xCoord - boxCenterX) ++ "," ++ toString (yCoord - boxCenterY) ++ ")"

        textContentWidth =
            characterWidthPixels * String.length textContent

        boxWidth =
            textContentWidth + 15

        boxCenterX =
            boxWidth // 2

        boxCenterY =
            boxHeight // 2
    in
        g
            [ transform tranformValue
            , SvgMouse.onClickPreventBubble NoOp
            , name (toString nodeId)
            ]
            [ rect
                [ width (toString boxWidth)
                , height (toString boxHeight)
                , rx "2"
                , ry "2"
                , fill "none"
                , stroke "black"
                , strokeWidth "1"
                ]
                []
            , text_
                [ x (toString <| boxCenterX)
                , y (toString <| boxCenterY)
                , fill "black"
                , textAnchor "middle"
                , alignmentBaseline "central"
                , fontSize "10px"
                , fontFamily "Inconsolata, sans-serif"
                ]
                [ text textContent ]
            ]
