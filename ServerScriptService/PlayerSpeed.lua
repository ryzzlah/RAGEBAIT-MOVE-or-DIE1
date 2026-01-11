-- ServerScriptService/PlayerSpeed
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEFAULT_SPEED = 20
local SPRINT_SPEED = 28

local sprintEvent = ReplicatedStorage:FindFirstChild("SprintIntent")
if not sprintEvent then
	sprintEvent = Instance.new("RemoteEvent")
	sprintEvent.Name = "SprintIntent"
	sprintEvent.Parent = ReplicatedStorage
end

local function applySpeed(humanoid, speed)
	if humanoid and humanoid.Parent and humanoid.Health > 0 then
		humanoid.WalkSpeed = speed
	end
end

local function getTargetSpeed(player)
	local base = player:GetAttribute("BaseWalkSpeed") or DEFAULT_SPEED
	if player:GetAttribute("IsSprinting") == true then
		return SPRINT_SPEED
	end
	return base
end

Players.PlayerAdded:Connect(function(player)
	-- You can change this per-player later (VIP/skills) by setting this attribute elsewhere
	if player:GetAttribute("BaseWalkSpeed") == nil then
		player:SetAttribute("BaseWalkSpeed", DEFAULT_SPEED)
	end
	if player:GetAttribute("IsSprinting") == nil then
		player:SetAttribute("IsSprinting", false)
	end

	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid", 10)
		if not humanoid then return end

		player:SetAttribute("IsSprinting", false)

		-- Apply immediately + after a couple delays (covers load timing weirdness)
		applySpeed(humanoid, getTargetSpeed(player))
		task.delay(0.25, function() applySpeed(humanoid, getTargetSpeed(player)) end)
		task.delay(1.00, function() applySpeed(humanoid, getTargetSpeed(player)) end)

		-- If something tries to change it back to 16, force it back
		humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			local target = getTargetSpeed(player)
			if humanoid.WalkSpeed ~= target then
				-- tiny delay to avoid fights with Roblox internal updates
				task.defer(function()
					applySpeed(humanoid, target)
				end)
			end
		end)

		-- If you change BaseWalkSpeed attribute (VIP/skills), it updates live
		player:GetAttributeChangedSignal("BaseWalkSpeed"):Connect(function()
			applySpeed(humanoid, getTargetSpeed(player))
		end)

		player:GetAttributeChangedSignal("IsSprinting"):Connect(function()
			applySpeed(humanoid, getTargetSpeed(player))
		end)
	end)
end)

sprintEvent.OnServerEvent:Connect(function(player, wantsSprint)
	if typeof(wantsSprint) ~= "boolean" then return end
	player:SetAttribute("IsSprinting", wantsSprint)
end)
