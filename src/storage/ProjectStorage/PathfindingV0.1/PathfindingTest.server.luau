local PathfindingModule = require(game.ServerStorage.PathfindingService)
local NodeHeapClass = require(game.ServerStorage.PathfindingService.NodeHeap)
local PathNodeClass = require(game.ServerStorage.PathfindingService.PathNode)

local heap = NodeHeapClass()
local l = {}
l[1] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 1)
l[2] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 23)
l[3] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 4)
l[4] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 7)
l[5] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 8)
l[6] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 6)
l[7] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 2)
l[8] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 1)
l[9] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 4)
l[10] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 2)
l[11] = PathNodeClass(Vector3.new(0, 0, 0), "End", nil, 5)

for _, n in l do
	heap:push(n)
end
print(heap.raw)
print(heap:pop())
print(heap:pop())
heap:pop()
print(heap.raw)


task.wait(1)

local function makepath(p)
	for _, node in p.Nodes do
		local p = Instance.new("Part")
		p.Position = node.Position
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(1, 1, 1)
		p.Anchored = true
		p.Transparency = 0.5
		p.Color = Color3.new(0.847058, 0.294117, 0.294117)
		p.Parent = workspace.Testing
	end
end

local pathfindingService = PathfindingModule:init()

local pos1 = Vector3.new(-104, 1, 43)
local pos2 = Vector3.new(-37.5, 1, 42)
local pos2_5 = Vector3.new(-58, 54.499, 44)


-- local path = pathfindingService:createPath(pos1, pos2) or {}
-- makepath(path)

local pos3 = Vector3.new(-31.5, 6.5, 57)
path = pathfindingService:createPath(pos3,pos2)
makepath(path)

path = pathfindingService:createPath(pos2_5,pos2)
makepath(path)

local pos4 = Vector3.new(-5.5, 10, 15)
path = pathfindingService:createPath(pos1,pos4)
makepath(path)

local pos6 = Vector3.new(23, 54, 41)
local pos5 = Vector3.new(21.5, 0.5, 10.5)
path = pathfindingService:createPath(pos5,pos6)
makepath(path)