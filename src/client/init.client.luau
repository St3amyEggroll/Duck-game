--!strict
-- Client bootstrap: the single entry point for all client-side systems.
-- Keep this thin — it wires modules together; UI/input logic lives in modules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

print(`[{Config.Game.Name}] Client starting...`)

-- TODO: initialize client systems here, e.g.:
--   require(script:WaitForChild("InputController")).start()
--   require(script:WaitForChild("HudController")).start()
