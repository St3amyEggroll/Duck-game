--!strict
-- Remotes (ModuleScript) | ReplicatedStorage > DuckShared
-- One place that owns the DuckRemotes folder + its RemoteEvents, so the round
-- and weapon systems no longer each reimplement folder/remote creation.
-- On the server it creates them; on the client it waits for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "DuckRemotes"
local REMOTE_NAMES = { "WeaponFire", "WeaponAim", "WeaponEffect", "RoundState" }

local function ensureFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local folder: Folder
if RunService:IsServer() then
	folder = ensureFolder()
	for _, name in REMOTE_NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local Remotes = {}

-- the shared folder also carries the "RoundActive" attribute the weapons read
Remotes.folder = folder

function Remotes.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
