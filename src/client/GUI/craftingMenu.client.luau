--[[
	Hi, if you're here, god knows why this works.
	Warning: DO NOT TRY TO ORGANIZE THIS.
	This is a terrible code, and I regretted making this.
	put how much hours you wasted to a warning to the next guy who sees this:

	total_wasted_hours_here: 6
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local _camera = workspace.CurrentCamera

_G.MyInventory = _G.MyInventory
	or {
		{ name = "Grass", count = 64 },
		{ name = "Dirt", count = 64 },
		{ name = "Stone", count = 32 },
		{ name = "Wood", count = 16 },
		nil,
		nil,
		nil,
		nil,
		nil,
	}
local inventory = _G.MyInventory

local selectedSlot = 1
local craftingGrid = {}
local MAX_STACK = 64

local BLOCK_DATA = {
	Grass = { color = Color3.fromRGB(102, 153, 0) },
	Dirt = { color = Color3.fromRGB(139, 69, 19) },
	Stone = { color = Color3.fromRGB(112, 112, 112) },
	Wood = { color = Color3.fromRGB(162, 87, 0) },
	Planks = { color = Color3.fromRGB(204, 142, 58) },
	Stick = { color = Color3.fromRGB(160, 100, 60) },
	CraftingTable = { color = Color3.fromRGB(120, 80, 40) },
	Pickaxe = { color = Color3.fromRGB(150, 150, 150) },
	Sword = { color = Color3.fromRGB(200, 200, 200) },
	Axe = { color = Color3.fromRGB(180, 180, 180) },
}

local recipes = {
	{ grid = { "Wood", "", "", "", "", "", "", "", "" }, output = { name = "Planks", count = 4 } },

	{ grid = { "", "", "", "Planks", "", "", "Planks", "", "" }, output = { name = "Stick", count = 4 } },
	{
		grid = { "Planks", "Planks", "", "Planks", "Planks", "", "", "", "" },
		output = { name = "CraftingTable", count = 1 },
	},
	{
		grid = { "Planks", "Planks", "Planks", "", "Stick", "", "", "Stick", "" },
		output = {
			name = "Pickaxe",
			count = 1,
		},
	},
	{ grid = { "", "Planks", "", "", "Stick", "", "", "", "" }, output = { name = "Sword", count = 1 } },

	{ grid = { "Planks", "Planks", "", "Planks", "", "", "", "Stick", "Stick" }, output = { name = "Axe", count = 1 } },
}

local function flattenGrid()
	local flat = {}
	for i = 1, 9 do
		flat[i] = craftingGrid[i] or ""
	end
	return flat
end

local function matchesRecipe(flat)
	for _, recipe in ipairs(recipes) do
		local match = true
		for i = 1, 9 do
			local g = flat[i]
			local p = recipe.grid[i]
			if (p ~= "" and g ~= p) or (p == "" and g ~= "") then
				match = false
				break
			end
		end
		if match then
			return recipe.output
		end
	end
	return nil
end

local function addToInventory(name, count)
	count = count or 1
	for i = 1, 9 do
		local slot = inventory[i]
		if slot and slot.name == name and slot.count < MAX_STACK then
			local add = math.min(count, MAX_STACK - slot.count)
			slot.count += add
			count -= add
			if count <= 0 then
				return true
			end
		elseif not slot then
			inventory[i] = { name = name, count = math.min(count, MAX_STACK) }
			return true
		end
	end
	return false
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CraftingMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
mainFrame.Position = UDim2.new(0.075, 0, 0.075, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(1, 0, 0, 50)
titleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleFrame.BorderSizePixel = 0
titleFrame.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Crafting"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 50, 0, 50)
closeBtn.Position = UDim2.new(1, -55, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.Size = UDim2.new(0.28, 0, 0.65, 0)
viewportFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
viewportFrame.BackgroundTransparency = 1
viewportFrame.Parent = mainFrame

local vpCamera = Instance.new("Camera")
vpCamera.CFrame = CFrame.new(Vector3.new(3, 2, 5), Vector3.new(0, 2, 0))
viewportFrame.CurrentCamera = vpCamera

local charClone = nil
local rotationConn = nil
local function updateCharPreview()
	if charClone then
		charClone:Destroy()
	end
	if rotationConn then
		rotationConn:Disconnect()
	end

	local char = player.Character

	if not char then
		charClone = nil
		return
	end

	local success, result = pcall(function()
		return char:Clone()
	end)

	if not success or not result then
		warn("Failed to clone character for ViewportFrame.")
		charClone = nil
		return
	end

	charClone = result
	charClone.Parent = viewportFrame

	local root = charClone:FindFirstChild("HumanoidRootPart")

	if root then
		root.CFrame = CFrame.new(0, 0, 0)
		for _, part in pairs(charClone:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			elseif part:IsA("JointInstance") then
				part.Enabled = false
			end
		end
	else
		charClone:Destroy()
		charClone = nil
		return
	end

	rotationConn = RunService.Heartbeat:Connect(function()
		if root and root.Parent then
			root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(2), 0)
		end
	end)
end

player.CharacterAdded:Connect(updateCharPreview)
if player.Character then
	updateCharPreview()
end

local craftFrame = Instance.new("Frame")
craftFrame.Size = UDim2.new(0.35, 0, 0.55, 0)
craftFrame.Position = UDim2.new(0.33, 0, 0.12, 0)
craftFrame.BackgroundTransparency = 1
craftFrame.Parent = mainFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 65, 0, 65)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = craftFrame

local gridSlots = {}
for i = 1, 9 do
	local slot = Instance.new("Frame")
	slot.Name = "GridSlot" .. i
	slot.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	slot.BorderSizePixel = 0
	slot.LayoutOrder = i
	slot.Parent = craftFrame

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slot

	local slotLabel = Instance.new("TextLabel")
	slotLabel.Name = "Label"
	slotLabel.Size = UDim2.new(1, 0, 1, 0)
	slotLabel.BackgroundTransparency = 1
	slotLabel.Text = ""
	slotLabel.TextColor3 = Color3.new(1, 1, 1)
	slotLabel.TextScaled = true
	slotLabel.Font = Enum.Font.Gotham
	slotLabel.Parent = slot

	gridSlots[i] = { frame = slot, label = slotLabel }
end

local outputFrame = Instance.new("Frame")
outputFrame.Size = UDim2.new(0, 70, 0, 70)
outputFrame.Position = UDim2.new(0.33, 20, 0.68, 0)
outputFrame.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
outputFrame.BorderSizePixel = 0
outputFrame.Parent = mainFrame

local outputCorner = Instance.new("UICorner")
outputCorner.CornerRadius = UDim.new(0, 8)
outputCorner.Parent = outputFrame

local outputLabel = Instance.new("TextLabel")
outputLabel.Size = UDim2.new(1, 0, 1, 0)
outputLabel.BackgroundTransparency = 1
outputLabel.Text = ""
outputLabel.TextColor3 = Color3.new(1, 1, 1)
outputLabel.TextScaled = true
outputLabel.Font = Enum.Font.GothamBold
outputLabel.Parent = outputFrame

local hotbarFrame = Instance.new("Frame")
hotbarFrame.Size = UDim2.new(0.6, 0, 0, 70)
hotbarFrame.Position = UDim2.new(0.2, 0, 0.8, 0)
hotbarFrame.BackgroundTransparency = 1
hotbarFrame.Parent = mainFrame

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 12)
hotbarLayout.Parent = hotbarFrame

local hotbarSlots = {}
for i = 1, 9 do
	local slot = Instance.new("Frame")
	slot.Name = "HotbarSlot" .. i
	slot.Size = UDim2.new(0, 55, 0, 55)
	slot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	slot.BorderSizePixel = 2
	slot.BorderColor3 = Color3.fromRGB(120, 120, 120)
	slot.Parent = hotbarFrame

	local hCorner = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, 6)
	hCorner.Parent = slot

	local hLabel = Instance.new("TextLabel")
	hLabel.Name = "Label"
	hLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	hLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	hLabel.Size = UDim2.new(1, -10, 1, -10)
	hLabel.BackgroundTransparency = 1
	hLabel.Text = ""
	hLabel.TextColor3 = Color3.new(1, 1, 1)
	hLabel.TextScaled = true
	hLabel.Font = Enum.Font.Gotham
	hLabel.Parent = slot

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
	countLabel.Position = UDim2.new(1, -8, 1, -8)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = ""
	countLabel.TextColor3 = Color3.new(1, 1, 1)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Parent = slot

	hotbarSlots[i] = { frame = slot, label = hLabel, count = countLabel }
end

local function updateHotbarDisplay()
	for i = 1, 9 do
		local slotData = hotbarSlots[i]
		local item = inventory[i]
		local frame = slotData.frame
		local label = slotData.label
		local countLbl = slotData.count

		if item then
			frame.BackgroundColor3 = BLOCK_DATA[item.name] and BLOCK_DATA[item.name].color or Color3.fromRGB(80, 80, 80)
			label.Text = item.name
			countLbl.Text = item.count > 1 and tostring(item.count) or ""
		else
			frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			label.Text = ""
			countLbl.Text = ""
		end

		local stroke = frame:FindFirstChild("Selected")
		if stroke then
			stroke:Destroy()
		end
		if i == selectedSlot then
			local stroke = Instance.new("UIStroke")
			stroke.Name = "Selected"
			stroke.Color = Color3.new(0, 1, 0)
			stroke.Thickness = 4
			stroke.Parent = frame
		end
	end
end

local function updateCraftingDisplay()
	local flat = flattenGrid()
	local outputItem = matchesRecipe(flat)

	for i = 1, 9 do
		local slotData = gridSlots[i]
		local name = craftingGrid[i]
		if name then
			slotData.frame.BackgroundColor3 = BLOCK_DATA[name] and BLOCK_DATA[name].color or Color3.fromRGB(80, 80, 80)
			slotData.label.Text = name
		else
			slotData.frame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			slotData.label.Text = ""
		end
	end

	if outputItem then
		outputFrame.BackgroundColor3 = BLOCK_DATA[outputItem.name] and BLOCK_DATA[outputItem.name].color
			or Color3.fromRGB(100, 100, 100)
		outputLabel.Text = outputItem.name .. "\nx" .. outputItem.count
	else
		outputFrame.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		outputLabel.Text = ""
	end
end

local function clearCraftingGrid()
	for i = 1, 9 do
		if craftingGrid[i] then
			addToInventory(craftingGrid[i])
			craftingGrid[i] = nil
		end
	end
	updateCraftingDisplay()
end

local menuOpen = false

local function toggleMenu()
	menuOpen = not menuOpen
	mainFrame.Visible = menuOpen
	if menuOpen then
		for i = 1, 9 do
			craftingGrid[i] = nil
		end
		updateCharPreview()
		updateHotbarDisplay()
		updateCraftingDisplay()
		UserInputService.MouseIconEnabled = true
	else
		clearCraftingGrid()
		UserInputService.MouseIconEnabled = false -- Hide cursor outside
	end
end

closeBtn.MouseButton1Click:Connect(toggleMenu)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Escape then
		toggleMenu()
	elseif input.KeyCode.Name:match("One") then
		selectedSlot = 1
	elseif input.KeyCode.Name:match("Two") then
		selectedSlot = 2
	elseif input.KeyCode.Name:match("Three") then
		selectedSlot = 3
	elseif input.KeyCode.Name:match("Four") then
		selectedSlot = 4
	elseif input.KeyCode.Name:match("Five") then
		selectedSlot = 5
	elseif input.KeyCode.Name:match("Six") then
		selectedSlot = 6
	elseif input.KeyCode.Name:match("Seven") then
		selectedSlot = 7
	elseif input.KeyCode.Name:match("Eight") then
		selectedSlot = 8
	elseif input.KeyCode.Name:match("Nine") then
		selectedSlot = 9
	end
	if menuOpen then
		updateHotbarDisplay()
	end
end)

for i = 1, 9 do
	hotbarSlots[i].frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and menuOpen then
			selectedSlot = i
			updateHotbarDisplay()
		end
	end)
end

for i = 1, 9 do
	gridSlots[i].frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and menuOpen then
			local selItem = inventory[selectedSlot]
			if selItem and selItem.count > 0 and not craftingGrid[i] then
				craftingGrid[i] = selItem.name
				selItem.count -= 1
				if selItem.count == 0 then
					inventory[selectedSlot] = nil
				end
				updateHotbarDisplay()
			elseif craftingGrid[i] then
				addToInventory(craftingGrid[i])
				craftingGrid[i] = nil
			end
			updateCraftingDisplay()
		end
	end)
end

outputFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and menuOpen then
		local outputItem = matchesRecipe(flattenGrid())
		if outputItem then
			addToInventory(outputItem.name, outputItem.count)
			clearCraftingGrid()
			updateHotbarDisplay()
		end
	end
end)

updateHotbarDisplay()