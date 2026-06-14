--!strict
-- Central game configuration: the single source of truth for tunable values.
-- Shared between client and server so both agree on the same numbers.

local Config = {}

Config.Game = {
	Name = "Duck-game",
	RoundDuration = 180, -- seconds
}

Config.Duck = {
	WalkSpeed = 16,
	JumpPower = 50,
	MaxHealth = 100,
}

table.freeze(Config.Game)
table.freeze(Config.Duck)
table.freeze(Config)

return Config
