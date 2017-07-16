module View exposing (boxedText)

import Svg exposing (Svg, rect, text, text_, g)
import Svg.Attributes exposing (transform, width, height, x, y, rx, ry, stroke, strokeWidth, fill, textAnchor, alignmentBaseline, fontSize, fontFamily, name)
import SvgMouse
import Types exposing (..)
import Graph exposing (NodeId)


boxedText : NodeId -> NodeLabel -> Svg Msg
boxedText nodeId { x, y, nodeText } =
    let
        tranformValue =
            "translate(" ++ toString (x - boxCenterX) ++ "," ++ toString (y - boxCenterY) ++ ")"

        textContentWidth =
            characterWidthPixels * String.length nodeText

        boxWidth =
            textContentWidth + 15

        boxCenterX =
            boxWidth // 2

        boxCenterY =
            boxHeight // 2

        dragStartEvent =
            SvgMouse.onMouseDown (NodeDrag << DragStart nodeId)
    in
        g
            [ transform tranformValue
            , name (toString nodeId)
            ]
            [ rect
                [ width (toString boxWidth)
                , height (toString boxHeight)
                , rx "2"
                , ry "2"
                , fill "white"
                , stroke "black"
                , strokeWidth "1"
                , dragStartEvent
                ]
                []
            , text_
                [ Svg.Attributes.x (toString <| boxCenterX)
                , Svg.Attributes.y (toString <| boxCenterY)
                , fill "black"
                , textAnchor "middle"
                , alignmentBaseline "central"
                , fontSize "10px"
                , fontFamily "Inconsolata, sans-serif"
                , dragStartEvent
                ]
                [ text nodeText ]
            ]



-- TODO I'm using monospace font, but I don't like this assumption
-- Is there an "elmy" way to query the width of rendered text?


characterWidthPixels : Int
characterWidthPixels =
    6


boxHeight : Int
boxHeight =
    25
