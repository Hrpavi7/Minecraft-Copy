local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local COLOR_PALETTE = {
	DaySky = Color3.fromRGB(150, 200, 255),
	DayFog = Color3.fromRGB(180, 220, 255),
	Ambient = Color3.fromRGB(100, 100, 100),
}

local function applyLightingSettings()
	Lighting.Brightness = 1.2
	Lighting.OutdoorAmbient = COLOR_PALETTE.Ambient
	Lighting.Ambient = COLOR_PALETTE.Ambient
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.2
	Lighting.GeographicLatitude = 20
	Lighting.Technology = Enum.Technology.Future
end

local function setupPostProcessing()
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Saturation = 0.2
	colorCorrection.Contrast = 0.1
	colorCorrection.Brightness = 0.05
	colorCorrection.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.0
	bloom.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.2
	atmosphere.Offset = 0
	atmosphere.Haze = 0.5
	atmosphere.Color = COLOR_PALETTE.DayFog
	atmosphere.Decay = Color3.fromRGB(1, 1, 1)
	atmosphere.Parent = Lighting
end

local function applyShaders()
	applyLightingSettings()
	setupPostProcessing()
end

applyShaders()