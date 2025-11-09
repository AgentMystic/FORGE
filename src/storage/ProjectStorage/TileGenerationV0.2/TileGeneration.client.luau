--by mys.tic
print("Tile Generation Started!!!!!")

local folder = Instance.new("Folder")
folder.Name = "ChunkGeneration"
folder.Parent = workspace

--may god be with me.

--Configurable parameters
local tileSize = 10 --studs
local chunkSize = 16 --16x16 10x10 tiles
local loadedChunkRange = 6

--fetch services
local players = game:GetService("Players")

--variables
local chunkMap = {}
local loadedChunks = {}
local lastChunk = {nil,nil}
local player = players.LocalPlayer


--procedural infinity

local function syncLoadChunk(x : IntValue,y : IntValue)

end

local function asyncLoadChunk(x : IntValue,y : IntValue)
    local thread = coroutine.wrap(syncLoadChunk)
    thread(x,y)
end

local function syncUnloadChunk(x : IntValue,y : IntValue)

end

local function asyncUnloadChunk(x : IntValue,y : IntValue)
    local thread = coroutine.wrap(syncUnloadChunk)
    thread(x,y)
end

local function getChunksToUnload(currentChunk : table | nil) : table

    if not currentChunk then
        currentChunk = lastChunk
    end

    local chunksToUnload = {}
    --square chunk loading
    for _,loadedChunk in loadedChunks do
        if math.abs(loadedChunk[1] - currentChunk[1]) > loadedChunkRange or math.abs(loadedChunk[2] - currentChunk[2]) > loadedChunkRange then
            table.insert(chunksToUnload,loadedChunk)
        end
    end

    return chunksToUnload

end

--Finds all chunks that are in both tables and returns the first table without thsoe chunks. C = A - (A n B) , return C
local function removeIntersectingChunks(A : table,B : table) : table

    local C = {}

    for _,a in A do
        local flag = false
        for _,b in B do
            if a[1] == b[1] and a[2] == b[2] then -- 
                flag = true
            end
        end
        if not flag then
            table.insert(C,a)
        end
    end

    return C

end

--Finds all squares in the loadedChunkRange around the currentChunk, or lastChunk if not provided.
local function getChunksToLoad(currentChunk : table | nil) : table

    if not  currentChunk then
        currentChunk = lastChunk
    end

    local chunksToLoad = {}

end


local chunkLoadingThread = coroutine.wrap(function()

    while true do

        task.wait(.05)

        local character = player.Character or nil
        if not character then
            continue
        end

        local humRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humRootPart then
            continue
        end

        local currentPosition = humRootPart.Position
        local currentChunk = {math.ceil(currentPosition.X/(chunkSize*tileSize)),math.ceil(currentPosition.Z/(chunkSize*tileSize))}
        if lastChunk[1] == currentChunk[1] and lastChunk[2] == currentChunk[2] then
            continue
        end

        lastChunk = currentChunk

        --now the madness descends

        --how do we figure every chunk to unload and which to load based on range? 
        local toUnload = getChunksToUnload()
        for _,chunk in toUnload do
            asyncUnloadChunk(chunk[1],chunk[2])
        end
        --now how do we figure out all chunks to load . . . , , , 

    end


end)
chunkLoadingThread()




