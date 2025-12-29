local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TerrainEvents = ReplicatedStorage:WaitForChild("TerrainEvents")
local InitialLoadProgress = TerrainEvents:WaitForChild("InitialLoadProgress")

local loadingScreen = Instance.new("ScreenGui")
loadingScreen.Name = "InitialLoadingScreen"
loadingScreen.ResetOnSpawn = false

loadingScreen.DisplayOrder = 100
loadingScreen.Parent = playerGui

local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
bgFrame.BorderSizePixel = 0
bgFrame.Parent = loadingScreen

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "LOADING..."
titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
titleLabel.Position = UDim2.new(0, 0, 0.4, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.Code
titleLabel.TextSize = 30
titleLabel.TextStrokeTransparency = 0.8
titleLabel.Parent = bgFrame

local barContainer = Instance.new("Frame")
barContainer.Size = UDim2.new(0.6, 0, 0.05, 0)
barContainer.Position = UDim2.new(0.2, 0, 0.55, 0)
barContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
barContainer.BorderSizePixel = 2
barContainer.BorderColor3 = Color3.fromRGB(255, 255, 255)
barContainer.Parent = bgFrame

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
barFill.BorderSizePixel = 0
barFill.Parent = barContainer

local percentLabel = Instance.new("TextLabel")
percentLabel.Text = "0%"
percentLabel.Size = UDim2.new(1, 0, 1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
percentLabel.Font = Enum.Font.Code
percentLabel.TextStrokeTransparency = 0.5
percentLabel.Parent = barContainer

local function updateProgress(progress)
	progress = math.max(0, math.min(1, progress))

	barFill:TweenSize(UDim2.new(progress, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)

	percentLabel.Text = math.floor(progress * 100) .. "%"

	if progress >= 1 then
		local fadeTime = 1.5
		local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		if not player.Character then
			player.CharacterAdded:Wait()
		end

		TweenService:Create(bgFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(titleLabel, tweenInfo, { TextTransparency = 1 }):Play()
		TweenService
			:Create(barContainer, tweenInfo, { BackgroundTransparency = 1, BorderColor3 = Color3.fromRGB(0, 0, 0) })
			:Play()
		TweenService:Create(barFill, tweenInfo, { BackgroundTransparency = 1 }):Play()

		local textTween = TweenService:Create(percentLabel, tweenInfo, { TextTransparency = 1 })

		textTween.Completed:Connect(function()
			loadingScreen:Destroy()
		end)

		textTween:Play()
	end
end

InitialLoadProgress.OnClientEvent:Connect(updateProgress)
