module Data.Layout exposing
    ( LayoutEngine(..)
    , engineToString
    )

{-| GraphViz layout engines available through viz-js
<https://github.com/mdaines/viz.js/wiki/API#render-options>
-}


type LayoutEngine
    = Circo
    | Dot
    | Fdp
    | Neato
    | Osage
    | Twopi


engineToString : LayoutEngine -> String
engineToString layoutEngine =
    case layoutEngine of
        Circo ->
            "circo"

        Dot ->
            "dot"

        Fdp ->
            "fdp"

        Neato ->
            "neato"

        Osage ->
            "osage"

        Twopi ->
            "twopi"
