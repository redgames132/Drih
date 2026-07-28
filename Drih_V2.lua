--// REDARELHOS HUB - UI FRAMEWORK
--// Uso: LocalScript em StarterPlayerScripts ou StarterGui
--// Observação:
--// Este script cria a interface completa e profissional.
--// As funções de automação/teleporte/etc. estão como HOOKS visuais,
--// para você conectar apenas em experiências próprias/autorizadas.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

--//====================================================
--// PALETA / TEMAS
--//====================================================

local ThemePresets = {
	["Neon Blue"] = {
		main = Color3.fromRGB(10, 25, 48),    -- #0A1930
		panel = Color3.fromRGB(14, 31, 58),
		card = Color3.fromRGB(18, 39, 75),
		pill = Color3.fromRGB(25, 46, 86),
	},
	["Royal Blue"] = {
		main = Color3.fromRGB(9, 20, 40),
		panel = Color3.fromRGB(18, 34, 69),
		card = Color3.fromRGB(26, 47, 93),
		pill = Color3.fromRGB(35, 57, 108),
	},
	["Ice Tech"] = {
		main = Color3.fromRGB(15, 24, 43),
		panel = Color3.fromRGB(19, 34, 62),
		card = Color3.fromRGB(23, 44, 82),
		pill = Color3.fromRGB(30, 52, 96),
	},
}

local AccentPalette = {
	Color3.fromRGB(0, 175, 255),  -- #00AFFF
	Color3.fromRGB(50, 205, 255),
	Color3.fromRGB(91, 140, 255),
}

local Colors = {
	MediumBlue = Color3.fromRGB(30, 58, 138), -- #1E3A8A
	White = Color3.fromRGB(255, 255, 255),    -- #FFFFFF
	DarkGray = Color3.fromRGB(26, 26, 26),    -- #1A1A1A
	Black = Color3.fromRGB(0, 0, 0),
	Red = Color3.fromRGB(255, 96, 96),
	Green = Color3.fromRGB(72, 255, 155),
	Yellow = Color3.fromRGB(255, 214, 92),
}

local Defaults = {
	theme = "Neon Blue",
	mainColor = AccentPalette[1],
	transparency = 0.18,
	scale = 1,
	compact = false,
	animations = true,
}

local State = {
	Settings = {
		theme = Defaults.theme,
		mainColor = Defaults.mainColor,
		transparency = Defaults.transparency,
		scale = Defaults.scale,
		compact = Defaults.compact,
		animations = Defaults.animations,
	},
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
		carInfo = "Aguardando integração do veículo atual.",

		raceTime = "--:--.---",
		racePosition = "#--",
		bestRaceTime = "--:--.---",
		raceHistory = "Nenhuma corrida registrada na sessão.",

		playersOnline = #Players:GetPlayers(),
		ping = "-- ms",
		fps = 0,
		serverTime = "--:--:--",
		serverInfo = ("PlaceId: %s\nJobId: %s"):format(game.PlaceId, game.JobId),
	},
	Toggles = {},
}

local sessionStart = os.clock()
local moneyHistory = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

--//====================================================
--// HELPERS
--//====================================================

local function create(className, props, children)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	return obj
end

local function round(obj, radius)
	create("UICorner", {
		CornerRadius = UDim.new(0, radius or 14),
		Parent = obj
	})
end

local function stroke(obj, color, transparency, thickness)
	local s = create("UIStroke", {
		Color = color or State.Settings.mainColor,
		Transparency = transparency == nil and 0.4 or transparency,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = obj
	})
	return s
end

local function padding(obj, px)
	create("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = obj
	})
end

local function tween(obj, props, t, style, dir)
	if not State.Settings.animations then
		for k, v in pairs(props) do
			obj[k] = v
		end
		return
	end

	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function formatNumber(n)
	n = tonumber(n) or 0
	local s = tostring(math.floor(n))
	while true do
		local replaced
		s, replaced = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
		if replaced == 0 then
			break
		end
	end
	return s
end

local function formatMoney(n)
	return "$ " .. formatNumber(n)
end

local function formatTime(sec)
	sec = math.max(0, math.floor(sec))
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function clamp(n, a, b)
	return math.max(a, math.min(b, n))
end

local CLICK_SOUND_ID = "rbxassetid://0" -- substitua pelo seu asset se quiser
local clickSound = create("Sound", {
	Name = "RedarelhosClick",
	SoundId = CLICK_SOUND_ID,
	Volume = 0.2,
	Parent = SoundService
})

local function playClick()
	if clickSound.SoundId ~= "rbxassetid://0" then
		clickSound:Play()
	end
end

--//====================================================
--// REGISTROS DE ESTILO
--//====================================================

local BackgroundRegistry = {}
local AccentBGRegistry = {}
local AccentStrokeRegistry = {}
local AccentTextRegistry = {}
local DescriptionRegistry = {}
local ToggleRenderers = {}
local StatBindings = {}
local TextBindings = {}
local GraphBars = {}
local ToggleBindings = {}
local Pages = {}
local AutomationKeys = {}

local function registerBackground(obj, role, baseTransparency)
	table.insert(BackgroundRegistry, {
		obj = obj,
		role = role,
		base = baseTransparency or 0,
	})
end

local function registerAccentBG(obj)
	table.insert(AccentBGRegistry, obj)
end

local function registerAccentStroke(obj)
	table.insert(AccentStrokeRegistry, obj)
end

local function registerAccentText(obj)
	table.insert(AccentTextRegistry, obj)
end

local function registerDescription(obj)
	table.insert(DescriptionRegistry, obj)
end

local function bindStat(key, label, formatter)
	StatBindings[key] = StatBindings[key] or {}
	table.insert(StatBindings[key], {label = label, formatter = formatter})
	local value = State.Stats[key]
	label.Text = formatter and formatter(value) or tostring(value)
end

local function bindText(key, label)
	TextBindings[key] = TextBindings[key] or {}
	table.insert(TextBindings[key], label)
	label.Text = tostring(State.Stats[key] or "")
end

local function updateGraph()
	local maxValue = 1
	for _, v in ipairs(moneyHistory) do
		maxValue = math.max(maxValue, tonumber(v) or 0)
	end

	for i, bar in ipairs(GraphBars) do
		local value = moneyHistory[i] or 0
		local alpha = clamp(value / maxValue, 0.06, 1)
		bar.Size = UDim2.new(0, 12, alpha, 0)
		bar.Position = UDim2.new(0, (i - 1) * 16, 1, -6)
	end
end

local function setStat(key, value)
	State.Stats[key] = value

	for _, binding in ipairs(StatBindings[key] or {}) do
		binding.label.Text = binding.formatter and binding.formatter(value) or tostring(value)
	end

	for _, label in ipairs(TextBindings[key] or {}) do
		label.Text = tostring(value)
	end
end

local function applyVisuals()
	local preset = ThemePresets[State.Settings.theme]
	local delta = State.Settings.transparency - Defaults.transparency

	for _, entry in ipairs(BackgroundRegistry) do
		if entry.obj and entry.obj.Parent then
			entry.obj.BackgroundColor3 = preset[entry.role] or preset.card
			entry.obj.BackgroundTransparency = clamp(entry.base + delta, 0, 0.9)
		end
	end

	for _, obj in ipairs(AccentBGRegistry) do
		if obj and obj.Parent then
			obj.BackgroundColor3 = State.Settings.mainColor
		end
	end

	for _, obj in ipairs(AccentStrokeRegistry) do
		if obj and obj.Parent then
			obj.Color = State.Settings.mainColor
		end
	end

	for _, obj in ipairs(AccentTextRegistry) do
		if obj and obj.Parent then
			obj.TextColor3 = State.Settings.mainColor
		end
	end

	for _, render in pairs(ToggleRenderers) do
		render()
	end

	for _, label in ipairs(DescriptionRegistry) do
		if label and label.Parent then
			label.Visible = not State.Settings.compact
		end
	end
end

--//====================================================
--// GUI BASE
--//====================================================

local screenGui = create("ScreenGui", {
	Name = "RedarelhosHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = LocalPlayer:WaitForChild("PlayerGui"),
})

local blur = Lighting:FindFirstChild("RedarelhosHubBlur")
if blur then
	blur:Destroy()
end
blur = create("BlurEffect", {
	Name = "RedarelhosHubBlur",
	Size = 0,
	Parent = Lighting
})

local notifications = create("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 20),
	Size = UDim2.new(0, 320, 1, -40),
	BackgroundTransparency = 1,
	Parent = screenGui,
})
create("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 10),
	Parent = notifications
})

local tooltip = create("TextLabel", {
	Name = "Tooltip",
	Visible = false,
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundColor3 = Colors.DarkGray,
	BackgroundTransparency = 0.15,
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 500,
	Parent = screenGui,
})
padding(tooltip, 10)
round(tooltip, 12)
stroke(tooltip, State.Settings.mainColor, 0.35, 1)

local loading = create("Frame", {
	Name = "LoadingScreen",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Colors.Black,
	BackgroundTransparency = 0.15,
	Parent = screenGui,
})
local loadingCard = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(420, 180),
	BackgroundTransparency = 0.12,
	Parent = loading,
})
registerBackground(loadingCard, "panel", 0.12)
round(loadingCard, 22)
local loadingStroke = stroke(loadingCard, State.Settings.mainColor, 0.2, 1.4)
registerAccentStroke(loadingStroke)

local logo = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.14),
	Size = UDim2.fromOffset(64, 64),
	BackgroundTransparency = 0.08,
	Parent = loadingCard,
})
registerBackground(logo, "pill", 0.08)
round(logo, 18)
local logoStroke = stroke(logo, State.Settings.mainColor, 0.1, 1.6)
registerAccentStroke(logoStroke)

local logoText = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "RH",
	TextColor3 = State.Settings.mainColor,
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	Parent = logo,
})
registerAccentText(logoText)

create("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.56),
	Size = UDim2.fromOffset(360, 30),
	Text = "REDARELHOS HUB",
	TextColor3 = Colors.White,
	TextSize = 26,
	Font = Enum.Font.GothamBold,
	Parent = loadingCard,
})

create("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.74),
	Size = UDim2.fromOffset(360, 22),
	Text = "Inicializando interface premium...",
	TextColor3 = Color3.fromRGB(220, 230, 255),
	TextTransparency = 0.08,
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	Parent = loadingCard,
})

local loadTrack = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.88),
	Size = UDim2.fromOffset(320, 10),
	BackgroundColor3 = Colors.DarkGray,
	BackgroundTransparency = 0.35,
	Parent = loadingCard,
})
round(loadTrack, 999)

local loadFill = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = State.Settings.mainColor,
	Parent = loadTrack,
})
round(loadFill, 999)
registerAccentBG(loadFill)

local viewport = Camera and Camera.ViewportSize or Vector2.new(1600, 900)
local startW = clamp(math.floor(viewport.X * 0.72), 860, 1280)
local startH = clamp(math.floor(viewport.Y * 0.74), 560, 760)

local windowRoot = create("Frame", {
	Name = "WindowRoot",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(startW, startH),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = screenGui,
})
create("UISizeConstraint", {
	MinSize = Vector2.new(820, 520),
	MaxSize = Vector2.new(1500, 900),
	Parent = windowRoot,
})

local openScale = create("UIScale", {
	Scale = 0.96,
	Parent = windowRoot
})

local shadow = create("Frame", {
	Position = UDim2.fromOffset(0, 10),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Colors.Black,
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	Parent = windowRoot,
})
round(shadow, 22)

local main = create("Frame", {
	Name = "Main",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 0.12,
	ClipsDescendants = true,
	Parent = windowRoot,
})
registerBackground(main, "main", 0.12)
round(main, 22)
local mainStroke = stroke(main, State.Settings.mainColor, 0.2, 1.4)
registerAccentStroke(mainStroke)

local userScale = create("UIScale", {
	Scale = State.Settings.scale,
	Parent = main
})

local particleLayer = create("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = main,
})

for i = 1, 18 do
	local dot = create("Frame", {
		Size = UDim2.fromOffset(math.random(2, 5), math.random(2, 5)),
		Position = UDim2.new(math.random(), 0, math.random(), 0),
		BackgroundColor3 = State.Settings.mainColor,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Parent = particleLayer,
	})
	registerAccentBG(dot)
	round(dot, 999)

	task.spawn(function()
		while dot.Parent do
			local targetPos = UDim2.new(math.random(), 0, math.random(), 0)
			local targetTransparency = 0.82 + math.random() * 0.12
			tween(dot, {Position = targetPos, BackgroundTransparency = targetTransparency}, 6 + math.random() * 6)
			task.wait(5 + math.random() * 4)
		end
	end)
end

local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 74),
	BackgroundTransparency = 0.07,
	Parent = main,
})
registerBackground(header, "panel", 0.07)

local headerLogo = create("Frame", {
	Position = UDim2.fromOffset(18, 13),
	Size = UDim2.fromOffset(46, 46),
	BackgroundTransparency = 0.08,
	Parent = header,
})
registerBackground(headerLogo, "pill", 0.08)
round(headerLogo, 15)
local headerLogoStroke = stroke(headerLogo, State.Settings.mainColor, 0.05, 1.5)
registerAccentStroke(headerLogoStroke)

local headerLogoText = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "RH",
	TextColor3 = State.Settings.mainColor,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	Parent = headerLogo,
})
registerAccentText(headerLogoText)

local title = create("TextLabel", {
	Position = UDim2.fromOffset(76, 12),
	Size = UDim2.fromOffset(300, 24),
	BackgroundTransparency = 1,
	Text = "REDARELHOS HUB",
	TextColor3 = Colors.White,
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
})

local subtitle = create("TextLabel", {
	Position = UDim2.fromOffset(76, 38),
	Size = UDim2.fromOffset(280, 18),
	BackgroundTransparency = 1,
	Text = "Car Dealership Tycoon • Interface Premium",
	TextColor3 = Color3.fromRGB(205, 220, 255),
	TextTransparency = 0.08,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
})

local function makePill(parent, text, width)
	local pill = create("Frame", {
		Size = UDim2.fromOffset(width or 94, 32),
		BackgroundTransparency = 0.14,
		Parent = parent,
	})
	registerBackground(pill, "pill", 0.14)
	round(pill, 12)
	stroke(pill, Colors.MediumBlue, 0.55, 1)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = text,
		TextColor3 = Colors.White,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		Parent = pill,
	})
	return pill, label
end

local statsStrip = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -120, 0.5, 0),
	Size = UDim2.fromOffset(520, 38),
	BackgroundTransparency = 1,
	Parent = header,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	Parent = statsStrip
})

local _, versionPill = makePill(statsStrip, "v1.0.0", 72)
local _, sessionPill = makePill(statsStrip, "00:00:00", 92)
local _, fpsPill = makePill(statsStrip, "FPS: 0", 80)
local _, playerPill = makePill(statsStrip, LocalPlayer.Name, 140)

local btnHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -18, 0.5, 0),
	Size = UDim2.fromOffset(86, 34),
	BackgroundTransparency = 1,
	Parent = header,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	Parent = btnHolder
})

local function makeHeaderButton(text, color)
	local button = create("TextButton", {
		Size = UDim2.fromOffset(38, 34),
		BackgroundTransparency = 0.12,
		Text = text,
		TextColor3 = color or Colors.White,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = btnHolder,
	})
	registerBackground(button, "pill", 0.12)
	round(button, 10)
	stroke(button, color or State.Settings.mainColor, 0.45, 1)
	return button
end

local minimizeBtn = makeHeaderButton("—", Colors.White)
local closeBtn = makeHeaderButton("✕", Colors.Red)

local body = create("Frame", {
	Name = "Body",
	Position = UDim2.fromOffset(0, 74),
	Size = UDim2.new(1, 0, 1, -74),
	BackgroundTransparency = 1,
	Parent = main,
})

local sidebar = create("Frame", {
	Name = "Sidebar",
	Position = UDim2.fromOffset(14, 12),
	Size = UDim2.new(0, 230, 1, -24),
	BackgroundTransparency = 0.08,
	Parent = body,
})
registerBackground(sidebar, "panel", 0.08)
round(sidebar, 18)
stroke(sidebar, Colors.MediumBlue, 0.55, 1)

local content = create("Frame", {
	Name = "Content",
	Position = UDim2.new(0, 256, 0, 12),
	Size = UDim2.new(1, -270, 1, -24),
	BackgroundTransparency = 0.06,
	Parent = body,
})
registerBackground(content, "panel", 0.06)
round(content, 18)
stroke(content, Colors.MediumBlue, 0.55, 1)

local searchWrap = create("Frame", {
	Position = UDim2.fromOffset(14, 14),
	Size = UDim2.new(1, -28, 0, 42),
	BackgroundTransparency = 0.08,
	Parent = sidebar,
})
registerBackground(searchWrap, "pill", 0.08)
round(searchWrap, 14)
stroke(searchWrap, Colors.MediumBlue, 0.55, 1)

create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.fromOffset(24, 42),
	Text = "⌕",
	TextColor3 = State.Settings.mainColor,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Parent = searchWrap,
})
local searchIcon = searchWrap:FindFirstChildOfClass("TextLabel")
if searchIcon then registerAccentText(searchIcon) end

local searchBox = create("TextBox", {
	Position = UDim2.fromOffset(38, 0),
	Size = UDim2.new(1, -48, 1, 0),
	BackgroundTransparency = 1,
	PlaceholderText = "Pesquisar funções...",
	Text = "",
	TextColor3 = Colors.White,
	PlaceholderColor3 = Color3.fromRGB(180, 200, 230),
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	Parent = searchWrap,
})

local tabsScroll = create("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 68),
	Size = UDim2.new(1, -20, 1, -78),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = State.Settings.mainColor,
	Parent = sidebar,
})
create("UIListLayout", {
	Padding = UDim.new(0, 8),
	Parent = tabsScroll
})

local contentHeader = create("Frame", {
	Position = UDim2.fromOffset(16, 14),
	Size = UDim2.new(1, -32, 0, 52),
	BackgroundTransparency = 0.08,
	Parent = content,
})
registerBackground(contentHeader, "pill", 0.08)
round(contentHeader, 14)
stroke(contentHeader, Colors.MediumBlue, 0.55, 1)

local pageTitle = create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.new(0.5, 0, 1, 0),
	Text = "Farming",
	TextColor3 = Colors.White,
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = contentHeader,
})

local pageSub = create("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(260, 18),
	Text = "Painel organizado • Futurista • Responsivo",
	TextColor3 = Color3.fromRGB(205, 220, 255),
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = contentHeader,
})

local pagesHolder = create("Frame", {
	Position = UDim2.fromOffset(16, 78),
	Size = UDim2.new(1, -32, 1, -132),
	BackgroundTransparency = 1,
	Parent = content,
})

local statusBar = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -14),
	Size = UDim2.new(1, -32, 0, 40),
	BackgroundTransparency = 0.08,
	Parent = content,
})
registerBackground(statusBar, "pill", 0.08)
round(statusBar, 14)
stroke(statusBar, Colors.MediumBlue, 0.55, 1)

local statusText = create("TextLabel", {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(0, 260, 1, 0),
	BackgroundTransparency = 1,
	Text = "Pronto",
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = statusBar,
})

local progressTrack = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(260, 10),
	BackgroundColor3 = Colors.DarkGray,
	BackgroundTransparency = 0.35,
	Parent = statusBar,
})
round(progressTrack, 999)

local progressFill = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = State.Settings.mainColor,
	Parent = progressTrack,
})
round(progressFill, 999)
registerAccentBG(progressFill)

local resizeHandle = create("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -8, 1, -6),
	Size = UDim2.fromOffset(22, 22),
	BackgroundTransparency = 1,
	Text = "◢",
	TextColor3 = State.Settings.mainColor,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Parent = main,
})
registerAccentText(resizeHandle)

--//====================================================
--// UX
--//====================================================

local function notify(titleText, bodyText, kind)
	local barColor = State.Settings.mainColor
	if kind == "success" then
		barColor = Colors.Green
	elseif kind == "warning" then
		barColor = Colors.Yellow
	elseif kind == "error" then
		barColor = Colors.Red
	end

	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 0.08,
		ClipsDescendants = true,
		Parent = notifications,
	})
	registerBackground(card, "panel", 0.08)
	round(card, 16)
	stroke(card, barColor, 0.25, 1.2)

	local line = create("Frame", {
		Size = UDim2.fromOffset(4, 68),
		BackgroundColor3 = barColor,
		Parent = card,
	})
	round(line, 999)

	create("TextLabel", {
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.new(1, -28, 0, 18),
		BackgroundTransparency = 1,
		Text = titleText,
		TextColor3 = Colors.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	create("TextLabel", {
		Position = UDim2.fromOffset(16, 30),
		Size = UDim2.new(1, -28, 0, 28),
		BackgroundTransparency = 1,
		Text = bodyText,
		TextColor3 = Color3.fromRGB(215, 225, 255),
		TextWrapped = true,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	tween(card, {Size = UDim2.new(1, 0, 0, 68)}, 0.24)
	task.delay(4.5, function()
		if card and card.Parent then
			tween(card, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.22)
			task.wait(0.25)
			card:Destroy()
		end
	end)
end

local function attachTooltip(guiObject, text)
	if not text or text == "" then return end

	guiObject.MouseEnter:Connect(function()
		tooltip.Text = text
		tooltip.Visible = true
	end)

	guiObject.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)
end

UserInputService.InputChanged:Connect(function(input)
	if tooltip.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
		tooltip.Position = UDim2.fromOffset(input.Position.X + 18, input.Position.Y + 18)
	end
end)

local function addHover(button)
	local scale = create("UIScale", {Scale = 1, Parent = button})

	button.MouseEnter:Connect(function()
		tween(scale, {Scale = 1.02}, 0.14)
	end)

	button.MouseLeave:Connect(function()
		tween(scale, {Scale = 1}, 0.14)
	end)
end

local function setProgress(alpha, text)
	alpha = clamp(alpha, 0, 1)
	statusText.Text = text or "Pronto"
	tween(progressFill, {Size = UDim2.new(alpha, 0, 1, 0)}, 0.22)
end

local function updateAutomationProgress()
	local total, active = 0, 0
	for key in pairs(AutomationKeys) do
		total += 1
		if State.Toggles[key] then
			active += 1
		end
	end

	local percent = total > 0 and (active / total) or 0
	local label = ("Automações ativas: %d/%d"):format(active, total)
	if active == 0 then
		label = "Nenhuma automação ativa"
	end
	setProgress(percent, label)
end

--//====================================================
--// HOOKS SEGUROS / PLACEHOLDERS
--//====================================================

local function hookAction(actionKey, itemLabel)
	notify("Hook pronto", itemLabel .. " acionado. Conecte aqui a lógica autorizada do seu jogo.", "info")
end

local function hookToggle(toggleKey, itemLabel, enabled)
	local text = enabled and "ativado" or "desativado"
	notify("Toggle alterado", itemLabel .. " " .. text .. ".", enabled and "success" or "warning")
end

--//====================================================
--// CONTROLES
--//====================================================

local function makeCard(parent, height, auto)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, height or 72),
		AutomaticSize = auto and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BackgroundTransparency = 0.08,
		Parent = parent,
	})
	registerBackground(card, "card", 0.08)
	round(card, 16)
	stroke(card, Colors.MediumBlue, 0.58, 1)
	return card
end

local function createSection(parent, titleText)
	local section = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		Parent = section
	})

	local headerBtn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 0.08,
		Text = "",
		AutoButtonColor = false,
		Parent = section,
	})
	registerBackground(headerBtn, "pill", 0.08)
	round(headerBtn, 14)
	stroke(headerBtn, Colors.MediumBlue, 0.55, 1)
	addHover(headerBtn)

	local titleLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -42, 1, 0),
		BackgroundTransparency = 1,
		Text = titleText,
		TextColor3 = Colors.White,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = headerBtn,
	})

	local chevron = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "▾",
		TextColor3 = State.Settings.mainColor,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		Parent = headerBtn,
	})
	registerAccentText(chevron)

	local bodyFrame = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = section,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		Parent = bodyFrame
	})

	local collapsed = false
	headerBtn.MouseButton1Click:Connect(function()
		playClick()
		collapsed = not collapsed
		bodyFrame.Visible = not collapsed
		chevron.Text = collapsed and "▸" or "▾"
	end)

	return {
		frame = section,
		body = bodyFrame,
		items = {},
	}
end

local function createToggle(parent, item)
	local card = makeCard(parent, 72, false)
	card:SetAttribute("SearchText", ((item.label or "") .. " " .. (item.desc or "")):lower())

	local titleLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -110, 0, 20),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Colors.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local descLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -110, 0, 24),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = Color3.fromRGB(205, 220, 255),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})
	registerDescription(descLabel)
	attachTooltip(card, item.desc)
	attachTooltip(descLabel, item.desc)

	local toggleBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(56, 30),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = card,
	})
	addHover(toggleBtn)

	local track = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(80, 88, 110),
		BackgroundTransparency = 0.15,
		Parent = toggleBtn,
	})
	round(track, 999)
	stroke(track, Colors.MediumBlue, 0.45, 1)

	local knob = create("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = Colors.White,
		Parent = track,
	})
	round(knob, 999)

	local state = item.default or false

	local function render()
		if state then
			tween(track, {BackgroundColor3 = State.Settings.mainColor, BackgroundTransparency = 0.02}, 0.18)
			tween(knob, {Position = UDim2.new(1, -27, 0, 3)}, 0.18)
		else
			tween(track, {BackgroundColor3 = Color3.fromRGB(80, 88, 110), BackgroundTransparency = 0.15}, 0.18)
			tween(knob, {Position = UDim2.fromOffset(3, 3)}, 0.18)
		end
	end

	ToggleRenderers[item.key] = render

	local function setValue(newValue, silent)
		state = newValue
		State.Toggles[item.key] = state
		render()
		if not silent then
			if item.automation then
				updateAutomationProgress()
			end
			if item.key == "compactMode" then
				State.Settings.compact = state
				applyVisuals()
				notify("Modo compacto", state and "Ativado." or "Desativado.", "info")
			elseif item.key == "animations" then
				State.Settings.animations = state
				notify("Animações", state and "Ativadas." or "Desativadas.", "info")
			else
				hookToggle(item.key, item.label, state)
			end
		end
	end

	ToggleBindings[item.key] = setValue

	toggleBtn.MouseButton1Click:Connect(function()
		playClick()
		setValue(not state, false)
	end)

	setValue(state, true)
	return card
end

local function createButton(parent, item)
	local card = makeCard(parent, 72, false)
	card:SetAttribute("SearchText", ((item.label or "") .. " " .. (item.desc or "")):lower())

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -170, 0, 20),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Colors.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local descLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -170, 0, 24),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = Color3.fromRGB(205, 220, 255),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})
	registerDescription(descLabel)
	attachTooltip(card, item.desc)

	local actionBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(136, 38),
		BackgroundColor3 = State.Settings.mainColor,
		Text = item.buttonText or "Executar",
		TextColor3 = Colors.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = card,
	})
	registerAccentBG(actionBtn)
	round(actionBtn, 12)
	local st = stroke(actionBtn, State.Settings.mainColor, 0.1, 1)
	registerAccentStroke(st)
	addHover(actionBtn)

	actionBtn.MouseButton1Click:Connect(function()
		playClick()

		if item.action == "stopAllAutomations" then
			for key in pairs(AutomationKeys) do
				if ToggleBindings[key] then
					ToggleBindings[key](false, true)
				end
			end
			updateAutomationProgress()
			notify("Automações", "Todas as automações foram desativadas.", "warning")

		elseif item.action == "cycleTheme" then
			local order = {"Neon Blue", "Royal Blue", "Ice Tech"}
			local currentIndex = table.find(order, State.Settings.theme) or 1
			local nextTheme = order[(currentIndex % #order) + 1]
			State.Settings.theme = nextTheme
			applyVisuals()
			notify("Tema alterado", "Tema atual: " .. nextTheme, "success")

		elseif item.action == "cycleAccent" then
			local idx = table.find(AccentPalette, State.Settings.mainColor) or 1
			State.Settings.mainColor = AccentPalette[(idx % #AccentPalette) + 1]
			applyVisuals()
			notify("Cor principal", "A cor principal foi atualizada.", "success")

		elseif item.action == "restoreDefaults" then
			State.Settings.theme = Defaults.theme
			State.Settings.mainColor = Defaults.mainColor
			State.Settings.transparency = Defaults.transparency
			State.Settings.scale = Defaults.scale
			State.Settings.compact = Defaults.compact
			State.Settings.animations = Defaults.animations
			userScale.Scale = State.Settings.scale

			if ToggleBindings["compactMode"] then ToggleBindings["compactMode"](false, true) end
			if ToggleBindings["animations"] then ToggleBindings["animations"](true, true) end

			applyVisuals()
			notify("Configurações", "Padrões restaurados com sucesso.", "success")

		elseif item.action == "saveSettings" then
			notify("Salvar configurações", "Conecte este botão ao seu sistema de persistência/DataStore.", "info")

		elseif item.action == "copyJobId" then
			notify("Job ID", game.JobId, "info")

		else
			hookAction(item.action, item.label)
		end
	end)

	return card
end

local function createStat(parent, item)
	local card = makeCard(parent, 60, false)
	card:SetAttribute("SearchText", ((item.label or "") .. " " .. (item.desc or "")):lower())

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -184, 1, 0),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Colors.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local valuePill = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(160, 34),
		BackgroundTransparency = 0.08,
		Parent = card,
	})
	registerBackground(valuePill, "pill", 0.08)
	round(valuePill, 12)
	local pStroke = stroke(valuePill, State.Settings.mainColor, 0.3, 1)
	registerAccentStroke(pStroke)

	local valueLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "--",
		TextColor3 = Colors.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Parent = valuePill,
	})

	bindStat(item.statKey, valueLabel, item.formatter)
	attachTooltip(card, item.desc)
	return card
end

local function createTextBlock(parent, item)
	local card = makeCard(parent, nil, true)
	card:SetAttribute("SearchText", ((item.label or "") .. " " .. (item.desc or "")):lower())
	padding(card, 14)

	local titleLabel = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Colors.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local bodyLabel = create("TextLabel", {
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 56),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(215, 225, 255),
		TextWrapped = true,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	bindText(item.statKey, bodyLabel)
	attachTooltip(card, item.desc)
	return card
end

local function createSlider(parent, item)
	local card = makeCard(parent, 92, false)
	card:SetAttribute("SearchText", ((item.label or "") .. " " .. (item.desc or "")):lower())

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -140, 0, 18),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Colors.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local descLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 30),
		Size = UDim2.new(1, -140, 0, 18),
		BackgroundTransparency = 1,
		Text = item.desc or "",
		TextColor3 = Color3.fromRGB(205, 220, 255),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	registerDescription(descLabel)

	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 10, 0),
		Size = UDim2.fromOffset(80, 18),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = State.Settings.mainColor,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})
	registerAccentText(valueLabel)

	local bar = create("Frame", {
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(1, -28, 0, 10),
		BackgroundColor3 = Colors.DarkGray,
		BackgroundTransparency = 0.35,
		Parent = card,
	})
	round(bar, 999)

	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = State.Settings.mainColor,
		Parent = bar,
	})
	registerAccentBG(fill)
	round(fill, 999)

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Colors.White,
		Parent = bar,
	})
	round(knob, 999)

	local dragging = false
	local min, max, step = item.min or 0, item.max or 1, item.step or 0.01
	local current = item.default or min

	local function display(v)
		if item.formatter then
			return item.formatter(v)
		end
		return tostring(v)
	end

	local function setValue(v, silent)
		v = clamp(v, min, max)
		v = math.round(v / step) * step

		if step >= 1 then
			v = math.floor(v)
		else
			v = tonumber(string.format("%.2f", v))
		end

		current = v
		local alpha = (v - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = display(v)

		if not silent then
			if item.key == "guiScale" then
				State.Settings.scale = v
				userScale.Scale = v
			elseif item.key == "uiTransparency" then
				State.Settings.transparency = v
				applyVisuals()
			end
		end
	end

	local function updateFromMouse(x)
		local rel = clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		setValue(min + (max - min) * rel, false)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFromMouse(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromMouse(input.Position.X)
		end
	end)

	setValue(current, true)
	attachTooltip(card, item.desc)
	return card
end

local function createGraph(parent, item)
	local card = makeCard(parent, 190, false)
	card:SetAttribute("SearchText", ((item.label or "") .. " " .. (item.desc or "")):lower())

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 20),
		BackgroundTransparency = 1,
		Text = item.label,
		TextColor3 = Colors.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local plot = create("Frame", {
		Position = UDim2.fromOffset(14, 42),
		Size = UDim2.new(1, -28, 1, -56),
		BackgroundTransparency = 0.12,
		ClipsDescendants = true,
		Parent = card,
	})
	registerBackground(plot, "pill", 0.12)
	round(plot, 12)
	stroke(plot, Colors.MediumBlue, 0.62, 1)

	for i = 1, 4 do
		create("Frame", {
			Position = UDim2.new(0, 0, i / 5, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Parent = plot,
		})
	end

	for i = 1, 24 do
		local bar = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, (i - 1) * 16, 1, -6),
			Size = UDim2.new(0, 12, 0.06, 0),
			BackgroundColor3 = State.Settings.mainColor,
			BorderSizePixel = 0,
			Parent = plot,
		})
		registerAccentBG(bar)
		round(bar, 999)
		table.insert(GraphBars, bar)
	end

	updateGraph()
	attachTooltip(card, item.desc)
	return card
end

--//====================================================
--// CONFIG DAS TABS
--//====================================================

local TabDefinitions = {
	{
		name = "Farming",
		icon = "FA",
		sections = {
			{
				title = "Automações",
				items = {
					{type = "toggle", key = "autoDrive", label = "Auto Drive", desc = "Segue uma rota automaticamente.", automation = true},
					{type = "toggle", key = "autoRaces", label = "Auto Complete Races", desc = "Completa corridas automaticamente.", automation = true},
					{type = "toggle", key = "autoDeliveries", label = "Auto Complete Delivery Jobs", desc = "Conclui entregas automaticamente.", automation = true},
					{type = "toggle", key = "autoFarmMoney", label = "Auto Farm Money", desc = "Executa rotina automática de ganho.", automation = true},
					{type = "toggle", key = "autoAcceptJobs", label = "Auto Accept Jobs", desc = "Aceita trabalhos automaticamente.", automation = true},
					{type = "toggle", key = "autoClaimRewards", label = "Auto Claim Rewards", desc = "Resgata recompensas automaticamente.", automation = true},
				}
			},
			{
				title = "Métricas da Sessão",
				items = {
					{type = "stat", statKey = "profitPerMin", label = "Dinheiro ganho por minuto", desc = "Estimativa baseada na sessão.", formatter = function(v) return formatMoney(v) .. "/min" end},
					{type = "stat", statKey = "sessionMoney", label = "Dinheiro total ganho na sessão", desc = "Total acumulado na sessão atual.", formatter = formatMoney},
					{type = "stat", statKey = "deliveries", label = "Entregas concluídas", desc = "Contador de entregas concluídas.", formatter = formatNumber},
				}
			},
			{
				title = "Controles",
				items = {
					{type = "button", action = "stopAllAutomations", label = "Parar todas as automações", desc = "Desativa todos os processos automáticos da interface.", buttonText = "Parar"},
				}
			},
		}
	},
	{
		name = "Teleports",
		icon = "TP",
		sections = {
			{
				title = "Locais Importantes",
				items = {
					{type = "button", action = "tpDealership", label = "Teleportar para a concessionária", desc = "Acesso rápido à concessionária.", buttonText = "Ir"},
					{type = "button", action = "tpWorkshop", label = "Teleportar para oficina", desc = "Acesso rápido à oficina.", buttonText = "Ir"},
					{type = "button", action = "tpFuel", label = "Teleportar para postos de combustível", desc = "Acesso rápido aos postos.", buttonText = "Ir"},
					{type = "button", action = "tpEvents", label = "Teleportar para eventos", desc = "Vai para a área de eventos.", buttonText = "Ir"},
					{type = "button", action = "tpRaces", label = "Teleportar para corridas", desc = "Vai para as áreas de corrida.", buttonText = "Ir"},
					{type = "button", action = "tpPremium", label = "Teleportar para concessionárias premium", desc = "Vai para concessionárias premium.", buttonText = "Ir"},
				}
			},
			{
				title = "Navegação",
				items = {
					{type = "button", action = "openCitiesList", label = "Lista completa das cidades", desc = "Abre a lista de cidades disponíveis.", buttonText = "Abrir"},
					{type = "textblock", statKey = "serverInfo", label = "Favoritos", desc = "Use esta área para listar destinos favoritos e recentes."},
				}
			},
		}
	},
	{
		name = "Veículos",
		icon = "VH",
		sections = {
			{
				title = "Gerenciamento",
				items = {
					{type = "button", action = "spawnVehicle", label = "Spawnar veículo selecionado", desc = "Gera o veículo escolhido.", buttonText = "Spawnar"},
					{type = "button", action = "storeVehicle", label = "Guardar veículo", desc = "Guarda o veículo atual.", buttonText = "Guardar"},
					{type = "button", action = "repairVehicle", label = "Reparar veículo", desc = "Repara o veículo atual.", buttonText = "Reparar"},
					{type = "toggle", key = "autoRefuel", label = "Reabastecer automaticamente", desc = "Mantém o combustível do veículo em rotina automática."},
				}
			},
			{
				title = "Telemetria",
				items = {
					{type = "stat", statKey = "vehicleSpeed", label = "Velocidade em tempo real", desc = "Leitura da velocidade atual."},
					{type = "stat", statKey = "vehicleMileage", label = "Quilometragem", desc = "Quilometragem registrada do veículo."},
					{type = "stat", statKey = "vehiclePower", label = "Potência", desc = "Potência estimada do carro."},
					{type = "stat", statKey = "vehicleAcceleration", label = "Aceleração", desc = "Aceleração estimada."},
					{type = "stat", statKey = "vehicleTraction", label = "Tração", desc = "Informação de tração do veículo."},
				}
			},
			{
				title = "Informações Completas",
				items = {
					{type = "textblock", statKey = "carInfo", label = "Informações completas do carro", desc = "Mostra detalhes adicionais do veículo atual."},
				}
			},
		}
	},
	{
		name = "Corridas",
		icon = "CR",
		sections = {
			{
				title = "Automação de Corridas",
				items = {
					{type = "toggle", key = "autoJoinRaces", label = "Entrar automaticamente em corridas", desc = "Fica pronto para ingressar automaticamente."},
					{type = "toggle", key = "autoReady", label = "Auto Ready", desc = "Marca pronto automaticamente quando disponível."},
				}
			},
			{
				title = "Tempo e Posição",
				items = {
					{type = "stat", statKey = "raceTime", label = "Tempo da corrida", desc = "Tempo atual da corrida."},
					{type = "stat", statKey = "racePosition", label = "Posição atual", desc = "Posição atual na corrida."},
					{type = "stat", statKey = "bestRaceTime", label = "Melhor tempo registrado", desc = "Melhor tempo salvo na sessão."},
				}
			},
			{
				title = "Histórico e Resultados",
				items = {
					{type = "textblock", statKey = "raceHistory", label = "Histórico das últimas corridas", desc = "Registro das corridas mais recentes."},
					{type = "stat", statKey = "raceWins", label = "Estatísticas de vitórias", desc = "Vitórias acumuladas na sessão.", formatter = formatNumber},
					{type = "stat", statKey = "raceLosses", label = "Estatísticas de derrotas", desc = "Derrotas acumuladas na sessão.", formatter = formatNumber},
				}
			},
		}
	},
	{
		name = "Economia",
		icon = "EC",
		sections = {
			{
				title = "Resumo Financeiro",
				items = {
					{type = "stat", statKey = "moneyCurrent", label = "Dinheiro atual", desc = "Valor atual disponível.", formatter = formatMoney},
					{type = "stat", statKey = "sessionMoney", label = "Dinheiro ganho na sessão", desc = "Lucro acumulado na sessão atual.", formatter = formatMoney},
					{type = "stat", statKey = "profitPerMin", label = "Lucro por minuto", desc = "Estimativa por minuto.", formatter = function(v) return formatMoney(v) .. "/min" end},
					{type = "stat", statKey = "deliveries", label = "Total de entregas", desc = "Entregas concluídas.", formatter = formatNumber},
					{type = "stat", statKey = "raceWins", label = "Total de corridas vencidas", desc = "Corridas vencidas na sessão.", formatter = formatNumber},
					{type = "stat", statKey = "kmDriven", label = "Total de quilômetros dirigidos", desc = "Distância total percorrida.", formatter = function(v) return formatNumber(v) .. " km" end},
					{type = "stat", statKey = "sessionTime", label = "Tempo de sessão", desc = "Duração total da sessão atual."},
				}
			},
			{
				title = "Análise",
				items = {
					{type = "graph", label = "Evolução financeira em gráfico", desc = "Visualização histórica simplificada do desempenho financeiro."},
				}
			},
		}
	},
	{
		name = "Visual",
		icon = "VS",
		sections = {
			{
				title = "Personalização",
				items = {
					{type = "button", action = "cycleTheme", label = "Alterar tema", desc = "Alterna entre presets visuais disponíveis.", buttonText = "Alterar"},
					{type = "slider", key = "uiTransparency", label = "Ajustar transparência", desc = "Controla a transparência global da interface.", min = 0.08, max = 0.45, step = 0.01, default = Defaults.transparency, formatter = function(v) return string.format("%.2f", v) end},
					{type = "slider", key = "guiScale", label = "Ajustar escala da GUI", desc = "Aumenta ou reduz a escala geral da interface.", min = 0.8, max = 1.25, step = 0.01, default = Defaults.scale, formatter = function(v) return string.format("%.2fx", v) end},
					{type = "toggle", key = "compactMode", label = "Ativar modo compacto", desc = "Oculta descrições para uma aparência mais enxuta."},
					{type = "button", action = "cycleAccent", label = "Alterar cor principal", desc = "Alterna entre tons de azul para destaque principal.", buttonText = "Alterar"},
					{type = "toggle", key = "animations", label = "Ativar animações", desc = "Liga ou desliga as animações da interface.", default = true},
				}
			},
			{
				title = "Configurações",
				items = {
					{type = "button", action = "restoreDefaults", label = "Restaurar configurações padrão", desc = "Restaura todos os parâmetros visuais ao padrão.", buttonText = "Restaurar"},
					{type = "button", action = "saveSettings", label = "Salvar configurações", desc = "Integre com seu sistema de persistência para salvar preferências.", buttonText = "Salvar"},
				}
			},
		}
	},
	{
		name = "Utilidades",
		icon = "UT",
		sections = {
			{
				title = "Sessão",
				items = {
					{type = "toggle", key = "antiAfk", label = "Anti AFK", desc = "Placeholder visual para rotina anti-idle autorizada."},
					{type = "toggle", key = "autoRejoin", label = "Rejoin automático", desc = "Placeholder visual para reentrada automática autorizada."},
					{type = "button", action = "copyJobId", label = "Copiar Job ID", desc = "Mostra o Job ID atual da sessão.", buttonText = "Copiar"},
				}
			},
			{
				title = "Servidor",
				items = {
					{type = "textblock", statKey = "serverInfo", label = "Mostrar informações do servidor", desc = "Informações técnicas da sessão atual."},
					{type = "stat", statKey = "playersOnline", label = "Mostrar quantidade de jogadores", desc = "Quantidade de jogadores conectados.", formatter = formatNumber},
					{type = "stat", statKey = "ping", label = "Mostrar ping", desc = "Ping atual do cliente."},
					{type = "stat", statKey = "fps", label = "Mostrar FPS", desc = "FPS aproximado do cliente.", formatter = function(v) return tostring(v) end},
					{type = "stat", statKey = "serverTime", label = "Mostrar horário do servidor", desc = "Substitua por sincronização real via RemoteFunction, se desejar."},
				}
			},
		}
	},
}

for _, tab in ipairs(TabDefinitions) do
	for _, section in ipairs(tab.sections) do
		for _, item in ipairs(section.items) do
			if item.automation and item.key then
				AutomationKeys[item.key] = true
			end
		end
	end
end

--//====================================================
--// RENDER DAS TABS
--//====================================================

local currentTab = nil

local function selectTab(tabName)
	currentTab = tabName

	for name, info in pairs(Pages) do
		local active = (name == tabName)
		info.page.Visible = active
		if active then
			info.page.Position = UDim2.new(0.015, 0, 0, 0)
			tween(info.page, {Position = UDim2.new(0, 0, 0, 0)}, 0.18)
			tween(info.button, {BackgroundTransparency = 0.02}, 0.18)
			info.indicator.Visible = true
			tween(info.indicator, {Size = UDim2.new(0, 4, 0.68, 0)}, 0.18)
			info.iconFrame.BackgroundColor3 = State.Settings.mainColor
			info.iconFrame.BackgroundTransparency = 0.02
			info.title.TextColor3 = Colors.White
		else
			info.page.Visible = false
			tween(info.button, {BackgroundTransparency = 0.08}, 0.18)
			info.indicator.Visible = false
			info.iconFrame.BackgroundColor3 = ThemePresets[State.Settings.theme].pill
			info.iconFrame.BackgroundTransparency = 0.12
			info.title.TextColor3 = Color3.fromRGB(220, 230, 255)
		end
	end

	pageTitle.Text = tabName
	searchBox.Text = ""
end

local function applySearch()
	local query = (searchBox.Text or ""):lower()
	local pageInfo = Pages[currentTab]
	if not pageInfo then return end

	for _, sectionInfo in ipairs(pageInfo.sections) do
		local anyVisible = false
		for _, itemInfo in ipairs(sectionInfo.items) do
			local hay = itemInfo.row:GetAttribute("SearchText") or ""
			local visible = query == "" or string.find(hay, query, 1, true) ~= nil
			itemInfo.row.Visible = visible
			if visible then
				anyVisible = true
			end
		end
		sectionInfo.frame.Visible = anyVisible
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

for _, tab in ipairs(TabDefinitions) do
	local tabBtn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 0.08,
		Text = "",
		AutoButtonColor = false,
		Parent = tabsScroll,
	})
	registerBackground(tabBtn, "pill", 0.08)
	round(tabBtn, 14)
	stroke(tabBtn, Colors.MediumBlue, 0.58, 1)
	addHover(tabBtn)

	local indicator = create("Frame", {
		Visible = false,
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(0, 4, 0.68, 0),
		BackgroundColor3 = State.Settings.mainColor,
		Parent = tabBtn,
	})
	registerAccentBG(indicator)
	round(indicator, 999)

	local iconFrame = create("Frame", {
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 0.12,
		Parent = tabBtn,
	})
	registerBackground(iconFrame, "pill", 0.12)
	round(iconFrame, 10)
	stroke(iconFrame, Colors.MediumBlue, 0.5, 1)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = tab.icon,
		TextColor3 = Colors.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Parent = iconFrame,
	})

	local titleLabel = create("TextLabel", {
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.new(1, -62, 1, 0),
		BackgroundTransparency = 1,
		Text = tab.name,
		TextColor3 = Color3.fromRGB(220, 230, 255),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tabBtn,
	})

	local page = create("ScrollingFrame", {
		Name = tab.name .. "Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = State.Settings.mainColor,
		Visible = false,
		Parent = pagesHolder,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		Parent = page,
	})
	padding(page, 2)

	local pageSections = {}

	for _, sectionDef in ipairs(tab.sections) do
		local section = createSection(page, sectionDef.title)
		table.insert(pageSections, section)

		for _, item in ipairs(sectionDef.items) do
			local row
			if item.type == "toggle" then
				row = createToggle(section.body, item)
			elseif item.type == "button" then
				row = createButton(section.body, item)
			elseif item.type == "stat" then
				row = createStat(section.body, item)
			elseif item.type == "textblock" then
				row = createTextBlock(section.body, item)
			elseif item.type == "slider" then
				row = createSlider(section.body, item)
			elseif item.type == "graph" then
				row = createGraph(section.body, item)
			end

			if row then
				table.insert(section.items, {row = row})
			end
		end
	end

	Pages[tab.name] = {
		button = tabBtn,
		indicator = indicator,
		iconFrame = iconFrame,
		title = titleLabel,
		page = page,
		sections = pageSections,
	}

	tabBtn.MouseButton1Click:Connect(function()
		playClick()
		selectTab(tab.name)
	end)
end

selectTab("Farming")
applyVisuals()
updateAutomationProgress()

--//====================================================
--// DRAG / RESIZE / MINIMIZE / CLOSE
--//====================================================

local expandedSize = windowRoot.Size
local minimized = false

local dragging = false
local dragStart, startPos

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = windowRoot.Position
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
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
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement and not minimized then
		local delta = UserInputService:GetMouseLocation() - resizeStart
		local newW = clamp(sizeStart.X + delta.X, 820, 1500)
		local newH = clamp(sizeStart.Y + delta.Y, 520, 900)
		windowRoot.Size = UDim2.fromOffset(newW, newH)
		expandedSize = windowRoot.Size
	end
end)

minimizeBtn.MouseButton1Click:Connect(function()
	playClick()
	minimized = not minimized

	if minimized then
		expandedSize = windowRoot.Size
		tween(windowRoot, {Size = UDim2.fromOffset(windowRoot.AbsoluteSize.X, 74)}, 0.22)
		task.delay(0.18, function()
			if minimized then
				body.Visible = false
				resizeHandle.Visible = false
			end
		end)
	else
		body.Visible = true
		resizeHandle.Visible = true
		tween(windowRoot, {Size = expandedSize}, 0.22)
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	playClick()
	tween(openScale, {Scale = 0.94}, 0.18)
	tween(blur, {Size = 0}, 0.2)
	task.wait(0.18)
	screenGui:Destroy()
	if blur and blur.Parent then
		blur:Destroy()
	end
end)

addHover(minimizeBtn)
addHover(closeBtn)

--//====================================================
--// LOOPS / INFO DINÂMICA
--//====================================================

local frames = 0
local lastFpsTick = tick()

RunService.RenderStepped:Connect(function()
	frames += 1
	local now = tick()
	if now - lastFpsTick >= 1 then
		local fps = frames
		frames = 0
		lastFpsTick = now
		setStat("fps", fps)
		fpsPill.Text = "FPS: " .. tostring(fps)
	end
end)

task.spawn(function()
	while screenGui.Parent do
		local elapsed = os.clock() - sessionStart
		local duration = formatTime(elapsed)
		setStat("sessionTime", duration)
		sessionPill.Text = duration

		local perMin = math.floor((State.Stats.sessionMoney or 0) / math.max(elapsed / 60, 1))
		setStat("profitPerMin", perMin)

		setStat("playersOnline", #Players:GetPlayers())
		setStat("serverTime", os.date("%H:%M:%S")) -- troque por tempo real do servidor se quiser

		local pingText = "-- ms"
		pcall(function()
			pingText = StatsService.Network.ServerStatsItem["Data Ping"]:GetValueString()
		end)
		setStat("ping", pingText)

		task.wait(1)
	end
end)

Players.PlayerAdded:Connect(function()
	setStat("playersOnline", #Players:GetPlayers())
end)

Players.PlayerRemoving:Connect(function()
	setStat("playersOnline", #Players:GetPlayers())
end)

task.spawn(function()
	while screenGui.Parent do
		table.insert(moneyHistory, State.Stats.sessionMoney or 0)
		if #moneyHistory > 24 then
			table.remove(moneyHistory, 1)
		end
		updateGraph()
		task.wait(5)
	end
end)

--//====================================================
--// ABERTURA
--//====================================================

applyVisuals()
tween(blur, {Size = 18}, 0.35)
tween(loadFill, {Size = UDim2.new(1, 0, 1, 0)}, 1.25)
task.wait(1.15)

windowRoot.Visible = true
tween(openScale, {Scale = 1}, 0.28)
notify("Redarelhos Hub", "Interface carregada com sucesso.", "success")

task.wait(0.15)
loading:Destroy()
