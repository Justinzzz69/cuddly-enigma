local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "Hello kitty",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map" }),
    Info = Window:AddTab({ Title = "Info", Icon = "heart" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

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

local yOffset = 3
local scanInterval = 1

local function getHRP(character)
    return character:WaitForChild("HumanoidRootPart")
end

local function collectMoney()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = getHRP(character)
    local nearestMoney
    local nearestDist = math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("money") then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestMoney = obj
            end
        end
    end
    if nearestMoney then
        hrp.CFrame = nearestMoney.CFrame + Vector3.new(0, yOffset, 0)
        print("Teleporting to money, Dist: " .. nearestDist)
        task.wait(0.2)
        local footPos = hrp.Position - Vector3.new(0, 3, 0)
        local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(footPos)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 0)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 0)
            print("Simulated left click at (" .. screenPos.X .. ", " .. screenPos.Y .. ")")
        else
            print("Position under player not on screen.")
        end
    else
        print("No money object found.")
    end
end

local autoCollectActive = false
local autoCollectTask
local function autoCollectLoop()
    while autoCollectActive do
        collectMoney()
        task.wait(scanInterval)
    end
end

local TeleportSection = Tabs.Teleport:AddSection("Auto Collect Money")
TeleportSection:AddToggle("AutoCollectMoneyToggle", {
    Title = "Auto Collect Money",
    Default = false,
    Callback = function(state)
        autoCollectActive = state
        if state then
            autoCollectTask = task.spawn(autoCollectLoop)
        else
            if autoCollectTask then
                task.cancel(autoCollectTask)
                autoCollectTask = nil
            end
        end
    end
})

local function dashToCoordinate(coord)
    for i = 47, 1, -1 do
        print("Teleport in " .. i .. " seconds...")
        task.wait(1)
    end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(coord)
    print("Teleported to coordinate: " .. tostring(coord))
end

local KeroPPIDashSection = Tabs.Teleport:AddSection("keroppi Dash")
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

local InfoSection = Tabs.Info:AddSection("Info")
InfoSection:AddParagraph({
    Title = "Info",
    Content = "Created by Tapetenputzer\nDiscord: tapetenputzer"
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub_MicUp")
SaveManager:SetFolder("FluentScriptHub_MicUp/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title = "Hello kitty",
    Content = "Script Loaded!",
    Duration = 5
})

Window:SelectTab(1)
