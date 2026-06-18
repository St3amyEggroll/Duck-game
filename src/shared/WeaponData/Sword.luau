--!strict
-- Sword (ModuleScript) | ReplicatedStorage > WeaponData
-- Melee: instant one-hit in a short arc in front of you.
return {
	name = "Sword",
	projectile = "melee",
	damage = 100,            -- one-hit
	range = 9,               -- reach in studs
	fireRate = 2,
	ammo = 14,               -- swings before it breaks
	swingColor = Color3.fromRGB(220, 240, 255),
	color = Color3.fromRGB(180, 200, 230), -- pickup tint
}
