{-# LANGUAGE LambdaCase #-}
module Lib
    ( module X
    , runMyPhoto
    ) where

import           System.Environment
import           Data.Map (Map)
import           Control.Monad
import qualified Data.Map as Map
import qualified Data.Text as Text
import qualified Data.Text.IO as Text
import           System.Exit

import MyPhoto.MyPhoto
import MyPhoto.Actions.UnRAW as X
import MyPhoto.Actions.UnTiff as X
import MyPhoto.Actions.Crop as X
import MyPhoto.Actions.Align as X
import MyPhoto.Actions.Stack as X
import MyPhoto.Actions.Show as X
import MyPhoto.Actions.Wait as X

actions :: Map String PrePAction
actions = Map.fromList [ ("unraw", unRAW)
                       , ("untiff", unTiff)
                       , ("crop", crop)
                       , ("align", align)
                       , ("stack", stack)
                       , ("wait", waitPAct)
                       , ("show", showImgs)
                       ]

type ComposeActionsState = (PAction, [String], Maybe PrePAction)
composeActions :: [String] -> (PAction, [Img])
composeActions = let

    composeActions' :: ComposeActionsState -> String -> ComposeActionsState
    composeActions' (act, opts, Nothing) opt = case opt `Map.lookup` actions of
      Just preAct -> (act, [], Just preAct) -- TODO: assert that otps were empty
      Nothing     -> (act, opts ++ [opt], Nothing)
    composeActions' (act, opts, Just preAct) "--" = (act <> endLine <> preAct opts, [], Nothing)
    composeActions' (act, opts, Just preAct) opt  = case opt `Map.lookup` actions of
      Just preAct2 -> (act <> endLine <> preAct opts, [], Just preAct2)
      Nothing      -> (act, opts ++ [opt], Just preAct)

  in (\(act, imgs) -> (act <> endLine <> logSeparator "Result:", imgs))
     . (\case
         (act, imgs, Nothing) -> (act, imgs)
         (act, opts, Just preAct) -> (act <> endLine <> preAct opts, []))
     . foldl composeActions' (mempty, [], Nothing)

help :: IO ()
help = do
  putStrLn "myphoto action [actArg [actArg ..]] [action [actArg [actArg ..]] ..] -- [img [img ...]]"
  putStrLn ""
  mapM_ (\(k,preAct) -> do
            putStrLn ""
            putStrLn k
            runPAction (preAct ["-h"]) [] >>= \case
              Left err -> putStrLn err
              _        -> mempty
            ) (Map.assocs actions)

runMyPhoto :: IO ()
runMyPhoto = do
  args <- getArgs

  when (args == ["-h"]) $ do
    help
    exitSuccess

  let (act, imgs) = composeActions args
  result <- runPAction act imgs
  case result of
    Left err   -> putStrLn err
    Right imgs' -> mapM_ putStrLn imgs'
