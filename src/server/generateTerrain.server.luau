local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BLOCK_SIZE = 4
local CHUNK_SIZE = 32
local MAX_HEIGHT = 128
local SEA_LEVEL = 40
local RENDER_DISTANCE = 4

local SEED = 4521
local NOISE_SCALE = 60
local BIOME_SCALE = 200

local chunks = {}
local requestQueue = {}
local isGenerating = false

local terrainFolder = Instance.new("Folder")
terrainFolder.Name = "ProceduralTerrain"
terrainFolder.Parent = workspace

local blockTemplate = Instance.new("Part")
blockTemplate.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
blockTemplate.Anchored = true
blockTemplate.TopSurface = Enum.SurfaceType.Smooth
blockTemplate.BottomSurface = Enum.SurfaceType.Smooth
blockTemplate.CastShadow = false

local Materials = {
	Grass = { Color3.fromRGB(91, 154, 76), Enum.Material.Grass },
	Dirt = { Color3.fromRGB(133, 94, 66), Enum.Material.Ground },
	Stone = { Color3.fromRGB(105, 105, 105), Enum.Material.Slate },
	Sand = { Color3.fromRGB(227, 219, 137), Enum.Material.Sand },
	Water = { Color3.fromRGB(64, 115, 255), Enum.Material.Plastic, 0.4 },
	Snow = { Color3.fromRGB(240, 240, 240), Enum.Material.Sand },
	Log = { Color3.fromRGB(86, 62, 44), Enum.Material.Wood },
	Leaves = { Color3.fromRGB(81, 133, 59), Enum.Material.Grass },
	Cactus = { Color3.fromRGB(85, 130, 65), Enum.Material.Plastic },
	Bedrock = { Color3.fromRGB(25, 25, 25), Enum.Material.Granite },
}

local function getBiome(x, z)
	local temp = math.noise(x / BIOME_SCALE, z / BIOME_SCALE, SEED + 0.1)
	local humid = math.noise(x / BIOME_SCALE + 500, z / BIOME_SCALE + 500, SEED + 0.1)

	if temp > 0.4 then
		return "Desert"
	elseif temp < -0.4 then
		return "Snow"
	elseif humid > 0.2 and temp > -0.2 then
		return "Forest"
	else
		return "Plains"
	end
end

local function getHeight(x, z, biome)
	local baseHeight = math.noise(x / NOISE_SCALE, z / NOISE_SCALE, SEED) * 20 + 50
	local mountainNoise = math.noise(x / (NOISE_SCALE * 0.5), z / (NOISE_SCALE * 0.5), SEED + 100)

	if biome == "Desert" then
		return baseHeight * 0.8
	elseif biome == "Snow" then
		return baseHeight + (mountainNoise * 40)
	else
		return baseHeight + (mountainNoise * 10)
	end
end

local function makeTree(x, y, z, chunkData)
	local height = math.random(4, 6)
	for i = 0, height - 1 do
		chunkData[x][y + i][z] = "Log"
	end
	for lx = -2, 2 do
		for ly = height - 2, height + 1 do
			for lz = -2, 2 do
				if chunkData[x + lx] and chunkData[x + lx][y + ly] and chunkData[x + lx][y + ly][z + lz] == nil then
					if math.abs(lx) + math.abs(lz) + math.abs(ly - height) <= 3 then
						chunkData[x + lx][y + ly][z + lz] = "Leaves"
					end
				end
			end
		end
	end
end

local function makeCactus(x, y, z, chunkData)
	local height = math.random(2, 4)
	for i = 0, height - 1 do
		chunkData[x][y + i][z] = "Cactus"
	end
end

local function generateChunkData(cx, cz)
	local data = {}
	local rng = Random.new(cx * SEED + cz)

	for x = 1, CHUNK_SIZE do
		data[x] = {}
		for y = 1, MAX_HEIGHT do
			data[x][y] = {}
		end
	end

	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			local wx = (cx * CHUNK_SIZE) + x
			local wz = (cz * CHUNK_SIZE) + z

			local biome = getBiome(wx, wz)
			local height = math.floor(getHeight(wx, wz, biome))
			local dirtDepth = math.random(3, 5)

			for y = 1, height do
				local blockType = "Stone"

				if y == 1 then
					blockType = "Bedrock"
				elseif y == height then
					if biome == "Desert" then
						blockType = "Sand"
					elseif biome == "Snow" then
						blockType = "Snow"
					else
						blockType = "Grass"
					end

					if y <= SEA_LEVEL + 2 and biome ~= "Snow" then
						blockType = "Sand"
					end
				elseif y > height - dirtDepth then
					if biome == "Desert" then
						blockType = "Sand"
					else
						blockType = "Dirt"
					end
				end

				data[x][y][z] = blockType
			end

			if height < SEA_LEVEL then
				for y = height + 1, SEA_LEVEL do
					data[x][y][z] = "Water"
				end
			end

			if x > 2 and x < CHUNK_SIZE - 2 and z > 2 and z < CHUNK_SIZE - 2 then
				if height > SEA_LEVEL and data[x][height][z] == "Grass" and biome == "Forest" then
					if rng:NextNumber() < 0.04 then
						makeTree(x, height + 1, z, data)
					end
				elseif height > SEA_LEVEL and biome == "Desert" and data[x][height][z] == "Sand" then
					if rng:NextNumber() < 0.01 then
						makeCactus(x, height + 1, z, data)
					end
				end
			end
		end
	end
	return data
end

local function buildChunk(cx, cz)
	if chunks[cx .. ":" .. cz] then
		return
	end

	local cFolder = Instance.new("Folder")
	cFolder.Name = cx .. ":" .. cz

	local data = generateChunkData(cx, cz)
	local partsBuffer = {}

	for x = 1, CHUNK_SIZE do
		for y = 1, MAX_HEIGHT do
			for z = 1, CHUNK_SIZE do
				local type = data[x][y][z]
				if type then
					local exposed = false

					if type == "Leaves" or type == "Log" or type == "Cactus" then
						exposed = true
					elseif type == "Water" then
						if y == SEA_LEVEL or (data[x][y + 1][z] == nil) then
							exposed = true
						end
					else
						if
							y == MAX_HEIGHT
							or data[x][y + 1][z] == nil
							or data[x][y + 1][z] == "Water"
							or (x > 1 and data[x - 1][y][z] == nil)
							or (x < CHUNK_SIZE and data[x + 1][y][z] == nil)
							or (z > 1 and data[x][y][z - 1] == nil)
							or (z < CHUNK_SIZE and data[x][y][z + 1] == nil)
						then
							exposed = true
						end
					end

					if exposed then
						local info = Materials[type]
						local part = blockTemplate:Clone()
						part.Position = Vector3.new(
							(cx * CHUNK_SIZE + x) * BLOCK_SIZE,
							y * BLOCK_SIZE,
							(cz * CHUNK_SIZE + z) * BLOCK_SIZE
						)
						part.Color = info[1]
						part.Material = info[2]
						if info[3] then
							part.Transparency = info[3]
							part.CanCollide = false
						end
						if type == "Leaves" then
							part.Transparency = 0.2
						end
						table.insert(partsBuffer, part)
					end
				end
			end
		end
		if x % 4 == 0 then
			RunService.Heartbeat:Wait()
		end
	end

	for _, p in ipairs(partsBuffer) do
		p.Parent = cFolder
	end

	cFolder.Parent = terrainFolder
	chunks[cx .. ":" .. cz] = cFolder
end

local function updateChunks()
	if isGenerating then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local pos = char.HumanoidRootPart.Position
			local cx = math.floor(pos.X / (CHUNK_SIZE * BLOCK_SIZE))
			local cz = math.floor(pos.Z / (CHUNK_SIZE * BLOCK_SIZE))

			for x = -RENDER_DISTANCE, RENDER_DISTANCE do
				for z = -RENDER_DISTANCE, RENDER_DISTANCE do
					local dist = math.sqrt(x * x + z * z)
					if dist <= RENDER_DISTANCE then
						local key = (cx + x) .. ":" .. (cz + z)
						if not chunks[key] then
							isGenerating = true
							buildChunk(cx + x, cz + z)
							isGenerating = false
							return
						end
					end
				end
			end

			for key, folder in pairs(chunks) do
				local coords = string.split(key, ":")
				local chunkX = tonumber(coords[1])
				local chunkZ = tonumber(coords[2])
				local dist = math.sqrt((chunkX - cx) ^ 2 + (chunkZ - cz) ^ 2)

				if dist > RENDER_DISTANCE + 2 then
					folder:Destroy()
					chunks[key] = nil
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(updateChunks)