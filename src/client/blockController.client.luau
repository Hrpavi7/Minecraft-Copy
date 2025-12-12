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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local breakRemote = remotes:WaitForChild("BreakBlock")
local placeRemote = remotes:WaitForChild("PlaceBlock")

local BLOCK_SIZE = 4
local MAX_DIST = 100

local BLOCK_DATA = {
	Grass = { hardness = 0.5, material = Enum.Material.Grass, color = Color3.fromRGB(102, 153, 0) },
	Dirt = { hardness = 0.7, material = Enum.Material.Mud, color = Color3.fromRGB(139, 69, 19) },
	Stone = { hardness = 1.8, material = Enum.Material.Rock, color = Color3.fromRGB(112, 112, 112) },
	Wood = { hardness = 1.2, material = Enum.Material.Wood, color = Color3.fromRGB(162, 87, 0) },
}

local inventory = _G.MyInventory
	or {
		{ name = "Grass", count = 64 },
		{ name = "Dirt", count = 64 },
		{ name = "Stone", count = 64 },
		{ name = "Wood", count = 64 },
		{ name = "Stone", count = 64 },
	}
local selectedSlot = 1

local previewPart = nil
local breaking = false
local breakStartTime = 0
local breakTarget = nil
local lastHit = nil
local mouseDown = false
local lastMousePos = nil
local sensitivity = 0.2

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinecraftGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local crosshair = Instance.new("TextLabel")
crosshair.Size = UDim2.new(0, 40, 0, 40)
crosshair.Position = UDim2.new(0.5, -20, 0.5, -20)
crosshair.BackgroundTransparency = 1
crosshair.Text = "+"
crosshair.TextColor3 = Color3.new(1, 1, 1)
crosshair.TextScaled = true
crosshair.Font = Enum.Font.Code
crosshair.Visible = false
crosshair.ZIndex = 10
crosshair.Parent = screenGui

local breakLabel = Instance.new("TextLabel")
breakLabel.Name = "BreakLabel"
breakLabel.Size = UDim2.new(0, 220, 0, 30)
breakLabel.Position = UDim2.new(0, 20, 0, 20)
breakLabel.BackgroundTransparency = 1
breakLabel.TextColor3 = Color3.new(1, 1, 1)
breakLabel.TextScaled = true
breakLabel.Font = Enum.Font.SourceSansBold
breakLabel.Text = ""
breakLabel.Visible = false
breakLabel.Parent = screenGui

local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "Hotbar"
hotbarFrame.Size = UDim2.new(0, 400, 0, 60)
hotbarFrame.Position = UDim2.new(0.5, -200, 1, -80)
hotbarFrame.BackgroundColor3 = Color3.new(0, 0, 0)
hotbarFrame.BackgroundTransparency = 0.5
hotbarFrame.Parent = screenGui

local function createSlot(i)
	local slotFrame = Instance.new("Frame")
	slotFrame.Name = "Slot" .. i
	slotFrame.Size = UDim2.new(0, 45, 0, 45)
	slotFrame.Position = UDim2.new(0, (i - 1) * 46 + 4, 0.5, -22.5)
	slotFrame.BackgroundTransparency = 1
	slotFrame.Parent = hotbarFrame

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	bg.BorderSizePixel = 2
	bg.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
	bg.Parent = slotFrame

	local numLabel = Instance.new("TextLabel")
	numLabel.Name = "NumLabel"
	numLabel.Size = UDim2.new(1, 0, 0.4, 0)
	numLabel.Position = UDim2.new(0, 0, 0.6, 0)
	numLabel.BackgroundTransparency = 1
	numLabel.Text = tostring(i)
	numLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	numLabel.TextScaled = true
	numLabel.Font = Enum.Font.SourceSans
	numLabel.Parent = slotFrame
end

for i = 1, 9 do
	createSlot(i)
end

local function snapToGrid(pos)
	return Vector3.new(
		math.round(pos.X / BLOCK_SIZE) * BLOCK_SIZE,
		math.round(pos.Y / BLOCK_SIZE) * BLOCK_SIZE,
		math.round(pos.Z / BLOCK_SIZE) * BLOCK_SIZE
	)
end

local function getRayResult()
	local origin = camera.CFrame.Position

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local filters = {}
	if player.Character then
		table.insert(filters, player.Character)
	end
	if previewPart then
		table.insert(filters, previewPart)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filters

	return workspace:Raycast(ray.Origin, ray.Direction * MAX_DIST, params)
end

local function updateSelectedVisual()
	for i = 1, 9 do
		local slot = hotbarFrame:FindFirstChild("Slot" .. i)
		if not slot then
			continue
		end

		local oldStroke = slot:FindFirstChild("SelectedStroke")
		if oldStroke then
			oldStroke:Destroy()
		end

		local item = inventory[i]
		local bg = slot.BG
		local label = slot:FindFirstChild("ItemLabel")

		if not label then
			label = Instance.new("TextLabel")
			label.Name = "ItemLabel"
			label.Size = UDim2.new(1, -10, 1, -10)
			label.Position = UDim2.new(0, 5, 0, 5)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Top
			label.Parent = slot
		end

		if item and item.name then
			local blockName = item.name
			bg.BackgroundColor3 = BLOCK_DATA[blockName] and BLOCK_DATA[blockName].color or Color3.fromRGB(80, 80, 80)
			label.Text = blockName .. (item.count > 1 and "\n" .. item.count or "")
		else
			bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			label.Text = ""
		end
	end

	local selSlot = hotbarFrame:FindFirstChild("Slot" .. selectedSlot)
	if selSlot then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "SelectedStroke"
		stroke.Color = Color3.new(1, 1, 0)
		stroke.Thickness = 4
		stroke.Parent = selSlot
	end
end

updateSelectedVisual()

local function updatePreviewAndBreakLogic()
	local result = getRayResult()

	if result then
		local hitBlockPos = snapToGrid(result.Instance.Position)
		lastHit = { pos = hitBlockPos, normal = result.Normal }

		local selectedItem = inventory[selectedSlot]
		local selectedBlockName = selectedItem and selectedItem.name

		if selectedBlockName and BLOCK_DATA[selectedBlockName] then
			local placePos = snapToGrid(hitBlockPos + result.Normal * BLOCK_SIZE)

			if not previewPart then
				previewPart = Instance.new("Part")
				previewPart.Name = "BlockPreview"
				previewPart.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
				previewPart.Anchored = true
				previewPart.CanCollide = false
				previewPart.Shape = Enum.PartType.Block
				previewPart.Parent = workspace

				-- UN COMMENT IF YOU WANT A SELECTION BOX AROUND THE BLOCK PREVIEW

				--	local selectionBox = Instance.new("SelectionBox")
				--	selectionBox.Adornee = previewPart
				--	selectionBox.Color3 = Color3.fromRGB(0, 255, 255)
				--	selectionBox.LineThickness = 0.05
				--	selectionBox.Transparency = 0.5
				--	selectionBox.Parent = previewPart
			end

			previewPart.Transparency = 0.6
			previewPart.Material = BLOCK_DATA[selectedBlockName].material
			previewPart.Color = BLOCK_DATA[selectedBlockName].color
			previewPart.Position = placePos
		else
			if previewPart then
				previewPart:Destroy()
				previewPart = nil
			end
		end

		if breaking and breakTarget and hitBlockPos == breakTarget and BLOCK_DATA[result.Instance.Name] then
			local hardness = BLOCK_DATA[result.Instance.Name].hardness
			local progress = math.min((tick() - breakStartTime) / hardness, 1)

			breakLabel.Visible = true
			breakLabel.Text = string.format("Breaking %s (%.0f%%)", result.Instance.Name, progress * 100)

			if progress >= 1 then
				breakRemote:FireServer(breakTarget)
				breaking = false
				breakTarget = nil
				breakLabel.Visible = false
			end
		else
			breakLabel.Visible = false
			if breaking then
				breaking = false
				breakTarget = nil
			end
		end
	else
		lastHit = nil
		if previewPart then
			previewPart:Destroy()
			previewPart = nil
		end
		breakLabel.Visible = false
		breaking = false
		breakTarget = nil
	end
end

local function updateCamera()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local rootPos = player.Character.HumanoidRootPart.Position
		local camDist = (camera.CFrame.Position - rootPos).Magnitude
		local isFirstPerson = (camDist < 1.5) or (player.CameraMode == Enum.CameraMode.LockFirstPerson)
		crosshair.Visible = isFirstPerson
	end

	if not mouseDown then
		return
	end

	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		return
	end

	local currentMousePos = UserInputService:GetMouseLocation()
	if lastMousePos then
		local delta = currentMousePos - lastMousePos
		camera.CFrame = camera.CFrame * CFrame.Angles(0, -math.rad(delta.X * sensitivity), 0)
		camera.CFrame = camera.CFrame * CFrame.Angles(-math.rad(delta.Y * sensitivity), 0, 0)
	end
	lastMousePos = currentMousePos
end

RunService.RenderStepped:Connect(updateCamera)
RunService.Heartbeat:Connect(updatePreviewAndBreakLogic)

local slotKeys = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if slotKeys[input.KeyCode] then
		selectedSlot = slotKeys[input.KeyCode]
		updateSelectedVisual()
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local result = getRayResult()

		if result and result.Instance and BLOCK_DATA[result.Instance.Name] then
			breakTarget = snapToGrid(result.Instance.Position)
			breakStartTime = tick()
			breaking = true
		else
			mouseDown = true
			lastMousePos = UserInputService:GetMouseLocation()
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local selectedItem = inventory[selectedSlot]
		if selectedItem and selectedItem.name and lastHit then
			local placePos = snapToGrid(lastHit.pos + lastHit.normal * BLOCK_SIZE)

			placeRemote:FireServer(selectedItem.name, placePos)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		breaking = false
		breakTarget = nil
		breakLabel.Visible = false

		mouseDown = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

mouse.WheelForward:Connect(function()
	selectedSlot = selectedSlot == 1 and 9 or selectedSlot - 1
	updateSelectedVisual()
end)

mouse.WheelBackward:Connect(function()
	selectedSlot = selectedSlot == 9 and 1 or selectedSlot + 1
	updateSelectedVisual()
end)

player.CharacterRemoving:Connect(function()
	if previewPart then
		previewPart:Destroy()
	end
end)
