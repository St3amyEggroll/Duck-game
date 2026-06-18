-- RoundHud (LocalScript) | StarterPlayer > StarterPlayerScripts
-- Polished pixel HUD driven by the RoundState remote. Shows a countdown/fight/
-- winner banner, a scoreboard, and the local duck's health bar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DuckShared = ReplicatedStorage:WaitForChild("DuckShared")
local PixelUI = require(DuckShared:WaitForChild("PixelUI"))
local Remotes = require(DuckShared:WaitForChild("Remotes"))
local roundState = Remotes.get("RoundState")

local player = Players.LocalPlayer
local PALETTE = PixelUI.PALETTE

local gui = Instance.new("ScreenGui")
gui.Name = "DuckHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- banner (top center)
--------------------------------------------------------------------
local banner = PixelUI.panel({
	parent = gui,
	size = UDim2.fromOffset(460, 100),
	position = UDim2.new(0.5, 0, 0, 28),
	anchor = Vector2.new(0.5, 0),
})
banner.Visible = false

local bannerScale = Instance.new("UIScale")
bannerScale.Parent = banner

local accentStrip = Instance.new("Frame")
accentStrip.Size = UDim2.new(1, 0, 0, 4)
accentStrip.BackgroundColor3 = PALETTE.accent
accentStrip.BorderSizePixel = 0
accentStrip.ZIndex = 2
accentStrip.Parent = banner

local mainLabel = PixelUI.label({
	parent = banner, text = "", textSize = 36,
	size = UDim2.new(1, -24, 0, 58), position = UDim2.fromOffset(12, 16),
})
local subLabel = PixelUI.label({
	parent = banner, text = "", textSize = 16,
	color = Color3.fromRGB(180, 180, 200),
	size = UDim2.new(1, -24, 0, 22), position = UDim2.fromOffset(12, 72),
})

local function showBanner(main: string, sub: string, big: boolean)
	banner.Visible = true
	mainLabel.Text = main
	mainLabel.TextSize = big and 56 or 34
	mainLabel.TextColor3 = big and PALETTE.accent or PALETTE.text
	subLabel.Text = sub or ""
	bannerScale.Scale = 0.85
	TweenService:Create(bannerScale,
		TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }):Play()
end

--------------------------------------------------------------------
-- scoreboard (top right)
--------------------------------------------------------------------
local board = PixelUI.panel({
	parent = gui,
	size = UDim2.fromOffset(220, 44),
	position = UDim2.new(1, -24, 0, 28),
	anchor = Vector2.new(1, 0),
})
board.AutomaticSize = Enum.AutomaticSize.Y

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = board

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = board

local boardTitle = PixelUI.label({
	parent = board, text = "DUCKS", textSize = 18, color = PALETTE.accent,
	size = UDim2.new(1, 0, 0, 22), xAlign = Enum.TextXAlignment.Left,
})
boardTitle.LayoutOrder = 0

local function updateBoard(scores)
	for _, ch in board:GetChildren() do
		if ch:IsA("TextLabel") and ch ~= boardTitle then ch:Destroy() end
	end
	for i, s in ipairs(scores) do
		local leader = (i == 1 and s.wins > 0)
		local row = PixelUI.label({
			parent = board,
			text = s.name .. "   " .. s.wins,
			textSize = 16,
			color = leader and PALETTE.accent or PALETTE.text,
			size = UDim2.new(1, 0, 0, 20),
			xAlign = Enum.TextXAlignment.Left,
		})
		row.LayoutOrder = i
	end
end

--------------------------------------------------------------------
-- health bar (bottom center) -- bound to the local duck's Humanoid
--------------------------------------------------------------------
local healthPanel = PixelUI.panel({
	parent = gui,
	size = UDim2.fromOffset(280, 40),
	position = UDim2.new(0.5, 0, 1, -18),
	anchor = Vector2.new(0.5, 1),
})
healthPanel.Visible = false

local healthPad = Instance.new("UIPadding")
healthPad.PaddingTop = UDim.new(0, 8)
healthPad.PaddingBottom = UDim.new(0, 8)
healthPad.PaddingLeft = UDim.new(0, 10)
healthPad.PaddingRight = UDim.new(0, 10)
healthPad.Parent = healthPanel

local healthBar = PixelUI.bar({
	parent = healthPanel,
	size = UDim2.fromScale(1, 1),
})
local healthFill = healthBar.Fill

local healthText = PixelUI.label({
	parent = healthBar,
	text = "",
	textSize = 16,
	size = UDim2.fromScale(1, 1),
})
healthText.ZIndex = 3

local function setHealth(current: number, max: number)
	local ratio = math.clamp(max > 0 and current / max or 0, 0, 1)
	TweenService:Create(healthFill, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
		{ Size = UDim2.new(ratio, 0, 1, 0) }):Play()
	healthFill.BackgroundColor3 = (ratio <= 0.3) and PALETTE.lowAmmo or PALETTE.health
	healthText.Text = string.format("%d / %d", math.max(0, math.floor(current + 0.5)), math.floor(max + 0.5))
end

local function bindCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hum then return end
	healthPanel.Visible = true
	setHealth(hum.Health, hum.MaxHealth)
	hum.HealthChanged:Connect(function(h)
		setHealth(h, hum.MaxHealth)
	end)
	hum.Died:Connect(function()
		setHealth(0, hum.MaxHealth)
	end)
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	task.spawn(bindCharacter, player.Character)
end
player.CharacterRemoving:Connect(function()
	healthPanel.Visible = false
end)

--------------------------------------------------------------------
-- react to round state
--------------------------------------------------------------------
local token = 0
roundState.OnClientEvent:Connect(function(state)
	updateBoard(state.scores or {})
	token += 1
	local mine = token
	local phase = state.phase

	if phase == "intermission" and state.timer then
		showBanner(tostring(state.timer), state.message or "Get ready", true)
	elseif phase == "waiting" then
		showBanner("WAITING", state.message or "", false)
	elseif phase == "active" then
		showBanner(state.message or "FIGHT!", "", false)
		task.delay(1.3, function() -- clear the banner so the fight is unobstructed
			if mine == token then banner.Visible = false end
		end)
	else -- result / matchover
		showBanner(state.message or "", phase == "matchover" and "match over" or "", false)
	end
end)
