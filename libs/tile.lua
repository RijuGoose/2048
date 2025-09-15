
local Tile = {}
Tile.__index = Tile

function Tile:new(value)
    local obj = {
        number = value
    }
    setmetatable(obj, Tile)
    return obj
end

function Tile:setNumber(value)
    self.number = value
end

return Tile