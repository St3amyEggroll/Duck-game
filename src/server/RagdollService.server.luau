-- RagdollService (Script) | ServerScriptService
-- Turns R6 ducks into ragdolls when they die: limb joints become ball sockets
-- so the body flops, and the server takes ownership so explosions can fling the
-- corpse for everyone. Other deaths (gunshots, ring-outs) just go limp.
--
-- WeaponService fires the "RagdollLaunch" BindableEvent (in ServerStorage/
-- DuckServer) to ragdoll + throw a body from a blast. We create that event here.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- R6 limb joints (all live in the Torso). RootJoint is left rigid on purpose,
-- so the torso + root fly together as one solid chunk instead of folding up.
local LIMB_MOTORS = { "Neck", "Left Shoulder", "Right Shoulder", "Left Hip", "Right Hip" }

-- launch channel (same DuckServer folder WeaponService already uses)
local duckServer = ServerStorage:FindFirstChild("DuckServer")
if not duckServer then
	duckServer = Instance.new("Folder"); duckServer.Name = "DuckServer"; duckServer.Parent = ServerStorage
end
local launchEvent = duckServer:FindFirstChild("RagdollLaunch")
if not launchEvent then
	launchEvent = Instance.new("BindableEvent"); launchEvent.Name = "RagdollLaunch"; launchEvent.Parent = duckServer
end

local active = {} -- [character] = true  (bodies we're keeping pinned to the 2D plane)

local function ragdollCharacter(character)
	local hum = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local torso = character:FindFirstChild("Torso")
	if not hum or not hrp or not torso then return end

	-- swap each limb motor for a ball-socket so it swings freely
	for _, name in LIMB_MOTORS do
		local motor = torso:FindFirstChild(name)
		if motor and motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
			local a0 = Instance.new("Attachment"); a0.CFrame = motor.C0; a0.Parent = motor.Part0
			local a1 = Instance.new("Attachment"); a1.CFrame = motor.C1; a1.Parent = motor.Part1
			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.LimitsEnabled = true
			socket.UpperAngle = 55
			socket.TwistLimitsEnabled = true
			socket.TwistLowerAngle = -35
			socket.TwistUpperAngle = 35
			socket.Parent = motor.Part1
			motor.Enabled = false
		end
	end

	-- only the (invisible) root collides with the world; limbs just flop, so
	-- they never jitter against each other or the floor
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and part ~= hrp then
			part.CanCollide = false
		end
	end

	hum.PlatformStand = true
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)

	-- server simulates the body so server-applied blast velocity actually lands
	-- and replicates to every client
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			pcall(function() part:SetNetworkOwner(nil) end)
		end
	end

	active[character] = true
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then active[character] = nil end
	end)
end

-- ragdoll a body (once) and optionally fling it
local function activate(character, launchVelocity)
	if typeof(character) ~= "Instance" or not character:IsDescendantOf(workspace) then return end
	if not active[character] then
		ragdollCharacter(character)
	end
	if launchVelocity then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Apply the throw NOW, again next frame, and once more a beat later.
			-- SetNetworkOwner(nil) takes a moment to actually transfer simulation to
			-- the server, and the client's last simulated frame can stomp a single
			-- assignment -- re-asserting guarantees the fling lands and replicates.
			local vx, vy = launchVelocity.X, launchVelocity.Y
			local spin = (math.random() - 0.5) * 60
			local function shove()
				if not hrp.Parent then return end
				hrp.AssemblyLinearVelocity = Vector3.new(vx, vy, 0)
				hrp.AssemblyAngularVelocity = Vector3.new(0, 0, spin)
			end
			shove()
			task.defer(shove)
			task.delay(0.05, shove)
		end
	end
end

launchEvent.Event:Connect(activate)

-- keep ragdolls on the 2D plane WITHOUT teleporting them. The old version
-- snapped each part's CFrame every frame, which zeroed the throw's momentum the
-- instant a flopping limb nudged the core off Z=0 -- so the body never flew.
-- Instead we only steer the Z VELOCITY: zero by default, gently pulled back
-- toward the plane if it drifts. The X/Y fling is left completely untouched.
RunService.Heartbeat:Connect(function()
	for character in active do
		if not character.Parent then
			active[character] = nil
		else
			for _, part in character:GetChildren() do
				if part:IsA("BasePart") then
					local v = part.AssemblyLinearVelocity
					local z = part.Position.Z
					local targetVz = 0
					if math.abs(z) > 0.5 then targetVz = -z * 6 end -- soft pull, no teleport
					if v.Z ~= targetVz then
						part.AssemblyLinearVelocity = Vector3.new(v.X, v.Y, targetVz)
					end
				end
			end
		end
	end
end)

-- hook every duck: stop the default joint-break, ragdoll on death.
-- This system is R6-only (the limb joints above live in the Torso); warn loudly
-- if a duck loads as R15 instead of silently doing nothing.
local function onCharacter(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	if hum.RigType ~= Enum.HumanoidRigType.R6 then
		warn("[RagdollService] Duck is not R6 -- ragdoll + gun posing need R6. Set Game Settings > Avatar > Rig Type to R6.")
		return
	end
	hum.BreakJointsOnDeath = false -- we replace joints with sockets instead
	hum.Died:Connect(function()
		activate(char, nil)
	end)
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then task.spawn(onCharacter, player.Character) end
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in Players:GetPlayers() do hookPlayer(p) end
