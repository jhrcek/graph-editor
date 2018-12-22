module View exposing (focusLabelInput, view)

import Browser.Dom as Dom
import Canvas
import Data.Layout as Layout
import Export
import Graph
import GraphUtil
import Html exposing (Html, button, div, form, h3, input, text, textarea)
import Html.Attributes exposing (checked, class, classList, id, name, placeholder, readonly, rows, size, style, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Markdown
import Svg exposing (Svg)
import Svg.Attributes exposing (fill)
import SvgMouse
import Task
import Types exposing (Drag, EdgeLabel(..), EditState(..), EditorMode(..), ExportFormat(..), GraphEdge, GraphNode, ModalState(..), Model, ModelGraph, Msg(..), WindowSize, exportFormatToString, nodeLabelToString)


view : Model -> Html Msg
view { graph, draggedNode, editorMode, windowSize, modalState } =
    Html.div []
        [ viewCanvas editorMode graph draggedNode windowSize
        , controlsPanel editorMode
        , viewNodeForm editorMode
        , viewEdgeForm editorMode graph
        , viewModal modalState graph
        ]


viewCanvas : EditorMode -> ModelGraph -> Maybe Drag -> WindowSize -> Html Msg
viewCanvas editorMode graph maybeDrag winSize =
    let
        canvasEventListeners =
            case editorMode of
                EditMode EditingNothing ->
                    [ SvgMouse.onCanvasMouseDown CreateNode ]

                EditMode (CreatingEdge _ _) ->
                    [ SvgMouse.onMouseUpUnselectStartNode ]

                _ ->
                    []

        svgElemAttributes =
            canvasEventListeners
                ++ [ style "width" (String.fromFloat winSize.width ++ "px")
                   , style "height" (String.fromFloat winSize.height ++ "px")
                   ]
    in
    Svg.svg svgElemAttributes <|
        if Graph.isEmpty graph then
            [ Canvas.positionedText
                (round <| winSize.width / 2)
                (round <| winSize.height / 2)
                "emptyGraphText"
                "Click anywhere to create the first node"
                [ fill "grey" ]
            ]

        else
            nonEmptyGraphView editorMode maybeDrag graph


nonEmptyGraphView : EditorMode -> Maybe Drag -> ModelGraph -> List (Svg Msg)
nonEmptyGraphView editorMode maybeDrag graph =
    let
        nodesView =
            Graph.nodes graph |> List.map (viewNode maybeDrag editorMode)

        edgesView =
            Graph.edges graph |> List.map (viewEdge graph maybeDrag editorMode)

        edgeBeingCreated =
            getEdgeBeingCreated editorMode graph
    in
    Canvas.svgDefs :: edgeBeingCreated :: edgesView ++ nodesView


getEdgeBeingCreated : EditorMode -> ModelGraph -> Svg Msg
getEdgeBeingCreated editorMode graph =
    case editorMode of
        EditMode (CreatingEdge nodeId mousePosition) ->
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
        EditMode (EditingNodeLabel node) ->
            nodeForm node

        _ ->
            Html.text ""


viewEdgeForm : EditorMode -> ModelGraph -> Html Msg
viewEdgeForm editorMode graph =
    case editorMode of
        EditMode (EditingEdgeLabel edge) ->
            edgeForm edge graph

        _ ->
            Html.text ""


nodeForm : GraphNode -> Html Msg
nodeForm { label } =
    let
        currentText =
            nodeLabelToString label
    in
    labelForm NodeLabelEdit NodeLabelEditConfirm "Node text" currentText label.x label.y


edgeForm : GraphEdge -> ModelGraph -> Html Msg
edgeForm ({ from, to } as edge) graph =
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


labelForm : (String -> Msg) -> Msg -> String -> String -> Int -> Int -> Html Msg
labelForm editMsg confirmMsg placeholderVal currentValue x y =
    form
        [ onSubmit confirmMsg
        , style "position" "absolute"

        -- 95 and 13 are hardcoded halves of the form size 190 x 30
        , style "left" (String.fromInt (x - 95) ++ "px")
        , style "top" (String.fromInt (y - 13) ++ "px")
        ]
        [ input [ type_ "text", placeholder placeholderVal, value currentValue, onInput editMsg, id labelInputId, size 15 ] []
        , button [ onClick confirmMsg ] [ text "OK" ]
        ]


controlsPanel : EditorMode -> Html Msg
controlsPanel editorMode =
    div [ style "position" "absolute", style "top" "0", style "width" "100%" ]
        [ modeButtons editorMode
        , helpAndAboutButtons
        , if editorMode == LayoutMode then
            div []
                [ layoutEngineButtons
                , zoomButtons
                ]

          else
            text ""
        ]


modeButtons : EditorMode -> Html Msg
modeButtons editorMode =
    let
        ( isEdit, isLayout, isDeletion ) =
            case editorMode of
                EditMode _ ->
                    ( True, False, False )

                LayoutMode ->
                    ( False, True, False )

                DeletionMode ->
                    ( False, False, True )
    in
    div [ class "btn-group m-2" ]
        [ modeButton isEdit "Create/Edit" (EditMode EditingNothing)
        , modeButton isLayout "Layout" LayoutMode
        , modeButton isDeletion "Delete" DeletionMode
        ]


modeButton : Bool -> String -> EditorMode -> Html Msg
modeButton isActive modeText mode =
    button
        [ type_ "button"
        , onClick (SetMode mode)
        , classList [ ( "btn", True ), ( "btn-primary", isActive ), ( "btn-secondary", not isActive ) ]
        ]
        [ text modeText ]


layoutEngineButtons : Html Msg
layoutEngineButtons =
    div [ class "btn-group btn-group-sm ml-2" ] <|
        List.map layoutEngineButton [ Layout.Dot, Layout.Circo, Layout.Fdp, Layout.Neato, Layout.Osage, Layout.Twopi ]


layoutEngineButton : Layout.LayoutEngine -> Html Msg
layoutEngineButton layoutEngine =
    button [ class "btn btn-secondary", onClick (PerformAutomaticLayout layoutEngine) ]
        [ text (Layout.engineToString layoutEngine) ]


zoomButtons : Html Msg
zoomButtons =
    div [ class "btn-group btn-group-sm ml-2" ]
        [ button [ class "btn btn-secondary", title "Shrink graph", onClick (Resize 0.9) ] [ text "➖" ]
        , button [ class "btn btn-secondary", title "Expand graph", onClick (Resize 1.1) ] [ text "➕" ]
        ]


helpAndAboutButtons : Html Msg
helpAndAboutButtons =
    div [ class "btn-group m-2", style "position" "absolute", style "right" "0px" ]
        [ button [ type_ "button", class "btn btn-secondary", onClick (ModalStateChange (Export Dot)) ] [ text "Export" ]
        , button [ type_ "button", class "btn btn-secondary", onClick (ModalStateChange Help) ] [ text "Help" ]
        , button [ type_ "button", class "btn btn-secondary", onClick (ModalStateChange About) ] [ text "About" ]
        ]


viewModal : ModalState -> ModelGraph -> Html Msg
viewModal modalState graph =
    case modalState of
        Hidden ->
            text ""

        Help ->
            modal "Help" helpContent

        About ->
            modal "About" aboutContent

        Export exportFormat ->
            modal "Export" <| exportModalBody exportFormat graph


modal : String -> Html Msg -> Html Msg
modal title body =
    div []
        [ div [ class "modal fade show", style "display" "block" ]
            [ div [ class "modal-dialog" ]
                [ div [ class "modal-content" ]
                    [ div [ class "modal-header" ]
                        [ h3 [ class "modal-title" ] [ text title ]
                        , button [ class "close", type_ "button", onClick (ModalStateChange Hidden) ] [ text "×" ]
                        ]
                    , div [ class "modal-body" ]
                        [ body ]
                    ]
                ]
            ]
        , div [ class "modal-backdrop fade show" ] []
        ]


exportModalBody : ExportFormat -> ModelGraph -> Html Msg
exportModalBody currentFormat graph =
    let
        exportPreview =
            case currentFormat of
                Tgf ->
                    Export.toTgf graph

                Dot ->
                    Export.toDot graph
    in
    div []
        [ div []
            [ text "Format"
            , formatRadio currentFormat Dot
            , formatRadio currentFormat Tgf
            ]
        , div [] [ textarea [ style "width" "100%", readonly True, rows 15 ] [ text exportPreview ] ]
        , div [] [ button [ class "btn btn-primary float-right", onClick (Download currentFormat) ] [ text "Download" ] ]
        ]


formatRadio : ExportFormat -> ExportFormat -> Html Msg
formatRadio currentFormat desiredFormat =
    Html.label []
        [ input
            [ type_ "radio"
            , name "exportFormat"
            , checked (currentFormat == desiredFormat)
            , onClick (ModalStateChange (Export desiredFormat))
            , class "mx-1"
            ]
            []
        , text <| exportFormatToString desiredFormat
        ]


helpContent : Html a
helpContent =
    Markdown.toHtml [] """
**Elm Graph Editor** is simple editor for creating [directed graphs](https://en.wikipedia.org/wiki/Directed_graph).
It has three modes: *Create/Edit*, *Move* and *Delete*.
Each modes makes different graph editing actions available.

In **Create/Edit** mode you can
  * create new nodes by clicking on the canvas
  * edit node text by double clicking nodes. Enter confirms the edit.
  * create new edges by click & holding mouse button on a node, dragging and releasing mouse on target node.
  * edit edge text by double clicking edges. Enter confirms the edit.

In **Layout** mode you can
  * move nodes by drag and drop
  * layout the entire graph automatically using one of the provided layout engines (based on [GraphViz](https://graphviz.gitlab.io/)).
  * move nodes closer together / further away from each other using - / + buttons.

In **Delete** mode you can remove nodes and edges from the graph by just clicking them. Removing a node removes all its incoming and outgoing edges.
  """


aboutContent : Html a
aboutContent =
    Markdown.toHtml [] """
**Elm Graph Editor** version 1.0.0

Created by [Jan Hrček](http://janhrcek.cz)

Implemented in [Elm](http://elm-lang.org/)

Source code available on [GitHub](https://github.com/jhrcek/graph-editor)
    """


labelInputId : String
labelInputId =
    "labelForm"


focusLabelInput : Cmd Msg
focusLabelInput =
    Task.attempt
        (\_ -> NoOp)
        (Dom.focus labelInputId)
