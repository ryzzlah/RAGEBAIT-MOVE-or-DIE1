-- ServerScriptService/SpectateService (ModuleScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spectateEvent = ReplicatedStorage:WaitForChild("SpectateEvent")

local SpectateService = {}

local function getAliveInRoundUserIds()
	local ids = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("InRound") == true and p:GetAttribute("AliveInRound") == true then
			table.insert(ids, p.UserId)
		end
	end
	return ids
end

-- API for RoundManager
function SpectateService.SetRoundState(playersInRound: {Player}, isRoundRunning: boolean)
	for _, p in ipairs(playersInRound) do
		p:SetAttribute("InRound", isRoundRunning)
		-- if round starts, everyone alive; if round ends, clear alive too
		if isRoundRunning then
			p:SetAttribute("AliveInRound", true)
		else
			p:SetAttribute("AliveInRound", false)
		end
	end
end

function SpectateService.MarkEliminated(plr: Player)
	plr:SetAttribute("AliveInRound", false)
	-- keep InRound true until round ends (so client knows round is still running)
end

function SpectateService.ClearPlayer(plr: Player)
	plr:SetAttribute("InRound", false)
	plr:SetAttribute("AliveInRound", false)
end

return SpectateService
