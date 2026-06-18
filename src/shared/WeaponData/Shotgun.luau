--!strict
-- Shotgun (ModuleScript) | ReplicatedStorage > WeaponData
-- Hitscan, but fires a fan of pellets. Brutal up close, useless far away.
return {
	name = "Shotgun",
	projectile = "hitscan",
	damage = 34,             -- per pellet (a few pellets = a kill)
	pellets = 6,
	spread = math.rad(13),
	fireRate = 1.3,
	ammo = 6,
	range = 95,
	tracerColor = Color3.fromRGB(255, 180, 90),
	color = Color3.fromRGB(200, 120, 60), -- pickup tint
}
