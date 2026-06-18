--!strict
-- Config (ModuleScript) | ReplicatedStorage > DuckShared
-- The single source of truth shared by client AND server, so they never drift.
-- Every tunable lives here; gameplay scripts read from it rather than hardcoding.

local Config = {
	-- world / movement
	PLANE_Z = 0,
	WALK_SPEED = 24,
	JUMP_HEIGHT = 9,
	DEFAULT_KILL_Y = -30,

	-- round flow (seconds, except counts)
	MIN_PLAYERS = 1,
	INTERMISSION_TIME = 3,
	RESULT_TIME = 3,
	ROUND_TIME = 90,
	ROUND_WINS = 5,

	-- aiming (used by both the weapon client and server so the pose matches
	-- for everyone watching)
	AIM_MAX_TILT = math.rad(28), -- how far the torso can lean
	AIM_TILT_SIGN = 1, -- flip to -1 if the lean goes the wrong way

	-- shared combat tunables (per-weapon values live in WeaponData/*)
	KNOCKBACK = 95, -- default ragdoll launch force on a kill
	MAX_PLANE_DRIFT = 20, -- shots rejected if the muzzle is this far off Z=0
}

return table.freeze(Config)
