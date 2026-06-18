--!strict
-- WeaponDefs (ModuleScript) | ReplicatedStorage > DuckShared
-- Loads every weapon DATA module under ReplicatedStorage/WeaponData. Both the
-- weapon system (needs a name->def map) and the pickup system (needs the list)
-- used to scan that folder themselves; now they share this one loader.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponDefs = {}

-- Returns ({ defs... }, { [name] = def }). Skips any module that errors or
-- doesn't return a table with a `name`.
function WeaponDefs.loadAll(): ({ any }, { [string]: any })
	local list = {}
	local byName = {}
	local folder = ReplicatedStorage:FindFirstChild("WeaponData")
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("ModuleScript") then
				local ok, data = pcall(require, m)
				if ok and type(data) == "table" and data.name then
					table.insert(list, data)
					byName[data.name] = data
				end
			end
		end
	end
	return list, byName
end

return WeaponDefs
