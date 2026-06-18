-- PixelUI (ModuleScript) | ReplicatedStorage > DuckShared
-- Reusable pixel-art GUI helpers. Every menu/HUD calls these so the whole
-- game shares one consistent retro look. Set FONT_ID once and you're done.

local TweenService = game:GetService("TweenService")

local PixelUI = {}

--========================  STYLE  ========================--
-- Get a pixel font: Studio > Toolbox > Creator Store > Fonts (filter for
-- "pixel"), click one to add it, then copy its asset id and paste below as
-- "rbxassetid://<id>". Leave "" to use a built-in fallback so text still shows.
local FONT_ID = "" -- e.g. "rbxassetid://1234567890"

PixelUI.PALETTE = {
	bg     = Color3.fromRGB(28, 24, 38),    -- dark panel fill
	bgDark = Color3.fromRGB(18, 16, 26),    -- recessed track / bar background
	border = Color3.fromRGB(12, 10, 18),    -- near-black border
	text   = Color3.fromRGB(245, 240, 225), -- off-white
	accent = Color3.fromRGB(245, 200, 70),  -- duck yellow
	danger = Color3.fromRGB(220, 70, 80),
	health = Color3.fromRGB(120, 210, 110), -- green health fill
	lowAmmo = Color3.fromRGB(235, 110, 90), -- ammo/health warning color
}
local BORDER_PX = 3
--=========================================================--

function PixelUI.font(): Font
	if FONT_ID ~= "" then
		return Font.new(FONT_ID, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end
	return Font.fromEnum(Enum.Font.Fantasy) -- chunky fallback until you add a pixel font
end

-- a hard, sharp-cornered border (the retro panel edge)
function PixelUI.sharpBorder(parent: GuiObject, color: Color3?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = BORDER_PX
	stroke.Color = color or PixelUI.PALETTE.border
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.Parent = parent
	return stroke
end

function PixelUI.panel(props)
	props = props or {}
	local f = Instance.new("Frame")
	f.BackgroundColor3 = props.color or PixelUI.PALETTE.bg
	f.BorderSizePixel = 0
	f.Size = props.size or UDim2.fromOffset(300, 120)
	f.Position = props.position or UDim2.fromScale(0.5, 0.5)
	f.AnchorPoint = props.anchor or Vector2.new(0.5, 0.5)
	PixelUI.sharpBorder(f, props.border)
	if props.parent then f.Parent = props.parent end
	return f
end

function PixelUI.label(props)
	props = props or {}
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.FontFace = PixelUI.font()
	t.Text = props.text or ""
	t.TextColor3 = props.color or PixelUI.PALETTE.text
	t.TextSize = props.textSize or 24
	t.TextStrokeColor3 = PixelUI.PALETTE.border
	t.TextStrokeTransparency = props.strokeT or 0.3
	t.TextXAlignment = props.xAlign or Enum.TextXAlignment.Center
	t.Size = props.size or UDim2.fromScale(1, 1)
	t.Position = props.position or UDim2.fromScale(0, 0)
	if props.parent then t.Parent = props.parent end
	return t
end

function PixelUI.button(props)
	props = props or {}
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = props.color or PixelUI.PALETTE.accent
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.FontFace = PixelUI.font()
	b.Text = props.text or "OK"
	b.TextColor3 = props.textColor or PixelUI.PALETTE.border
	b.TextSize = props.textSize or 22
	b.Size = props.size or UDim2.fromOffset(180, 48)
	b.Position = props.position or UDim2.fromScale(0.5, 0.5)
	b.AnchorPoint = props.anchor or Vector2.new(0.5, 0.5)
	PixelUI.sharpBorder(b, props.border)
	if props.parent then b.Parent = props.parent end
	return b
end

-- crisp pixel image/icon (nearest-neighbor, no blur)
function PixelUI.icon(props)
	props = props or {}
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Image = props.image or ""
	img.ResampleMode = Enum.ResamplerMode.Pixelated
	img.Size = props.size or UDim2.fromOffset(48, 48)
	img.Position = props.position or UDim2.fromScale(0, 0)
	if props.parent then img.Parent = props.parent end
	return img
end

-- a recessed value bar (health, charge, etc). Returns the background frame; set
-- the fill via `bar.Fill.Size = UDim2.new(ratio, 0, 1, 0)`.
function PixelUI.bar(props)
	props = props or {}
	local bg = Instance.new("Frame")
	bg.Name = props.name or "Bar"
	bg.BackgroundColor3 = props.bgColor or PixelUI.PALETTE.bgDark
	bg.BorderSizePixel = 0
	bg.Size = props.size or UDim2.fromOffset(220, 18)
	bg.Position = props.position or UDim2.fromScale(0, 0)
	bg.AnchorPoint = props.anchor or Vector2.new(0, 0)
	PixelUI.sharpBorder(bg, props.border)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = props.color or PixelUI.PALETTE.health
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = bg

	if props.parent then bg.Parent = props.parent end
	return bg
end

-- a centered crosshair (four ticks around a gap). Returns the container Frame;
-- move it by setting its Position. Reorder ticks via props if you like.
function PixelUI.crosshair(props)
	props = props or {}
	local color = props.color or PixelUI.PALETTE.text
	local thick = props.thickness or 3
	local len = props.length or 8
	local gap = props.gap or 5

	local container = Instance.new("Frame")
	container.Name = "Crosshair"
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromOffset(40, 40)
	container.AnchorPoint = Vector2.new(0.5, 0.5)

	local function tick(w, h, px, py)
		local t = Instance.new("Frame")
		t.BackgroundColor3 = color
		t.BorderSizePixel = 0
		t.Size = UDim2.fromOffset(w, h)
		t.Position = UDim2.new(0.5, px, 0.5, py)
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		PixelUI.sharpBorder(t)
		t.Parent = container
	end
	tick(thick, len, 0, -(gap + len / 2)) -- top
	tick(thick, len, 0, gap + len / 2) -- bottom
	tick(len, thick, -(gap + len / 2), 0) -- left
	tick(len, thick, gap + len / 2, 0) -- right

	if props.parent then container.Parent = props.parent end
	return container
end

-- snappy "pop-in" scale tween. Reuses a UIScale so it can be re-triggered.
function PixelUI.popIn(obj: GuiObject, fromScale: number?)
	local scale = obj:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
	scale.Parent = obj
	scale.Scale = fromScale or 0.82
	TweenService:Create(scale,
		TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }):Play()
	return scale
end

return PixelUI
