-- MapService (ModuleScript) | ServerScriptService
-- Turns a map DATA table into a real Workspace.CurrentMap model, and manages
-- swapping between maps. The client camera reads CurrentMap.CameraFrame; the
-- round manager reads CurrentMap.Spawns and the "KillY" attribute.
--
-- Duck-Game look (all driven by the data tables, world textures stay flat):
--   * layered backdrop  -- a far sky plane + an optional horizon band
--   * Decor folder       -- non-colliding background silhouettes (buildings,
--                           pipes, columns) sitting BEHIND the play plane
--   * platform top-trim   -- a bright cap strip on each platform's top edge,
--                           the crisp 2D-platformer "ledge" highlight

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("DuckShared"):WaitForChild("Config"))
local PLANE_Z = Config.PLANE_Z
local PLATFORM_DEPTH = 8       -- thick in Z so the duck (locked at Z=0) always collides
local TRIM_H = 0.9             -- thickness of the bright top-edge cap
local DECOR_Z = PLANE_Z - 12   -- background decor sits behind the action
local BAND_Z = PLANE_Z - 28    -- horizon band, just in front of the far backdrop
local BACK_Z = PLANE_Z - 30    -- far backdrop

local MapService = {}
MapService.current = nil      -- the loaded Model
MapService.currentData = nil  -- the data table it was built from
local lastName = nil

-- gather every map module sitting in ReplicatedStorage/Maps
local function loadMapModules(): {any}
	local maps = {}
	local folder = ReplicatedStorage:FindFirstChild("Maps")
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("ModuleScript") then
				local ok, data = pcall(require, m)
				if ok and type(data) == "table" then
					table.insert(maps, data)
				end
			end
		end
	end
	return maps
end

-- nudge a color lighter (+) or darker (-) for cheap shading
local function shift(c: Color3, amt: number): Color3
	return Color3.new(
		math.clamp(c.R + amt, 0, 1),
		math.clamp(c.G + amt, 0, 1),
		math.clamp(c.B + amt, 0, 1))
end

-- one-time flat lighting so the world reads as clean, bold 2D
local styled = false
local function setupStyle()
	if styled then return end
	styled = true
	Lighting.GlobalShadows = false
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(160, 160, 168)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 178)
	Lighting.ClockTime = 14
	Lighting.FogEnd = 1e6
end

local function makePart(name, size, pos, color, canCollide, transparency): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.Position = pos
	if color then p.Color = color end
	p.CanCollide = canCollide
	p.Transparency = transparency or 0
	return p
end

local function build(data): Model
	local model = Instance.new("Model")
	model.Name = "CurrentMap"
	model:SetAttribute("MapName", data.name or "Map")
	model:SetAttribute("KillY", data.killY or Config.DEFAULT_KILL_Y)

	local cam = data.camera or { x = 0, y = 16, w = 120, h = 64 }

	-- far backdrop (fills the framed view)
	local backdrop = makePart("Backdrop",
		Vector3.new(cam.w * 2.4, cam.h * 2.4, 1),
		Vector3.new(cam.x, cam.y, BACK_Z),
		data.backdrop or Color3.fromRGB(60, 80, 120), false, 0)
	backdrop.Parent = model

	-- optional horizon band across the lower portion (sky/ground split, sunset, etc.)
	if data.backdrop2 then
		local band = makePart("Horizon",
			Vector3.new(cam.w * 2.4, cam.h * 0.55, 1),
			Vector3.new(cam.x, cam.y - cam.h * 0.14, BAND_Z),
			data.backdrop2, false, 0)
		band.Parent = model
	end

	-- background decor silhouettes (non-colliding, behind the play plane)
	if data.decor and #data.decor > 0 then
		local decor = Instance.new("Folder")
		decor.Name = "Decor"
		decor.Parent = model
		for i, d in ipairs(data.decor) do
			local part = makePart("Decor" .. i,
				Vector3.new(d.w, d.h, 2),
				Vector3.new(d.x, d.y, d.z or DECOR_Z),
				d.color or Color3.fromRGB(40, 46, 70), false, d.transparency or 0)
			part.Parent = decor
		end
	end

	-- platforms (collision + flat color) with a bright top-edge cap
	local geo = Instance.new("Folder")
	geo.Name = "Geometry"
	geo.Parent = model
	for i, plat in ipairs(data.platforms or {}) do
		local baseColor = plat.color or Color3.fromRGB(90, 80, 70)
		local part = makePart("Platform" .. i,
			Vector3.new(plat.w, plat.h, PLATFORM_DEPTH),
			Vector3.new(plat.x, plat.y, PLANE_Z),
			baseColor, true, 0)
		part.Parent = geo

		-- top-edge trim: a thin bright bar flush with the platform's top, poking
		-- 0.1 proud of the front face so it never z-fights. Non-colliding, so it
		-- never changes how the duck stands on the platform.
		if plat.trim ~= false then
			local trimColor = plat.trim or data.accent or shift(baseColor, 0.18)
			if typeof(trimColor) ~= "Color3" then trimColor = shift(baseColor, 0.18) end
			local cap = makePart("Trim" .. i,
				Vector3.new(plat.w, TRIM_H, PLATFORM_DEPTH + 0.2),
				Vector3.new(plat.x, plat.y + plat.h / 2 - TRIM_H / 2, PLANE_Z),
				trimColor, false, 0)
			cap.Parent = geo
		end
	end

	-- invisible camera frame (the client camera frames exactly this rectangle)
	local frame = makePart("CameraFrame",
		Vector3.new(cam.w, cam.h, 1),
		Vector3.new(cam.x, cam.y, PLANE_Z), nil, false, 1)
	frame.Parent = model

	-- invisible spawn markers (read by the round manager)
	local spawns = Instance.new("Folder")
	spawns.Name = "Spawns"
	spawns.Parent = model
	for i, s in ipairs(data.spawns or {}) do
		local sp = makePart("Spawn" .. i, Vector3.new(2, 2, 2),
			Vector3.new(s.x, s.y, PLANE_Z), nil, false, 1)
		sp.Parent = spawns
	end

	model.Parent = workspace
	return model
end

function MapService.load(data)
	setupStyle()
	if MapService.current then
		MapService.current:Destroy()
	end
	MapService.current = build(data)
	MapService.currentData = data
	return MapService.current
end

function MapService.loadRandom()
	local maps = loadMapModules()
	if #maps == 0 then
		warn("[MapService] No maps found in ReplicatedStorage/Maps")
		return
	end
	local pick = maps[1]
	if #maps > 1 then
		local tries = 0
		repeat
			pick = maps[math.random(#maps)]
			tries += 1
		until pick.name ~= lastName or tries > 10
	end
	lastName = pick.name
	return MapService.load(pick)
end

function MapService.getSpawns(): {Vector3}
	local out = {}
	local cur = MapService.current
	local folder = cur and cur:FindFirstChild("Spawns")
	if folder then
		for _, p in folder:GetChildren() do
			if p:IsA("BasePart") then table.insert(out, p.Position) end
		end
	end
	return out
end

function MapService.getKillY(): number
	local cur = MapService.current
	return (cur and cur:GetAttribute("KillY")) or Config.DEFAULT_KILL_Y
end

return MapService
