local BoardHandler = {
    size = nil,
    board = {},
    uiBoard = {}
}

local Square = require("libs.square")

BoardHandler.ACTION_TILE_MERGED = "merged"
BoardHandler.ACTION_TILE_MOVED = "moved"
BoardHandler.ACTION_TILE_NOT_MOVED = "not_moved"

BoardHandler.DIRECTION_MOVE_UP = "move_up"
BoardHandler.DIRECTION_MOVE_DOWN = "move_down"
BoardHandler.DIRECTION_MOVE_LEFT = "move_left"
BoardHandler.DIRECTION_MOVE_RIGHT = "move_right"

local Tile = require("libs.tile")
local createMatrix
local handleNeighborTiles
local addRandomNumber
local logCurrentState

function BoardHandler.newBoard(size)
    BoardHandler.size = size
    for i = 1, size do
        BoardHandler.board[i] = {}
        BoardHandler.uiBoard[i] = {}
        for j = 1, size do
            BoardHandler.board[i][j] = Tile:new(nil)
        end
    end
end

local function isBoardFull()
    for i = 1, BoardHandler.size do
        for j = 1, BoardHandler.size do
            if (BoardHandler.board[i][j].number == nil) then
                return false
            end
        end
    end
    return true
end

function BoardHandler.addRandomNumber()
    local startRow
    local startCol

    if (isBoardFull() == false) then
        repeat
            startRow = math.random(1, BoardHandler.size)
            startCol = math.random(1, BoardHandler.size)
        until BoardHandler.board[startRow][startCol].number == nil

        local sq = Square.create(startCol, startRow, 2)
        BoardHandler.uiBoard[startRow][startCol] = sq
        BoardHandler.board[startRow][startCol]:setNumber(2)

        return sq
    end
end

function BoardHandler.moveTiles(direction)
    local mergeTable = createMatrix(BoardHandler.size)
    local tileMovesTable = createMatrix(BoardHandler.size)

    local moveHappened = false

    local rowStart, rowEnd, rowStep
    local colStart, colEnd, colStep
    local slidingStart, slidingStep, slidingWindowIsInBoard
    local moveTableRowOffset, moveTableColOffset

    if direction == BoardHandler.DIRECTION_MOVE_DOWN then
        rowStart, rowEnd, rowStep = BoardHandler.size, 1, -1
        colStart, colEnd, colStep = 1, BoardHandler.size, 1
        slidingStart = function(row, col)
            return row
        end
        slidingStep = 1
        slidingWindowIsInBoard = function(pos)
            return pos <= BoardHandler.size
        end
        moveTableRowOffset, moveTableColOffset = -1, 0

    elseif direction == BoardHandler.DIRECTION_MOVE_UP then
        rowStart, rowEnd, rowStep = 1, BoardHandler.size, 1
        colStart, colEnd, colStep = 1, BoardHandler.size, 1
        slidingStart = function(row, col)
            return row
        end
        slidingStep = -1
        slidingWindowIsInBoard = function(pos)
            return pos >= 1
        end
        moveTableRowOffset, moveTableColOffset = 1, 0

    elseif direction == BoardHandler.DIRECTION_MOVE_RIGHT then
        rowStart, rowEnd, rowStep = 1, BoardHandler.size, 1
        colStart, colEnd, colStep = BoardHandler.size, 1, -1
        slidingStart = function(row, col)
            return col
        end
        slidingStep = 1
        slidingWindowIsInBoard = function(pos)
            return pos <= BoardHandler.size
        end
        moveTableRowOffset, moveTableColOffset = 0, -1

    elseif direction == BoardHandler.DIRECTION_MOVE_LEFT then
        rowStart, rowEnd, rowStep = 1, BoardHandler.size, 1
        colStart, colEnd, colStep = 1, BoardHandler.size, 1
        slidingStart = function(row, col)
            return col
        end
        slidingStep = -1
        slidingWindowIsInBoard = function(pos)
            return pos >= 1
        end
        moveTableRowOffset, moveTableColOffset = 0, 1
    end

    for row = rowStart, rowEnd, rowStep do
        for col = colStart, colEnd, colStep do
            local slidingPos = slidingStart(row, col)

            while slidingWindowIsInBoard(slidingPos) do

                local currentRow, currentCol
                if direction == BoardHandler.DIRECTION_MOVE_DOWN or direction == BoardHandler.DIRECTION_MOVE_UP then
                    currentRow = slidingPos
                    currentCol = col
                else
                    currentRow = row
                    currentCol = slidingPos
                end

                if mergeTable[currentRow][currentCol] == true then
                    break
                end

                local action = handleNeighborTiles(currentRow, currentCol, direction)

                if action.action == BoardHandler.ACTION_TILE_MERGED then
                    mergeTable[currentRow][currentCol] = true
                    local moveTableRow = row + moveTableRowOffset
                    local moveTableCol = col + moveTableColOffset
                    tileMovesTable[moveTableRow][moveTableCol] = {
                        action = action.action,
                        toRow = action.toRow,
                        toCol = action.toCol
                    }
                    moveHappened = true
                    break
                elseif action.action == BoardHandler.ACTION_TILE_MOVED then
                    local moveTableRow = row + moveTableRowOffset
                    local moveTableCol = col + moveTableColOffset
                    tileMovesTable[moveTableRow][moveTableCol] = {
                        action = action.action,
                        toRow = action.toRow,
                        toCol = action.toCol
                    }
                    moveHappened = true
                end

                slidingPos = slidingPos + slidingStep
            end
        end
    end

    if(moveHappened == true) then
        return tileMovesTable
    else
        return nil
    end
end

handleNeighborTiles = function(baseTileRow, baseTileCol, direction)
    local baseTileNumber = BoardHandler.board[baseTileRow][baseTileCol].number

    local neighborRow, neighborCol
    local tileIsInsideBoard

    if direction == BoardHandler.DIRECTION_MOVE_LEFT then
        neighborRow = baseTileRow
        neighborCol = baseTileCol + 1
        tileIsInsideBoard = baseTileCol + 1 <= BoardHandler.size
    elseif direction == BoardHandler.DIRECTION_MOVE_RIGHT then
        neighborRow = baseTileRow
        neighborCol = baseTileCol - 1
        tileIsInsideBoard = baseTileCol - 1 >= 1
    elseif direction == BoardHandler.DIRECTION_MOVE_UP then
        neighborRow = baseTileRow + 1
        neighborCol = baseTileCol
        tileIsInsideBoard = baseTileRow + 1 <= BoardHandler.size
    elseif direction == BoardHandler.DIRECTION_MOVE_DOWN then
        neighborRow = baseTileRow - 1
        neighborCol = baseTileCol
        tileIsInsideBoard = baseTileRow - 1 >= 1
    end

    if not tileIsInsideBoard then
        return {
            action = BoardHandler.ACTION_TILE_NOT_MOVED
        }
    end

    local neighborNumber = BoardHandler.board[neighborRow][neighborCol].number

    if baseTileNumber ~= nil then
        if baseTileNumber == neighborNumber then
            -- BoardHandler.board[baseTileRow][baseTileCol]:setNumber(baseTileNumber * 2)
            BoardHandler.board[baseTileRow][baseTileCol]:setNumber(baseTileNumber + 1)
            BoardHandler.board[neighborRow][neighborCol]:setNumber(nil)
            return {
                action = BoardHandler.ACTION_TILE_MERGED,
                toRow = baseTileRow,
                toCol = baseTileCol
            }
        end
    else
        if neighborNumber ~= nil then
            BoardHandler.board[baseTileRow][baseTileCol]:setNumber(neighborNumber)
            BoardHandler.board[neighborRow][neighborCol]:setNumber(nil)
            return {
                action = BoardHandler.ACTION_TILE_MOVED,
                toRow = baseTileRow,
                toCol = baseTileCol
            }
        end
    end
    return {
        action = BoardHandler.ACTION_TILE_NOT_MOVED
    }
end

createMatrix = function(n)
    local matrix = {}
    for i = 1, n do
        matrix[i] = {}
    end
    return matrix
end

return BoardHandler
