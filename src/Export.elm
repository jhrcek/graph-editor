module Export exposing (toTGF)

import Graph
import Types exposing (EdgeLabel(..), ModelGraph, NodeText(..))


toTGF : ModelGraph -> String
toTGF graph =
    let
        nodes =
            Graph.nodes graph
                |> List.map
                    (\{ id, label } ->
                        let
                            (NodeText _ nodeLabel) =
                                label.nodeText
                        in
                        toString id ++ " " ++ nodeLabel
                    )

        edges =
            Graph.edges graph
                |> List.map
                    (\{ from, to, label } ->
                        let
                            (EdgeLabel _ edgeLabel) =
                                label
                        in
                        toString from ++ " " ++ toString to ++ " " ++ edgeLabel
                    )
    in
    (nodes ++ "#" :: edges)
        -- trimming is questionable; little info about the format exists.
        -- yEd imports it fine though.
        |> List.map String.trim
        |> String.join "\n"
