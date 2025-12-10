local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function removeForcefield(character)
	wait(0.01)

	local forcefield = character:FindFirstChild("ForceField")
	if forcefield then
		forcefield:Destroy()
	end
end

if player.Character then
	removeForcefield(player.Character)
end

player.CharacterAdded:Connect(removeForcefield)