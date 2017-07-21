module View exposing (view)

import Canvas
import Graph exposing (NodeId)
import Html exposing (Html, button, div, form, h3, input, label, li, span, text, ul)
import Html.Attributes as Attr exposing (autofocus, class, classList, id, name, placeholder, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Svg exposing (Svg)
import SvgMouse
import Types exposing (Drag, EditorMode(..), GraphNode, Model, ModelGraph, Msg, Msg(..), NodeLabel)


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
                    [ SvgMouse.onCanvasMouseDown CanvasClicked ]

                _ ->
                    []

        svgElemAttributes =
            canvasEventListeners ++ [ style [ ( "width", "100%" ), ( "height", "100%" ), ( "position", "fixed" ) ] ]
    in
        Svg.svg svgElemAttributes
            (Graph.nodes graph |> List.map (viewNode draggedNode editorMode))


viewNode : Maybe Drag -> EditorMode -> GraphNode -> Svg Msg
viewNode mDrag editorMode node =
    let
        labelMaybeAffectedByDrag =
            case mDrag of
                Just drag ->
                    if drag.nodeId == node.id then
                        Types.getDraggedNodePosition drag node.label
                    else
                        node.label

                Nothing ->
                    node.label
    in
        Canvas.boxedText node.id labelMaybeAffectedByDrag editorMode


viewNodeForm : Model -> Html Msg
viewNodeForm { editorMode, graph } =
    case editorMode of
        NodeEditMode (Just ( nodeId, nodeText )) ->
            nodeForm nodeId nodeText

        _ ->
            Html.text ""


controlsPanel : EditorMode -> Html Msg
controlsPanel currentMode =
    let
        nodeEditModeEnabled =
            --TODO don't like this chatty way of recognizing the enum constant. Better way?
            case currentMode of
                NodeEditMode _ ->
                    True

                _ ->
                    False
    in
        div [ class "card card-outline-secondary", style [ ( "width", "10rem" ) ] ]
            [ ul [ class "list-group list-group-flush" ]
                [ modeView (currentMode == BrowsingMode) "Browse" BrowsingMode
                , modeView nodeEditModeEnabled "Edit nodes" (NodeEditMode Nothing)
                , modeView (currentMode == EdgeEditMode) "Edit edges" EdgeEditMode
                , modeView (currentMode == DeletionMode) "Deletion mode" DeletionMode
                ]
            ]


modeView : Bool -> String -> EditorMode -> Html Msg
modeView isActive modeText mode =
    li [ classList [ ( "list-group-item", True ), ( "active", isActive ) ], onClick (SetMode mode) ]
        [ text modeText ]


nodeForm : NodeId -> String -> Html Msg
nodeForm nodeId nodeText =
    div [ class "card", style [ ( "width", "18rem" ) ] ]
        [ form [ class "card-block input-group", onSubmit (NodeEditConfirm nodeId nodeText) ]
            [ input [ class "form-control", placeholder "Node text", type_ "text", autofocus True, value nodeText, onInput (NodeLabelEdit nodeId) ] []
            ]
        ]
