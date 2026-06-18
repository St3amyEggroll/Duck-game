-- Vignette (LocalScript) | StarterPlayer > StarterPlayerScripts
-- A subtle screen vignette that darkens the edges to focus the eye on the
-- center of the arena. Built from four edge gradients (no image asset needed),
-- and sits behind the HUD. Purely cosmetic.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "DuckVignette"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1 -- behind the HUD (DisplayOrder 10)
gui.Parent = player:WaitForChild("PlayerGui")

local DARK = Color3.fromRGB(0, 0, 0)
local DEPTH = 0.34 -- darkness at the very edge (0 = none, 1 = black)
local THICK = 0.22 -- fraction of the screen each band reaches inward

-- fromEdge=true means the band's "start" sits on the screen edge
local function band(size: UDim2, pos: UDim2, anchor: Vector2, rotation: number, fromEdge: boolean)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = DARK
	f.BorderSizePixel = 0
	f.Size = size
	f.Position = pos
	f.AnchorPoint = anchor
	f.ZIndex = 1

	local edgeT = 1 - DEPTH
	local grad = Instance.new("UIGradient")
	grad.Rotation = rotation
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fromEdge and edgeT or 1),
		NumberSequenceKeypoint.new(1, fromEdge and 1 or edgeT),
	})
	grad.Parent = f
	f.Parent = gui
end

-- top / bottom (vertical gradient), left / right (horizontal gradient)
band(UDim2.new(1, 0, THICK, 0), UDim2.fromScale(0, 0), Vector2.new(0, 0), 90, true)
band(UDim2.new(1, 0, THICK, 0), UDim2.fromScale(0, 1), Vector2.new(0, 1), 90, false)
band(UDim2.new(THICK, 0, 1, 0), UDim2.fromScale(0, 0), Vector2.new(0, 0), 0, true)
band(UDim2.new(THICK, 0, 1, 0), UDim2.fromScale(1, 0), Vector2.new(1, 0), 0, false)
