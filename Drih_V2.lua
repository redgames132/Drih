--// ══════════════════════════════════════════════════════════════
--// REDARELHOS HUB v3.0 — VERMELHO & PRETO
--// LocalScript → StarterGui
--// Abrir/Fechar: RightShift ou botão na tela
--// ══════════════════════════════════════════════════════════════

--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--// LIMPAR INSTÂNCIAS ANTERIORES
for _, v in ipairs(PlayerGui:GetChildren()) do
	if v.Name == "RedarelhosHub" then v:Destroy() end
end
for _, v in ipairs(Lighting:GetChildren()) do
	if v.Name == "RHBlur" then v:Destroy() end
end

--// ══════════════════════════════════════
--// CORES
--// ══════════════════════════════════════

local Color = {
	Red = Color3.fromRGB(255, 30, 30),
	RedGlow = Color3.fromRGB(255, 55, 55),
	RedDark = Color3.fromRGB(160, 10, 10),
	RedSoft = Color3.fromRGB(255, 85, 85),

	BG = Color3.fromRGB(6, 6, 10),
	Panel = Color3.fromRGB(12, 12, 18),
	Card = Color3.fromRGB(18, 18, 26),
	Elevated = Color3.fromRGB(26, 26, 36),

	White = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(190, 190, 210),
	DimText = Color3.fromRGB(120, 120, 145),
	Gray = Color3.fromRGB(40, 40, 52),
	Black = Color3.fromRGB(0, 0, 0),

	Green = Color3.fromRGB(60, 255, 110),
	Yellow = Color3.fromRGB(255, 210, 80),
	ErrRed = Color3.fromRGB(255, 70, 70),
}

--// ══════════════════════════════════════
--// ESTADO
--// ══════════════════════════════════════

local HubState = {
	isOpen = false,
	isMinimized = false,
	toggles = {},
	currentTab = nil,
	savedSize = nil,
	driftMode = false,
	speedLimit = 0,
	nitroActive = false,
}

local sessionStart = os.clock()
local moneyData = {}
for i = 1, 24 do moneyData[i] = 0 end

local StatLabels = {}
local TextLabels = {}
local ToggleFuncs = {}
local GraphBars = {}
local SearchCards = {}
local TabPages = {}
local TabButtons = {}
local AutoKeys = {}

local Stats = {
	fps = 0, ping = "-- ms", sessionTime = "00:00:00",
	moneyCurrent = 0, sessionMoney = 0, profitPerMin = 0,
	deliveries = 0, raceWins = 0, raceLosses = 0, kmDriven = 0,
	vehicleSpeed = "0 km/h", vehicleMileage = "0 km",
	vehiclePower = "0 HP", vehicleAcceleration = "--",
	vehicleTraction = "--", carInfo = "Nenhum veículo detectado.",
	raceTime = "--:--.---", racePosition = "#--",
	bestRaceTime = "--:--.---",
	raceHistory = "Nenhuma corrida registrada.",
	playersOnline = 0, serverTime = "--:--:--",
	serverInfo = "", speedLimitDisplay = "OFF",
	driftStatus = "OFF", nitroStatus = "OFF",
}

--// ══════════════════════════════════════
--// FUNÇÕES UTILITÁRIAS
--// ══════════════════════════════════════

local function new(class, props, children)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then obj[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = obj end
	if props and props.Parent then obj.Parent = props.Parent end
	return obj
end

local function addCorner(obj, r)
	new("UICorner", {CornerRadius = UDim.new(0, r or 12), Parent = obj})
end

local function addStroke(obj, col, trans, thick)
	return new("UIStroke", {
		Color = col or Color.Red,
		Transparency = trans or 0.5,
		Thickness = thick or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = obj,
	})
end

local function addPadding(obj, px)
	new("UIPadding", {
		PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px),
		Parent = obj,
	})
end

local function animate(obj, props, dur)
	local t = TweenService:Create(obj,
		TweenInfo.new(dur or 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function clampN(n, a, b) return math.max(a, math.min(b, n)) end

local function fmtNum(n)
	n = math.floor(tonumber(n) or 0)
	local s, k = tostring(n), 1
	while k > 0 do s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2") end
	return s
end

local function fmtMoney(n) return "$ " .. fmtNum(n) end

local function fmtTime(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60)
end

local function setStat(key, val)
	Stats[key] = val
	for _, b in ipairs(StatLabels[key] or {}) do
		pcall(function() b.label.Text = b.fmt and b.fmt(val) or tostring(val) end)
	end
	for _, lbl in ipairs(TextLabels[key] or {}) do
		pcall(function() lbl.Text = tostring(val) end)
	end
end

local function bindStat(key, label, fmt)
	StatLabels[key] = StatLabels[key] or {}
	table.insert(StatLabels[key], {label = label, fmt = fmt})
	label.Text = fmt and fmt(Stats[key]) or tostring(Stats[key])
end

local function bindText(key, label)
	TextLabels[key] = TextLabels[key] or {}
	table.insert(TextLabels[key], label)
	label.Text = tostring(Stats[key] or "")
end

local function addHover(btn)
	local sc = new("UIScale", {Scale = 1, Parent = btn})
	btn.MouseEnter:Connect(function() animate(sc, {Scale = 1.03}, 0.1) end)
	btn.MouseLeave:Connect(function() animate(sc, {Scale = 1}, 0.1) end)
end

--// ══════════════════════════════════════
--// SCREENGUI
--// ══════════════════════════════════════

local ScreenGui = new("ScreenGui", {
	Name = "RedarelhosHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = PlayerGui,
})

local BlurEffect = new("BlurEffect", {
	Name = "RHBlur",
	Size = 0,
	Parent = Lighting,
})

--// ══════════════════════════════════════
--// BOTÃO FLUTUANTE (SEMPRE VISÍVEL)
--// ══════════════════════════════════════

local floatBtn = new("TextButton", {
	Name = "FloatBtn",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(48, 48),
	BackgroundColor3 = Color.Red,
	Text = "RH",
	TextColor3 = Color.White,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	ZIndex = 999,
	Parent = ScreenGui,
})
addCorner(floatBtn, 14)
addStroke(floatBtn, Color.RedGlow, 0.1, 2)
addHover(floatBtn)

--// ══════════════════════════════════════
--// NOTIFICAÇÕES
--// ══════════════════════════════════════

local notifBox = new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 16),
	Size = UDim2.new(0, 330, 1, -32),
	BackgroundTransparency = 1,
	ZIndex = 900,
	Parent = ScreenGui,
})
new("UIListLayout", {
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 8),
	Parent = notifBox,
})

local function notify(title, body, kind)
	local col = Color.Red
	if kind == "success" then col = Color.Green
	elseif kind == "warning" then col = Color.Yellow
	elseif kind == "error" then col = Color.ErrRed end

	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color.Panel,
		BackgroundTransparency = 0.04,
		ClipsDescendants = true,
		ZIndex = 901,
		Parent = notifBox,
	})
	addCorner(card, 12)
	addStroke(card, col, 0.15, 1.2)

	new("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = col,
		BorderSizePixel = 0,
		ZIndex = 902,
		Parent = card,
	})

	new("TextLabel", {
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundTransparency = 1,
		Text = title or "",
		TextColor3 = Color.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 902,
		Parent = card,
	})

	new("TextLabel", {
		Position = UDim2.fromOffset(16, 30),
		Size = UDim2.new(1, -24, 0, 30),
		BackgroundTransparency = 1,
		Text = body or "",
		TextColor3 = Color.SubText,
		TextWrapped = true,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 902,
		Parent = card,
	})

	animate(card, {Size = UDim2.new(1, 0, 0, 68)}, 0.22)

	task.delay(4, function()
		pcall(function()
			animate(card, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
			task.wait(0.25)
			card:Destroy()
		end)
	end)
end

--// ══════════════════════════════════════
--// TOOLTIP
--// ══════════════════════════════════════

local tipLabel = new("TextLabel", {
	Visible = false,
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundColor3 = Color.Panel,
	BackgroundTransparency = 0.06,
	TextColor3 = Color.White,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextWrapped = true,
	ZIndex = 950,
	Parent = ScreenGui,
})
addPadding(tipLabel, 8)
addCorner(tipLabel, 8)
addStroke(tipLabel, Color.Red, 0.3, 1)

local function setTooltip(obj, text)
	if not text or text == "" then return end
	obj.MouseEnter:Connect(function() tipLabel.Text = text; tipLabel.Visible = true end)
	obj.MouseLeave:Connect(function() tipLabel.Visible = false end)
end

UserInputService.InputChanged:Connect(function(input)
	if tipLabel.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
		tipLabel.Position = UDim2.fromOffset(input.Position.X + 14, input.Position.Y + 14)
	end
end)

--// ══════════════════════════════════════
--// JANELA PRINCIPAL
--// ══════════════════════════════════════

local Window = new("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(960, 620),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 10,
	Parent = ScreenGui,
})
new("UISizeConstraint", {MinSize = Vector2.new(820, 500), MaxSize = Vector2.new(1400, 850), Parent = Window})

local WinScale = new("UIScale", {Scale = 0.9, Parent = Window})

-- Sombra
local Shadow = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 5),
	Size = UDim2.new(1, 8, 1, 8),
	BackgroundColor3 = Color.Black,
	BackgroundTransparency = 0.45,
	ZIndex = 9,
	Parent = Window,
})
addCorner(Shadow, 24)

-- Main
local Main = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color.BG,
	BackgroundTransparency = 0.02,
	ClipsDescendants = true,
	ZIndex = 11,
	Parent = Window,
})
addCorner(Main, 20)
addStroke(Main, Color.Red, 0.2, 1.5)

-- Partículas
for i = 1, 16 do
	local dot = new("Frame", {
		Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4)),
		Position = UDim2.new(math.random() * 0.95, 0, math.random() * 0.95, 0),
		BackgroundColor3 = Color.Red,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = Main,
	})
	addCorner(dot, 999)
	task.spawn(function()
		while dot and dot.Parent do
			animate(dot, {
				Position = UDim2.new(math.random() * 0.95, 0, math.random() * 0.95, 0),
				BackgroundTransparency = 0.84 + math.random() * 0.12,
			}, 6 + math.random() * 5)
			task.wait(5 + math.random() * 4)
		end
	end)
end

--// ══════════════════════════════════════
--// HEADER
--// ══════════════════════════════════════

local Header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 68),
	BackgroundColor3 = Color.Panel,
	BackgroundTransparency = 0.02,
	ZIndex = 20,
	Parent = Main,
})

-- Logo
local LogoBox = new("Frame", {
	Position = UDim2.fromOffset(14, 11),
	Size = UDim2.fromOffset(44, 44),
	BackgroundColor3 = Color.Red,
	ZIndex = 21,
	Parent = Header,
})
addCorner(LogoBox, 13)
addStroke(LogoBox, Color.RedGlow, 0.05, 1.5)

new("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "RH",
	TextColor3 = Color.White,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	ZIndex = 22,
	Parent = LogoBox,
})

-- Título
new("TextLabel", {
	Position = UDim2.fromOffset(70, 8),
	Size = UDim2.fromOffset(280, 26),
	BackgroundTransparency = 1,
	Text = "REDARELHOS HUB",
	TextColor3 = Color.White,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21,
	Parent = Header,
})

new("TextLabel", {
	Position = UDim2.fromOffset(70, 36),
	Size = UDim2.fromOffset(320, 16),
	BackgroundTransparency = 1,
	Text = "Car Dealership Tycoon • v3.0",
	TextColor3 = Color.DimText,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21,
	Parent = Header,
})

-- Header pills
local function headerPill(parent, text, w)
	local p = new("Frame", {
		Size = UDim2.fromOffset(w, 28),
		BackgroundColor3 = Color.Elevated,
		BackgroundTransparency = 0.06,
		ZIndex = 21,
		Parent = parent,
	})
	addCorner(p, 8)
	addStroke(p, Color.Gray, 0.45, 1)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = text,
		TextColor3 = Color.White,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		ZIndex = 22,
		Parent = p,
	})
	return p, l
end

local PillStrip = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -105, 0.5, 0),
	Size = UDim2.fromOffset(420, 32),
	BackgroundTransparency = 1,
	ZIndex = 21,
	Parent = Header,
})
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	Parent = PillStrip,
})

local _, VersionPill = headerPill(PillStrip, "v3.0", 52)
local _, SessionPill = headerPill(PillStrip, "00:00:00", 80)
local _, FpsPill = headerPill(PillStrip, "FPS: 0", 68)
local _, PlayerPill = headerPill(PillStrip, Player.Name, 120)

-- Header buttons
local BtnHolder = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(84, 34),
	BackgroundTransparency = 1,
	ZIndex = 21,
	Parent = Header,
})
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 6),
	Parent = BtnHolder,
})

local function hdrBtn(text, col)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(36, 32),
		BackgroundColor3 = Color.Elevated,
		BackgroundTransparency = 0.06,
		Text = text,
		TextColor3 = col or Color.White,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		ZIndex = 22,
		Parent = BtnHolder,
	})
	addCorner(b, 9)
	addStroke(b, col or Color.Gray, 0.4, 1)
	addHover(b)
	return b
end

local MinBtn = hdrBtn("—", Color.White)
local CloseBtn = hdrBtn("✕", Color.ErrRed)

--// ══════════════════════════════════════
--// BODY
--// ══════════════════════════════════════

local Body = new("Frame", {
	Position = UDim2.fromOffset(0, 68),
	Size = UDim2.new(1, 0, 1, -68),
	BackgroundTransparency = 1,
	ZIndex = 15,
	Parent = Main,
})

-- Sidebar
local Sidebar = new("Frame", {
	Position = UDim2.fromOffset(10, 8),
	Size = UDim2.new(0, 200, 1, -16),
	BackgroundColor3 = Color.Panel,
	BackgroundTransparency = 0.03,
	ZIndex = 16,
	Parent = Body,
})
addCorner(Sidebar, 14)
addStroke(Sidebar, Color.Gray, 0.45, 1)

-- Pesquisa
local SearchFrame = new("Frame", {
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.new(1, -20, 0, 36),
	BackgroundColor3 = Color.Elevated,
	BackgroundTransparency = 0.05,
	ZIndex = 17,
	Parent = Sidebar,
})
addCorner(SearchFrame, 10)
addStroke(SearchFrame, Color.Gray, 0.5, 1)

new("TextLabel", {
	Position = UDim2.fromOffset(10, 0),
	Size = UDim2.fromOffset(18, 36),
	BackgroundTransparency = 1,
	Text = "🔍",
	TextSize = 12,
	ZIndex = 18,
	Parent = SearchFrame,
})

local SearchInput = new("TextBox", {
	Position = UDim2.fromOffset(30, 0),
	Size = UDim2.new(1, -38, 1, 0),
	BackgroundTransparency = 1,
	PlaceholderText = "Pesquisar...",
	Text = "",
	TextColor3 = Color.White,
	PlaceholderColor3 = Color.DimText,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	ZIndex = 18,
	Parent = SearchFrame,
})

-- Tab list
local TabList = new("ScrollingFrame", {
	Position = UDim2.fromOffset(6, 54),
	Size = UDim2.new(1, -12, 1, -62),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Color.Red,
	ZIndex = 17,
	Parent = Sidebar,
})
new("UIListLayout", {Padding = UDim.new(0, 6), Parent = TabList})

-- Content area
local Content = new("Frame", {
	Position = UDim2.new(0, 222, 0, 8),
	Size = UDim2.new(1, -232, 1, -16),
	BackgroundColor3 = Color.Panel,
	BackgroundTransparency = 0.03,
	ZIndex = 16,
	Parent = Body,
})
addCorner(Content, 14)
addStroke(Content, Color.Gray, 0.45, 1)

-- Content header
local ContentHdr = new("Frame", {
	Position = UDim2.fromOffset(12, 10),
	Size = UDim2.new(1, -24, 0, 44),
	BackgroundColor3 = Color.Elevated,
	BackgroundTransparency = 0.05,
	ZIndex = 17,
	Parent = Content,
})
addCorner(ContentHdr, 10)
addStroke(ContentHdr, Color.Gray, 0.5, 1)

local PageTitleLabel = new("TextLabel", {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(0.6, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color.White,
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 18,
	Parent = ContentHdr,
})

new("TextLabel", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(220, 16),
	BackgroundTransparency = 1,
	Text = "Redarelhos Hub Premium",
	TextColor3 = Color.DimText,
	TextSize = 10,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 18,
	Parent = ContentHdr,
})

-- Page container
local PageContainer = new("Frame", {
	Position = UDim2.fromOffset(12, 64),
	Size = UDim2.new(1, -24, 1, -114),
	BackgroundTransparency = 1,
	ZIndex = 17,
	Parent = Content,
})

-- Status bar
local StatusBar = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(1, -24, 0, 36),
	BackgroundColor3 = Color.Elevated,
	BackgroundTransparency = 0.05,
	ZIndex = 17,
	Parent = Content,
})
addCorner(StatusBar, 10)
addStroke(StatusBar, Color.Gray, 0.5, 1)

local StatusLabel = new("TextLabel", {
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "Pronto",
	TextColor3 = Color.White,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 18,
	Parent = StatusBar,
})

local ProgressTrack = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(200, 6),
	BackgroundColor3 = Color.Gray,
	BackgroundTransparency = 0.3,
	ZIndex = 18,
	Parent = StatusBar,
})
addCorner(ProgressTrack, 999)

local ProgressFill = new("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color.Red,
	ZIndex = 19,
	Parent = ProgressTrack,
})
addCorner(ProgressFill, 999)

-- Resize
local ResizeBtn = new("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -5, 1, -3),
	Size = UDim2.fromOffset(18, 18),
	BackgroundTransparency = 1,
	Text = "◢",
	TextColor3 = Color.Red,
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	ZIndex = 30,
	Parent = Main,
})

--// ══════════════════════════════════════
--// COMPONENTES DE CONTEÚDO
--// ══════════════════════════════════════

local function mkCard(parent, h, autoY)
	local c = new("Frame", {
		Size = UDim2.new(1, 0, 0, h or 64),
		AutomaticSize = autoY and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BackgroundColor3 = Color.Card,
		BackgroundTransparency = 0.04,
		ZIndex = 20,
		Parent = parent,
	})
	addCorner(c, 12)
	addStroke(c, Color.Gray, 0.55, 1)
	return c
end

local function mkSection(parent, title)
	local sec = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = parent,
	})
	new("UIListLayout", {Padding = UDim.new(0, 6), Parent = sec})

	local hdr = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color.Elevated,
		BackgroundTransparency = 0.05,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 21,
		Parent = sec,
	})
	addCorner(hdr, 10)
	addStroke(hdr, Color.Gray, 0.5, 1)
	addHover(hdr)

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -36, 1, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Color.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
		Parent = hdr,
	})

	local chev = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text = "▾",
		TextColor3 = Color.Red,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		ZIndex = 22,
		Parent = hdr,
	})

	local body = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = sec,
	})
	new("UIListLayout", {Padding = UDim.new(0, 6), Parent = body})

	local collapsed = false
	hdr.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		body.Visible = not collapsed
		chev.Text = collapsed and "▸" or "▾"
	end)

	return sec, body
end

local function mkToggle(parent, item)
	local card = mkCard(parent, 62)
	card:SetAttribute("SearchKey", ((item.label or "") .. " " .. (item.desc or "")):lower())
	table.insert(SearchCards, card)

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -90, 0, 18),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Color.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 28),
		Size = UDim2.new(1, -90, 0, 20),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = Color.SubText,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	setTooltip(card, item.desc)

	local tBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(48, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 22,
		Parent = card,
	})

	local track = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color.Gray,
		ZIndex = 23,
		Parent = tBtn,
	})
	addCorner(track, 999)

	local knob = new("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color.White,
		ZIndex = 24,
		Parent = track,
	})
	addCorner(knob, 999)

	local on = item.default or false

	local function render()
		if on then
			animate(track, {BackgroundColor3 = Color.Red}, 0.15)
			animate(knob, {Position = UDim2.new(1, -23, 0, 3)}, 0.15)
		else
			animate(track, {BackgroundColor3 = Color.Gray}, 0.15)
			animate(knob, {Position = UDim2.fromOffset(3, 3)}, 0.15)
		end
	end

	local function set(val, silent)
		on = val
		HubState.toggles[item.key] = val
		render()
		if not silent then
			updateProgress()
			if item.onToggle then item.onToggle(val) end
			notify("Toggle", item.label .. (val and " ativado" or " desativado"), val and "success" or "warning")
		end
	end

	ToggleFuncs[item.key] = set

	tBtn.MouseButton1Click:Connect(function()
		set(not on, false)
	end)

	set(on, true)
	return card
end

local function mkButton(parent, item)
	local card = mkCard(parent, 62)
	card:SetAttribute("SearchKey", ((item.label or "") .. " " .. (item.desc or "")):lower())
	table.insert(SearchCards, card)

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -150, 0, 18),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Color.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 28),
		Size = UDim2.new(1, -150, 0, 20),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = Color.SubText,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	setTooltip(card, item.desc)

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(120, 32),
		BackgroundColor3 = Color.Red,
		Text = item.btnText or "Executar",
		TextColor3 = Color.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		ZIndex = 22,
		Parent = card,
	})
	addCorner(btn, 8)
	addStroke(btn, Color.RedGlow, 0.1, 1)
	addHover(btn)

	btn.MouseButton1Click:Connect(function()
		if item.onClick then
			item.onClick()
		else
			notify("Ação", item.label .. " executado.", "info")
		end
	end)

	return card
end

local function mkStat(parent, item)
	local card = mkCard(parent, 52)
	card:SetAttribute("SearchKey", ((item.label or ""):lower()))
	table.insert(SearchCards, card)

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -162, 1, 0),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Color.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(140, 28),
		BackgroundColor3 = Color.Elevated,
		BackgroundTransparency = 0.05,
		ZIndex = 21,
		Parent = card,
	})
	addCorner(pill, 8)
	addStroke(pill, Color.Red, 0.35, 1)

	local vLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "--",
		TextColor3 = Color.White,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		ZIndex = 22,
		Parent = pill,
	})

	bindStat(item.statKey, vLabel, item.fmt)
	return card
end

local function mkTextBlock(parent, item)
	local card = mkCard(parent, nil, true)
	card:SetAttribute("SearchKey", ((item.label or ""):lower()))
	table.insert(SearchCards, card)
	addPadding(card, 12)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Color.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	local bl = new("TextLabel", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 36),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color.SubText,
		TextWrapped = true,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 21,
		Parent = card,
	})

	bindText(item.statKey, bl)
	return card
end

local function mkSlider(parent, item)
	local card = mkCard(parent, 82)
	card:SetAttribute("SearchKey", ((item.label or ""):lower()))
	table.insert(SearchCards, card)

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -90, 0, 16),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Color.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 26),
		Size = UDim2.new(1, -90, 0, 14),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = Color.DimText,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	local vLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(60, 16),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color.Red,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 21,
		Parent = card,
	})

	local bar = new("Frame", {
		Position = UDim2.fromOffset(12, 54),
		Size = UDim2.new(1, -24, 0, 8),
		BackgroundColor3 = Color.Gray,
		BackgroundTransparency = 0.3,
		ZIndex = 21,
		Parent = card,
	})
	addCorner(bar, 999)

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color.Red,
		ZIndex = 22,
		Parent = bar,
	})
	addCorner(fill, 999)

	local kn = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color.White,
		ZIndex = 23,
		Parent = bar,
	})
	addCorner(kn, 999)

	local min, max, step = item.min or 0, item.max or 1, item.step or 0.01
	local cur = item.default or min
	local isDragging = false

	local function display(v)
		return item.fmt and item.fmt(v) or tostring(v)
	end

	local function setV(v)
		v = clampN(v, min, max)
		v = math.round(v / step) * step
		if step >= 1 then v = math.floor(v) end
		cur = v
		local a = (v - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		kn.Position = UDim2.new(a, 0, 0.5, 0)
		vLabel.Text = display(v)
		if item.onChanged then item.onChanged(v) end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			local rel = clampN((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			setV(min + (max - min) * rel)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local rel = clampN((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			setV(min + (max - min) * rel)
		end
	end)

	setV(cur)
	return card
end

local function mkGraph(parent, item)
	local card = mkCard(parent, 170)
	card:SetAttribute("SearchKey", ((item.label or ""):lower()))
	table.insert(SearchCards, card)

	new("TextLabel", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Color.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = card,
	})

	local plot = new("Frame", {
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 1, -42),
		BackgroundColor3 = Color.Elevated,
		BackgroundTransparency = 0.08,
		ClipsDescendants = true,
		ZIndex = 21,
		Parent = card,
	})
	addCorner(plot, 8)

	for i = 1, 24 do
		local b = new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 4 + (i-1)*14, 1, -4),
			Size = UDim2.new(0, 10, 0.04, 0),
			BackgroundColor3 = Color.Red,
			BorderSizePixel = 0,
			ZIndex = 22,
			Parent = plot,
		})
		addCorner(b, 999)
		table.insert(GraphBars, b)
	end

	return card
end

--// ══════════════════════════════════════
--// PROGRESS
--// ══════════════════════════════════════

function updateProgress()
	local total, active = 0, 0
	for key in pairs(AutoKeys) do
		total += 1
		if HubState.toggles[key] then active += 1 end
	end
	local pct = total > 0 and (active / total) or 0
	StatusLabel.Text = active > 0 and ("Automações: %d/%d"):format(active, total) or "Pronto"
	animate(ProgressFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2)
end

local function updateGraph()
	local mx = 1
	for _, v in ipairs(moneyData) do mx = math.max(mx, v) end
	for i, bar in ipairs(GraphBars) do
		local val = moneyData[i] or 0
		local a = clampN(val / mx, 0.04, 1)
		animate(bar, {Size = UDim2.new(0, 10, a, 0)}, 0.3)
	end
end

--// ══════════════════════════════════════
--// FUNÇÕES DE DIREÇÃO (DRIVING)
--// ══════════════════════════════════════

local function getVehicleSeat()
	local char = Player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local seat = hum.SeatPart
	if seat and (seat:IsA("VehicleSeat") or seat.Name == "DriveSeat") then
		return seat
	end
	return nil
end

local function getVehicleModel()
	local seat = getVehicleSeat()
	if not seat then return nil end
	local model = seat.Parent
	while model and not model:IsA("Model") do
		model = model.Parent
	end
	return model
end

local function applyDriftMode(enabled)
	HubState.driftMode = enabled
	setStat("driftStatus", enabled and "ON" or "OFF")

	task.spawn(function()
		while HubState.driftMode do
			local seat = getVehicleSeat()
			if seat and seat:IsA("VehicleSeat") then
				pcall(function()
					seat.TurnSpeed = enabled and 8 or 1
					seat.Torque = enabled and (seat.Torque * 1.0) or seat.Torque
				end)
			end
			task.wait(0.5)
		end
		-- Restaurar
		local seat = getVehicleSeat()
		if seat and seat:IsA("VehicleSeat") then
			pcall(function() seat.TurnSpeed = 1 end)
		end
	end)
end

local function applySpeedLimit(limit)
	HubState.speedLimit = limit
	setStat("speedLimitDisplay", limit > 0 and (tostring(limit) .. " km/h") or "OFF")

	task.spawn(function()
		while HubState.speedLimit > 0 do
			local seat = getVehicleSeat()
			if seat and seat:IsA("VehicleSeat") then
				pcall(function()
					local currentSpeed = seat.Velocity.Magnitude * 3.6
					if currentSpeed > HubState.speedLimit then
						seat.MaxSpeed = HubState.speedLimit / 3.6
					end
				end)
			end
			task.wait(0.1)
		end
		-- Restaurar
		local seat = getVehicleSeat()
		if seat and seat:IsA("VehicleSeat") then
			pcall(function() seat.MaxSpeed = 999 end)
		end
	end)
end

local function applyNitro(enabled)
	HubState.nitroActive = enabled
	setStat("nitroStatus", enabled and "ATIVO" or "OFF")

	task.spawn(function()
		while HubState.nitroActive do
			local seat = getVehicleSeat()
			if seat and seat:IsA("VehicleSeat") then
				pcall(function()
					local dir = seat.CFrame.LookVector
					seat.Velocity = seat.Velocity + dir * 2
				end)
			end
			task.wait(0.08)
		end
	end)
end

--// ══════════════════════════════════════
--// DEFINIÇÕES DAS TABS
--// ══════════════════════════════════════

local Tabs = {
	{
		name = "Farming", icon = "⚡",
		sections = {
			{title = "Automações", items = {
				{t="toggle", key="autoDrive", label="Auto Drive", desc="Segue rota automaticamente.", auto=true},
				{t="toggle", key="autoRaces", label="Auto Complete Races", desc="Completa corridas.", auto=true},
				{t="toggle", key="autoDelivery", label="Auto Delivery Jobs", desc="Conclui entregas.", auto=true},
				{t="toggle", key="autoFarm", label="Auto Farm Money", desc="Rotina de ganho automática.", auto=true},
				{t="toggle", key="autoAccept", label="Auto Accept Jobs", desc="Aceita trabalhos.", auto=true},
				{t="toggle", key="autoClaim", label="Auto Claim Rewards", desc="Resgata recompensas.", auto=true},
			}},
			{title = "Métricas", items = {
				{t="stat", statKey="profitPerMin", label="Dinheiro/min", fmt=function(v) return fmtMoney(v).."/min" end},
				{t="stat", statKey="sessionMoney", label="Total sessão", fmt=fmtMoney},
				{t="stat", statKey="deliveries", label="Entregas concluídas", fmt=fmtNum},
			}},
			{title = "Controles", items = {
				{t="button", label="Parar tudo", desc="Desativa todas automações.", btnText="⏹ Parar", onClick=function()
					for key in pairs(AutoKeys) do
						if ToggleFuncs[key] then ToggleFuncs[key](false, true) end
					end
					updateProgress()
					notify("Automações", "Todas desativadas.", "warning")
				end},
			}},
		}
	},
	{
		name = "Direção", icon = "🏎️",
		sections = {
			{title = "Modos de Direção", items = {
				{t="toggle", key="driftMode", label="Modo Drift", desc="Aumenta a rotação para facilitar derrapagens.", onToggle=function(v) applyDriftMode(v) end},
				{t="toggle", key="nitroBoost", label="Nitro Boost", desc="Aplica impulso contínuo ao veículo.", onToggle=function(v) applyNitro(v) end},
				{t="toggle", key="autoSteer", label="Auto Steer (Correção)", desc="Corrige automaticamente a direção em retas."},
				{t="toggle", key="stabilizer", label="Estabilizador de Veículo", desc="Reduz capotamentos e instabilidades."},
			}},
			{title = "Limitador de Velocidade", items = {
				{t="slider", key="speedLimiter", label="Limite de Velocidade", desc="Define velocidade máxima (0 = sem limite).", min=0, max=300, step=10, default=0, fmt=function(v)
					if v == 0 then return "OFF" end
					return tostring(v) .. " km/h"
				end, onChanged=function(v)
					applySpeedLimit(v)
				end},
				{t="stat", statKey="speedLimitDisplay", label="Limite atual"},
			}},
			{title = "Câmera de Direção", items = {
				{t="toggle", key="freeCam", label="Câmera Livre", desc="Desbloqueia a rotação da câmera durante direção."},
				{t="toggle", key="rearCam", label="Câmera Traseira", desc="Alterna para visão traseira ao segurar tecla."},
				{t="slider", key="camDist", label="Distância da Câmera", desc="Ajusta o zoom da câmera.", min=10, max=60, step=1, default=20, fmt=function(v)
					return tostring(v) .. "m"
				end, onChanged=function(v)
					pcall(function() Player.CameraMaxZoomDistance = v end)
				end},
				{t="slider", key="fov", label="Campo de Visão (FOV)", desc="Altera o FOV da câmera.", min=50, max=120, step=1, default=70, fmt=function(v)
					return tostring(v) .. "°"
				end, onChanged=function(v)
					pcall(function() workspace.CurrentCamera.FieldOfView = v end)
				end},
			}},
			{title = "Status do Veículo", items = {
				{t="stat", statKey="driftStatus", label="Drift Mode"},
				{t="stat", statKey="nitroStatus", label="Nitro"},
				{t="stat", statKey="vehicleSpeed", label="Velocidade Atual"},
			}},
			{title = "Telemetria em Tempo Real", items = {
				{t="stat", statKey="vehiclePower", label="Potência"},
				{t="stat", statKey="vehicleAcceleration", label="Aceleração"},
				{t="stat", statKey="vehicleTraction", label="Tração"},
				{t="stat", statKey="vehicleMileage", label="Quilometragem"},
			}},
		}
	},
	{
		name = "Teleports", icon = "📍",
		sections = {
			{title = "Locais", items = {
				{t="button", label="Concessionária", desc="TP rápido.", btnText="Ir", onClick=function() notify("Teleport", "Conecte ao sistema de TP do jogo.", "info") end},
				{t="button", label="Oficina", desc="TP rápido.", btnText="Ir"},
				{t="button", label="Postos de Combustível", desc="TP rápido.", btnText="Ir"},
				{t="button", label="Eventos", desc="TP rápido.", btnText="Ir"},
				{t="button", label="Corridas", desc="TP rápido.", btnText="Ir"},
				{t="button", label="Premium Dealers", desc="TP rápido.", btnText="Ir"},
			}},
			{title = "Navegação", items = {
				{t="button", label="Lista de Cidades", desc="Abre todas cidades.", btnText="Abrir"},
				{t="textblock", statKey="serverInfo", label="Favoritos"},
			}},
		}
	},
	{
		name = "Veículos", icon = "🚗",
		sections = {
			{title = "Gerenciamento", items = {
				{t="button", label="Spawnar Veículo", desc="Gera o veículo.", btnText="Spawnar"},
				{t="button", label="Guardar Veículo", desc="Guarda veículo.", btnText="Guardar"},
				{t="button", label="Reparar Veículo", desc="Repara veículo.", btnText="Reparar"},
				{t="toggle", key="autoRefuel", label="Reabastecer Auto", desc="Mantém combustível."},
			}},
			{title = "Telemetria", items = {
				{t="stat", statKey="vehicleSpeed", label="Velocidade"},
				{t="stat", statKey="vehicleMileage", label="Quilometragem"},
				{t="stat", statKey="vehiclePower", label="Potência"},
				{t="stat", statKey="vehicleAcceleration", label="Aceleração"},
				{t="stat", statKey="vehicleTraction", label="Tração"},
			}},
			{title = "Info", items = {
				{t="textblock", statKey="carInfo", label="Informações do carro"},
			}},
		}
	},
	{
		name = "Corridas", icon = "🏁",
		sections = {
			{title = "Automação", items = {
				{t="toggle", key="autoJoinRace", label="Auto Join Corridas", desc="Entra automaticamente."},
				{t="toggle", key="autoReady", label="Auto Ready", desc="Marca pronto."},
			}},
			{title = "Tempo", items = {
				{t="stat", statKey="raceTime", label="Tempo da Corrida"},
				{t="stat", statKey="racePosition", label="Posição"},
				{t="stat", statKey="bestRaceTime", label="Melhor Tempo"},
			}},
			{title = "Resultados", items = {
				{t="textblock", statKey="raceHistory", label="Histórico"},
				{t="stat", statKey="raceWins", label="Vitórias", fmt=fmtNum},
				{t="stat", statKey="raceLosses", label="Derrotas", fmt=fmtNum},
			}},
		}
	},
	{
		name = "Economia", icon = "💰",
		sections = {
			{title = "Financeiro", items = {
				{t="stat", statKey="moneyCurrent", label="Dinheiro atual", fmt=fmtMoney},
				{t="stat", statKey="sessionMoney", label="Ganho sessão", fmt=fmtMoney},
				{t="stat", statKey="profitPerMin", label="Lucro/min", fmt=function(v) return fmtMoney(v).."/min" end},
				{t="stat", statKey="deliveries", label="Entregas", fmt=fmtNum},
				{t="stat", statKey="raceWins", label="Corridas vencidas", fmt=fmtNum},
				{t="stat", statKey="kmDriven", label="Km dirigidos", fmt=function(v) return fmtNum(v).." km" end},
				{t="stat", statKey="sessionTime", label="Tempo sessão"},
			}},
			{title = "Gráfico", items = {
				{t="graph", label="Evolução Financeira"},
			}},
		}
	},
	{
		name = "Visual", icon = "🎨",
		sections = {
			{title = "Interface", items = {
				{t="toggle", key="animations", label="Animações", desc="Liga/desliga animações.", default=true},
			}},
			{title = "Configurações", items = {
				{t="button", label="Restaurar Padrões", desc="Reseta tudo.", btnText="Restaurar"},
				{t="button", label="Salvar Configs", desc="Salvar.", btnText="Salvar"},
			}},
		}
	},
	{
		name = "Utilidades", icon = "🔧",
		sections = {
			{title = "Sessão", items = {
				{t="toggle", key="antiAfk", label="Anti AFK", desc="Impede kick por inatividade.", onToggle=function(v)
					if v then
						task.spawn(function()
							while HubState.toggles["antiAfk"] do
								pcall(function()
									local vu = game:GetService("VirtualUser")
									vu:CaptureController()
									vu:ClickButton2(Vector2.new())
								end)
								task.wait(55)
							end
						end)
					end
				end},
				{t="toggle", key="autoRejoin", label="Rejoin Automático", desc="Reconecta se desconectar."},
				{t="button", label="Copiar Job ID", desc="Copia o ID.", btnText="Copiar", onClick=function()
					pcall(function() if setclipboard then setclipboard(game.JobId) end end)
					notify("Job ID", game.JobId, "info")
				end},
			}},
			{title = "Servidor", items = {
				{t="textblock", statKey="serverInfo", label="Info do Servidor"},
				{t="stat", statKey="playersOnline", label="Jogadores", fmt=fmtNum},
				{t="stat", statKey="ping", label="Ping"},
				{t="stat", statKey="fps", label="FPS", fmt=function(v) return tostring(v) end},
				{t="stat", statKey="serverTime", label="Horário"},
			}},
		}
	},
}

-- Registrar automation keys
for _, tab in ipairs(Tabs) do
	for _, sec in ipairs(tab.sections) do
		for _, item in ipairs(sec.items) do
			if item.auto and item.key then AutoKeys[item.key] = true end
		end
	end
end

--// ══════════════════════════════════════
--// CONSTRUIR TABS
--// ══════════════════════════════════════

local function selectTab(name)
	HubState.currentTab = name
	PageTitleLabel.Text = name

	for tabName, info in pairs(TabPages) do
		local active = (tabName == name)
		info.page.Visible = active

		if active then
			info.page.CanvasPosition = Vector2.new(0, 0)
			animate(info.btn, {BackgroundColor3 = Color.Red, BackgroundTransparency = 0.05}, 0.15)
			info.indicator.Visible = true
			info.lbl.TextColor3 = Color.White
		else
			animate(info.btn, {BackgroundColor3 = Color.Elevated, BackgroundTransparency = 0.05}, 0.15)
			info.indicator.Visible = false
			info.lbl.TextColor3 = Color.SubText
		end
	end

	SearchInput.Text = ""
end

-- Pesquisa
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	local query = (SearchInput.Text or ""):lower()
	local info = TabPages[HubState.currentTab]
	if not info then return end

	for _, secInfo in ipairs(info.secs) do
		local anyVis = false
		for _, cardInfo in ipairs(secInfo.cards) do
			local hay = cardInfo:GetAttribute("SearchKey") or ""
			local vis = query == "" or hay:find(query, 1, true) ~= nil
			cardInfo.Visible = vis
			if vis then anyVis = true end
		end
		secInfo.frame.Visible = anyVis
	end
end)

for _, tab in ipairs(Tabs) do
	-- Sidebar button
	local tBtn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Color.Elevated,
		BackgroundTransparency = 0.05,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 18,
		Parent = TabList,
	})
	addCorner(tBtn, 10)
	addStroke(tBtn, Color.Gray, 0.5, 1)
	addHover(tBtn)

	local indicator = new("Frame", {
		Visible = false,
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(0, 3, 0.65, 0),
		BackgroundColor3 = Color.Red,
		ZIndex = 19,
		Parent = tBtn,
	})
	addCorner(indicator, 999)

	new("TextLabel", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(22, 44),
		BackgroundTransparency = 1,
		Text = tab.icon,
		TextSize = 14,
		ZIndex = 19,
		Parent = tBtn,
	})

	local tLbl = new("TextLabel", {
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -42, 1, 0),
		BackgroundTransparency = 1,
		Text = tab.name,
		TextColor3 = Color.SubText,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 19,
		Parent = tBtn,
	})

	-- Page
	local page = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color.Red,
		Visible = false,
		ZIndex = 20,
		Parent = PageContainer,
	})
	new("UIListLayout", {Padding = UDim.new(0, 8), Parent = page})

	local pageSecs = {}

	for _, secDef in ipairs(tab.sections) do
		local secFrame, secBody = mkSection(page, secDef.title)
		local secCards = {}

		for _, item in ipairs(secDef.items) do
			local card
			if item.t == "toggle" then card = mkToggle(secBody, item)
			elseif item.t == "button" then card = mkButton(secBody, item)
			elseif item.t == "stat" then card = mkStat(secBody, item)
			elseif item.t == "textblock" then card = mkTextBlock(secBody, item)
			elseif item.t == "slider" then card = mkSlider(secBody, item)
			elseif item.t == "graph" then card = mkGraph(secBody, item)
			end
			if card then table.insert(secCards, card) end
		end

		table.insert(pageSecs, {frame = secFrame, cards = secCards})
	end

	TabPages[tab.name] = {
		btn = tBtn,
		indicator = indicator,
		lbl = tLbl,
		page = page,
		secs = pageSecs,
	}

	tBtn.MouseButton1Click:Connect(function()
		selectTab(tab.name)
	end)
end

selectTab("Farming")
updateProgress()

--// ══════════════════════════════════════
--// DRAG
--// ══════════════════════════════════════

do
	local dragging, dragStart, startPos = false, nil, nil

	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

--// ══════════════════════════════════════
--// RESIZE
--// ══════════════════════════════════════

do
	local resizing, resStart, szStart = false, nil, nil

	ResizeBtn.MouseButton1Down:Connect(function()
		resizing = true
		resStart = UserInputService:GetMouseLocation()
		szStart = Window.AbsoluteSize
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement and not HubState.isMinimized then
			local delta = UserInputService:GetMouseLocation() - resStart
			Window.Size = UDim2.fromOffset(clampN(szStart.X + delta.X, 820, 1400), clampN(szStart.Y + delta.Y, 500, 850))
		end
	end)
end

--// ══════════════════════════════════════
--// ABRIR / FECHAR / MINIMIZAR
--// ══════════════════════════════════════

local function openHub()
	if HubState.isOpen then return end
	HubState.isOpen = true
	HubState.isMinimized = false

	Window.Visible = true
	Body.Visible = true
	ResizeBtn.Visible = true
	WinScale.Scale = 0.9
	Main.BackgroundTransparency = 0.5
	floatBtn.Visible = false

	animate(BlurEffect, {Size = 16}, 0.25)
	animate(WinScale, {Scale = 1}, 0.25)
	animate(Main, {BackgroundTransparency = 0.02}, 0.25)
end

local function closeHub()
	if not HubState.isOpen then return end

	animate(WinScale, {Scale = 0.9}, 0.18)
	animate(Main, {BackgroundTransparency = 0.6}, 0.18)
	animate(BlurEffect, {Size = 0}, 0.18)

	task.delay(0.2, function()
		Window.Visible = false
		HubState.isOpen = false
		HubState.isMinimized = false
		floatBtn.Visible = true
	end)
end

local function toggleHub()
	if HubState.isOpen then closeHub() else openHub() end
end

-- Minimizar
MinBtn.MouseButton1Click:Connect(function()
	if not HubState.isOpen then return end
	HubState.isMinimized = not HubState.isMinimized

	if HubState.isMinimized then
		HubState.savedSize = Window.Size
		animate(Window, {Size = UDim2.fromOffset(Window.AbsoluteSize.X, 68)}, 0.18)
		task.delay(0.16, function()
			if HubState.isMinimized then
				Body.Visible = false
				ResizeBtn.Visible = false
			end
		end)
	else
		Body.Visible = true
		ResizeBtn.Visible = true
		if HubState.savedSize then
			animate(Window, {Size = HubState.savedSize}, 0.18)
		end
	end
end)

-- Fechar
CloseBtn.MouseButton1Click:Connect(function()
	closeHub()
end)

-- Botão flutuante
floatBtn.MouseButton1Click:Connect(function()
	openHub()
end)

-- Tecla RightShift
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		toggleHub()
	end
end)

--// ══════════════════════════════════════
--// LOOPS DE ATUALIZAÇÃO
--// ══════════════════════════════════════

-- FPS
do
	local frameCount = 0
	local lastCheck = tick()

	RunService.RenderStepped:Connect(function()
		frameCount += 1
		local now = tick()
		if now - lastCheck >= 1 then
			local fps = frameCount
			frameCount = 0
			lastCheck = now
			setStat("fps", fps)
			FpsPill.Text = "FPS: " .. tostring(fps)
		end
	end)
end

-- Velocidade em tempo real
RunService.Heartbeat:Connect(function()
	local seat = getVehicleSeat()
	if seat then
		local speed = math.floor(seat.Velocity.Magnitude * 3.6)
		setStat("vehicleSpeed", tostring(speed) .. " km/h")
	else
		setStat("vehicleSpeed", "0 km/h")
	end
end)

-- Sessão, ping, players
task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		local elapsed = os.clock() - sessionStart
		local dur = fmtTime(elapsed)
		setStat("sessionTime", dur)
		SessionPill.Text = dur

		local pm = math.floor((Stats.sessionMoney or 0) / math.max(elapsed / 60, 1))
		setStat("profitPerMin", pm)

		setStat("playersOnline", #Players:GetPlayers())
		setStat("serverTime", os.date("%H:%M:%S"))

		local pingStr = "-- ms"
		pcall(function()
			pingStr = tostring(math.floor(Player:GetNetworkPing() * 1000)) .. " ms"
		end)
		setStat("ping", pingStr)

		setStat("serverInfo", string.format(
			"PlaceId: %s\nJobId: %s\nJogadores: %d\nUptime: %s",
			tostring(game.PlaceId), tostring(game.JobId),
			#Players:GetPlayers(), dur
		))

		-- Informações do veículo
		local model = getVehicleModel()
		if model then
			local seat = getVehicleSeat()
			local info = "Veículo: " .. model.Name
			if seat and seat:IsA("VehicleSeat") then
				info = info .. "\nMaxSpeed: " .. tostring(math.floor(seat.MaxSpeed))
				info = info .. "\nTorque: " .. tostring(math.floor(seat.Torque))
				info = info .. "\nTurnSpeed: " .. tostring(seat.TurnSpeed)
			end
			setStat("carInfo", info)
			pcall(function()
				setStat("vehiclePower", tostring(math.floor(seat.Torque)) .. " T")
			end)
		end

		task.wait(1)
	end
end)

-- Gráfico
task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		table.insert(moneyData, Stats.sessionMoney or 0)
		if #moneyData > 24 then table.remove(moneyData, 1) end
		updateGraph()
		task.wait(5)
	end
end)

--// ══════════════════════════════════════
--// INICIALIZAÇÃO
--// ══════════════════════════════════════

-- Abrir automaticamente
task.delay(0.5, function()
	openHub()
	task.wait(0.3)
	notify("Redarelhos Hub v3.0", "Interface carregada! RightShift para abrir/fechar.", "success")
	notify("Nova tab: Direção", "Drift, limitador de velocidade, nitro, câmera e mais!", "info")
end)
