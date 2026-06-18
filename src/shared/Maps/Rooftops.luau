--!strict
-- Rooftops (ModuleScript) | ReplicatedStorage > Maps
-- Dusk city rooftops. Big, open, vertical -- two solid building tops flank a
-- central void you can knock ducks into, with floating ledges and a tower
-- climbing up the middle. Sunset horizon + a skyline of silhouettes behind.
--
-- Layered palette: warm bright rooftops up front, deep-blue skyline silhouettes
-- behind, and a dusk->sunset sky gradient furthest back.

return {
	name = "Rooftops",
	backdrop = Color3.fromRGB(46, 54, 92),   -- deep dusk sky (base/fallback)
	skyTop = Color3.fromRGB(38, 44, 86),     -- deep upper sky
	skyBottom = Color3.fromRGB(236, 142, 86), -- sunset glow at the horizon
	backdrop2 = Color3.fromRGB(232, 138, 84),
	accent = Color3.fromRGB(255, 210, 124),   -- warm neon ledge trim
	camera = { x = 0, y = 24, w = 184, h = 98 },
	killY = -34,

	platforms = {
		-- the two big building tops (ground level), with a central pit between
		{ x = -64, y = 0,  w = 44, h = 12, color = Color3.fromRGB(124, 100, 80) },
		{ x = 64,  y = 0,  w = 44, h = 12, color = Color3.fromRGB(124, 100, 80) },

		-- mid platforms over the pit
		{ x = -26, y = 12, w = 24, h = 4, color = Color3.fromRGB(168, 134, 102) },
		{ x = 26,  y = 12, w = 24, h = 4, color = Color3.fromRGB(168, 134, 102) },
		{ x = 0,   y = 8,  w = 20, h = 4, color = Color3.fromRGB(168, 134, 102) }, -- low center bridge

		-- upper ring -- brightest, catches the most light
		{ x = -46, y = 24, w = 18, h = 4, color = Color3.fromRGB(190, 156, 122) },
		{ x = 46,  y = 24, w = 18, h = 4, color = Color3.fromRGB(190, 156, 122) },
		{ x = 0,   y = 26, w = 26, h = 5, color = Color3.fromRGB(190, 156, 122) }, -- tower top

		-- antenna perch
		{ x = 0,   y = 42, w = 16, h = 3, color = Color3.fromRGB(208, 176, 140) },
	},

	-- where DUCKS spawn
	spawns = {
		{ x = -64, y = 10 }, { x = 64, y = 10 },
		{ x = -26, y = 18 }, { x = 26, y = 18 },
		{ x = -46, y = 31 }, { x = 46, y = 31 },
	},

	-- where WEAPON PICKUPS spawn (kept off the spawn roofs so you scramble for them)
	weaponSpawns = {
		{ x = 0, y = 12 },  { x = 0, y = 31 },  { x = 0, y = 46 },
		{ x = -26, y = 16 }, { x = 26, y = 16 },
		{ x = -46, y = 28 }, { x = 46, y = 28 },
	},

	-- background skyline silhouettes (non-colliding, behind the action) --
	-- darker than the rooftops so the foreground stays clearly readable
	decor = {
		{ x = -72, y = 18, w = 34, h = 80, color = Color3.fromRGB(28, 33, 60) },
		{ x = -34, y = 8,  w = 28, h = 56, color = Color3.fromRGB(32, 37, 66) },
		{ x = 4,   y = 14, w = 24, h = 68, color = Color3.fromRGB(25, 30, 56) },
		{ x = 40,  y = 6,  w = 30, h = 52, color = Color3.fromRGB(32, 37, 66) },
		{ x = 74,  y = 20, w = 36, h = 84, color = Color3.fromRGB(28, 33, 60) },
		-- a couple of antennae / water towers
		{ x = -34, y = 44, w = 2,  h = 22, color = Color3.fromRGB(22, 27, 48) },
		{ x = 40,  y = 38, w = 2,  h = 20, color = Color3.fromRGB(22, 27, 48) },
		{ x = 0,   y = 50, w = 10, h = 8,  color = Color3.fromRGB(38, 43, 74) },
	},
}
