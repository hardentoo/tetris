{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}

module Tetris.Types where

import Data.Binary
import Network.WebSockets
import GHC.Generics

-- =========================================
-- Types and constants
-- =========================================

-- | frames per second
glob_fps :: Int
glob_fps = 60

-- | length and width of the block in pixels
blockSize :: Int
blockSize = 30

-- | Initial speed af falling for a figure
init_tact :: Speed
init_tact = 0.7

-- | Name of the player in multiplayer mode (just for server)
type PlayerName = String

-- | Representation of the board as a list of blockes
type BlockedFigure = (Coord, Coord, Coord, Coord)

-- | Representation of board as a list of fulfilled blocks in it
type Board = [Coord]

-- | Score type
type Score = Int

-- | Block type. Contains x and y coordinates of its left upper point and 
-- integer representation of colour
-- type Coord = (Int, Int, Int)

data Coord = Coord 
  { x   :: Int  -- ^ Координата x.
  , y   :: Int  -- ^ Координата y.
  , clr :: Int  -- ^ Цвет блока.
  } deriving(Eq, Show, Generic)

instance Binary Coord

-- | Type for time (passed from previous tact)
type Time = Float

-- | Type for speed (duration on one tact)
type Speed = Float

--Для каждой фигуры свой тип, чтобы однозначно можно было 
--определить ее и тип операций над ней, например, фигуру I можно вращать
--произвольно только на расстоянии больше 4 клеток от края,
--а фигуру O на расстоянии больше 2 клеток от края

data FigureType = O | I | T | J | L | S | Z
                      deriving(Generic, Eq, Show)

data Direction = DUp | DDown | DLeft | DRight
                      deriving(Generic, Eq, Show)

data Figure = Figure 
  {
    f_type      :: FigureType 
  , direction :: Direction
  , coord     :: Coord 
  } deriving(Generic, Eq, Show)

instance Binary FigureType
instance Binary Direction 
instance Binary Figure


-- | Ширина экрана.
screenWidth :: Int
screenWidth = 300

-- | Высота экрана.
screenHeight :: Int
screenHeight = 600


-- this should replace current gamestate (tuple)
data GameState = GameState
 {  board   :: Board
  , figures :: [Figure]
  , speed   :: Speed
  , time    :: Time
  , score   :: Score
  } deriving (Generic, Eq)


instance Show GameState where
  show GameState{..} = 
    show board ++ " " ++
    show (head figures) ++ " " ++ 
    show speed ++ " " ++
    show time ++ " " ++
    show score ++ "end "

-- fromGS :: GameState -> Gamestate
-- fromGS GameState{..} = (board, figures, (speed, time), score)


-- toGS :: Gamestate -> GameState
-- toGS (board, figures, (speed, time), score) = GameState board figures speed time score


toWeb :: GameState -> WebGS
toWeb GameState{..} = WebGS board (take 10 figures) speed time score


fromWeb :: WebGS -> GameState
fromWeb WebGS{..} = GameState w_board w_figures w_speed w_time w_score



data WebGS = WebGS
  { w_board   :: Board
  , w_figures :: [Figure]
  , w_speed   :: Speed
  , w_time    :: Time
  , w_score   :: Score
  } deriving (Generic)

instance Show WebGS where
  show WebGS{..} = 
    show w_board ++ " " ++
    show (head w_figures) ++ " " ++ 
    show w_speed ++ " " ++
    show w_time ++ " " ++
    show w_score ++ "end "

instance Binary WebGS

instance WebSocketsData WebGS where
  fromLazyByteString = decode
  toLazyByteString   = encode


data GSPair = GSPair WebGS WebGS deriving(Generic)

instance Binary GSPair

instance WebSocketsData GSPair where
  fromLazyByteString = decode
  toLazyByteString   = encode


-- (l, h + blockSize, c)



-- take2 :: (Int, Int, Int) -> Int
-- take2 (_, b, _) = b



-- fromWebGS :: WebGS -> Gamestate
-- fromWebGS WebGS{..} = (w_board, w_figures, (w_speed, w_time), w_score)


-- toWebGS :: Gamestate -> WebGS
-- toWebGS (board, figures, (speed, time), score) = WebGS board (take 10 figures) speed time score