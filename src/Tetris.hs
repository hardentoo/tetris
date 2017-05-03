module Tetris where

import System.Random
import Graphics.Gloss.Data.Vector
import Graphics.Gloss.Geometry.Line
import Graphics.Gloss.Interface.Pure.Game
import GHC.Float

glob_fps = 60

run :: IO ()

run = do
 g <- newStdGen
 play display bgColor fps (genUniverse g ) drawTetris handleTetris updateTetris
   where
    display = InWindow "Tetris" (screenWidth, screenHeight) (200, 200)
    bgColor = black   -- цвет фона
    fps     = glob_fps   -- кол-во кадров в секунду



-- =========================================
-- Types
-- =========================================



blockSize :: Int
blockSize = 30

init_tact::Time
init_tact = 0.7

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
-- x y цвет 
type Coord = (Int, Int,Int)

--время
type Time = Float


type TetrisType = Int

--Состояние игры в текущий момент(разделили доску и фигуру,
--чтобы при полете фигуры не мигала вся доска, также, чтобы было более 
--оптимизировано)
--[Figure] - бесконечный список фигур, в текущем состоянии берем первый элемент списка
-- доска фигуры скорость время счет круговой(1) или прямоугольный(0) плавный(1) или чтупенчатый(0) init_tack
----------------------------------------------------------------------------------------------------------------------------------------------------------
type Gamestate = (Board,  [Figure], (Speed, Time), Score,TetrisType,TetrisType,Time)

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
genUniverse g = (genEmptyBoard,initFigures g,(init_tact, 0),0,0,0,0.7)


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
turn (a,(Figure t DUp c):rest,d,e,v,p,k) | collide1 = (a,(Figure t DUp c):rest,d,e,v,p,k)
                                   | otherwise = (a,(Figure t DRight c):rest,d,e,v,p,k)
                            where 
                                collide1 = collidesFigure (figureToDraw (Figure t DRight c)) a
turn (a,(Figure t DRight c):rest,d,e,v,p,k) | collide2 = (a,(Figure t DRight c):rest,d,e,v,p,k)
                                      | otherwise = (a,(Figure t DDown c):rest,d,e,v,p,k)
                            where 
                                collide2 = collidesFigure (figureToDraw (Figure t DDown c)) a
turn (a,(Figure t DDown c):rest,d,e,v,p,k) | collide3 = (a,(Figure t DDown c):rest,d,e,v,p,k)
                                     | otherwise = (a,(Figure t DLeft c):rest,d,e,v,p,k)
                            where 
                                collide3 = collidesFigure (figureToDraw (Figure t DLeft c)) a
turn (a,(Figure t DLeft c):rest,d,e,v,p,k) | collide4 = (a,(Figure t DLeft c):rest,d,e,v,p,k)
                                     | otherwise = (a,(Figure t DUp c):rest,d,e,v,p,k)
                            where 
                                collide4 = collidesFigure (figureToDraw (Figure t DUp c)) a




turn (a,(Figure t DUp c):rest,d,e,v,1,k) | collide1 = (a,(Figure t DUp c):rest,d,e,v,1,k)
                                   | otherwise = (a,(Figure t DRight c):rest,d,e,v,1,k)
                            where 
                                collide1 = collidesFigureSmooth (figureToDraw (Figure t DRight c)) a
turn (a,(Figure t DRight c):rest,d,e,v,1,k) | collide2 = (a,(Figure t DRight c):rest,d,e,v,1,k)
                                      | otherwise = (a,(Figure t DDown c):rest,d,e,v,1,k)
                            where 
                                collide2 = collidesFigureSmooth (figureToDraw (Figure t DDown c)) a
turn (a,(Figure t DDown c):rest,d,e,v,1,k) | collide3 = (a,(Figure t DDown c):rest,d,e,v,1,k)
                                     | otherwise = (a,(Figure t DLeft c):rest,d,e,v,1,k)
                            where 
                                collide3 = collidesFigureSmooth (figureToDraw (Figure t DLeft c)) a
turn (a,(Figure t DLeft c):rest,d,e,v,1,k) | collide4 = (a,(Figure t DLeft c):rest,d,e,v,1,k)
                                     | otherwise = (a,(Figure t DUp c):rest,d,e,v,1,k)
                            where 
                                collide4 = collidesFigureSmooth (figureToDraw (Figure t DUp c)) a


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
moveLeft (a,((Figure s t (b,c,z)):rest),d,e,v,p,k) | collide = (a, ((Figure s t (b,c,z)):rest),d,e,v,p,k)
        |otherwise = (a, ((Figure s t (b - blockSize,c,z)):rest),d,e,v,p,k)
  where 
    collide = collidesFigureSides (figureToDraw (Figure s t (b - blockSize,c,z))) a

moveRight::Gamestate -> Gamestate
moveRight (a,(Figure s t (b,c,z)):rest,d,e,v,p,k) | collide = (a, ((Figure s t (b,c,z)):rest),d,e,v,p,k)
        |otherwise = (a, ((Figure s t (b + blockSize,c,z)):rest),d,e,v,p,k)
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
collidesBlockSidesSmooth::Coord -> Board -> Bool
collidesBlockSidesSmooth (a,b,z) [] = (a < 0) || (a  + blockSize > screenWidth)
collidesBlockSidesSmooth (a,b,z) ((brda, brdb,z1):[]) = (a < 0) || (a  + blockSize > screenWidth) || (a==brda) && (b==brdb)||((a==brda) &&(b>(brdb - blockSize) && b<(brdb + blockSize)))
collidesBlockSidesSmooth (a,b,z) ((brda, brdb,z1):brds) | (a < 0) || (a  + blockSize > screenWidth) || (a==brda) && (b==brdb)||((a==brda) &&(b>(brdb - blockSize) && b<(brdb + blockSize)))  = True
                                             | otherwise = collidesBlockSides (a,b,z) brds

collidesBlockDown::Coord -> Board-> Bool
collidesBlockDown (a,b,z) []  =   (b + blockSize > screenHeight)
collidesBlockDown (a,b,z) ((brda,brdb,z1):[])  =   ((b + blockSize > screenHeight) || (a==brda) && (b==brdb))
collidesBlockDown (a,b,z) ((brda,brdb,z1):brds)  | (b + blockSize > screenHeight) || (a==brda) && (b==brdb)  = True
                                            |  otherwise = collidesBlockDown (a,b,z) brds
collidesBlockDownSmooth::Coord -> Board-> Bool
collidesBlockDownSmooth (a,b,z) []  =   (b  > screenHeight)|| (b < 0)
collidesBlockDownSmooth (a,b,z) ((brda,brdb,z1):[])  =   ((b  > screenHeight) || (a ==brda) && ((b )==brdb))|| (b < 0)
collidesBlockDownSmooth (a,b,z) ((brda,brdb,z1):brds)  | (b > screenHeight) || (a ==brda) && ((b ) ==brdb)|| (b < 0)  = True
                                            |  otherwise = collidesBlockDownSmooth (a,b,z) brds

collidesBlockUp::Coord -> Board-> Bool
collidesBlockUp (a,b,z) []  =  b < 0
collidesBlockUp (a,b,z) ((brda,brdb,z1):[])  =   (b < 0 && (b==brdb))
collidesBlockUp (a,b,z) ((brda,brdb,z1):brds)  | b < 0 && (b==brdb)  = True
                                          |  otherwise = collidesBlockUp (a,b,z) brds


collidesFigure::BlockedFigure -> Board -> Bool
collidesFigure (a,b,c,d) board = (collidesFigureSides (a,b,c,d) board) || (collidesFigureDown (a,b,c,d) board)

collidesFigureSmooth::BlockedFigure -> Board -> Bool
collidesFigureSmooth (a,b,c,d) board = (collidesFigureSidesSmooth (a,b,c,d) board) || (collidesFigureDownSmooth (a,b,c,d) board)

collidesFigureSides::BlockedFigure -> Board -> Bool
collidesFigureSides (a,b,c,d) board | (collidesBlockSides a board) || (collidesBlockSides b board) || (collidesBlockSides c board) || (collidesBlockSides d board) = True
        |otherwise = False

collidesFigureSidesSmooth::BlockedFigure -> Board -> Bool
collidesFigureSidesSmooth (a,b,c,d) board | (collidesBlockSidesSmooth a board) || (collidesBlockSidesSmooth b board) || (collidesBlockSidesSmooth c board) || (collidesBlockSidesSmooth d board) = True
        |otherwise = False        


collidesFigureDown::BlockedFigure -> Board -> Bool
collidesFigureDown (a,b,c,d) board | (collidesBlockDown a board) || (collidesBlockDown b board) || (collidesBlockDown c board) || (collidesBlockDown d board) = True
        |otherwise = False
collidesFigureDownSmooth::BlockedFigure -> Board -> Bool
collidesFigureDownSmooth (a,b,c,d) board | (collidesBlockDownSmooth a board) || (collidesBlockDownSmooth b board) || (collidesBlockDownSmooth c board) || (collidesBlockDownSmooth d board) = True
        |otherwise = False
isGameOver::Gamestate -> Bool
isGameOver (a,(f1:f2:rest),d,e,v,0,k) = collidesFigureDown (figureToDraw f2) a
isGameOver (a,(f1:f2:rest),d,e,v,1,k) = collidesFigureDownSmooth (figureToDraw f1) a




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
dropit (a,((Figure sha dir (b,c,z)):rest),d,e,v,0,k) pts  | collide = (a,((Figure sha dir (b,c,z)):rest),d,e+(div pts blockSize),v,0,k)                   
                                                  | otherwise = dropit (a,((Figure sha dir (b,c + blockSize,z)):rest),d,e,v,0,k) pts                                        
                                          where                                           
                                              collide = collidesFigureDown (figureToDraw (Figure sha dir (b,c + blockSize,z))) a
dropit (a,((Figure sha dir (b,c,z)):rest),d,e,v,1,k) pts  | collide = (a,((Figure sha dir (b,c,z)):rest),d,e+(div pts blockSize),v,1,k)                   
                                                  | otherwise = dropit (a,((Figure sha dir (b,c + 1,z)):rest),d,e,v,1,k) pts                                        
                                          where                                           
                                              collide = collidesFigureDown (figureToDraw (Figure sha dir (b,c + blockSize,z))) a                                              


drawBoard::Board  -> Picture
drawBoard s = pictures (map drawBlock s)
drawBoardCircle :: Board -> Picture
drawBoardCircle s = pictures (map drawBlockCircle s)
--(b==(324)||b==323||b == 322||b == 325||b == 326||b==321||b == 327||b==288||b==0  )
drawBlockCircle :: Coord-> Picture
drawBlockCircle  (b,c,1) |(b==0)=   pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (35 ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color blue  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 6) ) ,
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 1) ),
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 3) / 5 -2 ) (fromIntegral 1) )             -- белая рамка
   

   ]))
    ]
                    |(b==270) = 
   pictures[ color blue   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ),
   color magenta  (thickArc (fromIntegral (324  )) (fromIntegral (359  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 1) ),
  color magenta  (thickArc (fromIntegral (324  )) (fromIntegral (359  )) (fromIntegral (c + 3) / 5 -2 ) (fromIntegral 1) )  ]                 
                   |otherwise = pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (fromIntegral(-b) ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color blue   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ) ,            -- белая рамка
   color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ) ,
   color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) ) 

   ]))
    ]
  where
  w = fromIntegral 0
  h = fromIntegral 0
drawBlockCircle  (b,c,2) |(b==0)=   pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (35 ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color yellow  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 6) ) ,
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2  ) (fromIntegral 1) ),
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 3) / 5 -2 ) (fromIntegral 1) )            -- белая рамка
   

   ]))
    ]
                        |(b==270) = 
       pictures [color yellow   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ) ,
       color magenta   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ) ,
       color magenta   (thickArc (324) (359) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) ) 
         ]
                   |otherwise = pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (fromIntegral(-b) ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color yellow   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ) ,
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ),
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) )            -- белая рамка
   

   ]))
    ]
  where
  w = fromIntegral 0
  h = fromIntegral 0
drawBlockCircle  (b,c,3) |(b==0)=   pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (35 ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color red  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5  -2) (fromIntegral 6) ),
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 1) ) ,
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 3) / 5 -2 ) (fromIntegral 1) )              -- белая рамка
   

   ]))
    ]
                 |(b==270) = 
   pictures [ color red   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ) ,
   color magenta   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ) ,
   color magenta   (thickArc (324) (359) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) ) ]
                   |otherwise = pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (fromIntegral(-b) ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color red   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ) ,
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ) ,
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) )             -- белая рамка
   

   ]))
    ]
  where
  w = fromIntegral 0
  h = fromIntegral 0
drawBlockCircle  (b,c,4) |(b==0)=   pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (35 ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color green  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 6) ) ,
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 1) ),
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 3) / 5 -2 ) (fromIntegral 1) )            -- белая рамка
   

   ]))
    ]
                  |(b==270) = 
    pictures [color green   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ),
    color magenta   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ),
    color magenta   (thickArc (324) (359) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) ) ]
                   |otherwise = pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (fromIntegral(-b) ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color green   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ),
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ),
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) )             -- белая рамка
   

   ]))
    ]
  where
  w = fromIntegral 0
  h = fromIntegral 0
drawBlockCircle  (b,c,5) |(b==0)=   pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (35 ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color orange  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5  -2) (fromIntegral 6) ),
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5  -2) (fromIntegral 1) ),
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 3) / 5 -2 ) (fromIntegral 1) )             -- белая рамка
   

   ]))
    ]
                  |(b==270) = 
   pictures [ color orange   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ),
   color magenta   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ) ,
   color magenta   (thickArc (324) (359) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) )  ]
                   |otherwise = pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (fromIntegral(-b) ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color orange   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ),
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ),
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) )             -- белая рамка
   

   ]))
    ]
  where
  w = fromIntegral 0
  h = fromIntegral 0
drawBlockCircle  (b,c,_) |(b==0)=   pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (35 ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color white  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5 -2 ) (fromIntegral 6) ),
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 5) / 5  -2) (fromIntegral 1) ) ,
  color magenta  (thickArc (fromIntegral (0  )) (fromIntegral (36  )) (fromIntegral (c + 3) / 5-2  ) (fromIntegral 1) )              -- белая рамка
   

   ]))
    ]
                 |(b==270) = 
   pictures [ color white   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ),
   color magenta   (thickArc (324) (359) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ),
   color magenta   (thickArc (324) (359) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) ) ]
                   |otherwise = pictures [ translate (-w) h (scale  1.3 1.3 (pictures
 [ --color magenta (rotate (fromIntegral(-b) ) (thickArc (fromIntegral (0 )) (fromIntegral (36 )) (fromIntegral (c + 5) / 5 ) (fromIntegral 6) )),
  color white   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 6) ) ,
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 5) / 5  - 2) (fromIntegral 1) ),
  color magenta   (thickArc (((fromIntegral b)/30)*36) (((fromIntegral b)/30)*36 + 36) (fromIntegral (c + 3) / 5  - 2) (fromIntegral 1) )            -- белая рамка
   

   ]))
    ]
  where
  w = fromIntegral 0
  h = fromIntegral 0
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
drawFigure (b,(f:fs),s,t,v,p,k) = drawBlockedFigure  (figureToDraw f)



drawFigureCircle::Gamestate  ->  Picture
drawFigureCircle (b,(f:fs),s,t,v,p,k) = drawBlockedFigureCircle  (figureToDraw f)


drawBlockedFigureCircle :: BlockedFigure -> Picture
drawBlockedFigureCircle ((a, b, c, d)) =         pictures  [drawBlockCircle   a ,
                                                     drawBlockCircle    b ,
                                                     drawBlockCircle     c ,
                                                     drawBlockCircle     d ]
drawBlockedFigure::BlockedFigure -> Picture

 
drawBlockedFigure ((a, b, c, d)) =         pictures  [drawBlock   a ,
                                                     drawBlock    b ,
                                                     drawBlock     c ,
                                                     drawBlock     d ]

--Рисуем тетрис
--Пока только рисует квадрат


rect :: Point -> Point -> Picture
rect (l, b) (r, t) = polygon [ (l, b), (l, t), (r, t), (r, b) ]

-- | Прямоугольник с закруглёнными краями и границей заданной толщины.
roundedRect
  :: Color    -- ^ Цвет заливки.
  -> Color    -- ^ Цвет границы.
  -> Float    -- ^ Ширина прямоугольника.
  -> Float    -- ^ Высота прямоугольника.
  -> Float    -- ^ Радиус закругления.
  -> Float    -- ^ Толщина границы.
  -> Picture
roundedRect innerColor borderColor w h r d = pictures
  [ color innerColor inner
  , color borderColor border
  ]
  where
    border = pictures
      [ rect (-w/2 - d/2, -h/2 + r) (-w/2 + d/2, h/2 - r)
      , rect ( w/2 - d/2, -h/2 + r) ( w/2 + d/2, h/2 - r)
      , rect ( w/2 - r, -h/2 + d/2) (-w/2 + r, -h/2 - d/2)
      , rect ( w/2 - r,  h/2 + d/2) (-w/2 + r,  h/2 - d/2)
      , translate (-w/2 + r) ( h/2 - r) (rotate 270 cornerBorder)
      , translate (-w/2 + r) (-h/2 + r) (rotate 180 cornerBorder)
      , translate ( w/2 - r) (-h/2 + r) (rotate 90 cornerBorder)
      , translate ( w/2 - r) ( h/2 - r) cornerBorder
      ]

    inner = pictures
      [ rect (-w/2, -h/2 + r) (-w/2 + r,  h/2 - r)
      , rect ( w/2, -h/2 + r) ( w/2 - r,  h/2 - r)
      , rect (-w/2 + r, -h/2) ( w/2 - r, -h/2 + r)
      , rect (-w/2 + r,  h/2) ( w/2 - r,  h/2 - r)
      , rect (-w/2 + r, -h/2 + r) (w/2 - r, h/2 - r)
      , translate (-w/2 + r) ( h/2 - r) (rotate 270 corner)
      , translate (-w/2 + r) (-h/2 + r) (rotate 180 corner)
      , translate ( w/2 - r) (-h/2 + r) (rotate 90 corner)
      , translate ( w/2 - r) ( h/2 - r) corner
      ]

    corner = thickArc 0 90 (r/2) r
    cornerBorder = thickArc 0 90 r d



fieldHeight :: Float
fieldHeight = 40

fieldWidth :: Float
fieldWidth = 150


drawTetris ::Gamestate-> Picture
drawTetris (b,fs,s,t,tetristype,p,k) | tetristype==1 =  pictures
  [ drawFigureCircle (b,fs,s,t,tetristype,p,k),
   drawBoardCircle b ,
    drawScore t,
    (scale 1.3 1.3 (color cyan (circle  ( 115)))),
    translate (-0.3 * fieldWidth/2 + 113) (fieldHeight/2 + (fromIntegral screenHeight /2) - 53)
  (roundedRect (withAlpha 0.7 white) (greyN 0.7) ( fieldWidth/2 + 43) ((fromIntegral screenHeight / 10) + fieldHeight / 15) (0.1 * fieldWidth) (0.02 * fieldWidth)),
  drawmenuCircle,
  drawmenuSmooth,
  drawtextCircle,
  drawtextSmooth 
  
  
  ] 
    |otherwise = pictures
  [ drawFigure (b,fs,s,t,tetristype,p,k),
   drawBoard b ,
    drawScore t,
    translate (-0.3 * fieldWidth/2 + 113) (fieldHeight/2 + (fromIntegral screenHeight /2) - 53)
  (roundedRect (withAlpha 0.7 white) (greyN 0.7) ( fieldWidth/2 + 43) ((fromIntegral screenHeight / 10) + fieldHeight / 15) (0.1 * fieldWidth) (0.02 * fieldWidth)),
  drawmenuCircle,
  drawmenuSmooth,
  drawtextCircle,
  drawtextSmooth  
  
  
  ] 

drawmenuSmooth :: Picture
drawmenuSmooth = (color orange (polygon [ (101, 290), (101, 250), (148, 250), (148, 290) ]))

drawmenuCircle :: Picture
drawmenuCircle =  (color yellow (polygon [ (34, 290), (34, 250), (100, 250), (100, 290) ]))

drawtextSmooth :: Picture
drawtextSmooth = translate (-(fromIntegral screenWidth  / 2) + 225) (fromIntegral screenHeight / 2 -18) (scale 13 13 (pictures [translate (2) (-1.5) (scale 0.008 0.008 (color red (text  "Smooth")))]))

drawtextCircle :: Picture
drawtextCircle = translate (-(fromIntegral screenWidth  / 2) + 123) (fromIntegral screenHeight / 2 + 4) (scale 30 30 (pictures [translate (2) (-1.5) (scale 0.008 0.008 (color red (text  "Type")))]))

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
updateTetris dt (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k)|p==0 = updateTetrisStepped dt (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k)            
                                                                  |otherwise = updateTetrisSmooth dt (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k)


updateTetrisStepped :: Float -> Gamestate -> Gamestate
updateTetrisStepped dt (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k) | gameover = (genEmptyBoard,rest,(0.7, 0),0,v,p,0.7)
                                                              -- | collide =  (deleteRows (sortRows (updateBoard (Figure sha dir (b ,c,cl)) a)), rest, (sp, ti), e + 1)
                                                                            | otherwise = newLevel (newTact (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k) dt sp)
                                                                              where
                                                                   -- collide =  collidesFigureDown (figureToDraw (Figure sha dir (b ,c + blockSize,cl)))   a
                                                                              gameover = isGameOver (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k)
updateTetrisSmooth:: Float -> Gamestate -> Gamestate
updateTetrisSmooth dt (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k) | gameover = (genEmptyBoard,rest,(0.01, 0),0,v,p,0.01)
                                                              -- | collide =  (deleteRows (sortRows (updateBoard (Figure sha dir (b ,c,cl)) a)), rest, (sp, ti), e + 1)
                                                                            | otherwise = newLevel (newTact (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k) dt sp)
                                                                              where
                                                                   -- collide =  collidesFigureDown (figureToDraw (Figure sha dir (b ,c + blockSize,cl)))   a
                                                                              gameover = isGameOver (a,(Figure sha dir (b,c,cl):rest),(sp, ti),e,v,p,k)
-- ===========================================
-- timing
-- =======================================

newTact::Gamestate -> Float -> Float -> Gamestate
newTact (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti), s,v,0,k) dt tact
  | paused = (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti), s,v,0,k)
  | new && collides = (deleteRows (sortRows (updateBoard (Figure sha dir (f1,f2,f3)) b)), rest, (sp, ti), s + 1,v,0,k)
  | new = newTact (b, (Figure sha dir (f1,f2 + blockSize,f3):rest), (sp, 0), s,v,0,k) (dt + ti - tact) tact
  | collides = (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti + dt + tact * 0.3), s,v,0,k)
  | otherwise = (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti + dt), s,v,0,k)
                                        where
                                          new = ti + dt >= tact
                                          collides =  collidesFigureDown (figureToDraw (Figure sha dir (f1 ,f2 + blockSize,f3))) b
                                          paused = sp < 0
newTact (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti), s,v,1,k) dt tact
  | paused = (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti), s,v,1,k)
  | new && collides = (deleteRows (sortRows (updateBoard (Figure sha dir (f1,f2,f3)) b)), rest, (sp, ti), s + 1,v,1,k)
  | new = newTact (b, (Figure sha dir (f1,f2 + 1,f3):rest), (sp, 0), s,v,1,k) (dt + ti - tact) tact
  | collides = (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti + dt + tact * 0.3), s,v,1,k)
  | otherwise = (b, (Figure sha dir (f1,f2,f3):rest), (sp, ti + dt), s,v,1,k)
                                        where
                                          new = ti + dt >= tact
                                          collides =  collidesFigureDownSmooth (figureToDraw (Figure sha dir (f1 ,f2 + blockSize,f3))) b
                                          paused = sp < 0
newLevel::Gamestate -> Gamestate
newLevel (b, (Figure sha dir (f1,f2,f3)):rest, (sp, ti), s,v,p,k)
  | l5 = (b, (Figure sha dir (f1,f2,f3)):rest, (signum(sp) * 0.1, ti), s,v,p,k)
  | l4 = (b, (Figure sha dir (f1,f2,f3)):rest, (signum(sp) * 0.15, ti), s,v,p,k)
  | l3 = (b, (Figure sha dir (f1,f2,f3)):rest, (signum(sp) * 0.2, ti), s,v,p,k)
  | l2 = (b, (Figure sha dir (f1,f2,f3)):rest, (signum(sp) * 0.25, ti), s,v,p,k)
  | l2 = (b, (Figure sha dir (f1,f2,f3)):rest, (signum(sp) * 0.3, ti), s,v,p,k)
  | l1 = (b, (Figure sha dir (f1,f2,f3)):rest, (signum(sp) * 0.4, ti), s,v,p,k)
  | otherwise = (b, (Figure sha dir (f1,f2,f3)):rest, (sp, ti), s,v,p,k)
        where 
          l5 = s >= 5000
          l4 = s >= 3000 && s <= 5000
          l3 = s >= 2000 && s <= 3000
          l2 = s >= 1500 && s <= 2000
          l1 = s >= 1000 && s <= 1500

--Аргумент функции play, которая говорит, что длает каждая клавиша


handleTetris :: Event -> Gamestate -> Gamestate

handleTetris (EventKey (Char 'l') Down _ _) (a,(Figure sha dir (b,c,z):rest),d,e,v,p,k) = moveRight (a,(Figure sha dir (b,c,z):rest),d,e,v,p,k)
handleTetris (EventKey (Char 'l') Up _ _) t = t

handleTetris (EventKey (Char 'j') Down _ _)  (a,(Figure sha dir (b,c,z):rest),d,e,v,p,k)  = moveLeft (a,(Figure sha dir (b,c,z):rest),d,e,v,p,k)
handleTetris (EventKey (Char 'j') Up _ _)  t  = t

handleTetris(EventKey (SpecialKey KeySpace) Down _ _ ) (a,(Figure sha dir (b,c,z):rest),d,e,v,p,k)  = dropit (a,(Figure sha dir (b,c,z):rest),d,e,v,p,k) (screenHeight-c)
handleTetris(EventKey (SpecialKey KeySpace) Up _ _ ) t = t

handleTetris (EventKey (Char 'k') Down _ _ ) (a,(Figure sha dir (b,c,z):rest),d,e,v,p,k) = turn (a, (Figure sha dir (b ,c,z):rest),d,e,v,p,k)
handleTetris (EventKey (Char 'k') Up _ _ ) t = t

handleTetris (EventKey (Char 'p') Down _ _ ) (a,(Figure sha dir (b,c,z):rest),(sp, ti),e,v,p,k) = (a,(Figure sha dir (b,c,z):rest),(- sp, ti),e,v,p,k)
handleTetris (EventKey (Char 'p') Up _ _ ) t = t

handleTetris (EventKey (MouseButton LeftButton) Up _ mouse) (a,(Figure sha dir (b,c,z):rest),(sp, ti),e,v,p,k) =  (mouseToCell mouse  (a,(Figure sha dir (b,c,z):rest),(sp, ti),e,v,p,k) )
handleTetris  _ t = t  






mouseToCell :: Point->Gamestate -> Gamestate
mouseToCell (x, y) (a,(Figure sha dir (b,c,z):rest),(sp, ti),e,v,p,k)  | (x> 34 && x<100 && y > 250 && y < 290 && v==0) =  (a,(Figure sha dir (b,c,z):rest),(sp, ti),e,1,p,k)
                                                                       | (x> 34 && x<100 && y > 250 && y < 290 && v==1) =  (a,(Figure sha dir (b,c,z):rest),(sp, ti),e,0,p,k)
                                                                       | (x> 101 && x<148 && y > 250 && y < 290 && p==0) =  (genEmptyBoard,rest,(0.01, 0),0,v,1,0.01)
                                                                       | (x> 101 && x<148 && y > 250 && y < 290 && p==1) =  (genEmptyBoard,rest,(0.7, 0),0,v,0,0.7)
                                                           |otherwise =  (a,(Figure sha dir (b,c,z):rest),(sp, ti),e,v,p,k)
--(genEmptyBoard,rest,(k, 0),0,v,p,k)
--(color orange (polygon [ (101, 290), (101, 250), (148, 250), (148, 290) ]))
--(color yellow (polygon [ (34, 290), (34, 250), (100, 250), (100, 290) ]))
  --(Just (i, j))
  --where
   -- i = floor (x + fromIntegral screenWidth  / 2) `div` cellSize
    --j = floor (y + fromIntegral screenHeight / 2) `div` cellSize



type Node = (Int, Int)




-- | Поставить камень и сменить игрока (если возможно).
--placeStone :: Maybe Node -> Game -> Game
--placeStone Nothing game = game
--placeStone (Just point) game =
--    case gameWinner game of
--      Just _ -> game    -- если есть победитель, то поставить фишку нельзя
--      Nothing -> case modifyAt point (gameBoard game) (gamePlayer game) (listBoard game) of --здесь еще нужно дописать функцию преобразования
--        Nothing -> game -- если поставить фишку нельзя, ничего не изменится
--        Just newBoard -> completeMove (ruleKo (removeStones (changeBoard newBoard game)))
    