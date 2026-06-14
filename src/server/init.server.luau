--!strict
-- Server bootstrap: the single entry point for all server-side systems.
-- Keep this thin — it wires modules together; gameplay logic lives in modules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

print(`[{Config.Game.Name}] Server starting...`)

-- TODO: initialize server systems here, e.g.:
--   require(script:WaitForChild("PlayerManager")).start()
--   require(script:WaitForChild("RoundService")).start()
