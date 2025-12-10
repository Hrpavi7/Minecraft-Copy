-- 🖱️ CURSOR VISIBILITY TOGGLE (First Person: INVISIBLE | Third Person: VISIBLE)
-- NEW LocalScript for StarterPlayer > StarterPlayerScripts
-- ✅ Auto-detects F5 toggle / camera changes
-- ✅ Perfect for Minecraft clone (invisible FPS cursor, visible third person drag-look)
-- ✅ Respawn-safe + 60fps smooth updates
-- ✅ NO CONFLICTS with your BlockController (remove `mouse.Icon = ""` line if present)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function updateCursorVisibility()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		UserInputService.MouseIconEnabled = true  -- Default safe
		return
	end

	-- Detect First Person (distance < 2 studs OR LockFirstPerson mode)
	local rootPos = player.Character.HumanoidRootPart.Position
	local camDistance = (camera.CFrame.Position - rootPos).Magnitude
	local isFirstPerson = (camDistance < 2) or (player.CameraMode == Enum.CameraMode.LockFirstPerson)

	-- INVISIBLE in First Person | VISIBLE in Third Person
	UserInputService.MouseIconEnabled = not isFirstPerson

	-- Optional: Set default cursor icon in third person (Minecraft-y arrow/gun)
	if not isFirstPerson then
		player:GetMouse().Icon = ""  -- Roblox default (arrow or gun cursor)
	end
end

-- Update every frame (instant response to F5)
RunService.Heartbeat:Connect(updateCursorVisibility)

-- Respawn safe
local function onCharacterAdded(character)
	wait(0.1)  -- Let camera settle
	updateCursorVisibility()
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

print("👁️ Cursor Toggle LOADED! F5 test: First=invisible, Third=visible")