local ProximityPromptService = game:GetService("ProximityPromptService")
local service = {}
local main = {}
--marci.ano
local NodeHeapClass = require(game.ServerStorage.PathfindingService.NodeHeap)
local PathNodeClass = require(game.ServerStorage.PathfindingService.PathNode)
local PathClass = require(game.ServerStorage.PathfindingService.Path)

local init = false
local object = nil

local nodeDistance = 2
local epsilon = 1.1 --constant indicating the cost ratio of an air node, compared to a grounded node. (avoid bunny hops or jumping/falling when unnecessary)
--~at a large number it will be less likely to jump or anything, but it will have the drawback of it searching a larger amount before concluding a destination is reachable.

--IMPORTANT, POSSIBLY AIR NEIGHBORS MAY NEED DIFFERENT CHECKING!!!

local function setPart(pos, i)
	local p = Instance.new("Part")
	p.Position = pos
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1, 1, 1)
	p.Anchored = true
	p.CanQuery = false
	p.CanCollide = true
	p.Transparency = 0.5
	if i == 0 then
		p.Color = Color3.new(0.525490, 0.027450, 0.811764)
	else
		p.Color = Color3.new(0.105882, 0.027450, 0.811764)
		p.Transparency = 0
	end
	p.Parent = workspace.Testing
end

--somehow keeps track if a node can be reached through a jump still? I need jumpheight to create arcs? from pos to negative.
local function isViableAirNode(node, params)
	local previous = node.Previous

	local higher = previous.Position.Y < node.Position.Y
	local equalHeight = previous.Position.Y == node.Position.Y
	local lower = previous.Position.Y > node.Position.Y

	local heightLeft = previous.JumpHeightLeft
	local movement = previous.MovementLeft
	local state = previous.Action

	local sameXY = previous.Position.X == node.Position.X and previous.Position.Z == node.Position.Z

	node:setFCost(node.FCost * epsilon)
	if previous.Grounded then
		movement = params.Movement
		heightLeft = params.JumpHeightLeft
	end
	
	
	if lower then
		node:setFalling()
		node:setJumpHeightLeft(0)
		node:setMovementLeft(params.Movement)
	elseif higher then
		node:setJumping()
		if heightLeft > 0 then
			node:setJumpHeightLeft(heightLeft - 1)
			node:setMovementLeft(params.Movement)
		else
			return false
		end
	elseif equalHeight then --
		if state == "Jumping" then
			node:setJumping()
			node:setJumpHeightLeft(heightLeft)
		else
			node:setFalling()
			node:setJumpHeightLeft(0)
		end
	end

	if not sameXY then
		if movement <= 0 then
			return false
		else
			node:setMovementLeft(movement - 1)
		end
	end

	return true
end

local function canReachNode(node, params)
	local pos = node.Position
	local cf = CFrame.new(pos + Vector3.new(0, params.Height / 2, 0))
	local size = Vector3.new(params.Width, params.Height, params.Width)
	local overlapP = OverlapParams.new()
	overlapP.MaxParts = 1
	overlapP.FilterDescendantsInstances = {workspace.Testing}
	overlapP.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:GetPartBoundsInBox(cf, size, overlapP)
	if #result > 0 then
		return false
	end
	
	local raycastP =  RaycastParams.new()
	raycastP.FilterDescendantsInstances = {workspace.Testing}
	raycastP.FilterType = Enum.RaycastFilterType.Exclude
	
	local previousPos = node.Previous.Position
	result = workspace:Raycast(previousPos, node.Position - previousPos,raycastP)
	if result then
		
		return false
	end

	result = workspace:Raycast(pos, Vector3.new(0, -1 * nodeDistance, 0),raycastP)
	if result then
		node:setGrounded()
	else
		if not isViableAirNode(node, params) then
			return false
		end
	end

	return true
end

main.__index = main
function main:createPath(
	a: Vector3,
	b: Vector3,
	params: table
): Object --Unfortunately Roblox's own path class will always overwrite mine.
	local t0 = os.clock()
	local nodeHeap = NodeHeapClass()
	local nodeMap = {}
	if not params then
		params = {}
	end
	if params.Jump == nil then
		params.Jump = 10
	end
	params.JumpHeightLeft = math.floor(params.Jump / nodeDistance)
	if params.Height == nil then
		params.Height = 10
	end
	if params.Width == nil then
		params.Width = 5
	end
	if params.Speed == nil then --studs
		params.Speed = 4
	end
	params.Movement = params.Speed / nodeDistance --nodes

	local function getAllAdjacentNodes(node, origin: Vector3, destination: Vector3, params): table
		local adjacent = {}
		for i = -1, 1 do
			for j = -1, 1 do
				for k = -1, 1 do
					if i == 0 and j == 0 and k == 0 then
						continue
					end
					local neighbourPosition = node.Position
						+ Vector3.new(nodeDistance * i, nodeDistance * j, nodeDistance * k)
					local sPosition = tostring(neighbourPosition)
					if nodeMap[sPosition] then
						continue
					end
					local cost = (destination - neighbourPosition).magnitude + (origin - neighbourPosition).magnitude
					local neighbourNode = PathNodeClass(neighbourPosition, "Walk", node, cost)

					if not canReachNode(neighbourNode, params) then
						continue
					end

					nodeMap[sPosition] = true
					table.insert(adjacent, neighbourNode)
				end
			end
		end
		return adjacent
	end

	nodeMap[tostring(a)] = true

	local firstNode = PathNodeClass(a, "Start", nil, 0)
	local result = workspace:Raycast(a, Vector3.new(0, -1 * nodeDistance, 0))
	if result then
		firstNode:setGrounded()
	end

	local currentNode = firstNode

	local neededDistance = math.sqrt(nodeDistance)

	while true do
		setPart(currentNode.Position, 1)
		if currentNode == nil then
			break
		end

		if (currentNode.Position - b).magnitude <= neededDistance then
			break
		end

		for _, n in getAllAdjacentNodes(currentNode, a, b, params) do
			setPart(n.Position, 0)
			nodeHeap:push(n)
		end
		currentNode = nodeHeap:pop()
	end

	if currentNode == nil then
		return nil
	end

	local pathway = {}
	repeat
		table.insert(pathway, currentNode)
		currentNode = currentNode.Previous
	until currentNode == nil

	local newPathway = {}
	for i = #pathway, 1, -1 do
		table.insert(newPathway, pathway[i])
	end

	local path = PathClass(newPathway)

	local t1 = os.clock()
	print(string.format("Time taken to construct path of length %i nodes is %f seconds.", #path, t1 - t0))

	return path
end

local function createService()
	init = true
	return setmetatable({}, main)
end

function service:init()
	if init then
		return object
	end
	object = createService()
	return object
end

return service
