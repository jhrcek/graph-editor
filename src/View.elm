module View exposing (view)

import Canvas
import Graph exposing (Edge, NodeId)
import GraphUtil
import Html exposing (Html, button, div, form, h3, input, label, li, span, text, ul)
import Html.Attributes as Attr exposing (autofocus, class, classList, id, name, placeholder, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Svg exposing (Svg)
import SvgMouse
import Types exposing (..)


view : Model -> Html Msg
view ({ graph, draggedNode, editorMode } as model) =
    Html.div []
        [ viewCanvas editorMode graph draggedNode
        , controlsPanel model.editorMode
        , viewNodeForm model
        ]


viewCanvas : EditorMode -> ModelGraph -> Maybe Drag -> Html Msg
viewCanvas editorMode graph draggedNode =
    let
        canvasEventListeners =
            case editorMode of
                NodeEditMode _ ->
                    [ SvgMouse.onCanvasMouseDown CreateNode ]

                EdgeEditMode (FromSelected _ _) ->
                    [ SvgMouse.onMouseUpUnselectStartNode ]

                _ ->
                    []

        svgElemAttributes =
            canvasEventListeners ++ [ style [ ( "width", "100%" ), ( "height", "100%" ), ( "position", "fixed" ) ] ]

        nodesView =
            Graph.nodes graph |> List.map (viewNode draggedNode editorMode)

        edgesView =
            Graph.edges graph |> List.map (viewEdge graph draggedNode editorMode)

        edgeBeingCreated =
            getEdgeBeingCreated editorMode graph
    in
        Svg.svg svgElemAttributes <| Canvas.svgDefs :: edgeBeingCreated :: edgesView ++ nodesView


getEdgeBeingCreated : EditorMode -> ModelGraph -> Svg Msg
getEdgeBeingCreated editorMode graph =
    case editorMode of
        EdgeEditMode (FromSelected nodeId mousePosition) ->
            let
                fromNode =
                    GraphUtil.getNode nodeId graph
            in
                Canvas.drawEdge fromNode.label mousePosition.x mousePosition.y "edgeTextIdNotNeeded" (EdgeLabel Nothing "") []

        _ ->
            Svg.text ""


viewNode : Maybe Drag -> EditorMode -> GraphNode -> Svg Msg
viewNode mDrag editorMode node =
    let
        nodeMaybeAffectedByDrag =
            applyDrag mDrag node
    in
        Canvas.boxedText nodeMaybeAffectedByDrag editorMode


viewEdge : ModelGraph -> Maybe Drag -> EditorMode -> GraphEdge -> Html Msg
viewEdge graph mDrag editorMode edge =
    let
        fromNode =
            GraphUtil.getNode edge.from graph |> applyDrag mDrag

        toNode =
            GraphUtil.getNode edge.to graph |> applyDrag mDrag
    in
        Canvas.edgeArrow edge fromNode toNode editorMode


applyDrag : Maybe Drag -> GraphNode -> GraphNode
applyDrag mDrag node =
    case mDrag of
        Just drag ->
            if drag.nodeId == node.id then
                { node | label = Types.getDraggedNodePosition drag node.label }
            else
                node

        Nothing ->
            node


viewNodeForm : Model -> Html Msg
viewNodeForm { editorMode, graph } =
    case editorMode of
        NodeEditMode (Just node) ->
            nodeForm node.id (nodeTextToString node.label.nodeText) node.label.x node.label.y

        _ ->
            Html.text ""



-- This has size 246 x 38 TODO de-hard code the values


nodeForm : NodeId -> String -> Int -> Int -> Html Msg
nodeForm nodeId nodeText x y =
    div [ class "card", style [ ( "width", "18rem" ), ( "position", "absolute" ), ( "left", toString (x - 246 // 2) ++ "px" ), ( "top", toString (y - 38 // 2) ++ "px" ) ] ]
        [ form [ class "card-block input-group", onSubmit (NodeEditConfirm nodeId nodeText) ]
            [ input [ class "form-control", placeholder "Node text", type_ "text", autofocus True, value nodeText, onInput (NodeLabelEdit nodeId) ] []
            ]
        ]


controlsPanel : EditorMode -> Html Msg
controlsPanel currentMode =
    div [ class "card card-outline-secondary", style [ ( "width", "10rem" ) ] ]
        [ ul [ class "list-group list-group-flush" ]
            [ modeView (currentMode == BrowsingMode) "Browse" BrowsingMode
            , modeView (isNodeEditMode currentMode) "Edit nodes" (NodeEditMode Nothing)
            , modeView (isEdgeEditMode currentMode) "Edit edges" (EdgeEditMode NothingSelected)
            , modeView (currentMode == DeletionMode) "Deletion mode" DeletionMode
            ]
        ]


modeView : Bool -> String -> EditorMode -> Html Msg
modeView isActive modeText mode =
    li [ classList [ ( "list-group-item", True ), ( "active", isActive ) ], onClick (SetMode mode) ]
        [ text modeText ]
