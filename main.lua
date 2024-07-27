-- Oleg Kotov

local cellSize -- px
local boardSize = 3
local board = {}

local cellCount = boardSize * boardSize
local moveCount = 0

local cellSprite
local crossSprite
local circleSprite

local figures = { "X", "O" }
local isFirstPlayerMove = true

local gameState = ""

local botThinkTime = 0
local botThinkDuration = 1
local botIsThinking = false

math.randomseed( os.time() )

local player1FigureIndex = math.random( #figures )
local player1 = {
    figure = figures[player1FigureIndex],
    isBot = false
}

table.remove( figures, player1FigureIndex )

local player2 = {
    figure = figures[math.random( #figures )],
    isBot = true
}

local players = { player1, player2 }

-------------------------------------------------------------------

function loadImages()
    cellSprite = love.graphics.newImage( "images/tile_back.png" )
    crossSprite = love.graphics.newImage( "images/tile_red.png" )
    circleSprite = love.graphics.newImage( "images/tile_green.png" )
end

function reset()
    moveCount = 0
    isFirstPlayerMove = true
    gameState = ""
    botThinkTime = 0
    botThinkDuration = 1
    botIsThinking = false
end

function initBoard()
    for i = 1, boardSize do
        board[i] = {}
        for j = 1, boardSize do
            board[i][j] = ""
        end
    end

    -- board = {
    --     { "X", "O", ""  },
    --     { "O", "X", "X" },
    --     { "",  "",  "O" }
    -- }
end

-------------------------------------------------------------------

function checkWin( figure )
    
    -- check rows and columns

    for row = 1, boardSize do
        local rowWin = true
        local colWin = true

        for col = 1, boardSize do
            if board[row][col] ~= figure then
                rowWin = false
            end
            if board[col][row] ~= figure then
                colWin = false
            end
        end

        if rowWin or colWin then
            return true
        end
    end

    -- check diagonals

    local diagWin1 = true
    local diagWin2 = true

    for i = 1, boardSize do
        if board[i][i] ~= figure then
            diagWin1 = false
        end
        if board[i][boardSize - i + 1] ~= figure then
            diagWin2 = false
        end
    end

    if diagWin1 or diagWin2 then
        return true
    end

    return false
end

function checkDraw()
    return isBoardFullFast()
end

function isBoardFull()
    for i = 1, boardSize do
        for j = 1, boardSize do
            if board[i][j] == "" then
                return false
            end
        end
    end
    return true
end

function isBoardFullFast()
    if moveCount == cellCount then
        return true
    end
    return false
end

-------------------------------------------------------------------

function makeMove( row, col )

    -- select needed figure
    if isFirstPlayerMove then
        board[row][col] = players[1].figure
    else
        board[row][col] = players[2].figure
    end

    moveCount = moveCount + 1

    if checkWin( board[row][col] ) then
        gameState = "win"
        return
    end

    if checkDraw() then
        gameState = "draw"
        return
    end

    isFirstPlayerMove = not isFirstPlayerMove

    if isFirstPlayerMove and player1.isBot then
        botIsThinking = true
    end

    if not isFirstPlayerMove and player2.isBot then
        botIsThinking = true
    end
end

function botMove()

    -- game over
    if gameState == "win" or gameState == "draw" then
        return
    end

    local emptyCells = {}

    for row = 1, boardSize do
        for col = 1, boardSize do
            if board[row][col] == "" then
                table.insert( emptyCells, {row = row, col = col} )
            end
        end
    end

    local randomIndex = math.random( #emptyCells )
    local randomCell = emptyCells[randomIndex]

    makeMove( randomCell.row, randomCell.col )
end

-- player move
function love.mousepressed( x, y, button )

    -- if game is over, ignore clicks
    if gameState == "win" or gameState == "draw" then
        return
    end

    -- ignore clicks if it's not player's turn

    if isFirstPlayerMove and player1.isBot then
        return
    end

    if not isFirstPlayerMove and player2.isBot then
        return
    end

    -- if not left mouse button, ignore clicks
    if button ~= 1 then return end

    local row = math.floor( y / cellSize ) + 1
    local col = math.floor( x / cellSize ) + 1

    local isClickedInBoard = row >= 1 and row <= boardSize and col >= 1 and col <= boardSize
    local isEmptyCell = board[row][col] == ""

    if isClickedInBoard and isEmptyCell then
        makeMove( row, col )
    end
end

-------------------------------------------------------------------

function drawCell( cellSprite, row, col )
    local drawX = ( col - 1 ) * cellSize
    local drawY = ( row - 1 ) * cellSize
    love.graphics.draw( cellSprite, drawX, drawY )
end

function drawCells()
    for row = 1, boardSize do
        for col = 1, boardSize do
            drawCell( cellSprite, row, col )
        end
    end
end

function drawTileCentered( tileSprite, row, col )
    local tileWidth, tileHeight = tileSprite:getDimensions()
    local drawX = ( col - 1 ) * cellSize + ( cellSize - tileWidth ) * 0.5
    local drawY = ( row - 1 ) * cellSize + ( cellSize - tileHeight ) * 0.5
    love.graphics.draw( tileSprite, drawX, drawY )
end

function drawTiles()
    for row = 1, boardSize do
        for col = 1, boardSize do
            if board[row][col] == "X" then
                drawTileCentered( crossSprite, row, col )
            elseif board[row][col] == "O" then
                drawTileCentered( circleSprite, row, col )
            end
        end
    end
end

function drawText( x, y )

    local isWinOrDraw = gameState == "win" or gameState == "draw"

    local player1Arrow = ( isWinOrDraw or not isFirstPlayerMove ) and "" or "> "
    local player1Figure = players[1].figure == "X" and "Red" or "Green"
    local player1IsBot = players[1].isBot and " - BOT" or ""

    local player2Arrow = ( isWinOrDraw or isFirstPlayerMove ) and "" or "> "
    local player2Figure = players[2].figure == "X" and "Red" or "Green"
    local player2IsBot = players[2].isBot and " - BOT" or ""
    
    local winOrDrawText = ""

    if gameState == "win" then
        winOrDrawText = "Player " .. ( isFirstPlayerMove and 1 or 2 ) .. " wins!"
    elseif gameState == "draw" then
        winOrDrawText = "It's a draw!"
    end

    local player1Text = player1Arrow .. "Player 1 (" .. player1Figure .. ")" .. player1IsBot
    local player2Text = player2Arrow .. "Player 2 (" .. player2Figure .. ")" .. player2IsBot

    local finalText = player1Text .. "\n" .. player2Text .. "\n\n" .. winOrDrawText

    love.graphics.print( finalText, x, y )
end

-------------------------------------------------------------------

function love.load()

    loadImages()

    cellSize = cellSprite:getWidth()

    local screenHeight = cellSize * boardSize
    local screenWidth = screenHeight + 20 + 250

    love.window.setMode( screenWidth, screenHeight )
    love.window.setTitle( "Tic-Tac-Toe" )

    initBoard()

    if player1.isBot then
        botIsThinking = true
    end
end

function love.update( dt )
    if botIsThinking then
        botThinkTime = botThinkTime + dt
        if botThinkTime >= botThinkDuration then
            botThinkTime = 0
            botIsThinking = false
            botMove()
        end
    end
end

function love.draw()

    -- background color
    love.graphics.clear( 63/255, 124/255, 182/255 )
    
    drawCells()
    drawTiles()
    drawText( boardSize * cellSize + 20, 20 )
end

function love.keypressed( key )
    
    if key == "r" then
        reset()
        initBoard()

        if player1.isBot then
            botIsThinking = true
        end
    end
end

