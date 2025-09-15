local composer = require("composer")

local scene = composer.newScene()

local const = require("libs.const")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local screenWidth = const.screenW
local boardSize = 4
local slice = screenWidth / boardSize

local Tile = require("libs.tile")
local Square = require("libs.square")
local BoardHandler = require("libs.boardhandler")

local isMoving = false

local function updateBoard(movedTiles, direction, afterUpdate)
    if (movedTiles ~= nil) then
        isMoving = true
        local totalMoveCount = 0
        local completedMoveCount = 0

        for row = 1, BoardHandler.size do
            for col = 1, BoardHandler.size do
                local moved = movedTiles[row][col]
                if (moved ~= nil) then
                    totalMoveCount = totalMoveCount + 1
                end
            end
        end

        local rowStart, rowEnd, rowStep
        local colStart, colEnd, colStep

        if direction == BoardHandler.DIRECTION_MOVE_DOWN then
            rowStart, rowEnd, rowStep = BoardHandler.size, 1, -1
            colStart, colEnd, colStep = 1, BoardHandler.size, 1

        elseif direction == BoardHandler.DIRECTION_MOVE_UP then
            rowStart, rowEnd, rowStep = 1, BoardHandler.size, 1
            colStart, colEnd, colStep = 1, BoardHandler.size, 1

        elseif direction == BoardHandler.DIRECTION_MOVE_RIGHT then
            rowStart, rowEnd, rowStep = 1, BoardHandler.size, 1
            colStart, colEnd, colStep = BoardHandler.size, 1, -1

        elseif direction == BoardHandler.DIRECTION_MOVE_LEFT then
            rowStart, rowEnd, rowStep = 1, BoardHandler.size, 1
            colStart, colEnd, colStep = 1, BoardHandler.size, 1
        end

        for row = rowStart, rowEnd, rowStep do
            for col = colStart, colEnd, colStep do
                local moved = movedTiles[row][col]
                if (moved ~= nil) then
                    local onCompleteListener = function()

                        if (moved.action == BoardHandler.ACTION_TILE_MOVED) then
                            BoardHandler.uiBoard[row][col]:removeSelf()
                            BoardHandler.uiBoard[moved.toRow][moved.toCol] =
                                Square.create(moved.toCol, moved.toRow,
                                    BoardHandler.board[moved.toRow][moved.toCol].number)
                            scene.stage:insert(BoardHandler.uiBoard[moved.toRow][moved.toCol])
                        elseif (moved.action == BoardHandler.ACTION_TILE_MERGED) then
                            BoardHandler.uiBoard[row][col]:removeSelf()
                            BoardHandler.uiBoard[moved.toRow][moved.toCol]:removeSelf()
                            BoardHandler.uiBoard[moved.toRow][moved.toCol] =
                                Square.create(moved.toCol, moved.toRow,
                                    BoardHandler.board[moved.toRow][moved.toCol].number)
                            scene.stage:insert(BoardHandler.uiBoard[moved.toRow][moved.toCol])

                        end

                        completedMoveCount = completedMoveCount + 1

                        if (totalMoveCount == completedMoveCount) then
                            afterUpdate()
                        end
                    end

                    BoardHandler.uiBoard[row][col]:move(moved.toCol, moved.toRow, {}, onCompleteListener)
                end
            end
        end
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    BoardHandler.newBoard(boardSize)
    local newNumber = BoardHandler.addRandomNumber()

    local boardBase = display.newGroup()
    boardBase.anchorChildren = true
    boardBase.x = const.halfW
    boardBase.y = const.halfH

    scene.stage = boardBase
    sceneGroup:insert(boardBase)

    local bg = display.newRect(boardBase, 0, 0, screenWidth, screenWidth)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0.1, 0.3, 0.5)

    boardBase.bg = bg

    for i = 0, BoardHandler.size do
        local line = display.newLine(boardBase, i * slice, 0, i * slice, screenWidth)
        line.strokewWidth = 2
        local line2 = display.newLine(boardBase, 0, i * slice, screenWidth, i * slice)
        line2.strokewWidth = 2
    end

    scene.stage:insert(newNumber)
end

-- show()
function scene:show(event)

    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen
        local object = scene.stage.bg

        function object:touch(event)
            if (isMoving == true) then
                return false
            end
            if (event.phase == "began") then

                -- Set touch focus
                display.getCurrentStage():setFocus(self)
                self.isFocus = true

            elseif (self.isFocus) then
                if (event.phase == "moved") then
                    local xDiff = event.x - event.xStart
                    local yDiff = event.y - event.yStart

                    local movedTiles
                    local direction
                    local afterUpdate = function()
                        local newNumber = BoardHandler.addRandomNumber()
                        scene.stage:insert(newNumber)
                        isMoving = false
                    end
                    if (math.abs(xDiff) > 100) then
                        self.isFocus = nil
                        if (xDiff > 0) then
                            direction = BoardHandler.DIRECTION_MOVE_RIGHT
                        else
                            direction = BoardHandler.DIRECTION_MOVE_LEFT
                        end
                        movedTiles = BoardHandler.moveTiles(direction)

                        updateBoard(movedTiles, direction, afterUpdate)
                    end

                    if (math.abs(yDiff) > 100) then
                        self.isFocus = nil
                        if (yDiff > 0) then
                            direction = BoardHandler.DIRECTION_MOVE_DOWN
                        else
                            direction = BoardHandler.DIRECTION_MOVE_UP
                        end
                        movedTiles = BoardHandler.moveTiles(direction)

                        updateBoard(movedTiles, direction, afterUpdate)
                    end

                elseif (event.phase == "ended" or event.phase == "cancelled") then

                    -- Reset touch focus
                    display.getCurrentStage():setFocus(nil)
                    self.isFocus = nil
                end
            end
            return true
        end

        object:addEventListener("touch", object)

    end
end

-- hide()
function scene:hide(event)

    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is on screen (but is about to go off screen)

    elseif (phase == "did") then
        -- Code here runs immediately after the scene goes entirely off screen

    end
end

-- destroy()
function scene:destroy(event)

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)
-- -----------------------------------------------------------------------------------

return scene
