-- DuckController2D (LocalScript) | StarterPlayer > StarterPlayerScripts
-- 2D-locked movement + a map-aware static camera.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local DuckShared = ReplicatedStorage:WaitForChild("DuckShared")
local Config = require(DuckShared:WaitForChild("Config"))
local PlaneUtil = require(DuckShared:WaitForChild("PlaneUtil"))

local PLANE_Z = Config.PLANE_Z
local WALK_SPEED = Config.WALK_SPEED
local JUMP_HEIGHT = Config.JUMP_HEIGHT

--========================  CAMERA TUNABLES  ========================--
local CAM_FOV      = 40    -- lower = flatter perspective (camera sits further back)
local FRAME_MARGIN = 1.08  -- breathing room around the framed area (1.0 = exact)
-- Used only if no map / CameraFrame is loaded yet.
local FALLBACK = { x = 0, y = 18, w = 120, h = 60 }
--===================================================================--

local humanoid: Humanoid? = nil
local root: BasePart? = nil
local moveLeft, moveRight = false, false

--------------------------------------------------------------------
-- disable default MOVEMENT controls (camera handled separately below)
--------------------------------------------------------------------
local playerScripts = player:WaitForChild("PlayerScripts")
local PlayerModule = require(playerScripts:WaitForChild("PlayerModule")) :: any
PlayerModule:GetControls():Disable()

--------------------------------------------------------------------
-- which rectangle to frame: the current map's CameraFrame, then a
-- top-level CameraFrame, then the fallback. Each map carries its own frame,
-- so the camera re-fits automatically whenever a map loads or swaps.
--------------------------------------------------------------------
local function getFrame(): (Vector3, number, number)
	local map = workspace:FindFirstChild("CurrentMap")
	local part = (map and map:FindFirstChild("CameraFrame"))
		or workspace:FindFirstChild("CameraFrame")
	if part and part:IsA("BasePart") then
		return part.Position, part.Size.X, part.Size.Y
	end
	return Vector3.new(FALLBACK.x, FALLBACK.y, PLANE_Z), FALLBACK.w, FALLBACK.h
end

local function computeCameraCF(cam: Camera): CFrame
	local center, w, h = getFrame()
	local halfW = (w / 2) * FRAME_MARGIN
	local halfH = (h / 2) * FRAME_MARGIN
	local vp = cam.ViewportSize
	local aspect = vp.X / math.max(vp.Y, 1)
	local tanHalf = math.tan(math.rad(CAM_FOV) / 2) -- FieldOfView is VERTICAL fov

	local distV = halfH / tanHalf
	local distH = halfW / (tanHalf * aspect)
	local dist = math.max(distV, distH)

	local camPos = Vector3.new(center.X, center.Y, PLANE_Z + dist)
	return CFrame.lookAt(camPos, Vector3.new(center.X, center.Y, PLANE_Z))
end

--------------------------------------------------------------------
-- OWN the camera: runs just AFTER the default camera each frame, forcing
-- Scriptable + our CFrame so nothing can fight it or right-click-pan.
--------------------------------------------------------------------
RunService:BindToRenderStep("DuckCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	if cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.CameraType = Enum.CameraType.Scriptable
	end
	cam.FieldOfView = CAM_FOV
	cam.CFrame = computeCameraCF(cam)
end)

--------------------------------------------------------------------
-- character setup on (re)spawn
--------------------------------------------------------------------
local function onCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
	hum.AutoRotate = false
	hum.WalkSpeed = WALK_SPEED
	hum.UseJumpPower = false
	hum.JumpHeight = JUMP_HEIGHT
	humanoid, root = hum, hrp
end

if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)

--------------------------------------------------------------------
-- input
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.A or k == Enum.KeyCode.Left then
		moveLeft = true
	elseif k == Enum.KeyCode.D or k == Enum.KeyCode.Right then
		moveRight = true
	elseif k == Enum.KeyCode.Space or k == Enum.KeyCode.W or k == Enum.KeyCode.Up then
		if humanoid then humanoid.Jump = true end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local k = input.KeyCode
	if k == Enum.KeyCode.A or k == Enum.KeyCode.Left then
		moveLeft = false
	elseif k == Enum.KeyCode.D or k == Enum.KeyCode.Right then
		moveRight = false
	end
end)

--------------------------------------------------------------------
-- movement + 2D lock
--------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if not humanoid or not root or humanoid.Health <= 0 then return end

	local dir = (moveRight and 1 or 0) - (moveLeft and 1 or 0)
	humanoid:Move(Vector3.new(dir, 0, 0), false)

	local aim = PlaneUtil.mouseWorldOnPlane(PLANE_Z)
	local faceRight = if aim then aim.X >= root.Position.X else dir >= 0
	local yaw = if faceRight then -math.pi / 2 else math.pi / 2

	local pos = root.Position
	root.CFrame = CFrame.new(pos.X, pos.Y, PLANE_Z) * CFrame.Angles(0, yaw, 0)

	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X, v.Y, 0)
end)
