module Tetris where

import System.Random
import Graphics.Gloss.Data.Vector
import Graphics.Gloss.Geometry.Line
import Graphics.Gloss.Interface.Pure.Game
import GHC.Float

run :: IO ()

--run = putStrLn "This project is not yet implemented"
run = do
 g <- newStdGen

   --putStrLn "This project is not yet implemented"
 
 play display bgColor fps (genUniverse g ) drawTetris handleTetris updateTetris
   where
    display = InWindow "Tetris" (screenWidth, screenHeight) (200, 200)
    bgColor = black   -- цвет фона
    fps     = 5    -- кол-во кадров в секунду



-- =========================================
-- Types
-- =========================================



blockSize :: Int
blockSize = 30



                               --data Shape = J | L | I | S | Z | O | T
                               --         deriving (Eq, Show, Enum)
--Клетка заполнена?
data Block = Free | Full
         deriving(Eq, Show)

--Строки нашей доски
type Row = [Block]

--Все поле
type Board = [Coord]

--Счет
type Score = Int

--Координаты фигуры, поворот однозначно определяется 
--их последовательностью
type Coord = (Int, Int,Int)

--время
type Time = Float


--Состояние игры в текущий момент(разделили доску и фигуру,
--чтобы при полете фигуры не мигала вся доска, также, чтобы было более 
--оптимизировано)
--[Figure] - бесконечный список фигур, в текущем состоянии берем первый элемент списка
----------------------------------------------------------------------------------------------------------------------------------------------------------
type Gamestate = (Board,  [Figure], Speed, Score)
--data Gamestate = Gamestate
--    { board   :: Board  
--    , figure  :: Figure
--     , speed   :: Speed
--     , score    :: Score
--     }
------------------------------------------------------------------------------------------------------------------------------------------------------------

--Скорость
type Speed = Float

--Для каждой фигуры свой тип, чтобы однозначно можно было 
--определить ее и тип операций над ней, например, фигуру I можно вращать
--произвольно только на расстоянии больше 4 клеток от края,
--а фигуру O на расстоянии больше 2 клеток от края

data FigureType = O | I | T | J | L | S | Z
                      deriving(Eq, Show)

data Direction = DUp | DDown | DLeft | DRight
                      deriving(Eq, Show)

data Figure = Figure FigureType Direction Coord 
                      deriving(Eq, Show)


-- | Ширина экрана.
screenWidth :: Int
screenWidth = 300

-- | Высота экрана.
screenHeight :: Int
screenHeight = 600

-- =========================================
-- Generating
-- =========================================

--На вход принимается случайное число от 0 до 6, которое определяет
--Фигуру
genFigure::Int -> Figure
genFigure a | a== 0  =  Figure O DUp (div screenWidth 2, blockSize * 2,0) 
            | a== 1  =  Figure I DUp (div screenWidth 2, blockSize * 2,1) 
            | a== 2  =  Figure T DUp (div screenWidth 2, blockSize * 2,2) 
            | a== 3  =  Figure J DUp (div screenWidth 2, blockSize * 2,3) 
            | a== 4  =  Figure L DUp (div screenWidth 2, blockSize * 2,4) 
            | a== 5  =  Figure S DUp (div screenWidth 2, blockSize * 2,5) 
            | a== 6  =  Figure Z DUp (div screenWidth 2, blockSize * 2,6) 
------------------------------------------------------------------------------------------------------------------------------------------

-- | Инициализировать случайный бесконечный
-- список чисел от 0 до 6 которые соответствуют фигурам
initFigures :: StdGen -> [Figure]
initFigures g = map genFigure
  (randomRs getrange g)

-- диапазон генерации случайных чисел
getrange :: (Int, Int)
getrange = (0, 6)
  


--Заполняем доску пустыми значениями и генерируем бесконечное количество фигур

genEmptyBoard::Board
genEmptyBoard = []

genRows::Int->Int->[Row]
genRows _ 0 = []
genRows w h = (genRows w (h-1)) ++ [genRow w]


genRow::Int->Row
genRow 0 = []
genRow w = (genRow (w-1)) ++ [Free]


genUniverse::StdGen -> Gamestate
genUniverse g = (genEmptyBoard,initFigures g,0,0)


-------------------------------------------------------------------------------------------------------------------------------------
--Генерируем бесконечный список из случайных фигур
-- == initFigures
generateRandomFigureList:: StdGen -> [Figure]
generateRandomFigureList _ =  [Figure O DUp (0,0,0)]



-- =========================================
-- Moves
-- =========================================

--Поворачивает фигуру: положение фигуры в пространстве опредляется 
--двумя числами, функция смотрит, какая ей дана фигура, и вычисляет 
--расстояние до края доски и на основании этой информации поворачивает ее
--(если это можно сделать), т.е. изменяет 3 координату

type BlockedFigure = (Coord, Coord, Coord, Coord)


turn::Gamestate -> Gamestate
turn (a,(Figure t DUp c):rest,d,e) | collide1 = (a,(Figure t DUp c):rest,d,e)
                                   | otherwise = (a,(Figure t DRight c):rest,d,e)
                            where 
                                collide1 = collidesFigure (figureToDraw (Figure t DRight c)) a
turn (a,(Figure t DRight c):rest,d,e) | collide2 = (a,(Figure t DRight c):rest,d,e)
                                      | otherwise = (a,(Figure t DDown c):rest,d,e)
                            where 
                                collide2 = collidesFigure (figureToDraw (Figure t DDown c)) a
turn (a,(Figure t DDown c):rest,d,e) | collide3 = (a,(Figure t DDown c):rest,d,e)
                                     | otherwise = (a,(Figure t DLeft c):rest,d,e)
                            where 
                                collide3 = collidesFigure (figureToDraw (Figure t DLeft c)) a
turn (a,(Figure t DLeft c):rest,d,e) | collide4 = (a,(Figure t DLeft c):rest,d,e)
                                     | otherwise = (a,(Figure t DUp c):rest,d,e)
                            where 
                                collide4 = collidesFigure (figureToDraw (Figure t DUp c)) a

figureToDraw::Figure->BlockedFigure
figureToDraw (Figure O d c) = figureToDrawO (Figure O d c)
figureToDraw (Figure I d c) = figureToDrawI (Figure I d c)
figureToDraw (Figure T d c) = figureToDrawT (Figure T d c)
figureToDraw (Figure J d c) = figureToDrawJ (Figure J d c)
figureToDraw (Figure L d c) = figureToDrawL (Figure L d c)
figureToDraw (Figure S d c) = figureToDrawS (Figure S d c)
figureToDraw (Figure Z d c) = figureToDrawZ (Figure Z d c)


figureToDrawO::Figure -> BlockedFigure
figureToDrawO (Figure O _ (x, y,z)) = ((x, y,z), (x+blockSize, y,z), (x, y-blockSize,z), (x+blockSize, y-blockSize,z))


figureToDrawI::Figure -> BlockedFigure
figureToDrawI (Figure I d (x, y,z)) | (d == DUp) || (d == DDown) = ((x, y+blockSize,z), (x, y,z), (x, y-blockSize,z), (x, y-2*blockSize,z))
                  | otherwise = ((x-blockSize, y,z), (x, y,z), (x+blockSize, y,z), (x+2*blockSize, y,z))

figureToDrawZ::Figure -> BlockedFigure
figureToDrawZ (Figure Z d (x, y,z)) | (d == DUp) || (d == DDown) = ((x-blockSize, y-blockSize,z), (x-blockSize, y,z), (x, y,z), (x, y+blockSize,z))
                    | otherwise = ((x-blockSize, y,z), (x, y,z), (x, y-blockSize,z), (x+blockSize, y-blockSize,z))

figureToDrawS::Figure -> BlockedFigure
figureToDrawS (Figure S d (x, y,z)) | (d == DUp) || (d == DDown) = ((x-blockSize, y+blockSize,z), (x-blockSize, y,z), (x, y,z), (x, y-blockSize,z))
                    | otherwise = ((x-blockSize, y,z), (x, y,z), (x, y+blockSize,z), (x+blockSize, y+blockSize,z))


figureToDrawJ::Figure -> BlockedFigure
figureToDrawJ (Figure J d (x,y,z)) | d == DDown = ((x-blockSize, y-blockSize,z), (x, y-blockSize,z), (x, y,z), (x, y+blockSize,z))
                 | d == DUp = ((x, y-blockSize,z), (x, y,z), (x, y+blockSize,z), (x+blockSize, y+blockSize,z))
                 | d == DRight = ((x-blockSize, y,z), (x, y,z), (x+blockSize, y,z), (x+blockSize, y-blockSize,z))
                 | otherwise = ((x-blockSize, y+blockSize,z), (x-blockSize, y,z), (x, y,z), (x+blockSize, y,z))


figureToDrawL::Figure -> BlockedFigure
figureToDrawL (Figure L d (x,y,z)) | d == DDown = ((x, y+blockSize,z), (x, y,z), (x, y-blockSize,z), (x+blockSize, y-blockSize,z))
                 | d == DUp = ((x, y-blockSize,z), (x, y,z), (x, y+blockSize,z), (x-blockSize, y+blockSize,z))
                 | d == DRight = ((x-blockSize, y,z), (x, y,z), (x+blockSize, y,z), (x+blockSize, y+blockSize,z))
                 | otherwise = ((x-blockSize, y-blockSize,z), (x-blockSize, y,z), (x, y,z), (x+blockSize, y,z))

figureToDrawT::Figure -> BlockedFigure
figureToDrawT (Figure T d (x,y,z)) | d == DDown = ((x-blockSize, y,z), (x, y,z), (x+blockSize, y,z), (x, y-blockSize,z))
                 | d == DUp = ((x-blockSize, y,z), (x, y,z), (x+blockSize, y,z), (x, y+blockSize,z))
                 | d == DRight = ((x, y+blockSize,z), (x, y,z), (x, y-blockSize,z), (x+blockSize, y,z))
                 | otherwise = ((x, y+blockSize,z), (x, y,z), (x, y-blockSize,z), (x-blockSize, y,z))

--Принимает пустую доску, моделирует всю игру, после
--окончания возвращает счет
startGame::Board -> Score
startGame  _ =  0
--Переещает фигуру влево  



moveLeft::Gamestate -> Gamestate
moveLeft (a,((Figure s t (b,c,z)):rest),d,e) | collide = (a, ((Figure s t (b,c,z)):rest),d,e)
        |otherwise = (a, ((Figure s t (b - blockSize,c,z)):rest),d,e)
  where 
    collide = collidesFigureSides (figureToDraw (Figure s t (b - blockSize,c,z))) a

moveRight::Gamestate -> Gamestate
moveRight (a,(Figure s t (b,c,z)):rest,d,e) | collide = (a, ((Figure s t (b,c,z)):rest),d,e)
        |otherwise = (a, ((Figure s t (b + blockSize,c,z)):rest),d,e)
  where 
    collide = collidesFigureSides (figureToDraw (Figure s t (b + blockSize,c,z))) a


collidesBlock::Coord -> Bool
collidesBlock (a,b,z) | (a < 0) || (a  + blockSize > screenWidth) || (b < 0) || (b + blockSize > screenHeight) = True
       |otherwise = False


collidesBlockSides::Coord -> Board -> Bool
collidesBlockSides (a,b,z) [] = (a < 0) || (a  + blockSize > screenWidth)
collidesBlockSides (a,b,z) ((brda, brdb,z1):[]) = (a < 0) || (a  + blockSize > screenWidth) || (a==brda) && (b==brdb)
collidesBlockSides (a,b,z) ((brda, brdb,z1):brds) | (a < 0) || (a  + blockSize > screenWidth) || (a==brda) && (b==brdb)  = True
                                             | otherwise = collidesBlockSides (a,b,z) brds


collidesBlockDown::Coord -> Board-> Bool
collidesBlockDown (a,b,z) []  =   (b + blockSize > screenHeight)
collidesBlockDown (a,b,z) ((brda,brdb,z1):[])  =   ((b + blockSize > screenHeight) || (a==brda) && (b==brdb))
collidesBlockDown (a,b,z) ((brda,brdb,z1):brds)  | (b + blockSize > screenHeight) || (a==brda) && (b==brdb)  = True
                                            |  otherwise = collidesBlockDown (a,b,z) brds



collidesBlockUp::Coord -> Board-> Bool
collidesBlockUp (a,b,z) []  =  b < 0
collidesBlockUp (a,b,z) ((brda,brdb,z1):[])  =   (b < 0 && (b==brdb))
collidesBlockUp (a,b,z) ((brda,brdb,z1):brds)  | b < 0 && (b==brdb)  = True
                                          |  otherwise = collidesBlockUp (a,b,z) brds
--collidesBlockDown (a,b) ((brda,brdb):brds) = True


collidesFigure::BlockedFigure -> Board -> Bool
collidesFigure (a,b,c,d) board = (collidesFigureSides (a,b,c,d) board) || (collidesFigureDown (a,b,c,d) board)

collidesFigureSides::BlockedFigure -> Board -> Bool
collidesFigureSides (a,b,c,d) board | (collidesBlockSides a board) || (collidesBlockSides b board) || (collidesBlockSides c board) || (collidesBlockSides d board) = True
        |otherwise = False


collidesFigureDown::BlockedFigure -> Board -> Bool
collidesFigureDown (a,b,c,d) board | (collidesBlockDown a board) || (collidesBlockDown b board) || (collidesBlockDown c board) || (collidesBlockDown d board) = True
        |otherwise = False


isGameOver::Gamestate -> Bool
isGameOver (a,(f1:f2:rest),d,e) = collidesFigureDown (figureToDraw f2) a




sortRows :: Board -> Board
sortRows []     = []
sortRows ((brda,brdb,z):brds) = sortRows (filter (\(x,y,z) -> y > brdb) brds) ++ [(brda,brdb,z)] ++ sortRows (filter (\(x,y,z) -> y <= brdb) brds)


deleteRows :: Board -> Board
deleteRows [] = []
deleteRows ((brda,brdb,z):brds) | (length (filter (\(x,y,z) -> brdb == y) ((brda,brdb,z):brds)) == 10)  =  (deleteRows (map (\(x,y,z) -> (x, y + blockSize,z)) (filter (\(x,y,z) -> y < brdb) l)) ++ (filter (\(x,y,z) -> y > brdb) l))
                              | otherwise = (filter (\(x,y,z) -> brdb == y) ((brda,brdb,z):brds)) ++ (deleteRows  (filter (\(x,y,z) -> brdb /= y) ((brda,brdb,z):brds)))                  -----   ToDo:   Обработать левый операнд аппенда.  После функции проверить, что между У нет зазоров.
                         where l = (filter (\(x,y,z) -> brdb /= y) ((brda,brdb,z):brds))

--При нажатии клавиши "вниз" роняет фигуру 


dropit::Gamestate -> Int -> Gamestate
dropit (a,((Figure sha dir (b,c,z)):rest),d,e) pts  | collide = (a,((Figure sha dir (b,c,z)):rest),d,e+(div pts blockSize))                   
                                                  | otherwise = dropit (a,((Figure sha dir (b,c + blockSize,z)):rest),d,e) pts                                        
                                          where                                           
                                              collide = collidesFigureDown (figureToDraw (Figure sha dir (b,c + blockSize,z))) a





-----------------------------------------------------------------------------------------------------------------
--Смотрит, нет ли строк, которые можно удалить
--checkRowsToDelete::Board -> [Bool]
--checkRowsToDelete (r:[]) =  (checkRow r):[]
--checkRowsToDelete (r:rs) = (checkRow r) : (checkRowsToDelete rs)

--Смотрит, можно ли удаоить строку
--checkRow::Row -> Bool
--checkRow (Free:[]) = False
--checkRow (Full:[]) = True
--checkRow (c:cs)  | c == Free = False
       --          | otherwise =  checkRow cs
--Удаляет строку
--deleteRow::[Bool] -> Board -> Board
--deleteRow (b:bs) (r:rs)  | b == False = r:(deleteRow bs rs)
  --  | otherwise = (deleteRow bs rs)                                  

--------------------------------------------------------------------------------------------------------------
--gameover :: Gamestate -> Bool
--gameover _ =  False



-- =========================================
-- Drawing
-- =========================================





--Рисуем доску
--заглушка
--drawBoard::Board  -> Picture
--drawBoard _ =  translate (-w) h (scale 30 30 (pictures
--  [ color white (polygon [ (0, 0), (0, -2), (6, -2), (6, 0) ])            -- белая рамка
--  , color black (polygon [ (0, 0), (0, -1.9), (5.9, -1.9), (5.9, 0) ])    -- чёрные внутренности
--  , translate 2 (-1.5) (scale 0.01 0.01 (color red (text (show 0))))  -- красный счёт
--  ]))
--  where
--    w = fromIntegral screenWidth  / 2
--    h = fromIntegral screenHeight / 2

drawBoard::Board  -> Picture
drawBoard s = pictures (map drawBlock s)

drawBlock :: Coord-> Picture

drawBlock  (b,c,1) =  pictures [ translate (-w) h (scale  1 1 (pictures
 [ color blue  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])            -- белая рамка
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 2),fromIntegral (-c-30 )), (fromIntegral  (b +2),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c-28)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c-28)) ])
   ,color magenta  (polygon [ ( fromIntegral b+28, fromIntegral (-c)), (fromIntegral b+28, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])

   ]))



   


   
    ]
  where
  w = fromIntegral screenWidth  / 2
  h = fromIntegral screenHeight / 2
drawBlock  (b,c,2) =  pictures [ translate (-w) h (scale  1 1 (pictures
 [ color yellow  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])            -- белая рамка
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 2),fromIntegral (-c-30 )), (fromIntegral  (b +2),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c-28)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c-28)) ])
   ,color magenta  (polygon [ ( fromIntegral b+28, fromIntegral (-c)), (fromIntegral b+28, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ]))]
  where
  w = fromIntegral screenWidth  / 2
  h = fromIntegral screenHeight / 2
drawBlock  (b,c,3) =  pictures [ translate (-w) h (scale  1 1 (pictures
 [ color red  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])            -- белая рамка
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 2),fromIntegral (-c-30 )), (fromIntegral  (b +2),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c-28)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c-28)) ])
   ,color magenta  (polygon [ ( fromIntegral b+28, fromIntegral (-c)), (fromIntegral b+28, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ]))]
  where
  w = fromIntegral screenWidth  / 2
  h = fromIntegral screenHeight / 2
drawBlock  (b,c,4) =  pictures [ translate (-w) h (scale  1 1 (pictures
 [ color green  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])            -- белая рамка
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 2),fromIntegral (-c-30 )), (fromIntegral  (b +2),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c-28)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c-28)) ])
   ,color magenta  (polygon [ ( fromIntegral b+28, fromIntegral (-c)), (fromIntegral b+28, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ]))]
  where
  w = fromIntegral screenWidth  / 2
  h = fromIntegral screenHeight / 2
drawBlock  (b,c,5) =  pictures [ translate (-w) h (scale  1 1 (pictures
 [ color orange  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])            -- белая рамка
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 2),fromIntegral (-c-30 )), (fromIntegral  (b +2),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c-28)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c-28)) ])
   ,color magenta  (polygon [ ( fromIntegral b+28, fromIntegral (-c)), (fromIntegral b+28, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ]))]
  where
  w = fromIntegral screenWidth  / 2
  h = fromIntegral screenHeight / 2


drawBlock  (b,c,_) =  pictures [ translate (-w) h (scale  1 1 (pictures
 [ color white  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])            -- белая рамка
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (-c - 2)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 2),fromIntegral (-c-30 )), (fromIntegral  (b +2),fromIntegral (- c)) ])
   ,color magenta  (polygon [ ( fromIntegral b, fromIntegral (-c-28)), (fromIntegral b, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c-28)) ])
   ,color magenta  (polygon [ ( fromIntegral b+28, fromIntegral (-c)), (fromIntegral b+28, fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (-c - 30)), (fromIntegral  (b + 30),fromIntegral (- c)) ])
   ]))]
  where
  w = fromIntegral screenWidth  / 2
  h = fromIntegral screenHeight / 2

drawFigure::Gamestate  ->  Picture
drawFigure (b,(f:fs),s,t) = drawBlockedFigure  (figureToDraw f)

drawBlockedFigure::BlockedFigure -> Picture

 
drawBlockedFigure ((a, b, c, d)) =         pictures  [drawBlock   a ,
                                                     drawBlock    b ,
                                                     drawBlock     c ,
                                                     drawBlock     d ]










--Рисуем тетрис
--Пока только рисует квадрат
drawTetris ::Gamestate-> Picture
drawTetris (b,fs,s,t) = pictures
  [ drawFigure (b,fs,s,t),
   drawBoard b ,
    drawScore t
  ] 


drawScore :: Score -> Picture
drawScore score = translate (-w) h (scale 30 30 (pictures
  [ color yellow (polygon [ (0, 0), (0, -2), (6, -2), (6, 0) ])            -- белая рамка
  , color black (polygon [ (0, 0), (0, -1.9), (5.9, -1.9), (5.9, 0) ])    -- чёрные внутренности
  , translate 2 (-1.5) (scale 0.01 0.01 (color green (text (show score))))  -- красный счёт
  ]))
  where
    w = fromIntegral screenWidth  / 2
    h = fromIntegral screenHeight / 2

-- =========================================
-- Updating
-- =========================================


--Проверяет, достигла ли нижняя часть фигуры нижней 
--границы доски или другой фигуры: делаем xor доски и фигуры,
--если количество свободных блоков одно и то же, то не достигла, иначе
--достигла Пока она реализована в updateTetris
collidesFloor::Gamestate -> Bool
collidesFloor _ =  False
--Проверяет, не выходит ли правая или левая часть фигуры за правую или
-- левую часть доски соответственно
--пока реализована в обраюотчиках клавиш
collidesSide::Gamestate -> Bool
collidesSide _ =  False
--Делает пустые блоки доски, на в которых находится фигура заполненными,
--вызываем ее после падения фигуры

vectolist :: (Coord, Coord, Coord, Coord) -> [Coord]
vectolist (a,b,c,d) = [a,b,c,d]

updateBoard::Figure -> Board ->Board
updateBoard (Figure sha dir (b ,c,z)) a = a ++ vectolist (figureToDraw (Figure sha dir (b ,c,z)))

--На основании прошедшего времени меняет скорость полета фигур
updateSpeed::Time -> Speed -> Speed
updateSpeed _ _ = 0


--Аргумент функции play, обновляет состояние тетриса
--С каждым кадром двигает фигуру вниз и пока здесь же проверяет, не достигла ли фигура нижней границы


updateTetris :: Float -> Gamestate -> Gamestate
updateTetris _  (a,(Figure sha dir (b,c,z):rest),d,e) | gameover = (genEmptyBoard,rest,d,0)
                                                    | collide =  (deleteRows (sortRows (updateBoard (Figure sha dir (b ,c,z)) a)), rest, d, e + 1)
                                                    | otherwise = (a,(Figure sha dir (b,c + blockSize,z):rest),d,e)
                                                       where
                                                       collide =  collidesFigureDown (figureToDraw (Figure sha dir (b ,c + blockSize,z)))   a
                                                       gameover = isGameOver (a,(Figure sha dir (b,c,z):rest),d,e)
--Обновить весь тетрис
updateTheWholeTetris:: Time -> Speed -> Gamestate -> Gamestate
updateTheWholeTetris _ _ (a,(b:rest),c,d) = (a,(b:rest),c,d)
-- ===========================================
-- timing
-- =======================================


--Обновляет общее состояние тетриса
--newTact::Figure -> Board -> Speed -> Gamestate
--newTact _ _ _ =  ([[Free]],[Figure O DUp (0,0)],0,0)
--Застявляет фигуру постоянно падать, вызываем эту фунцию на каждом такте
--newMove::Board -> Gamestate
--newMove _ =  ([[Free]],[Figure O DUp (0,0)],0,0)


--Аргумент функции play, которая говорит, что длает каждая клавиша


handleTetris :: Event -> Gamestate -> Gamestate

handleTetris (EventKey (Char 'l') Down _ _) (a,(Figure sha dir (b,c,z):rest),d,e) = moveRight (a,(Figure sha dir (b,c,z):rest),d,e)
handleTetris (EventKey (Char 'l') Up _ _) t = t

handleTetris (EventKey (Char 'j') Down _ _)  (a,(Figure sha dir (b,c,z):rest),d,e)  = moveLeft (a,(Figure sha dir (b,c,z):rest),d,e)
handleTetris (EventKey (Char 'j') Up _ _)  t  = t

handleTetris(EventKey (SpecialKey KeySpace) Down _ _ ) (a,(Figure sha dir (b,c,z):rest),d,e)  = dropit (a,(Figure sha dir (b,c,z):rest),d,e) (screenHeight-c)
handleTetris(EventKey (SpecialKey KeySpace) Up _ _ ) t = t

handleTetris (EventKey (Char 'k') Down _ _ ) (a,(Figure sha dir (b,c,z):rest),d,e) = turn (a, (Figure sha dir (b ,c,z):rest),d,e)
handleTetris (EventKey (Char 'k') Up _ _ ) t = t

handleTetris  _ t = t  






--------------