module Canvas exposing (boxedText, edgeArrow, drawEdge, svgDefs)

import Graph exposing (NodeId)
import Svg exposing (Svg, g, rect, text, text_)
import Svg.Attributes exposing (alignmentBaseline, d, fill, fontFamily, fontSize, height, id, markerEnd, markerHeight, markerUnits, markerWidth, orient, refX, refY, rx, ry, stroke, strokeWidth, style, textAnchor, transform, width, x, x1, x2, y, y1, y2)
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

        nodeTextId =
            toString id
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
            , positionedText boxCenterX boxCenterY nodeTextId (nodeTextToString label.nodeText) modeDependentAttributes
            ]


positionedText : Int -> Int -> String -> String -> List (Svg.Attribute Msg) -> Svg Msg
positionedText xCoord yCoord elementId textContent additionalAttributes =
    text_
        ([ Svg.Attributes.x (toString <| xCoord)
         , Svg.Attributes.y (toString <| yCoord)
         , fill "black"
         , textAnchor "middle"
         , alignmentBaseline "central"
         , fontSize "16px"
         , fontFamily "sans-serif, monospace"
         , id elementId

         --prevent text to be selectable by click+dragging
         , style "user-select: none; -moz-user-select: none;"
         ]
            ++ additionalAttributes
        )
        [ text textContent ]


getBoxWidth : NodeText -> Int
getBoxWidth nodeText =
    case nodeText of
        UnknownSize str ->
            (characterWidthPixels * String.length str) + characterWidthPixels

        Sized bbox str ->
            round bbox.width + characterWidthPixels


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

        edgeTextId =
            toString fromNode.id ++ ":" ++ toString toNode.id
    in
        drawEdge fromNode.label arrowHeadX arrowHeadY edgeTextId modeDependentAttributes


drawEdge : NodeLabel -> Int -> Int -> String -> List (Svg.Attribute Msg) -> Svg Msg
drawEdge fromLabel xTo yTo edgeTextId attrList =
    let
        coordAttrs =
            [ x1 (toString fromLabel.x)
            , y1 (toString fromLabel.y)
            , x2 (toString xTo)
            , y2 (toString yTo)
            ]

        edgeCenterX =
            (fromLabel.x + xTo) // 2

        edgeCenterY =
            (fromLabel.y + yTo) // 2
    in
        g attrList
            [ Svg.line (coordAttrs ++ [ stroke "transparent", strokeWidth "6" ]) []
            , Svg.line (coordAttrs ++ [ stroke "black", strokeWidth "1", markerEnd "url(#arrow)" ]) []

            -- TODO draw bacground rectangle whose size is based on edge label's text bounding box
            , positionedText edgeCenterX edgeCenterY edgeTextId "test text1" [ SvgMouse.onClickStopPropagation NoOp ]
            ]


svgDefs : Svg Msg
svgDefs =
    Svg.defs [] [ arrowHeadMarkerDef ]


{-| Arrowhead to be reused by all edges, inspired by <http://vanseodesign.com/web-design/svg-markers/>
-}
arrowHeadMarkerDef : Svg a
arrowHeadMarkerDef =
    Svg.marker [ id "arrow", markerWidth "15", markerHeight "6", refX "15", refY "3", orient "auto", markerUnits "strokeWidth" ]
        [ Svg.path [ d "M0,0 L0,6 L15,3 z", fill "black" ] []
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


characterWidthPixels : Int
characterWidthPixels =
    9


characterHeightPixels : Int
characterHeightPixels =
    15


boxHeight : Int
boxHeight =
    characterHeightPixels + 10


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
