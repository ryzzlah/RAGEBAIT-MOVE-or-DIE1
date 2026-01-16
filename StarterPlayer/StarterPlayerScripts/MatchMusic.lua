-- StarterPlayerScripts/MatchMusic (LocalScript)
-- Plays match-only music for participants and spectators.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local matchState = ReplicatedStorage:WaitForChild("MatchState")

local MUSIC_ID = "rbxassetid://97512561148601"
local MUSIC_VOLUME = 0.5

local sound = SoundService:FindFirstChild("MatchMusic")
if not sound then
	sound = Instance.new("Sound")
	sound.Name = "MatchMusic"
	sound.SoundId = MUSIC_ID
	sound.Volume = MUSIC_VOLUME
	sound.Looped = true
	sound.Parent = SoundService
end

local inMatch = false

local function getPlayerFromSubject(subject: Instance?)
	if not subject then return nil end
	if subject:IsA("Humanoid") then
		return Players:GetPlayerFromCharacter(subject.Parent)
	end
	if subject:IsA("BasePart") then
		return Players:GetPlayerFromCharacter(subject.Parent)
	end
	return nil
end

local function isSpectatingAliveTarget()
	local cam = workspace.CurrentCamera
	if not cam then return false end
	local target = getPlayerFromSubject(cam.CameraSubject)
	if not target then return false end
	if target == player then return false end
	return target:GetAttribute("InRound") == true and target:GetAttribute("AliveInRound") == true
end

local function shouldPlay()
	if not inMatch then return false end
	local participant = player:GetAttribute("MatchParticipant") == true
	local alive = player:GetAttribute("AliveInRound") == true
	if participant and alive then
		return true
	end
	return isSpectatingAliveTarget()
end

local function refresh()
	if shouldPlay() then
		if not sound.IsPlaying then
			sound:Play()
		end
	else
		if sound.IsPlaying then
			sound:Stop()
		end
	end
end

matchState.OnClientEvent:Connect(function(v)
	inMatch = (v == true)
	refresh()
end)

player:GetAttributeChangedSignal("MatchParticipant"):Connect(refresh)
player:GetAttributeChangedSignal("InRound"):Connect(refresh)
player:GetAttributeChangedSignal("AliveInRound"):Connect(refresh)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refresh)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(refresh)
end

task.spawn(function()
	while sound.Parent do
		if inMatch then
			refresh()
		end
		task.wait(0.5)
	end
end)

refresh()
