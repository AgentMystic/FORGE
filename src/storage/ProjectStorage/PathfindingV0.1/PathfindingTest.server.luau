local PathfindingModule = require(game.ServerStorage.PathfindingService)

PathfindingModule:init()


local pos1 = Vector3.new(-12,0,13)

local pos2 = Vector3.new(20,0,1)

local path = PathfindingModule:CreatePath(pos1,pos2)
for _,node in path.Nodes do 
    local p = Instance.new("Part")
    p.Postion = node.Position
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(1,1,1)
    p.Anchored = true
    p.Transparency = 0.5
    p.Color = Color3.new(0.847058, 0.294117, 0.294117)
end