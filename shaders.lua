-- ═══════════════════════════════════════════════════════════
--  🎬 NOVA CINEMATIC PRO v2.0
--  Ultimate Shader Suite | Film Grain | Vignette | HSV Picker
-- ═══════════════════════════════════════════════════════════

local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local plr = Players.LocalPlayer

-- ═══ CLEANUP ═══
if CoreGui:FindFirstChild("NovaCinematicPro") then
    CoreGui.NovaCinematicPro:Destroy()
end
for _, n in ipairs({"NovaBlur","NovaBloom","NovaColor","NovaDOF","NovaSunRays","NovaAtmosphere"}) do
    local ex = Lighting:FindFirstChild(n)
    if ex then ex:Destroy() end
end

-- ═══════════════════════════════════════════════════════════
--  LIGHTING EFFECTS
-- ═══════════════════════════════════════════════════════════

local Blur = Instance.new("BlurEffect")
Blur.Name = "NovaBlur"; Blur.Size = 0; Blur.Parent = Lighting

local Bloom = Instance.new("BloomEffect")
Bloom.Name = "NovaBloom"; Bloom.Intensity = 0.4
Bloom.Size = 24; Bloom.Threshold = 0.95; Bloom.Parent = Lighting

local Color = Instance.new("ColorCorrectionEffect")
Color.Name = "NovaColor"; Color.Parent = Lighting

local DOF = Instance.new("DepthOfFieldEffect")
DOF.Name = "NovaDOF"; DOF.FocusDistance = 50
DOF.InFocusRadius = 50; DOF.Parent = Lighting

local SunRays = Instance.new("SunRaysEffect")
SunRays.Name = "NovaSunRays"; SunRays.Intensity = 0.1
SunRays.Spread = 0.5; SunRays.Parent = Lighting

local Atmosphere = Instance.new("Atmosphere")
Atmosphere.Name = "NovaAtmosphere"; Atmosphere.Density = 0.3
Atmosphere.Offset = 0.25; Atmosphere.Color = Color3.fromRGB(199, 170, 107)
Atmosphere.Decay = Color3.fromRGB(106, 112, 125); Atmosphere.Parent = Lighting

-- ═══ STATE ═══
local motionBlurEnabled = false
local motionBlurStrength = 0.3
local lastCam = workspace.CurrentCamera.CFrame
local customPresets = {}

-- Motion blur loop
RS.RenderStepped:Connect(function(dt)
    if not motionBlurEnabled then Blur.Size = 0; return end
    local cam = workspace.CurrentCamera
    local cur = cam.CFrame
    local posD = (cur.Position - lastCam.Position).Magnitude
    local rotD = (cur.LookVector - lastCam.LookVector).Magnitude * 100
    local total = (posD + rotD) * motionBlurStrength
    local target = math.clamp(total, 0, 24)
    Blur.Size = Blur.Size + (target - Blur.Size) * 0.4
    lastCam = cur
end)

-- ═══ COLORS ═══
local C = {
    bg         = Color3.fromRGB(8, 8, 14),
    bg2        = Color3.fromRGB(14, 14, 22),
    card       = Color3.fromRGB(18, 18, 28),
    cardLight  = Color3.fromRGB(26, 26, 40),
    cardHover  = Color3.fromRGB(34, 34, 52),
    accent     = Color3.fromRGB(255, 90, 90),
    accent2    = Color3.fromRGB(255, 150, 70),
    accent3    = Color3.fromRGB(255, 60, 130),
    purple     = Color3.fromRGB(160, 90, 255),
    cyan       = Color3.fromRGB(80, 220, 255),
    green      = Color3.fromRGB(80, 230, 140),
    yellow     = Color3.fromRGB(255, 220, 90),
    red        = Color3.fromRGB(255, 70, 90),
    text       = Color3.fromRGB(240, 240, 250),
    subtext    = Color3.fromRGB(180, 180, 200),
    muted      = Color3.fromRGB(110, 110, 140),
    border     = Color3.fromRGB(45, 45, 65),
    toggleOff  = Color3.fromRGB(45, 45, 65),
    toggleOn   = Color3.fromRGB(255, 90, 90),
}

-- ═══════════════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════════════

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p; return c end
local function stroke(p, col, t, tr) local s = Instance.new("UIStroke"); s.Color = col or C.border; s.Thickness = t or 1; s.Transparency = tr or 0.5; s.Parent = p; return s end
local function grad(p, seq, rot) local g = Instance.new("UIGradient"); g.Color = seq; g.Rotation = rot or 90; g.Parent = p; return g end
local function tween(o, p, d, s, dir) return TS:Create(o, TweenInfo.new(d or 0.25, s or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), p):Play() end

-- ═══════════════════════════════════════════════════════════
--  MAIN GUI
-- ═══════════════════════════════════════════════════════════

local Gui = Instance.new("ScreenGui")
Gui.Name = "NovaCinematicPro"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

-- ═══════════════════════════════════════════════════════════
--  OVERLAY EFFECTS (Film Grain, Vignette, Chromatic, Scanlines)
-- ═══════════════════════════════════════════════════════════

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "NovaOverlays"
OverlayGui.ResetOnSpawn = false
OverlayGui.IgnoreGuiInset = true
OverlayGui.DisplayOrder = -1
OverlayGui.Parent = CoreGui

-- Vignette
local Vignette = Instance.new("ImageLabel")
Vignette.Size = UDim2.new(1, 0, 1, 0)
Vignette.BackgroundTransparency = 1
Vignette.Image = "rbxassetid://11295263412"
Vignette.ImageColor3 = Color3.new(0, 0, 0)
Vignette.ImageTransparency = 1
Vignette.ScaleType = Enum.ScaleType.Stretch
Vignette.Parent = OverlayGui

-- Film Grain
local FilmGrain = Instance.new("ImageLabel")
FilmGrain.Size = UDim2.new(1, 0, 1, 0)
FilmGrain.BackgroundTransparency = 1
FilmGrain.Image = "rbxassetid://7027187124"
FilmGrain.ImageTransparency = 1
FilmGrain.ScaleType = Enum.ScaleType.Tile
FilmGrain.TileSize = UDim2.new(0, 256, 0, 256)
FilmGrain.Parent = OverlayGui

-- Scanlines
local Scanlines = Instance.new("Frame")
Scanlines.Size = UDim2.new(1, 0, 1, 0)
Scanlines.BackgroundTransparency = 1
Scanlines.Parent = OverlayGui
local scanGrad = Instance.new("UIGradient")
scanGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
    ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
}
scanGrad.Transparency = NumberSequence.new(1)
scanGrad.Rotation = 90
scanGrad.Parent = Scanlines

-- Chromatic Aberration (2 offset colored images)
local ChromaRed = Instance.new("Frame")
ChromaRed.Size = UDim2.new(1, 0, 1, 0)
ChromaRed.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ChromaRed.BackgroundTransparency = 1
ChromaRed.BorderSizePixel = 0
ChromaRed.Parent = OverlayGui

local ChromaBlue = Instance.new("Frame")
ChromaBlue.Size = UDim2.new(1, 0, 1, 0)
ChromaBlue.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
ChromaBlue.BackgroundTransparency = 1
ChromaBlue.BorderSizePixel = 0
ChromaBlue.Parent = OverlayGui

-- Letterbox (cinematic black bars)
local LetterTop = Instance.new("Frame")
LetterTop.Size = UDim2.new(1, 0, 0, 0)
LetterTop.Position = UDim2.new(0, 0, 0, 0)
LetterTop.BackgroundColor3 = Color3.new(0,0,0)
LetterTop.BorderSizePixel = 0
LetterTop.Parent = OverlayGui

local LetterBot = Instance.new("Frame")
LetterBot.Size = UDim2.new(1, 0, 0, 0)
LetterBot.Position = UDim2.new(0, 0, 1, 0)
LetterBot.AnchorPoint = Vector2.new(0, 1)
LetterBot.BackgroundColor3 = Color3.new(0,0,0)
LetterBot.BorderSizePixel = 0
LetterBot.Parent = OverlayGui

-- Grain animation
task.spawn(function()
    while OverlayGui.Parent do
        FilmGrain.Position = UDim2.new(0, math.random(-50, 50), 0, math.random(-50, 50))
        task.wait(0.05)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  WINDOW HOLDER
-- ═══════════════════════════════════════════════════════════

local Holder = Instance.new("Frame")
Holder.Size = UDim2.new(0, 500, 0, 600)
Holder.Position = UDim2.new(0.5, -250, 0.5, -300)
Holder.BackgroundTransparency = 1
Holder.Parent = Gui

-- Ambient glow
local glow1 = Instance.new("ImageLabel")
glow1.Size = UDim2.new(1.4, 0, 1.4, 0)
glow1.Position = UDim2.new(-0.2, 0, -0.2, 0)
glow1.BackgroundTransparency = 1
glow1.Image = "rbxassetid://5028857084"
glow1.ImageColor3 = C.accent
glow1.ImageTransparency = 0.75
glow1.Parent = Holder

local glow2 = Instance.new("ImageLabel")
glow2.Size = UDim2.new(1.35, 0, 1.35, 0)
glow2.Position = UDim2.new(-0.175, 0, -0.175, 0)
glow2.BackgroundTransparency = 1
glow2.Image = "rbxassetid://5028857084"
glow2.ImageColor3 = C.purple
glow2.ImageTransparency = 0.85
glow2.Parent = Holder

-- Pulse glows
task.spawn(function()
    while Gui.Parent do
        tween(glow1, {ImageTransparency = 0.6}, 2, Enum.EasingStyle.Sine)
        tween(glow2, {ImageTransparency = 0.7}, 2.5, Enum.EasingStyle.Sine)
        task.wait(2.5)
        tween(glow1, {ImageTransparency = 0.85}, 2, Enum.EasingStyle.Sine)
        tween(glow2, {ImageTransparency = 0.9}, 2.5, Enum.EasingStyle.Sine)
        task.wait(2.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  MAIN FRAME
-- ═══════════════════════════════════════════════════════════

local Main = Instance.new("Frame")
Main.Size = UDim2.new(1, 0, 1, 0)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Parent = Holder
corner(Main, 16)
stroke(Main, C.accent, 1.5, 0.4)

grad(Main, ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 14, 20)),
    ColorSequenceKeypoint.new(0.5, C.bg),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 24))
}, 135)

-- ═══ TITLE BAR ═══
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 65)
titleBar.BackgroundColor3 = C.card
titleBar.BorderSizePixel = 0
titleBar.Parent = Main
corner(titleBar, 16)

local titleCover = Instance.new("Frame")
titleCover.Size = UDim2.new(1, 0, 0, 16)
titleCover.Position = UDim2.new(0, 0, 1, -16)
titleCover.BackgroundColor3 = C.card
titleCover.BorderSizePixel = 0
titleCover.Parent = titleBar

local titleLine = Instance.new("Frame")
titleLine.Size = UDim2.new(1, -20, 0, 2)
titleLine.Position = UDim2.new(0, 10, 1, -2)
titleLine.BackgroundColor3 = C.accent
titleLine.BorderSizePixel = 0
titleLine.Parent = titleBar
grad(titleLine, ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.purple),
    ColorSequenceKeypoint.new(0.33, C.accent3),
    ColorSequenceKeypoint.new(0.66, C.accent),
    ColorSequenceKeypoint.new(1, C.accent2)
}, 0)

-- Animate title line
task.spawn(function()
    while Gui.Parent do
        tween(titleLine, {Rotation = 180}, 5, Enum.EasingStyle.Linear)
        task.wait(5)
        tween(titleLine, {Rotation = 0}, 5, Enum.EasingStyle.Linear)
        task.wait(5)
    end
end)

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 40, 0, 40)
logo.Position = UDim2.new(0, 14, 0.5, -20)
logo.BackgroundColor3 = C.cardLight
logo.Text = "🎬"
logo.TextSize = 22
logo.Parent = titleBar
corner(logo, 10)
stroke(logo, C.accent, 1, 0.3)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 260, 0, 24)
titleText.Position = UDim2.new(0, 64, 0, 12)
titleText.BackgroundTransparency = 1
titleText.Text = "NOVA CINEMATIC"
titleText.TextColor3 = C.text
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

grad(titleText, ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.accent),
    ColorSequenceKeypoint.new(1, C.accent2)
}, 0)

local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(0, 260, 0, 14)
subText.Position = UDim2.new(0, 64, 0, 36)
subText.BackgroundTransparency = 1
subText.Text = "★ PRO EDITION v2.0"
subText.TextColor3 = C.subtext
subText.Font = Enum.Font.GothamSemibold
subText.TextSize = 10
subText.TextXAlignment = Enum.TextXAlignment.Left
subText.Parent = titleBar

-- FPS Counter
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 60, 0, 20)
fpsLabel.Position = UDim2.new(1, -180, 0.5, -10)
fpsLabel.BackgroundColor3 = C.cardLight
fpsLabel.Text = "60 FPS"
fpsLabel.TextColor3 = C.green
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 10
fpsLabel.Parent = titleBar
corner(fpsLabel, 6)

-- FPS calc
task.spawn(function()
    while Gui.Parent do
        local frames = 0
        local startTime = tick()
        local conn
        conn = RS.RenderStepped:Connect(function() frames = frames + 1 end)
        task.wait(1)
        conn:Disconnect()
        local fps = math.floor(frames / (tick() - startTime))
        fpsLabel.Text = fps .. " FPS"
        if fps >= 50 then fpsLabel.TextColor3 = C.green
        elseif fps >= 30 then fpsLabel.TextColor3 = C.yellow
        else fpsLabel.TextColor3 = C.red end
    end
end)

-- Close/Min
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -44, 0.5, -16)
closeBtn.BackgroundColor3 = C.red
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
corner(closeBtn, 8)

closeBtn.MouseButton1Click:Connect(function()
    tween(Holder, {Position = UDim2.new(0.5, -250, 1.5, 0)}, 0.4)
    task.wait(0.4)
    Gui:Destroy()
    OverlayGui:Destroy()
end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.Position = UDim2.new(1, -82, 0.5, -16)
minBtn.BackgroundColor3 = C.accent2
minBtn.Text = "─"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.AutoButtonColor = false
minBtn.Parent = titleBar
corner(minBtn, 8)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(Holder, {Size = UDim2.new(0, 500, 0, 70)}, 0.4, Enum.EasingStyle.Back)
    else
        tween(Holder, {Size = UDim2.new(0, 500, 0, 600)}, 0.4, Enum.EasingStyle.Back)
    end
end)

-- ═══ DRAG ═══
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Holder.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ═══ SIDEBAR NAVIGATION ═══
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -130)
sidebar.Position = UDim2.new(0, 12, 0, 75)
sidebar.BackgroundColor3 = C.card
sidebar.BorderSizePixel = 0
sidebar.Parent = Main
corner(sidebar, 12)
stroke(sidebar, C.border, 1, 0.5)

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 6)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sidebar
local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 10)
sidePad.PaddingBottom = UDim.new(0, 10)
sidePad.Parent = sidebar

local tabs, tabPages = {}, {}
local tabNames = {
    {name="Color", icon="🎨", id="Color"},
    {name="Bloom", icon="✨", id="Bloom"},
    {name="Blur", icon="💨", id="Blur"},
    {name="DOF", icon="🔍", id="DOF"},
    {name="World", icon="🌫", id="World"},
    {name="FX", icon="🎞", id="FX"},
    {name="Presets", icon="🎬", id="Presets"},
    {name="Save", icon="💾", id="Save"},
}

-- Content area
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -154, 1, -130)
content.Position = UDim2.new(0, 146, 0, 75)
content.BackgroundColor3 = C.card
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = Main
corner(content, 12)
stroke(content, C.border, 1, 0.5)

for _, info in ipairs(tabNames) do
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -4, 1, -4)
    page.Position = UDim2.new(0, 2, 0, 2)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.accent
    page.CanvasSize = UDim2.new(0, 0, 0, 800)
    page.Visible = false
    page.Parent = content
    tabPages[info.id] = page
end

local currentTab = nil
local function switchTab(id)
    for tid, p in pairs(tabPages) do p.Visible = false end
    if currentTab and tabs[currentTab] then
        tween(tabs[currentTab], {BackgroundColor3 = C.cardLight}, 0.2)
        tabs[currentTab].TextColor3 = C.subtext
    end
    tabPages[id].Visible = true
    tween(tabs[id], {BackgroundColor3 = C.accent}, 0.2)
    tabs[id].TextColor3 = C.bg
    currentTab = id
end

for _, info in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 38)
    b.BackgroundColor3 = C.cardLight
    b.Text = info.icon .. "  " .. info.name
    b.TextColor3 = C.subtext
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = sidebar
    corner(b, 8)
    
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.Parent = b
    
    b.MouseEnter:Connect(function()
        if currentTab ~= info.id then tween(b, {BackgroundColor3 = C.cardHover}, 0.15) end
    end)
    b.MouseLeave:Connect(function()
        if currentTab ~= info.id then tween(b, {BackgroundColor3 = C.cardLight}, 0.15) end
    end)
    b.MouseButton1Click:Connect(function() switchTab(info.id) end)
    tabs[info.id] = b
end

-- ═══ STATUS BAR ═══
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -24, 0, 30)
statusBar.Position = UDim2.new(0, 12, 1, -40)
statusBar.BackgroundColor3 = C.card
statusBar.BorderSizePixel = 0
statusBar.Parent = Main
corner(statusBar, 8)
stroke(statusBar, C.border, 1, 0.5)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 12, 0.5, -4)
statusDot.BackgroundColor3 = C.green
statusDot.Parent = statusBar
corner(statusDot, 4)
stroke(statusDot, C.green, 2, 0.4)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -30, 1, 0)
statusText.Position = UDim2.new(0, 28, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "🎬 Ready — Adjust shaders in real-time"
statusText.TextColor3 = C.text
statusText.Font = Enum.Font.GothamSemibold
statusText.TextSize = 11
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

local function setStatus(t, c)
    statusText.Text = t
    tween(statusDot, {BackgroundColor3 = c or C.green}, 0.2)
    local s = statusDot:FindFirstChildOfClass("UIStroke")
    if s then tween(s, {Color = c or C.green}, 0.2) end
end

-- Pulse
task.spawn(function()
    while Gui.Parent do
        tween(statusDot, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 11, 0.5, -5)}, 0.9, Enum.EasingStyle.Sine)
        task.wait(0.9)
        tween(statusDot, {Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 12, 0.5, -4)}, 0.9, Enum.EasingStyle.Sine)
        task.wait(0.9)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  UI COMPONENTS
-- ═══════════════════════════════════════════════════════════

local function sectionLabel(parent, text, yPos)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 0, 22)
    f.Position = UDim2.new(0, 10, 0, yPos)
    f.BackgroundTransparency = 1
    f.Parent = parent
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 3, 0, 12)
    line.Position = UDim2.new(0, 0, 0.5, -6)
    line.BackgroundColor3 = C.accent
    line.BorderSizePixel = 0
    line.Parent = f
    corner(line, 2)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.accent
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
end

local function createSlider(parent, text, yPos, min, max, default, decimals, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 58)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundColor3 = C.cardLight
    container.BorderSizePixel = 0
    container.Parent = parent
    corner(container, 8)
    stroke(container, C.border, 1, 0.5)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, -12, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.4, -12, 0, 20)
    valLbl.Position = UDim2.new(0.6, 0, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = string.format("%." .. (decimals or 2) .. "f", default)
    valLbl.TextColor3 = C.accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 5)
    track.Position = UDim2.new(0, 12, 0, 38)
    track.BackgroundColor3 = C.bg
    track.BorderSizePixel = 0
    track.Parent = container
    corner(track, 3)
    
    local fill = Instance.new("Frame")
    local pct = (default - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)
    grad(fill, ColorSequence.new(C.accent, C.accent2), 0)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = track
    corner(knob, 7)
    stroke(knob, C.accent, 2, 0.2)
    
    local sDrag = false
    local inputBtn = Instance.new("TextButton")
    inputBtn.Size = UDim2.new(1, 20, 0, 28)
    inputBtn.Position = UDim2.new(0, -10, 0.5, -14)
    inputBtn.BackgroundTransparency = 1
    inputBtn.Text = ""
    inputBtn.ZIndex = 6
    inputBtn.Parent = track
    
    local function update(x)
        local ap = track.AbsolutePosition.X
        local as = track.AbsoluteSize.X
        local r = math.clamp((x - ap) / as, 0, 1)
        local v = min + r * (max - min)
        if decimals == 0 then v = math.floor(v) end
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -7, 0.5, -7)
        valLbl.Text = string.format("%." .. (decimals or 2) .. "f", v)
        callback(v)
    end
    
    inputBtn.MouseButton1Down:Connect(function() sDrag = true end)
    UIS.InputChanged:Connect(function(input)
        if sDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sDrag = false
        end
    end)
end

local function createToggle(parent, icon, text, yPos, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 42)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundColor3 = C.cardLight
    container.BorderSizePixel = 0
    container.Parent = parent
    corner(container, 8)
    stroke(container, C.border, 1, 0.5)
    
    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 24, 0, 24)
    iconLbl.Position = UDim2.new(0, 10, 0.5, -12)
    iconLbl.BackgroundColor3 = C.card
    iconLbl.Text = icon
    iconLbl.TextSize = 12
    iconLbl.Parent = container
    corner(iconLbl, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, -12, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 22)
    pill.Position = UDim2.new(1, -50, 0.5, -11)
    pill.BackgroundColor3 = default and C.toggleOn or C.toggleOff
    pill.BorderSizePixel = 0
    pill.Parent = container
    corner(pill, 11)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    corner(knob, 8)
    
    local enabled = default
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = container
    clickBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        tween(pill, {BackgroundColor3 = enabled and C.toggleOn or C.toggleOff}, 0.3)
        tween(knob, {Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.3, Enum.EasingStyle.Back)
        callback(enabled)
    end)
end

local function createButton(parent, icon, text, yPos, col1, col2, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = col1
    btn.Text = icon .. "  " .. text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 8)
    stroke(btn, col2 or col1, 1, 0.4)
    grad(btn, ColorSequence.new(col1, col2 or col1), 90)
    
    btn.MouseEnter:Connect(function() tween(btn, {Size = UDim2.new(1, -16, 0, 40)}, 0.15) end)
    btn.MouseLeave:Connect(function() tween(btn, {Size = UDim2.new(1, -20, 0, 38)}, 0.15) end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ═══ VISUAL HSV COLOR PICKER ═══
local function createColorPicker(parent, text, yPos, defaultColor, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 180)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundColor3 = C.cardLight
    container.BorderSizePixel = 0
    container.Parent = parent
    corner(container, 8)
    stroke(container, C.border, 1, 0.5)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local currentColor = defaultColor
    local h, s, v = 0, 0, 1
    
    -- Saturation/Value square
    local svBox = Instance.new("ImageLabel")
    svBox.Size = UDim2.new(0, 120, 0, 120)
    svBox.Position = UDim2.new(0, 10, 0, 32)
    svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    svBox.Image = "rbxassetid://4155801252"
    svBox.Parent = container
    corner(svBox, 6)
    stroke(svBox, C.border, 1, 0.3)
    
    local svCursor = Instance.new("Frame")
    svCursor.Size = UDim2.new(0, 8, 0, 8)
    svCursor.BackgroundColor3 = Color3.new(1,1,1)
    svCursor.BorderSizePixel = 0
    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    svCursor.Position = UDim2.new(1, 0, 0, 0)
    svCursor.Parent = svBox
    corner(svCursor, 4)
    stroke(svCursor, Color3.new(0,0,0), 1, 0)
    
    -- Hue bar
    local hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(0, 20, 0, 120)
    hueBar.Position = UDim2.new(0, 140, 0, 32)
    hueBar.BorderSizePixel = 0
    hueBar.Parent = container
    corner(hueBar, 6)
    grad(hueBar, ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0))
    }, 90)
    
    local hueCursor = Instance.new("Frame")
    hueCursor.Size = UDim2.new(1, 4, 0, 3)
    hueCursor.Position = UDim2.new(0, -2, 0, 0)
    hueCursor.BackgroundColor3 = Color3.new(1,1,1)
    hueCursor.BorderSizePixel = 0
    hueCursor.Parent = hueBar
    stroke(hueCursor, Color3.new(0,0,0), 1, 0)
    
    -- Preview & RGB
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 80, 0, 40)
    preview.Position = UDim2.new(0, 175, 0, 32)
    preview.BackgroundColor3 = defaultColor
    preview.BorderSizePixel = 0
    preview.Parent = container
    corner(preview, 6)
    stroke(preview, C.accent, 1, 0.3)
    
    local rgbLbl = Instance.new("TextLabel")
    rgbLbl.Size = UDim2.new(0, 80, 0, 60)
    rgbLbl.Position = UDim2.new(0, 175, 0, 82)
    rgbLbl.BackgroundTransparency = 1
    rgbLbl.Text = string.format("R %d\nG %d\nB %d", math.floor(defaultColor.R*255), math.floor(defaultColor.G*255), math.floor(defaultColor.B*255))
    rgbLbl.TextColor3 = C.subtext
    rgbLbl.Font = Enum.Font.GothamSemibold
    rgbLbl.TextSize = 10
    rgbLbl.TextXAlignment = Enum.TextXAlignment.Left
    rgbLbl.TextYAlignment = Enum.TextYAlignment.Top
    rgbLbl.Parent = container
    
    local function updateColor()
        currentColor = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = currentColor
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        rgbLbl.Text = string.format("R %d\nG %d\nB %d", math.floor(currentColor.R*255), math.floor(currentColor.G*255), math.floor(currentColor.B*255))
        callback(currentColor)
    end
    
    local svDrag, hueDrag = false, false
    
    local svBtn = Instance.new("TextButton")
    svBtn.Size = UDim2.new(1,0,1,0); svBtn.BackgroundTransparency = 1; svBtn.Text = ""
    svBtn.Parent = svBox
    
    local hueBtn = Instance.new("TextButton")
    hueBtn.Size = UDim2.new(1,0,1,0); hueBtn.BackgroundTransparency = 1; hueBtn.Text = ""
    hueBtn.Parent = hueBar
    
    svBtn.MouseButton1Down:Connect(function() svDrag = true end)
    hueBtn.MouseButton1Down:Connect(function() hueDrag = true end)
    
    UIS.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if svDrag then
            local ap = svBox.AbsolutePosition; local asz = svBox.AbsoluteSize
            local rx = math.clamp((input.Position.X - ap.X) / asz.X, 0, 1)
            local ry = math.clamp((input.Position.Y - ap.Y) / asz.Y, 0, 1)
            s = rx; v = 1 - ry
            svCursor.Position = UDim2.new(rx, 0, ry, 0)
            updateColor()
        end
        if hueDrag then
            local ap = hueBar.AbsolutePosition; local asz = hueBar.AbsoluteSize
            local ry = math.clamp((input.Position.Y - ap.Y) / asz.Y, 0, 1)
            h = ry
            hueCursor.Position = UDim2.new(0, -2, ry, -1)
            updateColor()
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDrag = false; hueDrag = false
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: COLOR
-- ═══════════════════════════════════════════════════════════

local colorPage = tabPages["Color"]
colorPage.CanvasSize = UDim2.new(0, 0, 0, 500)

sectionLabel(colorPage, "★ COLOR CORRECTION", 5)
createSlider(colorPage, "Contrast", 30, -1, 1, 0, 2, function(v) Color.Contrast = v end)
createSlider(colorPage, "Saturation", 94, -1, 5, 0, 2, function(v) Color.Saturation = v end)
createSlider(colorPage, "Brightness", 158, -1, 1, 0, 2, function(v) Color.Brightness = v end)
createSlider(colorPage, "Exposure", 222, -3, 3, 0, 2, function(v) Lighting.ExposureCompensation = v end)

sectionLabel(colorPage, "★ TINT COLOR", 296)
createColorPicker(colorPage, "Tint:", 322, Color3.new(1,1,1), function(c) Color.TintColor = c end)

-- ═══════════════════════════════════════════════════════════
--  TAB: BLOOM
-- ═══════════════════════════════════════════════════════════

local bloomPage = tabPages["Bloom"]
bloomPage.CanvasSize = UDim2.new(0, 0, 0, 260)

sectionLabel(bloomPage, "★ BLOOM (GLOW)", 5)
createSlider(bloomPage, "Intensity", 30, 0, 3, 0.4, 2, function(v) Bloom.Intensity = v end)
createSlider(bloomPage, "Size", 94, 0, 56, 24, 0, function(v) Bloom.Size = v end)
createSlider(bloomPage, "Threshold", 158, 0, 2, 0.95, 2, function(v) Bloom.Threshold = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: BLUR / MOTION
-- ═══════════════════════════════════════════════════════════

local blurPage = tabPages["Blur"]
blurPage.CanvasSize = UDim2.new(0, 0, 0, 220)

sectionLabel(blurPage, "★ MOTION BLUR", 5)
createToggle(blurPage, "💨", "Enable Motion Blur", 30, false, function(s)
    motionBlurEnabled = s
    if not s then Blur.Size = 0 end
end)
createSlider(blurPage, "Motion Blur Strength", 80, 0, 3, 0.3, 2, function(v) motionBlurStrength = v end)

sectionLabel(blurPage, "★ STATIC BLUR", 154)
createSlider(blurPage, "Static Blur Size", 180, 0, 56, 0, 0, function(v)
    if not motionBlurEnabled then Blur.Size = v end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: DOF
-- ═══════════════════════════════════════════════════════════

local dofPage = tabPages["DOF"]
dofPage.CanvasSize = UDim2.new(0, 0, 0, 320)

sectionLabel(dofPage, "★ DEPTH OF FIELD", 5)
createSlider(dofPage, "Far Intensity", 30, 0, 1, 0, 2, function(v) DOF.FarIntensity = v end)
createSlider(dofPage, "Near Intensity", 94, 0, 1, 0, 2, function(v) DOF.NearIntensity = v end)
createSlider(dofPage, "Focus Distance", 158, 0, 500, 50, 0, function(v) DOF.FocusDistance = v end)
createSlider(dofPage, "In-Focus Radius", 222, 0, 500, 50, 0, function(v) DOF.InFocusRadius = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: WORLD
-- ═══════════════════════════════════════════════════════════

local worldPage = tabPages["World"]
worldPage.CanvasSize = UDim2.new(0, 0, 0, 600)

sectionLabel(worldPage, "★ ATMOSPHERE", 5)
createSlider(worldPage, "Density", 30, 0, 1, 0.3, 2, function(v) Atmosphere.Density = v end)
createSlider(worldPage, "Offset", 94, 0, 1, 0.25, 2, function(v) Atmosphere.Offset = v end)
createSlider(worldPage, "Glare", 158, 0, 3, 0, 2, function(v) Atmosphere.Glare = v end)
createSlider(worldPage, "Haze", 222, 0, 3, 0, 2, function(v) Atmosphere.Haze = v end)

sectionLabel(worldPage, "★ SUN RAYS", 296)
createSlider(worldPage, "Ray Intensity", 322, 0, 1, 0.1, 2, function(v) SunRays.Intensity = v end)
createSlider(worldPage, "Ray Spread", 386, 0, 1, 0.5, 2, function(v) SunRays.Spread = v end)

sectionLabel(worldPage, "★ FOG", 460)
createSlider(worldPage, "Fog End Distance", 486, 0, 10000, 5000, 0, function(v) Lighting.FogEnd = v end)
createSlider(worldPage, "Fog Start", 550, 0, 5000, 0, 0, function(v) Lighting.FogStart = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: FX (Overlays)
-- ═══════════════════════════════════════════════════════════

local fxPage = tabPages["FX"]
fxPage.CanvasSize = UDim2.new(0, 0, 0, 700)

sectionLabel(fxPage, "★ VIGNETTE", 5)
createSlider(fxPage, "Vignette Intensity", 30, 0, 1, 0, 2, function(v) Vignette.ImageTransparency = 1 - v end)

sectionLabel(fxPage, "★ FILM GRAIN", 104)
createSlider(fxPage, "Grain Intensity", 130, 0, 1, 0, 2, function(v) FilmGrain.ImageTransparency = 1 - v * 0.5 end)

sectionLabel(fxPage, "★ CHROMATIC ABERRATION", 204)
createSlider(fxPage, "Chromatic Strength", 230, 0, 30, 0, 0, function(v)
    if v == 0 then
        ChromaRed.BackgroundTransparency = 1
        ChromaBlue.BackgroundTransparency = 1
    else
        ChromaRed.BackgroundTransparency = 1 - (v/30) * 0.15
        ChromaBlue.BackgroundTransparency = 1 - (v/30) * 0.15
        ChromaRed.Position = UDim2.new(0, -v, 0, 0)
        ChromaBlue.Position = UDim2.new(0, v, 0, 0)
    end
end)

sectionLabel(fxPage, "★ SCANLINES", 304)
createSlider(fxPage, "Scanlines Intensity", 330, 0, 1, 0, 2, function(v)
    if v == 0 then
        scanGrad.Transparency = NumberSequence.new(1)
        Scanlines.BackgroundTransparency = 1
    else
        Scanlines.BackgroundColor3 = Color3.new(0,0,0)
        Scanlines.BackgroundTransparency = 1 - v * 0.3
    end
end)

sectionLabel(fxPage, "★ LETTERBOX (CINEMATIC BARS)", 404)
createSlider(fxPage, "Bar Size", 430, 0, 200, 0, 0, function(v)
    tween(LetterTop, {Size = UDim2.new(1, 0, 0, v)}, 0.3)
    tween(LetterBot, {Size = UDim2.new(1, 0, 0, v)}, 0.3)
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: PRESETS
-- ═══════════════════════════════════════════════════════════

local presetPage = tabPages["Presets"]
presetPage.CanvasSize = UDim2.new(0, 0, 0, 900)

local presets = {
    ["🎬 Cinematic"] = {contrast=0.15,sat=0.1,bright=0.02,tint=Color3.fromRGB(255,240,220),bloom=0.6,bSize=30,bThresh=0.85,mBlur=true,mStr=0.35,dofFar=0.15,dofFoc=80,dofRad=60,atmDen=0.35,atmOff=0.3,sun=0.15,sunSpr=0.6,fog=5000,vign=0.3,grain=0.15,chrom=0,scan=0,letter=0,exp=0},
    ["🌅 Golden Hour"] = {contrast=0.2,sat=0.25,bright=0.05,tint=Color3.fromRGB(255,210,160),bloom=0.8,bSize=40,bThresh=0.8,mBlur=true,mStr=0.25,dofFar=0.1,dofFoc=100,dofRad=80,atmDen=0.4,atmOff=0.4,sun=0.3,sunSpr=0.8,fog=3000,vign=0.4,grain=0.1,chrom=0,scan=0,letter=0,exp=0.2},
    ["❄️ Cold Winter"] = {contrast=0.25,sat=-0.15,bright=0.03,tint=Color3.fromRGB(200,220,255),bloom=0.5,bSize=20,bThresh=0.9,mBlur=true,mStr=0.2,dofFar=0.05,dofFoc=120,dofRad=100,atmDen=0.5,atmOff=0.2,sun=0.05,sunSpr=0.4,fog=2000,vign=0.5,grain=0.05,chrom=0,scan=0,letter=0,exp=0},
    ["🌙 Dark Horror"] = {contrast=0.4,sat=-0.3,bright=-0.15,tint=Color3.fromRGB(180,180,210),bloom=0.3,bSize=15,bThresh=0.95,mBlur=true,mStr=0.5,dofFar=0.3,dofFoc=40,dofRad=30,atmDen=0.7,atmOff=0.1,sun=0,sunSpr=0,fog=800,vign=0.9,grain=0.6,chrom=8,scan=0,letter=0,exp=-0.5},
    ["🌈 Vibrant"] = {contrast=0.2,sat=0.4,bright=0.05,tint=Color3.new(1,1,1),bloom=0.7,bSize=25,bThresh=0.85,mBlur=false,mStr=0,dofFar=0,dofFoc=50,dofRad=50,atmDen=0.2,atmOff=0.3,sun=0.2,sunSpr=0.7,fog=8000,vign=0,grain=0,chrom=0,scan=0,letter=0,exp=0.1},
    ["🎥 Classic Movie"] = {contrast=0.3,sat=-0.1,bright=0,tint=Color3.fromRGB(230,235,255),bloom=0.5,bSize=20,bThresh=0.9,mBlur=true,mStr=0.4,dofFar=0.2,dofFoc=60,dofRad=50,atmDen=0.4,atmOff=0.25,sun=0.1,sunSpr=0.5,fog=3500,vign=0.5,grain=0.25,chrom=0,scan=0,letter=100,exp=0},
    ["☀️ Bright Sunny"] = {contrast=0.15,sat=0.2,bright=0.1,tint=Color3.fromRGB(255,250,235),bloom=1.2,bSize=45,bThresh=0.75,mBlur=false,mStr=0,dofFar=0,dofFoc=100,dofRad=80,atmDen=0.15,atmOff=0.35,sun=0.4,sunSpr=0.9,fog=10000,vign=0.1,grain=0,chrom=0,scan=0,letter=0,exp=0.3},
    ["🌸 Anime"] = {contrast=0.1,sat=0.5,bright=0.08,tint=Color3.fromRGB(255,235,245),bloom=1.0,bSize=35,bThresh=0.7,mBlur=false,mStr=0,dofFar=0.05,dofFoc=80,dofRad=70,atmDen=0.25,atmOff=0.4,sun=0.15,sunSpr=0.6,fog=6000,vign=0.2,grain=0,chrom=0,scan=0,letter=0,exp=0.15},
    ["📺 Retro VHS"] = {contrast=0.2,sat=0.15,bright=0.05,tint=Color3.fromRGB(255,220,220),bloom=0.7,bSize=25,bThresh=0.8,mBlur=true,mStr=0.3,dofFar=0.05,dofFoc=100,dofRad=80,atmDen=0.3,atmOff=0.3,sun=0.1,sunSpr=0.5,fog=4000,vign=0.4,grain=0.4,chrom=10,scan=0.3,letter=0,exp=0},
    ["🎮 Cyberpunk"] = {contrast=0.35,sat=0.3,bright=-0.05,tint=Color3.fromRGB(200,180,255),bloom=1.5,bSize=50,bThresh=0.7,mBlur=true,mStr=0.4,dofFar=0.15,dofFoc=70,dofRad=60,atmDen=0.4,atmOff=0.2,sun=0.05,sunSpr=0.4,fog=2500,vign=0.5,grain=0.15,chrom=6,scan=0.1,letter=0,exp=0.1},
    ["🔥 Blockbuster"] = {contrast=0.35,sat=0.1,bright=0.05,tint=Color3.fromRGB(255,220,190),bloom=0.9,bSize=35,bThresh=0.8,mBlur=true,mStr=0.5,dofFar=0.2,dofFoc=70,dofRad=50,atmDen=0.35,atmOff=0.3,sun=0.25,sunSpr=0.75,fog=4500,vign=0.55,grain=0.2,chrom=3,scan=0,letter=120,exp=0.15},
    ["🌊 Underwater"] = {contrast=0.2,sat=0.1,bright=-0.05,tint=Color3.fromRGB(150,200,230),bloom=0.6,bSize=30,bThresh=0.85,mBlur=true,mStr=0.4,dofFar=0.5,dofFoc=30,dofRad=25,atmDen=0.8,atmOff=0.15,sun=0.1,sunSpr=0.5,fog=1500,vign=0.4,grain=0.1,chrom=4,scan=0,letter=0,exp=-0.1},
    ["🚫 Reset"] = {contrast=0,sat=0,bright=0,tint=Color3.new(1,1,1),bloom=0.4,bSize=24,bThresh=0.95,mBlur=false,mStr=0,dofFar=0,dofFoc=50,dofRad=50,atmDen=0.3,atmOff=0.25,sun=0.1,sunSpr=0.5,fog=5000,vign=0,grain=0,chrom=0,scan=0,letter=0,exp=0},
}

local function applyPreset(p)
    Color.Contrast = p.contrast
    Color.Saturation = p.sat
    Color.Brightness = p.bright
    Color.TintColor = p.tint
    Bloom.Intensity = p.bloom
    Bloom.Size = p.bSize
    Bloom.Threshold = p.bThresh
    motionBlurEnabled = p.mBlur
    motionBlurStrength = p.mStr
    DOF.FarIntensity = p.dofFar
    DOF.FocusDistance = p.dofFoc
    DOF.InFocusRadius = p.dofRad
    Atmosphere.Density = p.atmDen
    Atmosphere.Offset = p.atmOff
    SunRays.Intensity = p.sun
    SunRays.Spread = p.sunSpr
    Lighting.FogEnd = p.fog
    Lighting.ExposureCompensation = p.exp
    if not p.mBlur then Blur.Size = 0 end
    Vignette.ImageTransparency = 1 - p.vign
    FilmGrain.ImageTransparency = 1 - p.grain * 0.5
    if p.chrom == 0 then
        ChromaRed.BackgroundTransparency = 1
        ChromaBlue.BackgroundTransparency = 1
    else
        ChromaRed.BackgroundTransparency = 1 - (p.chrom/30) * 0.15
        ChromaBlue.BackgroundTransparency = 1 - (p.chrom/30) * 0.15
        ChromaRed.Position = UDim2.new(0, -p.chrom, 0, 0)
        ChromaBlue.Position = UDim2.new(0, p.chrom, 0, 0)
    end
    if p.scan == 0 then
        Scanlines.BackgroundTransparency = 1
    else
        Scanlines.BackgroundColor3 = Color3.new(0,0,0)
        Scanlines.BackgroundTransparency = 1 - p.scan * 0.3
    end
    tween(LetterTop, {Size = UDim2.new(1, 0, 0, p.letter)}, 0.3)
    tween(LetterBot, {Size = UDim2.new(1, 0, 0, p.letter)}, 0.3)
end

sectionLabel(presetPage, "★ CINEMATIC PRESETS", 5)

local presetOrder = {"🎬 Cinematic","🌅 Golden Hour","❄️ Cold Winter","🌙 Dark Horror","🌈 Vibrant","🎥 Classic Movie","☀️ Bright Sunny","🌸 Anime","📺 Retro VHS","🎮 Cyberpunk","🔥 Blockbuster","🌊 Underwater","🚫 Reset"}
local pColors = {
    {C.accent, C.accent2}, {Color3.fromRGB(255,180,80), Color3.fromRGB(255,120,40)},
    {Color3.fromRGB(120,180,240), Color3.fromRGB(80,140,220)}, {Color3.fromRGB(80,80,120), Color3.fromRGB(40,40,80)},
    {Color3.fromRGB(255,100,200), C.purple}, {Color3.fromRGB(180,100,200), Color3.fromRGB(120,80,180)},
    {C.yellow, Color3.fromRGB(255,180,60)}, {Color3.fromRGB(255,150,200), Color3.fromRGB(255,100,180)},
    {Color3.fromRGB(220,150,150), Color3.fromRGB(180,100,100)}, {C.purple, C.cyan},
    {C.red, C.accent2}, {C.cyan, Color3.fromRGB(80,180,220)}, {C.red, Color3.fromRGB(160,40,40)},
}

for i, name in ipairs(presetOrder) do
    local yOff = 30 + (i - 1) * 46
    local col = pColors[i]
    createButton(presetPage, "", name, yOff, col[1], col[2], function()
        applyPreset(presets[name])
        setStatus("✓ Applied: " .. name, col[1])
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: SAVE / LOAD
-- ═══════════════════════════════════════════════════════════

local savePage = tabPages["Save"]
savePage.CanvasSize = UDim2.new(0, 0, 0, 400)

sectionLabel(savePage, "★ SAVE CURRENT CONFIG", 5)

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -20, 0, 38)
nameBox.Position = UDim2.new(0, 10, 0, 30)
nameBox.BackgroundColor3 = C.cardLight
nameBox.Text = ""
nameBox.PlaceholderText = "Enter preset name..."
nameBox.TextColor3 = C.text
nameBox.Font = Enum.Font.GothamSemibold
nameBox.TextSize = 12
nameBox.Parent = savePage
corner(nameBox, 8)
stroke(nameBox, C.accent, 1, 0.3)

local function saveCurrent()
    local name = nameBox.Text
    if name == "" then setStatus("❌ Enter a name first", C.red); return end
    customPresets[name] = {
        contrast=Color.Contrast, sat=Color.Saturation, bright=Color.Brightness, tint=Color.TintColor,
        bloom=Bloom.Intensity, bSize=Bloom.Size, bThresh=Bloom.Threshold,
        mBlur=motionBlurEnabled, mStr=motionBlurStrength,
        dofFar=DOF.FarIntensity, dofFoc=DOF.FocusDistance, dofRad=DOF.InFocusRadius,
        atmDen=Atmosphere.Density, atmOff=Atmosphere.Offset,
        sun=SunRays.Intensity, sunSpr=SunRays.Spread, fog=Lighting.FogEnd,
        exp=Lighting.ExposureCompensation,
        vign=1 - Vignette.ImageTransparency,
        grain=(1 - FilmGrain.ImageTransparency) * 2,
        chrom=math.abs(ChromaRed.Position.X.Offset),
        scan=ChromaRed.BackgroundTransparency == 1 and 0 or (1 - Scanlines.BackgroundTransparency) / 0.3,
        letter=LetterTop.Size.Y.Offset,
    }
    setStatus("💾 Saved: " .. name, C.green)
    nameBox.Text = ""
end

createButton(savePage, "💾", "Save Current Configuration", 78, C.green, Color3.fromRGB(40,180,100), saveCurrent)

sectionLabel(savePage, "★ INFO", 140)

local infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1, -20, 0, 100)
infoLbl.Position = UDim2.new(0, 10, 0, 166)
infoLbl.BackgroundColor3 = C.cardLight
infoLbl.Text = "🎬 NOVA CINEMATIC PRO v2.0\n\n★ Press ] to toggle UI\n★ Adjust all sliders in real-time\n★ 13 built-in presets\n★ Save your own configurations\n★ Motion blur, DOF, film grain\n★ Chromatic aberration & more"
infoLbl.TextColor3 = C.subtext
infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 11
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.TextYAlignment = Enum.TextYAlignment.Top
infoLbl.TextWrapped = true
infoLbl.Parent = savePage
corner(infoLbl, 8)
local infoPad = Instance.new("UIPadding")
infoPad.PaddingLeft = UDim.new(0, 12); infoPad.PaddingTop = UDim.new(0, 8)
infoPad.Parent = infoLbl

-- Activate default
switchTab("Color")

-- ═══════════════════════════════════════════════════════════
--  KEYBINDS
-- ═══════════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightBracket then
        Holder.Visible = not Holder.Visible
    end
end)

-- ═══════════════════════════════════════════════════════════
--  ENTRY ANIMATION
-- ═══════════════════════════════════════════════════════════

Holder.Position = UDim2.new(0.5, -250, -1.5, 0)
tween(Holder, {Position = UDim2.new(0.5, -250, 0.5, -300)}, 0.7, Enum.EasingStyle.Back)

print("═══════════════════════════════════════")
print("  🎬 NOVA CINEMATIC PRO v2.0 LOADED")
print("  📷 Press ] to toggle UI")
print("  🎞 13 presets + save/load")
print("═══════════════════════════════════════")
