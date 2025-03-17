-----------------------------
-- Bibliotheken laden
-----------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-----------------------------
-- Fenster und Tabs erstellen
-----------------------------
local Window = Fluent:CreateWindow({
    Title = "Banana Eats Script",
    SubTitle = "by Tapetenputzer",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Vier Haupt-Tabs
local Tabs = {
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "sun" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Im ESP-Tab zwei Sektionen: Toggles & Colors
local ESPTogglesSection = Tabs.ESP:AddSection("ESP Toggles")
local ESPColorsSection = Tabs.ESP:AddSection("ESP Colors")

-----------------------------
-- Variablen / Status Flags
-----------------------------
local cakeEspActive = false
local cakeEspLoop = nil
local cakeEspColor = Color3.fromRGB(255, 255, 0)

local coinEspActive = false
local coinEspLoop = nil
local coinEspColor = Color3.fromRGB(0, 255, 0)

local chamsActive = false
local chamsLoop = nil
local enemyChamColor = Color3.fromRGB(255, 0, 0)
local teamChamColor = Color3.fromRGB(0, 255, 0)

local nametagActive = false
local nametagLoop = nil

local fullbrightActive = false

local speedLoop = nil
local currentSpeed = 16

local valveEspActive = false
local valveEspLoop = nil
local valveEspColor = Color3.fromRGB(0, 255, 255)
local labeledValves = {}

local puzzleNumberEspActive = false
local puzzleNumberEspLoop = nil
local puzzleNumberEspColor = Color3.fromRGB(255, 255, 255) -- Anpassbar
local puzzleNumbers = {["23"] = true, ["34"] = true, ["31"] = true}

local noFogActive = false
local noFogLoop = nil

-- NEU: Fly-Funktion
local flyActive = false
local flySpeed = 50  -- Standardwert
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnection = nil

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-----------------------------
-- Hilfsfunktion: BillboardGui
-----------------------------
local function createBillboard(text)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Parent = billboard

    return billboard
end

-----------------------------
-- Entferner-Funktionen
-----------------------------
local function removeCakeEsp()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj:FindFirstChild("CakeESP") then
                obj.CakeESP:Destroy()
            end
            if obj:FindFirstChild("CakeLabel") then
                obj.CakeLabel:Destroy()
            end
        end
    end
end

local function removeCoinEsp()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj:FindFirstChild("CoinESP") then
                obj.CoinESP:Destroy()
            end
            if obj:FindFirstChild("CoinLabel") then
                obj.CoinLabel:Destroy()
            end
        end
    end
end

local function removeChams()
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

local function removeNametags()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local tag = player.Character.Head:FindFirstChild("Nametag")
            if tag then
                tag:Destroy()
            end
        end
    end
end

local function removeValveEsp()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj:FindFirstChild("ValveESP") then
                obj.ValveESP:Destroy()
            end
            if obj:FindFirstChild("ValveLabel") then
                obj.ValveLabel:Destroy()
            end
        end
    end
    labeledValves = {}
end

local function removePuzzleNumberEsp()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent and obj.Parent.Name == "Buttons" and puzzleNumbers[obj.Name] then
            if obj:FindFirstChild("PuzzleNumberESP") then
                obj.PuzzleNumberESP:Destroy()
            end
            if obj:FindFirstChild("PuzzleNumberLabel") then
                obj.PuzzleNumberLabel:Destroy()
            end
        end
    end
end

-----------------------------
-- Check-/Loop-Funktionen
-----------------------------
local function checkCakeEsp(obj)
    if not obj:IsA("BasePart") then return end
    if (obj.Parent and obj.Parent.Name == "Cake" and tonumber(obj.Name))
       or (obj.Parent and obj.Parent.Name == "CakePlate" and obj.Name == "Plate") then

        if not obj:FindFirstChild("CakeESP") then
            local esp = Instance.new("BoxHandleAdornment")
            esp.Name = "CakeESP"
            esp.Adornee = obj
            esp.AlwaysOnTop = true
            esp.ZIndex = 10
            esp.Size = obj.Size + Vector3.new(0.2, 0.2, 0.2)
            esp.Transparency = 0.5
            esp.Color3 = cakeEspColor
            esp.Parent = obj
        end

        if not obj:FindFirstChild("CakeLabel") then
            local labelText = "Cake Plate"
            if obj.Parent and obj.Parent.Name == "Cake" then
                local num = tonumber(obj.Name)
                if num and num >= 1 and num <= 6 then
                    labelText = "Main Plate"
                end
            end
            local billboard = createBillboard(labelText)
            billboard.Name = "CakeLabel"
            billboard.Parent = obj
        end
    end
end

local function cakeEspLoopFunction()
    while cakeEspActive do
        for _, obj in pairs(workspace:GetDescendants()) do
            checkCakeEsp(obj)
        end
        wait(1)
    end
end

local function checkCoinEsp(obj)
    if not obj:IsA("BasePart") then return end
    if obj.Parent and obj.Parent.Name == "Tokens" and obj.Name == "Token" then

        if not obj:FindFirstChild("CoinESP") then
            local esp = Instance.new("BoxHandleAdornment")
            esp.Name = "CoinESP"
            esp.Adornee = obj
            esp.AlwaysOnTop = true
            esp.ZIndex = 10
            esp.Size = obj.Size + Vector3.new(0.2, 0.2, 0.2)
            esp.Transparency = 0.5
            esp.Color3 = coinEspColor
            esp.Parent = obj
        end

        if not obj:FindFirstChild("CoinLabel") then
            local billboard = createBillboard("Coin")
            billboard.Name = "CoinLabel"
            billboard.Parent = obj
        end
    end
end

local function coinEspLoopFunction()
    while coinEspActive do
        for _, obj in pairs(workspace:GetDescendants()) do
            checkCoinEsp(obj)
        end
        wait(1)
    end
end

local function checkChams()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local isSameTeam = (player.TeamColor == game.Players.LocalPlayer.TeamColor)
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
end

local function chamsLoopFunction()
    while chamsActive do
        checkChams()
        wait(1)
    end
end

local function checkNametags()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local isSameTeam = (player.TeamColor == game.Players.LocalPlayer.TeamColor)
            local color = isSameTeam and teamChamColor or enemyChamColor
            local head = player.Character.Head
            local existingTag = head:FindFirstChild("Nametag")
            if not existingTag then
                local billboard = createBillboard(player.Name)
                billboard.Name = "Nametag"
                billboard.Parent = head
            else
                existingTag.TextLabel.TextColor3 = color
            end
        end
    end
end

local function nametagLoopFunction()
    while nametagActive do
        checkNametags()
        wait(1)
    end
end

local function checkValveEsp(obj)
    if not obj:IsA("BasePart") then return end
    local parent = obj.Parent
    if not parent then return end

    local isValve = false
    if parent.Name == "Valve" or parent.Name == "ValvePuzzle" then
        isValve = true
    elseif parent.Name == "Buttons" and obj.Name == "ValveButton" then
        isValve = true
    end
    if not isValve then return end

    if labeledValves[parent] then
        return
    end
    labeledValves[parent] = true

    local basePart = obj
    if parent:IsA("Model") then
        if parent.PrimaryPart then
            basePart = parent.PrimaryPart
        else
            for _, child in ipairs(parent:GetDescendants()) do
                if child:IsA("BasePart") then
                    basePart = child
                    break
                end
            end
        end
    end

    if not basePart:FindFirstChild("ValveESP") then
        local esp = Instance.new("BoxHandleAdornment")
        esp.Name = "ValveESP"
        esp.Adornee = basePart
        esp.AlwaysOnTop = true
        esp.ZIndex = 10
        esp.Size = basePart.Size + Vector3.new(0.2, 0.2, 0.2)
        esp.Transparency = 0.5
        esp.Color3 = valveEspColor
        esp.Parent = basePart
    end

    if not basePart:FindFirstChild("ValveLabel") then
        local billboard = createBillboard("Valve")
        billboard.Name = "ValveLabel"
        billboard.Parent = basePart
    end
end

local function valveEspLoopFunction()
    while valveEspActive do
        labeledValves = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            checkValveEsp(obj)
        end
        wait(1)
    end
end

-- Puzzle Number ESP: JEDER Puzzle-Teil (Name "23","34","31") bekommt ein eigenes Label
local function checkPuzzleNumberEsp(obj)
    if not obj:IsA("BasePart") then return end
    if obj.Parent and obj.Parent.Name == "Buttons" and puzzleNumbers[obj.Name] then
        if not obj:FindFirstChild("PuzzleNumberESP") then
            local esp = Instance.new("BoxHandleAdornment")
            esp.Name = "PuzzleNumberESP"
            esp.Adornee = obj
            esp.AlwaysOnTop = true
            esp.ZIndex = 10
            esp.Size = obj.Size + Vector3.new(0.2, 0.2, 0.2)
            esp.Transparency = 0.5
            esp.Color3 = puzzleNumberEspColor
            esp.Parent = obj
        end
        if not obj:FindFirstChild("PuzzleNumberLabel") then
            local billboard = createBillboard("Cube Puzzle")
            billboard.Name = "PuzzleNumberLabel"
            billboard.Parent = obj
        end
    end
end

local function puzzleNumberEspLoopFunction()
    while puzzleNumberEspActive do
        for _, obj in pairs(workspace:GetDescendants()) do
            checkPuzzleNumberEsp(obj)
        end
        wait(1)
    end
end

local function noFogLoopFunction()
    while noFogActive do
        game.Lighting.FogStart = 0
        game.Lighting.FogEnd = 1e9
        wait(0.5)
    end
end

-- NEU: Fly-Funktion
local function enableFly()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        flyBodyVelocity = Instance.new("BodyVelocity", root)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBodyGyro = Instance.new("BodyGyro", root)
        flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBodyGyro.CFrame = root.CFrame
        flyActive = true
        flyConnection = RunService.RenderStepped:Connect(function()
            local direction = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                direction = direction - Vector3.new(0, 1, 0)
            end
            if direction.Magnitude > 0 then
                flyBodyVelocity.Velocity = direction.Unit * flySpeed
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            flyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
        end)
    end
end

local function disableFly()
    flyActive = false
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

-----------------------------
-- ESP-Tab: Toggles
-----------------------------
ESPTogglesSection:AddToggle("CakeEspToggle", {
    Title = "Enable Cake ESP",
    Default = false,
    Callback = function(state)
        cakeEspActive = state
        if state then
            if cakeEspLoop then task.cancel(cakeEspLoop) end
            cakeEspLoop = task.spawn(cakeEspLoopFunction)
        else
            if cakeEspLoop then task.cancel(cakeEspLoop) end
            cakeEspLoop = nil
            removeCakeEsp()
        end
    end
})

ESPTogglesSection:AddToggle("CoinEspToggle", {
    Title = "Enable Coin ESP",
    Default = false,
    Callback = function(state)
        coinEspActive = state
        if state then
            if coinEspLoop then task.cancel(coinEspLoop) end
            coinEspLoop = task.spawn(coinEspLoopFunction)
        else
            if coinEspLoop then task.cancel(coinEspLoop) end
            coinEspLoop = nil
            removeCoinEsp()
        end
    end
})

ESPTogglesSection:AddToggle("ChamsToggle", {
    Title = "Enable Chams",
    Default = false,
    Callback = function(state)
        chamsActive = state
        if state then
            if chamsLoop then task.cancel(chamsLoop) end
            chamsLoop = task.spawn(chamsLoopFunction)
        else
            if chamsLoop then task.cancel(chamsLoop) end
            chamsLoop = nil
            removeChams()
        end
    end
})

ESPTogglesSection:AddToggle("NametagToggle", {
    Title = "Enable Nametags",
    Default = false,
    Callback = function(state)
        nametagActive = state
        if state then
            if nametagLoop then task.cancel(nametagLoop) end
            nametagLoop = task.spawn(nametagLoopFunction)
        else
            if nametagLoop then task.cancel(nametagLoop) end
            nametagLoop = nil
            removeNametags()
        end
    end
})

ESPTogglesSection:AddToggle("ValveEspToggle", {
    Title = "Enable Valve ESP",
    Default = false,
    Callback = function(state)
        valveEspActive = state
        if state then
            if valveEspLoop then task.cancel(valveEspLoop) end
            valveEspLoop = task.spawn(valveEspLoopFunction)
        else
            if valveEspLoop then
                task.cancel(valveEspLoop)
                valveEspLoop = nil
            end
            removeValveEsp()
        end
    end
})

ESPTogglesSection:AddToggle("PuzzleNumberEspToggle", {
    Title = "Enable Puzzle Number ESP",
    Default = false,
    Callback = function(state)
        puzzleNumberEspActive = state
        if state then
            if puzzleNumberEspLoop then task.cancel(puzzleNumberEspLoop) end
            puzzleNumberEspLoop = task.spawn(puzzleNumberEspLoopFunction)
        else
            if puzzleNumberEspLoop then
                task.cancel(puzzleNumberEspLoop)
                puzzleNumberEspLoop = nil
            end
            removePuzzleNumberEsp()
        end
    end
})

-----------------------------
-- ESP-Tab: Colors
-----------------------------
ESPColorsSection:AddColorpicker("CakeEspColor", {
    Title = "Cake ESP Color",
    Default = cakeEspColor,
    Callback = function(color)
        cakeEspColor = color
    end
})

ESPColorsSection:AddColorpicker("CoinEspColor", {
    Title = "Coin ESP Color",
    Default = coinEspColor,
    Callback = function(color)
        coinEspColor = color
    end
})

ESPColorsSection:AddColorpicker("EnemyChamsColor", {
    Title = "Enemy Chams Color",
    Default = enemyChamColor,
    Callback = function(color)
        enemyChamColor = color
    end
})

ESPColorsSection:AddColorpicker("TeamChamsColor", {
    Title = "Team Chams Color",
    Default = teamChamColor,
    Callback = function(color)
        teamChamColor = color
    end
})

ESPColorsSection:AddColorpicker("ValveEspColor", {
    Title = "Valve ESP Color",
    Default = valveEspColor,
    Callback = function(color)
        valveEspColor = color
    end
})

ESPColorsSection:AddColorpicker("PuzzleNumberEspColor", {
    Title = "Puzzle Number Color",
    Default = puzzleNumberEspColor,
    Callback = function(color)
        puzzleNumberEspColor = color
    end
})

-----------------------------
-- Player-Tab: Speed & Fly
-----------------------------
local SpeedInput = Tabs.Player:AddInput("SpeedInput", {
    Title = "Set Speed",
    Placeholder = "Default = 16",
    Numeric = true
})

Tabs.Player:AddButton({
    Title = "Set Player Speed",
    Description = "Set speed of Player",
    Callback = function()
        local speed = tonumber(SpeedInput.Value)
        if speed and speed > 0 then
            currentSpeed = speed
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = currentSpeed
            end
            if speedLoop then task.cancel(speedLoop) end
            speedLoop = task.spawn(function()
                while true do
                    local c = game.Players.LocalPlayer.Character
                    if c and c:FindFirstChild("Humanoid") then
                        c.Humanoid.WalkSpeed = currentSpeed
                    end
                    wait(1)
                end
            end)
        end
    end
})

Tabs.Player:AddButton({
    Title = "Reset Speed",
    Description = "Sets the speed to 16",
    Callback = function()
        currentSpeed = 16
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = currentSpeed
        end
        if speedLoop then
            task.cancel(speedLoop)
            speedLoop = nil
        end
    end
})

-- NEU: Fly Toggle und Fly Speed Input
local FlySpeedInput = Tabs.Player:AddInput("FlySpeedInput", {
    Title = "Set Fly Speed",
    Placeholder = "Default = 50",
    Numeric = true
})
Tabs.Player:AddButton({
    Title = "Set Fly Speed",
    Description = "Set fly speed of Player",
    Callback = function()
        local fSpeed = tonumber(FlySpeedInput.Value)
        if fSpeed and fSpeed > 0 then
            flySpeed = fSpeed
        end
    end
})
Tabs.Player:AddToggle("FlyToggle", {
    Title = "Fly (Local)",
    Default = false,
    Callback = function(state)
        if state then
            enableFly()
        else
            disableFly()
        end
    end
})

-----------------------------
-- Visual-Tab
-----------------------------
Tabs.Visual:AddToggle("FullbrightToggle", {
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

Tabs.Visual:AddToggle("NoFogToggle", {
    Title = "Disable Fog",
    Default = false,
    Callback = function(state)
        if state then
            noFogActive = true
            if noFogLoop then task.cancel(noFogLoop) end
            noFogLoop = task.spawn(noFogLoopFunction)
        else
            noFogActive = false
            if noFogLoop then task.cancel(noFogLoop) end
            game.Lighting.FogStart = 0
            game.Lighting.FogEnd = 1000
        end
    end
})

-----------------------------
-- Settings-Tab
-----------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-----------------------------
-- Abschluss
-----------------------------
Fluent:Notify({
    Title = "Tapetenputzer",
    Content = "Script Loaded!",
    Duration = 5
})

Window:SelectTab(1) -- Standardmäßig den ersten Tab (ESP) auswählen
