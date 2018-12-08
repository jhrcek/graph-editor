module Data.Layout exposing
    ( LayoutEngine(..)
    , engineToString
    )


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
