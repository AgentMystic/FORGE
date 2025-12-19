--y not
local static = {}
static.__index = static

--Pops the top node in the heap (the lowest FCost node). Log(n)
function static:pop()

    if #self.raw == 0 then return nil end

    local lowest = self.raw[1]
    local length = #self.raw
    local last = self.raw[length]
    
    self.raw[length] = nil
    self.raw[1] = last

    local i = 1
     while true do
        local left = i * 2
        local right = left + 1
        local smallest = i

        if left <= #self.raw and self.raw[left].FCost < self.raw[smallest].FCost then
            smallest = left
        end

        if right <= #self.raw and self.raw[right].FCost < self.raw[smallest].FCost then
            smallest = right
        end

        if smallest == i then
            break
        end

        -- Swap
        self.raw[i], self.raw[smallest] = self.raw[smallest], self.raw[i]
        i = smallest
    end

    return lowest 
end

--Inserts a node into the heap. Log(n)
function static:push(pathNode)

    table.insert(self.raw,pathNode)
    local i = #self.raw
    
    while i>1 do 
        local parent = math.floor(i/2)
        if self.raw[i].FCost >= self.raw[parent].FCost then 
            break
        end
        self.raw[i],self.raw[parent] = self.raw[parent],self.raw[i]
        i = parent
    end

end

--Returns the top node in the heap, but does not remove it from the heap. 1 (array single access time)
function static:peek()
    if #self.raw == 0 then return nil end
    return self.raw[1]
end


local function new()
    local newHeap = {}
    newHeap.raw = {}
    return setmetatable(newHeap,static)
end

return new