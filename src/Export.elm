module Export exposing (toTGF)

import Graph.TGF
import Types exposing (ModelGraph, edgeLabelToString, nodeTextToString)


toTGF : ModelGraph -> String
toTGF =
    Graph.TGF.output (.nodeText >> nodeTextToString) edgeLabelToString
