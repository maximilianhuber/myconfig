{-# LANGUAGE LambdaCase #-}
module MyPhoto.Utils
  where

import           Data.Text (Text)
import qualified Data.Text as Text
import           Control.Monad ((>=>))
import           System.FilePath (takeExtension)
import qualified Data.Char as C

import MyPhoto.Model

logStr :: String -> PAction
logStr msg = PAction $
  \imgs -> do
    putStrLn msg
    return (Right imgs)

line :: String
line = "################################################################################"
endLine :: PAction
endLine = PAction $
  \imgs -> do
    putStrLn ("## (#=" ++ show (length imgs) ++ ")")
    putStrLn line
    return (Right imgs)
logSeparator :: String -> PAction
logSeparator "" = logStr line
logSeparator msg = logStr ( line ++"\n## " ++ msg)

filterByExtension :: [String] -> PAction
filterByExtension exts = let
    lowerExts = map (map C.toLower) exts
    hasOneOfTheExtensions :: FilePath -> Bool
    hasOneOfTheExtensions img = let
        ext = (map C.toLower . takeExtension) img
      in ext `elem` lowerExts
  in PAction $
    \imgs -> do
      putStr ("### filter by extension: " ++ show exts)
      let oldLength = length imgs
          imgs' = filter hasOneOfTheExtensions imgs
          newLength = length imgs'
      putStrLn (" (#=" ++ show oldLength ++ ") -> (#=" ++ show newLength ++ ")")
      return (Right imgs')

assertThatAllExist :: PAction
assertThatAllExist = undefined
