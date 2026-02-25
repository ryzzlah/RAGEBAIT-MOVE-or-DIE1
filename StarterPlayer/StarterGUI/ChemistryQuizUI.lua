-- StarterGui/ChemistryQuizUI (LocalScript)
-- GCSE balancing quiz panel with built-in answer checking.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function mk(parent, className, props)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local old = playerGui:FindFirstChild("ChemistryQuizGui")
if old then
	old:Destroy()
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local GUI_NAME = "ChemistryQuizGui"
local ACCENT = Color3.fromRGB(85, 200, 120)
local PANEL_BG = Color3.fromRGB(18, 18, 18)
local TOP_BG = Color3.fromRGB(12, 12, 12)
local ROW_BG = Color3.fromRGB(24, 24, 24)
local STROKE = Color3.fromRGB(60, 60, 60)

local questions = {
	{
		prompt = "H2 + O2 -> H2O",
		format = "H2, O2, H2O",
		expected = {2, 1, 2},
		allowScaled = true,
	},
	{
		prompt = "Mg + O2 -> MgO",
		format = "Mg, O2, MgO",
		expected = {2, 1, 2},
		allowScaled = true,
	},
	{
		prompt = "C3H8 + O2 -> CO2 + H2O",
		format = "C3H8, O2, CO2, H2O",
		expected = {1, 5, 3, 4},
		allowScaled = true,
	},
}

local function parseCoefficients(text, expectedCount)
	local nums = {}
	for n in string.gmatch(text, "%d+") do
		table.insert(nums, tonumber(n))
	end

	if #nums ~= expectedCount then
		return nil, "Wrong count"
	end

	for _, n in ipairs(nums) do
		if not n or n <= 0 then
			return nil, "Use positive integers"
		end
	end

	return nums, nil
end

local function coeffsMatch(given, expected, allowScaled)
	if #given ~= #expected then
		return false
	end

	if not allowScaled then
		for i = 1, #expected do
			if given[i] ~= expected[i] then
				return false
			end
		end
		return true
	end

	-- Accept equivalent ratios (example: 2,10,6,8 is valid for 1,5,3,4)
	for i = 1, #expected do
		if given[i] * expected[1] ~= expected[i] * given[1] then
			return false
		end
	end

	return true
end

local gui = mk(playerGui, "ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 90,
})

local openButton = mk(gui, "TextButton", {
	Name = "OpenQuizButton",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 20, 0.5, 36),
	Size = UDim2.new(0, isMobile and 150 or 180, 0, isMobile and 42 or 48),
	BackgroundColor3 = Color3.fromRGB(36, 36, 36),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "CHEM QUIZ",
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	AutoButtonColor = true,
	ZIndex = 5,
})
mk(openButton, "UICorner", {CornerRadius = UDim.new(0, 10)})
mk(openButton, "UIStroke", {Thickness = 1, Color = ACCENT, Transparency = 0})

local overlay = mk(gui, "TextButton", {
	Name = "Overlay",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.35,
	Text = "",
	Visible = false,
	AutoButtonColor = false,
	ZIndex = 10,
})

local panelWidth = isMobile and 360 or 760
local panelHeight = isMobile and 520 or 500

local panel = mk(gui, "Frame", {
	Name = "QuizPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, panelWidth, 0, panelHeight),
	BackgroundColor3 = PANEL_BG,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
})
mk(panel, "UICorner", {CornerRadius = UDim.new(0, 14)})
mk(panel, "UIStroke", {Thickness = 2, Color = STROKE, Transparency = 0})

local header = mk(panel, "Frame", {
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = TOP_BG,
	BorderSizePixel = 0,
	ZIndex = 21,
})
mk(header, "UICorner", {CornerRadius = UDim.new(0, 14)})
mk(header, "Frame", {
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.5, 0),
	BorderSizePixel = 0,
	BackgroundColor3 = TOP_BG,
	ZIndex = 21,
})

mk(panel, "TextLabel", {
	Size = UDim2.new(1, -120, 0, 54),
	Position = UDim2.new(0, 14, 0, 0),
	BackgroundTransparency = 1,
	Text = "GCSE Balancing Quiz",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	ZIndex = 22,
})

local closeBtn = mk(panel, "TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0, 27),
	Size = UDim2.new(0, 34, 0, 34),
	BackgroundColor3 = Color3.fromRGB(190, 65, 65),
	Text = "X",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	AutoButtonColor = true,
	ZIndex = 22,
})
mk(closeBtn, "UICorner", {CornerRadius = UDim.new(1, 0)})

local instructionBox = mk(panel, "Frame", {
	Size = UDim2.new(1, -24, 0, isMobile and 140 or 120),
	Position = UDim2.new(0, 12, 0, 66),
	BackgroundColor3 = ROW_BG,
	BorderSizePixel = 0,
	ZIndex = 21,
})
mk(instructionBox, "UICorner", {CornerRadius = UDim.new(0, 10)})
mk(instructionBox, "UIStroke", {Thickness = 1, Color = STROKE, Transparency = 0})

mk(instructionBox, "TextLabel", {
	Size = UDim2.new(1, -16, 1, -12),
	Position = UDim2.new(0, 8, 0, 6),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Text = "How to balance:\n1) Count atoms on both sides.\n2) Change only big numbers in front.\n3) Balance one element at a time.\n4) Leave H and O near the end.\n5) Recheck all atoms.\nAnswer format below: write coefficients in order, like 2,1,2",
	TextColor3 = Color3.fromRGB(230, 230, 230),
	Font = Enum.Font.Gotham,
	TextSize = isMobile and 13 or 14,
	ZIndex = 22,
})

local questionsHolder = mk(panel, "ScrollingFrame", {
	Name = "QuestionsHolder",
	Size = UDim2.new(1, -24, 1, -(isMobile and 250 or 240)),
	Position = UDim2.new(0, 12, 0, isMobile and 216 or 196),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 21,
})

mk(questionsHolder, "UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local entries = {}

for i, q in ipairs(questions) do
	local row = mk(questionsHolder, "Frame", {
		Size = UDim2.new(1, 0, 0, isMobile and 100 or 90),
		BackgroundColor3 = ROW_BG,
		BorderSizePixel = 0,
		ZIndex = 22,
	})
	mk(row, "UICorner", {CornerRadius = UDim.new(0, 10)})
	mk(row, "UIStroke", {Thickness = 1, Color = STROKE, Transparency = 0})

	mk(row, "TextLabel", {
		Size = UDim2.new(1, -14, 0, 24),
		Position = UDim2.new(0, 8, 0, 6),
		BackgroundTransparency = 1,
		Text = ("Q%d: %s"):format(i, q.prompt),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = isMobile and 13 or 14,
		ZIndex = 23,
	})

	local input = mk(row, "TextBox", {
		Size = UDim2.new(1, -16, 0, 30),
		Position = UDim2.new(0, 8, 0, 34),
		BackgroundColor3 = Color3.fromRGB(34, 34, 34),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		PlaceholderText = q.format,
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		ClearTextOnFocus = false,
		ZIndex = 23,
	})
	mk(input, "UICorner", {CornerRadius = UDim.new(0, 8)})
	mk(input, "UIStroke", {Thickness = 1, Color = Color3.fromRGB(70, 70, 70), Transparency = 0})

	local status = mk(row, "TextLabel", {
		Size = UDim2.new(1, -14, 0, 20),
		Position = UDim2.new(0, 8, 0, 68),
		BackgroundTransparency = 1,
		Text = "Not checked yet",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(175, 175, 175),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		ZIndex = 23,
	})

	table.insert(entries, {
		data = q,
		input = input,
		status = status,
	})
end

local footer = mk(panel, "Frame", {
	Size = UDim2.new(1, -24, 0, 46),
	Position = UDim2.new(0, 12, 1, -58),
	BackgroundTransparency = 1,
	ZIndex = 21,
})

local scoreLabel = mk(footer, "TextLabel", {
	Size = UDim2.new(0.45, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = ("Score: 0/%d"):format(#questions),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	ZIndex = 22,
})

local resetBtn = mk(footer, "TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -130, 0.5, 0),
	Size = UDim2.new(0, 110, 0, 36),
	BackgroundColor3 = Color3.fromRGB(45, 45, 45),
	Text = "Reset",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	AutoButtonColor = true,
	ZIndex = 22,
})
mk(resetBtn, "UICorner", {CornerRadius = UDim.new(0, 10)})
mk(resetBtn, "UIStroke", {Thickness = 1, Color = STROKE, Transparency = 0})

local checkBtn = mk(footer, "TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 0),
	Size = UDim2.new(0, 120, 0, 36),
	BackgroundColor3 = ACCENT,
	Text = "Check Answers",
	TextColor3 = Color3.fromRGB(12, 12, 12),
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	AutoButtonColor = true,
	ZIndex = 22,
})
mk(checkBtn, "UICorner", {CornerRadius = UDim.new(0, 10)})

local function setOpen(opened)
	panel.Visible = opened
	overlay.Visible = opened
end

openButton.MouseButton1Click:Connect(function()
	setOpen(not panel.Visible)
end)

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

overlay.MouseButton1Click:Connect(function()
	setOpen(false)
end)

checkBtn.MouseButton1Click:Connect(function()
	local score = 0

	for _, entry in ipairs(entries) do
		local expected = entry.data.expected
		local parsed, err = parseCoefficients(entry.input.Text, #expected)

		if not parsed then
			entry.status.Text = "Invalid input: " .. tostring(err)
			entry.status.TextColor3 = Color3.fromRGB(255, 100, 100)
		elseif coeffsMatch(parsed, expected, entry.data.allowScaled) then
			entry.status.Text = "Correct"
			entry.status.TextColor3 = Color3.fromRGB(90, 220, 120)
			score += 1
		else
			entry.status.Text = "Incorrect. Expected ratio: " .. table.concat(expected, ",")
			entry.status.TextColor3 = Color3.fromRGB(255, 130, 130)
		end
	end

	scoreLabel.Text = ("Score: %d/%d"):format(score, #questions)
end)

resetBtn.MouseButton1Click:Connect(function()
	for _, entry in ipairs(entries) do
		entry.input.Text = ""
		entry.status.Text = "Not checked yet"
		entry.status.TextColor3 = Color3.fromRGB(175, 175, 175)
	end
	scoreLabel.Text = ("Score: 0/%d"):format(#questions)
end)
