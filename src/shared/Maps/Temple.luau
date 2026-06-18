--!strict
-- Temple (ModuleScript) | ReplicatedStorage > Maps
-- A ruined jungle temple. Open sides (easy ring-outs, like Rooftops) but a
-- climbable stepped pyramid up the middle to an altar. Stone blocks, columns
-- and foliage behind, gold ledge trim.

return {
	name = "Temple",
	backdrop = Color3.fromRGB(42, 70, 64),    -- jungle teal
	backdrop2 = Color3.fromRGB(96, 128, 110), -- misty horizon
	accent = Color3.fromRGB(232, 200, 112),   -- gold trim
	camera = { x = 0, y = 22, w = 176, h = 94 },
	killY = -32,

	platforms = {
		-- side stone roofs with an open void between them
		{ x = -60, y = 2, w = 40, h = 12, color = Color3.fromRGB(122, 116, 96) },
		{ x = 60,  y = 2, w = 40, h = 12, color = Color3.fromRGB(122, 116, 96) },

		-- stepped pyramid up the middle
		{ x = 0,   y = 4,  w = 30, h = 4, color = Color3.fromRGB(140, 132, 108) },
		{ x = -22, y = 14, w = 18, h = 4, color = Color3.fromRGB(150, 142, 116) },
		{ x = 22,  y = 14, w = 18, h = 4, color = Color3.fromRGB(150, 142, 116) },
		{ x = 0,   y = 22, w = 22, h = 5, color = Color3.fromRGB(158, 150, 122) },
		{ x = 0,   y = 38, w = 16, h = 4, color = Color3.fromRGB(168, 158, 130) }, -- altar

		-- high side ledges
		{ x = -42, y = 24, w = 16, h = 4, color = Color3.fromRGB(150, 142, 116) },
		{ x = 42,  y = 24, w = 16, h = 4, color = Color3.fromRGB(150, 142, 116) },
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

	-- temple columns + foliage behind
	decor = {
		{ x = -40, y = 24, w = 7, h = 60, color = Color3.fromRGB(60, 78, 70) }, -- columns
		{ x = -14, y = 28, w = 7, h = 64, color = Color3.fromRGB(56, 74, 66) },
		{ x = 14,  y = 28, w = 7, h = 64, color = Color3.fromRGB(56, 74, 66) },
		{ x = 40,  y = 24, w = 7, h = 60, color = Color3.fromRGB(60, 78, 70) },
		{ x = -70, y = 30, w = 26, h = 70, color = Color3.fromRGB(36, 60, 54) }, -- jungle mass
		{ x = 70,  y = 30, w = 26, h = 70, color = Color3.fromRGB(36, 60, 54) },
		{ x = 0,   y = 52, w = 40, h = 12, color = Color3.fromRGB(48, 70, 60) }, -- canopy
	},
}
