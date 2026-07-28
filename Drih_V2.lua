--// ═══════════════════════════════════════════════════════════
--// REDARELHOS HUB v2.0 — VERMELHO & PRETO
--// LocalScript → StarterPlayerScripts ou StarterGui
--// Tecla para abrir/fechar: RightShift
--// ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ════════════════════════════════════════
-- PALETA VERMELHO & PRETO
-- ════════════════════════════════════════

local C = {
	Accent      = Color3.fromRGB(255, 35, 35),     -- Vermelho neon
	AccentDark  = Color3.fromRGB(180, 15, 15),      -- Vermelho escuro
	AccentGlow  = Color3.fromRGB(255, 60, 60),      -- Vermelho brilhante
	AccentSoft  = Color3.fromRGB(255, 90, 90),      -- Vermelho suave

	BG1         = Color3.fromRGB(8, 8, 12),         -- Preto profundo
	BG2         = Color3.fromRGB(14, 14, 20),       -- Painel
	BG3         = Color3.fromRGB(20, 20, 28),       -- Card
	BG4         = Color3.fromRGB(28, 28, 38),       -- Pill/Elevado

	White       = Color3.fromRGB(255, 255, 255),
	TextSub     = Color3.fromRGB(200, 200, 215),
	TextDim     = Color3.fromRGB(140, 140, 160),
	DarkGray    = Color3.fromRGB(35, 35, 45),
	Black       = Color3.fromRGB(0, 0, 0),
	Green       = Color3.fromRGB(72, 255, 120),
	Yellow      = Color3.fromRGB(255, 214, 92),
	Red         = Color3.fromRGB(255, 80, 80),
}

-- ════════════════════════════════════════
-- ESTADO GLOBAL
-- ════════════════════════════════════════

local State = {
	Open = false,
	Minimized = false,
	Toggles = {},
	Stats = {
		moneyCurrent = 0,
		sessionMoney = 0,
		profitPerMin = 0,
		deliveries = 0,
		raceWins = 0,
		raceLosses = 0,
		kmDriven = 0,
		sessionTime = "00:00:00",
		vehicleSpeed = "0 km/h",
		vehicleMileage = "0 km",
		vehiclePower = "0 HP",
		vehicleAcceleration = "--",
		vehicleTraction = "--",
		carInfo = "Nenhum veículo detectado.",
		raceTime = "--:--.---",
		racePosition = "#--",
		bestRaceTime = "--:--.---",
		raceHistory = "Nenhuma corrida registrada.",
		playersOnline = 0,
		ping = "-- ms",
		fps = 0,
		serverTime = "--:--:--",
		serverInfo = "",
	},
}

local sessionStart = os.clock()
local moneyHistory = {}
for i = 1, 24 do moneyHistory[i] = 0 end

-- ════════════════════════════════════════
-- REGISTROS PARA ATUALIZAÇÕES
-- ════════════════════════════════════════

local StatBindings = {}
local TextBindings = {}
local ToggleStates = {}
local ToggleRenderers = {}
local ToggleSetters = {}
local AutomationKeys = {}
local GraphBars = {}
local AllCards = {}
local PageMap = {}

-- ════════════════════════════════════════
-- UTILIDADES
-- ════════════════════════════════════════

local function create(class, props, kids)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	for _, child in ipairs(kids or {}) do
		child.Parent = obj
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

local function corner(obj, r)
	return create("UICorner", {CornerRadius = UDim.new(0, r or 12), Parent = obj})
end

local function addStroke(obj, color, trans, thick)
	return create("UIStroke", {
		Color = color or C.Accent,
		Transparency = trans or 0.5,
		Thickness = thick or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = obj,
	})
end

local function pad(obj, px)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = obj,
	})
end

local function tw(obj, props, dur, style, dir)
	local info = TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function clamp(n, a, b) return math.max(a, math.min(b, n)) end

local function formatNum(n)
	n = math.floor(tonumber(n) or 0)
	local s = tostring(n)
	local result = ""
	local count = 0
	for i = #s, 1, -1 do
		count = count + 1
		result = s:sub(i, i) .. result
		if count % 3 == 0 and i > 1 then
			result = "." .. result
		end
	end
	return result
end

local function formatMoney(n) return "$ " .. formatNum(n) end

local function formatTime(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%02d:%02d:%02d", math.floor(sec/3600), math.floor(sec%3600/60), sec%60)
end

local function setStat(key, value)
	State.Stats[key] = value
	for _, b in ipairs(StatBindings[key] or {}) do
		pcall(function()
			b.label.Text = b.fmt and b.fmt(value) or tostring(value)
		end)
	end
	for _, lbl in ipairs(TextBindings[key] or {}) do
		pcall(function() lbl.Text = tostring(value) end)
	end
end

local function bindStat(key, label, fmt)
	StatBindings[key] = StatBindings[key] or {}
	table.insert(StatBindings[key], {label = label, fmt = fmt})
	label.Text = fmt and fmt(State.Stats[key]) or tostring(State.Stats[key])
end

local function bindText(key, label)
	TextBindings[key] = TextBindings[key] or {}
	table.insert(TextBindings[key], label)
	label.Text = tostring(State.Stats[key] or "")
end

-- ════════════════════════════════════════
-- LIMPAR GUI ANTERIOR
-- ════════════════════════════════════════

local pg = Player:WaitForChild("PlayerGui")
local oldGui = pg:FindFirstChild("RedarelhosHub")
if oldGui then oldGui:Destroy() end
local oldBlur = Lighting:FindFirstChild("RHBlur")
if oldBlur then oldBlur:Destroy() end

-- ════════════════════════════════════════
-- SCREENGUI
-- ════════════════════════════════════════

local gui = create("ScreenGui", {
	Name = "RedarelhosHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = pg,
})

local blur = create("BlurEffect", {
	Name = "RHBlur",
	Size = 0,
	Parent = Lighting,
})

-- ════════════════════════════════════════
-- NOTIFICAÇÕES
-- ════════════════════════════════════════

local notifHolder = create("Frame", {
	Name = "Notifs",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 20),
	Size = UDim2.new(0, 340, 1, -40),
	BackgroundTransparency = 1,
	Parent = gui,
})
create("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 10),
	Parent = notifHolder,
})

local function notify(title, body, kind)
	local col = C.Accent
	if kind == "success" then col = C.Green
	elseif kind == "warning" then col = C.Yellow
	elseif kind == "error" then col = C.Red end

	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = C.BG2,
		BackgroundTransparency = 0.06,
		ClipsDescendants = true,
		Parent = notifHolder,
	})
	corner(card, 14)
	addStroke(card, col, 0.2, 1.2)

	create("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = col,
		BorderSizePixel = 0,
		Parent = card,
	})

	create("TextLabel", {
		Position = UDim2.fromOffset(18, 12),
		Size = UDim2.new(1, -30, 0, 18),
		BackgroundTransparency = 1,
		Text = title or "",
		TextColor3 = C.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	create("TextLabel", {
		Position = UDim2.fromOffset(18, 32),
		Size = UDim2.new(1, -30, 0, 30),
		BackgroundTransparency = 1,
		Text = body or "",
		TextColor3 = C.TextSub,
		TextWrapped = true,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	tw(card, {Size = UDim2.new(1, 0, 0, 72)}, 0.25)

	task.delay(4, function()
		if card and card.Parent then
			tw(card, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
			task.wait(0.25)
			pcall(function() card:Destroy() end)
		end
	end)
end

-- ════════════════════════════════════════
-- TOOLTIP
-- ════════════════════════════════════════

local tooltipLabel = create("TextLabel", {
	Name = "Tooltip",
	Visible = false,
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundColor3 = C.BG2,
	BackgroundTransparency = 0.08,
	TextColor3 = C.White,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 999,
	Parent = gui,
})
pad(tooltipLabel, 10)
corner(tooltipLabel, 10)
addStroke(tooltipLabel, C.Accent, 0.3, 1)

local function attachTooltip(obj, text)
	if not text or text == "" then return end
	obj.MouseEnter:Connect(function()
		tooltipLabel.Text = text
		tooltipLabel.Visible = true
	end)
	obj.MouseLeave:Connect(function()
		tooltipLabel.Visible = false
	end)
end

UserInputService.InputChanged:Connect(function(input)
	if tooltipLabel.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
		tooltipLabel.Position = UDim2.fromOffset(input.Position.X + 16, input.Position.Y + 16)
	end
end)

-- ════════════════════════════════════════
-- HOVER EFFECT
-- ════════════════════════════════════════

local function addHover(btn, scaleAmt)
	local s = create("UIScale", {Scale = 1, Parent = btn})
	btn.MouseEnter:Connect(function() tw(s, {Scale = scaleAmt or 1.025}, 0.12) end)
	btn.MouseLeave:Connect(function() tw(s, {Scale = 1}, 0.12) end)
end

-- ════════════════════════════════════════
-- LOADING SCREEN
-- ════════════════════════════════════════

local loadScreen = create("Frame", {
	Name = "Loading",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.Black,
	BackgroundTransparency = 0.08,
	ZIndex = 100,
	Parent = gui,
})

local loadCard = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(440, 200),
	BackgroundColor3 = C.BG2,
	BackgroundTransparency = 0.06,
	ZIndex = 101,
	Parent = loadScreen,
})
corner(loadCard, 22)
addStroke(loadCard, C.Accent, 0.15, 1.5)

-- Logo
local loadLogo = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 18),
	Size = UDim2.fromOffset(60, 60),
	BackgroundColor3 = C.BG4,
	BackgroundTransparency = 0.05,
	ZIndex = 102,
	Parent = loadCard,
})
corner(loadLogo, 16)
addStroke(loadLogo, C.Accent, 0.08, 1.6)

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "RH",
	TextColor3 = C.Accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	ZIndex = 103,
	Parent = loadLogo,
})

create("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 88),
	Size = UDim2.fromOffset(380, 30),
	BackgroundTransparency = 1,
	Text = "REDARELHOS HUB",
	TextColor3 = C.White,
	TextSize = 28,
	Font = Enum.Font.GothamBold,
	ZIndex = 102,
	Parent = loadCard,
})

create("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 120),
	Size = UDim2.fromOffset(380, 20),
	BackgroundTransparency = 1,
	Text = "Carregando interface premium...",
	TextColor3 = C.TextSub,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	ZIndex = 102,
	Parent = loadCard,
})

local loadTrack = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 155),
	Size = UDim2.fromOffset(340, 10),
	BackgroundColor3 = C.DarkGray,
	BackgroundTransparency = 0.3,
	ZIndex = 102,
	Parent = loadCard,
})
corner(loadTrack, 999)

local loadFill = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = C.Accent,
	ZIndex = 103,
	Parent = loadTrack,
})
corner(loadFill, 999)

-- ════════════════════════════════════════
-- JANELA PRINCIPAL
-- ════════════════════════════════════════

local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1600, 900)
local W = clamp(math.floor(vp.X * 0.72), 860, 1280)
local H = clamp(math.floor(vp.Y * 0.74), 560, 760)

local windowRoot = create("Frame", {
	Name = "WindowRoot",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})

create("UISizeConstraint", {
	MinSize = Vector2.new(820, 520),
	MaxSize = Vector2.new(1500, 900),
	Parent = windowRoot,
})

local openScale = create("UIScale", {Scale = 0.92, Parent = windowRoot})

-- Sombra
local shadowFrame = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 6),
	Size = UDim2.new(1, 10, 1, 10),
	BackgroundColor3 = C.Black,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = windowRoot,
})
corner(shadowFrame, 26)

-- Fundo principal
local mainFrame = create("Frame", {
	Name = "Main",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.BG1,
	BackgroundTransparency = 0.04,
	ClipsDescendants = true,
	Parent = windowRoot,
})
corner(mainFrame, 22)
addStroke(mainFrame, C.Accent, 0.25, 1.5)

-- Partículas
for i = 1, 20 do
	local dot = create("Frame", {
		Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4)),
		Position = UDim2.new(math.random(), 0, math.random(), 0),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = mainFrame,
	})
	corner(dot, 999)
	task.spawn(function()
		while dot and dot.Parent do
			tw(dot, {
				Position = UDim2.new(math.random(), 0, math.random(), 0),
				BackgroundTransparency = 0.82 + math.random() * 0.14,
			}, 5 + math.random() * 5)
			task.wait(4 + math.random() * 4)
		end
	end)
end

-- ════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════

local headerFrame = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 72),
	BackgroundColor3 = C.BG2,
	BackgroundTransparency = 0.04,
	ZIndex = 10,
	Parent = mainFrame,
})

-- Logo do header
local hLogo = create("Frame", {
	Position = UDim2.fromOffset(16, 13),
	Size = UDim2.fromOffset(46, 46),
	BackgroundColor3 = C.BG4,
	BackgroundTransparency = 0.04,
	ZIndex = 11,
	Parent = headerFrame,
})
corner(hLogo, 14)
addStroke(hLogo, C.Accent, 0.08, 1.5)

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "RH",
	TextColor3 = C.Accent,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	ZIndex = 12,
	Parent = hLogo,
})

-- Título
create("TextLabel", {
	Position = UDim2.fromOffset(74, 10),
	Size = UDim2.fromOffset(300, 26),
	BackgroundTransparency = 1,
	Text = "REDARELHOS HUB",
	TextColor3 = C.White,
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
	Parent = headerFrame,
})

create("TextLabel", {
	Position = UDim2.fromOffset(74, 38),
	Size = UDim2.fromOffset(340, 18),
	BackgroundTransparency = 1,
	Text = "Car Dealership Tycoon • v2.0 • Premium",
	TextColor3 = C.TextDim,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
	Parent = headerFrame,
})

-- Pills do header
local function makeHPill(parent, text, width)
	local p = create("Frame", {
		Size = UDim2.fromOffset(width, 30),
		BackgroundColor3 = C.BG4,
		BackgroundTransparency = 0.08,
		ZIndex = 11,
		Parent = parent,
	})
	corner(p, 10)
	addStroke(p, C.DarkGray, 0.4, 1)
	local l = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = text,
		TextColor3 = C.White,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		ZIndex = 12,
		Parent = p,
	})
	return p, l
end

local hPillStrip = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -110, 0.5, 0),
	Size = UDim2.fromOffset(460, 36),
	BackgroundTransparency = 1,
	ZIndex = 11,
	Parent = headerFrame,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	Parent = hPillStrip,
})

local _, versionLabel = makeHPill(hPillStrip, "v2.0", 60)
local _, sessionLabel = makeHPill(hPillStrip, "00:00:00", 88)
local _, fpsLabel = makeHPill(hPillStrip, "FPS: 0", 76)
local _, playerLabel = makeHPill(hPillStrip, Player.Name, 130)

-- Botões fechar/minimizar
local hBtnHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(86, 36),
	BackgroundTransparency = 1,
	ZIndex = 11,
	Parent = headerFrame,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	Parent = hBtnHolder,
})

local function makeHeaderBtn(text, color)
	local btn = create("TextButton", {
		Size = UDim2.fromOffset(38, 34),
		BackgroundColor3 = C.BG4,
		BackgroundTransparency = 0.08,
		Text = text,
		TextColor3 = color or C.White,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		ZIndex = 12,
		Parent = hBtnHolder,
	})
	corner(btn, 10)
	addStroke(btn, color or C.DarkGray, 0.4, 1)
	addHover(btn)
	return btn
end

local minimizeBtn = makeHeaderBtn("—", C.White)
local closeBtn = makeHeaderBtn("✕", C.Red)

-- ════════════════════════════════════════
-- BODY (SIDEBAR + CONTENT)
-- ════════════════════════════════════════

local bodyFrame = create("Frame", {
	Name = "Body",
	Position = UDim2.fromOffset(0, 72),
	Size = UDim2.new(1, 0, 1, -72),
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = mainFrame,
})

-- Sidebar
local sidebarFrame = create("Frame", {
	Position = UDim2.fromOffset(12, 10),
	Size = UDim2.new(0, 220, 1, -20),
	BackgroundColor3 = C.BG2,
	BackgroundTransparency = 0.04,
	ZIndex = 6,
	Parent = bodyFrame,
})
corner(sidebarFrame, 16)
addStroke(sidebarFrame, C.DarkGray, 0.45, 1)

-- Pesquisa
local searchWrap = create("Frame", {
	Position = UDim2.fromOffset(12, 12),
	Size = UDim2.new(1, -24, 0, 40),
	BackgroundColor3 = C.BG4,
	BackgroundTransparency = 0.06,
	ZIndex = 7,
	Parent = sidebarFrame,
})
corner(searchWrap, 12)
addStroke(searchWrap, C.DarkGray, 0.5, 1)

create("TextLabel", {
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.fromOffset(20, 40),
	BackgroundTransparency = 1,
	Text = "🔍",
	TextColor3 = C.Accent,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	ZIndex = 8,
	Parent = searchWrap,
})

local searchBox = create("TextBox", {
	Position = UDim2.fromOffset(34, 0),
	Size = UDim2.new(1, -44, 1, 0),
	BackgroundTransparency = 1,
	PlaceholderText = "Pesquisar...",
	Text = "",
	TextColor3 = C.White,
	PlaceholderColor3 = C.TextDim,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	ZIndex = 8,
	Parent = searchWrap,
})

-- Tabs scroll
local tabScroll = create("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 62),
	Size = UDim2.new(1, -16, 1, -72),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = C.Accent,
	ZIndex = 7,
	Parent = sidebarFrame,
})
create("UIListLayout", {Padding = UDim.new(0, 7), Parent = tabScroll})

-- Content
local contentFrame = create("Frame", {
	Position = UDim2.new(0, 244, 0, 10),
	Size = UDim2.new(1, -256, 1, -20),
	BackgroundColor3 = C.BG2,
	BackgroundTransparency = 0.04,
	ZIndex = 6,
	Parent = bodyFrame,
})
corner(contentFrame, 16)
addStroke(contentFrame, C.DarkGray, 0.45, 1)

-- Content header
local contentHeaderFrame = create("Frame", {
	Position = UDim2.fromOffset(14, 12),
	Size = UDim2.new(1, -28, 0, 48),
	BackgroundColor3 = C.BG4,
	BackgroundTransparency = 0.06,
	ZIndex = 7,
	Parent = contentFrame,
})
corner(contentHeaderFrame, 12)
addStroke(contentHeaderFrame, C.DarkGray, 0.5, 1)

local pageTitle = create("TextLabel", {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "Farming",
	TextColor3 = C.White,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 8,
	Parent = contentHeaderFrame,
})

create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(280, 18),
	BackgroundTransparency = 1,
	Text = "Premium • Futurista • Responsivo",
	TextColor3 = C.TextDim,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 8,
	Parent = contentHeaderFrame,
})

-- Pages holder
local pagesHolder = create("Frame", {
	Position = UDim2.fromOffset(14, 72),
	Size = UDim2.new(1, -28, 1, -128),
	BackgroundTransparency = 1,
	ZIndex = 7,
	Parent = contentFrame,
})

-- Status bar
local statusBar = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.new(1, -28, 0, 38),
	BackgroundColor3 = C.BG4,
	BackgroundTransparency = 0.06,
	ZIndex = 7,
	Parent = contentFrame,
})
corner(statusBar, 12)
addStroke(statusBar, C.DarkGray, 0.5, 1)

local statusText = create("TextLabel", {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(0, 260, 1, 0),
	BackgroundTransparency = 1,
	Text = "Pronto",
	TextColor3 = C.White,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 8,
	Parent = statusBar,
})

local progressTrack = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(240, 8),
	BackgroundColor3 = C.DarkGray,
	BackgroundTransparency = 0.3,
	ZIndex = 8,
	Parent = statusBar,
})
corner(progressTrack, 999)

local progressFill = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = C.Accent,
	ZIndex = 9,
	Parent = progressTrack,
})
corner(progressFill, 999)

-- Resize handle
local resizeHandle = create("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -6, 1, -4),
	Size = UDim2.fromOffset(20, 20),
	BackgroundTransparency = 1,
	Text = "◢",
	TextColor3 = C.Accent,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	ZIndex = 20,
	Parent = mainFrame,
})

-- ════════════════════════════════════════
-- COMPONENTES
-- ════════════════════════════════════════

local function makeCard(parent, h, autoY)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, h or 70),
		AutomaticSize = autoY and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BackgroundColor3 = C.BG3,
		BackgroundTransparency = 0.06,
		ZIndex = 8,
		Parent = parent,
	})
	corner(card, 14)
	addStroke(card, C.DarkGray, 0.55, 1)
	table.insert(AllCards, card)
	return card
end

local function makeSection(parent, title)
	local section = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 8,
		Parent = parent,
	})
	create("UIListLayout", {Padding = UDim.new(0, 7), Parent = section})

	local hdr = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.BG4,
		BackgroundTransparency = 0.06,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 9,
		Parent = section,
	})
	corner(hdr, 12)
	addStroke(hdr, C.DarkGray, 0.5, 1)
	addHover(hdr)

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 10,
		Parent = hdr,
	})

	local chevron = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "▾",
		TextColor3 = C.Accent,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		ZIndex = 10,
		Parent = hdr,
	})

	local bodyF = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 8,
		Parent = section,
	})
	create("UIListLayout", {Padding = UDim.new(0, 7), Parent = bodyF})

	local collapsed = false
	hdr.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		bodyF.Visible = not collapsed
		chevron.Text = collapsed and "▸" or "▾"
	end)

	return {frame = section, body = bodyF, items = {}}
end

local function makeToggle(parent, item)
	local card = makeCard(parent, 68)
	card:SetAttribute("SearchText", ((item.label or "").." "..(item.desc or "")):lower())

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -100, 0, 20),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = C.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -100, 0, 22),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = C.TextSub,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	attachTooltip(card, item.desc)

	local toggleBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(52, 28),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = card,
	})
	addHover(toggleBtn)

	local track = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.DarkGray,
		BackgroundTransparency = 0.1,
		ZIndex = 11,
		Parent = toggleBtn,
	})
	corner(track, 999)
	addStroke(track, C.DarkGray, 0.4, 1)

	local knob = create("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = C.White,
		ZIndex = 12,
		Parent = track,
	})
	corner(knob, 999)

	local enabled = item.default or false

	local function render()
		if enabled then
			tw(track, {BackgroundColor3 = C.Accent, BackgroundTransparency = 0}, 0.18)
			tw(knob, {Position = UDim2.new(1, -25, 0, 3)}, 0.18)
		else
			tw(track, {BackgroundColor3 = C.DarkGray, BackgroundTransparency = 0.1}, 0.18)
			tw(knob, {Position = UDim2.fromOffset(3, 3)}, 0.18)
		end
	end

	ToggleRenderers[item.key] = render

	local function setValue(v, silent)
		enabled = v
		State.Toggles[item.key] = v
		render()
		if not silent then
			updateAutomationProgress()
			local msg = enabled and "ativado" or "desativado"
			notify("Toggle", item.label .. " " .. msg .. ".", enabled and "success" or "warning")
		end
	end

	ToggleSetters[item.key] = setValue

	toggleBtn.MouseButton1Click:Connect(function()
		setValue(not enabled, false)
	end)

	setValue(enabled, true)
	return card
end

local function makeButton(parent, item)
	local card = makeCard(parent, 68)
	card:SetAttribute("SearchText", ((item.label or "").." "..(item.desc or "")):lower())

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -160, 0, 20),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = C.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -160, 0, 22),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = C.TextSub,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	attachTooltip(card, item.desc)

	local actionBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(130, 36),
		BackgroundColor3 = C.Accent,
		Text = item.buttonText or "Executar",
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = card,
	})
	corner(actionBtn, 10)
	addStroke(actionBtn, C.AccentGlow, 0.15, 1)
	addHover(actionBtn)

	actionBtn.MouseButton1Click:Connect(function()
		if item.action == "stopAll" then
			for key in pairs(AutomationKeys) do
				if ToggleSetters[key] then
					ToggleSetters[key](false, true)
				end
			end
			updateAutomationProgress()
			notify("Automações", "Todas desativadas.", "warning")
		elseif item.action == "copyJobId" then
			if setclipboard then
				pcall(setclipboard, game.JobId)
			end
			notify("Job ID", game.JobId, "info")
		else
			notify("Ação", item.label .. " executado.", "info")
		end
	end)

	return card
end

local function makeStatCard(parent, item)
	local card = makeCard(parent, 56)
	card:SetAttribute("SearchText", ((item.label or ""):lower()))

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -174, 1, 0),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	local pill = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(150, 32),
		BackgroundColor3 = C.BG4,
		BackgroundTransparency = 0.06,
		ZIndex = 9,
		Parent = card,
	})
	corner(pill, 10)
	addStroke(pill, C.Accent, 0.35, 1)

	local valueLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "--",
		TextColor3 = C.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		ZIndex = 10,
		Parent = pill,
	})

	bindStat(item.statKey, valueLabel, item.formatter)
	attachTooltip(card, item.desc)
	return card
end

local function makeTextBlock(parent, item)
	local card = makeCard(parent, nil, true)
	card:SetAttribute("SearchText", ((item.label or ""):lower()))
	pad(card, 14)

	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	local bodyLabel = create("TextLabel", {
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = C.TextSub,
		TextWrapped = true,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 9,
		Parent = card,
	})

	bindText(item.statKey, bodyLabel)
	return card
end

local function makeSlider(parent, item)
	local card = makeCard(parent, 88)
	card:SetAttribute("SearchText", ((item.label or ""):lower()))

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -100, 0, 18),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 28),
		Size = UDim2.new(1, -100, 0, 16),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = C.TextDim,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(70, 18),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = C.Accent,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 9,
		Parent = card,
	})

	local bar = create("Frame", {
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 0, 10),
		BackgroundColor3 = C.DarkGray,
		BackgroundTransparency = 0.3,
		ZIndex = 9,
		Parent = card,
	})
	corner(bar, 999)

	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.Accent,
		ZIndex = 10,
		Parent = bar,
	})
	corner(fill, 999)

	local knobEl = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = C.White,
		ZIndex = 11,
		Parent = bar,
	})
	corner(knobEl, 999)

	local min, max, step = item.min or 0, item.max or 1, item.step or 0.01
	local current = item.default or min
	local sliderDragging = false

	local function display(v)
		return item.formatter and item.formatter(v) or tostring(v)
	end

	local function setVal(v)
		v = clamp(v, min, max)
		v = math.round(v / step) * step
		if step >= 1 then v = math.floor(v) end
		current = v
		local a = (v - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knobEl.Position = UDim2.new(a, 0, 0.5, 0)
		valueLabel.Text = display(v)

		if item.onChanged then
			item.onChanged(v)
		end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliderDragging = true
			local rel = clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			setVal(min + (max - min) * rel)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliderDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local rel = clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			setVal(min + (max - min) * rel)
		end
	end)

	setVal(current)
	return card
end

local function makeGraph(parent, item)
	local card = makeCard(parent, 180)
	card:SetAttribute("SearchText", ((item.label or ""):lower()))

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 18),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = card,
	})

	local plot = create("Frame", {
		Position = UDim2.fromOffset(14, 38),
		Size = UDim2.new(1, -28, 1, -50),
		BackgroundColor3 = C.BG4,
		BackgroundTransparency = 0.1,
		ClipsDescendants = true,
		ZIndex = 9,
		Parent = card,
	})
	corner(plot, 10)
	addStroke(plot, C.DarkGray, 0.55, 1)

	for i = 1, 4 do
		create("Frame", {
			Position = UDim2.new(0, 0, i/5, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = 10,
			Parent = plot,
		})
	end

	for i = 1, 24 do
		local b = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 6 + (i-1)*15, 1, -6),
			Size = UDim2.new(0, 10, 0.05, 0),
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = plot,
		})
		corner(b, 999)
		table.insert(GraphBars, b)
	end

	return card
end

-- ════════════════════════════════════════
-- PROGRESS
-- ════════════════════════════════════════

function updateAutomationProgress()
	local total, active = 0, 0
	for key in pairs(AutomationKeys) do
		total += 1
		if State.Toggles[key] then active += 1 end
	end
	local pct = total > 0 and (active / total) or 0
	statusText.Text = active > 0
		and ("Automações ativas: %d/%d"):format(active, total)
		or "Nenhuma automação ativa"
	tw(progressFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2)
end

local function updateGraph()
	local maxV = 1
	for _, v in ipairs(moneyHistory) do maxV = math.max(maxV, v) end
	for i, bar in ipairs(GraphBars) do
		local val = moneyHistory[i] or 0
		local a = clamp(val / maxV, 0.05, 1)
		tw(bar, {Size = UDim2.new(0, 10, a, 0)}, 0.3)
	end
end

-- ════════════════════════════════════════
-- TAB DEFINITIONS
-- ════════════════════════════════════════

local TabDefs = {
	{
		name = "Farming", icon = "⚡",
		sections = {
			{title = "Automações", items = {
				{type="toggle", key="autoDrive", label="Auto Drive", desc="Segue uma rota automaticamente.", automation=true},
				{type="toggle", key="autoRaces", label="Auto Complete Races", desc="Completa corridas automaticamente.", automation=true},
				{type="toggle", key="autoDeliveries", label="Auto Delivery Jobs", desc="Conclui entregas automaticamente.", automation=true},
				{type="toggle", key="autoFarm", label="Auto Farm Money", desc="Rotina automática de ganho.", automation=true},
				{type="toggle", key="autoAcceptJobs", label="Auto Accept Jobs", desc="Aceita trabalhos automaticamente.", automation=true},
				{type="toggle", key="autoClaimRewards", label="Auto Claim Rewards", desc="Resgata recompensas automaticamente.", automation=true},
			}},
			{title = "Métricas", items = {
				{type="stat", statKey="profitPerMin", label="Dinheiro/minuto", desc="Estimativa baseada na sessão.", formatter=function(v) return formatMoney(v).."/min" end},
				{type="stat", statKey="sessionMoney", label="Total ganho na sessão", formatter=formatMoney},
				{type="stat", statKey="deliveries", label="Entregas concluídas", formatter=formatNum},
			}},
			{title = "Controles", items = {
				{type="button", action="stopAll", label="Parar todas automações", desc="Desativa todos os processos.", buttonText="⏹ Parar"},
			}},
		}
	},
	{
		name = "Teleports", icon = "📍",
		sections = {
			{title = "Locais", items = {
				{type="button", action="tpDealership", label="Concessionária", desc="Teleporte rápido.", buttonText="Ir"},
				{type="button", action="tpWorkshop", label="Oficina", desc="Teleporte rápido.", buttonText="Ir"},
				{type="button", action="tpFuel", label="Postos de combustível", desc="Teleporte rápido.", buttonText="Ir"},
				{type="button", action="tpEvents", label="Eventos", desc="Teleporte rápido.", buttonText="Ir"},
				{type="button", action="tpRaces", label="Corridas", desc="Teleporte rápido.", buttonText="Ir"},
				{type="button", action="tpPremium", label="Concessionárias premium", desc="Teleporte rápido.", buttonText="Ir"},
			}},
			{title = "Navegação", items = {
				{type="button", action="openCities", label="Lista de cidades", desc="Abre lista de cidades.", buttonText="Abrir"},
				{type="textblock", statKey="serverInfo", label="Favoritos", desc="Destinos favoritos."},
			}},
		}
	},
	{
		name = "Veículos", icon = "🚗",
		sections = {
			{title = "Gerenciamento", items = {
				{type="button", action="spawn", label="Spawnar veículo", desc="Gera o veículo escolhido.", buttonText="Spawnar"},
				{type="button", action="store", label="Guardar veículo", desc="Guarda o veículo atual.", buttonText="Guardar"},
				{type="button", action="repair", label="Reparar veículo", desc="Repara o veículo.", buttonText="Reparar"},
				{type="toggle", key="autoRefuel", label="Reabastecer automaticamente", desc="Mantém combustível cheio."},
			}},
			{title = "Telemetria", items = {
				{type="stat", statKey="vehicleSpeed", label="Velocidade"},
				{type="stat", statKey="vehicleMileage", label="Quilometragem"},
				{type="stat", statKey="vehiclePower", label="Potência"},
				{type="stat", statKey="vehicleAcceleration", label="Aceleração"},
				{type="stat", statKey="vehicleTraction", label="Tração"},
			}},
			{title = "Info", items = {
				{type="textblock", statKey="carInfo", label="Informações do carro"},
			}},
		}
	},
	{
		name = "Corridas", icon = "🏁",
		sections = {
			{title = "Automação", items = {
				{type="toggle", key="autoJoinRaces", label="Entrar em corridas", desc="Entra automaticamente."},
				{type="toggle", key="autoReady", label="Auto Ready", desc="Marca pronto automaticamente."},
			}},
			{title = "Tempo e Posição", items = {
				{type="stat", statKey="raceTime", label="Tempo da corrida"},
				{type="stat", statKey="racePosition", label="Posição atual"},
				{type="stat", statKey="bestRaceTime", label="Melhor tempo"},
			}},
			{title = "Histórico", items = {
				{type="textblock", statKey="raceHistory", label="Últimas corridas"},
				{type="stat", statKey="raceWins", label="Vitórias", formatter=formatNum},
				{type="stat", statKey="raceLosses", label="Derrotas", formatter=formatNum},
			}},
		}
	},
	{
		name = "Economia", icon = "💰",
		sections = {
			{title = "Resumo Financeiro", items = {
				{type="stat", statKey="moneyCurrent", label="Dinheiro atual", formatter=formatMoney},
				{type="stat", statKey="sessionMoney", label="Ganho na sessão", formatter=formatMoney},
				{type="stat", statKey="profitPerMin", label="Lucro/minuto", formatter=function(v) return formatMoney(v).."/min" end},
				{type="stat", statKey="deliveries", label="Total entregas", formatter=formatNum},
				{type="stat", statKey="raceWins", label="Corridas vencidas", formatter=formatNum},
				{type="stat", statKey="kmDriven", label="Km dirigidos", formatter=function(v) return formatNum(v).." km" end},
				{type="stat", statKey="sessionTime", label="Tempo sessão"},
			}},
			{title = "Análise", items = {
				{type="graph", label="Evolução financeira"},
			}},
		}
	},
	{
		name = "Visual", icon = "🎨",
		sections = {
			{title = "Personalização", items = {
				{type="slider", key="guiScale", label="Escala da GUI", desc="Ajusta o tamanho da interface.", min=0.75, max=1.3, step=0.01, default=1, formatter=function(v) return string.format("%.2fx", v) end, onChanged=function(v) end},
				{type="toggle", key="animations", label="Animações", desc="Liga/desliga animações.", default=true},
			}},
			{title = "Configurações", items = {
				{type="button", action="restoreDefaults", label="Restaurar padrões", desc="Reseta tudo.", buttonText="Restaurar"},
				{type="button", action="saveSettings", label="Salvar configs", desc="Salvar preferências.", buttonText="Salvar"},
			}},
		}
	},
	{
		name = "Utilidades", icon = "🔧",
		sections = {
			{title = "Sessão", items = {
				{type="toggle", key="antiAfk", label="Anti AFK", desc="Impede kick por inatividade."},
				{type="toggle", key="autoRejoin", label="Rejoin automático", desc="Reconecta automaticamente."},
				{type="button", action="copyJobId", label="Copiar Job ID", desc="Copia o ID da sessão.", buttonText="Copiar"},
			}},
			{title = "Servidor", items = {
				{type="textblock", statKey="serverInfo", label="Informações do servidor"},
				{type="stat", statKey="playersOnline", label="Jogadores online", formatter=formatNum},
				{type="stat", statKey="ping", label="Ping"},
				{type="stat", statKey="fps", label="FPS", formatter=function(v) return tostring(v) end},
				{type="stat", statKey="serverTime", label="Horário"},
			}},
		}
	},
}

-- Registrar automation keys
for _, tab in ipairs(TabDefs) do
	for _, sec in ipairs(tab.sections) do
		for _, item in ipairs(sec.items) do
			if item.automation and item.key then
				AutomationKeys[item.key] = true
			end
		end
	end
end

-- ════════════════════════════════════════
-- RENDER TABS
-- ════════════════════════════════════════

local currentTab = nil

local function selectTab(name)
	currentTab = name
	for tabName, info in pairs(PageMap) do
		local active = (tabName == name)
		info.page.Visible = active
		if active then
			info.page.Position = UDim2.new(0.02, 0, 0, 0)
			tw(info.page, {Position = UDim2.new(0, 0, 0, 0)}, 0.18)
			tw(info.btn, {BackgroundColor3 = C.Accent, BackgroundTransparency = 0.06}, 0.18)
			info.indicator.Visible = true
			tw(info.indicator, {Size = UDim2.new(0, 4, 0.65, 0)}, 0.18)
			info.titleLbl.TextColor3 = C.White
		else
			tw(info.btn, {BackgroundColor3 = C.BG4, BackgroundTransparency = 0.06}, 0.18)
			info.indicator.Visible = false
			info.titleLbl.TextColor3 = C.TextSub
		end
	end
	pageTitle.Text = name
	searchBox.Text = ""
end

-- Pesquisa
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = (searchBox.Text or ""):lower()
	local info = PageMap[currentTab]
	if not info then return end

	for _, secInfo in ipairs(info.sections) do
		local anyVisible = false
		for _, itemInfo in ipairs(secInfo.items) do
			local hay = itemInfo.card:GetAttribute("SearchText") or ""
			local vis = query == "" or string.find(hay, query, 1, true) ~= nil
			itemInfo.card.Visible = vis
			if vis then anyVisible = true end
		end
		secInfo.frame.Visible = anyVisible
	end
end)

-- Construir tabs
for _, tab in ipairs(TabDefs) do
	-- Sidebar button
	local tabBtn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = C.BG4,
		BackgroundTransparency = 0.06,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
		Parent = tabScroll,
	})
	corner(tabBtn, 12)
	addStroke(tabBtn, C.DarkGray, 0.5, 1)
	addHover(tabBtn)

	local indicator = create("Frame", {
		Visible = false,
		Position = UDim2.fromOffset(0, 7),
		Size = UDim2.new(0, 4, 0.65, 0),
		BackgroundColor3 = C.Accent,
		ZIndex = 9,
		Parent = tabBtn,
	})
	corner(indicator, 999)

	create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.fromOffset(26, 48),
		BackgroundTransparency = 1,
		Text = tab.icon,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		ZIndex = 9,
		Parent = tabBtn,
	})

	local tLbl = create("TextLabel", {
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -50, 1, 0),
		BackgroundTransparency = 1,
		Text = tab.name,
		TextColor3 = C.TextSub,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
		Parent = tabBtn,
	})

	-- Page
	local page = create("ScrollingFrame", {
		Name = tab.name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.Accent,
		Visible = false,
		ZIndex = 8,
		Parent = pagesHolder,
	})
	create("UIListLayout", {Padding = UDim.new(0, 9), Parent = page})
	pad(page, 2)

	local pageSections = {}

	for _, secDef in ipairs(tab.sections) do
		local sec = makeSection(page, secDef.title)
		local secItems = {}

		for _, item in ipairs(secDef.items) do
			local card
			if item.type == "toggle" then
				card = makeToggle(sec.body, item)
			elseif item.type == "button" then
				card = makeButton(sec.body, item)
			elseif item.type == "stat" then
				card = makeStatCard(sec.body, item)
			elseif item.type == "textblock" then
				card = makeTextBlock(sec.body, item)
			elseif item.type == "slider" then
				card = makeSlider(sec.body, item)
			elseif item.type == "graph" then
				card = makeGraph(sec.body, item)
			end
			if card then
				table.insert(secItems, {card = card})
			end
		end

		table.insert(pageSections, {frame = sec.frame, items = secItems})
	end

	PageMap[tab.name] = {
		btn = tabBtn,
		indicator = indicator,
		titleLbl = tLbl,
		page = page,
		sections = pageSections,
	}

	tabBtn.MouseButton1Click:Connect(function()
		selectTab(tab.name)
	end)
end

selectTab("Farming")
updateAutomationProgress()

-- ════════════════════════════════════════
-- DRAG (ARRASTAR JANELA)
-- ════════════════════════════════════════

do
	local dragging = false
	local dragStart, startPos

	headerFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = windowRoot.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			windowRoot.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ════════════════════════════════════════
-- RESIZE
-- ════════════════════════════════════════

do
	local resizing = false
	local resizeStart, sizeStart

	resizeHandle.MouseButton1Down:Connect(function()
		resizing = true
		resizeStart = UserInputService:GetMouseLocation()
		sizeStart = windowRoot.AbsoluteSize
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement and not State.Minimized then
			local delta = UserInputService:GetMouseLocation() - resizeStart
			local newW = clamp(sizeStart.X + delta.X, 820, 1500)
			local newH = clamp(sizeStart.Y + delta.Y, 520, 900)
			windowRoot.Size = UDim2.fromOffset(newW, newH)
		end
	end)
end

-- ════════════════════════════════════════
-- ABRIR / FECHAR / MINIMIZAR (CORRIGIDO)
-- ════════════════════════════════════════

local expandedSize = windowRoot.Size

local function openGUI()
	if State.Open then return end
	State.Open = true
	State.Minimized = false

	windowRoot.Visible = true
	bodyFrame.Visible = true
	resizeHandle.Visible = true
	openScale.Scale = 0.92
	mainFrame.BackgroundTransparency = 0.5

	tw(blur, {Size = 18}, 0.3)
	tw(openScale, {Scale = 1}, 0.28)
	tw(mainFrame, {BackgroundTransparency = 0.04}, 0.28)
end

local function closeGUI()
	if not State.Open then return end

	tw(openScale, {Scale = 0.92}, 0.2)
	tw(mainFrame, {BackgroundTransparency = 0.6}, 0.2)
	tw(blur, {Size = 0}, 0.2)

	task.delay(0.22, function()
		windowRoot.Visible = false
		State.Open = false
		State.Minimized = false
	end)
end

local function toggleGUI()
	if State.Open then
		closeGUI()
	else
		openGUI()
	end
end

-- Minimizar
minimizeBtn.MouseButton1Click:Connect(function()
	if not State.Open then return end

	State.Minimized = not State.Minimized

	if State.Minimized then
		expandedSize = windowRoot.Size
		tw(windowRoot, {Size = UDim2.fromOffset(windowRoot.AbsoluteSize.X, 72)}, 0.2)
		task.delay(0.18, function()
			if State.Minimized then
				bodyFrame.Visible = false
				resizeHandle.Visible = false
			end
		end)
	else
		bodyFrame.Visible = true
		resizeHandle.Visible = true
		tw(windowRoot, {Size = expandedSize}, 0.2)
	end
end)

-- Fechar
closeBtn.MouseButton1Click:Connect(function()
	closeGUI()
end)

-- Tecla RightShift para abrir/fechar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		toggleGUI()
	end
end)

-- ════════════════════════════════════════
-- LOOPS DE ATUALIZAÇÃO
-- ════════════════════════════════════════

-- FPS
do
	local frames = 0
	local lastTick = tick()

	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = tick()
		if now - lastTick >= 1 then
			local fps = frames
			frames = 0
			lastTick = now
			setStat("fps", fps)
			fpsLabel.Text = "FPS: " .. tostring(fps)
		end
	end)
end

-- Sessão, Ping, Players, etc.
task.spawn(function()
	while gui and gui.Parent do
		local elapsed = os.clock() - sessionStart
		local dur = formatTime(elapsed)
		setStat("sessionTime", dur)
		sessionLabel.Text = dur

		local perMin = math.floor((State.Stats.sessionMoney or 0) / math.max(elapsed / 60, 1))
		setStat("profitPerMin", perMin)

		setStat("playersOnline", #Players:GetPlayers())
		setStat("serverTime", os.date("%H:%M:%S"))

		-- Ping (tentativa)
		local pingStr = "-- ms"
		pcall(function()
			local stats = game:GetService("Stats")
			pingStr = tostring(math.floor(stats:GetValue("ReceiveDataCyclePing") or 0)) .. " ms"
		end)
		setStat("ping", pingStr)

		-- Server info
		setStat("serverInfo", string.format(
			"PlaceId: %s\nJobId: %s\nJogadores: %d\nUptime: %s",
			tostring(game.PlaceId),
			tostring(game.JobId),
			#Players:GetPlayers(),
			dur
		))

		task.wait(1)
	end
end)

-- Anti AFK (funcional)
task.spawn(function()
	while gui and gui.Parent do
		if State.Toggles["antiAfk"] then
			local vu = game:GetService("VirtualUser")
			pcall(function()
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
		end
		task.wait(60)
	end
end)

-- Gráfico
task.spawn(function()
	while gui and gui.Parent do
		table.insert(moneyHistory, State.Stats.sessionMoney or 0)
		if #moneyHistory > 24 then
			table.remove(moneyHistory, 1)
		end
		updateGraph()
		task.wait(5)
	end
end)

-- ════════════════════════════════════════
-- LOADING SEQUENCE (CORRIGIDA)
-- ════════════════════════════════════════

task.spawn(function()
	-- Loading animation
	tw(loadFill, {Size = UDim2.new(0.3, 0, 1, 0)}, 0.4)
	task.wait(0.4)
	tw(loadFill, {Size = UDim2.new(0.6, 0, 1, 0)}, 0.35)
	task.wait(0.35)
	tw(loadFill, {Size = UDim2.new(0.85, 0, 1, 0)}, 0.3)
	task.wait(0.3)
	tw(loadFill, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
	task.wait(0.35)

	-- Fade out loading
	tw(loadScreen, {BackgroundTransparency = 1}, 0.3)
	tw(loadCard, {BackgroundTransparency = 1}, 0.3)

	for _, child in ipairs(loadCard:GetDescendants()) do
		pcall(function()
			if child:IsA("TextLabel") or child:IsA("Frame") then
				tw(child, {BackgroundTransparency = 1}, 0.25)
			end
			if child:IsA("TextLabel") then
				tw(child, {TextTransparency = 1}, 0.25)
			end
		end)
	end

	task.wait(0.35)
	loadScreen:Destroy()

	-- Abrir GUI
	openGUI()

	task.wait(0.3)
	notify("Redarelhos Hub v2.0", "Interface carregada! Use RightShift para abrir/fechar.", "success")
end)
