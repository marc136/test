module Test.Internal exposing (Test(..), failNow, filter)

import Random.Pcg as Random exposing (Generator)
import Test.Expectation exposing (Expectation(..))
import Dict exposing (Dict)
import Fuzz exposing (Fuzzer)
import Fuzz.Internal exposing (unpackGenVal, unpackGenTree)
import RoseTree exposing (RoseTree(..))
import Lazy.List


type Test
    = Test (Random.Seed -> Int -> List Expectation)
    | Labeled String Test
    | Batch (List Test)


{-| Create a test that always fails for the given reason and description.
-}
failNow : { description : String, reason : Test.Expectation.Reason } -> Test
failNow record =
    Test
        (\_ _ -> [ Test.Expectation.fail record ])


filter : (String -> Bool) -> Test -> Test
filter =
    filterHelp False


filterHelp : Bool -> (String -> Bool) -> Test -> Test
filterHelp lastCheckPassed isKeepable test =
    case test of
        Test _ ->
            if lastCheckPassed then
                test
            else
                Batch []

        Labeled desc labeledTest ->
            labeledTest
                |> filterHelp (isKeepable desc) isKeepable
                |> Labeled desc

        Batch tests ->
            tests
                |> List.map (filterHelp lastCheckPassed isKeepable)
                |> Batch
