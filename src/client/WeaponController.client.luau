-- WeaponController (LocalScript) | StarterPlayer > StarterPlayerScripts
-- Thin client: aims your gun, requests fire, draws every shot the server
-- reports, and renders hit feedback (feather puff + white flash) on the duck
-- the server says got hit.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer

local DuckShared = ReplicatedStorage:WaitForChild("DuckShared")
local AimUtil = require(DuckShared:WaitForChild("AimUtil"))
local Config = require(DuckShared:WaitForChild("Config"))
local PixelUI = require(DuckShared:WaitForChild("PixelUI"))
local PlaneUtil = require(DuckShared:WaitForChild("PlaneUtil"))
local Remotes = require(DuckShared:WaitForChild("Remotes"))

local PLANE_Z = Config.PLANE_Z or 0
local MAX_TILT = Config.AIM_MAX_TILT or math.rad(28)
local TILT_SIGN = Config.AIM_TILT_SIGN or 1
local AIM_SEND_INTERVAL = 0.04

--========================  HIT FEEDBACK  ========================--
local HIT_FLASH_TIME = 0.08                     -- white flash duration on a struck duck
local FEATHER_COLOR  = Color3.fromRGB(250, 240, 200)
local PUFF_COLOR     = Color3.fromRGB(220, 70, 80) -- a few of these only on a kill
--================================================================--

local remotes = Remotes.folder
local fireRemote = Remotes.get("WeaponFire")
local aimRemote = Remotes.get("WeaponAim")
local effectRemote = Remotes.get("WeaponEffect")
local roundState = Remotes.get("RoundState")

local char, torso, rootJoint, restC0
local gunMotor, handle, muzzle, gunModel
local roundActive = false
local lastFire, lastAimSend = 0, 0

local gui = Instance.new("ScreenGui")
gui.Name = "DuckWeaponHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")
local ammoLabel = PixelUI.label({
	parent = gui, text = "", textSize = 22, color = PixelUI.PALETTE.accent,
	size = UDim2.fromOffset(220, 30), position = UDim2.new(0.5, 0, 1, -66),
})
ammoLabel.AnchorPoint = Vector2.new(0.5, 1) -- sits just above the health bar
ammoLabel.Visible = false

-- crosshair that follows the cursor while you're alive
local crosshair = PixelUI.crosshair({ parent = gui, color = PixelUI.PALETTE.accent })
crosshair.Visible = false

RunService.RenderStepped:Connect(function()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local alive = hum ~= nil and hum.Health > 0
	crosshair.Visible = alive
	if not alive then return end
	local m = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	crosshair.Position = UDim2.fromOffset(m.X + inset.X, m.Y + inset.Y)
end)

local function clearGun()
	gunMotor, handle, muzzle, gunModel = nil, nil, nil, nil
	if rootJoint and rootJoint.Parent and restC0 then rootJoint.C0 = restC0 end
	ammoLabel.Visible = false
end

local function refreshGun()
	if not torso then clearGun() return end
	local m = torso:FindFirstChild("GunMotor")
	if m and m:IsA("Motor6D") and m.Part1 then
		gunMotor, handle = m, m.Part1
		gunModel = handle.Parent
		muzzle = handle:FindFirstChild("Muzzle")
		ammoLabel.Visible = true
	else
		clearGun()
	end
end

local function onCharacter(c)
	char = c
	torso = c:WaitForChild("Torso", 5) or c:FindFirstChild("UpperTorso")
	local hrp = c:WaitForChild("HumanoidRootPart", 5)
	rootJoint = hrp and hrp:WaitForChild("RootJoint", 5)
	restC0 = rootJoint and rootJoint.C0
	clearGun()
	if torso then
		torso.ChildAdded:Connect(function(ch) if ch.Name == "GunMotor" then task.wait() refreshGun() end end)
		torso.ChildRemoved:Connect(function(ch) if ch.Name == "GunMotor" then refreshGun() end end)
	end
	refreshGun()
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

roundState.OnClientEvent:Connect(function(state) roundActive = (state.phase == "active") end)

local function syncRoundActive()
	roundActive = remotes:GetAttribute("RoundActive") == true
end
syncRoundActive()
remotes:GetAttributeChangedSignal("RoundActive"):Connect(syncRoundActive)

RunService.RenderStepped:Connect(function()
	if not gunMotor or not torso or not torso.Parent then return end
	local aimPoint = PlaneUtil.mouseWorldOnPlane(PLANE_Z)
	if not aimPoint then return end
	local pivot = torso.Position + Vector3.new(0, 0.5, 0)
	local d = aimPoint - pivot
	d = Vector3.new(d.X, d.Y, 0)
	if d.Magnitude < 1e-3 then return end
	local angle = math.atan2(d.Y, d.X)
	AimUtil.applyAim(torso, gunMotor, rootJoint, restC0, angle, MAX_TILT, TILT_SIGN)
	local now = os.clock()
	if now - lastAimSend >= AIM_SEND_INTERVAL then
		lastAimSend = now
		aimRemote:FireServer(angle)
	end
	if gunModel then
		local ammo = tonumber(gunModel:GetAttribute("Ammo")) or 0
		ammoLabel.Text = "AMMO " .. tostring(ammo)
		ammoLabel.TextColor3 = (ammo <= 2) and PixelUI.PALETTE.lowAmmo or PixelUI.PALETTE.accent
	end
end)

local function fire()
	if not (roundActive or remotes:GetAttribute("RoundActive") == true) or not gunMotor or not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if gunModel and (gunModel:GetAttribute("Ammo") or 0) <= 0 then return end
	local fr = (gunModel and gunModel:GetAttribute("FireRate")) or 4
	local now = os.clock()
	if now - lastFire < 1 / fr then return end
	lastFire = now
	local aimPoint = PlaneUtil.mouseWorldOnPlane(PLANE_Z)
	if not aimPoint then return end
	local pivot = torso.Position + Vector3.new(0, 0.5, 0)
	local d = aimPoint - pivot
	d = Vector3.new(d.X, d.Y, 0)
	if d.Magnitude < 1e-3 then return end
	fireRemote:FireServer(math.atan2(d.Y, d.X))
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then fire() end
end)

--------------------------------------------------------------------
-- shot rendering for ALL players' shots
--------------------------------------------------------------------
local function quickPart(props, lifetime)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in props do p[k] = v end
	p.Parent = workspace
	Debris:AddItem(p, lifetime)
	return p
end

local function flash(pos, color)
	quickPart({
		Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8),
		Color = color or Color3.fromRGB(255, 240, 180), CFrame = CFrame.new(pos),
	}, 0.05)
end

-- brief white flash over the whole struck duck (Highlight = no need to
-- remember/restore each part's color)
local function flashDuck(model)
	if not model or not model.Parent then return end
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.25
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = model
	hl.Parent = model
	Debris:AddItem(hl, HIT_FLASH_TIME)
end

-- feathers scatter out of the hit point in the XY plane, fading as they go.
-- More feathers + a few red puffs on a kill. Client-only, purely cosmetic.
local function featherBurst(pos, lethal)
	local n = lethal and 14 or 7
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + (math.random() - 0.5)
		local f = quickPart({
			Size = Vector3.new(0.3, 0.3, 0.06),
			Material = Enum.Material.SmoothPlastic,
			Color = (lethal and i % 4 == 0) and PUFF_COLOR or FEATHER_COLOR,
			CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
		}, 0.5)
		local dist = (lethal and 5 or 3) + math.random() * 2
		local target = pos + Vector3.new(math.cos(a) * dist, math.sin(a) * dist + 1, 0)
		TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(target) * CFrame.Angles(math.random() * 9, math.random() * 9, math.random() * 9),
			Transparency = 1,
		}):Play()
	end
end

effectRemote.OnClientEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end

	if kind == "hitscan" then
		local origin = data.o
		for _, endp in ipairs(data.e or {}) do
			local length = (endp - origin).Magnitude
			if length > 0.05 then
				quickPart({
					Size = Vector3.new(0.22, 0.22, length),
					Color = data.c or Color3.fromRGB(255, 230, 120),
					CFrame = CFrame.lookAt(origin, endp) * CFrame.new(0, 0, -length / 2),
				}, 0.07)
			end
		end
		flash(origin)

	elseif kind == "melee" then
		local origin = data.o
		local dir = Vector3.new(math.cos(data.a), math.sin(data.a), 0)
		local range = data.r or 8
		local center = origin + dir * (range * 0.5)
		quickPart({
			Size = Vector3.new(range, 1.4, 0.2),
			Color = data.c or Color3.fromRGB(220, 240, 255),
			Transparency = 0.2,
			CFrame = CFrame.lookAt(center, center + Vector3.new(0, 0, 1)) * CFrame.Angles(0, 0, data.a),
		}, 0.12)

	elseif kind == "explosion" then
		local ball = quickPart({
			Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3),
			Color = data.c or Color3.fromRGB(255, 170, 60), CFrame = CFrame.new(data.p),
		}, 0.35)
		local r = (data.r or 12) * 2
		TweenService:Create(ball, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(r, r, r), Transparency = 1 }):Play()

	elseif kind == "hit" then
		if data.m then flashDuck(data.m) end
		if data.p then featherBurst(data.p, data.lethal == true) end
	end
end)
