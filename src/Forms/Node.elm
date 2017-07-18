module Forms.Node exposing (nodeForm)

import Graph exposing (NodeId)
import Html exposing (Html, button, div, form, h3, input, label, text)
import Html.Attributes as Attr exposing (autofocus, class, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Types exposing (EditorMode(..), ModelGraph, Msg(..))


nodeForm : NodeId -> String -> Html Msg
nodeForm nodeId nodeText =
    div [ class "popover left in", style [ ( "top", "0px" ), ( "left", "0px" ), ( "display", "block" ) ] ]
        [ h3 [ class "popover-title" ] [ text "Edit Node" ]
        , div [ class "popover-content" ]
            [ form [ onSubmit (NodeEditConfirm nodeId nodeText) ]
                [ div [ class "form-group" ]
                    [ label [ class "col-md-12 control-label" ] [ text "Node ID" ]
                    , div [ class "col-md-4" ]
                        [ input
                            [ class "form-control field"
                            , Attr.id "nodeId"
                            , type_ "text"
                            , value (toString nodeId)
                            , readonly True
                            ]
                            []
                        ]
                    ]
                , div [ class "form-group" ]
                    [ label [ class "col-md-12 control-label" ] [ text "Node label" ]
                    , div [ class "col-md-10" ]
                        [ input
                            [ class "form-control field"
                            , Attr.id "nodeLabel"
                            , type_ "text"
                            , value nodeText
                            , onInput (NodeLabelEdit nodeId)
                            , autofocus True
                            ]
                            []
                        ]
                    ]
                , div [ class "popover-footer" ]
                    [ button [ class "btn btn-primary", Attr.id "confirmEdit", type_ "submit" ] [ text "Ok" ]
                    , button [ class "btn btn-default", Attr.id "cancelEdit", type_ "button", onClick NodeEditCancel ] [ text "Cancel" ]
                    , button [ class "btn btn-danger", Attr.id "deleteNode", onClick (DeleteNode nodeId) ] [ text "Delete" ]
                    ]
                ]
            ]
        ]
