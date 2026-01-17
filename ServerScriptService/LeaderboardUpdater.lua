-- ServerScriptService/LeaderboardUpdater.lua
-- Writes Coins/Wins to OrderedDataStores for leaderboard boards.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local COINS_STORE_NAME = "LeaderboardCoins"
local WINS_STORE_NAME = "LeaderboardWins"

local coinsStore = DataStoreService:GetOrderedDataStore(COINS_STORE_NAME)
local winsStore = DataStoreService:GetOrderedDataStore(WINS_STORE_NAME)

local UPDATE_INTERVAL = 60
local MAX_RETRIES = 5

local function retry(pcallFn)
	local lastErr
	for i = 1, MAX_RETRIES do
		local ok, result = pcall(pcallFn)
		if ok then return true, result end
		lastErr = result
		task.wait(0.3 * i)
	end
	return false, lastErr
end

local function readInt(ls: Instance?, name: string): number
	local v = ls and ls:FindFirstChild(name)
	if v and v:IsA("IntValue") then
		return v.Value
	end
	return 0
end

local function updatePlayer(plr: Player)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then return end

	local coins = readInt(ls, "Coins")
	local wins = readInt(ls, "Wins")

	retry(function()
		return coinsStore:SetAsync(plr.UserId, coins)
	end)

	retry(function()
		return winsStore:SetAsync(plr.UserId, wins)
	end)
end

Players.PlayerRemoving:Connect(updatePlayer)

task.spawn(function()
	while true do
		task.wait(UPDATE_INTERVAL)
		for _, plr in ipairs(Players:GetPlayers()) do
			updatePlayer(plr)
		end
	end
end)

game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		updatePlayer(plr)
	end
	task.wait(2)
end)
