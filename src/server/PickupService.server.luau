-- PickupService (Script) | ServerScriptService
-- Keeps the current map stocked with weapon pickups. Walk into one to grab it.
-- Robust version: a per-frame watcher ensures pickups always exist, regardless
-- of map-load timing (the old version could miss the map and spawn nothing).

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MapService = require(ServerScriptService:WaitForChild("MapService"))
local WeaponDefs = require(ReplicatedStorage:WaitForChild("DuckShared"):WaitForChild("WeaponDefs"))

local RESPAWN_TIME = 8

-- equip channel (don't hang forever -- warn if WeaponService didn't make it)
local equipRequest
do
	local folder = ServerStorage:WaitForChild("DuckServer", 10)
	equipRequest = folder and folder:WaitForChild("EquipRequest", 10)
	if not equipRequest then
		warn("[PickupService] EquipRequest missing -- is WeaponService a Script in ServerScriptService?")
	end
end

-- which weapons can drop (shared loader, mapped to { name, pickup color })
local WEAPONS = {}
do
	local defs = WeaponDefs.loadAll()
	for _, d in defs do
		table.insert(WEAPONS, { name = d.name, color = d.color or d.tracerColor or Color3.fromRGB(255, 220, 120) })
	end
end
if #WEAPONS == 0 then
	warn("[PickupService] No weapons found in ReplicatedStorage/WeaponData -- check the folder name and that the weapons are ModuleScripts.")
end

local function makePickup(parent, pos, point)
	local entry = WEAPONS[math.random(#WEAPONS)]

	local pick = Instance.new("Part")
	pick.Name = "Pickup"
	pick.Size = Vector3.new(2.4, 2.4, 0.6)
	pick.Color = entry.color
	pick.Material = Enum.Material.Neon
	pick.Transparency = 0.15
	pick.Anchored = true
	pick.CanCollide = false
	pick.CFrame = CFrame.new(pos)
	pick:SetAttribute("Weapon", entry.name)
	pick:SetAttribute("Available", true)
	pick.Parent = parent

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(130, 28)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = pick
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0.3
	lbl.Text = string.upper(entry.name)
	lbl.Parent = bb

	pick.Touched:Connect(function(hit)
		if pick:GetAttribute("Available") ~= true then return end
		local model = hit:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		if not plr then return end
		pick:SetAttribute("Available", false)
		if equipRequest then equipRequest:Fire(plr, entry.name) end
		pick:Destroy()
		point.part = nil
		point.nextSpawn = os.clock() + RESPAWN_TIME
	end)

	point.part = pick
end

-- rebuild the list of spawn points whenever the map changes
local currentMap = nil
local points = {}

local function rebuildForMap()
	points = {}
	local data = MapService.currentData
	local pts = data and (data.weaponSpawns or data.spawns) or {}
	for _, s in ipairs(pts) do
		table.insert(points, { pos = Vector3.new(s.x, s.y, 0), part = nil, nextSpawn = 0 })
	end
end

-- watcher: every frame, make sure the current map has its pickups
RunService.Heartbeat:Connect(function()
	if #WEAPONS == 0 then return end
	local map = workspace:FindFirstChild("CurrentMap")
	if not map then
		currentMap = nil
		return
	end
	if map ~= currentMap then
		currentMap = map
		rebuildForMap()
	end
	local now = os.clock()
	for _, point in ipairs(points) do
		if (not point.part or not point.part.Parent) and now >= point.nextSpawn then
			makePickup(map, point.pos, point)
		end
	end
end)
