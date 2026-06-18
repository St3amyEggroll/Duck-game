--!strict
-- Rooftops (ModuleScript) | ReplicatedStorage > Maps
-- Dusk city rooftops. Big, open, vertical -- two solid building tops flank a
-- central void you can knock ducks into, with floating ledges and a tower
-- climbing up the middle. Sunset horizon + a skyline of silhouettes behind.

return {
	name = "Rooftops",
	backdrop = Color3.fromRGB(46, 54, 92),   -- deep dusk sky
	backdrop2 = Color3.fromRGB(232, 138, 84), -- sunset band low on screen
	accent = Color3.fromRGB(255, 206, 120),   -- warm neon ledge trim
	camera = { x = 0, y = 24, w = 184, h = 98 },
	killY = -34,

	platforms = {
		-- the two big building tops (ground level), with a central pit between
		{ x = -64, y = 0,  w = 44, h = 12, color = Color3.fromRGB(108, 88, 70) },
		{ x = 64,  y = 0,  w = 44, h = 12, color = Color3.fromRGB(108, 88, 70) },

		-- mid platforms over the pit
		{ x = -26, y = 12, w = 24, h = 4, color = Color3.fromRGB(150, 120, 92) },
		{ x = 26,  y = 12, w = 24, h = 4, color = Color3.fromRGB(150, 120, 92) },
		{ x = 0,   y = 8,  w = 20, h = 4, color = Color3.fromRGB(150, 120, 92) }, -- low center bridge

		-- upper ring
		{ x = -46, y = 24, w = 18, h = 4, color = Color3.fromRGB(168, 138, 108) },
		{ x = 46,  y = 24, w = 18, h = 4, color = Color3.fromRGB(168, 138, 108) },
		{ x = 0,   y = 26, w = 26, h = 5, color = Color3.fromRGB(168, 138, 108) }, -- tower top

		-- antenna perch
		{ x = 0,   y = 42, w = 16, h = 3, color = Color3.fromRGB(190, 160, 128) },
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

	-- background skyline silhouettes (non-colliding, behind the action)
	decor = {
		{ x = -72, y = 18, w = 34, h = 80, color = Color3.fromRGB(34, 40, 70) },
		{ x = -34, y = 8,  w = 28, h = 56, color = Color3.fromRGB(38, 44, 76) },
		{ x = 4,   y = 14, w = 24, h = 68, color = Color3.fromRGB(31, 37, 66) },
		{ x = 40,  y = 6,  w = 30, h = 52, color = Color3.fromRGB(38, 44, 76) },
		{ x = 74,  y = 20, w = 36, h = 84, color = Color3.fromRGB(34, 40, 70) },
		-- a couple of antennae / water towers
		{ x = -34, y = 44, w = 2,  h = 22, color = Color3.fromRGB(28, 33, 58) },
		{ x = 40,  y = 38, w = 2,  h = 20, color = Color3.fromRGB(28, 33, 58) },
		{ x = 0,   y = 50, w = 10, h = 8,  color = Color3.fromRGB(44, 50, 84) },
	},
}
