-- StarterPlayerScripts/AdminUI.lua
-- Simple admin panel (purple accent) for moderation and testing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ADMIN_USER_IDS = {
	[1676263675] = true, -- you
	-- add more userIds here
}

if not ADMIN_USER_IDS[player.UserId] then
	return
end

local AdminAction = ReplicatedStorage:WaitForChild("AdminAction")
local AdminGetCatalog = ReplicatedStorage:WaitForChild("AdminGetCatalog")

local ACCENT = Color3.fromRGB(170, 80, 255)
local PANEL_BG = Color3.fromRGB(18, 18, 22)
local TOP_BG = Color3.fromRGB(14, 14, 18)
local BTN = Color3.fromRGB(42, 42, 52)
local BTN_DIM = Color3.fromRGB(32, 32, 40)
local BTN_STROKE = Color3.fromRGB(80, 80, 95)

local function mk(parent, class, props)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end

local function clear(container, className)
	for _, c in ipairs(container:GetChildren()) do
		if not className or c:IsA(className) then
			c:Destroy()
		end
	end
end

local old = playerGui:FindFirstChild("AdminGui")
if old then old:Destroy() end

local gui = mk(playerGui, "ScreenGui", {
	Name = "AdminGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = true,
	DisplayOrder = 120,
})

local btn = mk(gui, "TextButton", {
	Name="AdminButton",
	Text="ADMIN",
	Size=UDim2.new(0,140,0,44),
	Position = UDim2.new(0, 20, 0.5, -78),
	BackgroundColor3=BTN,
	TextColor3=Color3.fromRGB(255,255,255),
	TextScaled=true,
	Font=Enum.Font.GothamBold,
	AutoButtonColor=true,
	ZIndex = 5,
})
mk(btn, "UICorner", {CornerRadius=UDim.new(0,10)})
mk(btn, "UIStroke", {Thickness=1, Color=ACCENT, Transparency=0})

local overlay = mk(gui, "TextButton", {
	Name="Overlay",
	Size=UDim2.new(1,0,1,0),
	BackgroundColor3=Color3.fromRGB(0,0,0),
	BackgroundTransparency=0.45,
	Text="",
	Visible=false,
	AutoButtonColor=false,
	ZIndex=10
})

local PANEL_W, PANEL_H = 720, 420
local panel = mk(gui, "Frame", {
	Name="AdminPanel",
	Size=UDim2.new(0,PANEL_W,0,PANEL_H),
	Position=UDim2.new(0.5,-PANEL_W/2,0.5,-PANEL_H/2),
	BackgroundColor3=PANEL_BG,
	BorderSizePixel=0,
	Visible=false,
	ZIndex=20
})
mk(panel, "UICorner", {CornerRadius=UDim.new(0,16)})
mk(panel, "UIStroke", {Thickness=2, Color=Color3.fromRGB(45,45,55), Transparency=0})

local top = mk(panel, "Frame", {
	Size=UDim2.new(1,0,0,54),
	BackgroundColor3=TOP_BG,
	BorderSizePixel=0,
	ZIndex=21,
})
mk(top, "UICorner", {CornerRadius=UDim.new(0,16)})
mk(top, "Frame", {
	Size=UDim2.new(1,0,0.5,0),
	Position=UDim2.new(0,0,0.5,0),
	BackgroundColor3=TOP_BG,
	BorderSizePixel=0,
	ZIndex=21,
})
mk(panel, "Frame", {
	Size=UDim2.new(1,0,0,2),
	Position=UDim2.new(0,0,0,54),
	BackgroundColor3=ACCENT,
	BorderSizePixel=0,
	ZIndex=21
})

mk(top, "TextLabel", {
	Size=UDim2.new(1,-110,1,0),
	Position=UDim2.new(0,16,0,0),
	BackgroundTransparency=1,
	Text="Admin Panel",
	TextXAlignment=Enum.TextXAlignment.Left,
	TextScaled=true,
	Font=Enum.Font.GothamBold,
	TextColor3=Color3.fromRGB(255,255,255),
	ZIndex=22
})

local closeBtn = mk(top, "TextButton", {
	Size=UDim2.new(0,34,0,34),
	Position=UDim2.new(1,-50,0.5,-17),
	BackgroundColor3=ACCENT,
	Text="",
	AutoButtonColor=true,
	ZIndex=22
})
mk(closeBtn, "UICorner", {CornerRadius=UDim.new(1,0)})
mk(closeBtn, "UIStroke", {Thickness=1, Color=Color3.fromRGB(90,20,90), Transparency=0})
mk(closeBtn, "TextLabel", {
	BackgroundTransparency=1,
	Size=UDim2.new(1,0,1,0),
	Text="X",
	Font=Enum.Font.GothamBold,
	TextScaled=true,
	TextColor3=Color3.fromRGB(255,255,255)
})

local tabs = mk(panel, "Frame", {
	Size=UDim2.new(1,-32,0,38),
	Position=UDim2.new(0,16,0,68),
	BackgroundTransparency=1,
	ZIndex=21
})
local tabLayout = mk(tabs, "UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0,10),
})
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function makeTab(text)
	local b = mk(tabs, "TextButton", {
		Size=UDim2.new(0,140,1,0),
		Text=text,
		BackgroundColor3=BTN_DIM,
		TextColor3=Color3.fromRGB(230,230,230),
		TextScaled=true,
		Font=Enum.Font.GothamBold,
		ZIndex=22
	})
	mk(b, "UICorner", {CornerRadius=UDim.new(0,10)})
	mk(b, "UIStroke", {Thickness=1, Color=BTN_STROKE, Transparency=0})
	return b
end

local playersTabBtn = makeTab("Players")
local itemsTabBtn = makeTab("Give Items")
local selfTabBtn = makeTab("Self")

local content = mk(panel, "Frame", {
	Size=UDim2.new(1,-32,1,-120),
	Position=UDim2.new(0,16,0,110),
	BackgroundTransparency=1,
	ZIndex=21
})

local function makeSection(name)
	local f = mk(content, "Frame", {
		Name = name,
		Size=UDim2.new(1,0,1,0),
		BackgroundTransparency=1,
		Visible=false,
		ZIndex=21
	})
	return f
end

local playersSection = makeSection("PlayersSection")
local itemsSection = makeSection("ItemsSection")
local selfSection = makeSection("SelfSection")

local selectedUserId: number? = nil
local selectedItemId: string? = nil
local selectedCategory: string? = "Trails"

local function setTab(tabName)
	playersSection.Visible = (tabName == "Players")
	itemsSection.Visible = (tabName == "Items")
	selfSection.Visible = (tabName == "Self")
end

local function styleTab(btnRef, active)
	local st = btnRef:FindFirstChildOfClass("UIStroke")
	btnRef.BackgroundColor3 = active and BTN or BTN_DIM
	btnRef.TextColor3 = active and Color3.fromRGB(255,255,255) or Color3.fromRGB(230,230,230)
	if st then st.Color = active and ACCENT or BTN_STROKE end
end

local function refreshTabStyles(active)
	styleTab(playersTabBtn, active == "Players")
	styleTab(itemsTabBtn, active == "Items")
	styleTab(selfTabBtn, active == "Self")
end

playersTabBtn.MouseButton1Click:Connect(function()
	setTab("Players")
	refreshTabStyles("Players")
end)
itemsTabBtn.MouseButton1Click:Connect(function()
	setTab("Items")
	refreshTabStyles("Items")
end)
selfTabBtn.MouseButton1Click:Connect(function()
	setTab("Self")
	refreshTabStyles("Self")
end)

-- ===== Players tab =====
local playersList = mk(playersSection, "ScrollingFrame", {
	Size=UDim2.new(0,260,1,0),
	BackgroundTransparency=1,
	BorderSizePixel=0,
	ScrollBarThickness=6,
	AutomaticCanvasSize=Enum.AutomaticSize.Y,
	CanvasSize=UDim2.new(0,0,0,0),
})
mk(playersList, "UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder})

local actions = mk(playersSection, "Frame", {
	Size=UDim2.new(1,-280,1,0),
	Position=UDim2.new(0,280,0,0),
	BackgroundTransparency=1,
})

local selectedLabel = mk(actions, "TextLabel", {
	Size=UDim2.new(1,0,0,28),
	BackgroundTransparency=1,
	TextXAlignment=Enum.TextXAlignment.Left,
	Text="Selected: none",
	Font=Enum.Font.GothamBold,
	TextSize=18,
	TextColor3=Color3.fromRGB(255,255,255),
})

local function makeActionButton(text, y)
	local b = mk(actions, "TextButton", {
		Size=UDim2.new(0,170,0,36),
		Position=UDim2.new(0,0,0,y),
		Text=text,
		BackgroundColor3=BTN,
		TextColor3=Color3.fromRGB(255,255,255),
		TextScaled=true,
		Font=Enum.Font.GothamBold,
		AutoButtonColor=true,
	})
	mk(b, "UICorner", {CornerRadius=UDim.new(0,10)})
	mk(b, "UIStroke", {Thickness=1, Color=ACCENT, Transparency=0})
	return b
end

local kickBtn = makeActionButton("Kick", 40)
local permBanBtn = makeActionButton("Perm Ban", 86)
local tempBanBtn = makeActionButton("Temp Ban", 132)
local giveCoinsBtn = makeActionButton("Give Coins", 204)
local deductCoinsBtn = makeActionButton("Deduct Coins", 250)
local giveFlyBtn = makeActionButton("Toggle Fly", 322)
local giveGodBtn = makeActionButton("Toggle God", 368)

local minutesBox = mk(actions, "TextBox", {
	Size=UDim2.new(0,80,0,28),
	Position=UDim2.new(0,180,0,138),
	PlaceholderText="min",
	Text="",
	BackgroundColor3=BTN_DIM,
	TextColor3=Color3.fromRGB(255,255,255),
	Font=Enum.Font.GothamBold,
	TextScaled=true,
})
mk(minutesBox, "UICorner", {CornerRadius=UDim.new(0,6)})

local coinsBox = mk(actions, "TextBox", {
	Size=UDim2.new(0,80,0,28),
	Position=UDim2.new(0,180,0,210),
	PlaceholderText="amt",
	Text="",
	BackgroundColor3=BTN_DIM,
	TextColor3=Color3.fromRGB(255,255,255),
	Font=Enum.Font.GothamBold,
	TextScaled=true,
})
mk(coinsBox, "UICorner", {CornerRadius=UDim.new(0,6)})

local reasonBox = mk(actions, "TextBox", {
	Size=UDim2.new(1,-200,0,28),
	Position=UDim2.new(0,180,0,92),
	PlaceholderText="reason (optional)",
	Text="",
	BackgroundColor3=BTN_DIM,
	TextColor3=Color3.fromRGB(255,255,255),
	Font=Enum.Font.Gotham,
	TextScaled=true,
})
mk(reasonBox, "UICorner", {CornerRadius=UDim.new(0,6)})

local function selectPlayer(p: Player)
	selectedUserId = p.UserId
	selectedLabel.Text = "Selected: " .. p.Name
end

local function refreshPlayers()
	clear(playersList, "TextButton")
	for _, p in ipairs(Players:GetPlayers()) do
		local b = mk(playersList, "TextButton", {
			Size=UDim2.new(1,-6,0,32),
			Text=p.Name,
			BackgroundColor3=BTN_DIM,
			TextColor3=Color3.fromRGB(255,255,255),
			TextScaled=true,
			Font=Enum.Font.GothamBold,
			AutoButtonColor=true,
		})
		mk(b, "UICorner", {CornerRadius=UDim.new(0,8)})
		mk(b, "UIStroke", {Thickness=1, Color=BTN_STROKE, Transparency=0})
		b.MouseButton1Click:Connect(function()
			selectPlayer(p)
		end)
	end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

local function ensureSelected()
	return selectedUserId ~= nil
end

kickBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	AdminAction:FireServer("Kick", {userId = selectedUserId, reason = reasonBox.Text})
end)

permBanBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	AdminAction:FireServer("PermBan", {userId = selectedUserId, reason = reasonBox.Text})
end)

tempBanBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	local minutes = tonumber(minutesBox.Text) or 1
	AdminAction:FireServer("TempBan", {userId = selectedUserId, minutes = minutes, reason = reasonBox.Text})
end)

giveCoinsBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	local amount = tonumber(coinsBox.Text) or 0
	AdminAction:FireServer("GiveCoins", {userId = selectedUserId, amount = amount})
end)

deductCoinsBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	local amount = tonumber(coinsBox.Text) or 0
	AdminAction:FireServer("DeductCoins", {userId = selectedUserId, amount = amount})
end)

giveFlyBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	local target = Players:GetPlayerByUserId(selectedUserId)
	local enabled = not (target and target:GetAttribute("AdminFly") == true)
	AdminAction:FireServer("SetFly", {userId = selectedUserId, enabled = enabled})
end)

giveGodBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	local target = Players:GetPlayerByUserId(selectedUserId)
	local enabled = not (target and target:GetAttribute("AdminGodMode") == true)
	AdminAction:FireServer("SetGod", {userId = selectedUserId, enabled = enabled})
end)

-- ===== Items tab =====
local catBar = mk(itemsSection, "Frame", {
	Size=UDim2.new(1,0,0,32),
	BackgroundTransparency=1,
})
local catLayout = mk(catBar, "UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0,8),
})
catLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local itemsList = mk(itemsSection, "ScrollingFrame", {
	Size=UDim2.new(1,0,1,-80),
	Position=UDim2.new(0,0,0,40),
	BackgroundTransparency=1,
	BorderSizePixel=0,
	ScrollBarThickness=6,
	AutomaticCanvasSize=Enum.AutomaticSize.Y,
	CanvasSize=UDim2.new(0,0,0,0),
})
mk(itemsList, "UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder})

local giveItemBtn = mk(itemsSection, "TextButton", {
	Size=UDim2.new(0,200,0,36),
	Position=UDim2.new(1,-200,1,-36),
	Text="Give Item",
	BackgroundColor3=BTN,
	TextColor3=Color3.fromRGB(255,255,255),
	TextScaled=true,
	Font=Enum.Font.GothamBold,
	AutoButtonColor=true,
})
mk(giveItemBtn, "UICorner", {CornerRadius=UDim.new(0,10)})
mk(giveItemBtn, "UIStroke", {Thickness=1, Color=ACCENT, Transparency=0})

local catalog = AdminGetCatalog:InvokeServer() or {Trails = {}, TrollItems = {}}

local function renderItems()
	clear(itemsList, "TextButton")
	local items = catalog[selectedCategory] or {}
	for _, id in ipairs(items) do
		local b = mk(itemsList, "TextButton", {
			Size=UDim2.new(1,-6,0,32),
			Text=id,
			BackgroundColor3=BTN_DIM,
			TextColor3=Color3.fromRGB(255,255,255),
			TextScaled=true,
			Font=Enum.Font.Gotham,
			AutoButtonColor=true,
		})
		mk(b, "UICorner", {CornerRadius=UDim.new(0,8)})
		mk(b, "UIStroke", {Thickness=1, Color=BTN_STROKE, Transparency=0})
		b.MouseButton1Click:Connect(function()
			selectedItemId = id
		end)
	end
end

local function makeCatBtn(text)
	local b = mk(catBar, "TextButton", {
		Size=UDim2.new(0,120,1,0),
		Text=text,
		BackgroundColor3=BTN_DIM,
		TextColor3=Color3.fromRGB(230,230,230),
		TextScaled=true,
		Font=Enum.Font.GothamBold,
		AutoButtonColor=true,
	})
	mk(b, "UICorner", {CornerRadius=UDim.new(0,8)})
	mk(b, "UIStroke", {Thickness=1, Color=BTN_STROKE, Transparency=0})
	b.MouseButton1Click:Connect(function()
		selectedCategory = text
		renderItems()
	end)
	return b
end

makeCatBtn("Trails")
makeCatBtn("TrollItems")
renderItems()

giveItemBtn.MouseButton1Click:Connect(function()
	if not ensureSelected() then return end
	if not selectedItemId then return end
	AdminAction:FireServer("GiveItem", {
		userId = selectedUserId,
		category = selectedCategory,
		itemId = selectedItemId,
	})
end)

-- ===== Self tab =====
local selfFly = mk(selfSection, "TextButton", {
	Size=UDim2.new(0,200,0,36),
	Position=UDim2.new(0,0,0,0),
	Text="Toggle Fly",
	BackgroundColor3=BTN,
	TextColor3=Color3.fromRGB(255,255,255),
	TextScaled=true,
	Font=Enum.Font.GothamBold,
	AutoButtonColor=true,
})
mk(selfFly, "UICorner", {CornerRadius=UDim.new(0,10)})
mk(selfFly, "UIStroke", {Thickness=1, Color=ACCENT, Transparency=0})

local selfGod = mk(selfSection, "TextButton", {
	Size=UDim2.new(0,200,0,36),
	Position=UDim2.new(0,0,0,48),
	Text="Toggle God",
	BackgroundColor3=BTN,
	TextColor3=Color3.fromRGB(255,255,255),
	TextScaled=true,
	Font=Enum.Font.GothamBold,
	AutoButtonColor=true,
})
mk(selfGod, "UICorner", {CornerRadius=UDim.new(0,10)})
mk(selfGod, "UIStroke", {Thickness=1, Color=ACCENT, Transparency=0})

local selfSpeedBox = mk(selfSection, "TextBox", {
	Size=UDim2.new(0,80,0,28),
	Position=UDim2.new(0,0,0,96),
	PlaceholderText="speed",
	Text="",
	BackgroundColor3=BTN_DIM,
	TextColor3=Color3.fromRGB(255,255,255),
	Font=Enum.Font.GothamBold,
	TextScaled=true,
})
mk(selfSpeedBox, "UICorner", {CornerRadius=UDim.new(0,6)})

local selfSpeed = mk(selfSection, "TextButton", {
	Size=UDim2.new(0,200,0,36),
	Position=UDim2.new(0,100,0,90),
	Text="Set Speed",
	BackgroundColor3=BTN,
	TextColor3=Color3.fromRGB(255,255,255),
	TextScaled=true,
	Font=Enum.Font.GothamBold,
	AutoButtonColor=true,
})
mk(selfSpeed, "UICorner", {CornerRadius=UDim.new(0,10)})
mk(selfSpeed, "UIStroke", {Thickness=1, Color=ACCENT, Transparency=0})

selfSpeedBox.Text = "32"

local selfSpeedOff = mk(selfSection, "TextButton", {
	Size=UDim2.new(0,200,0,36),
	Position=UDim2.new(0,0,0,138),
	Text="Clear Speed",
	BackgroundColor3=BTN_DIM,
	TextColor3=Color3.fromRGB(255,255,255),
	TextScaled=true,
	Font=Enum.Font.GothamBold,
	AutoButtonColor=true,
})
mk(selfSpeedOff, "UICorner", {CornerRadius=UDim.new(0,10)})
mk(selfSpeedOff, "UIStroke", {Thickness=1, Color=BTN_STROKE, Transparency=0})

selfFly.MouseButton1Click:Connect(function()
	local enabled = not (player:GetAttribute("AdminFly") == true)
	AdminAction:FireServer("SetFly", {userId = player.UserId, enabled = enabled})
end)

selfGod.MouseButton1Click:Connect(function()
	local enabled = not (player:GetAttribute("AdminGodMode") == true)
	AdminAction:FireServer("SetGod", {userId = player.UserId, enabled = enabled})
end)

selfSpeed.MouseButton1Click:Connect(function()
	local speed = tonumber(selfSpeedBox.Text) or 32
	AdminAction:FireServer("SetSpeed", {userId = player.UserId, enabled = true, speed = speed})
end)

selfSpeedOff.MouseButton1Click:Connect(function()
	AdminAction:FireServer("SetSpeed", {userId = player.UserId, enabled = false})
end)

-- ===== Open/Close =====
local function openPanel()
	overlay.Visible = true
	panel.Visible = true
end

local function closePanel()
	panel.Visible = false
	overlay.Visible = false
end

btn.MouseButton1Click:Connect(function()
	if panel.Visible then closePanel() else openPanel() end
end)

closeBtn.MouseButton1Click:Connect(closePanel)

overlay.MouseButton1Click:Connect(function()
	local pos = panel.AbsolutePosition
	local size = panel.AbsoluteSize
	local mousePos = UserInputService:GetMouseLocation()
	local inside =
		mousePos.X >= pos.X and mousePos.X <= (pos.X + size.X) and
		mousePos.Y >= pos.Y and mousePos.Y <= (pos.Y + size.Y)
	if not inside then
		closePanel()
	end
end)

setTab("Players")
refreshTabStyles("Players")
