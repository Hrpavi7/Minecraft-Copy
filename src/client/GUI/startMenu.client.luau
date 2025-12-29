local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local UI_CONFIG = {
	Title = "ROBLOX CRAFT",
	Font = Enum.Font.Arcade,
	ButtonColor = Color3.fromRGB(100, 100, 100),
	TextColor = Color3.fromRGB(255, 255, 255),
	BackgroundColor = Color3.fromRGB(0, 0, 0),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinecraftMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 20
blurEffect.Parent = Lighting

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = UI_CONFIG.BackgroundColor
mainFrame.BackgroundTransparency = 0.3
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = UI_CONFIG.Title
titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = UI_CONFIG.TextColor
titleLabel.TextSize = 80
titleLabel.Font = UI_CONFIG.Font
titleLabel.Parent = mainFrame
titleLabel.TextStrokeTransparency = 0.5

local menuContainer = Instance.new("Frame")
menuContainer.Size = UDim2.new(0.3, 0, 0.5, 0)
menuContainer.Position = UDim2.new(0.35, 0, 0.4, 0)
menuContainer.BackgroundTransparency = 1
menuContainer.Parent = mainFrame

local settingsContainer = Instance.new("Frame")
settingsContainer.Size = UDim2.new(0.4, 0, 0.6, 0)
settingsContainer.Position = UDim2.new(0.3, 0, 0.3, 0)
settingsContainer.BackgroundTransparency = 0.5
settingsContainer.BackgroundColor3 = Color3.new(0, 0, 0)
settingsContainer.Visible = false
settingsContainer.Parent = mainFrame

local function createButton(text, layoutOrder, parent)
	local btn = Instance.new("TextButton")
	btn.Text = text
	btn.Size = UDim2.new(1, 0, 0.15, 0)
	btn.Position = UDim2.new(0, 0, 0.2 * layoutOrder, 0)
	btn.BackgroundColor3 = UI_CONFIG.ButtonColor
	btn.TextColor3 = UI_CONFIG.TextColor
	btn.Font = UI_CONFIG.Font
	btn.TextSize = 25
	btn.BorderSizePixel = 4
	btn.BorderColor3 = Color3.fromRGB(50, 50, 50)
	btn.Parent = parent
	return btn
end

local playBtn = createButton("PLAY GAME", 0, menuContainer)
local settingsBtn = createButton("SETTINGS", 1, menuContainer)
local quitBtn = createButton("QUIT", 2, menuContainer) -- Visual only for this example

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Text = "OPTIONS"
settingsTitle.Size = UDim2.new(1, 0, 0.15, 0)
settingsTitle.BackgroundTransparency = 1
settingsTitle.TextColor3 = UI_CONFIG.TextColor
settingsTitle.Font = UI_CONFIG.Font
settingsTitle.TextSize = 35
settingsTitle.Parent = settingsContainer

local function createSlider(name, yPos, defaultVal, minVal, maxVal, callback)
	local label = Instance.new("TextLabel")
	label.Text = name .. ": " .. defaultVal
	label.Size = UDim2.new(1, 0, 0.1, 0)
	label.Position = UDim2.new(0, 0, yPos, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = UI_CONFIG.Font
	label.TextSize = 20
	label.Parent = settingsContainer

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(0.8, 0, 0.05, 0)
	sliderBg.Position = UDim2.new(0.1, 0, yPos + 0.1, 0)
	sliderBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	sliderBg.Parent = settingsContainer

	local sliderBtn = Instance.new("TextButton")
	sliderBtn.Text = ""
	sliderBtn.Size = UDim2.new(0.05, 0, 1.5, 0)
	sliderBtn.Position = UDim2.new(0.5, 0, -0.25, 0) -- Start middle
	sliderBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	sliderBtn.Parent = sliderBg

	local dragging = false

	sliderBtn.MouseButton1Down:Connect(function()
		dragging = true
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	RunService.RenderStepped:Connect(function()
		if dragging then
			local mousePos = UserInputService:GetMouseLocation().X
			local relativePos = mousePos - sliderBg.AbsolutePosition.X
			local percentage = math.clamp(relativePos / sliderBg.AbsoluteSize.X, 0, 1)
			sliderBtn.Position = UDim2.new(percentage, -sliderBtn.AbsoluteSize.X / 2, -0.25, 0)

			local value = math.floor(minVal + (maxVal - minVal) * percentage)
			label.Text = name .. ": " .. value
			callback(value)
		end
	end)
end

createSlider("SENSITIVITY", 0.2, 1, 0, 50, function(val)
	local realSens = val / 10
	if realSens <= 0 then
		realSens = 0.1
	end
	UserInputService.MouseDeltaSensitivity = realSens
end)

createSlider("FOV", 0.45, 70, 70, 120, function(val)
	camera.FieldOfView = val
end)

local backBtn = createButton("DONE", 4, settingsContainer)

local function freezePlayer(frozen)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	if frozen then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		rootPart.Anchored = true
		UserInputService.MouseIconEnabled = true
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		rootPart.Anchored = false
		UserInputService.MouseIconEnabled = false
	end
end

freezePlayer(true)

playBtn.MouseButton1Click:Connect(function()
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 1 })
	tween:Play()

	menuContainer.Visible = false
	titleLabel.Visible = false

	TweenService:Create(blurEffect, tweenInfo, { Size = 0 }):Play()

	task.wait(1)
	screenGui.Enabled = false
	freezePlayer(false)
end)

settingsBtn.MouseButton1Click:Connect(function()
	menuContainer.Visible = false
	settingsContainer.Visible = true
end)

backBtn.MouseButton1Click:Connect(function()
	settingsContainer.Visible = false
	menuContainer.Visible = true
end)

quitBtn.MouseButton1Click:Connect(function()
	player:Kick("You quit the game!")
end)
