-- =============================================
-- DRIH v3.0 - Minimal Premium
-- Ultra optimized | Beautiful | Zero lag
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
    Car=nil,Root=nil,Seat=nil,Inj={},OG=WS.Gravity,SL=nil,
}

pcall(function() if pg:FindFirstChild("DrihGUI") then pg.DrihGUI:Destroy() end end)
local SG = Instance.new("ScreenGui")
SG.Name="DrihGUI"; SG.ResetOnSpawn=false; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.Parent=pg

-- Theme
local A = Color3.fromRGB(120,55,245)
local A2 = Color3.fromRGB(240,55,170)
local BG = Color3.fromRGB(8,8,13)
local CD = Color3.fromRGB(14,14,21)
local TX = Color3.fromRGB(205,200,220)
local DM = Color3.fromRGB(90,85,110)
local GR = Color3.fromRGB(55,215,115)
local RD = Color3.fromRGB(245,55,75)
local OR = Color3.fromRGB(245,155,45)

-- Log
local logP,logC = nil,0
local function lg(m,c)
    if not logP then return end; logC+=1
    local e=Instance.new("TextLabel"); e.Size=UDim2.new(1,0,0,11); e.BackgroundTransparency=1
    e.Text=os.date("[%H:%M] ")..m; e.TextColor3=c or DM; e.TextSize=8; e.Font=Enum.Font.Code
    e.TextXAlignment=Enum.TextXAlignment.Left; e.TextTruncate=Enum.TextTruncate.AtEnd
    e.LayoutOrder=logC; e.ZIndex=12; e.Parent=logP
    task.defer(function() pcall(function() logP.CanvasPosition=Vector2.new(0,logP.AbsoluteCanvasSize.Y) end) end)
    if logC>30 then for _,ch in pairs(logP:GetChildren()) do if ch:IsA("TextLabel") then ch:Destroy() break end end end
end

local function nf(t,c)
    local f=Instance.new("Frame"); f.Size=UDim2.new(0,250,0,34); f.Position=UDim2.new(0.5,-125,0,-38)
    f.BackgroundColor3=Color3.fromRGB(10,10,16); f.BackgroundTransparency=0.02
    f.BorderSizePixel=0; f.ZIndex=100; f.Parent=SG
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)
    local s=Instance.new("UIStroke"); s.Color=c or A; s.Thickness=1.5; s.Transparency=0.25; s.Parent=f
    local g=Instance.new("Frame"); g.Size=UDim2.new(0.5,0,0,2); g.Position=UDim2.new(0.25,0,0,0)
    g.BackgroundColor3=c or A; g.BorderSizePixel=0; g.ZIndex=101; g.Parent=f
    Instance.new("UICorner",g).CornerRadius=UDim.new(0,1)
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-14,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=t; l.TextColor3=Color3.new(1,1,1); l.TextSize=11
    l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=102; l.Parent=f
    TweenService:Create(f,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-125,0,10)}):Play()
    task.delay(2.5,function()
        TweenService:Create(f,TweenInfo.new(0.2),{Position=UDim2.new(0.5,-125,0,-42),BackgroundTransparency=1}):Play()
        task.wait(0.25) pcall(function() f:Destroy() end)
    end)
end

-- Car detect
local carSt,carDot
local function findCar()
    local seat,mdl,root,meth=nil,nil,nil,"None"
    pcall(function() local h=char and char:FindFirstChildOfClass("Humanoid")
        if h and h.SeatPart then seat=h.SeatPart; mdl=seat:FindFirstAncestorWhichIsA("Model")
            if mdl==char then mdl=nil;seat=nil else meth="SeatPart" end end end)
    if not seat then pcall(function() local h=char and char:FindFirstChildOfClass("Humanoid")
        if h then for _,d in pairs(WS:GetDescendants()) do pcall(function()
            if (d:IsA("VehicleSeat") or d:IsA("Seat")) and d.Occupant==h then seat=d;mdl=d:FindFirstAncestorWhichIsA("Model");meth="Occupant" end
        end) end end end) end
    if not seat then pcall(function() local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if hrp then for _,w in pairs(hrp:GetChildren()) do if w:IsA("Weld") or w:IsA("WeldConstraint") then
            local p; pcall(function() p=w.Part1 end); if not p then pcall(function() p=w.Part0 end) end
            if p and p~=hrp then local m=p:FindFirstAncestorWhichIsA("Model")
                if m and m~=char then mdl=m; for _,ch in pairs(m:GetDescendants()) do
                    if ch:IsA("VehicleSeat") or ch:IsA("Seat") then seat=ch break end end
                    if not seat then seat=p end; meth="Weld"; break end end
        end end end end) end
    if mdl then root=mdl.PrimaryPart
        if not root then local bs,bsz=nil,0; for _,ch in pairs(mdl:GetDescendants()) do pcall(function()
            if ch:IsA("BasePart") and not ch:IsA("Seat") and not ch:IsA("VehicleSeat") then
                local s=ch.Size.Magnitude; if s>bsz then bsz=s;bs=ch end end end) end; root=bs end
        if not root and seat and seat:IsA("BasePart") then root=seat end end
    return seat,mdl,root,meth
end

-- Forces
local spdBV,gyroBG,flyBV,flyBG,nitroBV,spinBG
local function clean() for _,o in pairs(C.Inj) do pcall(function() o:Destroy() end) end; C.Inj={};spdBV=nil;gyroBG=nil;flyBV=nil;flyBG=nil;nitroBV=nil;spinBG=nil end
local function inj(cls,nm,par,props) local o=Instance.new(cls);o.Name="D_"..nm; for k,v in pairs(props) do pcall(function() o[k]=v end) end; o.Parent=par; table.insert(C.Inj,o); return o end

local function applyW()
    if not C.Car then return end
    for _,d in pairs(C.Car:GetDescendants()) do pcall(function()
        if not d:IsA("BasePart") then return end; local n=d.Name:lower()
        if not(n:find("wheel") or n:find("tire") or n:find("tyre")) then return end
        if C.Drft then
            local isR=n:find("rear") or n:find("back") or n:find("rl") or n:find("rr")
            local isF=n:find("front") or n:find("fl") or n:find("fr")
            if isR then d.CustomPhysicalProperties=PhysicalProperties.new(0.5,math.max((100-C.RearL)/100*0.5,0.005),0,1,1)
            elseif isF then d.CustomPhysicalProperties=PhysicalProperties.new(0.7,C.FrontG/100,0,1,1)
            else d.CustomPhysicalProperties=PhysicalProperties.new(0.5,math.max((100-C.DrftAmt)/100*0.5,0.005),0,1,1) end
        else d.CustomPhysicalProperties=PhysicalProperties.new(1,0.5,0,1,1) end
    end) end
end

local function setup()
    local r=C.Root; if not r then return end; clean()
    if C.Spd>0 then spdBV=inj("BodyVelocity","Spd",r,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=10000}) end
    if C.AFlip then gyroBG=inj("BodyGyro","Gyro",r,{MaxTorque=Vector3.new(C.FlipStr*700,0,C.FlipStr*700),P=2500,D=400}) end
    if C.Fly then flyBV=inj("BodyVelocity","Fly",r,{MaxForce=Vector3.new(math.huge,math.huge,math.huge),Velocity=Vector3.zero,P=10000});flyBG=inj("BodyGyro","FlyG",r,{MaxTorque=Vector3.new(math.huge,math.huge,math.huge),P=5000,D=500}) end
    if C.Nitro then nitroBV=inj("BodyVelocity","Nit",r,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=15000}) end
    if C.Spin then spinBG=inj("BodyAngularVelocity","Spin",r,{MaxTorque=Vector3.new(0,math.huge,0),AngularVelocity=Vector3.zero}) end
    applyW()
end

local function resetAll()
    clean();C.Grav=100;C.Nitro=false;C.HBrk=false;C.Spin=false
    pcall(function() WS.Gravity=C.OG end)
    if C.Car then for _,d in pairs(C.Car:GetDescendants()) do pcall(function()
        if d:IsA("BasePart") and(d.Name:lower():find("wheel") or d.Name:lower():find("tire")) then d.CustomPhysicalProperties=PhysicalProperties.new(1,0.5,0,1,1) end
        if d:IsA("BasePart") then d.Transparency=0 end
    end) end end
end

-- =============================================
-- GUI
-- =============================================
local M = Instance.new("Frame")
M.Name="Main"; M.Size=UDim2.new(0,380,0,500)
M.Position=UDim2.new(0.5,-190,0.5,-250)
M.BackgroundColor3=BG; M.BackgroundTransparency=0.01
M.BorderSizePixel=0; M.ClipsDescendants=true; M.Active=true; M.Parent=SG
Instance.new("UICorner",M).CornerRadius=UDim.new(0,14)

-- Glow border
local mS=Instance.new("UIStroke"); mS.Thickness=1.5; mS.Transparency=0.2; mS.Color=A; mS.Parent=M

-- Accent bar
local ab=Instance.new("Frame"); ab.Size=UDim2.new(0,2,0.8,0); ab.Position=UDim2.new(0,0,0.1,0)
ab.BorderSizePixel=0; ab.ZIndex=2; ab.Parent=M
local abG=Instance.new("UIGradient"); abG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,A),ColorSequenceKeypoint.new(0.5,A2),ColorSequenceKeypoint.new(1,Color3.fromRGB(45,140,255))
}); abG.Rotation=90; abG.Parent=ab

-- Title
local TB=Instance.new("Frame"); TB.Size=UDim2.new(1,0,0,46); TB.BackgroundColor3=Color3.fromRGB(6,6,10)
TB.BackgroundTransparency=0.1; TB.BorderSizePixel=0; TB.ZIndex=10; TB.Parent=M
Instance.new("UICorner",TB).CornerRadius=UDim.new(0,14)
local tbB=Instance.new("Frame"); tbB.Size=UDim2.new(1,0,0,14); tbB.Position=UDim2.new(0,0,1,-14)
tbB.BackgroundColor3=Color3.fromRGB(6,6,10); tbB.BackgroundTransparency=0.1; tbB.BorderSizePixel=0; tbB.ZIndex=10; tbB.Parent=TB

-- Title accent
local tA=Instance.new("Frame"); tA.Size=UDim2.new(0.6,0,0,1.5); tA.Position=UDim2.new(0.2,0,1,1)
tA.BorderSizePixel=0; tA.ZIndex=11; tA.Parent=TB
local tAG=Instance.new("UIGradient"); tAG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(60,25,140)),
    ColorSequenceKeypoint.new(0.5,A),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(60,25,140))
}); tAG.Parent=tA

-- Logo
local lF=Instance.new("Frame"); lF.Size=UDim2.new(0,28,0,28); lF.Position=UDim2.new(0,10,0.5,-14)
lF.BackgroundColor3=A; lF.BackgroundTransparency=0.88; lF.BorderSizePixel=0; lF.ZIndex=11; lF.Parent=TB
Instance.new("UICorner",lF).CornerRadius=UDim.new(0,7)
local lS=Instance.new("UIStroke"); lS.Color=A; lS.Thickness=1; lS.Transparency=0.55; lS.Parent=lF
local lT=Instance.new("TextLabel"); lT.Size=UDim2.new(1,0,1,0); lT.BackgroundTransparency=1
lT.Text="🏎️"; lT.TextSize=16; lT.ZIndex=12; lT.Parent=lF

-- Title text
local tN=Instance.new("TextLabel"); tN.Size=UDim2.new(0,55,0,18); tN.Position=UDim2.new(0,44,0,6)
tN.BackgroundTransparency=1; tN.Text="DRIH"; tN.TextColor3=Color3.new(1,1,1)
tN.TextSize=18; tN.Font=Enum.Font.GothamBlack; tN.TextXAlignment=Enum.TextXAlignment.Left
tN.ZIndex=11; tN.Parent=TB

local tSu=Instance.new("TextLabel"); tSu.Size=UDim2.new(0,140,0,9); tSu.Position=UDim2.new(0,46,0,26)
tSu.BackgroundTransparency=1; tSu.Text="Premium Car Tuner v3"; tSu.TextColor3=DM
tSu.TextSize=7; tSu.Font=Enum.Font.Gotham; tSu.TextXAlignment=Enum.TextXAlignment.Left
tSu.ZIndex=11; tSu.Parent=TB

-- Speed HUD
local sF=Instance.new("Frame"); sF.Size=UDim2.new(0,72,0,24); sF.Position=UDim2.new(1,-136,0.5,-12)
sF.BackgroundColor3=Color3.fromRGB(8,8,14); sF.BackgroundTransparency=0.15
sF.BorderSizePixel=0; sF.ZIndex=11; sF.Parent=TB
Instance.new("UICorner",sF).CornerRadius=UDim.new(0,6)
local sFS=Instance.new("UIStroke"); sFS.Color=GR; sFS.Thickness=1; sFS.Transparency=0.45; sFS.Parent=sF
C.SL=Instance.new("TextLabel"); C.SL.Size=UDim2.new(1,0,1,0); C.SL.BackgroundTransparency=1
C.SL.Text="0 MPH"; C.SL.TextColor3=GR; C.SL.TextSize=11; C.SL.Font=Enum.Font.GothamBlack
C.SL.ZIndex=12; C.SL.Parent=sF

-- Buttons
local function mkB(t,p,c)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0,22,0,22); b.Position=p
    b.BackgroundColor3=c; b.BackgroundTransparency=0.8; b.Text=t
    b.TextColor3=Color3.fromRGB(180,180,200); b.TextSize=10; b.Font=Enum.Font.GothamBold
    b.ZIndex=12; b.BorderSizePixel=0; b.Parent=TB
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0.4}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0.8}):Play() end)
    return b
end
local minB=mkB("—",UDim2.new(1,-52,0.5,-11),Color3.fromRGB(75,55,135))
local clsB=mkB("✕",UDim2.new(1,-26,0.5,-11),Color3.fromRGB(150,35,70))

-- Drag
local drg,dIn,dSt,sPo
TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drg=true;dSt=i.Position;sPo=M.Position;i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drg=false end end) end end)
TB.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then dIn=i end end)
UIS.InputChanged:Connect(function(i) if i==dIn and drg then local d=i.Position-dSt;M.Position=UDim2.new(sPo.X.Scale,sPo.X.Offset+d.X,sPo.Y.Scale,sPo.Y.Offset+d.Y) end end)

-- Status
local sB=Instance.new("Frame"); sB.Size=UDim2.new(1,-14,0,30); sB.Position=UDim2.new(0,7,0,50)
sB.BackgroundColor3=CD; sB.BackgroundTransparency=0.35; sB.BorderSizePixel=0; sB.ZIndex=15; sB.Parent=M
Instance.new("UICorner",sB).CornerRadius=UDim.new(0,7)
local sBS=Instance.new("UIStroke"); sBS.Color=Color3.fromRGB(40,28,80); sBS.Thickness=1; sBS.Transparency=0.55; sBS.Parent=sB

carDot=Instance.new("Frame"); carDot.Size=UDim2.new(0,7,0,7); carDot.Position=UDim2.new(0,8,0.5,-3)
carDot.BackgroundColor3=RD; carDot.BorderSizePixel=0; carDot.ZIndex=16; carDot.Parent=sB
Instance.new("UICorner",carDot).CornerRadius=UDim.new(1,0)

carSt=Instance.new("TextLabel"); carSt.Size=UDim2.new(0.5,0,1,0); carSt.Position=UDim2.new(0,20,0,0)
carSt.BackgroundTransparency=1; carSt.Text="No car"; carSt.TextColor3=RD; carSt.TextSize=9
carSt.Font=Enum.Font.GothamBold; carSt.TextXAlignment=Enum.TextXAlignment.Left; carSt.ZIndex=16; carSt.Parent=sB

local fB=Instance.new("TextButton"); fB.Size=UDim2.new(0,68,0,20); fB.Position=UDim2.new(1,-74,0.5,-10)
fB.BackgroundColor3=A; fB.BackgroundTransparency=0.3; fB.Text="🚗 Connect"; fB.TextColor3=Color3.new(1,1,1)
fB.TextSize=8; fB.Font=Enum.Font.GothamBold; fB.ZIndex=16; fB.BorderSizePixel=0; fB.Parent=sB
Instance.new("UICorner",fB).CornerRadius=UDim.new(0,5)
fB.MouseButton1Click:Connect(function()
    local seat,car,root,meth=findCar()
    if seat and car then C.Seat=seat;C.Car=car;C.Root=root
        carSt.Text=car.Name; carSt.TextColor3=GR; carDot.BackgroundColor3=GR
        lg("✅ "..car.Name,GR); nf("🚗 "..car.Name,GR); setup()
    else carSt.Text="Not found"; carSt.TextColor3=RD; carDot.BackgroundColor3=RD; nf("⚠️ Sit in car!",OR) end
end)

-- Content
local Co=Instance.new("ScrollingFrame"); Co.Size=UDim2.new(1,-14,1,-86); Co.Position=UDim2.new(0,7,0,84)
Co.BackgroundTransparency=1; Co.BorderSizePixel=0; Co.ScrollBarThickness=2
Co.ScrollBarImageColor3=A; Co.AutomaticCanvasSize=Enum.AutomaticSize.Y; Co.ZIndex=10; Co.Parent=M
local cL=Instance.new("UIListLayout"); cL.Padding=UDim.new(0,3); cL.SortOrder=Enum.SortOrder.LayoutOrder; cL.Parent=Co
Instance.new("UIPadding",Co).PaddingBottom=UDim.new(0,8)

-- =============================================
-- BUILDERS (minimal, clean)
-- =============================================
local function Sec(t,o)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1
    f.LayoutOrder=o; f.ZIndex=10; f.Parent=Co
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,1,0); l.Position=UDim2.new(0,2,0,0)
    l.BackgroundTransparency=1; l.Text=t; l.TextColor3=A; l.TextSize=8
    l.Font=Enum.Font.GothamBlack; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=11; l.Parent=f
end

local function Sl(t,ic,mn,mx,df,o,cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,36); f.BackgroundColor3=CD
    f.BackgroundTransparency=0.4; f.BorderSizePixel=0; f.LayoutOrder=o; f.ZIndex=10; f.Parent=Co
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,7)

    local i=Instance.new("TextLabel"); i.Size=UDim2.new(0,13,0,13); i.Position=UDim2.new(0,6,0,3)
    i.BackgroundTransparency=1; i.Text=ic; i.TextSize=10; i.ZIndex=11; i.Parent=f

    local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(0.38,0,0,10); lb.Position=UDim2.new(0,22,0,4)
    lb.BackgroundTransparency=1; lb.Text=t; lb.TextColor3=TX; lb.TextSize=8
    lb.Font=Enum.Font.GothamMedium; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.ZIndex=11; lb.Parent=f

    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(0,26,0,10); vl.Position=UDim2.new(1,-30,0,4)
    vl.BackgroundTransparency=1; vl.Text=tostring(df); vl.TextColor3=A; vl.TextSize=9
    vl.Font=Enum.Font.GothamBlack; vl.ZIndex=11; vl.Parent=f

    local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,-14,0,4); bar.Position=UDim2.new(0,7,0,22)
    bar.BackgroundColor3=Color3.fromRGB(22,20,32); bar.BorderSizePixel=0; bar.ZIndex=11; bar.Parent=f
    Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

    local fr=(df-mn)/(mx-mn)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new(fr,0,1,0); fill.BorderSizePixel=0; fill.ZIndex=12; fill.Parent=bar
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local fG=Instance.new("UIGradient"); fG.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(75,35,195)),
        ColorSequenceKeypoint.new(1,A2)
    }); fG.Parent=fill

    local kn=Instance.new("Frame"); kn.Size=UDim2.new(0,8,0,8); kn.Position=UDim2.new(fr,-4,0.5,-4)
    kn.BackgroundColor3=Color3.new(1,1,1); kn.BorderSizePixel=0; kn.ZIndex=13; kn.Parent=bar
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local kS=Instance.new("UIStroke"); kS.Color=A; kS.Thickness=1.5; kS.Parent=kn

    local sd=false
    local sb=Instance.new("TextButton"); sb.Size=UDim2.new(1,0,0,14); sb.Position=UDim2.new(0,0,0,-5)
    sb.BackgroundTransparency=1; sb.Text=""; sb.ZIndex=14; sb.Parent=bar
    sb.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then sd=true end end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then sd=false end end)
    UIS.InputChanged:Connect(function(inp) if sd and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local r=math.clamp((inp.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local v=math.floor(mn+r*(mx-mn)); vl.Text=tostring(v)
        fill.Size=UDim2.new(r,0,1,0); kn.Position=UDim2.new(r,-4,0.5,-4); cb(v)
    end end)
end

local function Btn(t,c,o,cb)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,26); b.BackgroundColor3=c
    b.BackgroundTransparency=0.3; b.BorderSizePixel=0; b.Text=t; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=9; b.Font=Enum.Font.GothamBold; b.LayoutOrder=o; b.ZIndex=10; b.Parent=Co
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0.15}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0.3}):Play() end)
end

local function Tog(t,ic,df,o,cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,24); f.BackgroundColor3=CD
    f.BackgroundTransparency=0.4; f.BorderSizePixel=0; f.LayoutOrder=o; f.ZIndex=10; f.Parent=Co
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)

    local icL=Instance.new("TextLabel"); icL.Size=UDim2.new(0,12,1,0); icL.Position=UDim2.new(0,5,0,0)
    icL.BackgroundTransparency=1; icL.Text=ic; icL.TextSize=9; icL.ZIndex=11; icL.Parent=f

    local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(0.6,0,1,0); lb.Position=UDim2.new(0,20,0,0)
    lb.BackgroundTransparency=1; lb.Text=t; lb.TextColor3=TX; lb.TextSize=8
    lb.Font=Enum.Font.GothamMedium; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.ZIndex=11; lb.Parent=f

    local bg=Instance.new("Frame"); bg.Size=UDim2.new(0,28,0,12); bg.Position=UDim2.new(1,-34,0.5,-6)
    bg.BackgroundColor3=df and A or Color3.fromRGB(25,24,35); bg.BorderSizePixel=0; bg.ZIndex=11; bg.Parent=f
    Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)

    local dt=Instance.new("Frame"); dt.Size=UDim2.new(0,8,0,8)
    dt.Position=df and UDim2.new(1,-10,0.5,-4) or UDim2.new(0,2,0.5,-4)
    dt.BackgroundColor3=Color3.new(1,1,1); dt.BorderSizePixel=0; dt.ZIndex=12; dt.Parent=bg
    Instance.new("UICorner",dt).CornerRadius=UDim.new(1,0)

    local en=df
    local bn=Instance.new("TextButton"); bn.Size=UDim2.new(1,0,1,0); bn.BackgroundTransparency=1
    bn.Text=""; bn.ZIndex=13; bn.Parent=f
    bn.MouseButton1Click:Connect(function() en=not en; cb(en)
        TweenService:Create(bg,TweenInfo.new(0.1),{BackgroundColor3=en and A or Color3.fromRGB(25,24,35)}):Play()
        TweenService:Create(dt,TweenInfo.new(0.1,Enum.EasingStyle.Quint),{Position=en and UDim2.new(1,-10,0.5,-4) or UDim2.new(0,2,0.5,-4)}):Play()
    end)
end

-- =============================================
-- CONTENT
-- =============================================
Sec("⚡ SPEED",0)
Sl("Speed Boost","🏁",0,400,0,1,function(v) C.Spd=v; if v>0 and C.Root and(not spdBV or not spdBV.Parent) then spdBV=inj("BodyVelocity","Spd",C.Root,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=10000}) end; if spdBV and spdBV.Parent then spdBV.MaxForce=v>0 and Vector3.new(v*200,0,v*200) or Vector3.zero end end)
Sl("Speed Limit","🚫",0,500,0,2,function(v) C.Lim=v end)
Tog("Nitro (N)","🔥",false,3,function(v) C.Nitro=v; if v and C.Root then if not nitroBV or not nitroBV.Parent then nitroBV=inj("BodyVelocity","Nit",C.Root,{MaxForce=Vector3.zero,Velocity=Vector3.zero,P=15000}) end else if nitroBV then pcall(function() nitroBV:Destroy() end);nitroBV=nil end end end)
Sl("Nitro Power","💥",50,600,150,4,function(v) C.NitroF=v end)

Sec("🔄 DRIFT",5)
Tog("Enable Drift","🔄",false,6,function(v) C.Drft=v;applyW() end)
Sl("Drift Amount","💫",0,100,95,7,function(v) C.DrftAmt=v;if C.Drft then applyW() end end)
Sl("Rear Looseness","🔙",0,100,70,8,function(v) C.RearL=v;if C.Drft then applyW() end end)
Sl("Front Grip","🔜",0,100,80,9,function(v) C.FrontG=v;if C.Drft then applyW() end end)
Tog("Handbrake (H)","🅿️",false,10,function(v) C.HBrk=v end)
Sl("Brake Power","🛑",0,100,50,11,function(v) C.BrkPow=v end)
Tog("Low-G Drift","🌙",false,12,function(v) C.Grav=v and 35 or 100 end)
Tog("Spin (J)","🌀",false,13,function(v) C.Spin=v; if v and C.Root then if not spinBG or not spinBG.Parent then spinBG=inj("BodyAngularVelocity","Spin",C.Root,{MaxTorque=Vector3.new(0,math.huge,0),AngularVelocity=Vector3.zero}) end else if spinBG then pcall(function() spinBG:Destroy() end);spinBG=nil end end end)
Sl("Spin Speed","🌀",5,100,30,14,function(v) C.SpinSpd=v end)

Sec("🌍 PHYSICS",15)
Sl("Gravity %","🪨",2,300,100,16,function(v) C.Grav=v end)
Tog("Moon (10%)","🌙",false,17,function(v) C.Grav=v and 10 or 100 end)
Tog("Bounce","🏀",false,18,function(v) C.Bounce=v end)
Tog("Anti-Flip","🛡️",true,19,function(v) C.AFlip=v; if C.Root then if v then if not gyroBG or not gyroBG.Parent then gyroBG=inj("BodyGyro","Gyro",C.Root,{MaxTorque=Vector3.new(C.FlipStr*700,0,C.FlipStr*700),P=2500,D=400}) end else if gyroBG then pcall(function() gyroBG:Destroy() end);gyroBG=nil end end end end)
Sl("Flip Strength","💪",10,100,60,20,function(v) C.FlipStr=v; if gyroBG and gyroBG.Parent then gyroBG.MaxTorque=Vector3.new(v*700,0,v*700) end end)

Sec("🦘 JUMP & FLY",21)
Tog("Car Jump (Space)","🦘",false,22,function(v) C.Jump=v end)
Sl("Jump Power","⬆️",20,250,75,23,function(v) C.JumpPow=v end)
Tog("Fly Mode","✈️",false,24,function(v) C.Fly=v; if C.Root then if v then if not flyBV or not flyBV.Parent then flyBV=inj("BodyVelocity","Fly",C.Root,{MaxForce=Vector3.new(math.huge,math.huge,math.huge),Velocity=Vector3.zero,P=10000}) end; if not flyBG or not flyBG.Parent then flyBG=inj("BodyGyro","FlyG",C.Root,{MaxTorque=Vector3.new(math.huge,math.huge,math.huge),P=5000,D=500}) end else if flyBV then pcall(function() flyBV:Destroy() end);flyBV=nil end; if flyBG then pcall(function() flyBG:Destroy() end);flyBG=nil end end end end)
Sl("Fly Speed","💨",10,500,80,25,function(v) C.FlySpd=v end)

Sec("🎮 FUN & VISUAL",26)
Tog("Invisible Car","👻",false,27,function(v) C.Invis=v; if C.Car then for _,d in pairs(C.Car:GetDescendants()) do pcall(function() if d:IsA("BasePart") then d.Transparency=v and 0.8 or 0 end end) end end end)
Tog("Neon Trail","✨",false,28,function(v) C.Trail=v; if v and C.Root then
    local a0=Instance.new("Attachment");a0.Name="D_A0";a0.Position=Vector3.new(0,0,-3);a0.Parent=C.Root
    local a1=Instance.new("Attachment");a1.Name="D_A1";a1.Position=Vector3.new(0,0,3);a1.Parent=C.Root
    local tr=Instance.new("Trail");tr.Name="D_Trail";tr.Attachment0=a0;tr.Attachment1=a1
    tr.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,A),ColorSequenceKeypoint.new(0.5,A2),ColorSequenceKeypoint.new(1,Color3.fromRGB(45,140,255))})
    tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
    tr.Lifetime=2;tr.MinLength=0.1;tr.LightEmission=0.6;tr.Parent=C.Root
    table.insert(C.Inj,a0);table.insert(C.Inj,a1);table.insert(C.Inj,tr)
else for i=#C.Inj,1,-1 do pcall(function() local o=C.Inj[i]; if o.Name=="D_Trail" or o.Name=="D_A0" or o.Name=="D_A1" then o:Destroy();table.remove(C.Inj,i) end end) end end end)

Sec("🔧 ACTIONS",29)
Btn("✅ Re-inject Forces",A,30,function() if not C.Root then nf("⚠️ Find car!",OR) return end; setup(); lg("✅ Injected",GR); nf("✅ Done!",A) end)
Btn("↩️ Reset Everything",Color3.fromRGB(38,36,48),31,function() resetAll(); lg("↩️ Reset",DM); nf("↩️ Reset!",DM) end)
Btn("🏃 Speed 50",Color3.fromRGB(40,28,75),32,function() pcall(function() char.Humanoid.WalkSpeed=50 end) end)
Btn("🏃 Speed 100",Color3.fromRGB(40,28,75),33,function() pcall(function() char.Humanoid.WalkSpeed=100 end) end)
Btn("💀 Reset Character",Color3.fromRGB(90,18,42),34,function() pcall(function() char.Humanoid.Health=0 end) end)
Btn("🔄 Rejoin",Color3.fromRGB(18,38,72),35,function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,plr) end) end)
Btn("🔍 Scan Car",Color3.fromRGB(22,20,32),36,function()
    if not C.Car then lg("⚠️ No car",OR) return end
    lg("=== "..C.Car.Name.." ===",OR)
    local t={}; for _,d in pairs(C.Car:GetDescendants()) do pcall(function() t[d.ClassName]=(t[d.ClassName] or 0)+1 end) end
    for cn,ct in pairs(t) do lg("  "..cn..": "..ct,DM) end
    for _,d in pairs(C.Car:GetDescendants()) do pcall(function()
        if d:IsA("BasePart") and(d.Name:lower():find("wheel") or d.Name:lower():find("tire")) then
            local fr="def"; pcall(function() fr=string.format("%.3f",d.CustomPhysicalProperties.Friction) end)
            lg("  🛞 "..d.Name.." F="..fr,GR)
        end
    end) end
end)

Sec("📋 LOG",37)
logP=Instance.new("ScrollingFrame"); logP.Size=UDim2.new(1,0,0,75); logP.BackgroundColor3=Color3.fromRGB(6,6,10)
logP.BackgroundTransparency=0.35; logP.BorderSizePixel=0; logP.ScrollBarThickness=2
logP.AutomaticCanvasSize=Enum.AutomaticSize.Y; logP.LayoutOrder=38; logP.ZIndex=10; logP.Parent=Co
Instance.new("UICorner",logP).CornerRadius=UDim.new(0,6)
local lLy=Instance.new("UIListLayout"); lLy.Padding=UDim.new(0,1); lLy.SortOrder=Enum.SortOrder.LayoutOrder; lLy.Parent=logP

-- =============================================
-- ★ HEARTBEAT ★
-- =============================================
local fc=0
RunService.Heartbeat:Connect(function()
    pcall(function() WS.Gravity=196.2*(C.Grav/100) end)
    local root=C.Root; if not root or not root.Parent then return end

    pcall(function()
        local spd=math.floor(root.Velocity.Magnitude)
        C.SL.Text=spd.." MPH"
        local col=spd>150 and RD or spd>80 and OR or GR
        C.SL.TextColor3=col; pcall(function() sFS.Color=col end)
    end)

    if spdBV and spdBV.Parent and C.Spd>0 then local fw=root.CFrame.LookVector; spdBV.Velocity=Vector3.new(fw.X*C.Spd,0,fw.Z*C.Spd) end
    if C.Lim>0 then local v=root.Velocity;local hs=Vector3.new(v.X,0,v.Z).Magnitude; if hs>C.Lim then local r=C.Lim/hs; root.Velocity=Vector3.new(v.X*r,v.Y,v.Z*r); pcall(function() root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X*r,root.AssemblyLinearVelocity.Y,root.AssemblyLinearVelocity.Z*r) end) end end
    if C.Nitro and nitroBV and nitroBV.Parent then if UIS:IsKeyDown(Enum.KeyCode.N) then local fw=root.CFrame.LookVector;nitroBV.Velocity=fw*C.NitroF;nitroBV.MaxForce=Vector3.new(C.NitroF*300,0,C.NitroF*300) else nitroBV.MaxForce=Vector3.zero end end
    if C.HBrk and UIS:IsKeyDown(Enum.KeyCode.H) then local v=root.Velocity;local b=1-(C.BrkPow/100*0.15);root.Velocity=Vector3.new(v.X*b,v.Y,v.Z*b);pcall(function() root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X*b,root.AssemblyLinearVelocity.Y,root.AssemblyLinearVelocity.Z*b) end) end
    if C.Spin and spinBG and spinBG.Parent then spinBG.AngularVelocity=UIS:IsKeyDown(Enum.KeyCode.J) and Vector3.new(0,C.SpinSpd,0) or Vector3.zero end
    if C.Bounce then local v=root.Velocity; if v.Y<-5 then root.Velocity=Vector3.new(v.X,math.abs(v.Y)*0.8,v.Z) end end
    if C.Fly and flyBV and flyBV.Parent then
        local cam=WS.CurrentCamera;local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.yAxis end
        flyBV.Velocity=dir.Magnitude>0 and dir.Unit*C.FlySpd or Vector3.zero
        if flyBG and flyBG.Parent then flyBG.CFrame=cam.CFrame end
    end

    fc+=1; if fc>=120 then fc=0
        local seat,car,rt,meth=findCar()
        if seat and car then if C.Car~=car then resetAll();C.Seat=seat;C.Car=car;C.Root=rt
            carSt.Text=car.Name;carSt.TextColor3=GR;carDot.BackgroundColor3=GR;lg("🚗 "..car.Name,GR);setup() end
        else if C.Car then resetAll();C.Car=nil;C.Root=nil;C.Seat=nil
            carSt.Text="No car";carSt.TextColor3=RD;carDot.BackgroundColor3=RD end end
        pcall(function() local h=(tick()*0.02)%1; mS.Color=Color3.fromHSV(h,0.55,0.75) end)
        pcall(function() lT.Rotation=math.sin(tick()*2)*8 end)
        pcall(function() tAG.Offset=Vector2.new(math.sin(tick()*0.8)*0.25,0) end)
        pcall(function() abG.Offset=Vector2.new(0,math.sin(tick()*0.5)*0.15) end)
        pcall(function() if C.Car then carDot.BackgroundTransparency=0.3+math.sin(tick()*3)*0.3 else carDot.BackgroundTransparency=0 end end)
    end
end)

UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Space and C.Jump and C.Root and C.Root.Parent then
        pcall(function() local bv=Instance.new("BodyVelocity");bv.Name="D_Jmp";bv.MaxForce=Vector3.new(0,math.huge,0);bv.Velocity=Vector3.new(0,C.JumpPow,0);bv.Parent=C.Root;task.delay(0.2,function() pcall(function() bv:Destroy() end) end) end)
    end
    if inp.KeyCode==Enum.KeyCode.RightShift then M.Visible=not M.Visible end
end)

local mini=false
minB.MouseButton1Click:Connect(function() mini=not mini
    TweenService:Create(M,TweenInfo.new(0.12,Enum.EasingStyle.Quint),{Size=mini and UDim2.new(0,380,0,46) or UDim2.new(0,380,0,500)}):Play()
    minB.Text=mini and "+" or "—"
end)
clsB.MouseButton1Click:Connect(function() resetAll()
    TweenService:Create(M,TweenInfo.new(0.12,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1}):Play()
    task.wait(0.15) SG:Destroy()
end)

M.Size=UDim2.new(0,0,0,0);M.Position=UDim2.new(0.5,0,0.5,0);M.BackgroundTransparency=1
TweenService:Create(M,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Size=UDim2.new(0,380,0,500),Position=UDim2.new(0.5,-190,0.5,-250),BackgroundTransparency=0.01
}):Play()

task.wait(0.35)
nf("🏎️ DRIH v3.0 — Premium",A)
lg("🏎️ DRIH v3.0",A)
lg("Single scrollable page — no tab overhead",Color3.fromRGB(100,180,255))
lg("120-frame auto-detect cycle",GR)
lg("N=Nitro H=Brake J=Spin Space=Jump",DM)

print("=== DRIH v3.0 ===")
print("RIGHT SHIFT = Toggle")
