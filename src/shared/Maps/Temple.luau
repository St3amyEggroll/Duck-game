--!strict
-- Temple (ModuleScript) | ReplicatedStorage > Maps
-- A ruined jungle temple. Open sides (easy ring-outs, like Rooftops) but a
-- climbable stepped pyramid up the middle to an altar. Stone blocks, columns
-- and foliage behind, gold ledge trim.
--
-- Layered palette: warm sunlit stone up front, deep-green jungle behind, and a
-- teal->misty sky gradient furthest back.

return {
	name = "Temple",
	backdrop = Color3.fromRGB(42, 70, 64),    -- jungle teal (base/fallback)
	skyTop = Color3.fromRGB(34, 60, 56),      -- canopy shade up high
	skyBottom = Color3.fromRGB(104, 138, 118), -- misty horizon
	backdrop2 = Color3.fromRGB(96, 128, 110),
	accent = Color3.fromRGB(238, 206, 116),   -- gold trim
	camera = { x = 0, y = 22, w = 176, h = 94 },
	killY = -32,

	platforms = {
		-- side stone roofs with an open void between them -- warm bright stone
		{ x = -60, y = 2, w = 40, h = 12, color = Color3.fromRGB(150, 142, 116) },
		{ x = 60,  y = 2, w = 40, h = 12, color = Color3.fromRGB(150, 142, 116) },

		-- stepped pyramid up the middle (gets brighter toward the altar)
		{ x = 0,   y = 4,  w = 30, h = 4, color = Color3.fromRGB(162, 152, 124) },
		{ x = -22, y = 14, w = 18, h = 4, color = Color3.fromRGB(172, 162, 132) },
		{ x = 22,  y = 14, w = 18, h = 4, color = Color3.fromRGB(172, 162, 132) },
		{ x = 0,   y = 22, w = 22, h = 5, color = Color3.fromRGB(182, 172, 140) },
		{ x = 0,   y = 38, w = 16, h = 4, color = Color3.fromRGB(196, 184, 150) }, -- altar

		-- high side ledges
		{ x = -42, y = 24, w = 16, h = 4, color = Color3.fromRGB(172, 162, 132) },
		{ x = 42,  y = 24, w = 16, h = 4, color = Color3.fromRGB(172, 162, 132) },
	},

	spawns = {
		{ x = -60, y = 12 }, { x = 60, y = 12 },
		{ x = -22, y = 20 }, { x = 22, y = 20 },
		{ x = -42, y = 30 }, { x = 42, y = 30 },
	},

	weaponSpawns = {
		{ x = 0, y = 8 },   { x = 0, y = 27 },  { x = 0, y = 42 },
		{ x = -22, y = 20 }, { x = 22, y = 20 },
		{ x = -42, y = 28 }, { x = 42, y = 28 },
	},

	-- temple columns + foliage behind -- deep desaturated green, recedes
	decor = {
		{ x = -40, y = 24, w = 7, h = 60, color = Color3.fromRGB(48, 64, 56) }, -- columns
		{ x = -14, y = 28, w = 7, h = 64, color = Color3.fromRGB(44, 60, 52) },
		{ x = 14,  y = 28, w = 7, h = 64, color = Color3.fromRGB(44, 60, 52) },
		{ x = 40,  y = 24, w = 7, h = 60, color = Color3.fromRGB(48, 64, 56) },
		{ x = -70, y = 30, w = 26, h = 70, color = Color3.fromRGB(28, 48, 42) }, -- jungle mass
		{ x = 70,  y = 30, w = 26, h = 70, color = Color3.fromRGB(28, 48, 42) },
		{ x = 0,   y = 52, w = 40, h = 12, color = Color3.fromRGB(38, 56, 48) }, -- canopy
	},
}
