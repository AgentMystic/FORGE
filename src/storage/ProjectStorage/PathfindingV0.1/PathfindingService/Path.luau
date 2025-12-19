local static = {}

static.__index = static

function static:length()
    return #self.Nodes
end

function public(list)
    local dynamic = {}
    dynamic.Nodes = list
    dynamic.Start = list[1]
    dynamic.End = list[-1]
    return setmetatable(dynamic,static)
end

return public