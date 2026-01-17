-- WinsLeaderboardBoard.server.lua
-- Put this Script under Workspace.WinsLeaderboard.Scoreboard.globalLeaderboard (Folder).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local STORE_NAME = "LeaderboardWins"
local ods = DataStoreService:GetOrderedDataStore(STORE_NAME)

local primaryColor = Color3.new(1, 1, 1)
local secondaryColor = Color3.new(0.815686, 0.815686, 0.815686)

local function getScrollingFrame()
	local scoreboard = script.Parent:FindFirstAncestor("Scoreboard")
	if not scoreboard then
		scoreboard = script.Parent.Parent
	end
	if not scoreboard then return nil end
	local gui = scoreboard:FindFirstChildWhichIsA("SurfaceGui", true)
	if not gui then return nil end
	return gui:FindFirstChildWhichIsA("ScrollingFrame", true)
end

local function cleanBoard(scroller: ScrollingFrame)
	for _, frame in ipairs(scroller:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
end

local function findInRow(row: Instance, name: string)
	return row:FindFirstChild(name, true)
end

local function updateBoard(scroller: ScrollingFrame, data)
	local template = script.Parent:FindFirstChild("Frame") or script:FindFirstChild("Frame")
	if not template then
		warn("[WinsLeaderboard] Missing Frame template under script.")
		return
	end

	for i, v in ipairs(data) do
		local userId = v.key
		local score = v.value

		local row = template:Clone()
		row.Name = "Row_" .. i
		row.LayoutOrder = i
		row.Parent = scroller

		local nameLbl = findInRow(row, "name")
		local rankLbl = findInRow(row, "rank")
		local valueLbl = findInRow(row, "value")
		local imageLbl = findInRow(row, "playerImage")

		if nameLbl then
			local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			nameLbl.Text = ok and name or "Unknown"
		end

		if imageLbl and imageLbl:IsA("ImageLabel") then
			local ok, img = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			if ok then imageLbl.Image = img end
		end

		if valueLbl then valueLbl.Text = tostring(score) end
		if rankLbl then rankLbl.Text = "# " .. i end

		if i % 2 == 0 then
			row.BackgroundColor3 = primaryColor
		else
			row.BackgroundColor3 = secondaryColor
		end

		if i == 1 then
			row.BackgroundColor3 = Color3.new(1, 1, 179/255)
			if nameLbl then
				nameLbl.TextStrokeColor3 = Color3.new(1, 226/255, 0)
				nameLbl.TextStrokeTransparency = 0
			end
			if valueLbl then
				valueLbl.TextStrokeColor3 = Color3.new(1, 226/255, 0)
				valueLbl.TextStrokeTransparency = 0
			end
			if rankLbl then
				rankLbl.TextStrokeColor3 = Color3.new(1, 226/255, 0)
				rankLbl.TextStrokeTransparency = 0
			end
		end
	end
end

while true do
	local scroller = getScrollingFrame()
	if not scroller then
		warn("[WinsLeaderboard] No SurfaceGui/ScrollingFrame found under", script.Parent:GetFullName())
		task.wait(5)
		continue
	end

	local ok, page = pcall(function()
		return ods:GetSortedAsync(false, 100)
	end)

	if ok and page then
		local data = page:GetCurrentPage()
		cleanBoard(scroller)
		updateBoard(scroller, data)
	else
		warn("[WinsLeaderboard] Update failed:", page)
	end

	task.wait(60)
end
