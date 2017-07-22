module Canvas exposing (boxedText, edgeLine)

import Graph exposing (NodeId)
import Svg exposing (Svg, g, rect, text, text_)
import Svg.Attributes exposing (alignmentBaseline, fill, fontFamily, fontSize, height, name, rx, ry, stroke, strokeWidth, style, textAnchor, transform, width, x, x1, x2, y, y1, y2)
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

        nodeFill =
            case editorMode of
                EdgeEditMode (FromSelected selectedNodeId) ->
                    if nodeId == selectedNodeId then
                        fill "grey"
                    else
                        fill "white"

                _ ->
                    fill "white"

        modeDependentAttributes =
            case editorMode of
                BrowsingMode ->
                    [ onClickStartDrag nodeId ]

                NodeEditMode _ ->
                    [ onClickStartDrag nodeId
                    , onDoubleClickStartEdit nodeId
                    ]

                EdgeEditMode edgeEditState ->
                    case edgeEditState of
                        NothingSelected ->
                            [ onMouseDownSelectStartingNode nodeId ]

                        FromSelected selectedNodeId ->
                            if nodeId /= selectedNodeId then
                                [ onMouseUpCreateEdge nodeId ]
                            else
                                [ SvgMouse.onMouseUpUnselectStartNode ]

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
                 , stroke "black"
                 , strokeWidth "1"
                 , nodeFill
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
                 , fontFamily "sans-serif"

                 --prevent text to be selectable by click+dragging
                 , style "user-select: none; -moz-user-select: none;"
                 ]
                    ++ modeDependentAttributes
                )
                [ text nodeText ]
            ]


edgeLine : Int -> Int -> Int -> Int -> Svg Msg
edgeLine xFrom yFrom xTo yTo =
    Svg.line
        [ x1 (toString xFrom)
        , y1 (toString yFrom)
        , x2 (toString xTo)
        , y2 (toString yTo)
        , stroke "black"
        , strokeWidth "1"
        ]
        []


onDoubleClickStartEdit : NodeId -> Svg.Attribute Msg
onDoubleClickStartEdit nodeId =
    SvgMouse.onDoubleClickStopPropagation (NodeEditStart nodeId)


onClickStartDrag : NodeId -> Svg.Attribute Msg
onClickStartDrag nodeId =
    SvgMouse.onMouseDownGetPosition (NodeDrag << DragStart nodeId)


onClickDeleteNode : NodeId -> Svg.Attribute Msg
onClickDeleteNode nodeId =
    SvgMouse.onClickStopPropagation (DeleteNode nodeId)


onMouseDownSelectStartingNode : NodeId -> Svg.Attribute Msg
onMouseDownSelectStartingNode nodeId =
    SvgMouse.onMouseDownStopPropagation (StartNodeOfEdgeSelected nodeId)


onMouseUpCreateEdge : NodeId -> Svg.Attribute Msg
onMouseUpCreateEdge nodeId =
    SvgMouse.onMouseUp (EndNodeOfEdgeSelected nodeId)



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
