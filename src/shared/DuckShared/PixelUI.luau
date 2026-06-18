-- PixelUI (ModuleScript) | ReplicatedStorage > DuckShared
-- Reusable pixel-art GUI helpers. Every menu/HUD calls these so the whole
-- game shares one consistent retro look. Set FONT_ID once and you're done.

local PixelUI = {}

--========================  STYLE  ========================--
-- Get a pixel font: Studio > Toolbox > Creator Store > Fonts (filter for
-- "pixel"), click one to add it, then copy its asset id and paste below as
-- "rbxassetid://<id>". Leave "" to use a built-in fallback so text still shows.
local FONT_ID = "" -- e.g. "rbxassetid://1234567890"

PixelUI.PALETTE = {
	bg     = Color3.fromRGB(28, 24, 38),    -- dark panel fill
	border = Color3.fromRGB(12, 10, 18),    -- near-black border
	text   = Color3.fromRGB(245, 240, 225), -- off-white
	accent = Color3.fromRGB(245, 200, 70),  -- duck yellow
	danger = Color3.fromRGB(220, 70, 80),
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

return PixelUI
