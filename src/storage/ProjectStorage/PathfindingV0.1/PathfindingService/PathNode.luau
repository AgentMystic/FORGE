local static = {}

static.__index = static

function static:next()
    return self.Next
end

function public(vector,action,next,fcost)
    local dynamic = {}
    dynamic.Position = vector
    dynamic.Action = action
    dynamic.Next = next
    dynamic.FCost = fcost
    return setmetatable(dynamic,static)
end

return public