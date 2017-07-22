module Canvas exposing (boxedText)

import Graph exposing (NodeId)
import Svg exposing (Svg, g, rect, text, text_)
import Svg.Attributes exposing (alignmentBaseline, fill, fontFamily, fontSize, height, name, rx, ry, stroke, strokeWidth, style, textAnchor, transform, width, x, y)
import SvgMouse
import Types exposing (..)


boxedText : NodeId -> NodeLabel -> EditorMode -> Svg Msg
boxedText nodeId { x, y, nodeText } editorMode =
    let
        tranformValue =
            "translate(" ++ toString (x - boxCenterX) ++ "," ++ toString (y - boxCenterY) ++ ")"

        textContentWidth =
            characterWidthPixels * String.length nodeText

        boxWidth =
            textContentWidth + 20

        boxCenterX =
            boxWidth // 2

        boxCenterY =
            boxHeight // 2

        modeDependentAttributes =
            case editorMode of
                BrowsingMode ->
                    [ onClickStartDrag nodeId ]

                NodeEditMode _ ->
                    [ onClickStartDrag nodeId
                    , onDoubleClickStartEdit nodeId
                    ]

                EdgeEditMode ->
                    [ onClickStartDrag nodeId ]

                DeletionMode ->
                    [ onClickDeleteNode nodeId, style "cursor: not-allowed;" ]
    in
        g
            [ transform tranformValue
            , name (toString nodeId)
            ]
            [ rect
                ([ width (toString boxWidth)
                 , height (toString boxHeight)
                 , rx "4"
                 , ry "4"
                 , fill "white"
                 , stroke "black"
                 , strokeWidth "1"
                 ]
                    ++ modeDependentAttributes
                )
                []
            , text_
                ([ Svg.Attributes.x (toString <| boxCenterX)
                 , Svg.Attributes.y (toString <| boxCenterY)
                 , fill "black"
                 , textAnchor "middle"
                 , alignmentBaseline "central"
                 , fontSize "16px"
                 , fontFamily "Inconsolata, sans-serif"
                 ]
                    ++ modeDependentAttributes
                )
                [ text nodeText ]
            ]


onDoubleClickStartEdit : NodeId -> Svg.Attribute Msg
onDoubleClickStartEdit nodeId =
    SvgMouse.onDoubleClickStopPropagation (NodeEditStart nodeId)


onClickStartDrag : NodeId -> Svg.Attribute Msg
onClickStartDrag nodeId =
    SvgMouse.onMouseDownStopPropagation (NodeDrag << DragStart nodeId)


onClickDeleteNode : NodeId -> Svg.Attribute Msg
onClickDeleteNode nodeId =
    SvgMouse.onClickStopPropagation (DeleteNode nodeId)



-- TODO I'm using monospace font, but I don't like this assumption
-- Is there an "elmy" way to query the width of rendered text?


characterWidthPixels : Int
characterWidthPixels =
    7


characterHeightPixels : Int
characterHeightPixels =
    14


boxHeight : Int
boxHeight =
    characterHeightPixels * 2
