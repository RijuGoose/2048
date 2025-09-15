local Square = {}

local time = 250
local _easing = easing.linear

local const = require("libs.const")
local screenWidth = const.screenW
local boardSize = 4
local slice = screenWidth / boardSize

function Square.create(col, row, number)
    col = col - 1
    row = row - 1

    local sq = display.newGroup()
    sq.anchorChildren = true
    local rect = display.newRect(sq, 0, 0, slice, slice)
    rect:setFillColor(0.1, 0.1 * number, 0.3)
    local text = display.newText({
                parent = sq,
         x = 0,
         y = 0,
         width = rect.width,
         align = "center",
         text = string.rep("🐌", number)
     })

    sq.anchorX = 0
    sq.anchorY = 0

    sq.x = col * slice
    sq.y = row * slice

    sq.col = col
    sq.row = row

    function sq:move(_col, _row, onStartListener, onCompleteListener)
        _col = _col - 1
        _row = _row - 1

        if (self.col ~= _col or self.row ~= _row) then
            transition.to(self, {
                time = time,
                transition = _easing,
                x = _col * slice,
                y = _row * slice,
                onComplete = onCompleteListener,
                onStart = onStartListener
            })
            self.col = _col
            self.row = _row
        end
    end
    return sq
end

return Square
