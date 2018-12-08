module GraphViz.VizJs exposing
    ( NodePositions
    , PlainGraph
    , PlainSource(..)
    , parsePlainSource
    , processGraphVizResponse
    )

import IntDict exposing (IntDict)
import Json.Decode as Decode exposing (Decoder)
import Parser exposing ((|.), (|=), Parser)
import Types exposing (WindowSize)


type alias NodePositions =
    IntDict
        { x : Float
        , y : Float
        }


processGraphVizResponse : Decode.Value -> WindowSize -> Result String NodePositions
processGraphVizResponse value windowSize =
    decodeGraphvizResponse value
        |> Result.andThen parsePlainSource
        |> Result.map (scaleToWindow windowSize)



-- JSON to PlainSource


decodeGraphvizResponse : Decode.Value -> Result String PlainSource
decodeGraphvizResponse value =
    case Decode.decodeValue graphVizResponseDecoder value of
        Err decodeErr ->
            Err <| Decode.errorToString decodeErr

        Ok result ->
            result


graphVizResponseDecoder : Decoder (Result String PlainSource)
graphVizResponseDecoder =
    Decode.oneOf
        [ Decode.field "GraphViz_PlainOutput" Decode.string |> Decode.map (Ok << PlainSource)
        , Decode.field "GraphViz_Error" Decode.string |> Decode.map Err
        ]



-- Plain Source to NodePositions


type PlainSource
    = PlainSource String


{-| Represents the part of data parsed from GraphViz
[plain](https://www.graphviz.org/doc/info/output.html#d:plain)
format, which is related to layout of nodes.
-}
type alias PlainGraph =
    { scale : Float
    , width : Float
    , height : Float
    , nodes : List PlainNode
    }


type alias PlainNode =
    { nodeId : Int
    , x : Float
    , y : Float
    }


parsePlainSource : PlainSource -> Result String PlainGraph
parsePlainSource (PlainSource plainSource) =
    Parser.run plainGraphParser plainSource
        |> Result.mapError Parser.deadEndsToString


plainGraphParser : Parser PlainGraph
plainGraphParser =
    Parser.succeed PlainGraph
        |. Parser.keyword "graph"
        |. Parser.spaces
        --scale
        |= Parser.float
        |. Parser.spaces
        --width
        |= Parser.float
        |. Parser.spaces
        --height
        |= Parser.float
        |. Parser.chompIf (\char -> char == '\n')
        |= listOfNodesParser
        |. Parser.chompUntil "stop"


listOfNodesParser : Parser (List PlainNode)
listOfNodesParser =
    Parser.sequence
        { start = ""
        , separator = ""
        , end = ""
        , spaces = Parser.spaces
        , item = plainNodeParser
        , trailing = Parser.Forbidden
        }


{-| Parse nodeId, x and y coordinate from GraphViz plain format's node line which has the format
"node name x y width height label style shape color fillcolor"
-}
plainNodeParser : Parser PlainNode
plainNodeParser =
    Parser.succeed PlainNode
        |. Parser.keyword "node"
        |. Parser.spaces
        -- nodeId
        |= Parser.int
        |. Parser.spaces
        -- x
        |= Parser.float
        |. Parser.spaces
        -- y
        |= Parser.float
        |. Parser.chompUntil "\n"



-- Scaling to window Size


scaleToWindow : WindowSize -> PlainGraph -> NodePositions
scaleToWindow windowSize plainGraph =
    let
        scaleX =
            windowSize.width / plainGraph.width

        scaleY =
            windowSize.height / plainGraph.height
    in
    plainGraph.nodes
        |> List.map
            (\plainNode ->
                ( plainNode.nodeId
                , { x = scaleX * plainNode.x
                  , y = scaleY * plainNode.y
                  }
                )
            )
        |> IntDict.fromList
