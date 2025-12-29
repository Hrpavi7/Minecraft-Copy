local Players = game:GetService("Players")

local DAMAGE_THRESHOLD = 10
local DAMAGE_MULTIPLIER = 5

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	local lastGroundedY = nil
	local maxFallDistance = 0

	humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if humanoid.FloorMaterial == Enum.Material.Air then
			if lastGroundedY == nil then
				lastGroundedY = rootPart.Position.Y
			end
		else
			if lastGroundedY then
				local fallDistance = lastGroundedY - rootPart.Position.Y

				if fallDistance > maxFallDistance then
					maxFallDistance = fallDistance
				end

				if maxFallDistance > DAMAGE_THRESHOLD then
					local damage = math.floor((maxFallDistance - DAMAGE_THRESHOLD) * DAMAGE_MULTIPLIER)
					humanoid:TakeDamage(damage)
				end

				lastGroundedY = nil
				maxFallDistance = 0
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end)
