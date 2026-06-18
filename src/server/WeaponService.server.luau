-- WeaponService (Script) | ServerScriptService
-- Data-driven, server-authoritative weapons. Hitscan / melee / grenades.
-- Anti-exploit pass: token-bucket rate limits + angle/origin sanity on the
-- fire & aim remotes. Also broadcasts a "hit" effect so clients can puff
-- feathers + flash the struck duck.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local DuckShared = ReplicatedStorage:WaitForChild("DuckShared")
local AimUtil = require(DuckShared:WaitForChild("AimUtil"))
local Config = require(DuckShared:WaitForChild("Config"))
local Remotes = require(DuckShared:WaitForChild("Remotes"))
local WeaponDefs = require(DuckShared:WaitForChild("WeaponDefs"))

local MAX_TILT = Config.AIM_MAX_TILT or math.rad(28)
local TILT_SIGN = Config.AIM_TILT_SIGN or 1

local KNOCKBACK = Config.KNOCKBACK
local MAX_PLANE_DRIFT = Config.MAX_PLANE_DRIFT -- shots are rejected if the shooter's
-- muzzle is this far off the Z=0 play plane (a tampered client flying in Z).

-- client remotes (the DuckRemotes folder + events are owned by DuckShared/Remotes)
local remotes = Remotes.folder
local fireRemote = Remotes.get("WeaponFire")
local aimRemote = Remotes.get("WeaponAim")
local effectRemote = Remotes.get("WeaponEffect")

-- tell every client a duck just got hit, so they can puff feathers + flash
-- it. `lethal` drives the kill hitstop client-side.
local function broadcastHit(model, lethal)
	if not model then return end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local pos = (hrp and hrp.Position) or model:GetPivot().Position
	effectRemote:FireAllClients("hit", { m = model, p = pos, lethal = lethal == true })
end

-- server-only equip channel (PickupService fires this)
local duckServer = ServerStorage:FindFirstChild("DuckServer")
if not duckServer then
	duckServer = Instance.new("Folder"); duckServer.Name = "DuckServer"; duckServer.Parent = ServerStorage
end
local equipRequest = duckServer:FindFirstChild("EquipRequest")
if not equipRequest then
	equipRequest = Instance.new("BindableEvent"); equipRequest.Name = "EquipRequest"; equipRequest.Parent = duckServer
end

-- ragdoll-launch channel (created by RagdollService).
local launchEvent = duckServer:WaitForChild("RagdollLaunch", 10)

-- weapon definitions (shared loader)
local _, DEFS = WeaponDefs.loadAll()

local state = {} -- [Player] = { def, ammo, lastFire, gun, motor, muzzle, torso, rootJoint, restC0 }

local function buildModel(def): Model
	local weapons = ReplicatedStorage:FindFirstChild("Weapons")
	local template = weapons and weapons:FindFirstChild(def.name)
	if template and template:IsA("Model") and template.PrimaryPart then
		return template:Clone()
	end
	local gun = Instance.new("Model"); gun.Name = def.name
	local handle = Instance.new("Part")
	handle.Name = "Handle"; handle.Size = Vector3.new(0.5, 0.7, 2.4)
	handle.Color = def.color or Color3.fromRGB(45, 45, 55)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false; handle.Massless = true; handle.Parent = gun
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"; barrel.Size = Vector3.new(0.3, 0.3, 1.4)
	barrel.Color = Color3.fromRGB(28, 28, 36); barrel.Material = Enum.Material.SmoothPlastic
	barrel.CanCollide = false; barrel.Massless = true; barrel.Parent = gun
	local w = Instance.new("Weld"); w.Part0 = handle; w.Part1 = barrel; w.C0 = CFrame.new(0, 0.15, -1.4); w.Parent = handle
	local muz = Instance.new("Attachment"); muz.Name = "Muzzle"; muz.Position = Vector3.new(0, 0.15, -2.1); muz.Parent = handle
	gun.PrimaryPart = handle
	return gun
end

local function unequip(player)
	local s = state[player]
	if not s then return end
	if s.rootJoint and s.rootJoint.Parent and s.restC0 then s.rootJoint.C0 = s.restC0 end
	if s.gun then s.gun:Destroy() end
	state[player] = nil
end

local function equip(player, weaponName)
	local def = DEFS[weaponName]
	if not def then return end
	local char = player.Character
	if not char then return end
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not torso or not hrp then return end
	local rootJoint = hrp:FindFirstChild("RootJoint")

	unequip(player)

	local gun = buildModel(def)
	local handle = gun.PrimaryPart :: BasePart
	gun.Parent = char
	local motor = Instance.new("Motor6D")
	motor.Name = "GunMotor"; motor.Part0 = torso; motor.Part1 = handle; motor.Parent = torso

	gun:SetAttribute("Weapon", def.name)
	gun:SetAttribute("Ammo", def.ammo or 0)
	gun:SetAttribute("FireRate", def.fireRate or 4)

	state[player] = {
		def = def, ammo = def.ammo or 0, lastFire = 0,
		gun = gun, motor = motor, muzzle = handle:FindFirstChild("Muzzle"),
		torso = torso, rootJoint = rootJoint, restC0 = rootJoint and rootJoint.C0,
	}
end
equipRequest.Event:Connect(equip)

-- ===== fire behaviours =====
local function newParams(char)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = { char }
	return p
end

local function knockbackVec(def, angle)
	local force = def.knockback or KNOCKBACK
	local dir = Vector3.new(math.cos(angle), math.sin(angle), 0)
	return dir * force + Vector3.new(0, force * 0.55, 0)
end

local function doHitscan(char, def, origin, angle)
	local endpoints = {}
	local victims = {} -- [model] = true   (hit at least once this shot)
	local killed = {}  -- [model] = true   (died this shot)
	for _ = 1, (def.pellets or 1) do
		local a = angle + (math.random() - 0.5) * 2 * (def.spread or 0)
		local dir = Vector3.new(math.cos(a), math.sin(a), 0)
		local result = workspace:Raycast(origin, dir * (def.range or 200), newParams(char))
		local endp = result and result.Position or (origin + dir * (def.range or 200))
		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			local h = model and model:FindFirstChildOfClass("Humanoid")
			if h and model ~= char and h.Health > 0 then
				h:TakeDamage(def.damage or 50)
				victims[model] = true
				if h.Health <= 0 then killed[model] = true end
			end
		end
		table.insert(endpoints, endp)
	end
	-- resolve all pellets first, then puff each victim ONCE with the correct
	-- final lethal flag (a shotgun shouldn't fire 6 puffs at one duck).
	for model in victims do
		broadcastHit(model, killed[model] == true)
	end
	if launchEvent then
		for model in killed do
			launchEvent:Fire(model, knockbackVec(def, angle))
		end
	end
	effectRemote:FireAllClients("hitscan", { o = origin, e = endpoints, c = def.tracerColor })
end

local function doMelee(char, def, origin, angle)
	local range = def.range or 8
	local dir = Vector3.new(math.cos(angle), math.sin(angle), 0)
	local center = origin + dir * (range * 0.5)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = { char }
	local hit = {}
	for _, part in workspace:GetPartBoundsInRadius(center, range * 0.65, op) do
		local model = part:FindFirstAncestorOfClass("Model")
		local h = model and model:FindFirstChildOfClass("Humanoid")
		if h and model ~= char and h.Health > 0 and not hit[h] then
			local to = model:GetPivot().Position - origin
			if Vector3.new(to.X, to.Y, 0).Unit:Dot(dir) > 0 then
				hit[h] = true
				h:TakeDamage(def.damage or 100)
				local lethal = h.Health <= 0
				broadcastHit(model, lethal)
				if lethal and launchEvent then
					launchEvent:Fire(model, knockbackVec(def, angle))
				end
			end
		end
	end
	effectRemote:FireAllClients("melee", { o = origin, a = angle, r = range, c = def.swingColor })
end

local function explode(pos, def, char)
	local radius = def.blastRadius or 12
	local op = OverlapParams.new()
	local done = {}
	for _, part in workspace:GetPartBoundsInRadius(pos, radius, op) do
		local model = part:FindFirstAncestorOfClass("Model")
		local h = model and model:FindFirstChildOfClass("Humanoid")
		local hrp = model and model:FindFirstChild("HumanoidRootPart")
		if h and hrp and h.Health > 0 and not done[h] then
			done[h] = true
			local dist = (hrp.Position - pos).Magnitude
			local fall = math.clamp(1 - dist / radius, 0, 1)
			local away = hrp.Position - pos
			away = Vector3.new(away.X, away.Y, 0)
			if away.Magnitude < 0.1 then away = Vector3.new(0, 1, 0) end
			local launch = away.Unit * (def.blastForce or 60) * (0.5 + fall)
				+ Vector3.new(0, (def.blastForce or 60) * 0.55, 0)
			h:TakeDamage((def.damage or 100) * fall)
			local lethal = h.Health <= 0
			broadcastHit(model, lethal)
			if lethal and launchEvent then
				launchEvent:Fire(model, launch)
			else
				hrp.AssemblyLinearVelocity = launch
			end
		end
	end
	effectRemote:FireAllClients("explosion", { p = pos, r = radius, c = def.explosionColor })
end

local function doGrenade(char, def, origin, angle)
	local dir = Vector3.new(math.cos(angle), math.sin(angle), 0)
	local nade = Instance.new("Part")
	nade.Name = "Grenade"
	nade.Shape = Enum.PartType.Ball
	nade.Size = Vector3.new(1.2, 1.2, 1.2)
	nade.Color = def.color or Color3.fromRGB(110, 190, 110)
	nade.Material = Enum.Material.SmoothPlastic
	nade.CanCollide = true
	nade.CFrame = CFrame.new(origin + dir * 2)
	nade.Parent = workspace
	nade.AssemblyLinearVelocity = dir * (def.throwSpeed or 60) + Vector3.new(0, 16, 0)
	pcall(function() nade:SetNetworkOwner(nil) end)

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not nade.Parent then conn:Disconnect() return end
		local p = nade.Position
		if math.abs(p.Z) > 0.01 then nade.CFrame = CFrame.new(p.X, p.Y, 0) end
		local v = nade.AssemblyLinearVelocity
		if v.Z ~= 0 then nade.AssemblyLinearVelocity = Vector3.new(v.X, v.Y, 0) end
	end)

	task.delay(def.fuse or 2, function()
		if conn then conn:Disconnect() end
		local pos = nade.Position
		nade:Destroy()
		explode(pos, def, char)
	end)
end

--========================  ANTI-EXPLOIT  ========================--
-- Per-player token buckets: a hard ceiling that drops floods cheaply, BEFORE we
-- do any raycasting / CFrame work. The per-weapon fire-rate gate below still
-- controls legit cadence; these ceilings sit well above any real rate (fastest
-- weapon = 4/s; the client streams aim ~25/s) and only kill spam.
local function makeLimiter(ratePerSec, burst)
	local buckets = {} -- [Player] = { tokens, last }
	local L = {}
	function L.allow(player)
		local now = os.clock()
		local b = buckets[player]
		if not b then b = { tokens = burst, last = now }; buckets[player] = b end
		b.tokens = math.min(burst, b.tokens + (now - b.last) * ratePerSec)
		b.last = now
		if b.tokens < 1 then return false end
		b.tokens -= 1
		return true
	end
	function L.drop(player) buckets[player] = nil end
	return L
end
local fireLimiter = makeLimiter(20, 8)
local aimLimiter  = makeLimiter(45, 20)

-- reject NaN / inf angles before they poison raycasts and replicated CFrames
local function finiteAngle(angle)
	if typeof(angle) ~= "number" then return nil end
	if angle ~= angle then return nil end -- NaN
	if angle == math.huge or angle == -math.huge then return nil end
	return angle
end

-- shot origin is server-derived (muzzle/torso), so it can't be faked -- this
-- just rejects a corrupted/off-plane shooter
local function originSane(o)
	if o.X ~= o.X or o.Y ~= o.Y or o.Z ~= o.Z then return false end -- NaN
	if math.abs(o.X) == math.huge or math.abs(o.Y) == math.huge then return false end
	if math.abs(o.Z) > MAX_PLANE_DRIFT then return false end
	return true
end
--================================================================--

-- ===== remotes =====
aimRemote.OnServerEvent:Connect(function(player, angle)
	if not aimLimiter.allow(player) then return end
	local a = finiteAngle(angle)
	if not a then return end
	local s = state[player]
	if not s then return end
	AimUtil.applyAim(s.torso, s.motor, s.rootJoint, s.restC0, a, MAX_TILT, TILT_SIGN)
end)

fireRemote.OnServerEvent:Connect(function(player, angle)
	if not remotes:GetAttribute("RoundActive") then return end
	if not fireLimiter.allow(player) then return end
	local a = finiteAngle(angle)
	if not a then return end
	local s = state[player]
	if not s then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if s.ammo <= 0 then return end
	if not s.torso or not s.torso.Parent then return end

	local def = s.def
	local now = os.clock()
	if now - s.lastFire < 1 / (def.fireRate or 4) then return end
	s.lastFire = now

	s.ammo -= 1
	if s.gun then s.gun:SetAttribute("Ammo", s.ammo) end

	AimUtil.applyAim(s.torso, s.motor, s.rootJoint, s.restC0, a, MAX_TILT, TILT_SIGN)
	local origin = (s.muzzle and s.muzzle.WorldPosition) or (s.torso.Position + Vector3.new(0, 0.5, 0))
	if not originSane(origin) then return end

	if def.projectile == "melee" then
		doMelee(char, def, origin, a)
	elseif def.projectile == "grenade" then
		doGrenade(char, def, origin, a)
	else
		doHitscan(char, def, origin, a)
	end
end)

local function onCharacter(player, char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then hum.Died:Connect(function() unequip(player) end) end
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(function(c) onCharacter(player, c) end)
	if player.Character then task.spawn(onCharacter, player, player.Character) end
	player.CharacterRemoving:Connect(function() unequip(player) end)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in Players:GetPlayers() do hookPlayer(p) end
Players.PlayerRemoving:Connect(function(p)
	state[p] = nil
	fireLimiter.drop(p) -- don't leak buckets
	aimLimiter.drop(p)
end)
