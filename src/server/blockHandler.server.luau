local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local breakRemote = remotesFolder:FindFirstChild("BreakBlock") or Instance.new("RemoteEvent")
breakRemote.Name = "BreakBlock"
breakRemote.Parent = remotesFolder

local placeRemote = remotesFolder:FindFirstChild("PlaceBlock") or Instance.new("RemoteEvent")
placeRemote.Name = "PlaceBlock"
placeRemote.Parent = remotesFolder

local BLOCK_DATA = {
	Grass = { material = Enum.Material.Grass, color = Color3.fromRGB(102, 153, 0) },
	Dirt = { material = Enum.Material.Mud, color = Color3.fromRGB(139, 69, 19) },
	Stone = { material = Enum.Material.Rock, color = Color3.fromRGB(112, 112, 112) },
	Wood = { material = Enum.Material.Wood, color = Color3.fromRGB(162, 87, 0) },
}

local blocksFolder = ReplicatedStorage:FindFirstChild("Blocks") or Instance.new("Folder")
blocksFolder.Name = "Blocks"
blocksFolder.Parent = ReplicatedStorage

for name, data in pairs(BLOCK_DATA) do
	if not blocksFolder:FindFirstChild(name) then
		local block = Instance.new("Part")
		block.Name = name
		block.Size = Vector3.new(4, 4, 4)
		block.Material = data.material
		block.Color = data.color
		block.Anchored = true
		block.CanCollide = true
		block.Parent = blocksFolder
	end
end

local BLOCK_SIZE = 4
local MAX_DISTANCE = 100

local function snapToGrid(pos)
	return Vector3.new(
		math.round(pos.X / BLOCK_SIZE) * BLOCK_SIZE,
		math.round(pos.Y / BLOCK_SIZE) * BLOCK_SIZE,
		math.round(pos.Z / BLOCK_SIZE) * BLOCK_SIZE
	)
end

local function findBlockAtPos(pos)
	pos = snapToGrid(pos)
	for _, part in pairs(workspace:GetChildren()) do
		if part:IsA("Part") and part.Size == Vector3.new(4, 4, 4) and part.Anchored and part.Position == pos then
			return part
		end
	end
	return nil
end

spawn(function()
	while true do
		wait(0.3)
		for _, obj in pairs(workspace:GetChildren()) do
			if obj.Name == "BlockPreview" and obj:IsA("Part") then
				obj:Destroy()
			end
		end
	end
end)

breakRemote.OnServerEvent:Connect(function(player, targetPos)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return
	end
	if (char.HumanoidRootPart.Position - targetPos).Magnitude > MAX_DISTANCE then
		return
	end

	local block = findBlockAtPos(targetPos)
	if block then
		block:Destroy()
	end
end)

placeRemote.OnServerEvent:Connect(function(player, blockName, placePos)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return
	end
	if (char.HumanoidRootPart.Position - placePos).Magnitude > MAX_DISTANCE then
		return
	end

	if not BLOCK_DATA[blockName] then
		return
	end
	if findBlockAtPos(placePos) then
		return
	end

	local block = blocksFolder[blockName]:Clone()
	block.Position = placePos
	block.Parent = workspace
end)