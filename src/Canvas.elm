module Canvas exposing (boxedText, drawEdge, edgeArrow, positionedText, svgDefs)

import Graph exposing (NodeId)
import Html.Attributes exposing (style)
import Html.Events
import Svg exposing (Svg, g, rect, text, text_)
import Svg.Attributes as Sattr exposing (d, dominantBaseline, fill, fillOpacity, fontFamily, fontSize, height, markerEnd, markerHeight, markerUnits, markerWidth, orient, refX, refY, rx, ry, stroke, strokeWidth, textAnchor, transform, width, x1, x2, y1, y2)
import SvgMouse
import Types exposing (DragMsg(..), EdgeLabel(..), EditState(..), EditorMode(..), GraphEdge, GraphNode, Msg(..), NodeLabel, NodeText(..), nodeLabelToString)


boxedText : GraphNode -> EditorMode -> Svg Msg
boxedText ({ id, label } as node) editorMode =
    let
        tranformValue =
            "translate(" ++ String.fromInt (label.x - boxCenterX) ++ "," ++ String.fromInt (label.y - boxCenterY) ++ ")"

        boxWidth =
            getBoxWidth label.nodeText

        boxCenterX =
            boxWidth // 2

        boxCenterY =
            boxHeight // 2

        modeDependentAttributes =
            case editorMode of
                LayoutMode ->
                    [ onClickStartDrag id
                    , style "cursor" "move"
                    ]

                EditMode editState ->
                    case editState of
                        EditingNothing ->
                            [ onMouseDownSelectStartingNode id
                            , onDoubleClickStartNodeLabelEdit node
                            ]

                        CreatingEdge selectedNodeId _ ->
                            [ if id == selectedNodeId then
                                SvgMouse.onMouseUpUnselectStartNode

                              else
                                onMouseUpCreateEdge id
                            ]

                        EditingEdgeLabel _ ->
                            [ onDoubleClickStartNodeLabelEdit node ]

                        EditingNodeLabel _ ->
                            [ onDoubleClickStartNodeLabelEdit node ]

                DeletionMode ->
                    [ onClickDeleteNode id
                    , style "cursor" "not-allowed"
                    ]

        nodeTextId =
            String.fromInt id
    in
    g
        [ transform tranformValue ]
        [ rect
            ([ width (String.fromInt boxWidth)
             , height (String.fromInt boxHeight)
             , rx "4"
             , ry "4"
             , stroke "black"
             , strokeWidth "1"
             , fill "white"
             ]
                ++ modeDependentAttributes
            )
            []
        , positionedText boxCenterX boxCenterY nodeTextId (nodeLabelToString label) modeDependentAttributes
        ]


positionedText : Int -> Int -> String -> String -> List (Svg.Attribute Msg) -> Svg Msg
positionedText xCoord yCoord elementId textContent additionalAttributes =
    text_
        ([ Sattr.id elementId
         , Sattr.x <| String.fromInt xCoord
         , Sattr.y <| String.fromInt yCoord
         , fill "black"
         , textAnchor "middle"
         , dominantBaseline "central" -- alignmentBaseline not working on FF - see https://stackoverflow.com/questions/19212498/firefox-support-for-alignment-baseline-property#answer-21373135
         , fontSize "16px"
         , fontFamily "sans-serif, monospace"

         --prevent text to be selectable by click+dragging
         , style "user-select" "none"

         --prevent text to be selectable by click+dragging
         , style "-moz-user-select" "none"
         ]
            ++ additionalAttributes
        )
        [ text textContent ]


getBoxWidth : NodeText -> Int
getBoxWidth (NodeText mBBox str) =
    -- When there's no text in the node, render it as a square
    if String.isEmpty str then
        boxHeight

    else
        case mBBox of
            Nothing ->
                characterWidthPixels * String.length str

            Just bbox ->
                characterWidthPixels + round bbox.width


edgeArrow : GraphEdge -> GraphNode -> GraphNode -> EditorMode -> Svg Msg
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
                    [ onClickDeleteEdge fromNode.id toNode.id, style "cursor" "not-allowed" ]

                EditMode _ ->
                    [ onDoubleClickStartEdgeLabelEdit edge, SvgMouse.onMouseDownStopPropagation NoOp ]

                _ ->
                    [ SvgMouse.onMouseDownStopPropagation NoOp ]

        edgeTextId =
            String.fromInt fromNode.id ++ ":" ++ String.fromInt toNode.id
    in
    drawEdge fromNode.label arrowHeadX arrowHeadY edgeTextId edge modeDependentAttributes


drawEdge : NodeLabel -> Int -> Int -> String -> GraphEdge -> List (Svg.Attribute Msg) -> Svg Msg
drawEdge fromLabel xTo yTo edgeTextId edge attrList =
    let
        coordAttrs =
            [ x1 (String.fromInt fromLabel.x)
            , y1 (String.fromInt fromLabel.y)
            , x2 (String.fromInt xTo)
            , y2 (String.fromInt yTo)
            ]

        edgeCenterX =
            (fromLabel.x + xTo) // 2

        edgeCenterY =
            (fromLabel.y + yTo) // 2

        (EdgeLabel mBBox edgeText) =
            edge.label

        backgroundRect attrs =
            case mBBox of
                Nothing ->
                    Svg.text ""

                Just bbox ->
                    rect
                        ([ Sattr.x (String.fromFloat bbox.x)
                         , Sattr.y (String.fromFloat bbox.y)
                         , width (String.fromFloat bbox.width)
                         , height (String.fromFloat bbox.height)
                         , fill "white"
                         , fillOpacity "0.8"
                         ]
                            ++ attrs
                        )
                        []
    in
    g attrList
        [ Svg.line (coordAttrs ++ [ stroke "transparent", strokeWidth "6" ]) []
        , Svg.line (coordAttrs ++ [ stroke "black", strokeWidth "1", markerEnd "url(#arrow)" ]) []
        , backgroundRect attrList
        , positionedText edgeCenterX edgeCenterY edgeTextId edgeText attrList
        ]


svgDefs : Svg Msg
svgDefs =
    Svg.defs [] [ arrowHeadMarkerDef ]


{-| Arrowhead to be reused by all edges, inspired by <http://vanseodesign.com/web-design/svg-markers/>
-}
arrowHeadMarkerDef : Svg a
arrowHeadMarkerDef =
    Svg.marker [ Sattr.id "arrow", markerWidth "15", markerHeight "6", refX "15", refY "3", orient "auto", markerUnits "strokeWidth" ]
        [ Svg.path [ d "M0,0 L0,6 L15,3 z", fill "black" ] []
        ]


onDoubleClickStartNodeLabelEdit : GraphNode -> Svg.Attribute Msg
onDoubleClickStartNodeLabelEdit node =
    SvgMouse.onDoubleClickStopPropagation (NodeLabelEditStart node)


onDoubleClickStartEdgeLabelEdit : GraphEdge -> Svg.Attribute Msg
onDoubleClickStartEdgeLabelEdit edge =
    SvgMouse.onDoubleClickStopPropagation (EdgeLabelEditStart edge)


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
    Html.Events.onMouseUp (EndNodeOfEdgeSelected nodeId)


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
determineAngle boxWidth boxHeight_ =
    atan2 (toFloat boxHeight_) (toFloat boxWidth)


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
