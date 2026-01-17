-- StarterPlayerScripts/NukeClient (LocalScript)
-- Shows a lobby-only "NUKE ALL" button and plays the nuke flash VFX.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NUKE_PRODUCT_ID = 3515484119
local VFX_DEFAULT_DURATION = 15

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
	Text = "NUKE ALL ☢",
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
local function setButtonVisible()
	btn.Visible = not inMatch
	btn.Active = not inMatch
end

btn.MouseButton1Click:Connect(function()
	if inMatch then return end
	MarketplaceService:PromptProductPurchase(player, NUKE_PRODUCT_ID)
end)

matchState.OnClientEvent:Connect(function(v)
	inMatch = (v == true)
	setButtonVisible()
end)

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

nukeVfxEvent.OnClientEvent:Connect(function(duration)
	task.spawn(function()
		playNukeFlash(duration)
	end)
end)

setButtonVisible()
