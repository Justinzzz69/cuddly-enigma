local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "Big Paintball",
    SubTitle = "made by Tapetenputzer",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "target" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "sun" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

--------------------------------------------------------------------------------
-- AIMBOT
--------------------------------------------------------------------------------
local AimEnabled = false
local AimFOV = 100
local AimSmooth = 0.1
local AimTeamCheck = true
local AimParts = {
    Head = "Head",
    Torso = "UpperTorso",
    Feet = "LeftFoot"
}
local CurrentAimPart = "Head"

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Radius = AimFOV
FOVCircle.Filled = false
FOVCircle.Visible = true
FOVCircle.Color = Color3.fromRGB(255, 255, 0)
FOVCircle.Position = Vector2.new(
    Workspace.CurrentCamera.ViewportSize.X / 2,
    Workspace.CurrentCamera.ViewportSize.Y / 2
)

RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    FOVCircle.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
end)

local function IsTeammate(p)
    return p.Team == LocalPlayer.Team
end

local function WorldToScreen(pos)
    local cam = Workspace.CurrentCamera
    local sPos, onScr = cam:WorldToViewportPoint(pos)
    return Vector2.new(sPos.X, sPos.Y), onScr
end

local function DistFromCenter(pt)
    local c = Vector2.new(
        Workspace.CurrentCamera.ViewportSize.X/2,
        Workspace.CurrentCamera.ViewportSize.Y/2
    )
    return (pt - c).Magnitude
end

local function ClosestEnemy()
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(CurrentAimPart) then
            if not AimTeamCheck or (AimTeamCheck and not IsTeammate(plr)) then
                local part = plr.Character[CurrentAimPart]
                local screenPos, onScreen = WorldToScreen(part.Position)
                if onScreen then
                    local mag = DistFromCenter(screenPos)
                    if mag < AimFOV and mag < dist then
                        dist = mag
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

local AimConnection
local function EnableAimbot()
    if AimConnection then AimConnection:Disconnect() end
    AimConnection = RunService.RenderStepped:Connect(function()
        if AimEnabled then
            local target = ClosestEnemy()
            if target and target.Character and target.Character:FindFirstChild(CurrentAimPart) then
                local pos = target.Character[CurrentAimPart].Position
                local cam = Workspace.CurrentCamera
                local cf = cam.CFrame
                local newCf = CFrame.new(cf.p, pos)
                cam.CFrame = cf:Lerp(newCf, AimSmooth)
            end
        end
    end)
end

local function DisableAimbot()
    AimEnabled = false
    if AimConnection then
        AimConnection:Disconnect()
        AimConnection = nil
    end
end

--------------------------------------------------------------------------------
-- ESP: CHAMS, NAMETAGS & SKELETON ESP
--------------------------------------------------------------------------------
-- Chams & Nametags (bereits vorhanden)
local ChamsActive = false
local NametagsActive = false
local EnemyColor = Color3.fromRGB(255, 0, 0)
local TeamColor = Color3.fromRGB(0, 255, 0)

local function RemoveChams()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part:FindFirstChild("Cham") then
                    part.Cham:Destroy()
                end
            end
        end
    end
end

local function RemoveNametags()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local tag = p.Character.Head:FindFirstChild("Nametag")
            if tag then tag:Destroy() end
        end
    end
end

local function UpdateChams()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local col = (not AimTeamCheck or not IsTeammate(p)) and EnemyColor or TeamColor
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local cham = part:FindFirstChild("Cham")
                    if not cham then
                        cham = Instance.new("BoxHandleAdornment")
                        cham.Name = "Cham"
                        cham.Adornee = part
                        cham.AlwaysOnTop = true
                        cham.ZIndex = 10
                        cham.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
                        cham.Transparency = 0.5
                        cham.Color3 = col
                        cham.Parent = part
                    else
                        cham.Color3 = col
                    end
                end
            end
        end
    end
end

local function ChamsLoop()
    while ChamsActive do
        UpdateChams()
        task.wait(2)
    end
end

local function UpdateNametags()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local col = (not AimTeamCheck or not IsTeammate(p)) and EnemyColor or TeamColor
            local ex = head:FindFirstChild("Nametag")
            if not ex then
                local b = Instance.new("BillboardGui")
                b.Name = "Nametag"
                b.Size = UDim2.new(0, 150, 0, 50)
                b.StudsOffset = Vector3.new(0, 2, 0)
                b.AlwaysOnTop = true
                local f = Instance.new("Frame", b)
                f.Size = UDim2.new(1, 0, 1, 0)
                f.BackgroundTransparency = 0.5
                f.BackgroundColor3 = Color3.new(0, 0, 0)
                local corner = Instance.new("UICorner", f)
                corner.CornerRadius = UDim.new(1, 0)
                local lbl = Instance.new("TextLabel", f)
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = p.Name
                lbl.TextScaled = true
                lbl.Font = Enum.Font.GothamSemibold
                lbl.TextColor3 = col
                lbl.TextStrokeTransparency = 0.3
                b.Parent = head
            else
                local frm = ex:FindFirstChildOfClass("Frame")
                if frm then
                    local lbl = frm:FindFirstChildOfClass("TextLabel")
                    if lbl then
                        lbl.TextColor3 = col
                    end
                end
            end
        end
    end
end

local function NametagsLoop()
    while NametagsActive do
        UpdateNametags()
        task.wait(2)
    end
end

-- Neuer Abschnitt: Skeleton ESP
local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}
local skeletonESPEnabled = false
local skeletonESPColor = Color3.new(1, 0, 0) -- Standard Rot
local SkeletonESPs = {}  -- Tabelle: [player] = { drawing1, drawing2, ... }

local function CreateSkeletonForPlayer(player)
    local drawings = {}
    for i, connection in ipairs(SkeletonConnections) do
        local line = Drawing.new("Line")
        line.Visible = true
        line.Transparency = 1
        line.Color = skeletonESPColor
        line.Thickness = 2
        drawings[i] = line
    end
    SkeletonESPs[player] = drawings
end

local function UpdateSkeletonESP(player)
    if not SkeletonESPs[player] then
        CreateSkeletonForPlayer(player)
    end
    local drawings = SkeletonESPs[player]
    local character = player.Character
    if character then
        for i, connection in ipairs(SkeletonConnections) do
            local partA = character:FindFirstChild(connection[1])
            local partB = character:FindFirstChild(connection[2])
            if partA and partB then
                local vectorA, onScreenA = Workspace.CurrentCamera:WorldToViewportPoint(partA.Position)
                local vectorB, onScreenB = Workspace.CurrentCamera:WorldToViewportPoint(partB.Position)
                if onScreenA and onScreenB then
                    drawings[i].Visible = true
                    drawings[i].From = Vector2.new(vectorA.X, vectorA.Y)
                    drawings[i].To = Vector2.new(vectorB.X, vectorB.Y)
                    drawings[i].Color = skeletonESPColor
                else
                    drawings[i].Visible = false
                end
            else
                drawings[i].Visible = false
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if SkeletonESPs[player] then
        for _, line in ipairs(SkeletonESPs[player]) do
            line:Remove()
        end
        SkeletonESPs[player] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if skeletonESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                UpdateSkeletonESP(player)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- PLAYER TAB
--------------------------------------------------------------------------------
local FlySec = Tabs.Player:AddSection("Fly")
local FlyToggle = FlySec:AddToggle("FlyToggle", {
    Title = "Fly",
    Default = false
})
FlyToggle:OnChanged(function(s)
    if s then
        enableFly()
    else
        disableFly()
    end
end)

local FlySpeedInp = FlySec:AddInput("FlySpeed", {
    Title = "Fly Speed",
    Placeholder = "50",
    Numeric = true
})
FlySec:AddButton({
    Title = "Set Fly Speed",
    Callback = function()
        local v = tonumber(FlySpeedInp.Value)
        if v and v > 0 then
            flySpeed = v
        end
    end
})

local WalkSec = Tabs.Player:AddSection("Walk")
local SpeedInp = WalkSec:AddInput("SpeedInput", {
    Title = "Walk Speed",
    Placeholder = "16",
    Numeric = true
})
WalkSec:AddButton({
    Title = "Set Speed",
    Callback = function()
        local v = tonumber(SpeedInp.Value)
        if v and v > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

local AntiSec = Tabs.Player:AddSection("Anti-AFK")
local AntiAFKToggle = AntiSec:AddToggle("AntiAFK", {
    Title = "Anti-AFK",
    Default = false
})
AntiAFKToggle:OnChanged(function(s)
    if s then
        enableAntiAfk()
    else
        disableAntiAfk()
    end
end)

--------------------------------------------------------------------------------
-- VISUAL TAB
--------------------------------------------------------------------------------
local VisualSec = Tabs.Visual:AddSection("Visual")
local FB = VisualSec:AddToggle("Fullbright", {
    Title = "Fullbright",
    Default = false
})
FB:OnChanged(function(s)
    if s then
        Lighting.Brightness = 10
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000
        Lighting.GlobalShadows = true
    end
end)

local NF = VisualSec:AddToggle("NoFog", {
    Title = "No Fog",
    Default = false
})
NF:OnChanged(function(s)
    if s then
        Lighting.FogStart = 0
        Lighting.FogEnd = 1e9
    else
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000
    end
end)

local CC = VisualSec:AddToggle("ColorCorrection", {
    Title = "Color Correction",
    Default = false
})
CC:OnChanged(function(s)
    if s then
        if not Lighting:FindFirstChild("ColorCorrectionEffect") then
            local c = Instance.new("ColorCorrectionEffect")
            c.Brightness = 0
            c.Contrast = 0
            c.Saturation = 1
            c.Parent = Lighting
        end
    else
        local c = Lighting:FindFirstChild("ColorCorrectionEffect")
        if c then c:Destroy() end
    end
end)

local SR = VisualSec:AddToggle("SunRays", {
    Title = "SunRays",
    Default = false
})
SR:OnChanged(function(s)
    if s then
        if not Lighting:FindFirstChild("SunRaysEffect") then
            local sr = Instance.new("SunRaysEffect")
            sr.Intensity = 0.3
            sr.Parent = Lighting
        end
    else
        local sr = Lighting:FindFirstChild("SunRaysEffect")
        if sr then sr:Destroy() end
    end
end)

--------------------------------------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title = "Big Paintball",
    Content = "Loaded!",
    Duration = 5
})

Window:SelectTab(1)
