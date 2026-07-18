-- ═══════════════════════════════════════════════════════════
--  🎬 NOVA CINEMATIC ULTRA v3.0
--  Motion Blur Pro | Time of Day | Weather | Lens Flare
-- ═══════════════════════════════════════════════════════════

local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer

-- ═══ CLEANUP ═══
for _, n in ipairs({"NovaCinematicUltra","NovaOverlaysU","NovaWeather"}) do
    local ex = CoreGui:FindFirstChild(n) if ex then ex:Destroy() end
end
for _, n in ipairs({"NovaBlur","NovaBloom","NovaColor","NovaDOF","NovaSunRays","NovaAtmosphere","NovaMotionBlur"}) do
    local ex = Lighting:FindFirstChild(n) if ex then ex:Destroy() end
end
local ws = workspace:FindFirstChild("NovaWeatherFolder")
if ws then ws:Destroy() end

-- ═══════════════════════════════════════════════════════════
--  LIGHTING EFFECTS
-- ═══════════════════════════════════════════════════════════

local Blur = Instance.new("BlurEffect")
Blur.Name = "NovaBlur"; Blur.Size = 0; Blur.Parent = Lighting

local MotionBlur = Instance.new("BlurEffect")
MotionBlur.Name = "NovaMotionBlur"; MotionBlur.Size = 0; MotionBlur.Parent = Lighting

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
local motionBlurStrength = 0.5
local motionBlurQuality = 8 -- accumulation samples
local timeOfDayLocked = false
local currentWeather = "None"
local weatherFolder = nil

-- ═══════════════════════════════════════════════════════════
--  ★★★ BEAUTIFUL MOTION BLUR SYSTEM ★★★
-- ═══════════════════════════════════════════════════════════

local cameraHistory = {} -- stores previous camera CFrames
local velocitySmoothed = 0
local rotationSmoothed = 0

RS.RenderStepped:Connect(function(dt)
    if not motionBlurEnabled then
        MotionBlur.Size = MotionBlur.Size * 0.85 -- smooth fadeout
        if MotionBlur.Size < 0.1 then MotionBlur.Size = 0 end
        return
    end
    
    local cam = workspace.CurrentCamera
    if not cam then return end
    local cur = cam.CFrame
    
    -- Store camera history
    table.insert(cameraHistory, 1, {cframe = cur, time = tick()})
    while #cameraHistory > motionBlurQuality do
        table.remove(cameraHistory)
    end
    
    if #cameraHistory < 2 then return end
    
    -- Calculate weighted velocity over multiple frames
    local totalVelocity = 0
    local totalRotation = 0
    local weightSum = 0
    
    for i = 1, #cameraHistory - 1 do
        local weight = 1 / i
        local a = cameraHistory[i]
        local b = cameraHistory[i + 1]
        local timeDelta = a.time - b.time
        if timeDelta > 0 then
            local posDelta = (a.cframe.Position - b.cframe.Position).Magnitude / timeDelta
            local lookDot = a.cframe.LookVector:Dot(b.cframe.LookVector)
            local rotDelta = math.acos(math.clamp(lookDot, -1, 1)) / timeDelta * 30
            totalVelocity = totalVelocity + posDelta * weight
            totalRotation = totalRotation + rotDelta * weight
            weightSum = weightSum + weight
        end
    end
    
    if weightSum > 0 then
        totalVelocity = totalVelocity / weightSum
        totalRotation = totalRotation / weightSum
    end
    
    -- Smooth interpolation for buttery motion
    velocitySmoothed = velocitySmoothed + (totalVelocity - velocitySmoothed) * 0.3
    rotationSmoothed = rotationSmoothed + (totalRotation - rotationSmoothed) * 0.3
    
    -- Combined intensity (movement + rotation)
    local combined = (velocitySmoothed * 0.4 + rotationSmoothed * 0.6) * motionBlurStrength
    local targetBlur = math.clamp(combined, 0, 32)
    
    -- Extra smooth blur transition
    MotionBlur.Size = MotionBlur.Size + (targetBlur - MotionBlur.Size) * 0.5
end)

-- ═══ COLORS ═══
local C = {
    bg         = Color3.fromRGB(6, 6, 12),
    bg2        = Color3.fromRGB(12, 12, 20),
    card       = Color3.fromRGB(18, 18, 30),
    cardLight  = Color3.fromRGB(26, 26, 42),
    cardHover  = Color3.fromRGB(34, 34, 54),
    accent     = Color3.fromRGB(255, 85, 100),
    accent2    = Color3.fromRGB(255, 160, 80),
    accent3    = Color3.fromRGB(255, 60, 150),
    purple     = Color3.fromRGB(150, 80, 255),
    cyan       = Color3.fromRGB(70, 220, 255),
    green      = Color3.fromRGB(70, 240, 150),
    yellow     = Color3.fromRGB(255, 220, 80),
    red        = Color3.fromRGB(255, 70, 90),
    text       = Color3.fromRGB(245, 245, 255),
    subtext    = Color3.fromRGB(180, 180, 210),
    muted      = Color3.fromRGB(110, 110, 145),
    border     = Color3.fromRGB(45, 45, 70),
    toggleOff  = Color3.fromRGB(45, 45, 65),
    toggleOn   = Color3.fromRGB(255, 85, 100),
}

-- ═══ HELPERS ═══
local function corner(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 10) c.Parent=p return c end
local function stroke(p,col,t,tr) local s=Instance.new("UIStroke") s.Color=col or C.border s.Thickness=t or 1 s.Transparency=tr or 0.5 s.Parent=p return s end
local function grad(p,seq,rot) local g=Instance.new("UIGradient") g.Color=seq g.Rotation=rot or 90 g.Parent=p return g end
local function tween(o,p,d,s,dir) return TS:Create(o,TweenInfo.new(d or 0.25,s or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),p):Play() end

-- ═══════════════════════════════════════════════════════════
--  MAIN GUI
-- ═══════════════════════════════════════════════════════════

local Gui = Instance.new("ScreenGui")
Gui.Name = "NovaCinematicUltra"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

-- ═══════════════════════════════════════════════════════════
--  OVERLAY EFFECTS
-- ═══════════════════════════════════════════════════════════

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "NovaOverlaysU"
OverlayGui.ResetOnSpawn = false
OverlayGui.IgnoreGuiInset = true
OverlayGui.DisplayOrder = -5
OverlayGui.Parent = CoreGui

local Vignette = Instance.new("ImageLabel")
Vignette.Size = UDim2.new(1, 0, 1, 0); Vignette.BackgroundTransparency = 1
Vignette.Image = "rbxassetid://11295263412"; Vignette.ImageColor3 = Color3.new(0,0,0)
Vignette.ImageTransparency = 1; Vignette.ScaleType = Enum.ScaleType.Stretch
Vignette.Parent = OverlayGui

local FilmGrain = Instance.new("ImageLabel")
FilmGrain.Size = UDim2.new(1, 0, 1, 0); FilmGrain.BackgroundTransparency = 1
FilmGrain.Image = "rbxassetid://7027187124"; FilmGrain.ImageTransparency = 1
FilmGrain.ScaleType = Enum.ScaleType.Tile; FilmGrain.TileSize = UDim2.new(0, 256, 0, 256)
FilmGrain.Parent = OverlayGui

local Scanlines = Instance.new("Frame")
Scanlines.Size = UDim2.new(1, 0, 1, 0); Scanlines.BackgroundTransparency = 1
Scanlines.BackgroundColor3 = Color3.new(0,0,0); Scanlines.Parent = OverlayGui

local ChromaR = Instance.new("Frame")
ChromaR.Size = UDim2.new(1, 0, 1, 0); ChromaR.BackgroundColor3 = Color3.fromRGB(255,0,0)
ChromaR.BackgroundTransparency = 1; ChromaR.BorderSizePixel = 0; ChromaR.Parent = OverlayGui

local ChromaB = Instance.new("Frame")
ChromaB.Size = UDim2.new(1, 0, 1, 0); ChromaB.BackgroundColor3 = Color3.fromRGB(0,100,255)
ChromaB.BackgroundTransparency = 1; ChromaB.BorderSizePixel = 0; ChromaB.Parent = OverlayGui

local LetterTop = Instance.new("Frame")
LetterTop.Size = UDim2.new(1, 0, 0, 0); LetterTop.BackgroundColor3 = Color3.new(0,0,0)
LetterTop.BorderSizePixel = 0; LetterTop.Parent = OverlayGui

local LetterBot = Instance.new("Frame")
LetterBot.Size = UDim2.new(1, 0, 0, 0); LetterBot.Position = UDim2.new(0, 0, 1, 0)
LetterBot.AnchorPoint = Vector2.new(0, 1); LetterBot.BackgroundColor3 = Color3.new(0,0,0)
LetterBot.BorderSizePixel = 0; LetterBot.Parent = OverlayGui

-- Lens Flare
local LensFlare = Instance.new("ImageLabel")
LensFlare.Size = UDim2.new(0, 400, 0, 400)
LensFlare.AnchorPoint = Vector2.new(0.5, 0.5)
LensFlare.Position = UDim2.new(0.75, 0, 0.3, 0)
LensFlare.BackgroundTransparency = 1
LensFlare.Image = "rbxassetid://5028857084"
LensFlare.ImageColor3 = Color3.fromRGB(255, 220, 150)
LensFlare.ImageTransparency = 1
LensFlare.Parent = OverlayGui

-- Light Leak
local LightLeak = Instance.new("Frame")
LightLeak.Size = UDim2.new(1, 0, 1, 0)
LightLeak.BackgroundTransparency = 1
LightLeak.BorderSizePixel = 0
LightLeak.Parent = OverlayGui
local leakGrad = Instance.new("UIGradient")
leakGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 80)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 80))
}
leakGrad.Transparency = NumberSequence.new(1)
leakGrad.Rotation = 45
leakGrad.Parent = LightLeak

-- Film Burn
local FilmBurn = Instance.new("ImageLabel")
FilmBurn.Size = UDim2.new(1, 0, 1, 0)
FilmBurn.BackgroundTransparency = 1
FilmBurn.Image = "rbxassetid://5028857084"
FilmBurn.ImageColor3 = Color3.fromRGB(255, 140, 60)
FilmBurn.ImageTransparency = 1
FilmBurn.Parent = OverlayGui

-- Glitch effect (colored strips)
local GlitchHolder = Instance.new("Frame")
GlitchHolder.Size = UDim2.new(1, 0, 1, 0)
GlitchHolder.BackgroundTransparency = 1
GlitchHolder.Visible = false
GlitchHolder.Parent = OverlayGui

-- Grain animation
task.spawn(function()
    while OverlayGui.Parent do
        FilmGrain.Position = UDim2.new(0, math.random(-50, 50), 0, math.random(-50, 50))
        task.wait(0.05)
    end
end)

-- Lens flare follow sun (simulated)
task.spawn(function()
    while OverlayGui.Parent do
        local t = tick()
        LensFlare.Position = UDim2.new(0.7 + math.sin(t*0.2)*0.1, 0, 0.3 + math.cos(t*0.15)*0.05, 0)
        task.wait(0.05)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════════

local Holder = Instance.new("Frame")
Holder.Size = UDim2.new(0, 540, 0, 620)
Holder.Position = UDim2.new(0.5, -270, 0.5, -310)
Holder.BackgroundTransparency = 1
Holder.Parent = Gui

-- Ambient glows
local glow1 = Instance.new("ImageLabel")
glow1.Size = UDim2.new(1.5, 0, 1.5, 0); glow1.Position = UDim2.new(-0.25, 0, -0.25, 0)
glow1.BackgroundTransparency = 1; glow1.Image = "rbxassetid://5028857084"
glow1.ImageColor3 = C.accent; glow1.ImageTransparency = 0.75
glow1.Parent = Holder

local glow2 = Instance.new("ImageLabel")
glow2.Size = UDim2.new(1.4, 0, 1.4, 0); glow2.Position = UDim2.new(-0.2, 0, -0.2, 0)
glow2.BackgroundTransparency = 1; glow2.Image = "rbxassetid://5028857084"
glow2.ImageColor3 = C.purple; glow2.ImageTransparency = 0.82
glow2.Parent = Holder

local glow3 = Instance.new("ImageLabel")
glow3.Size = UDim2.new(1.35, 0, 1.35, 0); glow3.Position = UDim2.new(-0.175, 0, -0.175, 0)
glow3.BackgroundTransparency = 1; glow3.Image = "rbxassetid://5028857084"
glow3.ImageColor3 = C.cyan; glow3.ImageTransparency = 0.88
glow3.Parent = Holder

-- Pulse
task.spawn(function()
    while Gui.Parent do
        tween(glow1,{ImageTransparency=0.6},2.5,Enum.EasingStyle.Sine)
        tween(glow2,{ImageTransparency=0.7},3,Enum.EasingStyle.Sine)
        tween(glow3,{ImageTransparency=0.75},3.5,Enum.EasingStyle.Sine)
        task.wait(3.5)
        tween(glow1,{ImageTransparency=0.85},2.5,Enum.EasingStyle.Sine)
        tween(glow2,{ImageTransparency=0.88},3,Enum.EasingStyle.Sine)
        tween(glow3,{ImageTransparency=0.92},3.5,Enum.EasingStyle.Sine)
        task.wait(3.5)
    end
end)

-- ═══ MAIN FRAME ═══
local Main = Instance.new("Frame")
Main.Size = UDim2.new(1, 0, 1, 0)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Parent = Holder
corner(Main, 18)
stroke(Main, C.accent, 1.5, 0.4)

grad(Main, ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 12, 22)),
    ColorSequenceKeypoint.new(0.5, C.bg),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 12, 26))
}, 135)

-- Inner particle stars
local starHolder = Instance.new("Frame")
starHolder.Size = UDim2.new(1, 0, 1, 0)
starHolder.BackgroundTransparency = 1
starHolder.ClipsDescendants = true
starHolder.Parent = Main
corner(starHolder, 18)

for i = 1, 25 do
    local s = Instance.new("Frame")
    local sz = math.random(1, 3)
    s.Size = UDim2.new(0, sz, 0, sz)
    s.Position = UDim2.new(math.random(), 0, math.random(), 0)
    s.BackgroundColor3 = C.text
    s.BackgroundTransparency = math.random(40, 85)/100
    s.BorderSizePixel = 0
    s.Parent = starHolder
    corner(s, sz)
    task.spawn(function()
        while s.Parent do
            tween(s, {BackgroundTransparency = math.random(20, 90)/100}, math.random(20, 40)/10)
            task.wait(math.random(2, 4))
        end
    end)
end

-- ═══ TITLE BAR ═══
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 70)
titleBar.BackgroundColor3 = C.card
titleBar.BorderSizePixel = 0
titleBar.Parent = Main
corner(titleBar, 18)

local tCover = Instance.new("Frame")
tCover.Size = UDim2.new(1, 0, 0, 20); tCover.Position = UDim2.new(0, 0, 1, -20)
tCover.BackgroundColor3 = C.card; tCover.BorderSizePixel = 0
tCover.Parent = titleBar

grad(titleBar, ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 40)),
    ColorSequenceKeypoint.new(1, C.card)
}, 90)

-- Animated title line
local titleLine = Instance.new("Frame")
titleLine.Size = UDim2.new(1, -30, 0, 3)
titleLine.Position = UDim2.new(0, 15, 1, -3)
titleLine.BackgroundColor3 = C.accent
titleLine.BorderSizePixel = 0
titleLine.Parent = titleBar
corner(titleLine, 2)

local lineGrad = Instance.new("UIGradient")
lineGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.purple),
    ColorSequenceKeypoint.new(0.25, C.accent3),
    ColorSequenceKeypoint.new(0.5, C.accent),
    ColorSequenceKeypoint.new(0.75, C.accent2),
    ColorSequenceKeypoint.new(1, C.yellow)
}
lineGrad.Parent = titleLine

task.spawn(function()
    while Gui.Parent do
        tween(lineGrad, {Rotation = 360}, 8, Enum.EasingStyle.Linear)
        task.wait(8)
        lineGrad.Rotation = 0
    end
end)

-- Logo box
local logoBox = Instance.new("Frame")
logoBox.Size = UDim2.new(0, 46, 0, 46)
logoBox.Position = UDim2.new(0, 14, 0.5, -23)
logoBox.BackgroundColor3 = C.cardLight
logoBox.BorderSizePixel = 0
logoBox.Parent = titleBar
corner(logoBox, 12)
stroke(logoBox, C.accent, 1.5, 0.3)

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(1, 0, 1, 0)
logo.BackgroundTransparency = 1
logo.Text = "🎬"
logo.TextSize = 26
logo.Parent = logoBox

-- Rotate logo slowly
task.spawn(function()
    while Gui.Parent do
        tween(logoBox, {Rotation = 360}, 20, Enum.EasingStyle.Linear)
        task.wait(20)
        logoBox.Rotation = 0
    end
end)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 300, 0, 26)
titleText.Position = UDim2.new(0, 72, 0, 12)
titleText.BackgroundTransparency = 1
titleText.Text = "NOVA CINEMATIC"
titleText.TextColor3 = C.text
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 20
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

grad(titleText, ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.accent),
    ColorSequenceKeypoint.new(0.5, C.accent2),
    ColorSequenceKeypoint.new(1, C.yellow)
}, 0)

local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(0, 300, 0, 16)
subText.Position = UDim2.new(0, 72, 0, 38)
subText.BackgroundTransparency = 1
subText.Text = "★ ULTRA EDITION v3.0"
subText.TextColor3 = C.subtext
subText.Font = Enum.Font.GothamSemibold
subText.TextSize = 10
subText.TextXAlignment = Enum.TextXAlignment.Left
subText.Parent = titleBar

-- FPS box
local fpsBox = Instance.new("Frame")
fpsBox.Size = UDim2.new(0, 68, 0, 30)
fpsBox.Position = UDim2.new(1, -200, 0.5, -15)
fpsBox.BackgroundColor3 = C.cardLight
fpsBox.BorderSizePixel = 0
fpsBox.Parent = titleBar
corner(fpsBox, 8)
stroke(fpsBox, C.green, 1, 0.4)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 0.6, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "60"
fpsLabel.TextColor3 = C.green
fpsLabel.Font = Enum.Font.GothamBlack
fpsLabel.TextSize = 14
fpsLabel.Parent = fpsBox

local fpsSubLbl = Instance.new("TextLabel")
fpsSubLbl.Size = UDim2.new(1, 0, 0.4, -2)
fpsSubLbl.Position = UDim2.new(0, 0, 0.6, 0)
fpsSubLbl.BackgroundTransparency = 1
fpsSubLbl.Text = "FPS"
fpsSubLbl.TextColor3 = C.muted
fpsSubLbl.Font = Enum.Font.GothamSemibold
fpsSubLbl.TextSize = 8
fpsSubLbl.Parent = fpsBox

task.spawn(function()
    while Gui.Parent do
        local frames = 0; local start = tick()
        local conn; conn = RS.RenderStepped:Connect(function() frames = frames + 1 end)
        task.wait(1); conn:Disconnect()
        local fps = math.floor(frames / (tick() - start))
        fpsLabel.Text = tostring(fps)
        if fps >= 50 then fpsLabel.TextColor3 = C.green
        elseif fps >= 30 then fpsLabel.TextColor3 = C.yellow
        else fpsLabel.TextColor3 = C.red end
    end
end)

-- Close/Min
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -46, 0.5, -17)
closeBtn.BackgroundColor3 = C.red; closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14; closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
corner(closeBtn, 8); stroke(closeBtn, C.red, 1, 0.3)

closeBtn.MouseButton1Click:Connect(function()
    tween(Holder, {Position = UDim2.new(0.5, -270, 1.5, 0)}, 0.4)
    task.wait(0.4)
    Gui:Destroy(); OverlayGui:Destroy()
    if weatherFolder then weatherFolder:Destroy() end
end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 34, 0, 34); minBtn.Position = UDim2.new(1, -86, 0.5, -17)
minBtn.BackgroundColor3 = C.accent2; minBtn.Text = "─"; minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 14; minBtn.AutoButtonColor = false
minBtn.Parent = titleBar
corner(minBtn, 8); stroke(minBtn, C.accent2, 1, 0.3)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then tween(Holder, {Size = UDim2.new(0, 540, 0, 76)}, 0.4, Enum.EasingStyle.Back)
    else tween(Holder, {Size = UDim2.new(0, 540, 0, 620)}, 0.4, Enum.EasingStyle.Back) end
end)

-- ═══ DRAG ═══
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Holder.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- ═══ SIDEBAR ═══
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 140, 1, -140)
sidebar.Position = UDim2.new(0, 12, 0, 80)
sidebar.BackgroundColor3 = C.card
sidebar.BorderSizePixel = 0
sidebar.Parent = Main
corner(sidebar, 14)
stroke(sidebar, C.border, 1, 0.5)

local sideScroll = Instance.new("ScrollingFrame")
sideScroll.Size = UDim2.new(1, 0, 1, 0)
sideScroll.BackgroundTransparency = 1
sideScroll.BorderSizePixel = 0
sideScroll.ScrollBarThickness = 0
sideScroll.CanvasSize = UDim2.new(0, 0, 0, 500)
sideScroll.Parent = sidebar

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 6)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sideScroll
local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 10); sidePad.PaddingBottom = UDim.new(0, 10)
sidePad.Parent = sideScroll

local tabs, tabPages = {}, {}
local tabNames = {
    {name="Color", icon="🎨", id="Color"},
    {name="Bloom", icon="✨", id="Bloom"},
    {name="Motion", icon="💨", id="Motion"},
    {name="DOF", icon="🔍", id="DOF"},
    {name="Time", icon="⏰", id="Time"},
    {name="Weather", icon="🌦", id="Weather"},
    {name="World", icon="🌫", id="World"},
    {name="FX", icon="🎞", id="FX"},
    {name="Presets", icon="🎬", id="Presets"},
    {name="Info", icon="ℹ️", id="Info"},
}

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -164, 1, -140)
content.Position = UDim2.new(0, 156, 0, 80)
content.BackgroundColor3 = C.card
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = Main
corner(content, 14)
stroke(content, C.border, 1, 0.5)

for _, info in ipairs(tabNames) do
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -4, 1, -4); page.Position = UDim2.new(0, 2, 0, 2)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = C.accent
    page.CanvasSize = UDim2.new(0, 0, 0, 800); page.Visible = false
    page.Parent = content
    tabPages[info.id] = page
end

local currentTab = nil
local function switchTab(id)
    for _, p in pairs(tabPages) do p.Visible = false end
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
    b.Size = UDim2.new(1, -16, 0, 40); b.BackgroundColor3 = C.cardLight
    b.Text = info.icon .. "  " .. info.name; b.TextColor3 = C.subtext
    b.Font = Enum.Font.GothamBold; b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left; b.AutoButtonColor = false
    b.Parent = sideScroll
    corner(b, 8)
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 14); pad.Parent = b
    b.MouseEnter:Connect(function() if currentTab ~= info.id then tween(b, {BackgroundColor3 = C.cardHover}, 0.15) end end)
    b.MouseLeave:Connect(function() if currentTab ~= info.id then tween(b, {BackgroundColor3 = C.cardLight}, 0.15) end end)
    b.MouseButton1Click:Connect(function() switchTab(info.id) end)
    tabs[info.id] = b
end

-- Status
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -24, 0, 34); statusBar.Position = UDim2.new(0, 12, 1, -46)
statusBar.BackgroundColor3 = C.card; statusBar.BorderSizePixel = 0; statusBar.Parent = Main
corner(statusBar, 10); stroke(statusBar, C.border, 1, 0.5)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 10, 0, 10); statusDot.Position = UDim2.new(0, 14, 0.5, -5)
statusDot.BackgroundColor3 = C.green; statusDot.Parent = statusBar
corner(statusDot, 5); stroke(statusDot, C.green, 2, 0.4)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -34, 1, 0); statusText.Position = UDim2.new(0, 32, 0, 0)
statusText.BackgroundTransparency = 1; statusText.Text = "🎬 Nova Cinematic Ultra ready"
statusText.TextColor3 = C.text; statusText.Font = Enum.Font.GothamSemibold
statusText.TextSize = 11; statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

local function setStatus(t, c)
    statusText.Text = t
    tween(statusDot, {BackgroundColor3 = c or C.green}, 0.2)
    local s = statusDot:FindFirstChildOfClass("UIStroke")
    if s then tween(s, {Color = c or C.green}, 0.2) end
end

task.spawn(function()
    while Gui.Parent do
        tween(statusDot, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 13, 0.5, -6)}, 1, Enum.EasingStyle.Sine)
        task.wait(1)
        tween(statusDot, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 14, 0.5, -5)}, 1, Enum.EasingStyle.Sine)
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  COMPONENTS
-- ═══════════════════════════════════════════════════════════

local function sectionLabel(parent, text, yPos)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 0, 24); f.Position = UDim2.new(0, 10, 0, yPos)
    f.BackgroundTransparency = 1; f.Parent = parent
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 4, 0, 14); line.Position = UDim2.new(0, 0, 0.5, -7)
    line.BackgroundColor3 = C.accent; line.BorderSizePixel = 0; line.Parent = f
    corner(line, 2)
    grad(line, ColorSequence.new(C.accent, C.accent2), 90)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -12, 1, 0); l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = C.accent
    l.Font = Enum.Font.GothamBold; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
end

local function createSlider(parent, text, yPos, min, max, default, decimals, callback)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, -20, 0, 60); c.Position = UDim2.new(0, 10, 0, yPos)
    c.BackgroundColor3 = C.cardLight; c.BorderSizePixel = 0; c.Parent = parent
    corner(c, 10); stroke(c, C.border, 1, 0.5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, -14, 0, 20); l.Position = UDim2.new(0, 14, 0, 8)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = C.text
    l.Font = Enum.Font.GothamSemibold; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.4, -14, 0, 20); v.Position = UDim2.new(0.6, 0, 0, 8)
    v.BackgroundTransparency = 1; v.Text = string.format("%." .. (decimals or 2) .. "f", default)
    v.TextColor3 = C.accent; v.Font = Enum.Font.GothamBold; v.TextSize = 12
    v.TextXAlignment = Enum.TextXAlignment.Right; v.Parent = c
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6); track.Position = UDim2.new(0, 14, 0, 40)
    track.BackgroundColor3 = C.bg; track.BorderSizePixel = 0; track.Parent = c
    corner(track, 3)
    local fill = Instance.new("Frame")
    local pct = (default - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0); fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0; fill.Parent = track
    corner(fill, 3)
    grad(fill, ColorSequence.new(C.accent, C.accent2), 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16); knob.Position = UDim2.new(pct, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0
    knob.ZIndex = 5; knob.Parent = track
    corner(knob, 8); stroke(knob, C.accent, 2, 0.2)
    local drag = false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 20, 0, 30); btn.Position = UDim2.new(0, -10, 0.5, -15)
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 6; btn.Parent = track
    local function upd(x)
        local ap = track.AbsolutePosition.X; local asz = track.AbsoluteSize.X
        local rx = math.clamp((x - ap) / asz, 0, 1)
        local val = min + rx * (max - min)
        if decimals == 0 then val = math.floor(val) end
        fill.Size = UDim2.new(rx, 0, 1, 0); knob.Position = UDim2.new(rx, -8, 0.5, -8)
        v.Text = string.format("%." .. (decimals or 2) .. "f", val); callback(val)
    end
    btn.MouseButton1Down:Connect(function() drag = true end)
    UIS.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then upd(inp.Position.X) end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    return c
end

local function createToggle(parent, icon, text, yPos, default, callback)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, -20, 0, 44); c.Position = UDim2.new(0, 10, 0, yPos)
    c.BackgroundColor3 = C.cardLight; c.BorderSizePixel = 0; c.Parent = parent
    corner(c, 10); stroke(c, C.border, 1, 0.5)
    local i = Instance.new("TextLabel")
    i.Size = UDim2.new(0, 26, 0, 26); i.Position = UDim2.new(0, 12, 0.5, -13)
    i.BackgroundColor3 = C.card; i.Text = icon; i.TextSize = 13; i.Parent = c
    corner(i, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, -12, 1, 0); l.Position = UDim2.new(0, 44, 0, 0)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = C.text
    l.Font = Enum.Font.GothamSemibold; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 42, 0, 22); pill.Position = UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = default and C.toggleOn or C.toggleOff
    pill.BorderSizePixel = 0; pill.Parent = c
    corner(pill, 11)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0
    knob.Parent = pill
    corner(knob, 8)
    local en = default
    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(1,0,1,0); cb.BackgroundTransparency = 1; cb.Text = ""; cb.Parent = c
    cb.MouseButton1Click:Connect(function()
        en = not en
        tween(pill, {BackgroundColor3 = en and C.toggleOn or C.toggleOff}, 0.3)
        tween(knob, {Position = en and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.3, Enum.EasingStyle.Back)
        callback(en)
    end)
end

local function createButton(parent, icon, text, yPos, col1, col2, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 40); b.Position = UDim2.new(0, 10, 0, yPos)
    b.BackgroundColor3 = col1; b.Text = icon .. "  " .. text
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
    b.TextSize = 12; b.AutoButtonColor = false; b.Parent = parent
    corner(b, 10); stroke(b, col2 or col1, 1, 0.4)
    grad(b, ColorSequence.new(col1, col2 or col1), 90)
    b.MouseEnter:Connect(function() tween(b, {Size = UDim2.new(1, -16, 0, 42)}, 0.15) end)
    b.MouseLeave:Connect(function() tween(b, {Size = UDim2.new(1, -20, 0, 40)}, 0.15) end)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function createColorPicker(parent, text, yPos, defaultColor, callback)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, -20, 0, 190); c.Position = UDim2.new(0, 10, 0, yPos)
    c.BackgroundColor3 = C.cardLight; c.BorderSizePixel = 0; c.Parent = parent
    corner(c, 10); stroke(c, C.border, 1, 0.5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, 20); l.Position = UDim2.new(0, 10, 0, 8)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = C.text
    l.Font = Enum.Font.GothamSemibold; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    local cur = defaultColor
    local h, s, v = 0, 0, 1
    local sv = Instance.new("ImageLabel")
    sv.Size = UDim2.new(0, 130, 0, 130); sv.Position = UDim2.new(0, 10, 0, 36)
    sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1); sv.Image = "rbxassetid://4155801252"
    sv.Parent = c
    corner(sv, 6); stroke(sv, C.border, 1, 0.3)
    local svCur = Instance.new("Frame")
    svCur.Size = UDim2.new(0, 10, 0, 10); svCur.BackgroundColor3 = Color3.new(1,1,1)
    svCur.BorderSizePixel = 0; svCur.AnchorPoint = Vector2.new(0.5, 0.5)
    svCur.Position = UDim2.new(1, 0, 0, 0); svCur.Parent = sv
    corner(svCur, 5); stroke(svCur, Color3.new(0,0,0), 1, 0)
    local hue = Instance.new("Frame")
    hue.Size = UDim2.new(0, 22, 0, 130); hue.Position = UDim2.new(0, 150, 0, 36)
    hue.BorderSizePixel = 0; hue.Parent = c
    corner(hue, 6)
    grad(hue, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
    }, 90)
    local hueCur = Instance.new("Frame")
    hueCur.Size = UDim2.new(1, 4, 0, 3); hueCur.Position = UDim2.new(0, -2, 0, 0)
    hueCur.BackgroundColor3 = Color3.new(1,1,1); hueCur.BorderSizePixel = 0
    hueCur.Parent = hue
    stroke(hueCur, Color3.new(0,0,0), 1, 0)
    local prev = Instance.new("Frame")
    prev.Size = UDim2.new(0, 90, 0, 50); prev.Position = UDim2.new(0, 190, 0, 36)
    prev.BackgroundColor3 = defaultColor; prev.BorderSizePixel = 0; prev.Parent = c
    corner(prev, 6); stroke(prev, C.accent, 1.5, 0.2)
    local rgb = Instance.new("TextLabel")
    rgb.Size = UDim2.new(0, 90, 0, 70); rgb.Position = UDim2.new(0, 190, 0, 96)
    rgb.BackgroundTransparency = 1
    rgb.Text = string.format("R %d\nG %d\nB %d", math.floor(defaultColor.R*255), math.floor(defaultColor.G*255), math.floor(defaultColor.B*255))
    rgb.TextColor3 = C.subtext; rgb.Font = Enum.Font.GothamSemibold
    rgb.TextSize = 10; rgb.TextXAlignment = Enum.TextXAlignment.Left
    rgb.TextYAlignment = Enum.TextYAlignment.Top; rgb.Parent = c
    local function updC()
        cur = Color3.fromHSV(h, s, v)
        prev.BackgroundColor3 = cur; sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        rgb.Text = string.format("R %d\nG %d\nB %d", math.floor(cur.R*255), math.floor(cur.G*255), math.floor(cur.B*255))
        callback(cur)
    end
    local svD, hueD = false, false
    local svB = Instance.new("TextButton") svB.Size = UDim2.new(1,0,1,0) svB.BackgroundTransparency = 1 svB.Text = "" svB.Parent = sv
    local hueB = Instance.new("TextButton") hueB.Size = UDim2.new(1,0,1,0) hueB.BackgroundTransparency = 1 hueB.Text = "" hueB.Parent = hue
    svB.MouseButton1Down:Connect(function() svD = true end)
    hueB.MouseButton1Down:Connect(function() hueD = true end)
    UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if svD then
            local ap = sv.AbsolutePosition; local asz = sv.AbsoluteSize
            local rx = math.clamp((inp.Position.X - ap.X) / asz.X, 0, 1)
            local ry = math.clamp((inp.Position.Y - ap.Y) / asz.Y, 0, 1)
            s = rx; v = 1 - ry; svCur.Position = UDim2.new(rx, 0, ry, 0); updC()
        end
        if hueD then
            local ap = hue.AbsolutePosition; local asz = hue.AbsoluteSize
            local ry = math.clamp((inp.Position.Y - ap.Y) / asz.Y, 0, 1)
            h = ry; hueCur.Position = UDim2.new(0, -2, ry, -1); updC()
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then svD = false hueD = false end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: COLOR
-- ═══════════════════════════════════════════════════════════
local colorPage = tabPages["Color"]
colorPage.CanvasSize = UDim2.new(0, 0, 0, 620)

sectionLabel(colorPage, "★ COLOR CORRECTION", 5)
createSlider(colorPage, "Contrast", 32, -1, 1, 0, 2, function(v) Color.Contrast = v end)
createSlider(colorPage, "Saturation", 98, -1, 5, 0, 2, function(v) Color.Saturation = v end)
createSlider(colorPage, "Brightness", 164, -1, 1, 0, 2, function(v) Color.Brightness = v end)
createSlider(colorPage, "Exposure", 230, -3, 3, 0, 2, function(v) Lighting.ExposureCompensation = v end)

sectionLabel(colorPage, "★ COLOR TEMPERATURE", 306)
createSlider(colorPage, "Temperature (Cool↔Warm)", 332, -100, 100, 0, 0, function(val)
    local warm = val / 100
    if warm > 0 then
        Color.TintColor = Color3.new(1, 1 - warm*0.15, 1 - warm*0.3)
    else
        Color.TintColor = Color3.new(1 + warm*0.3, 1 + warm*0.15, 1)
    end
end)

sectionLabel(colorPage, "★ CUSTOM TINT", 408)
createColorPicker(colorPage, "Tint Color:", 434, Color3.new(1,1,1), function(c) Color.TintColor = c end)

-- ═══════════════════════════════════════════════════════════
--  TAB: BLOOM
-- ═══════════════════════════════════════════════════════════
local bloomPage = tabPages["Bloom"]
bloomPage.CanvasSize = UDim2.new(0, 0, 0, 280)

sectionLabel(bloomPage, "★ BLOOM (GLOW)", 5)
createSlider(bloomPage, "Intensity", 32, 0, 3, 0.4, 2, function(v) Bloom.Intensity = v end)
createSlider(bloomPage, "Size", 98, 0, 56, 24, 0, function(v) Bloom.Size = v end)
createSlider(bloomPage, "Threshold", 164, 0, 2, 0.95, 2, function(v) Bloom.Threshold = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: MOTION BLUR (dedicated)
-- ═══════════════════════════════════════════════════════════
local motionPage = tabPages["Motion"]
motionPage.CanvasSize = UDim2.new(0, 0, 0, 340)

sectionLabel(motionPage, "★ MOTION BLUR PRO", 5)
createToggle(motionPage, "💨", "Enable Motion Blur", 32, false, function(s)
    motionBlurEnabled = s
    if not s then MotionBlur.Size = 0; cameraHistory = {} end
    setStatus(s and "💨 Motion blur active" or "💨 Motion blur off", s and C.green or C.muted)
end)
createSlider(motionPage, "Blur Strength", 82, 0, 5, 0.5, 2, function(v) motionBlurStrength = v end)
createSlider(motionPage, "Quality (Samples)", 148, 2, 16, 8, 0, function(v) motionBlurQuality = v end)

sectionLabel(motionPage, "★ STATIC BLUR", 224)
createSlider(motionPage, "Static Blur", 250, 0, 56, 0, 0, function(v) Blur.Size = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: DOF
-- ═══════════════════════════════════════════════════════════
local dofPage = tabPages["DOF"]
dofPage.CanvasSize = UDim2.new(0, 0, 0, 340)

sectionLabel(dofPage, "★ DEPTH OF FIELD", 5)
createSlider(dofPage, "Far Intensity", 32, 0, 1, 0, 2, function(v) DOF.FarIntensity = v end)
createSlider(dofPage, "Near Intensity", 98, 0, 1, 0, 2, function(v) DOF.NearIntensity = v end)
createSlider(dofPage, "Focus Distance", 164, 0, 500, 50, 0, function(v) DOF.FocusDistance = v end)
createSlider(dofPage, "In-Focus Radius", 230, 0, 500, 50, 0, function(v) DOF.InFocusRadius = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: TIME OF DAY
-- ═══════════════════════════════════════════════════════════
local timePage = tabPages["Time"]
timePage.CanvasSize = UDim2.new(0, 0, 0, 400)

sectionLabel(timePage, "★ TIME OF DAY", 5)

local timeDisplay = Instance.new("Frame")
timeDisplay.Size = UDim2.new(1, -20, 0, 80)
timeDisplay.Position = UDim2.new(0, 10, 0, 32)
timeDisplay.BackgroundColor3 = C.cardLight
timeDisplay.BorderSizePixel = 0
timeDisplay.Parent = timePage
corner(timeDisplay, 10)
stroke(timeDisplay, C.border, 1, 0.5)

local timeIcon = Instance.new("TextLabel")
timeIcon.Size = UDim2.new(0, 60, 0, 60)
timeIcon.Position = UDim2.new(0, 10, 0.5, -30)
timeIcon.BackgroundTransparency = 1
timeIcon.Text = "🌅"
timeIcon.TextSize = 40
timeIcon.Parent = timeDisplay

local timeText = Instance.new("TextLabel")
timeText.Size = UDim2.new(1, -80, 0, 30)
timeText.Position = UDim2.new(0, 76, 0, 12)
timeText.BackgroundTransparency = 1
timeText.Text = "12:00"
timeText.TextColor3 = C.text
timeText.Font = Enum.Font.GothamBlack
timeText.TextSize = 24
timeText.TextXAlignment = Enum.TextXAlignment.Left
timeText.Parent = timeDisplay

local timeSubText = Instance.new("TextLabel")
timeSubText.Size = UDim2.new(1, -80, 0, 20)
timeSubText.Position = UDim2.new(0, 76, 0, 42)
timeSubText.BackgroundTransparency = 1
timeSubText.Text = "Midday"
timeSubText.TextColor3 = C.subtext
timeSubText.Font = Enum.Font.GothamSemibold
timeSubText.TextSize = 11
timeSubText.TextXAlignment = Enum.TextXAlignment.Left
timeSubText.Parent = timeDisplay

local function getTimeInfo(hour)
    if hour < 5 then return "🌙", "Night", C.purple end
    if hour < 7 then return "🌄", "Dawn", C.accent3 end
    if hour < 11 then return "🌅", "Morning", C.accent2 end
    if hour < 14 then return "☀️", "Midday", C.yellow end
    if hour < 17 then return "🌤", "Afternoon", C.accent2 end
    if hour < 19 then return "🌇", "Sunset", C.accent end
    if hour < 21 then return "🌆", "Evening", C.purple end
    return "🌙", "Night", C.purple
end

createSlider(timePage, "Time (Hours)", 124, 0, 24, 12, 1, function(v)
    Lighting.ClockTime = v
    local icon, name, col = getTimeInfo(v)
    timeIcon.Text = icon
    local h = math.floor(v)
    local m = math.floor((v - h) * 60)
    timeText.Text = string.format("%02d:%02d", h, m)
    timeSubText.Text = name
    tween(timeText, {TextColor3 = col}, 0.3)
end)

sectionLabel(timePage, "★ QUICK TIMES", 200)
createButton(timePage, "🌅", "Sunrise (6:30)", 226, C.accent3, C.accent2, function()
    Lighting.ClockTime = 6.5
    setStatus("⏰ Set to Sunrise", C.accent2)
end)
createButton(timePage, "☀️", "Midday (12:00)", 274, C.yellow, C.accent2, function()
    Lighting.ClockTime = 12
    setStatus("⏰ Set to Midday", C.yellow)
end)
createButton(timePage, "🌇", "Sunset (18:00)", 322, C.accent, C.accent3, function()
    Lighting.ClockTime = 18
    setStatus("⏰ Set to Sunset", C.accent)
end)
createButton(timePage, "🌙", "Night (23:00)", 370, C.purple, Color3.fromRGB(80, 60, 180), function()
    Lighting.ClockTime = 23
    setStatus("⏰ Set to Night", C.purple)
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: WEATHER
-- ═══════════════════════════════════════════════════════════
local weatherPage = tabPages["Weather"]
weatherPage.CanvasSize = UDim2.new(0, 0, 0, 400)

sectionLabel(weatherPage, "★ WEATHER EFFECTS", 5)

local function clearWeather()
    if weatherFolder then weatherFolder:Destroy(); weatherFolder = nil end
    currentWeather = "None"
end

local function createWeather(type_)
    clearWeather()
    weatherFolder = Instance.new("Folder")
    weatherFolder.Name = "NovaWeatherFolder"
    weatherFolder.Parent = workspace
    
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    if type_ == "Rain" then
        local attach = Instance.new("Attachment")
        attach.Parent = char.HumanoidRootPart
        attach.Position = Vector3.new(0, 30, 0)
        
        local rain = Instance.new("ParticleEmitter")
        rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        rain.Rate = 500
        rain.Lifetime = NumberRange.new(1, 1.5)
        rain.Speed = NumberRange.new(80, 100)
        rain.SpreadAngle = Vector2.new(5, 5)
        rain.Size = NumberSequence.new(0.3)
        rain.Color = ColorSequence.new(Color3.fromRGB(150, 180, 220))
        rain.Transparency = NumberSequence.new(0.3)
        rain.LightEmission = 0.5
        rain.EmissionDirection = Enum.NormalId.Bottom
        rain.Parent = attach
        weatherFolder:SetAttribute("Attach", true)
        rain:Clone().Parent = attach
        attach.Parent = weatherFolder
        
    elseif type_ == "Snow" then
        local attach = Instance.new("Attachment")
        attach.Parent = char.HumanoidRootPart
        attach.Position = Vector3.new(0, 40, 0)
        
        local snow = Instance.new("ParticleEmitter")
        snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        snow.Rate = 300
        snow.Lifetime = NumberRange.new(3, 5)
        snow.Speed = NumberRange.new(5, 15)
        snow.SpreadAngle = Vector2.new(180, 180)
        snow.Size = NumberSequence.new(0.5)
        snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
        snow.Transparency = NumberSequence.new(0.2)
        snow.Rotation = NumberRange.new(0, 360)
        snow.RotSpeed = NumberRange.new(-90, 90)
        snow.Parent = attach
        attach.Parent = weatherFolder
        
    elseif type_ == "Sandstorm" then
        local attach = Instance.new("Attachment")
        attach.Parent = char.HumanoidRootPart
        
        local sand = Instance.new("ParticleEmitter")
        sand.Texture = "rbxasset://textures/particles/smoke_main.dds"
        sand.Rate = 200
        sand.Lifetime = NumberRange.new(2, 4)
        sand.Speed = NumberRange.new(40, 60)
        sand.SpreadAngle = Vector2.new(45, 45)
        sand.Size = NumberSequence.new(15)
        sand.Color = ColorSequence.new(Color3.fromRGB(210, 180, 140))
        sand.Transparency = NumberSequence.new(0.6)
        sand.Parent = attach
        attach.Parent = weatherFolder
    end
    
    currentWeather = type_
end

createButton(weatherPage, "🌧", "Rain", 32, C.cyan, Color3.fromRGB(80, 140, 200), function()
    createWeather("Rain")
    setStatus("🌧 Rain enabled", C.cyan)
end)
createButton(weatherPage, "❄️", "Snow", 82, Color3.fromRGB(220, 230, 255), Color3.fromRGB(180, 200, 240), function()
    createWeather("Snow")
    setStatus("❄️ Snow enabled", C.cyan)
end)
createButton(weatherPage, "🌪", "Sandstorm", 132, C.accent2, Color3.fromRGB(180, 130, 60), function()
    createWeather("Sandstorm")
    setStatus("🌪 Sandstorm enabled", C.accent2)
end)
createButton(weatherPage, "☀️", "Clear Weather", 182, C.green, Color3.fromRGB(40, 180, 100), function()
    clearWeather()
    setStatus("☀️ Weather cleared", C.green)
end)

sectionLabel(weatherPage, "★ FOG (WEATHER FEEL)", 244)
createSlider(weatherPage, "Fog Density (End)", 270, 0, 5000, 5000, 0, function(v) Lighting.FogEnd = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: WORLD
-- ═══════════════════════════════════════════════════════════
local worldPage = tabPages["World"]
worldPage.CanvasSize = UDim2.new(0, 0, 0, 620)

sectionLabel(worldPage, "★ ATMOSPHERE", 5)
createSlider(worldPage, "Density", 32, 0, 1, 0.3, 2, function(v) Atmosphere.Density = v end)
createSlider(worldPage, "Offset", 98, 0, 1, 0.25, 2, function(v) Atmosphere.Offset = v end)
createSlider(worldPage, "Glare", 164, 0, 3, 0, 2, function(v) Atmosphere.Glare = v end)
createSlider(worldPage, "Haze", 230, 0, 3, 0, 2, function(v) Atmosphere.Haze = v end)

sectionLabel(worldPage, "★ SUN RAYS", 306)
createSlider(worldPage, "Ray Intensity", 332, 0, 1, 0.1, 2, function(v) SunRays.Intensity = v end)
createSlider(worldPage, "Ray Spread", 398, 0, 1, 0.5, 2, function(v) SunRays.Spread = v end)

sectionLabel(worldPage, "★ FOG CONTROL", 474)
createSlider(worldPage, "Fog End Distance", 500, 0, 10000, 5000, 0, function(v) Lighting.FogEnd = v end)
createSlider(worldPage, "Fog Start", 566, 0, 5000, 0, 0, function(v) Lighting.FogStart = v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: FX (Overlays + New Effects)
-- ═══════════════════════════════════════════════════════════
local fxPage = tabPages["FX"]
fxPage.CanvasSize = UDim2.new(0, 0, 0, 800)

sectionLabel(fxPage, "★ VIGNETTE", 5)
createSlider(fxPage, "Vignette Intensity", 32, 0, 1, 0, 2, function(v) Vignette.ImageTransparency = 1 - v end)

sectionLabel(fxPage, "★ FILM GRAIN", 108)
createSlider(fxPage, "Grain Intensity", 134, 0, 1, 0, 2, function(v) FilmGrain.ImageTransparency = 1 - v * 0.5 end)

sectionLabel(fxPage, "★ CHROMATIC ABERRATION", 210)
createSlider(fxPage, "Chromatic Strength", 236, 0, 30, 0, 0, function(v)
    if v == 0 then ChromaR.BackgroundTransparency = 1; ChromaB.BackgroundTransparency = 1
    else
        ChromaR.BackgroundTransparency = 1 - (v/30) * 0.15
        ChromaB.BackgroundTransparency = 1 - (v/30) * 0.15
        ChromaR.Position = UDim2.new(0, -v, 0, 0); ChromaB.Position = UDim2.new(0, v, 0, 0)
    end
end)

sectionLabel(fxPage, "★ LENS FLARE", 312)
createSlider(fxPage, "Lens Flare Intensity", 338, 0, 1, 0, 2, function(v) LensFlare.ImageTransparency = 1 - v end)

sectionLabel(fxPage, "★ LIGHT LEAK", 414)
createSlider(fxPage, "Light Leak Intensity", 440, 0, 1, 0, 2, function(v)
    leakGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1 - v * 0.5),
        NumberSequenceKeypoint.new(0.5, 1 - v * 0.3),
        NumberSequenceKeypoint.new(1, 1)
    }
    if v > 0 then LightLeak.BackgroundColor3 = Color3.new(1,1,1); LightLeak.BackgroundTransparency = 1 - v * 0.1
    else LightLeak.BackgroundTransparency = 1 end
end)

sectionLabel(fxPage, "★ FILM BURN", 516)
createSlider(fxPage, "Film Burn Intensity", 542, 0, 1, 0, 2, function(v) FilmBurn.ImageTransparency = 1 - v * 0.6 end)

sectionLabel(fxPage, "★ LETTERBOX (CINEMATIC BARS)", 618)
createSlider(fxPage, "Bar Size", 644, 0, 200, 0, 0, function(v)
    tween(LetterTop, {Size = UDim2.new(1, 0, 0, v)}, 0.3)
    tween(LetterBot, {Size = UDim2.new(1, 0, 0, v)}, 0.3)
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: PRESETS
-- ═══════════════════════════════════════════════════════════
local presetPage = tabPages["Presets"]
presetPage.CanvasSize = UDim2.new(0, 0, 0, 1050)

local presets = {
    ["🎬 Cinematic"] = {c=0.15,sa=0.1,br=0.02,tn=Color3.fromRGB(255,240,220),bi=0.6,bs=30,bt=0.85,mb=true,ms=0.5,dfF=0.15,dfC=80,dfR=60,aD=0.35,aO=0.3,su=0.15,ss=0.6,fg=5000,vi=0.3,gr=0.15,ch=0,le=0,lk=0,fb=0,lb=0,ex=0,tm=13.5},
    ["🌅 Golden Hour"] = {c=0.2,sa=0.25,br=0.05,tn=Color3.fromRGB(255,210,160),bi=0.8,bs=40,bt=0.8,mb=true,ms=0.4,dfF=0.1,dfC=100,dfR=80,aD=0.4,aO=0.4,su=0.4,ss=0.8,fg=3000,vi=0.4,gr=0.1,ch=0,le=0.4,lk=0.3,fb=0,lb=0,ex=0.2,tm=6.8},
    ["❄️ Cold Winter"] = {c=0.25,sa=-0.15,br=0.03,tn=Color3.fromRGB(200,220,255),bi=0.5,bs=20,bt=0.9,mb=true,ms=0.3,dfF=0.05,dfC=120,dfR=100,aD=0.6,aO=0.2,su=0.05,ss=0.4,fg=2000,vi=0.5,gr=0.05,ch=0,le=0,lk=0,fb=0,lb=0,ex=0.1,tm=15},
    ["🌙 Dark Horror"] = {c=0.4,sa=-0.3,br=-0.15,tn=Color3.fromRGB(180,180,210),bi=0.3,bs=15,bt=0.95,mb=true,ms=0.7,dfF=0.3,dfC=40,dfR=30,aD=0.7,aO=0.1,su=0,ss=0,fg=800,vi=0.9,gr=0.6,ch=8,le=0,lk=0,fb=0,lb=0,ex=-0.5,tm=2},
    ["🌈 Vibrant"] = {c=0.2,sa=0.4,br=0.05,tn=Color3.new(1,1,1),bi=0.7,bs=25,bt=0.85,mb=false,ms=0,dfF=0,dfC=50,dfR=50,aD=0.2,aO=0.3,su=0.2,ss=0.7,fg=8000,vi=0,gr=0,ch=0,le=0,lk=0,fb=0,lb=0,ex=0.1,tm=12},
    ["🎥 Classic Movie"] = {c=0.3,sa=-0.1,br=0,tn=Color3.fromRGB(230,235,255),bi=0.5,bs=20,bt=0.9,mb=true,ms=0.6,dfF=0.2,dfC=60,dfR=50,aD=0.4,aO=0.25,su=0.1,ss=0.5,fg=3500,vi=0.5,gr=0.25,ch=0,le=0.1,lk=0.15,fb=0,lb=100,ex=0,tm=14},
    ["☀️ Bright Sunny"] = {c=0.15,sa=0.2,br=0.1,tn=Color3.fromRGB(255,250,235),bi=1.2,bs=45,bt=0.75,mb=false,ms=0,dfF=0,dfC=100,dfR=80,aD=0.15,aO=0.35,su=0.5,ss=0.9,fg=10000,vi=0.1,gr=0,ch=0,le=0.5,lk=0.1,fb=0,lb=0,ex=0.3,tm=13},
    ["🌸 Anime"] = {c=0.1,sa=0.5,br=0.08,tn=Color3.fromRGB(255,235,245),bi=1.0,bs=35,bt=0.7,mb=false,ms=0,dfF=0.05,dfC=80,dfR=70,aD=0.25,aO=0.4,su=0.2,ss=0.6,fg=6000,vi=0.2,gr=0,ch=0,le=0.2,lk=0.1,fb=0,lb=0,ex=0.15,tm=14},
    ["📺 Retro VHS"] = {c=0.2,sa=0.15,br=0.05,tn=Color3.fromRGB(255,220,220),bi=0.7,bs=25,bt=0.8,mb=true,ms=0.4,dfF=0.05,dfC=100,dfR=80,aD=0.3,aO=0.3,su=0.1,ss=0.5,fg=4000,vi=0.4,gr=0.4,ch=10,le=0,lk=0.2,fb=0.3,lb=0,ex=0,tm=15},
    ["🎮 Cyberpunk"] = {c=0.35,sa=0.3,br=-0.05,tn=Color3.fromRGB(200,180,255),bi=1.5,bs=50,bt=0.7,mb=true,ms=0.5,dfF=0.15,dfC=70,dfR=60,aD=0.4,aO=0.2,su=0.05,ss=0.4,fg=2500,vi=0.5,gr=0.15,ch=6,le=0,lk=0.2,fb=0,lb=0,ex=0.1,tm=21},
    ["🔥 Blockbuster"] = {c=0.35,sa=0.1,br=0.05,tn=Color3.fromRGB(255,220,190),bi=0.9,bs=35,bt=0.8,mb=true,ms=0.6,dfF=0.2,dfC=70,dfR=50,aD=0.35,aO=0.3,su=0.3,ss=0.75,fg=4500,vi=0.55,gr=0.2,ch=3,le=0.3,lk=0.15,fb=0.1,lb=120,ex=0.15,tm=17.5},
    ["🌊 Underwater"] = {c=0.2,sa=0.1,br=-0.05,tn=Color3.fromRGB(150,200,230),bi=0.6,bs=30,bt=0.85,mb=true,ms=0.5,dfF=0.5,dfC=30,dfR=25,aD=0.8,aO=0.15,su=0.1,ss=0.5,fg=1500,vi=0.4,gr=0.1,ch=4,le=0,lk=0,fb=0,lb=0,ex=-0.1,tm=12},
    ["🌵 Desert"] = {c=0.25,sa=0.15,br=0.15,tn=Color3.fromRGB(255,220,180),bi=1.0,bs=40,bt=0.75,mb=true,ms=0.4,dfF=0.1,dfC=150,dfR=120,aD=0.35,aO=0.3,su=0.5,ss=0.85,fg=5000,vi=0.3,gr=0.1,ch=0,le=0.6,lk=0.15,fb=0,lb=0,ex=0.4,tm=13},
    ["🌌 Space"] = {c=0.4,sa=-0.2,br=-0.2,tn=Color3.fromRGB(180,190,230),bi=1.5,bs=40,bt=0.6,mb=true,ms=0.3,dfF=0.1,dfC=100,dfR=80,aD=0,aO=0,su=0.05,ss=0.3,fg=10000,vi=0.6,gr=0.2,ch=5,le=0,lk=0,fb=0,lb=0,ex=-0.3,tm=0},
    ["🏔 Mountain"] = {c=0.25,sa=0.2,br=0.05,tn=Color3.fromRGB(240,245,255),bi=0.8,bs=30,bt=0.85,mb=true,ms=0.3,dfF=0.1,dfC=200,dfR=150,aD=0.5,aO=0.35,su=0.3,ss=0.7,fg=3500,vi=0.3,gr=0.1,ch=0,le=0.2,lk=0,fb=0,lb=0,ex=0.15,tm=8},
    ["🍂 Autumn"] = {c=0.2,sa=0.3,br=0.03,tn=Color3.fromRGB(255,200,150),bi=0.7,bs=32,bt=0.85,mb=true,ms=0.3,dfF=0.1,dfC=80,dfR=70,aD=0.4,aO=0.35,su=0.35,ss=0.7,fg=4000,vi=0.4,gr=0.15,ch=0,le=0.3,lk=0.2,fb=0,lb=0,ex=0.1,tm=16.5},
    ["🌆 Neon City"] = {c=0.3,sa=0.4,br=-0.05,tn=Color3.fromRGB(220,200,255),bi=1.8,bs=45,bt=0.65,mb=true,ms=0.5,dfF=0.2,dfC=60,dfR=50,aD=0.5,aO=0.2,su=0.05,ss=0.4,fg=2000,vi=0.5,gr=0.1,ch=8,le=0,lk=0.15,fb=0,lb=0,ex=0.05,tm=22},
    ["🌫 Foggy"] = {c=0.15,sa=-0.1,br=0.03,tn=Color3.fromRGB(230,235,240),bi=0.5,bs=25,bt=0.9,mb=true,ms=0.3,dfF=0.4,dfC=40,dfR=30,aD=0.8,aO=0.2,su=0.05,ss=0.5,fg=800,vi=0.5,gr=0.1,ch=0,le=0,lk=0,fb=0,lb=0,ex=0,tm=7},
    ["🎨 Painting"] = {c=0.15,sa=0.5,br=0.1,tn=Color3.fromRGB(255,240,220),bi=1.2,bs=45,bt=0.7,mb=false,ms=0,dfF=0.1,dfC=100,dfR=80,aD=0.3,aO=0.3,su=0.3,ss=0.7,fg=6000,vi=0.3,gr=0.3,ch=0,le=0.3,lk=0.2,fb=0,lb=0,ex=0.2,tm=11},
    ["🔴 Blood Moon"] = {c=0.4,sa=-0.5,br=-0.1,tn=Color3.fromRGB(255,150,150),bi=0.6,bs=30,bt=0.85,mb=true,ms=0.6,dfF=0.2,dfC=50,dfR=40,aD=0.6,aO=0.15,su=0.1,ss=0.6,fg=1500,vi=0.7,gr=0.3,ch=6,le=0,lk=0.2,fb=0,lb=0,ex=-0.2,tm=0.5},
    ["🚫 Reset"] = {c=0,sa=0,br=0,tn=Color3.new(1,1,1),bi=0.4,bs=24,bt=0.95,mb=false,ms=0,dfF=0,dfC=50,dfR=50,aD=0.3,aO=0.25,su=0.1,ss=0.5,fg=5000,vi=0,gr=0,ch=0,le=0,lk=0,fb=0,lb=0,ex=0,tm=14},
}

local function applyPreset(p)
    Color.Contrast = p.c; Color.Saturation = p.sa; Color.Brightness = p.br
    Color.TintColor = p.tn
    Bloom.Intensity = p.bi; Bloom.Size = p.bs; Bloom.Threshold = p.bt
    motionBlurEnabled = p.mb; motionBlurStrength = p.ms
    DOF.FarIntensity = p.dfF; DOF.FocusDistance = p.dfC; DOF.InFocusRadius = p.dfR
    Atmosphere.Density = p.aD; Atmosphere.Offset = p.aO
    SunRays.Intensity = p.su; SunRays.Spread = p.ss
    Lighting.FogEnd = p.fg; Lighting.ExposureCompensation = p.ex
    Lighting.ClockTime = p.tm
    if not p.mb then MotionBlur.Size = 0 end
    Vignette.ImageTransparency = 1 - p.vi
    FilmGrain.ImageTransparency = 1 - p.gr * 0.5
    if p.ch == 0 then ChromaR.BackgroundTransparency = 1; ChromaB.BackgroundTransparency = 1
    else
        ChromaR.BackgroundTransparency = 1 - (p.ch/30) * 0.15
        ChromaB.BackgroundTransparency = 1 - (p.ch/30) * 0.15
        ChromaR.Position = UDim2.new(0, -p.ch, 0, 0); ChromaB.Position = UDim2.new(0, p.ch, 0, 0)
    end
    LensFlare.ImageTransparency = 1 - p.le
    if p.lk > 0 then
        leakGrad.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1 - p.lk * 0.5),
            NumberSequenceKeypoint.new(0.5, 1 - p.lk * 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }
        LightLeak.BackgroundColor3 = Color3.new(1,1,1)
        LightLeak.BackgroundTransparency = 1 - p.lk * 0.1
    else leakGrad.Transparency = NumberSequence.new(1); LightLeak.BackgroundTransparency = 1 end
    FilmBurn.ImageTransparency = 1 - p.fb * 0.6
    tween(LetterTop, {Size = UDim2.new(1, 0, 0, p.lb)}, 0.3)
    tween(LetterBot, {Size = UDim2.new(1, 0, 0, p.lb)}, 0.3)
end

sectionLabel(presetPage, "★ CINEMATIC PRESETS", 5)

local pOrder = {"🎬 Cinematic","🌅 Golden Hour","❄️ Cold Winter","🌙 Dark Horror","🌈 Vibrant","🎥 Classic Movie","☀️ Bright Sunny","🌸 Anime","📺 Retro VHS","🎮 Cyberpunk","🔥 Blockbuster","🌊 Underwater","🌵 Desert","🌌 Space","🏔 Mountain","🍂 Autumn","🌆 Neon City","🌫 Foggy","🎨 Painting","🔴 Blood Moon","🚫 Reset"}
local pCols = {
    {C.accent, C.accent2}, {Color3.fromRGB(255,180,80), Color3.fromRGB(255,120,40)},
    {Color3.fromRGB(120,180,240), Color3.fromRGB(80,140,220)}, {Color3.fromRGB(80,80,120), Color3.fromRGB(40,40,80)},
    {Color3.fromRGB(255,100,200), C.purple}, {Color3.fromRGB(180,100,200), Color3.fromRGB(120,80,180)},
    {C.yellow, Color3.fromRGB(255,180,60)}, {Color3.fromRGB(255,150,200), Color3.fromRGB(255,100,180)},
    {Color3.fromRGB(220,150,150), Color3.fromRGB(180,100,100)}, {C.purple, C.cyan},
    {C.red, C.accent2}, {C.cyan, Color3.fromRGB(80,180,220)},
    {Color3.fromRGB(230,180,100), Color3.fromRGB(200,140,60)}, {C.purple, Color3.fromRGB(50,50,100)},
    {Color3.fromRGB(200,220,240), Color3.fromRGB(150,180,220)}, {Color3.fromRGB(255,150,80), Color3.fromRGB(200,100,50)},
    {C.accent3, C.purple}, {Color3.fromRGB(180,180,200), Color3.fromRGB(140,140,170)},
    {Color3.fromRGB(255,200,150), Color3.fromRGB(220,150,100)}, {C.red, Color3.fromRGB(100,20,20)},
    {C.red, Color3.fromRGB(160,40,40)},
}

for i, name in ipairs(pOrder) do
    local yOff = 32 + (i - 1) * 48
    local col = pCols[i] or {C.accent, C.accent2}
    createButton(presetPage, "", name, yOff, col[1], col[2], function()
        applyPreset(presets[name])
        setStatus("✓ Applied: " .. name, col[1])
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: INFO
-- ═══════════════════════════════════════════════════════════
local infoPage = tabPages["Info"]
infoPage.CanvasSize = UDim2.new(0, 0, 0, 400)

sectionLabel(infoPage, "★ NOVA CINEMATIC ULTRA", 5)

local infoBox = Instance.new("Frame")
infoBox.Size = UDim2.new(1, -20, 0, 340)
infoBox.Position = UDim2.new(0, 10, 0, 32)
infoBox.BackgroundColor3 = C.cardLight
infoBox.BorderSizePixel = 0
infoBox.Parent = infoPage
corner(infoBox, 10)
stroke(infoBox, C.accent, 1, 0.4)

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -20, 1, -20)
infoText.Position = UDim2.new(0, 10, 0, 10)
infoText.BackgroundTransparency = 1
infoText.Text = "🎬 NOVA CINEMATIC ULTRA v3.0\n\n★ 21 built-in cinematic presets\n★ Beautiful accumulation motion blur\n★ Time of day control (0-24h)\n★ Weather system (rain/snow/sand)\n★ Color temperature (warm/cool)\n★ Lens flare & light leaks\n★ Film burn & retro VHS effects\n★ Full HSV color picker\n★ Live FPS counter\n\n🎮 KEYBINDS:\n★ ]  → Toggle UI\n★ Drag title bar to move\n\n⚙️ TIP: Try 'Cinematic' or 'Cyberpunk' first!\n\nMade with ❤️ by Nova"
infoText.TextColor3 = C.text
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 12
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextWrapped = true
infoText.Parent = infoBox

-- Activate default
switchTab("Color")

-- ═══════════════════════════════════════════════════════════
--  KEYBIND
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
Holder.Position = UDim2.new(0.5, -270, -1.5, 0)
tween(Holder, {Position = UDim2.new(0.5, -270, 0.5, -310)}, 0.8, Enum.EasingStyle.Back)

print("═══════════════════════════════════════")
print("  🎬 NOVA CINEMATIC ULTRA v3.0")
print("  💨 Beautiful Motion Blur | ⏰ Time of Day")
print("  🌦 Weather | ✨ Lens Flare | 21 Presets")
print("  Press ] to toggle UI")
print("═══════════════════════════════════════")
