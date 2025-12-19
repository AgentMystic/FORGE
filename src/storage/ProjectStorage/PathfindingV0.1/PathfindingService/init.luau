local service = {}
local main = {}

local init = false
local object = nil

local path

--Inserts an array of values b into array a, keeping the cost order of array a.
local function InsertOnCost(a,b) --binarysearching? 
    for _,element in b do
        
    end


end

main.__index = main
function main:createPath(self,a : Vector3, b : Vector3) : Object --Unfortunately Roblox's own path class will always overwrite mine.
    local diagCost = math.sqrt(2)
    
    local searching = true

    local possible = {} --keep sorted on costs.

    while searching do
        
    end


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