-- StarterPlayerScripts/NukeClient (LocalScript)
-- Plays the nuke flash VFX when the server fires NukeVFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VFX_DEFAULT_DURATION = 10
local VFX_DARK_DEFAULT = 5

local nukeVfxEvent = ReplicatedStorage:WaitForChild("NukeVFX")

local function mk(parent, class, props)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local old = playerGui:FindFirstChild("NukeVfxGui")
if old then old:Destroy() end

local gui = mk(playerGui, "ScreenGui", {
	Name = "NukeVfxGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = true,
	DisplayOrder = 200,
})

local flash = mk(gui, "Frame", {
	Name = "NukeFlash",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(255, 200, 80),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 200,
})

local function playNukeFlash(duration)
	local total = tonumber(duration) or VFX_DEFAULT_DURATION
	total = math.max(1, total)

	flash.Visible = true
	flash.BackgroundTransparency = 1

	local flashIn = TweenService:Create(
		flash,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.2 }
	)
	local flashOut = TweenService:Create(
		flash,
		TweenInfo.new(total, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)

	flashIn:Play()
	flashIn.Completed:Wait()
	flashOut:Play()
	flashOut.Completed:Wait()

	flash.Visible = false
end

local function playNukeDarkPhase(duration)
	local total = tonumber(duration) or VFX_DARK_DEFAULT
	total = math.max(0.5, total)

	local effect = Lighting:FindFirstChild("NukeDarkEffect")
	if not effect then
		effect = Instance.new("ColorCorrectionEffect")
		effect.Name = "NukeDarkEffect"
		effect.Parent = Lighting
	end

	effect.Enabled = true
	effect.Brightness = -0.3
	effect.Contrast = 0.5
	effect.Saturation = -0.2
	effect.TintColor = Color3.fromRGB(120, 110, 90)

	local tween = TweenService:Create(
		effect,
		TweenInfo.new(total, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Brightness = -0.6, Contrast = 0.8, Saturation = -0.4 }
	)
	tween:Play()
	tween.Completed:Wait()
end

local function clearNukeDarkPhase()
	local effect = Lighting:FindFirstChild("NukeDarkEffect")
	if not effect then return end
	local tween = TweenService:Create(
		effect,
		TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255) }
	)
	tween:Play()
	tween.Completed:Wait()
	effect:Destroy()
end

nukeVfxEvent.OnClientEvent:Connect(function(payload)
	local darkDuration = VFX_DARK_DEFAULT
	local flashDuration = VFX_DEFAULT_DURATION

	if typeof(payload) == "table" then
		darkDuration = tonumber(payload.darkDuration) or darkDuration
		flashDuration = tonumber(payload.flashDuration) or flashDuration
	elseif tonumber(payload) then
		flashDuration = tonumber(payload)
	end

	task.spawn(function()
		playNukeDarkPhase(darkDuration)
		playNukeFlash(flashDuration)
		clearNukeDarkPhase()
	end)
end)
