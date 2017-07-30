module Canvas exposing (boxedText, edgeArrow, drawEdge, svgDefs)

import Graph exposing (NodeId)
import Svg exposing (Svg, feComponentTransfer, feComposite, feFlood, g, rect, text, text_)
import Svg.Attributes exposing (alignmentBaseline, d, fill, filter, floodColor, floodOpacity, fontFamily, fontSize, height, id, in2, in_, markerEnd, markerHeight, markerUnits, markerWidth, name, orient, refX, refY, rx, ry, stroke, strokeWidth, style, textAnchor, transform, width, x, x1, x2, y, y1, y2)
import SvgMouse
import Types exposing (..)


boxedText : GraphNode -> EditorMode -> Svg Msg
boxedText { id, label } editorMode =
    let
        tranformValue =
            "translate(" ++ toString (label.x - boxCenterX) ++ "," ++ toString (label.y - boxCenterY) ++ ")"

        boxWidth =
            getBoxWidth label.nodeText

        boxCenterX =
            boxWidth // 2

        boxCenterY =
            boxHeight // 2

        nodeFill =
            case editorMode of
                EdgeEditMode (FromSelected selectedNodeId _) ->
                    if id == selectedNodeId then
                        fill "lightgray"
                    else
                        fill "white"

                _ ->
                    fill "white"

        modeDependentAttributes =
            case editorMode of
                BrowsingMode ->
                    [ onClickStartDrag id, style "cursor: move;" ]

                NodeEditMode _ ->
                    [ onClickStartDrag id
                    , onDoubleClickStartEdit id
                    ]

                EdgeEditMode edgeEditState ->
                    case edgeEditState of
                        NothingSelected ->
                            [ onMouseDownSelectStartingNode id ]

                        FromSelected selectedNodeId _ ->
                            if id /= selectedNodeId then
                                [ onMouseUpCreateEdge id ]
                            else
                                [ SvgMouse.onMouseUpUnselectStartNode ]

                DeletionMode ->
                    [ onClickDeleteNode id, style "cursor: not-allowed;" ]
    in
        g
            [ transform tranformValue ]
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
            , positionedText boxCenterX boxCenterY label.nodeText modeDependentAttributes
            ]


positionedText : Int -> Int -> String -> List (Svg.Attribute Msg) -> Svg Msg
positionedText xCoord yCoord txt additionalAttributes =
    text_
        ([ Svg.Attributes.x (toString <| xCoord)
         , Svg.Attributes.y (toString <| yCoord)
         , fill "black"
         , textAnchor "middle"
         , alignmentBaseline "central"
         , fontSize "16px"
         , fontFamily "sans-serif"

         --prevent text to be selectable by click+dragging
         , style "user-select: none; -moz-user-select: none;"
         ]
            ++ additionalAttributes
        )
        [ text txt ]


getBoxWidth : String -> Int
getBoxWidth nodeText =
    (characterWidthPixels * String.length nodeText) + 20


edgeArrow : Graph.Edge () -> GraphNode -> GraphNode -> EditorMode -> Svg Msg
edgeArrow edge fromNode toNode editorMode =
    let
        { x, y, nodeText } =
            toNode.label

        edgeIncomingAngle =
            atan2 (toFloat (y - fromNode.label.y)) (toFloat (fromNode.label.x - x))

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

        modeDependentAttributes =
            case editorMode of
                DeletionMode ->
                    [ onClickDeleteEdge fromNode.id toNode.id, style "cursor: not-allowed;" ]

                _ ->
                    []
    in
        drawEdge fromNode.label arrowHeadX arrowHeadY modeDependentAttributes


drawEdge : NodeLabel -> Int -> Int -> List (Svg.Attribute Msg) -> Svg Msg
drawEdge fromLabel xTo yTo attrList =
    let
        coordAttrs =
            [ x1 (toString fromLabel.x)
            , y1 (toString fromLabel.y)
            , x2 (toString xTo)
            , y2 (toString yTo)
            ]
    in
        g attrList
            [ Svg.line (coordAttrs ++ [ stroke "transparent", strokeWidth "6" ]) []
            , Svg.line (coordAttrs ++ [ stroke "black", strokeWidth "1", markerEnd "url(#arrow)" ]) []
            , positionedText ((fromLabel.x + xTo) // 2) ((fromLabel.y + yTo) // 2) "test text1" [ filter "url(#myBgColor)", SvgMouse.onClickStopPropagation NoOp ]
            ]


svgDefs : Svg a
svgDefs =
    Svg.defs []
        [ arrowHeadMarkerDef
        , textBackgroundColorDef
        ]


{-| Arrowhead to be reused by all edges, inspired by <http://vanseodesign.com/web-design/svg-markers/>
-}
arrowHeadMarkerDef : Svg a
arrowHeadMarkerDef =
    Svg.marker [ id "arrow", markerWidth "15", markerHeight "6", refX "15", refY "3", orient "auto", markerUnits "strokeWidth" ]
        [ Svg.path [ d "M0,0 L0,6 L15,3 z", fill "black" ] []
        ]


{-| Filter definition to set background color of edge text labels, inspired by <https://stackoverflow.com/questions/15500894/background-color-of-text-in-svg#answer-31013492>
-}
textBackgroundColorDef : Svg a
textBackgroundColorDef =
    Svg.filter [ id "myBgColor", x "0", y "0", width "1", height "1" ]
        [ feFlood [ floodColor "white", floodOpacity "0.7" ] []
        , feComposite [ in_ "SourceGraphic", in2 "BackgroundImage" ] []
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


onClickDeleteEdge : NodeId -> NodeId -> Svg.Attribute Msg
onClickDeleteEdge from to =
    SvgMouse.onClickStopPropagation (DeleteEdge from to)


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
