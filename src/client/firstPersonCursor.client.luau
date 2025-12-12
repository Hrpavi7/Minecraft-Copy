local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function updateCursorVisibility()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		UserInputService.MouseIconEnabled = true -- Default safe
		return
	end

	local rootPos = player.Character.HumanoidRootPart.Position
	local camDistance = (camera.CFrame.Position - rootPos).Magnitude
	local isFirstPerson = (camDistance < 2) or (player.CameraMode == Enum.CameraMode.LockFirstPerson)

	UserInputService.MouseIconEnabled = not isFirstPerson

	if not isFirstPerson then
		player:GetMouse().Icon = ""
	end
end

RunService.Heartbeat:Connect(updateCursorVisibility)

local function onCharacterAdded(character)
	wait(0.1)
	updateCursorVisibility()
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)