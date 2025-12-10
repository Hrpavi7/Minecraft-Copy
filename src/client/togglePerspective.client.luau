-- 🔄 FIXED Third Person Toggle (F5) - Works MULTIPLE TIMES!
-- LocalScript for StarterPlayer > StarterPlayerScripts
-- ✅ Toggles First ↔ LOCKED Third Person (fixed distance like Minecraft)
-- ✅ ContextActionService = Bypasses Studio F5 conflicts!
-- ✅ Respawn-safe + Snaps camera instantly
-- ✅ Test: Play → F5 spam! (Studio: May need published game for perfect F5)

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")  -- Fallback

local player = Players.LocalPlayer

local isThirdPerson = true  -- Start in third (Minecraft default)
local thirdDistance = 16  -- Fixed third person distance (tweak 12-24 for feel)

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

-- Setup on spawn/respawn
local function onCharacterAdded(character)
	wait(0.2)  -- Let camera init
	setCameraMode()
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- PRIMARY: ContextActionService (sinks F5, works in Studio/game)
ContextActionService:BindAction("ToggleCamera", function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		isThirdPerson = not isThirdPerson
		setCameraMode()
	end
end, false, Enum.KeyCode.F5)

-- FALLBACK: UserInputService (if CAS fails in rare cases)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F5 then
		isThirdPerson = not isThirdPerson
		setCameraMode()
	end
end)

print("🎮 F5 Toggle loaded! Spam F5 to test.")