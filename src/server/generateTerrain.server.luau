local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BLOCK_SIZE = 4 

local MAP_SIZE_X = 64
local MAP_SIZE_Z = 64

local MAX_HEIGHT = 32
local SEA_LEVEL = 8
local BEDROCK_LEVEL = 1

local SEED = math.random(1, 1000)
local FREQUENCY = 40
local AMPLITUDE = 16

local TEXTURE_IDS = {
	Grass = nil, 
	Dirt  = nil,
	Stone = nil,
	Sand  = nil,
	Log   = nil,
	Leaves= nil
}

local terrainFolder = Instance.new("Folder")
terrainFolder.Name = "Terrain"
terrainFolder.Parent = workspace

local function createBlock(x, y, z, blockType)
	local part = Instance.new("Part")
	part.Name = blockType
	part.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	part.Position = Vector3.new(x * BLOCK_SIZE, y * BLOCK_SIZE, z * BLOCK_SIZE)

	if blockType == "Grass" then
		part.Color = Color3.fromRGB(86, 147, 60)
		part.Material = Enum.Material.Grass
	elseif blockType == "Dirt" then
		part.Color = Color3.fromRGB(120, 72, 48)
		part.Material = Enum.Material.Slate 
	elseif blockType == "Stone" then
		part.Color = Color3.fromRGB(100, 100, 100)
		part.Material = Enum.Material.Slate
	elseif blockType == "Sand" then
		part.Color = Color3.fromRGB(235, 220, 160)
		part.Material = Enum.Material.Sand
	elseif blockType == "Water" then
		part.Color = Color3.fromRGB(50, 100, 200)
		part.Material = Enum.Material.Plastic
		part.Transparency = 0.4
		part.CanCollide = false
	elseif blockType == "Log" then
		part.Color = Color3.fromRGB(90, 60, 40)
		part.Material = Enum.Material.Wood
	elseif blockType == "Leaves" then
		part.Color = Color3.fromRGB(60, 120, 60)
		part.Material = Enum.Material.Grass
		part.Transparency = 0.1
	elseif blockType == "Bedrock" then
		part.Color = Color3.fromRGB(20, 20, 20)
		part.Material = Enum.Material.Granite
	end

	if TEXTURE_IDS[blockType] then
		local texture = Instance.new("Texture")
		texture.Texture = TEXTURE_IDS[blockType]
		texture.Face = Enum.NormalId.Top
		texture.Parent = part
		part.Material = Enum.Material.SmoothPlastic 
	end

	part.Parent = terrainFolder
end

local function generateTree(x, y, z)
	local height = math.random(4, 6)

	for i = 1, height do
		createBlock(x, y + i, z, "Log")
	end

	local leafStart = y + height - 2
	for ly = leafStart, y + height + 1 do
		for lx = x - 2, x + 2 do
			for lz = z - 2, z + 2 do
				if math.abs(lx - x) <= 2 and math.abs(lz - z) <= 2 then
					if not (lx == x and lz == z and ly < y + height) then
						if math.random() > 0.2 then
							createBlock(lx, ly, lz, "Leaves")
						end
					end
				end
			end
		end
	end
end

local function generateTerrain()
	for x = 1, MAP_SIZE_X do
		for z = 1, MAP_SIZE_Z do

			local noiseValue = math.noise(x / FREQUENCY, z / FREQUENCY, SEED)
			local groundHeight = math.floor((noiseValue * AMPLITUDE) + (MAX_HEIGHT / 2))

			if groundHeight < BEDROCK_LEVEL then groundHeight = BEDROCK_LEVEL end

			local surfaceBlock = "Grass"
			if groundHeight <= SEA_LEVEL + 1 then
				surfaceBlock = "Sand"
			end

			for y = 0, groundHeight do
				local blockType = "Stone" 

				if y == 0 then
					blockType = "Bedrock"
				elseif y == groundHeight then
					blockType = surfaceBlock
				elseif y > groundHeight - 3 then
					if surfaceBlock == "Sand" then blockType = "Sand" else blockType = "Dirt" end
				end

				createBlock(x, y, z, blockType)
			end

			if groundHeight < SEA_LEVEL then
				for y = groundHeight + 1, SEA_LEVEL do
					createBlock(x, y, z, "Water")
				end
			end

			if surfaceBlock == "Grass" and math.random(1, 150) == 1 then
				generateTree(x, groundHeight, z)
			end

			if x % 5 == 0 and z == 1 then task.wait() end
		end
	end
end

generateTerrain()