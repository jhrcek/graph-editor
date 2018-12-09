port module Ports exposing
    ( receiveGraphVizPlain
    , requestGraphVizPlain
    )

import Data.Layout as Layout
import Export
import Json.Decode as Decode
import Types exposing (ModelGraph)


requestGraphVizPlain : Layout.LayoutEngine -> ModelGraph -> Cmd msg
requestGraphVizPlain layoutEngine graph =
    requestGraphVizPlain_Impl
        { layoutEngine = Layout.engineToString layoutEngine
        , graphvizSource = Export.toDot graph
        }


port receiveGraphVizPlain : (Decode.Value -> msg) -> Sub msg


{-| Request to transform Graphviz dot String to Graphviz plain.
The resulting plain output will contain additional info about node layout which we'll parse out and adjust node positions for nicer layout.
-}
port requestGraphVizPlain_Impl : { layoutEngine : String, graphvizSource : String } -> Cmd msg
