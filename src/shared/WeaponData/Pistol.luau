--!strict
-- Pistol (ModuleScript) | ReplicatedStorage > WeaponData
-- A weapon is just data. To add a weapon, copy this file and change the values.
-- (Optional model: put a Model named like `name` in ReplicatedStorage/Weapons
--  with a PrimaryPart + a "Muzzle" Attachment; otherwise a placeholder is used.)

return {
	name = "Pistol",
	damage = 100,    -- 100 = one-shot kill
	fireRate = 4,    -- shots per second
	ammo = 12,
	spread = 0,      -- radians of random spread (0 = pinpoint)
	range = 220,
	projectile = "hitscan",
	tracerColor = Color3.fromRGB(255, 230, 120),
}
