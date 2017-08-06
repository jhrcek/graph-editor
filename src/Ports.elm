port module Ports
    exposing
        ( setBoundingBox
        , requestNodeTextBoundingBox
        )

import Types exposing (BBox, Msg)
import Graph exposing (NodeId)


requestNodeTextBoundingBox : NodeId -> Cmd msg
requestNodeTextBoundingBox nodeId =
    requestBoundingBox (toString nodeId)



-- request bounding box of svg element with given String id


port requestBoundingBox : String -> Cmd msg



-- receive Bounding Box from js


port setBoundingBox : (BBox -> msg) -> Sub msg
