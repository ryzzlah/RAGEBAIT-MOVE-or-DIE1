-- StarterPlayerScripts/NukeClient (LocalScript)
-- Shows a lobby-only "NUKE ALL" button and plays the nuke flash VFX.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NUKE_PRODUCT_ID = 3515484119
local VFX_DEFAULT_DURATION = 10
local VFX_DARK_DEFAULT = 5

local matchState = ReplicatedStorage:WaitForChild("MatchState")
local nukeVfxEvent = ReplicatedStorage:WaitForChild("NukeVFX")

local function mk(parent, class, props)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local old = playerGui:FindFirstChild("NukeGui")
if old then old:Destroy() end

local gui = mk(playerGui, "ScreenGui", {
	Name = "NukeGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = true,
	DisplayOrder = 110,
})

local btn = mk(gui, "TextButton", {
	Name = "NukeButton",
	Text = "NUKE ALL!",
	Size = UDim2.new(0, 140, 0, 38),
	Position = UDim2.new(0, 20, 0.5, -140),
	BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = true,
	ZIndex = 5,
})
mk(btn, "UICorner", { CornerRadius = UDim.new(0, 10) })
mk(btn, "UIStroke", { Thickness = 1, Color = Color3.fromRGB(235, 150, 65), Transparency = 0 })


local function isMobile()
	return UserInputService.TouchEnabled
end

local function positionNukeButton()
	local mobile = isMobile()

	local shopGui = playerGui:FindFirstChild("ShopGui")
	local shopBtn = shopGui and shopGui:FindFirstChild("ShopButton")
	local coinsGui = playerGui:FindFirstChild("CoinsHUD")
	local coinsFrame = coinsGui and coinsGui:FindFirstChildWhichIsA("Frame")

	if mobile and shopBtn and coinsFrame then
		local shopCenterY = shopBtn.AbsolutePosition.Y + (shopBtn.AbsoluteSize.Y / 2)
		local coinsCenterY = coinsFrame.AbsolutePosition.Y + (coinsFrame.AbsoluteSize.Y / 2)
		local midY = (shopCenterY + coinsCenterY) / 2
		local x = shopBtn.AbsolutePosition.X

		btn.AnchorPoint = Vector2.new(0, 0)
		btn.Position = UDim2.new(0, x, 0, math.floor(midY - (btn.AbsoluteSize.Y / 2)))
		return
	end

	if (not mobile) and shopBtn then
		btn.AnchorPoint = Vector2.new(0, 1)
		btn.Position = UDim2.new(0, shopBtn.AbsolutePosition.X, 0, shopBtn.AbsolutePosition.Y - 6)
		return
	end

	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.Position = UDim2.new(0.5, 0, 0, 110)
end

positionNukeButton()
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(positionNukeButton)
UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(positionNukeButton)
playerGui.ChildAdded:Connect(function()
	task.defer(positionNukeButton)
end)
task.defer(positionNukeButton)
task.delay(1, positionNukeButton)

local flash = mk(gui, "Frame", {
	Name = "NukeFlash",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(255, 200, 80),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 200,
})

local inMatch = false
local function canShowInMatch()
	return player:GetAttribute("AliveInRound") == false
end

local function setButtonVisible()
	local show = (not inMatch) or canShowInMatch()
	btn.Visible = show
	btn.Active = show
end

btn.MouseButton1Click:Connect(function()
	if inMatch then return end
	MarketplaceService:PromptProductPurchase(player, NUKE_PRODUCT_ID)
end)

matchState.OnClientEvent:Connect(function(v)
	inMatch = (v == true)
	setButtonVisible()
end)

player:GetAttributeChangedSignal("AliveInRound"):Connect(setButtonVisible)

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

setButtonVisible()
