module VizJs exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import GraphViz.VizJs exposing (PlainGraph, PlainSource(..), parsePlainSource)
import Parser exposing ((|.))
import Test exposing (..)


suite : Test
suite =
    describe "GraphViz.VizJs"
        [ describe "parsePlainSource" <|
            List.indexedMap mkTest testCases
        ]


mkTest : Int -> ( PlainSource, PlainGraph ) -> Test
mkTest testIndex ( input, expectedOutput ) =
    test ("Graph " ++ String.fromInt testIndex) <|
        \_ -> Expect.equal (Ok expectedOutput) (parsePlainSource input)


testCases : List ( PlainSource, PlainGraph )
testCases =
    [ ( PlainSource
            """graph 1 0.75 1.5
              node 0 0.375 1.25 0.75 0.5 "" solid ellipse black lightgrey
              node 1 0.375 0.25 0.75 0.5 "" solid ellipse black lightgrey
              edge 0 1 4 0.375 0.99766 0.375 0.89071 0.375 0.76353 0.375 0.64468 solid black
              stop"""
      , { scale = 1
        , width = 0.75
        , height = 1.5
        , nodes =
            [ { nodeId = 0, x = 0.375, y = 1.25 }
            , { nodeId = 1, x = 0.375, y = 0.25 }
            ]
        }
      )
    ]
