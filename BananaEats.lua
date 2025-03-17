-- Load Fluent Library & Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Main Window
local Window = Fluent:CreateWindow({
    Title = "Banana Eats Script",
    SubTitle = "by Tapetenputzer",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Define Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "gamepad" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local chamsActive = false
local nametagActive = false
local chamsLoop = nil
local nametagLoop = nil
local speedLoop = nil
local fullbrightActive = false
local currentSpeed = 16 -- Default Speed
local enemyChamColor = Color3.fromRGB(255, 0, 0) -- Default Enemy Chams Color
local teamChamColor = Color3.fromRGB(0, 255, 0) -- Default Team Chams Color

-- Function to Add Chams
local function addChams(player)
    if chamsActive and player.Character then
        local isSameTeam = player.TeamColor == game.Players.LocalPlayer.TeamColor
        local color = isSameTeam and teamChamColor or enemyChamColor
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                local cham = part:FindFirstChild("Cham")
                if not cham then
                    cham = Instance.new("BoxHandleAdornment")
                    cham.Name = "Cham"
                    cham.Adornee = part
                    cham.AlwaysOnTop = true
                    cham.ZIndex = 10
                    cham.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
                    cham.Transparency = 0.5
                    cham.Color3 = color
                    cham.Parent = part
                else
                    cham.Color3 = color
                end
            end
        end
    end
end

-- Chams Toggle
Tabs.Main:AddToggle("ChamsToggle", {
    Title = "Enable Chams",
    Default = false,
    Callback = function(state)
        chamsActive = state
        if state then
            if chamsLoop then task.cancel(chamsLoop) end
            chamsLoop = task.spawn(function()
                while chamsActive do
                    for _, player in pairs(game.Players:GetPlayers()) do
                        if player ~= game.Players.LocalPlayer then
                            addChams(player)
                        end
                    end
                    wait(1)
                end
            end)
        else
            if chamsLoop then
                task.cancel(chamsLoop)
                chamsLoop = nil
            end
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Character then
                    for _, part in pairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part:FindFirstChild("Cham") then
                            part.Cham:Destroy()
                        end
                    end
                end
            end
        end
    end
})

-- Color Pickers
Tabs.Main:AddColorpicker("EnemyChamsColor", {
    Title = "Enemy Chams Color",
    Default = enemyChamColor,
    Callback = function(color)
        enemyChamColor = color
    end
})

Tabs.Main:AddColorpicker("TeamChamsColor", {
    Title = "Team Chams Color",
    Default = teamChamColor,
    Callback = function(color)
        teamChamColor = color
    end
})

-- Function to Add Nametags
local function addNametag(player)
    if nametagActive and player.Character and player.Character:FindFirstChild("Head") then
        local existingTag = player.Character.Head:FindFirstChild("Nametag")
        if not existingTag then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "Nametag"
            billboard.Adornee = player.Character.Head
            billboard.Size = UDim2.new(0, 100, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.AlwaysOnTop = true

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = player.Name
            textLabel.TextColor3 = (player.TeamColor == game.Players.LocalPlayer.TeamColor) and teamChamColor or enemyChamColor
            textLabel.TextStrokeTransparency = 0.5
            textLabel.TextScaled = true
            textLabel.Parent = billboard

            billboard.Parent = player.Character.Head
        else
            existingTag.TextLabel.TextColor3 = (player.TeamColor == game.Players.LocalPlayer.TeamColor) and teamChamColor or enemyChamColor
        end
    end
end

-- Nametag Toggle
Tabs.Main:AddToggle("NametagToggle", {
    Title = "Enable Nametags",
    Default = false,
    Callback = function(state)
        nametagActive = state
        if state then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    addNametag(player)
                end
            end
        else
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("Head") then
                    local tag = player.Character.Head:FindFirstChild("Nametag")
                    if tag then
                        tag:Destroy()
                    end
                end
            end
        end
    end
})

-- Fullbright Toggle
Tabs.Main:AddToggle("FullbrightToggle", {
    Title = "Enable Fullbright",
    Default = false,
    Callback = function(state)
        fullbrightActive = state
        if state then
            game.Lighting.Brightness = 10
            game.Lighting.ClockTime = 12
            game.Lighting.FogEnd = 100000
            game.Lighting.GlobalShadows = false
        else
            game.Lighting.Brightness = 1
            game.Lighting.ClockTime = 14
            game.Lighting.FogEnd = 1000
            game.Lighting.GlobalShadows = true
        end
    end
})

-- Speed Input and Button
local SpeedInput = Tabs.Main:AddInput("SpeedInput", {
    Title = "Set Speed",
    Placeholder = "Default = 16",
    Numeric = true
})

Tabs.Main:AddButton({
    Title = "Set Player Speed",
    Description = "Set the Speed of Player",
    Callback = function()
        local speed = tonumber(SpeedInput.Value)
        if speed and speed > 0 then
            currentSpeed = speed
            if game.Players.LocalPlayer.Character then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
            end
            if speedLoop then
                task.cancel(speedLoop)
            end
            speedLoop = task.spawn(function()
                while true do
                    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
                    end
                    wait(1)
                end
            end)
        end
    end
})

Tabs.Main:AddButton({
    Title = "Reset Speed",
    Description = "Resets the Speed to Default (16)",
    Callback = function()
        currentSpeed = 16
        if game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
        end
        if speedLoop then
            task.cancel(speedLoop)
            speedLoop = nil
        end
    end
})

-- Configure SaveManager & InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- Notification on Script Start
Fluent:Notify({
    Title = "Tapetenputzer",
    Content = "Script loaded!",
    Duration = 5
})

Window:SelectTab(1)
