module View exposing (view, focusLabelInput)

import Canvas
import Dom
import Graph exposing (Edge, NodeId)
import GraphUtil
import Html exposing (Html, button, div, form, h3, input, label, li, span, text, ul)
import Html.Attributes as Attr exposing (class, classList, id, name, placeholder, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Svg exposing (Svg)
import SvgMouse
import Task
import Types exposing (..)


view : Model -> Html Msg
view ({ graph, draggedNode, editorMode } as model) =
    Html.div []
        [ viewCanvas editorMode graph draggedNode
        , controlsPanel editorMode
        , viewNodeForm editorMode
        , viewEdgeForm editorMode graph
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
                Canvas.drawEdge fromNode.label mousePosition.x mousePosition.y "edgeTextIdNotNeeded" dummyEdge []

        _ ->
            Svg.text ""


dummyEdge : GraphEdge
dummyEdge =
    { from = 0, to = 0, label = EdgeLabel Nothing "" }


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


viewNodeForm : EditorMode -> Html Msg
viewNodeForm editorMode =
    case editorMode of
        NodeEditMode (Just node) ->
            nodeForm node

        _ ->
            Html.text ""


viewEdgeForm : EditorMode -> ModelGraph -> Html Msg
viewEdgeForm editorMode graph =
    case editorMode of
        EdgeEditMode (EditingEdgeLabel edge) ->
            edgeForm edge graph

        _ ->
            Html.text ""


nodeForm : GraphNode -> Html Msg
nodeForm { id, label } =
    let
        currentText =
            (nodeTextToString label.nodeText)
    in
        labelForm NodeLabelEdit NodeLabelEditConfirm "Node text" currentText label.x label.y


edgeForm : GraphEdge -> ModelGraph -> Html Msg
edgeForm ({ from, to, label } as edge) graph =
    let
        (EdgeLabel _ currentText) =
            edge.label

        -- The form edge is to be rendered at the center of the edge
        ( formX, formY ) =
            let
                fromNodeLabel =
                    GraphUtil.getNode from graph |> .label

                toNodeLabel =
                    GraphUtil.getNode to graph |> .label
            in
                ( (fromNodeLabel.x + toNodeLabel.x) // 2
                , (fromNodeLabel.y + toNodeLabel.y) // 2
                )
    in
        labelForm EdgeLabelEdit EdgeLabelEditConfirm "Edge text" currentText formX formY



-- TODO 95 and 13 are hardcoded halves of the size of the input field in the form


labelForm : (String -> Msg) -> Msg -> String -> String -> Int -> Int -> Html Msg
labelForm editMsg confirmMsg placeholderVal currentValue x y =
    form
        [ onSubmit confirmMsg
        , style
            [ ( "position", "absolute" )
            , ( "left", toString (x - 95) ++ "px" )
            , ( "top", toString (y - 13) ++ "px" )
            ]
        ]
        [ input [ type_ "text", placeholder placeholderVal, value currentValue, onInput editMsg, id labelInputId ] [] ]


controlsPanel : EditorMode -> Html Msg
controlsPanel currentMode =
    div [ class "btn-group m-2" ]
        [ modeView (currentMode == BrowsingMode) "Browse" BrowsingMode
        , modeView (isNodeEditMode currentMode) "Edit nodes" (NodeEditMode Nothing)
        , modeView (isEdgeEditMode currentMode) "Edit edges" (EdgeEditMode NothingSelected)
        , modeView (currentMode == DeletionMode) "Remove" DeletionMode
        ]


modeView : Bool -> String -> EditorMode -> Html Msg
modeView isActive modeText mode =
    let
        btnClass =
            if isActive then
                "btn btn-primary"
            else
                "btn btn-secondary"
    in
        button [ type_ "button", class btnClass, onClick (SetMode mode) ]
            [ text modeText ]


labelInputId : String
labelInputId =
    "labelForm"


focusLabelInput : Cmd Msg
focusLabelInput =
    Dom.focus labelInputId
        -- focusing DOM element might fail if the element with given id is not found - ignoring this case
        |> Task.attempt (\focusResult -> NoOp)
