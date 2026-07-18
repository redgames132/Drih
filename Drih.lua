-- =============================================
-- DRIH v4.0 - Luxury Edition
-- Beautiful glass design | Ultra clean
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local VU = game:GetService("VirtualUser")
local WS = game:GetService("Workspace")

local plr = Players.LocalPlayer
local pg = plr.PlayerGui
local char = plr.Character or plr.CharacterAdded:Wait()
plr.CharacterAdded:Connect(function(c) char = c task.wait(1) end)
plr.Idled:Connect(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)

local C = {
    Spd=0,Lim=0,Grav=100,Drft=false,DrftAmt=95,RearL=70,FrontG=80,
    BrkPow=50,HBrk=false,Nitro=false,NitroF=150,AFlip=true,FlipStr=60,
    Jump=false,JumpPow=75,Fly=false,FlySpd=80,
    Spin=false,SpinSpd=30,Bounce=false,Invis=false,Trail=false,
    Car=nil,Root=nil,Seat=nil,Inj={},OG=WS.Gravity,
}

pcall(function() if pg:FindFirstChild("DrihGUI") then pg.DrihGUI:Destroy() end end)
local SG = Instance.new("ScreenGui")
SG.Name = "DrihGUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = pg

-- =============================================
-- PALETTE
-- =============================================
local P = {
    pri = Color3.fromRGB(108, 92, 231),    -- Soft violet
    sec = Color3.fromRGB(162, 155, 254),    -- Light lavender
    acc = Color3.fromRGB(253, 121, 168),    -- Soft pink
    bg1 = Color3.fromRGB(13, 13, 20),       -- Deep dark
    bg2 = Color3.fromRGB(20, 20, 30),       -- Card dark
    bg3 = Color3.fromRGB(28, 28, 40),       -- Lighter card
    tx1 = Color3.fromRGB(235, 235, 245),    -- White text
    tx2 = Color3.fromRGB(155, 155, 180),    -- Dim text
    tx3 = Color3.fromRGB(100, 100, 125),    -- Subtle text
    grn = Color3.fromRGB(85, 239, 196),     -- Mint green
    red = Color3.fromRGB(255, 107, 107),    -- Soft red
    orn = Color3.fromRGB(255, 177, 66),     -- Warm orange
    blu = Color3.fromRGB(116, 185, 255),    -- Sky blue
}

-- =============================================
-- LOG & NOTIFY
-- =============================================
local logP, logC = nil, 0

local function lg(m, c)
    if not logP then return end
    logC += 1
    local e = Instance.new("TextLabel")
    e.Size = UDim2.new(1, -8, 0, 12)
    e.Position = UDim2.new(0, 4, 0, 0)
    e.BackgroundTransparency = 1
    e.Text = os.date("%H:%M ") .. m
    e.TextColor3 = c or P.tx3
    e.TextSize = 8
    e.Font = Enum.Font.Gotham
    e.TextXAlignment = Enum.TextXAlignment.Left
    e.TextTruncate = Enum.TextTruncate.AtEnd
    e.LayoutOrder = logC
    e.ZIndex = 12
    e.Parent = logP
    task.defer(function()
        pcall(function()
            logP.CanvasPosition = Vector2.new(0, logP.AbsoluteCanvasSize.Y)
        end)
    end)
    if logC > 30 then
        for _, ch in pairs(logP:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() break end
        end
    end
end

local function nf(t, c)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 270, 0, 40)
    f.Position = UDim2.new(0.5, -135, 0, -45)
    f.BackgroundColor3 = P.bg1
    f.BackgroundTransparency = 0.02
    f.BorderSizePixel = 0
    f.ZIndex = 100
    f.Parent = SG
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

    local s = Instance.new("UIStroke")
    s.Color = c or P.pri
    s.Thickness = 1
    s.Transparency = 0.3
    s.Parent = f

    -- Top glow line
    local gl = Instance.new("Frame")
    gl.Size = UDim2.new(0.4, 0, 0, 2)
    gl.Position = UDim2.new(0.3, 0, 0, -1)
    gl.BackgroundColor3 = c or P.pri
    gl.BackgroundTransparency = 0.2
    gl.BorderSizePixel = 0
    gl.ZIndex = 101
    gl.Parent = f
    Instance.new("UICorner", gl).CornerRadius = UDim.new(0, 1)

    -- Icon circle
    local ic = Instance.new("Frame")
    ic.Size = UDim2.new(0, 24, 0, 24)
    ic.Position = UDim2.new(0, 10, 0.5, -12)
    ic.BackgroundColor3 = c or P.pri
    ic.BackgroundTransparency = 0.85
    ic.BorderSizePixel = 0
    ic.ZIndex = 101
    ic.Parent = f
    Instance.new("UICorner", ic).CornerRadius = UDim.new(1, 0)

    local icT = Instance.new("TextLabel")
    icT.Size = UDim2.new(1, 0, 1, 0)
    icT.BackgroundTransparency = 1
    icT.Text = "🏎️"
    icT.TextSize = 12
    icT.ZIndex = 102
    icT.Parent = ic

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -44, 1, 0)
    l.Position = UDim2.new(0, 40, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = P.tx1
    l.TextSize = 11
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 102
    l.Parent = f

    TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -135, 0, 12)
    }):Play()

    task.delay(2.5, function()
        TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0.5, -135, 0, -50),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.35)
        pcall(function() f:Destroy() end)
    end)
end

-- =============================================
-- CAR DETECTION
-- =============================================
local carLbl, carDot

local function findCar()
    local seat, mdl, root, meth = nil, nil, nil, "None"
    pcall(function()
        local h = char and char:FindFirstChildOfClass("Humanoid")
        if h and h.SeatPart then
            seat = h.SeatPart
            mdl = seat:FindFirstAncestorWhichIsA("Model")
            if mdl == char then mdl = nil; seat = nil else meth = "Seat" end
        end
    end)
    if not seat then
        pcall(function()
            local h = char and char:FindFirstChildOfClass("Humanoid")
            if h then
                for _, d in pairs(WS:GetDescendants()) do
                    pcall(function()
                        if (d:IsA("VehicleSeat") or d:IsA("Seat")) and d.Occupant == h then
                            seat = d
                            mdl = d:FindFirstAncestorWhichIsA("Model")
                            meth = "Occupant"
                        end
                    end)
                end
            end
        end)
    end
    if not seat then
        pcall(function()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, w in pairs(hrp:GetChildren()) do
                    if w:IsA("Weld") or w:IsA("WeldConstraint") then
                        local p
                        pcall(function() p = w.Part1 end)
                        if not p then pcall(function() p = w.Part0 end) end
                        if p and p ~= hrp then
                            local m = p:FindFirstAncestorWhichIsA("Model")
                            if m and m ~= char then
                                mdl = m
                                for _, ch in pairs(m:GetDescendants()) do
                                    if ch:IsA("VehicleSeat") or ch:IsA("Seat") then
                                        seat = ch
                                        break
                                    end
                                end
                                if not seat then seat = p end
                                meth = "Weld"
                                break
                            end
                        end
                    end
                end
            end
        end)
    end
    if mdl then
        root = mdl.PrimaryPart
        if not root then
            local bs, bsz = nil, 0
            for _, ch in pairs(mdl:GetDescendants()) do
                pcall(function()
                    if ch:IsA("BasePart") and not ch:IsA("Seat") and not ch:IsA("VehicleSeat") then
                        local s = ch.Size.Magnitude
                        if s > bsz then bsz = s; bs = ch end
                    end
                end)
            end
            root = bs
        end
        if not root and seat and seat:IsA("BasePart") then root = seat end
    end
    return seat, mdl, root, meth
end

-- =============================================
-- FORCE INJECTION
-- =============================================
local spdBV, gyroBG, flyBV, flyBG, nitroBV, spinBG

local function clean()
    for _, o in pairs(C.Inj) do pcall(function() o:Destroy() end) end
    C.Inj = {}
    spdBV = nil; gyroBG = nil; flyBV = nil; flyBG = nil; nitroBV = nil; spinBG = nil
end

local function inj(cls, nm, par, props)
    local o = Instance.new(cls)
    o.Name = "D_" .. nm
    for k, v in pairs(props) do pcall(function() o[k] = v end) end
    o.Parent = par
    table.insert(C.Inj, o)
    return o
end

local function applyW()
    if not C.Car then return end
    for _, d in pairs(C.Car:GetDescendants()) do
        pcall(function()
            if not d:IsA("BasePart") then return end
            local n = d.Name:lower()
            if not (n:find("wheel") or n:find("tire") or n:find("tyre")) then return end
            if C.Drft then
                local isR = n:find("rear") or n:find("back") or n:find("rl") or n:find("rr")
                local isF = n:find("front") or n:find("fl") or n:find("fr")
                if isR then
                    d.CustomPhysicalProperties = PhysicalProperties.new(0.5, math.max((100-C.RearL)/100*0.5, 0.005), 0, 1, 1)
                elseif isF then
                    d.CustomPhysicalProperties = PhysicalProperties.new(0.7, C.FrontG/100, 0, 1, 1)
                else
                    d.CustomPhysicalProperties = PhysicalProperties.new(0.5, math.max((100-C.DrftAmt)/100*0.5, 0.005), 0, 1, 1)
                end
            else
                d.CustomPhysicalProperties = PhysicalProperties.new(1, 0.5, 0, 1, 1)
            end
        end)
    end
end

local function setup()
    local r = C.Root
    if not r then return end
    clean()
    if C.Spd > 0 then spdBV = inj("BodyVelocity", "Spd", r, {MaxForce=Vector3.zero, Velocity=Vector3.zero, P=10000}) end
    if C.AFlip then gyroBG = inj("BodyGyro", "Gyro", r, {MaxTorque=Vector3.new(C.FlipStr*700,0,C.FlipStr*700), P=2500, D=400}) end
    if C.Fly then
        flyBV = inj("BodyVelocity", "Fly", r, {MaxForce=Vector3.new(math.huge,math.huge,math.huge), Velocity=Vector3.zero, P=10000})
        flyBG = inj("BodyGyro", "FlyG", r, {MaxTorque=Vector3.new(math.huge,math.huge,math.huge), P=5000, D=500})
    end
    if C.Nitro then nitroBV = inj("BodyVelocity", "Nit", r, {MaxForce=Vector3.zero, Velocity=Vector3.zero, P=15000}) end
    if C.Spin then spinBG = inj("BodyAngularVelocity", "Spin", r, {MaxTorque=Vector3.new(0,math.huge,0), AngularVelocity=Vector3.zero}) end
    applyW()
end

local function resetAll()
    clean()
    C.Grav = 100
    pcall(function() WS.Gravity = C.OG end)
    if C.Car then
        for _, d in pairs(C.Car:GetDescendants()) do
            pcall(function()
                if d:IsA("BasePart") and (d.Name:lower():find("wheel") or d.Name:lower():find("tire")) then
                    d.CustomPhysicalProperties = PhysicalProperties.new(1, 0.5, 0, 1, 1)
                end
                if d:IsA("BasePart") then d.Transparency = 0 end
            end)
        end
    end
end

-- =============================================
-- MAIN FRAME
-- =============================================
local M = Instance.new("Frame")
M.Name = "Main"
M.Size = UDim2.new(0, 360, 0, 480)
M.Position = UDim2.new(0.5, -180, 0.5, -240)
M.BackgroundColor3 = P.bg1
M.BackgroundTransparency = 0.01
M.BorderSizePixel = 0
M.ClipsDescendants = true
M.Active = true
M.Parent = SG
Instance.new("UICorner", M).CornerRadius = UDim.new(0, 16)

-- Outer glow stroke
local mS = Instance.new("UIStroke")
mS.Thickness = 1.5
mS.Transparency = 0.25
mS.Color = P.pri
mS.Parent = M

-- Inner glass overlay
local innerGlass = Instance.new("Frame")
innerGlass.Size = UDim2.new(1, -2, 1, -2)
innerGlass.Position = UDim2.new(0, 1, 0, 1)
innerGlass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
innerGlass.BackgroundTransparency = 0.97
innerGlass.BorderSizePixel = 0
innerGlass.ZIndex = 1
innerGlass.Parent = M
Instance.new("UICorner", innerGlass).CornerRadius = UDim.new(0, 15)

-- =============================================
-- HEADER
-- =============================================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = P.bg1
header.BackgroundTransparency = 0.1
header.BorderSizePixel = 0
header.ZIndex = 20
header.Parent = M
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

-- Fix bottom corners
local hFix = Instance.new("Frame")
hFix.Size = UDim2.new(1, 0, 0, 16)
hFix.Position = UDim2.new(0, 0, 1, -16)
hFix.BackgroundColor3 = P.bg1
hFix.BackgroundTransparency = 0.1
hFix.BorderSizePixel = 0
hFix.ZIndex = 20
hFix.Parent = header

-- Accent line under header
local hLine = Instance.new("Frame")
hLine.Size = UDim2.new(0.7, 0, 0, 1)
hLine.Position = UDim2.new(0.15, 0, 1, 1)
hLine.BorderSizePixel = 0
hLine.ZIndex = 21
hLine.Parent = header

local hLineG = Instance.new("UIGradient")
hLineG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.2, P.pri),
    ColorSequenceKeypoint.new(0.5, P.acc),
    ColorSequenceKeypoint.new(0.8, P.pri),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
})
hLineG.Parent = hLine

-- Logo pill
local logoPill = Instance.new("Frame")
logoPill.Size = UDim2.new(0, 34, 0, 34)
logoPill.Position = UDim2.new(0, 14, 0.5, -17)
logoPill.BackgroundColor3 = P.pri
logoPill.BackgroundTransparency = 0.85
logoPill.BorderSizePixel = 0
logoPill.ZIndex = 21
logoPill.Parent = header
Instance.new("UICorner", logoPill).CornerRadius = UDim.new(0, 10)

local lpStroke = Instance.new("UIStroke")
lpStroke.Color = P.pri
lpStroke.Thickness = 1
lpStroke.Transparency = 0.5
lpStroke.Parent = logoPill

local logoEmoji = Instance.new("TextLabel")
logoEmoji.Size = UDim2.new(1, 0, 1, 0)
logoEmoji.BackgroundTransparency = 1
logoEmoji.Text = "🏎️"
logoEmoji.TextSize = 18
logoEmoji.ZIndex = 22
logoEmoji.Parent = logoPill

-- Title
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 60, 0, 20)
titleLbl.Position = UDim2.new(0, 56, 0, 7)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "DRIH"
titleLbl.TextColor3 = P.tx1
titleLbl.TextSize = 20
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 21
titleLbl.Parent = header

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(0, 140, 0, 10)
subLbl.Position = UDim2.new(0, 58, 0, 29)
subLbl.BackgroundTransparency = 1
subLbl.Text = "Luxury Car Tuner"
subLbl.TextColor3 = P.tx3
subLbl.TextSize = 8
subLbl.Font = Enum.Font.Gotham
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.ZIndex = 21
subLbl.Parent = header

-- Speed HUD
local spdPill = Instance.new("Frame")
spdPill.Size = UDim2.new(0, 72, 0, 26)
spdPill.Position = UDim2.new(1, -140, 0.5, -13)
spdPill.BackgroundColor3 = P.bg2
spdPill.BackgroundTransparency = 0.2
spdPill.BorderSizePixel = 0
spdPill.ZIndex = 21
spdPill.Parent = header
Instance.new("UICorner", spdPill).CornerRadius = UDim.new(0, 8)

local spdStroke = Instance.new("UIStroke")
spdStroke.Color = P.grn
spdStroke.Thickness = 1
spdStroke.Transparency = 0.4
spdStroke.Parent = spdPill

local spdLbl = Instance.new("TextLabel")
spdLbl.Size = UDim2.new(1, 0, 1, 0)
spdLbl.BackgroundTransparency = 1
spdLbl.Text = "0 MPH"
spdLbl.TextColor3 = P.grn
spdLbl.TextSize = 12
spdLbl.Font = Enum.Font.GothamBlack
spdLbl.ZIndex = 22
spdLbl.Parent = spdPill

-- Header buttons
local function hBtn(txt, pos, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 24, 0, 24)
    b.Position = pos
    b.BackgroundColor3 = col
    b.BackgroundTransparency = 0.85
    b.Text = txt
    b.TextColor3 = P.tx2
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 22
    b.BorderSizePixel = 0
    b.Parent = header
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.5, TextColor3 = P.tx1}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.85, TextColor3 = P.tx2}):Play()
    end)
    return b
end

local minB = hBtn("—", UDim2.new(1, -56, 0.5, -12), P.pri)
local clsB = hBtn("✕", UDim2.new(1, -28, 0.5, -12), P.acc)

-- Drag
local drg, dIn, dSt, sPo
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drg = true; dSt = i.Position; sPo = M.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then drg = false end
        end)
    end
end)
header.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then dIn = i end
end)
UIS.InputChanged:Connect(function(i)
    if i == dIn and drg then
        local d = i.Position - dSt
        M.Position = UDim2.new(sPo.X.Scale, sPo.X.Offset + d.X, sPo.Y.Scale, sPo.Y.Offset + d.Y)
    end
end)

-- =============================================
-- STATUS BAR
-- =============================================
local stBar = Instance.new("Frame")
stBar.Size = UDim2.new(1, -20, 0, 32)
stBar.Position = UDim2.new(0, 10, 0, 56)
stBar.BackgroundColor3 = P.bg2
stBar.BackgroundTransparency = 0.3
stBar.BorderSizePixel = 0
stBar.ZIndex = 15
stBar.Parent = M
Instance.new("UICorner", stBar).CornerRadius = UDim.new(0, 8)

carDot = Instance.new("Frame")
carDot.Size = UDim2.new(0, 8, 0, 8)
carDot.Position = UDim2.new(0, 10, 0.5, -4)
carDot.BackgroundColor3 = P.red
carDot.BorderSizePixel = 0
carDot.ZIndex = 16
carDot.Parent = stBar
Instance.new("UICorner", carDot).CornerRadius = UDim.new(1, 0)

carLbl = Instance.new("TextLabel")
carLbl.Size = UDim2.new(0.5, 0, 1, 0)
carLbl.Position = UDim2.new(0, 24, 0, 0)
carLbl.BackgroundTransparency = 1
carLbl.Text = "No car connected"
carLbl.TextColor3 = P.tx3
carLbl.TextSize = 9
carLbl.Font = Enum.Font.GothamMedium
carLbl.TextXAlignment = Enum.TextXAlignment.Left
carLbl.ZIndex = 16
carLbl.Parent = stBar

local connBtn = Instance.new("TextButton")
connBtn.Size = UDim2.new(0, 72, 0, 22)
connBtn.Position = UDim2.new(1, -80, 0.5, -11)
connBtn.BackgroundColor3 = P.pri
connBtn.BackgroundTransparency = 0.25
connBtn.Text = "Connect"
connBtn.TextColor3 = P.tx1
connBtn.TextSize = 9
connBtn.Font = Enum.Font.GothamBold
connBtn.ZIndex = 16
connBtn.BorderSizePixel = 0
connBtn.Parent = stBar
Instance.new("UICorner", connBtn).CornerRadius = UDim.new(0, 6)

connBtn.MouseButton1Click:Connect(function()
    local seat, car, root, meth = findCar()
    if seat and car then
        C.Seat = seat; C.Car = car; C.Root = root
        carLbl.Text = car.Name
        carLbl.TextColor3 = P.grn
        carDot.BackgroundColor3 = P.grn
        lg("✅ " .. car.Name, P.grn)
        nf("Connected to " .. car.Name, P.grn)
        setup()
    else
        carLbl.Text = "Not found — sit in car"
        carLbl.TextColor3 = P.red
        carDot.BackgroundColor3 = P.red
        nf("No car found", P.orn)
    end
end)
connBtn.MouseEnter:Connect(function()
    TweenService:Create(connBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.1}):Play()
end)
connBtn.MouseLeave:Connect(function()
    TweenService:Create(connBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.25}):Play()
end)

-- =============================================
-- CONTENT
-- =============================================
local Co = Instance.new("ScrollingFrame")
Co.Size = UDim2.new(1, -20, 1, -96)
Co.Position = UDim2.new(0, 10, 0, 92)
Co.BackgroundTransparency = 1
Co.BorderSizePixel = 0
Co.ScrollBarThickness = 2
Co.ScrollBarImageColor3 = P.pri
Co.AutomaticCanvasSize = Enum.AutomaticSize.Y
Co.ZIndex = 10
Co.Parent = M

local coLay = Instance.new("UIListLayout")
coLay.Padding = UDim.new(0, 4)
coLay.SortOrder = Enum.SortOrder.LayoutOrder
coLay.Parent = Co

Instance.new("UIPadding", Co).PaddingBottom = UDim.new(0, 10)

-- =============================================
-- LUXURY UI BUILDERS
-- =============================================
local function Sec(t, o)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.LayoutOrder = o
    f.ZIndex = 10
    f.Parent = Co

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Position = UDim2.new(0, 0, 0, 2)
    l.BackgroundTransparency = 1
    l.Text = string.upper(t)
    l.TextColor3 = P.sec
    l.TextSize = 8
    l.Font = Enum.Font.GothamBlack
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 11
    l.Parent = f

    -- Elegant thin line
    local ln = Instance.new("Frame")
    ln.Size = UDim2.new(0.3, 0, 0, 1)
    ln.Position = UDim2.new(0, 0, 1, -1)
    ln.BackgroundColor3 = P.pri
    ln.BackgroundTransparency = 0.5
    ln.BorderSizePixel = 0
    ln.ZIndex = 10
    ln.Parent = f
end

local function Sl(t, ic, mn, mx, df, o, cb)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = P.bg2
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.LayoutOrder = o
    card.ZIndex = 10
    card.Parent = Co
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    -- Icon
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 22, 0, 22)
    iconBg.Position = UDim2.new(0, 8, 0, 4)
    iconBg.BackgroundColor3 = P.pri
    iconBg.BackgroundTransparency = 0.88
    iconBg.BorderSizePixel = 0
    iconBg.ZIndex = 11
    iconBg.Parent = card
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 6)

    local iconTxt = Instance.new("TextLabel")
    iconTxt.Size = UDim2.new(1, 0, 1, 0)
    iconTxt.BackgroundTransparency = 1
    iconTxt.Text = ic
    iconTxt.TextSize = 12
    iconTxt.ZIndex = 12
    iconTxt.Parent = iconBg

    -- Label
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.4, 0, 0, 12)
    lb.Position = UDim2.new(0, 36, 0, 6)
    lb.BackgroundTransparency = 1
    lb.Text = t
    lb.TextColor3 = P.tx1
    lb.TextSize = 10
    lb.Font = Enum.Font.GothamMedium
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 11
    lb.Parent = card

    -- Value pill
    local valPill = Instance.new("Frame")
    valPill.Size = UDim2.new(0, 34, 0, 16)
    valPill.Position = UDim2.new(1, -42, 0, 5)
    valPill.BackgroundColor3 = P.pri
    valPill.BackgroundTransparency = 0.82
    valPill.BorderSizePixel = 0
    valPill.ZIndex = 11
    valPill.Parent = card
    Instance.new("UICorner", valPill).CornerRadius = UDim.new(0, 5)

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(1, 0, 1, 0)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(df)
    vl.TextColor3 = P.sec
    vl.TextSize = 9
    vl.Font = Enum.Font.GothamBlack
    vl.ZIndex = 12
    vl.Parent = valPill

    -- Track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 4)
    track.Position = UDim2.new(0, 8, 0, 30)
    track.BackgroundColor3 = P.bg3
    track.BorderSizePixel = 0
    track.ZIndex = 11
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fr = (df - mn) / (mx - mn)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(fr, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.ZIndex = 12
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local fG = Instance.new("UIGradient")
    fG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.pri),
        ColorSequenceKeypoint.new(1, P.acc)
    })
    fG.Parent = fill

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(fr, -5, 0.5, -5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 13
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    -- Knob glow
    local kGlow = Instance.new("UIStroke")
    kGlow.Color = P.pri
    kGlow.Thickness = 2
    kGlow.Transparency = 0.3
    kGlow.Parent = knob

    local sd = false
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(1, 0, 0, 16)
    sb.Position = UDim2.new(0, 0, 0, -6)
    sb.BackgroundTransparency = 1
    sb.Text = ""
    sb.ZIndex = 14
    sb.Parent = track

    sb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sd = true end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sd = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if sd and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(mn + r * (mx - mn))
            vl.Text = tostring(v)
            fill.Size = UDim2.new(r, 0, 1, 0)
            knob.Position = UDim2.new(r, -5, 0.5, -5)
            cb(v)
        end
    end)
end

local function Tog(t, ic, df, o, cb)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 30)
    card.BackgroundColor3 = P.bg2
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.LayoutOrder = o
    card.ZIndex = 10
    card.Parent = Co
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)

    -- Icon
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 20, 0, 20)
    iconBg.Position = UDim2.new(0, 7, 0.5, -10)
    iconBg.BackgroundColor3 = P.pri
    iconBg.BackgroundTransparency = 0.88
    iconBg.BorderSizePixel = 0
    iconBg.ZIndex = 11
    iconBg.Parent = card
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 5)

    local iconTxt = Instance.new("TextLabel")
    iconTxt.Size = UDim2.new(1, 0, 1, 0)
    iconTxt.BackgroundTransparency = 1
    iconTxt.Text = ic
    iconTxt.TextSize = 10
    iconTxt.ZIndex = 12
    iconTxt.Parent = iconBg

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.6, 0, 1, 0)
    lb.Position = UDim2.new(0, 34, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = t
    lb.TextColor3 = P.tx1
    lb.TextSize = 10
    lb.Font = Enum.Font.GothamMedium
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 11
    lb.Parent = card

    -- Toggle track
    local tBg = Instance.new("Frame")
    tBg.Size = UDim2.new(0, 34, 0, 16)
    tBg.Position = UDim2.new(1, -42, 0.5, -8)
    tBg.BackgroundColor3 = df and P.pri or P.bg3
    tBg.BorderSizePixel = 0
    tBg.ZIndex = 11
    tBg.Parent = card
    Instance.new("UICorner", tBg).CornerRadius = UDim.new(1, 0)

    local tDot = Instance.new("Frame")
    tDot.Size = UDim2.new(0, 10, 0, 10)
    tDot.Position = df and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
    tDot.BackgroundColor3 = Color3.new(1, 1, 1)
    tDot.BorderSizePixel = 0
    tDot.ZIndex = 12
    tDot.Parent = tBg
    Instance.new("UICorner", tDot).CornerRadius = UDim.new(1, 0)

    local en = df
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 13
    btn.Parent = card

    btn.MouseButton1Click:Connect(function()
        en = not en
        cb(en)
        TweenService:Create(tBg, TweenInfo.new(0.15), {
            BackgroundColor3 = en and P.pri or P.bg3
        }):Play()
        TweenService:Create(tDot, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
            Position = en and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
        }):Play()
    end)
end

local function Btn(t, c, o, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = c
    b.BackgroundTransparency = 0.3
    b.BorderSizePixel = 0
    b.Text = t
    b.TextColor3 = P.tx1
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.LayoutOrder = o
    b.ZIndex = 10
    b.Parent = Co
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency = 0.15}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
    end)
end

-- =============================================
-- LAYOUT
-- =============================================
Sec("Speed & Power", 0)
Sl("Speed Boost", "🏁", 0, 400, 0, 1, function(v) C.Spd=v; if v>0 and C.Root and(not spdBV or not spdBV.Parent) then spdBV=inj("BodyVelocity","Spd",C.Root,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=10000}) end; if spdBV and spdBV.Parent then spdBV.MaxForce=v>0 and Vector3.new(v*200,0,v*200) or Vector3.zero end end)
Sl("Speed Limit", "🚫", 0, 500, 0, 2, function(v) C.Lim=v end)
Tog("Nitro Boost  ·  Hold N", "🔥", false, 3, function(v) C.Nitro=v; if v and C.Root then if not nitroBV or not nitroBV.Parent then nitroBV=inj("BodyVelocity","Nit",C.Root,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=15000}) end else if nitroBV then pcall(function() nitroBV:Destroy() end);nitroBV=nil end end end)
Sl("Nitro Power", "💥", 50, 600, 150, 4, function(v) C.NitroF=v end)

Sec("Drift Controls", 5)
Tog("Enable Drift", "🔄", false, 6, function(v) C.Drft=v;applyW() end)
Sl("Drift Intensity", "💫", 0, 100, 95, 7, function(v) C.DrftAmt=v;if C.Drft then applyW() end end)
Sl("Rear Looseness", "🔙", 0, 100, 70, 8, function(v) C.RearL=v;if C.Drft then applyW() end end)
Sl("Front Grip", "🔜", 0, 100, 80, 9, function(v) C.FrontG=v;if C.Drft then applyW() end end)
Tog("Handbrake  ·  Hold H", "🅿️", false, 10, function(v) C.HBrk=v end)
Sl("Brake Force", "🛑", 0, 100, 50, 11, function(v) C.BrkPow=v end)
Tog("Low-G Drift  ·  35%", "🌙", false, 12, function(v) C.Grav=v and 35 or 100 end)
Tog("Donut Spin  ·  Hold J", "🌀", false, 13, function(v) C.Spin=v; if v and C.Root then if not spinBG or not spinBG.Parent then spinBG=inj("BodyAngularVelocity","Spin",C.Root,{MaxTorque=Vector3.new(0,math.huge,0),AngularVelocity=Vector3.zero}) end else if spinBG then pcall(function() spinBG:Destroy() end);spinBG=nil end end end)
Sl("Spin Speed", "🌀", 5, 100, 30, 14, function(v) C.SpinSpd=v end)

Sec("Physics", 15)
Sl("Gravity", "🪨", 2, 300, 100, 16, function(v) C.Grav=v end)
Tog("Moon Gravity  ·  10%", "🌙", false, 17, function(v) C.Grav=v and 10 or 100 end)
Tog("Bounce Mode", "🏀", false, 18, function(v) C.Bounce=v end)
Tog("Anti-Flip", "🛡️", true, 19, function(v) C.AFlip=v; if C.Root then if v then if not gyroBG or not gyroBG.Parent then gyroBG=inj("BodyGyro","Gyro",C.Root,{MaxTorque=Vector3.new(C.FlipStr*700,0,C.FlipStr*700),P=2500,D=400}) end else if gyroBG then pcall(function() gyroBG:Destroy() end);gyroBG=nil end end end end)
Sl("Flip Strength", "💪", 10, 100, 60, 20, function(v) C.FlipStr=v; if gyroBG and gyroBG.Parent then gyroBG.MaxTorque=Vector3.new(v*700,0,v*700) end end)

Sec("Movement", 21)
Tog("Car Jump  ·  Space", "🦘", false, 22, function(v) C.Jump=v end)
Sl("Jump Power", "⬆️", 20, 250, 75, 23, function(v) C.JumpPow=v end)
Tog("Fly Mode  ·  WASD", "✈️", false, 24, function(v) C.Fly=v; if C.Root then if v then if not flyBV or not flyBV.Parent then flyBV=inj("BodyVelocity","Fly",C.Root,{MaxForce=Vector3.new(math.huge,math.huge,math.huge),Velocity=Vector3.zero,P=10000}) end; if not flyBG or not flyBG.Parent then flyBG=inj("BodyGyro","FlyG",C.Root,{MaxTorque=Vector3.new(math.huge,math.huge,math.huge),P=5000,D=500}) end else if flyBV then pcall(function() flyBV:Destroy() end);flyBV=nil end; if flyBG then pcall(function() flyBG:Destroy() end);flyBG=nil end end end end)
Sl("Fly Speed", "💨", 10, 500, 80, 25, function(v) C.FlySpd=v end)

Sec("Visuals", 26)
Tog("Ghost Car", "👻", false, 27, function(v) C.Invis=v; if C.Car then for _,d in pairs(C.Car:GetDescendants()) do pcall(function() if d:IsA("BasePart") then d.Transparency=v and 0.8 or 0 end end) end end end)
Tog("Neon Trail", "✨", false, 28, function(v) C.Trail=v; if v and C.Root then local a0=Instance.new("Attachment");a0.Name="D_A0";a0.Position=Vector3.new(0,0,-3);a0.Parent=C.Root; local a1=Instance.new("Attachment");a1.Name="D_A1";a1.Position=Vector3.new(0,0,3);a1.Parent=C.Root; local tr=Instance.new("Trail");tr.Name="D_Trail";tr.Attachment0=a0;tr.Attachment1=a1;tr.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,P.pri),ColorSequenceKeypoint.new(0.5,P.acc),ColorSequenceKeypoint.new(1,P.blu)});tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)});tr.Lifetime=2;tr.MinLength=0.1;tr.LightEmission=0.5;tr.Parent=C.Root;table.insert(C.Inj,a0);table.insert(C.Inj,a1);table.insert(C.Inj,tr) else for i=#C.Inj,1,-1 do pcall(function() local o=C.Inj[i]; if o.Name=="D_Trail" or o.Name=="D_A0" or o.Name=="D_A1" then o:Destroy();table.remove(C.Inj,i) end end) end end end)

Sec("Actions", 29)
Btn("Re-inject Forces", P.pri, 30, function() if not C.Root then nf("Sit in a car first",P.orn) return end; setup(); lg("✅ Injected",P.grn); nf("Forces applied",P.pri) end)
Btn("Reset Everything", P.bg3, 31, function() resetAll(); lg("↩️ Reset",P.tx3); nf("Reset complete",P.tx3) end)
Btn("Walk Speed · 100", Color3.fromRGB(35,30,55), 32, function() pcall(function() char.Humanoid.WalkSpeed=100 end) end)
Btn("Reset Character", Color3.fromRGB(60,25,40), 33, function() pcall(function() char.Humanoid.Health=0 end) end)
Btn("Rejoin Server", Color3.fromRGB(25,35,60), 34, function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,plr) end) end)
Btn("Scan Car Parts", P.bg2, 35, function()
    if not C.Car then lg("No car",P.orn) return end
    lg("═══ "..C.Car.Name.." ═══",P.sec)
    local t={}; for _,d in pairs(C.Car:GetDescendants()) do pcall(function() t[d.ClassName]=(t[d.ClassName] or 0)+1 end) end
    for cn,ct in pairs(t) do lg("  "..cn..": "..ct,P.tx3) end
end)

Sec("Activity Log", 36)

logP = Instance.new("ScrollingFrame")
logP.Size = UDim2.new(1, 0, 0, 70)
logP.BackgroundColor3 = P.bg2
logP.BackgroundTransparency = 0.4
logP.BorderSizePixel = 0
logP.ScrollBarThickness = 1
logP.ScrollBarImageColor3 = P.pri
logP.AutomaticCanvasSize = Enum.AutomaticSize.Y
logP.LayoutOrder = 37
logP.ZIndex = 10
logP.Parent = Co
Instance.new("UICorner", logP).CornerRadius = UDim.new(0, 8)

local lLy = Instance.new("UIListLayout")
lLy.Padding = UDim.new(0, 1)
lLy.SortOrder = Enum.SortOrder.LayoutOrder
lLy.Parent = logP

-- =============================================
-- HEARTBEAT
-- =============================================
local fc = 0

RunService.Heartbeat:Connect(function()
    pcall(function() WS.Gravity = 196.2 * (C.Grav / 100) end)

    local root = C.Root
    if not root or not root.Parent then return end

    -- Speed display
    pcall(function()
        local spd = math.floor(root.Velocity.Magnitude)
        spdLbl.Text = spd .. " MPH"
        local col = spd > 150 and P.red or spd > 80 and P.orn or P.grn
        spdLbl.TextColor3 = col
        spdStroke.Color = col
    end)

    -- Speed boost
    if spdBV and spdBV.Parent and C.Spd > 0 then
        local fw = root.CFrame.LookVector
        spdBV.Velocity = Vector3.new(fw.X * C.Spd, 0, fw.Z * C.Spd)
    end

    -- Speed limit
    if C.Lim > 0 then
        local v = root.Velocity
        local hs = Vector3.new(v.X, 0, v.Z).Magnitude
        if hs > C.Lim then
            local r = C.Lim / hs
            root.Velocity = Vector3.new(v.X*r, v.Y, v.Z*r)
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X*r, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z*r) end)
        end
    end

    -- Nitro
    if C.Nitro and nitroBV and nitroBV.Parent then
        if UIS:IsKeyDown(Enum.KeyCode.N) then
            local fw = root.CFrame.LookVector
            nitroBV.Velocity = fw * C.NitroF
            nitroBV.MaxForce = Vector3.new(C.NitroF * 300, 0, C.NitroF * 300)
        else
            nitroBV.MaxForce = Vector3.zero
        end
    end

    -- Handbrake
    if C.HBrk and UIS:IsKeyDown(Enum.KeyCode.H) then
        local v = root.Velocity
        local b = 1 - (C.BrkPow / 100 * 0.15)
        root.Velocity = Vector3.new(v.X*b, v.Y, v.Z*b)
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X*b, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z*b) end)
    end

    -- Spin
    if C.Spin and spinBG and spinBG.Parent then
        spinBG.AngularVelocity = UIS:IsKeyDown(Enum.KeyCode.J) and Vector3.new(0, C.SpinSpd, 0) or Vector3.zero
    end

    -- Bounce
    if C.Bounce then
        local v = root.Velocity
        if v.Y < -5 then root.Velocity = Vector3.new(v.X, math.abs(v.Y) * 0.8, v.Z) end
    end

    -- Fly
    if C.Fly and flyBV and flyBV.Parent then
        local cam = WS.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.yAxis end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * C.FlySpd or Vector3.zero
        if flyBG and flyBG.Parent then flyBG.CFrame = cam.CFrame end
    end

    -- Auto detect + animations (every 120 frames)
    fc += 1
    if fc >= 120 then
        fc = 0

        local seat, car, rt, meth = findCar()
        if seat and car then
            if C.Car ~= car then
                resetAll()
                C.Seat = seat; C.Car = car; C.Root = rt
                carLbl.Text = car.Name
                carLbl.TextColor3 = P.grn
                carDot.BackgroundColor3 = P.grn
                lg("🚗 " .. car.Name, P.grn)
                setup()
            end
        else
            if C.Car then
                resetAll()
                C.Car = nil; C.Root = nil; C.Seat = nil
                carLbl.Text = "No car connected"
                carLbl.TextColor3 = P.tx3
                carDot.BackgroundColor3 = P.red
            end
        end

        -- Border glow cycle
        pcall(function()
            local h = (tick() * 0.02) % 1
            mS.Color = Color3.fromHSV(h, 0.45, 0.8)
        end)

        -- Logo bob
        pcall(function()
            logoEmoji.Rotation = math.sin(tick() * 2) * 6
        end)

        -- Header line shimmer
        pcall(function()
            hLineG.Offset = Vector2.new(math.sin(tick() * 0.7) * 0.25, 0)
        end)

        -- Status dot pulse
        pcall(function()
            if C.Car then
                carDot.BackgroundTransparency = 0.25 + math.sin(tick() * 3) * 0.25
            else
                carDot.BackgroundTransparency = 0
            end
        end)
    end
end)

-- Key inputs
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Space and C.Jump and C.Root and C.Root.Parent then
        pcall(function()
            local bv = Instance.new("BodyVelocity")
            bv.Name = "D_Jmp"
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, C.JumpPow, 0)
            bv.Parent = C.Root
            task.delay(0.2, function() pcall(function() bv:Destroy() end) end)
        end)
    end
    if inp.KeyCode == Enum.KeyCode.RightShift then M.Visible = not M.Visible end
end)

-- Window controls
local mini = false
minB.MouseButton1Click:Connect(function()
    mini = not mini
    TweenService:Create(M, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        Size = mini and UDim2.new(0, 360, 0, 52) or UDim2.new(0, 360, 0, 480)
    }):Play()
    minB.Text = mini and "+" or "—"
end)

clsB.MouseButton1Click:Connect(function()
    resetAll()
    TweenService:Create(M, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }):Play()
    task.wait(0.25)
    SG:Destroy()
end)

-- =============================================
-- INTRO
-- =============================================
M.Size = UDim2.new(0, 0, 0, 0)
M.Position = UDim2.new(0.5, 0, 0.5, 0)
M.BackgroundTransparency = 1

TweenService:Create(M, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 360, 0, 480),
    Position = UDim2.new(0.5, -180, 0.5, -240),
    BackgroundTransparency = 0.01
}):Play()

task.wait(0.45)
nf("DRIH v4.0 — Luxury Edition", P.pri)
lg("DRIH v4.0 loaded", P.pri)
lg("N·Nitro  H·Brake  J·Spin  Space·Jump", P.tx3)
lg("Right Shift to toggle", P.tx3)

print("=== DRIH v4.0 ===")
print("RIGHT SHIFT = Toggle")
