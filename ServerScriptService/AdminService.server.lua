-- ServerScriptService/AdminService.server.lua
-- Admin actions: kick/ban, coins, item grants, temp perks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local ADMIN_USER_IDS = {
	[1676263675] = true, -- you
	-- add more userIds here: [123456] = true,
}

local BAN_STORE_NAME = "AdminBans_v1"
local banStore = DataStoreService:GetDataStore(BAN_STORE_NAME)

local AdminAction = ReplicatedStorage:FindFirstChild("AdminAction")
if not AdminAction then
	AdminAction = Instance.new("RemoteEvent")
	AdminAction.Name = "AdminAction"
	AdminAction.Parent = ReplicatedStorage
end

local AdminGetCatalog = ReplicatedStorage:FindFirstChild("AdminGetCatalog")
if not AdminGetCatalog then
	AdminGetCatalog = Instance.new("RemoteFunction")
	AdminGetCatalog.Name = "AdminGetCatalog"
	AdminGetCatalog.Parent = ReplicatedStorage
end

local function isAdmin(plr: Player): boolean
	return ADMIN_USER_IDS[plr.UserId] == true
end

local function getTarget(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function readInt(ls: Instance?, name: string): number
	local v = ls and ls:FindFirstChild(name)
	if v and v:IsA("IntValue") then
		return v.Value
	end
	return 0
end

local function writeInt(ls: Instance?, name: string, value: number)
	if not ls then return end
	local v = ls:FindFirstChild(name)
	if v and v:IsA("IntValue") then
		v.Value = value
	end
end

local function banKey(userId: number)
	return "u_" .. tostring(userId)
end

local function setBan(userId: number, expiresAt: number, reason: string, byUserId: number)
	local payload = {
		expires = expiresAt,
		reason = reason or "",
		by = byUserId,
		created = os.time(),
	}
	banStore:SetAsync(banKey(userId), payload)
end

local function clearBan(userId: number)
	banStore:RemoveAsync(banKey(userId))
end

local function checkBan(plr: Player)
	local ok, data = pcall(function()
		return banStore:GetAsync(banKey(plr.UserId))
	end)
	if not ok or type(data) ~= "table" then return end

	local expires = tonumber(data.expires) or 0
	local now = os.time()
	if expires == 0 or expires > now then
		local reason = data.reason or "Banned."
		plr:Kick(reason)
	else
		clearBan(plr.UserId)
	end
end

Players.PlayerAdded:Connect(checkBan)

local function buildCatalog()
	local trails = {}
	local trollItems = {}

	local trailRoots = {"Trails", "Robux_Trails"}
	for _, rootName in ipairs(trailRoots) do
		local root = ServerStorage:FindFirstChild(rootName)
		if root and root:IsA("Folder") then
			for _, child in ipairs(root:GetChildren()) do
				if child:IsA("Folder") then
					table.insert(trails, child.Name)
				end
			end
		end
	end

	local trollRoot = ServerStorage:FindFirstChild("TrollItems")
	if trollRoot and trollRoot:IsA("Folder") then
		for _, child in ipairs(trollRoot:GetChildren()) do
			if child:IsA("Tool") then
				table.insert(trollItems, child.Name)
			end
		end
	end

	table.sort(trails)
	table.sort(trollItems)

	return {
		Trails = trails,
		TrollItems = trollItems,
	}
end

local catalogCache = buildCatalog()

AdminGetCatalog.OnServerInvoke = function(plr: Player)
	if not isAdmin(plr) then return nil end
	catalogCache = buildCatalog()
	return catalogCache
end

local function setAdminSpeed(plr: Player, enabled: boolean, speedValue: number?)
	if enabled then
		if plr:GetAttribute("AdminSpeedRestore") == nil then
			plr:SetAttribute("AdminSpeedRestore", plr:GetAttribute("BaseWalkSpeed") or 20)
		end
		plr:SetAttribute("AdminSpeed", true)
		plr:SetAttribute("AdminSpeedValue", speedValue or 32)
		plr:SetAttribute("BaseWalkSpeed", speedValue or 32)
	else
		local restore = plr:GetAttribute("AdminSpeedRestore")
		plr:SetAttribute("AdminSpeed", false)
		plr:SetAttribute("AdminSpeedValue", nil)
		plr:SetAttribute("BaseWalkSpeed", restore or 20)
	end
end

AdminAction.OnServerEvent:Connect(function(plr: Player, action: string, payload: table)
	if not isAdmin(plr) then return end
	if typeof(action) ~= "string" then return end
	payload = payload or {}

	if action == "Kick" then
		local target = getTarget(tonumber(payload.userId) or 0)
		if target then
			target:Kick(payload.reason or "Kicked by admin.")
		end
		return
	end

	if action == "TempBan" then
		local userId = tonumber(payload.userId) or 0
		local minutes = math.max(1, tonumber(payload.minutes) or 1)
		local expires = os.time() + (minutes * 60)
		setBan(userId, expires, payload.reason or "Temp banned.", plr.UserId)
		local target = getTarget(userId)
		if target then target:Kick(payload.reason or "Temp banned.") end
		return
	end

	if action == "PermBan" then
		local userId = tonumber(payload.userId) or 0
		setBan(userId, 0, payload.reason or "Banned.", plr.UserId)
		local target = getTarget(userId)
		if target then target:Kick(payload.reason or "Banned.") end
		return
	end

	if action == "GiveCoins" or action == "DeductCoins" then
		local target = getTarget(tonumber(payload.userId) or 0)
		if not target then return end
		local ls = target:FindFirstChild("leaderstats")
		if not ls then return end
		local coins = readInt(ls, "Coins")
		local amount = math.max(0, tonumber(payload.amount) or 0)
		if action == "GiveCoins" then
			writeInt(ls, "Coins", coins + amount)
		else
			writeInt(ls, "Coins", math.max(0, coins - amount))
		end
		return
	end

	if action == "GiveItem" then
		local target = getTarget(tonumber(payload.userId) or 0)
		if not target then return end
		local category = tostring(payload.category or "")
		local itemId = tostring(payload.itemId or "")
		if category == "" or itemId == "" then return end

		local catalog = catalogCache
		local list = catalog and catalog[category]
		if type(list) ~= "table" then return end
		local okItem = false
		for _, id in ipairs(list) do
			if id == itemId then
				okItem = true
				break
			end
		end
		if not okItem then return end

		if PlayerData.MarkOwned(target, category, itemId) then
			PlayerData.Save(target)
		end
		return
	end

	if action == "SetFly" then
		local target = getTarget(tonumber(payload.userId) or 0)
		if not target then return end
		target:SetAttribute("AdminFly", payload.enabled == true)
		return
	end

	if action == "SetGod" then
		local target = getTarget(tonumber(payload.userId) or 0)
		if not target then return end
		target:SetAttribute("AdminGodMode", payload.enabled == true)
		return
	end

	if action == "SetSpeed" then
		local target = getTarget(tonumber(payload.userId) or 0)
		if not target then return end
		setAdminSpeed(target, payload.enabled == true, tonumber(payload.speed))
		return
	end
end)
