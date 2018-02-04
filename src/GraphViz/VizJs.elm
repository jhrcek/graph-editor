module GraphViz.VizJs exposing (NodePositions, processGraphVizResponse)

import IntDict exposing (IntDict)
import Json.Decode as Decode exposing (Decoder)
import Parser exposing ((|.), (|=), Parser)
import Window


type alias NodePositions =
    IntDict
        { x : Float
        , y : Float
        }


processGraphVizResponse : Decode.Value -> Window.Size -> Result String NodePositions
processGraphVizResponse value windowSize =
    decodeGraphvizResponse value
        |> Result.andThen parsePlainSource
        |> Result.map (scaleToWindow windowSize)



-- JSON to PlainSource


decodeGraphvizResponse : Decode.Value -> Result String PlainSource
decodeGraphvizResponse value =
    case Decode.decodeValue graphVizResponseDecoder value of
        Err decodeErr ->
            Err decodeErr

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
        |> Result.mapError toString


plainGraphParser : Parser PlainGraph
plainGraphParser =
    Parser.succeed PlainGraph
        |. Parser.keyword "graph"
        |. spaces
        --scale
        |= Parser.float
        |. spaces
        --width
        |= Parser.float
        |. spaces
        --height
        |= Parser.float
        |. Parser.ignoreUntil "\n"
        |= listOfNodesParser
        |. Parser.ignoreUntil "stop"


listOfNodesParser : Parser (List PlainNode)
listOfNodesParser =
    Parser.repeat Parser.zeroOrMore plainNodeParser


{-| Parse nodeId, x and y coordinate from GraphViz plain format's node line which has the format
"node name x y width height label style shape color fillcolor"
-}
plainNodeParser : Parser PlainNode
plainNodeParser =
    Parser.succeed PlainNode
        |. Parser.keyword "node"
        |. spaces
        -- nodeId
        |= Parser.int
        |. spaces
        -- x
        |= Parser.float
        |. spaces
        -- y
        |= Parser.float
        |. Parser.ignoreUntil "\n"


spaces : Parser ()
spaces =
    Parser.ignore Parser.zeroOrMore (\chr -> chr == ' ')



-- Scaling to window Size


scaleToWindow : Window.Size -> PlainGraph -> NodePositions
scaleToWindow windowSize plainGraph =
    let
        scaleX =
            toFloat windowSize.width / plainGraph.width

        scaleY =
            toFloat windowSize.height / plainGraph.height
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
