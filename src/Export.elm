module Export exposing (toDot, toTgf)

import Dict exposing (Dict)
import Graph.DOT as DOT
import Graph.TGF as TGF
import Types exposing (EdgeLabel, ModelGraph, NodeLabel, edgeLabelToString, nodeLabelToString)


toTgf : ModelGraph -> String
toTgf =
    TGF.output nodeLabelToString edgeLabelToString


toDot : ModelGraph -> String
toDot =
    DOT.outputWithStylesAndAttributes DOT.defaultStyles nodeLabelToAttrs edgeLabelToAttrs


nodeLabelToAttrs : NodeLabel -> Dict String String
nodeLabelToAttrs =
    Dict.singleton "label" << nodeLabelToString


edgeLabelToAttrs : EdgeLabel -> Dict String String
edgeLabelToAttrs =
    Dict.singleton "label" << edgeLabelToString
