module Canvas exposing (boxedText, edgeArrow, drawEdge, arrowHeadMarkerDefs)

import Graph exposing (NodeId)
import Svg exposing (Svg, g, rect, text, text_)
import Svg.Attributes exposing (alignmentBaseline, d, fill, fontFamily, fontSize, height, id, markerEnd, markerHeight, markerUnits, markerWidth, name, orient, refX, refY, rx, ry, stroke, strokeWidth, style, textAnchor, transform, width, x, x1, x2, y, y1, y2)
import SvgMouse
import Types exposing (..)


boxedText : NodeId -> NodeLabel -> EditorMode -> Svg Msg
boxedText nodeId { x, y, nodeText } editorMode =
    let
        tranformValue =
            "translate(" ++ toString (x - boxCenterX) ++ "," ++ toString (y - boxCenterY) ++ ")"

        boxWidth =
            getBoxWidth nodeText

        boxCenterX =
            boxWidth // 2

        boxCenterY =
            boxHeight // 2

        nodeFill =
            case editorMode of
                EdgeEditMode (FromSelected selectedNodeId _) ->
                    if nodeId == selectedNodeId then
                        fill "lightgray"
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

                        FromSelected selectedNodeId _ ->
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


getBoxWidth : String -> Int
getBoxWidth nodeText =
    (characterWidthPixels * String.length nodeText) + 20


edgeArrow : Int -> Int -> NodeLabel -> Svg Msg
edgeArrow xFrom yFrom ({ x, y, nodeText } as targetNodeLabel) =
    let
        edgeIncomingAngle =
            atan2 (toFloat (y - yFrom)) (toFloat (xFrom - x))

        boxWidth =
            getBoxWidth nodeText

        criticalAngle =
            determineAngle boxWidth boxHeight

        whichSideOfTargetBoxToPointTo =
            determineSide criticalAngle edgeIncomingAngle

        ( arrowHeadX, arrowHeadY ) =
            let
                yCorrection =
                    round (toFloat (boxWidth // 2) * tan edgeIncomingAngle)

                xCorrection =
                    round (toFloat (boxHeight // 2) / tan edgeIncomingAngle)
            in
                case whichSideOfTargetBoxToPointTo of
                    BRight ->
                        ( x + boxWidth // 2, y - yCorrection )

                    BLeft ->
                        ( x - boxWidth // 2, y + yCorrection )

                    BTop ->
                        ( x + xCorrection, y - boxHeight // 2 )

                    BBottom ->
                        ( x - xCorrection, y + boxHeight // 2 )
    in
        drawEdge xFrom yFrom arrowHeadX arrowHeadY


drawEdge : Int -> Int -> Int -> Int -> Svg Msg
drawEdge xFrom yFrom xTo yTo =
    Svg.line
        [ x1 (toString xFrom)
        , y1 (toString yFrom)
        , x2 (toString xTo)
        , y2 (toString yTo)
        , stroke "black"
        , strokeWidth "1"
        , markerEnd "url(#arrow)"
        ]
        []


{-| Arrowhead to be reused by all edges, inspired by <http://vanseodesign.com/web-design/svg-markers/>
-}
arrowHeadMarkerDefs : Svg a
arrowHeadMarkerDefs =
    Svg.defs []
        [ Svg.marker [ id "arrow", markerWidth "15", markerHeight "6", refX "15", refY "3", orient "auto", markerUnits "strokeWidth" ]
            [ Svg.path [ d "M0,0 L0,6 L15,3 z", fill "black" ] []
            ]
        ]


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


{-| Determine which side of the box we should draw arrowhead of incomming edge
We first find "critical angle" (angle between x axis and line from box center to its upper right corner.
Based on that we determine which side of the box the arrowhead should point.
-}
type BoxSide
    = BRight
    | BTop
    | BLeft
    | BBottom


determineAngle : Int -> Int -> Float
determineAngle boxWidth boxHeight =
    atan2 (toFloat boxHeight) (toFloat boxWidth)


determineSide : Float -> Float -> BoxSide
determineSide boxCriticalAngle edgeIncomingAngle =
    if -boxCriticalAngle < edgeIncomingAngle && edgeIncomingAngle <= boxCriticalAngle then
        BRight
    else if boxCriticalAngle < edgeIncomingAngle && edgeIncomingAngle <= (Basics.pi - boxCriticalAngle) then
        BTop
    else if (-Basics.pi + boxCriticalAngle) < edgeIncomingAngle && edgeIncomingAngle <= -boxCriticalAngle then
        BBottom
    else
        BLeft
