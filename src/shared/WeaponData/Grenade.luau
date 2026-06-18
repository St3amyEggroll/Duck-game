--!strict
-- Grenade (ModuleScript) | ReplicatedStorage > WeaponData
-- Thrown physics object. Flies on the 2D plane, explodes after a fuse,
-- damages + launches everything nearby (including you).
return {
	name = "Grenade",
	projectile = "grenade",
	damage = 120,
	fireRate = 1,
	ammo = 3,
	throwSpeed = 70,
	fuse = 2.2,
	blastRadius = 16,
	blastForce = 90,
	explosionColor = Color3.fromRGB(255, 170, 60),
	color = Color3.fromRGB(110, 190, 110), -- pickup tint
}
