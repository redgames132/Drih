-- =============================================
-- DRIH v5.0 - ELITE EDITION
-- Stunning glassmorphism | Animated accents
-- Premium card design | Buttery smooth
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
-- ELITE PALETTE
-- =============================================
local P = {
    p1 = Color3.fromRGB(99, 102, 241),     -- Indigo
    p2 = Color3.fromRGB(139, 92, 246),      -- Violet
    p3 = Color3.fromRGB(236, 72, 153),      -- Pink
    p4 = Color3.fromRGB(59, 130, 246),      -- Blue
    bg = Color3.fromRGB(9, 9, 15),          -- Void black
    c1 = Color3.fromRGB(15, 15, 24),        -- Card
    c2 = Color3.fromRGB(22, 22, 34),        -- Card hover
    c3 = Color3.fromRGB(30, 30, 45),        -- Card light
    w  = Color3.fromRGB(248, 248, 255),     -- White
    t1 = Color3.fromRGB(200, 200, 220),     -- Text primary
    t2 = Color3.fromRGB(130, 130, 160),     -- Text dim
    t3 = Color3.fromRGB(80, 80, 105),       -- Text muted
    gn = Color3.fromRGB(52, 211, 153),      -- Emerald
    rd = Color3.fromRGB(251, 113, 133),     -- Rose
    or_ = Color3.fromRGB(251, 191, 36),     -- Amber
}

-- =============================================
-- LOG & NOTIFY
-- =============================================
local logP, logC = nil, 0

local function lg(m, c)
    if not logP then return end
    logC += 1
    local e = Instance.new("TextLabel")
    e.Size = UDim2.new(1, -12, 0, 13)
    e.Position = UDim2.new(0, 6, 0, 0)
    e.BackgroundTransparency = 1
    e.Text = "· " .. m
    e.TextColor3 = c or P.t3
    e.TextSize = 8
    e.Font = Enum.Font.GothamMedium
    e.TextXAlignment = Enum.TextXAlignment.Left
    e.TextTruncate = Enum.TextTruncate.AtEnd
    e.LayoutOrder = logC
    e.ZIndex = 12
    e.Parent = logP
    task.defer(function()
        pcall(function() logP.CanvasPosition = Vector2.new(0, logP.AbsoluteCanvasSize.Y) end)
    end)
    if logC > 25 then
        for _, ch in pairs(logP:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() break end
        end
    end
end

local function nf(t, c)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0, 280, 0, 44)
    holder.Position = UDim2.new(0.5, -140, 0, -50)
    holder.BackgroundColor3 = P.c1
    holder.BackgroundTransparency = 0.02
    holder.BorderSizePixel = 0
    holder.ZIndex = 200
    holder.Parent = SG
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 14)

    -- Glow stroke
    local nS = Instance.new("UIStroke")
    nS.Color = c or P.p2
    nS.Thickness = 1.5
    nS.Transparency = 0.2
    nS.Parent = holder

    -- Animated top accent
    local topG = Instance.new("Frame")
    topG.Size = UDim2.new(0.5, 0, 0, 2)
    topG.Position = UDim2.new(0.25, 0, 0, -1)
    topG.BorderSizePixel = 0
    topG.ZIndex = 201
    topG.Parent = holder

    local tGG = Instance.new("UIGradient")
    tGG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(0.3, c or P.p2),
        ColorSequenceKeypoint.new(0.7, c or P.p3),
        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
    })
    tGG.Parent = topG

    -- Icon
    local icBg = Instance.new("Frame")
    icBg.Size = UDim2.new(0, 28, 0, 28)
    icBg.Position = UDim2.new(0, 10, 0.5, -14)
    icBg.BackgroundColor3 = c or P.p2
    icBg.BackgroundTransparency = 0.85
    icBg.BorderSizePixel = 0
    icBg.ZIndex = 201
    icBg.Parent = holder
    Instance.new("UICorner", icBg).CornerRadius = UDim.new(0, 8)

    local icT = Instance.new("TextLabel")
    icT.Size = UDim2.new(1, 0, 1, 0)
    icT.BackgroundTransparency = 1
    icT.Text = "🏎️"
    icT.TextSize = 14
    icT.ZIndex = 202
    icT.Parent = icBg

    -- Text
    local nT = Instance.new("TextLabel")
    nT.Size = UDim2.new(1, -50, 1, 0)
    nT.Position = UDim2.new(0, 44, 0, 0)
    nT.BackgroundTransparency = 1
    nT.Text = t
    nT.TextColor3 = P.w
    nT.TextSize = 11
    nT.Font = Enum.Font.GothamMedium
    nT.TextXAlignment = Enum.TextXAlignment.Left
    nT.ZIndex = 202
    nT.Parent = holder

    TweenService:Create(holder, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -140, 0, 14)
    }):Play()

    task.delay(3, function()
        TweenService:Create(holder, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -140, 0, -55),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.45)
        pcall(function() holder:Destroy() end)
    end)
end

-- =============================================
-- CAR & FORCES (Same engine, compact)
-- =============================================
local carLbl, carDot, spdLbl, spdStr
local spdBV, gyroBG, flyBV, flyBG, nitroBV, spinBG

local function findCar()
    local seat, mdl, root, meth = nil, nil, nil, "None"
    pcall(function() local h=char and char:FindFirstChildOfClass("Humanoid"); if h and h.SeatPart then seat=h.SeatPart; mdl=seat:FindFirstAncestorWhichIsA("Model"); if mdl==char then mdl=nil;seat=nil else meth="Seat" end end end)
    if not seat then pcall(function() local h=char and char:FindFirstChildOfClass("Humanoid"); if h then for _,d in pairs(WS:GetDescendants()) do pcall(function() if(d:IsA("VehicleSeat") or d:IsA("Seat")) and d.Occupant==h then seat=d;mdl=d:FindFirstAncestorWhichIsA("Model");meth="Occ" end end) end end end) end
    if not seat then pcall(function() local hrp=char and char:FindFirstChild("HumanoidRootPart"); if hrp then for _,w in pairs(hrp:GetChildren()) do if w:IsA("Weld") or w:IsA("WeldConstraint") then local p; pcall(function() p=w.Part1 end); if not p then pcall(function() p=w.Part0 end) end; if p and p~=hrp then local m=p:FindFirstAncestorWhichIsA("Model"); if m and m~=char then mdl=m; for _,ch in pairs(m:GetDescendants()) do if ch:IsA("VehicleSeat") or ch:IsA("Seat") then seat=ch break end end; if not seat then seat=p end; meth="Weld"; break end end end end end end) end
    if mdl then root=mdl.PrimaryPart; if not root then local bs,bsz=nil,0; for _,ch in pairs(mdl:GetDescendants()) do pcall(function() if ch:IsA("BasePart") and not ch:IsA("Seat") and not ch:IsA("VehicleSeat") then local s=ch.Size.Magnitude; if s>bsz then bsz=s;bs=ch end end end) end; root=bs end; if not root and seat and seat:IsA("BasePart") then root=seat end end
    return seat, mdl, root, meth
end

local function clean() for _,o in pairs(C.Inj) do pcall(function() o:Destroy() end) end; C.Inj={};spdBV=nil;gyroBG=nil;flyBV=nil;flyBG=nil;nitroBV=nil;spinBG=nil end
local function inj(cls,nm,par,props) local o=Instance.new(cls);o.Name="D_"..nm; for k,v in pairs(props) do pcall(function() o[k]=v end) end; o.Parent=par; table.insert(C.Inj,o); return o end
local function applyW() if not C.Car then return end; for _,d in pairs(C.Car:GetDescendants()) do pcall(function() if not d:IsA("BasePart") then return end; local n=d.Name:lower(); if not(n:find("wheel") or n:find("tire") or n:find("tyre")) then return end; if C.Drft then local isR=n:find("rear") or n:find("back") or n:find("rl") or n:find("rr"); local isF=n:find("front") or n:find("fl") or n:find("fr"); if isR then d.CustomPhysicalProperties=PhysicalProperties.new(0.5,math.max((100-C.RearL)/100*0.5,0.005),0,1,1) elseif isF then d.CustomPhysicalProperties=PhysicalProperties.new(0.7,C.FrontG/100,0,1,1) else d.CustomPhysicalProperties=PhysicalProperties.new(0.5,math.max((100-C.DrftAmt)/100*0.5,0.005),0,1,1) end else d.CustomPhysicalProperties=PhysicalProperties.new(1,0.5,0,1,1) end end) end end
local function setup() local r=C.Root; if not r then return end; clean(); if C.Spd>0 then spdBV=inj("BodyVelocity","Spd",r,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=10000}) end; if C.AFlip then gyroBG=inj("BodyGyro","Gyro",r,{MaxTorque=Vector3.new(C.FlipStr*700,0,C.FlipStr*700),P=2500,D=400}) end; if C.Fly then flyBV=inj("BodyVelocity","Fly",r,{MaxForce=Vector3.new(math.huge,math.huge,math.huge),Velocity=Vector3.zero,P=10000});flyBG=inj("BodyGyro","FlyG",r,{MaxTorque=Vector3.new(math.huge,math.huge,math.huge),P=5000,D=500}) end; if C.Nitro then nitroBV=inj("BodyVelocity","Nit",r,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=15000}) end; if C.Spin then spinBG=inj("BodyAngularVelocity","Spin",r,{MaxTorque=Vector3.new(0,math.huge,0),AngularVelocity=Vector3.zero}) end; applyW() end
local function resetAll() clean();C.Grav=100;pcall(function() WS.Gravity=C.OG end); if C.Car then for _,d in pairs(C.Car:GetDescendants()) do pcall(function() if d:IsA("BasePart") and(d.Name:lower():find("wheel") or d.Name:lower():find("tire")) then d.CustomPhysicalProperties=PhysicalProperties.new(1,0.5,0,1,1) end; if d:IsA("BasePart") then d.Transparency=0 end end) end end end

-- =============================================
-- MAIN FRAME
-- =============================================
local M = Instance.new("Frame")
M.Name = "Main"
M.Size = UDim2.new(0, 340, 0, 480)
M.Position = UDim2.new(0.5, -170, 0.5, -240)
M.BackgroundColor3 = P.bg
M.BorderSizePixel = 0
M.ClipsDescendants = true
M.Active = true
M.Parent = SG
Instance.new("UICorner", M).CornerRadius = UDim.new(0, 18)

-- Double stroke glow
local mS1 = Instance.new("UIStroke")
mS1.Thickness = 1
mS1.Transparency = 0.3
mS1.Color = P.p1
mS1.Parent = M

-- Subtle inner light
local iLight = Instance.new("Frame")
iLight.Size = UDim2.new(1, -2, 1, -2)
iLight.Position = UDim2.new(0, 1, 0, 1)
iLight.BackgroundColor3 = Color3.new(1, 1, 1)
iLight.BackgroundTransparency = 0.975
iLight.BorderSizePixel = 0
iLight.ZIndex = 1
iLight.Parent = M
Instance.new("UICorner", iLight).CornerRadius = UDim.new(0, 17)

-- Gradient overlay
local gOv = Instance.new("Frame")
gOv.Size = UDim2.new(1, 0, 0.4, 0)
gOv.Position = UDim2.new(0, 0, 0, 0)
gOv.BackgroundColor3 = P.p2
gOv.BackgroundTransparency = 0.94
gOv.BorderSizePixel = 0
gOv.ZIndex = 1
gOv.Parent = M

local gOvG = Instance.new("UIGradient")
gOvG.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1),
})
gOvG.Rotation = 90
gOvG.Parent = gOv

-- =============================================
-- HEADER
-- =============================================
local H = Instance.new("Frame")
H.Size = UDim2.new(1, 0, 0, 56)
H.BackgroundColor3 = P.bg
H.BackgroundTransparency = 0.2
H.BorderSizePixel = 0
H.ZIndex = 20
H.Parent = M
Instance.new("UICorner", H).CornerRadius = UDim.new(0, 18)

local hBtm = Instance.new("Frame")
hBtm.Size = UDim2.new(1, 0, 0, 18)
hBtm.Position = UDim2.new(0, 0, 1, -18)
hBtm.BackgroundColor3 = P.bg
hBtm.BackgroundTransparency = 0.2
hBtm.BorderSizePixel = 0
hBtm.ZIndex = 20
hBtm.Parent = H

-- Accent line
local hAcc = Instance.new("Frame")
hAcc.Size = UDim2.new(0.6, 0, 0, 1)
hAcc.Position = UDim2.new(0.2, 0, 1, 2)
hAcc.BorderSizePixel = 0
hAcc.ZIndex = 21
hAcc.Parent = H

local hAccG = Instance.new("UIGradient")
hAccG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
    ColorSequenceKeypoint.new(0.2, P.p1),
    ColorSequenceKeypoint.new(0.5, P.p3),
    ColorSequenceKeypoint.new(0.8, P.p4),
    ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
})
hAccG.Parent = hAcc

-- Logo
local logoBox = Instance.new("Frame")
logoBox.Size = UDim2.new(0, 36, 0, 36)
logoBox.Position = UDim2.new(0, 14, 0.5, -18)
logoBox.BackgroundColor3 = P.p2
logoBox.BackgroundTransparency = 0.88
logoBox.BorderSizePixel = 0
logoBox.ZIndex = 21
logoBox.Parent = H
Instance.new("UICorner", logoBox).CornerRadius = UDim.new(0, 10)

local logoS = Instance.new("UIStroke")
logoS.Color = P.p2
logoS.Thickness = 1
logoS.Transparency = 0.5
logoS.Parent = logoBox

local logoGrad = Instance.new("UIGradient")
logoGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, P.p1),
    ColorSequenceKeypoint.new(1, P.p3),
})
logoGrad.Rotation = 45
logoGrad.Parent = logoBox

local logoE = Instance.new("TextLabel")
logoE.Size = UDim2.new(1, 0, 1, 0)
logoE.BackgroundTransparency = 1
logoE.Text = "🏎️"
logoE.TextSize = 20
logoE.ZIndex = 22
logoE.Parent = logoBox

-- Title
local tMain = Instance.new("TextLabel")
tMain.Size = UDim2.new(0, 70, 0, 22)
tMain.Position = UDim2.new(0, 58, 0, 8)
tMain.BackgroundTransparency = 1
tMain.Text = "DRIH"
tMain.TextColor3 = P.w
tMain.TextSize = 22
tMain.Font = Enum.Font.GothamBlack
tMain.TextXAlignment = Enum.TextXAlignment.Left
tMain.ZIndex = 21
tMain.Parent = H

local tVer = Instance.new("TextLabel")
tVer.Size = UDim2.new(0, 140, 0, 11)
tVer.Position = UDim2.new(0, 60, 0, 32)
tVer.BackgroundTransparency = 1
tVer.Text = "Elite Car Tuner"
tVer.TextColor3 = P.t2
tVer.TextSize = 9
tVer.Font = Enum.Font.Gotham
tVer.TextXAlignment = Enum.TextXAlignment.Left
tVer.ZIndex = 21
tVer.Parent = H

-- Speed HUD
local spdBox = Instance.new("Frame")
spdBox.Size = UDim2.new(0, 78, 0, 30)
spdBox.Position = UDim2.new(1, -148, 0.5, -15)
spdBox.BackgroundColor3 = P.c1
spdBox.BackgroundTransparency = 0.15
spdBox.BorderSizePixel = 0
spdBox.ZIndex = 21
spdBox.Parent = H
Instance.new("UICorner", spdBox).CornerRadius = UDim.new(0, 9)

spdStr = Instance.new("UIStroke")
spdStr.Color = P.gn
spdStr.Thickness = 1
spdStr.Transparency = 0.35
spdStr.Parent = spdBox

-- Speed number
spdLbl = Instance.new("TextLabel")
spdLbl.Size = UDim2.new(0, 50, 1, 0)
spdLbl.Position = UDim2.new(0, 6, 0, 0)
spdLbl.BackgroundTransparency = 1
spdLbl.Text = "0"
spdLbl.TextColor3 = P.gn
spdLbl.TextSize = 16
spdLbl.Font = Enum.Font.GothamBlack
spdLbl.TextXAlignment = Enum.TextXAlignment.Left
spdLbl.ZIndex = 22
spdLbl.Parent = spdBox

-- Speed unit
local spdUnit = Instance.new("TextLabel")
spdUnit.Size = UDim2.new(0, 26, 0, 10)
spdUnit.Position = UDim2.new(1, -28, 0.5, -5)
spdUnit.BackgroundTransparency = 1
spdUnit.Text = "MPH"
spdUnit.TextColor3 = P.t3
spdUnit.TextSize = 7
spdUnit.Font = Enum.Font.GothamBold
spdUnit.ZIndex = 22
spdUnit.Parent = spdBox

-- Header buttons
local function hB(txt, pos, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 26)
    b.Position = pos
    b.BackgroundColor3 = col
    b.BackgroundTransparency = 0.88
    b.Text = txt
    b.TextColor3 = P.t2
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 22
    b.BorderSizePixel = 0
    b.Parent = H
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, TextColor3 = P.w}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.88, TextColor3 = P.t2}):Play()
    end)
    return b
end

local minB = hB("—", UDim2.new(1, -60, 0.5, -13), P.p1)
local clsB = hB("✕", UDim2.new(1, -30, 0.5, -13), P.p3)

-- Drag
local drg, dIn, dSt, sPo
H.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drg=true;dSt=i.Position;sPo=M.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drg=false end end) end end)
H.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then dIn=i end end)
UIS.InputChanged:Connect(function(i) if i==dIn and drg then local d=i.Position-dSt; M.Position=UDim2.new(sPo.X.Scale,sPo.X.Offset+d.X,sPo.Y.Scale,sPo.Y.Offset+d.Y) end end)

-- =============================================
-- STATUS BAR
-- =============================================
local sBar = Instance.new("Frame")
sBar.Size = UDim2.new(1, -24, 0, 34)
sBar.Position = UDim2.new(0, 12, 0, 60)
sBar.BackgroundColor3 = P.c1
sBar.BackgroundTransparency = 0.25
sBar.BorderSizePixel = 0
sBar.ZIndex = 15
sBar.Parent = M
Instance.new("UICorner", sBar).CornerRadius = UDim.new(0, 10)

local sbStr = Instance.new("UIStroke")
sbStr.Color = P.c3
sbStr.Thickness = 1
sbStr.Transparency = 0.6
sbStr.Parent = sBar

carDot = Instance.new("Frame")
carDot.Size = UDim2.new(0, 8, 0, 8)
carDot.Position = UDim2.new(0, 12, 0.5, -4)
carDot.BackgroundColor3 = P.rd
carDot.BorderSizePixel = 0
carDot.ZIndex = 16
carDot.Parent = sBar
Instance.new("UICorner", carDot).CornerRadius = UDim.new(1, 0)

-- Dot glow ring
local dotGlow = Instance.new("UIStroke")
dotGlow.Color = P.rd
dotGlow.Thickness = 2
dotGlow.Transparency = 0.7
dotGlow.Parent = carDot

carLbl = Instance.new("TextLabel")
carLbl.Size = UDim2.new(0.5, 0, 1, 0)
carLbl.Position = UDim2.new(0, 28, 0, 0)
carLbl.BackgroundTransparency = 1
carLbl.Text = "No car connected"
carLbl.TextColor3 = P.t3
carLbl.TextSize = 9
carLbl.Font = Enum.Font.GothamMedium
carLbl.TextXAlignment = Enum.TextXAlignment.Left
carLbl.ZIndex = 16
carLbl.Parent = sBar

local cBtn = Instance.new("TextButton")
cBtn.Size = UDim2.new(0, 76, 0, 22)
cBtn.Position = UDim2.new(1, -84, 0.5, -11)
cBtn.BackgroundColor3 = P.p1
cBtn.BackgroundTransparency = 0.2
cBtn.Text = "Connect"
cBtn.TextColor3 = P.w
cBtn.TextSize = 9
cBtn.Font = Enum.Font.GothamBold
cBtn.ZIndex = 16
cBtn.BorderSizePixel = 0
cBtn.Parent = sBar
Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 7)

local cBtnG = Instance.new("UIGradient")
cBtnG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, P.p1),
    ColorSequenceKeypoint.new(1, P.p2),
})
cBtnG.Parent = cBtn

cBtn.MouseButton1Click:Connect(function()
    local seat, car, root, meth = findCar()
    if seat and car then
        C.Seat=seat; C.Car=car; C.Root=root
        carLbl.Text=car.Name; carLbl.TextColor3=P.gn
        carDot.BackgroundColor3=P.gn; dotGlow.Color=P.gn
        lg("Connected: "..car.Name, P.gn)
        nf("Connected to "..car.Name, P.gn)
        setup()
    else
        carLbl.Text="Not found"; carLbl.TextColor3=P.rd
        carDot.BackgroundColor3=P.rd; dotGlow.Color=P.rd
        nf("Sit in a car first", P.or_)
    end
end)
cBtn.MouseEnter:Connect(function() TweenService:Create(cBtn, TweenInfo.new(0.1), {BackgroundTransparency=0.05}):Play() end)
cBtn.MouseLeave:Connect(function() TweenService:Create(cBtn, TweenInfo.new(0.1), {BackgroundTransparency=0.2}):Play() end)

-- =============================================
-- CONTENT SCROLL
-- =============================================
local Co = Instance.new("ScrollingFrame")
Co.Size = UDim2.new(1, -24, 1, -102)
Co.Position = UDim2.new(0, 12, 0, 98)
Co.BackgroundTransparency = 1
Co.BorderSizePixel = 0
Co.ScrollBarThickness = 2
Co.ScrollBarImageColor3 = P.p2
Co.AutomaticCanvasSize = Enum.AutomaticSize.Y
Co.ZIndex = 10
Co.Parent = M

local coL = Instance.new("UIListLayout")
coL.Padding = UDim.new(0, 5)
coL.SortOrder = Enum.SortOrder.LayoutOrder
coL.Parent = Co
Instance.new("UIPadding", Co).PaddingBottom = UDim.new(0, 12)

-- =============================================
-- ELITE UI BUILDERS
-- =============================================
local function Sec(t, o)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder = o
    f.ZIndex = 10
    f.Parent = Co

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0, 0, 0.5, -2)
    dot.BackgroundColor3 = P.p2
    dot.BorderSizePixel = 0
    dot.ZIndex = 11
    dot.Parent = f
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 1)
    l.BackgroundTransparency = 1
    l.Text = string.upper(t)
    l.TextColor3 = P.t2
    l.TextSize = 8
    l.Font = Enum.Font.GothamBlack
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 11
    l.Parent = f
end

local function Sl(t, ic, mn, mx, df, o, cb)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 48)
    card.BackgroundColor3 = P.c1
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.LayoutOrder = o
    card.ZIndex = 10
    card.Parent = Co
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    -- Subtle card border
    local cStr = Instance.new("UIStroke")
    cStr.Color = P.c3
    cStr.Thickness = 1
    cStr.Transparency = 0.7
    cStr.Parent = card

    -- Icon pill
    local iPill = Instance.new("Frame")
    iPill.Size = UDim2.new(0, 26, 0, 26)
    iPill.Position = UDim2.new(0, 10, 0, 5)
    iPill.BackgroundColor3 = P.p2
    iPill.BackgroundTransparency = 0.88
    iPill.BorderSizePixel = 0
    iPill.ZIndex = 11
    iPill.Parent = card
    Instance.new("UICorner", iPill).CornerRadius = UDim.new(0, 7)

    local iT = Instance.new("TextLabel")
    iT.Size = UDim2.new(1, 0, 1, 0)
    iT.BackgroundTransparency = 1
    iT.Text = ic
    iT.TextSize = 13
    iT.ZIndex = 12
    iT.Parent = iPill

    -- Label
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.4, 0, 0, 14)
    lb.Position = UDim2.new(0, 42, 0, 7)
    lb.BackgroundTransparency = 1
    lb.Text = t
    lb.TextColor3 = P.t1
    lb.TextSize = 10
    lb.Font = Enum.Font.GothamMedium
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 11
    lb.Parent = card

    -- Value badge
    local vBadge = Instance.new("Frame")
    vBadge.Size = UDim2.new(0, 36, 0, 18)
    vBadge.Position = UDim2.new(1, -44, 0, 6)
    vBadge.BackgroundColor3 = P.p1
    vBadge.BackgroundTransparency = 0.82
    vBadge.BorderSizePixel = 0
    vBadge.ZIndex = 11
    vBadge.Parent = card
    Instance.new("UICorner", vBadge).CornerRadius = UDim.new(0, 6)

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(1, 0, 1, 0)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(df)
    vl.TextColor3 = P.w
    vl.TextSize = 9
    vl.Font = Enum.Font.GothamBlack
    vl.ZIndex = 12
    vl.Parent = vBadge

    -- Track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 5)
    track.Position = UDim2.new(0, 10, 0, 34)
    track.BackgroundColor3 = P.c3
    track.BackgroundTransparency = 0.3
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
        ColorSequenceKeypoint.new(0, P.p1),
        ColorSequenceKeypoint.new(0.6, P.p2),
        ColorSequenceKeypoint.new(1, P.p3),
    })
    fG.Parent = fill

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(fr, -6, 0.5, -6)
    knob.BackgroundColor3 = P.w
    knob.BorderSizePixel = 0
    knob.ZIndex = 13
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local kS = Instance.new("UIStroke")
    kS.Color = P.p2
    kS.Thickness = 2
    kS.Transparency = 0.2
    kS.Parent = knob

    -- Inner dot
    local kDot = Instance.new("Frame")
    kDot.Size = UDim2.new(0, 4, 0, 4)
    kDot.Position = UDim2.new(0.5, -2, 0.5, -2)
    kDot.BackgroundColor3 = P.p2
    kDot.BorderSizePixel = 0
    kDot.ZIndex = 14
    kDot.Parent = knob
    Instance.new("UICorner", kDot).CornerRadius = UDim.new(1, 0)

    local sd = false
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(1, 0, 0, 18)
    sb.Position = UDim2.new(0, 0, 0, -6)
    sb.BackgroundTransparency = 1
    sb.Text = ""
    sb.ZIndex = 15
    sb.Parent = track

    sb.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sd = true end end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sd = false end end)
    UIS.InputChanged:Connect(function(inp)
        if sd and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(mn + r * (mx - mn))
            vl.Text = tostring(v)
            fill.Size = UDim2.new(r, 0, 1, 0)
            knob.Position = UDim2.new(r, -6, 0.5, -6)
            cb(v)
        end
    end)

    -- Hover effect
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(cStr, TweenInfo.new(0.15), {Transparency = 0.4, Color = P.p2}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(cStr, TweenInfo.new(0.15), {Transparency = 0.7, Color = P.c3}):Play()
    end)
end

local function Tog(t, ic, df, o, cb)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 34)
    card.BackgroundColor3 = P.c1
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.LayoutOrder = o
    card.ZIndex = 10
    card.Parent = Co
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local cStr = Instance.new("UIStroke")
    cStr.Color = P.c3
    cStr.Thickness = 1
    cStr.Transparency = 0.7
    cStr.Parent = card

    -- Icon
    local iPill = Instance.new("Frame")
    iPill.Size = UDim2.new(0, 22, 0, 22)
    iPill.Position = UDim2.new(0, 8, 0.5, -11)
    iPill.BackgroundColor3 = P.p2
    iPill.BackgroundTransparency = 0.88
    iPill.BorderSizePixel = 0
    iPill.ZIndex = 11
    iPill.Parent = card
    Instance.new("UICorner", iPill).CornerRadius = UDim.new(0, 6)

    local iT = Instance.new("TextLabel")
    iT.Size = UDim2.new(1, 0, 1, 0)
    iT.BackgroundTransparency = 1
    iT.Text = ic
    iT.TextSize = 11
    iT.ZIndex = 12
    iT.Parent = iPill

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.6, 0, 1, 0)
    lb.Position = UDim2.new(0, 36, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = t
    lb.TextColor3 = P.t1
    lb.TextSize = 10
    lb.Font = Enum.Font.GothamMedium
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 11
    lb.Parent = card

    -- Toggle switch
    local tBg = Instance.new("Frame")
    tBg.Size = UDim2.new(0, 36, 0, 18)
    tBg.Position = UDim2.new(1, -44, 0.5, -9)
    tBg.BackgroundColor3 = df and P.p1 or P.c3
    tBg.BorderSizePixel = 0
    tBg.ZIndex = 11
    tBg.Parent = card
    Instance.new("UICorner", tBg).CornerRadius = UDim.new(1, 0)

    -- Toggle gradient when on
    local tGrad = Instance.new("UIGradient")
    tGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.p1),
        ColorSequenceKeypoint.new(1, P.p2),
    })
    tGrad.Parent = tBg

    local tDot = Instance.new("Frame")
    tDot.Size = UDim2.new(0, 12, 0, 12)
    tDot.Position = df and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    tDot.BackgroundColor3 = P.w
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
        TweenService:Create(tBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = en and P.p1 or P.c3
        }):Play()
        TweenService:Create(tDot, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = en and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        }):Play()
    end)

    -- Hover
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(cStr, TweenInfo.new(0.15), {Transparency = 0.4, Color = P.p2}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(cStr, TweenInfo.new(0.15), {Transparency = 0.7, Color = P.c3}):Play()
    end)
end

local function Btn(t, o, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 32)
    b.BackgroundColor3 = P.c1
    b.BackgroundTransparency = 0.2
    b.BorderSizePixel = 0
    b.Text = t
    b.TextColor3 = P.t1
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.LayoutOrder = o
    b.ZIndex = 10
    b.Parent = Co
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

    local bStr = Instance.new("UIStroke")
    bStr.Color = P.c3
    bStr.Thickness = 1
    bStr.Transparency = 0.7
    bStr.Parent = b

    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(bStr, TweenInfo.new(0.15), {Color = P.p2, Transparency = 0.4}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(bStr, TweenInfo.new(0.15), {Color = P.c3, Transparency = 0.7}):Play()
    end)
end

-- =============================================
-- CONTENT LAYOUT
-- =============================================
Sec("Speed & Power", 0)
Sl("Speed Boost", "🏁", 0, 400, 0, 1, function(v) C.Spd=v; if v>0 and C.Root and(not spdBV or not spdBV.Parent) then spdBV=inj("BodyVelocity","Spd",C.Root,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=10000}) end; if spdBV and spdBV.Parent then spdBV.MaxForce=v>0 and Vector3.new(v*200,0,v*200) or Vector3.zero end end)
Sl("Speed Limiter", "🚫", 0, 500, 0, 2, function(v) C.Lim=v end)
Tog("Nitro Boost · Hold N", "🔥", false, 3, function(v) C.Nitro=v; if v and C.Root then if not nitroBV or not nitroBV.Parent then nitroBV=inj("BodyVelocity","Nit",C.Root,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=15000}) end else if nitroBV then pcall(function() nitroBV:Destroy() end);nitroBV=nil end end end)
Sl("Nitro Force", "💥", 50, 600, 150, 4, function(v) C.NitroF=v end)

Sec("Drift Controls", 5)
Tog("Enable Drift", "🔄", false, 6, function(v) C.Drft=v;applyW() end)
Sl("Drift Intensity", "💫", 0, 100, 95, 7, function(v) C.DrftAmt=v;if C.Drft then applyW() end end)
Sl("Rear Looseness", "🔙", 0, 100, 70, 8, function(v) C.RearL=v;if C.Drft then applyW() end end)
Sl("Front Grip", "🔜", 0, 100, 80, 9, function(v) C.FrontG=v;if C.Drft then applyW() end end)
Tog("Handbrake · Hold H", "🅿️", false, 10, function(v) C.HBrk=v end)
Sl("Brake Force", "🛑", 0, 100, 50, 11, function(v) C.BrkPow=v end)
Tog("Low-G Drift · 35%", "🌙", false, 12, function(v) C.Grav=v and 35 or 100 end)
Tog("Spin Mode · Hold J", "🌀", false, 13, function(v) C.Spin=v; if v and C.Root then if not spinBG or not spinBG.Parent then spinBG=inj("BodyAngularVelocity","Spin",C.Root,{MaxTorque=Vector3.new(0,math.huge,0),AngularVelocity=Vector3.zero}) end else if spinBG then pcall(function() spinBG:Destroy() end);spinBG=nil end end end)
Sl("Spin Speed", "🌀", 5, 100, 30, 14, function(v) C.SpinSpd=v end)

Sec("Physics", 15)
Sl("Gravity", "🪨", 2, 300, 100, 16, function(v) C.Grav=v end)
Tog("Moon Mode · 10%", "🌙", false, 17, function(v) C.Grav=v and 10 or 100 end)
Tog("Bounce Mode", "🏀", false, 18, function(v) C.Bounce=v end)
Tog("Anti-Flip", "🛡️", true, 19, function(v) C.AFlip=v; if C.Root then if v then if not gyroBG or not gyroBG.Parent then gyroBG=inj("BodyGyro","Gyro",C.Root,{MaxTorque=Vector3.new(C.FlipStr*700,0,C.FlipStr*700),P=2500,D=400}) end else if gyroBG then pcall(function() gyroBG:Destroy() end);gyroBG=nil end end end end)
Sl("Flip Strength", "💪", 10, 100, 60, 20, function(v) C.FlipStr=v; if gyroBG and gyroBG.Parent then gyroBG.MaxTorque=Vector3.new(v*700,0,v*700) end end)

Sec("Movement", 21)
Tog("Car Jump · Space", "🦘", false, 22, function(v) C.Jump=v end)
Sl("Jump Power", "⬆️", 20, 250, 75, 23, function(v) C.JumpPow=v end)
Tog("Fly Mode · WASD", "✈️", false, 24, function(v) C.Fly=v; if C.Root then if v then if not flyBV or not flyBV.Parent then flyBV=inj("BodyVelocity","Fly",C.Root,{MaxForce=Vector3.new(math.huge,math.huge,math.huge),Velocity=Vector3.zero,P=10000}) end; if not flyBG or not flyBG.Parent then flyBG=inj("BodyGyro","FlyG",C.Root,{MaxTorque=Vector3.new(math.huge,math.huge,math.huge),P=5000,D=500}) end else if flyBV then pcall(function() flyBV:Destroy() end);flyBV=nil end; if flyBG then pcall(function() flyBG:Destroy() end);flyBG=nil end end end end)
Sl("Fly Speed", "💨", 10, 500, 80, 25, function(v) C.FlySpd=v end)

Sec("Visuals", 26)
Tog("Ghost Car", "👻", false, 27, function(v) C.Invis=v; if C.Car then for _,d in pairs(C.Car:GetDescendants()) do pcall(function() if d:IsA("BasePart") then d.Transparency=v and 0.8 or 0 end end) end end end)
Tog("Neon Trail", "✨", false, 28, function(v) C.Trail=v; if v and C.Root then local a0=Instance.new("Attachment");a0.Name="D_A0";a0.Position=Vector3.new(0,0,-3);a0.Parent=C.Root; local a1=Instance.new("Attachment");a1.Name="D_A1";a1.Position=Vector3.new(0,0,3);a1.Parent=C.Root; local tr=Instance.new("Trail");tr.Name="D_Trail";tr.Attachment0=a0;tr.Attachment1=a1;tr.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,P.p1),ColorSequenceKeypoint.new(0.5,P.p3),ColorSequenceKeypoint.new(1,P.p4)});tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)});tr.Lifetime=2;tr.MinLength=0.1;tr.LightEmission=0.5;tr.Parent=C.Root;table.insert(C.Inj,a0);table.insert(C.Inj,a1);table.insert(C.Inj,tr) else for i=#C.Inj,1,-1 do pcall(function() local o=C.Inj[i]; if o.Name=="D_Trail" or o.Name=="D_A0" or o.Name=="D_A1" then o:Destroy();table.remove(C.Inj,i) end end) end end end)

Sec("Actions", 29)
Btn("✅  Re-inject Forces", 30, function() if not C.Root then nf("Sit in a car first",P.or_) return end; setup(); lg("Forces applied",P.gn); nf("Forces applied",P.p1) end)
Btn("↩️  Reset Everything", 31, function() resetAll(); lg("Reset complete",P.t3); nf("Reset complete",P.t2) end)
Btn("🏃  Walk Speed 100", 32, function() pcall(function() char.Humanoid.WalkSpeed=100 end) end)
Btn("💀  Reset Character", 33, function() pcall(function() char.Humanoid.Health=0 end) end)
Btn("🔄  Rejoin Server", 34, function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,plr) end) end)
Btn("🔍  Scan Car Parts", 35, function()
    if not C.Car then lg("No car connected",P.or_) return end
    lg("══ "..C.Car.Name.." ══",P.p2)
    local t={}; for _,d in pairs(C.Car:GetDescendants()) do pcall(function() t[d.ClassName]=(t[d.ClassName] or 0)+1 end) end
    for cn,ct in pairs(t) do lg("  "..cn.." × "..ct,P.t3) end
end)

Sec("Log", 36)

logP = Instance.new("ScrollingFrame")
logP.Size = UDim2.new(1, 0, 0, 70)
logP.BackgroundColor3 = P.c1
logP.BackgroundTransparency = 0.3
logP.BorderSizePixel = 0
logP.ScrollBarThickness = 1
logP.ScrollBarImageColor3 = P.p2
logP.AutomaticCanvasSize = Enum.AutomaticSize.Y
logP.LayoutOrder = 37
logP.ZIndex = 10
logP.Parent = Co
Instance.new("UICorner", logP).CornerRadius = UDim.new(0, 10)

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

    -- Speed HUD
    pcall(function()
        local spd = math.floor(root.Velocity.Magnitude)
        spdLbl.Text = tostring(spd)
        local col = spd > 150 and P.rd or spd > 80 and P.or_ or P.gn
        spdLbl.TextColor3 = col
        spdStr.Color = col
    end)

    if spdBV and spdBV.Parent and C.Spd > 0 then local fw=root.CFrame.LookVector; spdBV.Velocity=Vector3.new(fw.X*C.Spd,0,fw.Z*C.Spd) end
    if C.Lim > 0 then local v=root.Velocity;local hs=Vector3.new(v.X,0,v.Z).Magnitude; if hs>C.Lim then local r=C.Lim/hs; root.Velocity=Vector3.new(v.X*r,v.Y,v.Z*r); pcall(function() root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X*r,root.AssemblyLinearVelocity.Y,root.AssemblyLinearVelocity.Z*r) end) end end
    if C.Nitro and nitroBV and nitroBV.Parent then if UIS:IsKeyDown(Enum.KeyCode.N) then local fw=root.CFrame.LookVector;nitroBV.Velocity=fw*C.NitroF;nitroBV.MaxForce=Vector3.new(C.NitroF*300,0,C.NitroF*300) else nitroBV.MaxForce=Vector3.zero end end
    if C.HBrk and UIS:IsKeyDown(Enum.KeyCode.H) then local v=root.Velocity;local b=1-(C.BrkPow/100*0.15);root.Velocity=Vector3.new(v.X*b,v.Y,v.Z*b);pcall(function() root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X*b,root.AssemblyLinearVelocity.Y,root.AssemblyLinearVelocity.Z*b) end) end
    if C.Spin and spinBG and spinBG.Parent then spinBG.AngularVelocity=UIS:IsKeyDown(Enum.KeyCode.J) and Vector3.new(0,C.SpinSpd,0) or Vector3.zero end
    if C.Bounce then local v=root.Velocity; if v.Y<-5 then root.Velocity=Vector3.new(v.X,math.abs(v.Y)*0.8,v.Z) end end
    if C.Fly and flyBV and flyBV.Parent then local cam=WS.CurrentCamera;local dir=Vector3.zero; if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end; if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end; if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end; if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end; if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.yAxis end; if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.yAxis end; flyBV.Velocity=dir.Magnitude>0 and dir.Unit*C.FlySpd or Vector3.zero; if flyBG and flyBG.Parent then flyBG.CFrame=cam.CFrame end end

    fc += 1
    if fc >= 120 then
        fc = 0
        local seat, car, rt, meth = findCar()
        if seat and car then
            if C.Car ~= car then
                resetAll(); C.Seat=seat; C.Car=car; C.Root=rt
                carLbl.Text=car.Name; carLbl.TextColor3=P.gn
                carDot.BackgroundColor3=P.gn; dotGlow.Color=P.gn
                lg("Auto: "..car.Name, P.gn); setup()
            end
        else
            if C.Car then
                resetAll(); C.Car=nil; C.Root=nil; C.Seat=nil
                carLbl.Text="No car"; carLbl.TextColor3=P.t3
                carDot.BackgroundColor3=P.rd; dotGlow.Color=P.rd
            end
        end
        -- Animations
        pcall(function() local h=(tick()*0.018)%1; mS1.Color=Color3.fromHSV(h,0.4,0.85) end)
        pcall(function() logoE.Rotation=math.sin(tick()*1.5)*5 end)
        pcall(function() hAccG.Offset=Vector2.new(math.sin(tick()*0.6)*0.2,0) end)
        pcall(function() if C.Car then carDot.BackgroundTransparency=0.2+math.sin(tick()*3)*0.2; dotGlow.Transparency=0.5+math.sin(tick()*3)*0.2 else carDot.BackgroundTransparency=0; dotGlow.Transparency=0.7 end end)
    end
end)

UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Space and C.Jump and C.Root and C.Root.Parent then
        pcall(function() local bv=Instance.new("BodyVelocity");bv.Name="D_Jmp";bv.MaxForce=Vector3.new(0,math.huge,0);bv.Velocity=Vector3.new(0,C.JumpPow,0);bv.Parent=C.Root;task.delay(0.2,function() pcall(function() bv:Destroy() end) end) end)
    end
    if inp.KeyCode == Enum.KeyCode.RightShift then M.Visible = not M.Visible end
end)

local mini = false
minB.MouseButton1Click:Connect(function()
    mini = not mini
    TweenService:Create(M, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        Size = mini and UDim2.new(0, 340, 0, 56) or UDim2.new(0, 340, 0, 480)
    }):Play()
    minB.Text = mini and "+" or "—"
end)

clsB.MouseButton1Click:Connect(function()
    resetAll()
    TweenService:Create(M, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }):Play()
    task.wait(0.3) SG:Destroy()
end)

-- =============================================
-- INTRO
-- =============================================
M.Size = UDim2.new(0, 0, 0, 0)
M.Position = UDim2.new(0.5, 0, 0.5, 0)
M.BackgroundTransparency = 1

TweenService:Create(M, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 340, 0, 480),
    Position = UDim2.new(0.5, -170, 0.5, -240),
    BackgroundTransparency = 0
}):Play()

task.wait(0.55)
nf("DRIH v5.0 — Elite Edition", P.p2)
lg("DRIH v5.0 loaded", P.p2)
lg("N·Nitro  H·Brake  J·Spin  Space·Jump", P.t3)

print("=== DRIH v5.0 ===")
print("RIGHT SHIFT = Toggle")
