--!strict
-- Pit (ModuleScript) | ReplicatedStorage > Maps
-- An enclosed industrial arena: tall walls so ring-outs are hard and you have
-- to actually fight. Layered catwalks step up from a central floor, with pipes
-- and girders behind. Hazard-yellow ledge trim.
--
-- Palette is layered for depth: bright steel foreground platforms, mid-tone
-- decor behind them, and a dark steel sky gradient furthest back.

return {
	name = "Pit",
	backdrop = Color3.fromRGB(38, 42, 54),    -- dark steel (base/fallback)
	skyTop = Color3.fromRGB(26, 30, 42),      -- dim ceiling of the shaft
	skyBottom = Color3.fromRGB(58, 64, 84),   -- lit lower wall band
	backdrop2 = Color3.fromRGB(60, 66, 84),
	accent = Color3.fromRGB(250, 210, 70),    -- hazard-yellow trim (pops)
	camera = { x = 0, y = 18, w = 152, h = 86 },
	killY = -30,

	platforms = {
		-- floor + side walls (enclosed box) -- solid, mid-bright
		{ x = 0,   y = -4, w = 140, h = 8,  color = Color3.fromRGB(74, 80, 96) },
		{ x = -69, y = 22, w = 6,  h = 60, color = Color3.fromRGB(60, 66, 82) },
		{ x = 69,  y = 22, w = 6,  h = 60, color = Color3.fromRGB(60, 66, 82) },

		-- stepped catwalks -- brightest layer, clearly above the decor
		{ x = -42, y = 10, w = 28, h = 4, color = Color3.fromRGB(120, 126, 148) },
		{ x = 42,  y = 10, w = 28, h = 4, color = Color3.fromRGB(120, 126, 148) },
		{ x = -18, y = 20, w = 24, h = 4, color = Color3.fromRGB(132, 138, 160) },
		{ x = 18,  y = 20, w = 24, h = 4, color = Color3.fromRGB(132, 138, 160) },
		{ x = 0,   y = 30, w = 30, h = 4, color = Color3.fromRGB(144, 150, 172) }, -- center high deck
		{ x = -52, y = 32, w = 16, h = 4, color = Color3.fromRGB(132, 138, 160) },
		{ x = 52,  y = 32, w = 16, h = 4, color = Color3.fromRGB(132, 138, 160) },
	},

	spawns = {
		{ x = -58, y = 4 }, { x = 58, y = 4 },
		{ x = -42, y = 16 }, { x = 42, y = 16 },
		{ x = -52, y = 38 }, { x = 52, y = 38 },
	},

	weaponSpawns = {
		{ x = 0, y = 4 },   { x = 0, y = 36 },
		{ x = -18, y = 26 }, { x = 18, y = 26 },
		{ x = -42, y = 16 }, { x = 42, y = 16 },
	},

	-- pipes + girders behind the catwalks -- darker mid layer, recedes
	decor = {
		{ x = -30, y = 46, w = 92, h = 5, color = Color3.fromRGB(40, 44, 58) }, -- top pipe run
		{ x = 30,  y = 2,  w = 5,  h = 44, color = Color3.fromRGB(38, 42, 56) }, -- vertical pipe
		{ x = -36, y = 4,  w = 5,  h = 40, color = Color3.fromRGB(38, 42, 56) },
		{ x = 0,   y = 14, w = 130, h = 3, color = Color3.fromRGB(42, 46, 62) }, -- girder
		{ x = -10, y = 40, w = 14, h = 14, color = Color3.fromRGB(46, 50, 66) }, -- machinery block
		{ x = 44,  y = 42, w = 12, h = 12, color = Color3.fromRGB(46, 50, 66) },
	},
}
