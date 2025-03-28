---------------------------------------------------------------------
-- Libraries laden
---------------------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------
-- Haupt-GUI erstellen (Hello kitty)
---------------------------------------------------------------------
local Window = Fluent:CreateWindow({
    Title = "Hello kitty",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,  -- Blur-Effekt, falls gewünscht
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Player   = Window:AddTab({ Title = "Player",   Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map" }),
    Info     = Window:AddTab({ Title = "Info",     Icon = "heart" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

---------------------------------------------------------------------
-- PLAYER-FUNKTIONEN
---------------------------------------------------------------------
local currentSpeed = 16
local flySpeed = 50
local flyConnection, flyBodyVelocity, flyBodyGyro

local function setWalkSpeed(speed)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = speed
    end
end

local function enableFly()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        flyBodyVelocity = Instance.new("BodyVelocity", root)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBodyGyro = Instance.new("BodyGyro", root)
        flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBodyGyro.CFrame = root.CFrame
        flyConnection = RunService.RenderStepped:Connect(function()
            local dir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                dir = dir + Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                dir = dir - Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                dir = dir - Workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                dir = dir + Workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                dir = dir + Vector3.new(0,1,0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                dir = dir - Vector3.new(0,1,0)
            end
            if dir.Magnitude > 0 then
                flyBodyVelocity.Velocity = dir.Unit * flySpeed
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            flyBodyGyro.CFrame = Workspace.CurrentCamera.CFrame
        end)
    end
end

local function disableFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
end

local AFKConnection
local function EnableAntiAFK()
    if AFKConnection then
        AFKConnection:Disconnect()
        AFKConnection = nil
    end
    AFKConnection = LocalPlayer.Idled:Connect(function()
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):ClickButton2(Vector2.new())
    end)
end

local function DisableAntiAFK()
    if AFKConnection then
        AFKConnection:Disconnect()
        AFKConnection = nil
    end
end

---------------------------------------------------------------------
-- PLAYER-TAB: Movement
---------------------------------------------------------------------
local PlayerSection = Tabs.Player:AddSection("Movement")
PlayerSection:AddSlider("SpeedSlider", {
    Title = "Walk Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        currentSpeed = value
        setWalkSpeed(currentSpeed)
    end
})
PlayerSection:AddToggle("FlyToggle", {
    Title = "Fly",
    Default = false,
    Callback = function(state)
        if state then
            enableFly()
        else
            disableFly()
        end
    end
})
PlayerSection:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed",
    Default = 50,
    Min = 0,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        flySpeed = value
    end
})
local AntiAFKSection = Tabs.Player:AddSection("Anti AFK")
AntiAFKSection:AddToggle("AntiAFKToggle", {
    Title = "Anti AFK",
    Default = false,
    Callback = function(state)
        if state then
            EnableAntiAFK()
        else
            DisableAntiAFK()
        end
    end
})

---------------------------------------------------------------------
-- TELEPORT-TAB: Bestehende Funktionen (UGC, Auto Farm Entities)
---------------------------------------------------------------------
local UGCSection = Tabs.Teleport:AddSection("Get UGC Items")
UGCSection:AddButton({
    Title = "Get UGC Items",
    Callback = function()
        ReplicatedStorage.GameCommon.Messages.BuyUGCItem:FireServer(14526608964)
        ReplicatedStorage.GameCommon.Messages.BuyUGCItem:FireServer(15290834415)
        ReplicatedStorage.GameCommon.Messages.BuyUGCItem:FireServer(15014829602)
    end
})

local AutoSection = Tabs.Teleport:AddSection("Auto Farm Entities")
AutoSection:AddToggle("ServeToggle", {
    Title = "Auto Serve",
    Default = false,
    Callback = function(state)
        autoServeActive = state
        if state then
            processedInteractions = {}
            autoServeTask = task.spawn(AutoServeLoop)
            autoServeResetTask = task.spawn(autoServeResetLoop)
        else
            if autoServeTask then
                task.cancel(autoServeTask)
                autoServeTask = nil
            end
            if autoServeResetTask then
                task.cancel(autoServeResetTask)
                autoServeResetTask = nil
            end
        end
    end
})
AutoSection:AddToggle("TreasureToggle", {
    Title = "Auto Treasure Cheast",
    Default = false,
    Callback = function(state)
        treasureLoopActive = state
        if state then
            treasureLoopTask = task.spawn(TreasureCheastLoop)
        else
            if treasureLoopTask then
                task.cancel(treasureLoopTask)
                treasureLoopTask = nil
            end
        end
    end
})
AutoSection:AddToggle("UpgradeToggle", {
    Title = "Auto Upgrade",
    Default = false,
    Callback = function(state)
        upgradeLoopActive = state
        if state then
            upgradeLoopTask = task.spawn(AutoUpgradeLoop)
        else
            if upgradeLoopTask then
                task.cancel(upgradeLoopTask)
                upgradeLoopTask = nil
            end
        end
    end
})

---------------------------------------------------------------------
-- TELEPORT-TAB: Neue Rubrik "KeroPPI Dash"
---------------------------------------------------------------------
-- Hier fügen wir drei Buttons hinzu, die dich zu festen Koordinaten teleportieren.
-- Jeder Button startet einen Countdown von 47 Sekunden, der in der Konsole ausgegeben wird,
-- und teleportiert dich dann zur vorgegebenen Koordinate.
local function dashToCoordinate(coord)
    for i = 47, 1, -1 do
        print("Teleport in " .. i .. " Sekunden...")
        task.wait(1)
    end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(coord)
    print("Teleported to coordinate: " .. tostring(coord))
end

local KeroPPIDashSection = Tabs.Teleport:AddSection("KeroPPI Dash")
KeroPPIDashSection:AddButton({
    Title = "Dizzy Frenzy",
    Callback = function()
        dashToCoordinate(Vector3.new(1965.16, 219.93, 197.30))
    end
})
KeroPPIDashSection:AddButton({
    Title = "Rumble Stumble",
    Callback = function()
        dashToCoordinate(Vector3.new(-409.05, 231.95, 1758.00))
    end
})
KeroPPIDashSection:AddButton({
    Title = "Jungle Dash",
    Callback = function()
        dashToCoordinate(Vector3.new(-2145.95, 173.22, 120.95))
    end
})

---------------------------------------------------------------------
-- INFO-TAB
---------------------------------------------------------------------
local InfoSection = Tabs.Info:AddSection("Info")
InfoSection:AddParagraph({
    Title = "Info",
    Content = "Erstellt von Tapetenputzer\nDiscord: tapetenputzer"
})

---------------------------------------------------------------------
-- SETTINGS-TAB (wie im ursprünglichen Script)
---------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub_MicUp")
SaveManager:SetFolder("FluentScriptHub_MicUp/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

---------------------------------------------------------------------
-- FINALE NOTIFICATION
---------------------------------------------------------------------
Fluent:Notify({
    Title = "Hello kitty",
    Content = "Script Loaded!",
    Duration = 5
})

Window:SelectTab(1)
