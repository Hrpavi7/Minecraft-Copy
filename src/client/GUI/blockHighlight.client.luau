local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Configuration
local BLOCK_SIZE = 4 -- Must match your terrain generation script size

local highlight = Instance.new("Highlight")
highlight.Name = "BlockHighlight"
highlight.FillTransparency = 1 -- Only show outline
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.OutlineTransparency = 0.2
highlight.DepthMode = Enum.HighlightDepthMode.Occluded -- Can be set to AlwaysOnTop if you want to see it through walls
highlight.Parent = workspace

local currentTarget = nil
local blinkPhase = 0

RunService.Heartbeat:Connect(function(dt)
	blinkPhase += dt * 8

	local target = mouse.Target

	if
		target
		and target:IsA("BasePart")
		and target.Size.X == BLOCK_SIZE
		and target.Anchored
		and target.Transparency < 1
		and not player.Character:IsAncestorOf(target)
	then
		if target ~= currentTarget then
			currentTarget = target
			highlight.Adornee = target
		end
		highlight.OutlineTransparency = 0.2 + (math.sin(blinkPhase) + 1) / 2 * 0.6
	else
		if currentTarget then
			highlight.Adornee = nil
			currentTarget = nil
		end
	end
end)
