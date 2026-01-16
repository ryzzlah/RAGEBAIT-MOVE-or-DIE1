-- StarterPlayerScripts/AdminFlyClient.lua
-- Client-side fly controls for admin testing (toggle with F).

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character
local humanoid
local hrp

local flyActive = false
local bodyVel: BodyVelocity?
local bodyGyro: BodyGyro?

local FLY_SPEED = 70

local function isFlyAllowed()
	return player:GetAttribute("AdminFly") == true
end

local lastMobileJump = 0
local DOUBLE_JUMP_WINDOW = 1.5

local function attachChar(char: Model)
	character = char
	humanoid = char:FindFirstChildOfClass("Humanoid")
	hrp = char:FindFirstChild("HumanoidRootPart")
end

player.CharacterAdded:Connect(attachChar)
if player.Character then attachChar(player.Character) end

local function stopFly()
	flyActive = false
	if bodyVel then bodyVel:Destroy() bodyVel = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function startFly()
	if not hrp or not humanoid then return end
	if flyActive then return end
	flyActive = true

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVel.Velocity = Vector3.zero
	bodyVel.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyGyro.P = 2e4
	bodyGyro.Parent = hrp

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

local function toggleFly()
	if not isFlyAllowed() then
		stopFly()
		return
	end
	if flyActive then
		stopFly()
	else
		startFly()
	end
end

CAS:BindAction("AdminFlyToggle", function(_, state)
	if state == Enum.UserInputState.Begin then
		toggleFly()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.F)

player:GetAttributeChangedSignal("AdminFly"):Connect(function()
	if not isFlyAllowed() then
		stopFly()
	end
end)

UIS.JumpRequest:Connect(function()
	if not isFlyAllowed() then return end
	if not UIS.TouchEnabled or UIS.KeyboardEnabled then return end

	local now = os.clock()
	if (now - lastMobileJump) <= DOUBLE_JUMP_WINDOW then
		toggleFly()
		lastMobileJump = 0
	else
		lastMobileJump = now
	end
end)

RunService.RenderStepped:Connect(function()
	if not flyActive or not hrp or not humanoid then return end
	local cam = workspace.CurrentCamera
	if not cam then return end

	local move = Vector3.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
	if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end

	if move.Magnitude > 0 then
		move = move.Unit * FLY_SPEED
	end

	bodyVel.Velocity = move
	bodyGyro.CFrame = cam.CFrame
end)
