local service = {}
local main = {}

local init = false
local object = nil

local path


main.__index = main
function main:createPath(self,a : IntValue, b : IntValue) : Object --Unfortunately Roblox's own path class will always overwrite mine.
    




end


local function createService()
    init = true 
    return setmetatable({},main)
end

function service:init()
    if init then
       return object
    end
    object = createService()
    return object   
end

return service