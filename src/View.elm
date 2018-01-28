module View exposing (focusLabelInput, view)

import Canvas
import Dom
import Graph
import GraphUtil
import Html exposing (Html, button, div, form, h3, input, text)
import Html.Attributes exposing (class, id, placeholder, size, style, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Markdown
import Svg exposing (Svg)
import Svg.Attributes exposing (fill)
import SvgMouse
import Task
import Types exposing (Drag, EdgeLabel(..), EditState(..), EditorMode(..), GraphEdge, GraphNode, Model, ModelGraph, Msg(..), isEditMode, nodeLabelToString)
import Window


view : Model -> Html Msg
view ({ graph, draggedNode, editorMode, windowSize } as model) =
    Html.div []
        [ viewCanvas editorMode graph draggedNode windowSize
        , controlsPanel editorMode
        , viewNodeForm editorMode
        , viewEdgeForm editorMode graph
        , helpModal model.helpEnabled
        , aboutModal model.aboutEnabled
        ]


viewCanvas : EditorMode -> ModelGraph -> Maybe Drag -> Window.Size -> Html Msg
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
                ++ [ style
                        [ ( "width", toString winSize.width ++ "px" )
                        , ( "height", toString winSize.height ++ "px" )
                        , ( "position", "fixed" )
                        ]
                   ]
    in
    Svg.svg svgElemAttributes <|
        if Graph.isEmpty graph then
            [ Canvas.positionedText (winSize.width // 2) (winSize.height // 2) "emptyGraphText" "Click anywhere to create first node" [ fill "grey" ] ]
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



-- TODO 95 and 13 are hardcoded halves of the form size 190 x 30


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
        [ input [ type_ "text", placeholder placeholderVal, value currentValue, onInput editMsg, id labelInputId, size 15 ] []
        , button [ onClick confirmMsg ] [ text "OK" ]
        ]


controlsPanel : EditorMode -> Html Msg
controlsPanel editorMode =
    div []
        [ modeButtons editorMode
        , helpAndAboutButtons
        ]


modeButtons : EditorMode -> Html Msg
modeButtons currentMode =
    div [ class "btn-group m-2" ]
        [ modeButton (isEditMode currentMode) "Create/Edit" (EditMode EditingNothing)
        , modeButton (currentMode == MoveMode) "Move" MoveMode
        , modeButton (currentMode == DeletionMode) "Delete" DeletionMode
        ]


modeButton : Bool -> String -> EditorMode -> Html Msg
modeButton isActive modeText mode =
    let
        btnClass =
            if isActive then
                "btn btn-primary"
            else
                "btn btn-secondary"
    in
    button [ type_ "button", class btnClass, onClick (SetMode mode) ]
        [ text modeText ]


helpAndAboutButtons : Html Msg
helpAndAboutButtons =
    div [ class "btn-group m-2", style [ ( "position", "absolute" ), ( "right", "0px" ) ] ]
        [ button [ type_ "button", class "btn btn-secondary", onClick ExportTgf ] [ text "Export TGF" ]
        , button [ type_ "button", class "btn btn-secondary", onClick ExportDot ] [ text "Export DOT" ]
        , button [ type_ "button", class "btn btn-secondary", onClick (ToggleHelp True) ] [ text "Help" ]
        , button [ type_ "button", class "btn btn-secondary", onClick (ToggleAbout True) ] [ text "About" ]
        ]


modalDialog : Bool -> Msg -> String -> Html Msg -> Html Msg
modalDialog enabled closeMsg modalTitle content =
    viewIf enabled <|
        div []
            [ div [ class "modal fade show", style [ ( "display", "block" ) ] ]
                [ div [ class "modal-dialog" ]
                    [ div [ class "modal-content" ]
                        [ div [ class "modal-header" ]
                            [ h3 [ class "modal-title" ] [ text modalTitle ]
                            , button [ class "close", type_ "button", onClick closeMsg ] [ text "×" ]
                            ]
                        , div [ class "modal-body" ]
                            [ content ]
                        ]
                    ]
                ]
            , div [ class "modal-backdrop fade show" ] []
            ]


helpModal : Bool -> Html Msg
helpModal helpEnabled =
    modalDialog helpEnabled (ToggleHelp False) "Help" helpContent


helpContent : Html a
helpContent =
    Markdown.toHtml [] """
**Elm Graph Editor** is simple editor for creating [directed graphs](https://en.wikipedia.org/wiki/Directed_graph).
It has three modes: *Create/Edit*, *Move* and *Delete*.
Each modes makes different graph editing actions available.

In **Create/Edit** mode you can
  * Create new nodes by **clicking** on the canvas
  * Edit node text by **double clicking** nodes. Enter confirms the edit.
  * Create new edges by **click & holding** mouse button on a node, dragging and **releasing mouse** on target node.
  * Edit edge text by **double clicking** edges. Enter confirms the edit.

In **Move** mode you can organize your nodes by drag & drop: click and hold the mouse on node, move it where you want and release the mouse button.

In **Delete** mode you can remove nodes and edges from the graph by just clicking them. Removing a node removes all its incoming and outgoing edges.
  """


aboutModal : Bool -> Html Msg
aboutModal aboutEnabled =
    modalDialog aboutEnabled (ToggleAbout False) "About" aboutContent


aboutContent : Html a
aboutContent =
    Markdown.toHtml [] """
**Elm Graph Editor** version 1.0.0

Created by [Jan Hrček](http://janhrcek.cz)

Implemented in [Elm](http://elm-lang.org/)

Source code available on [GitHub](https://github.com/jhrcek/graph-editor)
    """


viewIf : Bool -> Html Msg -> Html Msg
viewIf flag view =
    if flag then
        view
    else
        Html.text ""


labelInputId : String
labelInputId =
    "labelForm"


focusLabelInput : Cmd Msg
focusLabelInput =
    Dom.focus labelInputId
        -- focusing DOM element might fail if the element with given id is not found - ignoring this case
        |> Task.attempt (always NoOp)
