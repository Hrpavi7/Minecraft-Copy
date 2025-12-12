local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local isThirdPerson = false
local thirdDistance = 16

local function setThirdPerson()
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = thirdDistance
	player.CameraMaxZoomDistance = thirdDistance
end

local function setFirstPerson()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

local function setCameraMode()
	if isThirdPerson then
		setThirdPerson()
	else
		setFirstPerson()
	end
end

local function onCharacterAdded(character)
	-- Wait slightly to ensure the character's camera properties are ready
	task.wait(0.2)
	setCameraMode()
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

ContextActionService:BindAction("ToggleCamera", function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		isThirdPerson = not isThirdPerson
		setCameraMode()
	end
end, false, Enum.KeyCode.F5)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F5 then
		isThirdPerson = not isThirdPerson
		setCameraMode()
	end
end)
