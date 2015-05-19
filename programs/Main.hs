{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
module Main where

import Control.Lens
import Data.Default
import Data.Monoid
import Graphics.Vty
import System.Exit

import Brick.Main
import Brick.Edit
import Brick.List
import Brick.Core
import Brick.Prim
import Brick.Center
import Brick.Border
import Brick.Util

styles :: [(String, BorderStyle)]
styles =
    [ ("ascii", asciiBorderStyle)
    , ("uni", unicodeBorderStyle)
    , ("uni-bold", unicodeBoldBorderStyle)
    , ("uni-rounded", unicodeRoundedBorderStyle)
    ]

data St =
    St { _stEditor :: Editor
       , _stList :: List Int
       , _stBorderStyle :: Int
       }

makeLenses ''St

drawUI :: St -> [Prim St]
drawUI st = [a]
    where
        bs = snd $ styles !! (st^.stBorderStyle)
        bsName = fst $ styles !! (st^.stBorderStyle)
        a = centered $
              borderedWithLabel bsName bs $
                (VLimit 1 $ HLimit 25 $ UseAttr (cyan `on` blue) $
                  With stEditor drawEditor)
                <<=
                hBorder bs
                =>>
                (VLimit 10 $ HLimit 25 $ With stList drawList)

appEvent :: Event -> St -> IO St
appEvent e st =
    case e of
        EvKey (KChar '1') [] -> return $ st & stBorderStyle .~ 0
        EvKey (KChar '2') [] -> return $ st & stBorderStyle .~ 1
        EvKey (KChar '3') [] -> return $ st & stBorderStyle .~ 2
        EvKey (KChar '4') [] -> return $ st & stBorderStyle .~ 3

        EvKey KEsc [] -> exitSuccess

        EvKey KEnter [] ->
            let el = length $ listElements $ st^.stList
            in return $ st & stList %~ listInsert el el

        ev -> return $ st & stEditor %~ (handleEvent ev)
                          & stList %~ (handleEvent ev)

initialState :: St
initialState =
    St { _stEditor = editor (CursorName "edit") ""
       , _stList = list listDrawElem []
       , _stBorderStyle = 0
       }

listDrawElem :: Bool -> Int -> Prim (List Int)
listDrawElem sel i =
    let selAttr = white `on` blue
        maybeSelect = if sel
                      then UseAttr selAttr
                      else id
    in maybeSelect $ hCentered (Txt $ "Number " <> show i)

theApp :: App St Event
theApp =
    def { appDraw = drawUI
        , appChooseCursor = showFirstCursor
        , appHandleEvent = appEvent
        }

main :: IO ()
main = defaultMain theApp initialState
