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

local function shouldPlay()
	if not inMatch then return false end
	local participant = player:GetAttribute("MatchParticipant") == true
	local inRound = player:GetAttribute("InRound") == true
	return participant or inRound
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

refresh()
