-- RoundManager (Script) | ServerScriptService
-- The real game loop: drives maps + spawns + rounds + scoring.
-- Also publishes a "RoundActive" flag so weapons know when shooting is allowed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MapService = require(ServerScriptService:WaitForChild("MapService"))
local DuckShared = ReplicatedStorage:WaitForChild("DuckShared")
local Config = require(DuckShared:WaitForChild("Config"))
local Remotes = require(DuckShared:WaitForChild("Remotes"))

--========================  TUNABLES (from Config)  ========================--
local MIN_PLAYERS       = Config.MIN_PLAYERS
local INTERMISSION_TIME = Config.INTERMISSION_TIME
local RESULT_TIME       = Config.RESULT_TIME
local ROUND_TIME        = Config.ROUND_TIME
local ROUND_WINS        = Config.ROUND_WINS
--==========================================================================--

Players.CharacterAutoLoads = false

local remotes = Remotes.folder
local roundState = Remotes.get("RoundState")

remotes:SetAttribute("RoundActive", false) -- weapons read this; true only mid-round

local wins: {[Player]: number} = {}

local function broadcast(phase: string, message: string, timer: number?)
	remotes:SetAttribute("RoundActive", phase == "active") -- the round-state flag
	local scores = {}
	for _, p in Players:GetPlayers() do
		table.insert(scores, { name = p.DisplayName, wins = wins[p] or 0 })
	end
	table.sort(scores, function(a, b) return a.wins > b.wins end)
	roundState:FireAllClients({ phase = phase, message = message, timer = timer, scores = scores })
end

local function spawnDuck(player: Player, pos: Vector3)
	player:LoadCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	hrp.CFrame = CFrame.new(pos)
end

local function runRound(participants: {Player}): Player?
	local killY = MapService.getKillY()
	local alive: {[Player]: boolean} = {}
	local conns: {RBXScriptConnection} = {}

	for _, p in ipairs(participants) do
		alive[p] = true
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			table.insert(conns, hum.Died:Connect(function()
				alive[p] = nil
			end))
		end
	end

	local threshold = (#participants <= 1) and 0 or 1
	local elapsed = 0

	while true do
		elapsed += task.wait()

		for p in pairs(alive) do
			if not p.Parent then
				alive[p] = nil
			else
				local char = p.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp :: BasePart).Position.Y < killY then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then (hum :: Humanoid).Health = 0 end
				end
			end
		end

		local count, last = 0, nil
		for p in pairs(alive) do
			count += 1
			last = p
		end

		if count <= threshold or elapsed >= ROUND_TIME then
			for _, c in conns do c:Disconnect() end
			return (count <= threshold) and last or nil
		end
	end
end

Players.PlayerRemoving:Connect(function(p)
	wins[p] = nil
end)

task.spawn(function()
	MapService.loadRandom()

	while true do
		for _, p in Players:GetPlayers() do
			if p.Character then p.Character:Destroy() end
		end

		while #Players:GetPlayers() < MIN_PLAYERS do
			broadcast("waiting", "Waiting for ducks", nil)
			task.wait(1)
		end

		MapService.loadRandom()

		for t = INTERMISSION_TIME, 1, -1 do
			broadcast("intermission", "Get ready", t)
			task.wait(1)
		end

		local participants = Players:GetPlayers()
		local spawns = MapService.getSpawns()
		for i, p in ipairs(participants) do
			local pos = spawns[((i - 1) % math.max(#spawns, 1)) + 1] or Vector3.new(0, 10, 0)
			spawnDuck(p, pos)
		end

		broadcast("active", "Fight!", nil) -- RoundActive becomes true here

		local winner = runRound(participants)

		-- round is over: turn shooting off immediately, before showing the result
		remotes:SetAttribute("RoundActive", false)

		local message
		if winner then
			wins[winner] = (wins[winner] or 0) + 1
			message = winner.DisplayName .. " wins the round"
		elseif #participants <= 1 then
			message = "Round over"
		else
			message = "Draw"
		end

		if winner and wins[winner] >= ROUND_WINS then
			broadcast("matchover", winner.DisplayName .. " wins the match!", nil)
			task.wait(RESULT_TIME + 2)
			for k in pairs(wins) do wins[k] = nil end
		else
			broadcast("result", message, nil)
			task.wait(RESULT_TIME)
		end
	end
end)
