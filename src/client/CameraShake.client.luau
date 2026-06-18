-- CameraShake (LocalScript) | StarterPlayer > StarterPlayerScripts
-- Adds a trauma-based screen shake on top of the static map camera. Runs just
-- AFTER DuckController2D sets the camera each frame, so it layers cleanly.
-- Self-contained: it listens for explosions, taking damage, and dying itself.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local DuckShared = ReplicatedStorage:WaitForChild("DuckShared")
local Remotes = require(DuckShared:WaitForChild("Remotes"))

--========================  TUNABLES  ========================--
local MAX_OFFSET = 2.2          -- studs of positional shake at full trauma
local MAX_ROLL   = math.rad(4)  -- radians of camera roll at full trauma
local DECAY      = 1.9          -- trauma lost per second (higher = snappier)

local HIT_SHAKE       = 0.35    -- taking a full 100 dmg hit (scaled by damage)
local DEATH_SHAKE     = 0.9
local EXPLOSION_SHAKE = 0.9     -- at point-blank, falls off with distance
local EXPLOSION_RANGE = 90      -- studs past which a blast isn't felt
--============================================================--

local trauma = 0
local rng = Random.new()

local function addTrauma(amount)
	trauma = math.clamp(trauma + amount, 0, 1)
end

-- apply the shake AFTER the controller's camera bind (Camera.Value + 1)
RunService:BindToRenderStep("DuckCameraShake", Enum.RenderPriority.Camera.Value + 2, function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	trauma = math.max(0, trauma - DECAY * dt)
	if trauma <= 0 then return end

	local s = trauma * trauma -- square = punchy onset, soft tail
	local ox = rng:NextNumber(-1, 1) * MAX_OFFSET * s
	local oy = rng:NextNumber(-1, 1) * MAX_OFFSET * s
	local roll = rng:NextNumber(-1, 1) * MAX_ROLL * s
	-- offset is applied in camera-local space, so it reads as an on-screen jolt
	cam.CFrame = cam.CFrame * CFrame.new(ox, oy, 0) * CFrame.Angles(0, 0, roll)
end)

--------------------------------------------------------------------
-- explosions (everyone nearby feels it, scaled by distance)
--------------------------------------------------------------------
local effect = Remotes.get("WeaponEffect")
effect.OnClientEvent:Connect(function(kind, data)
	if kind ~= "explosion" or not data or not data.p then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local closeness
	if hrp then
		local dist = (hrp.Position - data.p).Magnitude
		closeness = math.clamp(1 - dist / EXPLOSION_RANGE, 0, 1)
	else
		closeness = 0.6 -- spectating: still feel a moderate thump
	end
	addTrauma(EXPLOSION_SHAKE * closeness)
end)

--------------------------------------------------------------------
-- taking damage + dying (local player only)
--------------------------------------------------------------------
local function onCharacter(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	local last = hum.Health
	hum.HealthChanged:Connect(function(h)
		if h < last then
			addTrauma(math.clamp((last - h) / 100, 0, 1) * HIT_SHAKE)
		end
		last = h
	end)
	hum.Died:Connect(function()
		addTrauma(DEATH_SHAKE)
	end)
end

if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)
