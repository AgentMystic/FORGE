--by mys.tic
print("Tile Generation Started!!!!!")
task.wait(1)
local folder = Instance.new("Folder")
folder.Name = "ChunkGeneration"
folder.Parent = workspace

--may god be with me.

--Configurable parameters
local loadedChunkRange = 1 --
local seed = 1
local chunkSize = 8 --16x16 10x10 tiles
--Also configurable as long as the corresponding tile rooms are updated.
local tileSize = 10 --studs

--fetch services
local players = game:GetService("Players")

--variables
local chunkMap = {}
local loadedChunks = {}

local lastChunk = { nil, nil }
local player = players.LocalPlayer

--chunkTypes
local defaultTiles = {

	["Hallway"] = {
		type = "Hallway",
		rotations = 0,
		eldest = true, --for 1x1 rooms there are no other tiles so this is the only tile that operations need to be performed on.
	},

	["SingleOffice"] = {
		type = "SingleOffice",
		rotations = 0,
		eldest = true, --1x1 room so no other tiles that could be flagged. Only eldest will be used to construct the room.
		hasDoor = false,
	},

	--If eldest is false by default we check the room shape is possible, and if so change eldest to true and reserve the other chunk(s) with eldest false.
	["InterviewRoom"] = {
		type = "InterviewRoom",
		rotations = 0,
		eldest = false, --a 2x1 room, the eldest is the first tile, the other is generated based on the first.
		shape = { { 1, 0 } }, --list of all relative chunks which form this room, so which adjacent(or nearby) chunks need to be checked and reserved to form this room.
		hasDoor = false,
	},

	["Cafeteria"] = {
		type = "Cafeteria",
		rotations = 0,
		eldest = false,
		shape = { { 1, 0 }, { 0, 1 }, { 1, 1 } },
		hasDoor = false,
	},

	["Corner"] = {
		type = "Cafeteria",
		rotations = 0,
		eldest = false,
		shape = { { 1, 0 }, { 0, 1 } },
		hasDoor = false,
	},
}

--procedural infinity

local function getKey(x, y): string
	return tostring(x) .. "," .. tostring(y)
end

local function getChunkSeed(x, y)
	local combinedSeed = seed
		+ x * 73856093 -- large primes avoid collisions
		+ y * 19349663
	return combinedSeed
end

local function getSpaceAdjacent(x, y)
	local adjacent = {}
	if x + 1 <= chunkSize then
		local neighbour = { x + 1, y, 1 } -- right
		table.insert(adjacent, neighbour)
	end
	if x - 1 >= 1 then
		local neighbour = { x - 1, y, 3 } -- left
		table.insert(adjacent, neighbour)
	end
	if y - 1 >= 1 then
		local neighbour = { x, y - 1, 2 } -- back 2*90
		table.insert(adjacent, neighbour)
	end
	if y + 1 <= chunkSize then
		local neighbour = { x, y + 1, 0 } --front
		table.insert(adjacent, neighbour)
	end
	return adjacent -- list of {x,y, and  a number representing the orientation}
end

local function getNorthWestAdjacent(x, y)
	local adjacent = {}
	if x - 1 >= 1 then
		adjacent["West"] = { x - 1, y } -- left
	end
	if y + 1 <= chunkSize then
		adjacent["North"] = { x, y + 1 } --front
	end
	if y - 1 >= 1 then
		adjacent["South"] = { x, y - 1 }
	end
	if x + 1 <= chunkSize then
		adjacent["East"] = { x + 1, y }
	end
	return adjacent -- list of {x,y, and  a number representing the orientation}
end

--Find a chunk in the given table containing chunks.
local function findPositionTable(a: table, positionTable: table)
	for indx, element in a do
		if element[1] == positionTable[1] and element[2] == positionTable[2] then
			return indx
		end
		task.wait() --temporary cause execution time is being exhausted.
	end
	return false
end

local function getOwnConnections(x, y)
	local OwnRandom = Random.new(getChunkSeed(x, y))
	local map = {
		["North"] = nil,
		["West"] = nil,
	}
	local northRng = 0.7
	if OwnRandom:NextNumber() < northRng then
		map["North"] = OwnRandom:NextInteger(2, chunkSize - 1)
	end
	local westRng = 0.7
	if OwnRandom:NextNumber() < westRng then
		map["West"] = OwnRandom:NextInteger(2, chunkSize - 1)
	end

	return map
end
local function removeIntersecting(origin, altered) --b - (a n b)
	local newTable = {}
	for _, c in pairs(altered) do
		if not findPositionTable(origin, c) then
			table.insert(newTable, c)
		end
	end
	return newTable
end

local function mergePositionTables(a, b)
	for _, z in b do
		if not findPositionTable(a, z) then
			table.insert(a, z)
		end
	end
end

local function copyTable(table) --returns a shallow copy of the corresponding table.
	local new = {}
	for a, b in pairs(table) do
		new[a] = b
	end
	return new
end

local function getAdjacentTiles(x, y, z, connectionPoints) --return in x,y,prevx,prevy,score format... | Z refers to the iteration.., so we don't calculate score based on previous starting tiles.
	local adjacent = {}

	local function calculateCost(x, y, z)
		local cost = 0
		for i = z, #connectionPoints do
			local element = connectionPoints[i]

			local localCost = math.sqrt(math.pow(x - element[1], 2) + math.pow(y - element[2], 2))
			cost += localCost
		end
		return cost
	end

	if x + 1 <= chunkSize then
		local neighbour = { x + 1, y, x, y, calculateCost(x + 1, y, z) }
		table.insert(adjacent, neighbour)
	end
	if x - 1 >= 1 then
		local neighbour = { x - 1, y, x, y, calculateCost(x - 1, y, z) }
		table.insert(adjacent, neighbour)
	end
	if y - 1 >= 1 then
		local neighbour = { x, y - 1, x, y, calculateCost(x, y - 1, z) }
		table.insert(adjacent, neighbour)
	end
	if y + 1 <= chunkSize then
		local neighbour = { x, y + 1, x, y, calculateCost(x, y + 1, z) }
		table.insert(adjacent, neighbour)
	end

	return adjacent
end
local function getAllConnections(x, y)
	local map = {
		["North"] = nil,
		["West"] = nil,
		["South"] = nil,
		["East"] = nil,
	}
	local OwnRandom = Random.new(getChunkSeed(x, y))

	local northRng = 0.7
	if OwnRandom:NextNumber() < northRng then
		map["North"] = OwnRandom:NextInteger(2, chunkSize - 1)
	end
	local westRng = 0.7
	if OwnRandom:NextNumber() < westRng then
		map["West"] = OwnRandom:NextInteger(2, chunkSize - 1)
	end
	map["South"] = getOwnConnections(x, y - 1)["North"]
	map["East"] = getOwnConnections(x + 1, y)["West"]

	return map
end

local function createWall(pos1, pos2, chunk, destination)
	local xdif = pos2[1] - pos1[1]
	local ydif = pos2[2] - pos1[2]

	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(tileSize, 20, 1)
	part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
		+ Vector3.new(tileSize * (pos1[1] + 0.5 * xdif), 10, tileSize * (pos1[2] + 0.5 * ydif))
	part.Parent = destination
	part.Name = "Wall " .. getKey(pos1[1], pos1[2])

	if math.abs(pos1[1] - pos2[1]) == 1 then
		part.Rotation = Vector3.new(0, 90, 0)
	end
end

local function createDoor(pos1, pos2, chunk, destination)
	local xdif = pos2[1] - pos1[1]
	local ydif = pos2[2] - pos1[2]

	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(tileSize, 20, 1)
	part.Color = Color3.new(0.121568, 0.117647, 0.117647)
	part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
		+ Vector3.new(tileSize * (pos1[1] + 0.5 * xdif), 10, tileSize * (pos1[2] + 0.5 * ydif))
	part.Parent = destination
	part.Name = "Door " .. getKey(pos1[1], pos1[2])

	if math.abs(pos1[1] - pos2[1]) == 1 then
		part.Rotation = Vector3.new(0, 90, 0)
	end
end

local function generateWalls(room, pos, chunk, chunkMap, destination)

	if not room then
		if pos[1] == 1 then
			createWall(pos, { pos[1] - 1, pos[2] }, chunk, destination)
		end
		if pos[2] == chunkSize then
			createWall(pos, { pos[1], pos[2] + 1 }, chunk, destination)
		end
		return
	end

	local shape = room.shape
	local roomtiles = { pos }
	if shape then
		for _, tile in shape do --get every tile in the shape into roomtiles
			local rotx = tile[1]
			local roty = tile[2]
			for _ = 1, room.rotations do
				rotx, roty = roty, -rotx
			end
			table.insert(roomtiles, { rotx + pos[1], roty + pos[2] })
		end
	end

	local connecs = getOwnConnections(chunk[1], chunk[2])
	local connectN = connecs["North"]
	local connectW = connecs["West"]

	for _, tile in roomtiles do
		local adjacent = getNorthWestAdjacent(tile[1], tile[2])
		local west = adjacent["West"]
		local north = adjacent["North"]
		local south = adjacent["South"]
		local east = adjacent["East"]
		adjacent = removeIntersecting(roomtiles, adjacent)
		--west
		if west then -- ignore tiles that are roomtiles.
			if findPositionTable(adjacent, west) then -- if it wasn't removed because it was a fellow room members
				local neighbour = chunkMap[west[1]][west[2]]
				if not neighbour then
					createWall(tile, { tile[1] - 1, tile[2] }, chunk, destination)
				elseif room.type == "Hallway" then --hm logical equivalance ?  !(a^b ) = a ^ !b
					if not (neighbour.type == "Hallway") then --its a room
						if neighbour.eldest == true and neighbour.hasDoor == false and neighbour.rotations == 3 then
							neighbour.hasDoor = true
							createDoor(tile, { tile[1] - 1, tile[2] }, chunk, destination)
						else --todo
							print(connectW, " === "..tile[1].." and "..tile[2])
							createWall(tile, { tile[1] - 1, tile[2] }, chunk, destination)
						end
					end
				elseif room.eldest and not room.hasDoor and room.rotations == 1 then
					createDoor(tile, { tile[1] - 1, tile[2] }, chunk, destination)
				else
					createWall(tile, { tile[1] - 1, tile[2] }, chunk, destination)
				end
			end
		elseif not (tile[1] == 1 and tile[2] == connectW) then
			createWall(tile, { tile[1] - 1, tile[2] }, chunk, destination)
		end

		if north then
			if findPositionTable(adjacent, north) then
				local neighbour = chunkMap[north[1]][north[2]]
				if not neighbour then
					createWall(tile, { tile[1], tile[2] + 1 }, chunk, destination)
				elseif room.type == "Hallway" then --hm logical equivalance ?  !(a^b ) = a ^ !b
					if not (neighbour.type == "Hallway") then --its a room
						if neighbour.eldest == true and neighbour.hasDoor == false and neighbour.rotations == 0 then
							neighbour.hasDoor = true
							createDoor(tile, { tile[1], tile[2] + 1 }, chunk, destination)
						else
							print(connectN, " === "..tile[1].." and "..tile[2])
							createWall(tile, { tile[1], tile[2] + 1 }, chunk, destination)
						end
					end
				elseif room.eldest and not room.hasDoor and room.rotations == 2 then
					createDoor(tile, { tile[1], tile[2] + 1 }, chunk, destination)
				else
					createWall(tile, { tile[1], tile[2] + 1 }, chunk, destination)
				end
			end
		elseif not (tile[1] == connectN and tile[2] == chunkSize) then
			createWall(tile, { tile[1], tile[2] + 1 }, chunk, destination)
		end

		if south and not chunkMap[south[1]][south[2]] then --nobody will generate a tile for this wall for this room if it does exist in the chunk but there's no tile placed.
			createWall(tile, { tile[1], tile[2] - 1 }, chunk, destination)
		end
		if east and not chunkMap[east[1]][east[2]] then
			createWall(tile, { tile[1] + 1, tile[2] }, chunk, destination)
		end
	end

	--TODO VERY IMPORTANT, FOR THE NORTH AND WEST EDGE OF THE CHUNK MAKE SURE THERE ARE !!WALLS!! FOR EACH TILE THAT IS NOT OCCUPIED AND THEREFORE,
	--HAS NOT GENERATED WALLS. THIS IS FOR THE SAKE OF OTHER CHUNKS' ROOMS
end

local function buildChunk(destination, chunk, chunkMap)
	print(chunkMap)
	for x = 1, chunkSize do
		for y = 1, chunkSize do
			local room = chunkMap[x][y]

			if not room then
				if x == 1 or y == chunkSize then
					generateWalls(room, { x, y }, chunk, chunkMap, destination)
				end
				continue
			end

			if room.type == "Hallway" then
				local part = Instance.new("Part")
				part.Anchored = true
				part.Size = Vector3.new(tileSize, 1, tileSize)
				part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
					+ Vector3.new(tileSize * x, 10, tileSize * y)
				part.Parent = destination
				part.Name = getKey(x, y)
			elseif room.type == "InterviewRoom" then
				local part = Instance.new("Part")
				part.Anchored = true
				part.Color = Color3.fromRGB(16, 113, 204)
				part.Size = Vector3.new(tileSize, 1, tileSize)
				part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
					+ Vector3.new(tileSize * x, 10, tileSize * y)
				part.Parent = destination
				part.Name = getKey(x, y)
			elseif room.type == "SingleOffice" then
				local part = Instance.new("Part")
				part.Anchored = true
				part.Color = Color3.fromRGB(151, 16, 204)
				part.Size = Vector3.new(tileSize, 1, tileSize)
				part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
					+ Vector3.new(tileSize * x, 10, tileSize * y)
				part.Parent = destination
				part.Name = getKey(x, y)
			elseif room.type == "Cafeteria" then
				local part = Instance.new("Part")
				part.Anchored = true
				part.Color = Color3.fromRGB(185, 204, 16)
				part.Size = Vector3.new(tileSize, 1, tileSize)
				part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
					+ Vector3.new(tileSize * x, 10, tileSize * y)
				part.Parent = destination
				part.Name = getKey(x, y)
			elseif room.type == "Corner" then
				local part = Instance.new("Part")
				part.Anchored = true
				part.Color = Color3.fromRGB(16, 191, 204)
				part.Size = Vector3.new(tileSize, 1, tileSize)
				part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
					+ Vector3.new(tileSize * x, 10, tileSize * y)
				part.Parent = destination
				part.Name = getKey(x, y)
			else
				local part = Instance.new("Part")
				part.Anchored = true
				part.Color = Color3.fromRGB(204, 16, 16)
				part.Size = Vector3.new(tileSize, 1, tileSize)
				part.Position = chunkSize * tileSize * Vector3.new(chunk[1], 0, chunk[2])
					+ Vector3.new(tileSize * x, 10, tileSize * y)
				part.Parent = destination
				part.Name = getKey(x, y)
			end

			if room.eldest == true then
				generateWalls(room, { x, y }, chunk, chunkMap, destination)
			end
		end
	end
end

local function getFittingRooms(chunkMap: table, tile: table) --returns a room that fits in the chunkmap starting at the corresponding tile.
	local choices = {}
	for _, tpe in defaultTiles do
		if tpe.shape ~= nil then
			local x = tile[1]
			local y = tile[2]
			local rotation = tile[3]
			local blocked = false
			for _, space in tpe.shape do
				local rotX = space[1]
				local rotY = space[2]
				for i = 1, rotation do
					rotX, rotY = rotY, -rotX
				end

				if x + rotX < 1 or x + rotX > chunkSize or y + rotY < 1 or y + rotY > chunkSize then
					blocked = true
					break
				end
				if chunkMap[x + rotX][y + rotY] ~= nil then
					blocked = true
				end
			end
			if blocked then
				continue
			end
		end
		table.insert(choices, tpe)
	end
	return choices
end

local function addRoom(chunkMap, tile, room)
	local x = tile[1]
	local y = tile[2]
	local rotation = tile[3]
	local occupation = {}

	local shape = room.shape
	local copy = copyTable(room)
	copy.eldest = true
	copy.rotations = rotation
	chunkMap[x][y] = copy
	table.insert(occupation, { x, y })
	if shape then
		for _, space in shape do
			local rotX = space[1]
			local rotY = space[2]
			for _ = 1, rotation do
				rotX, rotY = rotY, -rotX
			end
			chunkMap[x + rotX][y + rotY] = room
			table.insert(occupation, { x + rotX, y + rotY })
		end
	end
	return occupation
end

local function generateChunkRooms(chunkMap, random: Random)
	local explored = {}
	for x, list in chunkMap do
		for y, floor in list do
			if floor["type"] == "Hallway" then
				table.insert(explored, { x, y })
			end
		end
	end
	local frontier = {}
	for _, tile in explored do --for every hallway
		local adjacent = getSpaceAdjacent(tile[1], tile[2])
		adjacent = removeIntersecting(explored, adjacent) --avoid explored tiles being in the adjacent list
		adjacent = removeIntersecting(frontier, adjacent) --avoid frontier tiles from being duped.
		mergePositionTables(frontier, adjacent)
	end --add every tile next to a hallway which isn't a hallway to a frontier list, for each tile there we want it to at least be generated as a room.

	local placedRooms = {}
	--possibly add its relativitiy to the hallway, if its to the left right front back? so we can use rotation, we only need the first, dont think this will cause bias?
	while #frontier > 0 do --there are spaces left to fill.
		local tile = frontier[1]
		local roomTypes = getFittingRooms(chunkMap, tile) -- how do we figure out if the room type occupise another frontier?
		local roomtp = roomTypes[random:NextInteger(1, #roomTypes)]
		local occupation = addRoom(chunkMap, tile, roomtp) --what tiles the room will occupy will be returned?
		if roomtp.type == "Hallway" then
			local adjacent = getSpaceAdjacent(tile[1], tile[2])
			adjacent = removeIntersecting(explored, adjacent) --avoid explored tiles being in the adjacent list
			adjacent = removeIntersecting(frontier, adjacent) --avoid frontier tiles from being duped.
			adjacent = removeIntersecting(placedRooms, adjacent)
			mergePositionTables(frontier, adjacent)
		end
		mergePositionTables(placedRooms, occupation)
		frontier = removeIntersecting(occupation, frontier) --remove any occupied tiles from the frontier.
	end

	return chunkMap
end

--Use a altered form of a* which based on the same connection points, generates the same result. it generates hallways based on distance from every connectionpoint,
--and the starting hallway, if we reach another connectionpoint we create the path that leads to it (influenced by the distance to other entry points, so not shortest per say).
--Then we remove the original starting point and start pathing from the next connectionpoint, ignoring the already connected starting point.
local function generateChunkHallways(connectionPoints: table) --interesting
	--Calculate the cost.. should update to not use magnitude.

	local formedHallways = {}

	for z = 1, #connectionPoints - 1 do
		local currentStart = connectionPoints[z]
		local searched = {} --{{x,y,prevx,prevy,(score)},{...}}
		local possible = {} --{{x,y,prevx,prevy,score}
		local adjacent = getAdjacentTiles(currentStart[1], currentStart[2], z, connectionPoints)

		table.insert(searched, currentStart)
		mergePositionTables(possible, adjacent)

		while true do
			local lowestCost = possible[1][5]
			local candidate = possible[1]

			for _, entry in possible do
				if entry[5] < lowestCost then
					lowestCost = entry[5]
					candidate = entry
				end
			end
			table.remove(possible, findPositionTable(possible, candidate))

			local found = findPositionTable(connectionPoints, candidate)
			if found and found > z then --if we found an entry chunk not already connected.
				--ADD the hallway connection to the formedhallways
				local path = candidate
				local newHalls = {}
				repeat
					table.insert(newHalls, { path[1], path[2] })
					path = searched[findPositionTable(searched, { path[3], path[4] })] -- find the previous tile, based on the prevx and prevy position/
				until path[3] == nil --if there's no prevx this is the starting pos.
				table.insert(newHalls, { path[1], path[2] })
				mergePositionTables(formedHallways, newHalls)

				break
			end
			table.insert(searched, candidate)
			adjacent = getAdjacentTiles(candidate[1], candidate[2], z, connectionPoints)
			adjacent = removeIntersecting(searched, adjacent)
			mergePositionTables(possible, adjacent)
		end
	end
	return formedHallways
end

local function syncLoadChunk(x: IntValue, y: IntValue) --we seem to start at chunk -1,-1
	table.insert(loadedChunks, { x, y })
	print("Started loading chunk " .. x .. " " .. y)
	local chunkMap = {}
	for t = 1, chunkSize do
		chunkMap[t] = {}
	end
	local key = getKey(x, y)

	local chunkFolder = Instance.new("Folder")
	chunkFolder.Parent = folder
	chunkFolder.Name = key

	local connections = getAllConnections(x, y)

	--create the tiles in the chunkmap where the hallways are connecting to the adjacent chunks.
	local startingHallways = {}
	--North
	if connections["North"] then
		chunkMap[connections["North"]][chunkSize] = defaultTiles["Hallway"]
		table.insert(startingHallways, { connections["North"], chunkSize })
	end
	--West
	if connections["West"] then
		chunkMap[1][connections["West"]] = defaultTiles["Hallway"]
		table.insert(startingHallways, { 1, connections["West"] })
	end
	--South
	if connections["South"] then
		chunkMap[connections["South"]][1] = defaultTiles["Hallway"]
		table.insert(startingHallways, { connections["South"], 1 })
	end
	--East
	if connections["East"] then
		chunkMap[chunkSize][connections["East"]] = defaultTiles["Hallway"]
		table.insert(startingHallways, { chunkSize, connections["East"] })
	end

	local rand = Random.new(getChunkSeed(x, y))

	local newHallway = { rand:NextInteger(2, chunkSize - 1), rand:NextInteger(2, chunkSize - 1) }
	table.insert(startingHallways, newHallway)
	if rand:NextNumber() < 0.6 then
		local secondHallway = { rand:NextInteger(2, chunkSize - 1), rand:NextInteger(2, chunkSize - 1) }
		if newHallway[1] ~= secondHallway[1] and newHallway[2] ~= secondHallway[2] then --if the new hallway isn't the same as the last.
			table.insert(startingHallways, secondHallway)
		end
	end
	local newHallwayTiles = generateChunkHallways(startingHallways) --issue is probably here.
	for _, tile in newHallwayTiles do
		chunkMap[tile[1]][tile[2]] = defaultTiles["Hallway"]
	end
	local newRooms = generateChunkRooms(chunkMap, rand)

	--hm for hallway generation. use some type of a* with bias towards any opening. and maybe randomly generate one or two other endpoints with bias near the middle to add randomness
	--now we have all respective connections, with their position so now we generate the hallways. through rand

	buildChunk(chunkFolder, { x, y }, chunkMap) --build the chunks
end

--cant we syncunloadchunk = coroutine.wrap()
local function asyncLoadChunk(x, y)
	local thread = coroutine.wrap(syncLoadChunk)
	thread(x, y)
end

--consider accepting chunk x y, or changing key method
local function syncUnloadChunk(x: IntValue, y: IntValue)
	local key = getKey(x, y)
	local child = folder:FindFirstChild(key)
	if child then
		child:Destroy()
	end
	table.remove(loadedChunks, findPositionTable(loadedChunks, { x, y }))
end

local function asyncUnloadChunk(x, y)
	local thread = coroutine.wrap(syncUnloadChunk)
	thread(x, y)
end

local function getChunksToUnload(currentChunk: table | nil): table
	if not currentChunk then
		currentChunk = lastChunk
	end

	local chunksToUnload = {}
	--square chunk loading
	for _, loadedChunk in loadedChunks do
		if
			math.abs(loadedChunk[1] - currentChunk[1]) > loadedChunkRange
			or math.abs(loadedChunk[2] - currentChunk[2]) > loadedChunkRange
		then
			table.insert(chunksToUnload, loadedChunk)
		end
	end

	return chunksToUnload
end

--Finds all chunks that are in both tables and returns the first table without those chunks. C = A - (A n B) , return C
--[[local function removeIntersectingChunks(A: table, B: table): table
	local C = {}

	for _, a in A do
		local flag = false
		for _, b in B do
			if a[1] == b[1] and a[2] == b[2] then --
				flag = true
			end
		end
		if not flag then
			table.insert(C, a)
		end
	end

	return C
end]]

--Finds all squares in the loadedChunkRange around the currentChunk, or lastChunk if not provided.
local function getChunksToLoad(currentChunk: table | nil): table
	if not currentChunk then
		currentChunk = lastChunk
	end

	local chunksToLoad = {}

	--ahh linear search for chunks? Ehh no interest in implementing binary search . and sorting

	for i = (-loadedChunkRange + currentChunk[1]), (loadedChunkRange + currentChunk[1]) do
		for j = (-loadedChunkRange + currentChunk[2]), (loadedChunkRange + currentChunk[2]) do
			if not findPositionTable(loadedChunks, { i, j }) then
				table.insert(chunksToLoad, { i, j })
			end
		end
	end
	return chunksToLoad
end

--Create a thread to run the chunkloading routine.
local chunkLoadingThread = coroutine.wrap(function()
	while true do
		task.wait(2)

		local character = player.Character or nil
		if not character then
			continue
		end

		local humRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humRootPart then
			continue
		end

		local currentPosition = humRootPart.Position
		local currentChunk = {
			math.floor(currentPosition.X / (chunkSize * tileSize)),
			math.floor(currentPosition.Z / (chunkSize * tileSize)),
		}
		if lastChunk[1] == currentChunk[1] and lastChunk[2] == currentChunk[2] then
			continue
		end

		local hasMoved = not (lastChunk[1] == currentChunk[1] and lastChunk[2] == currentChunk[2])

		--now the madness descends

		--we can honestly just add or remove a row/column when someone moves a chunk over.
		--how do we figure every chunk to unload and which to load based on range?
		if hasMoved then
			lastChunk = currentChunk

			local toUnload = getChunksToUnload()
			for _, chunk in toUnload do
				asyncUnloadChunk(chunk[1], chunk[2])
			end

			local toLoad = getChunksToLoad()
			for _, chunk in toLoad do
				asyncLoadChunk(chunk[1], chunk[2])
			end
		end
	end
end)
chunkLoadingThread()
