-- DuckShadows (LocalScript) | StarterPlayer > StarterPlayerScripts
-- A soft contact shadow under every duck so they read as grounded against the
-- flat 2D world. Raycasts down to the floor, scales + fades with height.
-- Purely cosmetic and client-side.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("DuckShared"):WaitForChild("Config"))
local PLANE_Z = Config.PLANE_Z

local MAX_DROP = 14    -- studs above the floor before the shadow fades to nothing
local BASE_WIDTH = 5.5 -- shadow width when standing on the ground
local MIN_T = 0.45     -- transparency when grounded (lower = darker)

local folder = Instance.new("Folder")
folder.Name = "DuckShadows"
folder.Parent = workspace

local shadows = {} -- [character] = Part
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function getShadow(char: Instance): Part
	local existing = shadows[char]
	if existing and existing.Parent then
		return existing
	end
	local s = Instance.new("Part")
	s.Name = "Shadow"
	s.Shape = Enum.PartType.Ball
	s.Anchored = true
	s.CanCollide = false
	s.CanQuery = false
	s.CanTouch = false
	s.CastShadow = false
	s.Material = Enum.Material.SmoothPlastic
	s.Color = Color3.fromRGB(0, 0, 0)
	s.Parent = folder
	shadows[char] = s
	return s
end

RunService.Heartbeat:Connect(function()
	-- characters currently in play, used both as raycast filter and the work set
	local chars = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(chars, p.Character)
		end
	end

	local filter = { folder }
	for _, c in chars do
		table.insert(filter, c)
	end
	rayParams.FilterDescendantsInstances = filter

	-- drop shadows whose duck is gone
	for char, part in shadows do
		if not char.Parent then
			part:Destroy()
			shadows[char] = nil
		end
	end

	for _, char in chars do
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		local s = getShadow(char)
		if hrp and hum and hum.Health > 0 then
			local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -200, 0), rayParams)
			if hit then
				local drop = hrp.Position.Y - hit.Position.Y
				local k = math.clamp(1 - drop / MAX_DROP, 0, 1)
				local w = BASE_WIDTH * (0.55 + 0.45 * k)
				s.Size = Vector3.new(w, w * 0.34, 0.5)
				s.CFrame = CFrame.new(hit.Position.X, hit.Position.Y + 0.15, PLANE_Z + 0.1)
				s.Transparency = MIN_T + (1 - MIN_T) * (1 - k)
			else
				s.Transparency = 1
			end
		else
			s.Transparency = 1
		end
	end
end)
