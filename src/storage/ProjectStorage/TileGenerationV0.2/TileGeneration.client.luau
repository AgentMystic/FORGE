--by mys.tic
print("Tile Generation Started!!!!!")

local folder = Instance.new("Folder")
folder.Name = "ChunkGeneration"
folder.Parent = workspace

--may god be with me.


--Configurable parameters
local loadedChunkRange = 4
local seed = 1
local chunkSize = 16 --16x16 10x10 tiles
--Also configurable as long as the corresponding tile rooms are updated.
local tileSize = 10 --studs

--fetch services
local players = game:GetService("Players")

--variables
local chunkMap = {}
local loadedChunks = {}
local lastChunk = { nil, nil }
local player = players.LocalPlayer

--procedural infinity

local function getKey(chunk:table): string
	return tostring(chunk[1]) +","+ tostring(chunk[2])
end

local function syncLoadChunk(x: IntValue, y: IntValue) end
	table.insert(loadedChunks)
local function asyncLoadChunk(x: IntValue, y: IntValue)
	local thread = coroutine.wrap(syncLoadChunk)
	thread(x, y)
end
--consider accepting chunk x y, or changing key method
local function syncUnloadChunk(x: IntValue, y: IntValue) end

local function asyncUnloadChunk(x: IntValue, y: IntValue)
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


local function findChunk(chunkTable: table, chunk: table)
	for indx, element in chunkTable do
		if element[1] == chunk[1] and element[2] == chunk[2] then
			return indx
		end
	end
	return false
end

--Finds all squares in the loadedChunkRange around the currentChunk, or lastChunk if not provided.
local function getChunksToLoad(currentChunk: table | nil): table
	if not currentChunk then
		currentChunk = lastChunk
	end

	local chunksToLoad = {}

	--ahh linear search for chunks? Ehh no interest in implementing binary search . and sorting

	for i = (-loadedChunkRange + currentChunk[1]), (loadedChunkRange + currentChunk[1]) do
		for j = (-loadedChunkRange + currentChunk[2]), (loadedChunkRange + currentChunk[2]) do
			if not findChunk(loadedChunks, { i, j }) then
				table.insert(chunksToLoad, { i, j })
			end
		end
	end
	return chunksToLoad
end

--Create a thread to run the chunkloading routine.
local chunkLoadingThread = coroutine.wrap(function()
	while true do
		task.wait(0.05)

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
