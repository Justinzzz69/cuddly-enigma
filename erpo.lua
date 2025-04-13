-- =============== FLUENT / LIBRARY SETUP ===============
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Helper function to re-enable movement (un-anchor, disable PlatformStand)
local function reEnableMovement()
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if root then root.Anchored = false end
        if hum then
            hum.PlatformStand = false
            hum.Sit = false
        end
    end
end

-- Create window (Acrylic = false for no blur)
local Window = Fluent:CreateWindow({
    Title = "ERPO Script",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Player    = Window:AddTab({ Title = "Player",    Icon = "user" }),
    ESP       = Window:AddTab({ Title = "ESP",       Icon = "eye" }),
    Functions = Window:AddTab({ Title = "Functions", Icon = "flame" }),
    Info      = Window:AddTab({ Title = "Info",      Icon = "heart" }),
    Settings  = Window:AddTab({ Title = "Settings",  Icon = "settings" })
}

-- =============== PLAYER / FLY / SPEED / ANTI AFK ===============
local currentSpeed = 16
local flySpeed = 50
local flyBodyVelocity, flyBodyGyro, flyConnection

---------------------------------------------------------
-- Helper functions
---------------------------------------------------------
local function getRootPart(character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not root then
        pcall(function()
            root = character:WaitForChild("HumanoidRootPart", 5)
        end)
    end
    return root
end

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
                dir = dir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                dir = dir - Vector3.new(0, 1, 0)
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

---------------------------------------------------------
-- Tab: Player
---------------------------------------------------------
local PlayerSection = Tabs.Player:AddSection("Speed, Fly")

PlayerSection:AddSlider("SpeedSlider", {
    Title = "Walk Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0
}):OnChanged(function(value)
    currentSpeed = value
    setWalkSpeed(currentSpeed)
end)

PlayerSection:AddToggle("FlyToggle", { Title = "Fly", Default = false })
    :OnChanged(function(state)
        if state then
            enableFly()
        else
            disableFly()
        end
    end)

PlayerSection:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed",
    Default = 50,
    Min = 0,
    Max = 300,
    Rounding = 0
}):OnChanged(function(value)
    flySpeed = value
end)

---------------------------------------------------------
-- Anti AFK
---------------------------------------------------------
local AntiAFKSection = Tabs.Player:AddSection("Anti AFK")
local AFKConnection

local function EnableAntiAFK()
    if AFKConnection then AFKConnection:Disconnect() AFKConnection = nil end
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

AntiAFKSection:AddToggle("AntiAFKToggle", { Title = "Anti AFK", Default = false })
    :OnChanged(function(state)
        if state then
            EnableAntiAFK()
        else
            DisableAntiAFK()
        end
    end)

---------------------------------------------------------
-- FUNCTIONS TAB
---------------------------------------------------------
local FunctionsSection = Tabs.Functions:AddSection("Auto Revive & Teleports")

-------------------------------
-- AUTO REVIVE (New):
-- Statt den Humanoid des Spielers zu teleportieren, wird nun das erste Objekt
-- im "PlayerHeads"-Ordner gefunden und mit einem Y-Offset von 5 Einheiten
-- über dem ReviveChecker-Hitbox teleportiert.
-------------------------------
local autoReviveConnection

local function AutoReviveCallback()
    local playerHeads = Workspace:FindFirstChild("PlayerHeads")
    if not playerHeads then return end

    local headObj = nil
    for _, obj in ipairs(playerHeads:GetChildren()) do
        if obj:IsA("BasePart") then
            headObj = obj
            break
        elseif obj:IsA("Model") then
            headObj = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if headObj then break end
        end
    end

    if headObj then
        local spawnArea = Workspace:FindFirstChild("Spawn Area")
        if not spawnArea then return end
        local important = spawnArea:FindFirstChild("Important")
        if not important then return end
        local reviveChecker = important:FindFirstChild("ReviveChecker")
        if not reviveChecker then return end
        local hitbox = reviveChecker:FindFirstChild("Hitbox")
        if hitbox and hitbox:IsA("BasePart") then
            headObj.CFrame = hitbox.CFrame * CFrame.new(0,5,0)
        end
    end
end

FunctionsSection:AddToggle("AutoReviveToggle", { Title = "Auto Revive", Default = false })
    :OnChanged(function(state)
        if state then
            autoReviveConnection = RunService.RenderStepped:Connect(function()
                AutoReviveCallback()
            end)
        else
            if autoReviveConnection then
                autoReviveConnection:Disconnect()
                autoReviveConnection = nil
            end
        end
    end)

-------------------------------
-- TELEPORT ITEMS TO QUOTACHECKER
-------------------------------
local TeleportSection = Tabs.Functions:AddSection("Teleport Items")
TeleportSection:AddButton({
    Title = "Teleport Items to QuotaChecker",
    Callback = function()
        local spawnArea = Workspace:FindFirstChild("Spawn Area")
        if not spawnArea then return end
        local important = spawnArea:FindFirstChild("Important")
        if not important then return end
        local quotaChecker = important:FindFirstChild("QuotaChecker")
        if not quotaChecker then return end

        local qcModel = quotaChecker:FindFirstChild("Model")
        if not qcModel then return end

        local targetPart = qcModel.PrimaryPart or qcModel:FindFirstChildWhichIsA("BasePart")
        if not targetPart then return end

        local spawnedLootFolder = Workspace:FindFirstChild("Spawned Loot")
        if spawnedLootFolder then
            for _, item in ipairs(spawnedLootFolder:GetChildren()) do
                local basePart = nil
                if item:IsA("Model") then
                    basePart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                elseif item:IsA("BasePart") then
                    basePart = item
                end
                if basePart then
                    -- Füge einen minimalen zufälligen Offset von ±0,1 Stud in X und Z hinzu
                    local offsetX = math.random(-10,10)/100  -- ergibt einen Wert zwischen -0.1 und 0.1
                    local offsetZ = math.random(-10,10)/100
                    basePart.CFrame = targetPart.CFrame * CFrame.new(offsetX, 3, offsetZ)
                    basePart.Velocity = Vector3.new(0,0,0)
                    -- Synchronisierung: kurzes Delay, damit die Physik-Engine den Offset verarbeiten kann
                    task.spawn(function()
                        task.wait(0.15)
                        basePart.Anchored = false
                    end)
                end
            end
        end
    end
})

-------------------------------
-- TELEPORT TO SHIP
-------------------------------
local function TeleportToShip()
    local spawnArea = Workspace:FindFirstChild("Spawn Area")
    if not spawnArea then return end
    local important = spawnArea:FindFirstChild("Important")
    if not important then return end
    local playerSpawn = important:FindFirstChild("PlayerSpawn")
    if not playerSpawn then return end
    local targetPart
    if playerSpawn:IsA("BasePart") then
        targetPart = playerSpawn
    elseif playerSpawn:IsA("Model") then
        targetPart = playerSpawn.PrimaryPart or playerSpawn:FindFirstChildWhichIsA("BasePart")
    end
    if not targetPart then return end
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = targetPart.CFrame
        end
    end
end

FunctionsSection:AddButton({
    Title = "Teleport to Ship",
    Callback = function()
        TeleportToShip()
    end
})

-------------------------------
-- AUTO SHOPPING
-------------------------------
local function AutoShopping()
    local shopItems = Workspace:FindFirstChild("Shop Items")
    if not shopItems then return end
    local targetContainer = Workspace:FindFirstChild("Store")
    if not targetContainer then return end
    local storeStore = targetContainer:FindFirstChild("Store")
    if not storeStore then return end
    local itemChecker = storeStore:FindFirstChild("ItemChecker")
    if not itemChecker then return end
    local hitbox = itemChecker:FindFirstChild("Hitbox")
    if not hitbox or not hitbox:IsA("BasePart") then return end
    local targetCF = hitbox.CFrame

    local function teleportFolder(folder)
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Folder") then
                teleportFolder(obj)
            else
                local base = nil
                if obj:IsA("BasePart") then
                    base = obj
                elseif obj:IsA("Model") then
                    base = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                end
                if base then
                    -- Füge einen minimalen zufälligen Offset von ±0,1 Stud in X und Z hinzu
                    local offsetX = math.random(-10,10)/100
                    local offsetZ = math.random(-10,10)/100
                    base.CFrame = targetCF * CFrame.new(offsetX, 1, offsetZ)
                    base.Velocity = Vector3.new(0,0,0)
                    task.spawn(function()
                        task.wait(0.15)
                        base.Anchored = false
                    end)
                end
            end
        end
    end

    teleportFolder(shopItems)
end

FunctionsSection:AddButton({
    Title = "Auto Shopping",
    Callback = function()
        AutoShopping()
    end
})

---------------------------------------------------------
-- ESP TAB – Sorted by Function
---------------------------------------------------------
local espActive = false
local espColor = Color3.fromRGB(255,255,255)

-- 1) Player ESP (Chams)
local function applyESPToCharacter(character)
    local highlight = character:FindFirstChild("ChamHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ChamHighlight"
        highlight.FillColor = espColor
        highlight.OutlineColor = espColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = character
    else
        highlight.FillColor = espColor
        highlight.OutlineColor = espColor
    end
end

local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            applyESPToCharacter(p.Character)
        end
    end
end

local function RemoveESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local highlight = p.Character:FindFirstChild("ChamHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
end

local espTask
local function espLoop()
    while espActive do
        UpdateESP()
        task.wait(2)
    end
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function(character)
            if espActive then
                applyESPToCharacter(character)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function(character)
            if espActive then
                applyESPToCharacter(character)
            end
        end)
    end
end)

-- 2) Nametags
local NametagsActive = false
local nametagTask

local function CreateNametag(p)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Nametag"
    billboard.Size = UDim2.new(0,50,0,50)
    billboard.StudsOffset = Vector3.new(0,2,0)
    billboard.AlwaysOnTop = true

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = p.Name
    label.TextScaled = false
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = espColor
    label.TextStrokeTransparency = 0.3

    return billboard
end

local function RemoveNametags()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local tag = p.Character.Head:FindFirstChild("Nametag")
            if tag then
                tag:Destroy()
            end
        end
    end
end

local function UpdateNametags()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local existing = head:FindFirstChild("Nametag")
            if not existing then
                local tag = CreateNametag(p)
                tag.Parent = head
            else
                existing.Size = UDim2.new(0,50,0,50)
                local frame = existing:FindFirstChildOfClass("Frame")
                if frame then
                    local lbl = frame:FindFirstChildOfClass("TextLabel")
                    if lbl then
                        lbl.TextColor3 = espColor
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

local espSection = Tabs.ESP:AddSection("Player ESP")
espSection:AddToggle("ESPToggle", { Title = "Player ESP (Chams)", Default = false })
    :OnChanged(function(state)
        espActive = state
        if state then
            espTask = task.spawn(espLoop)
        else
            if espTask then task.cancel(espTask) end
            espTask = nil
            RemoveESP()
        end
    end)

espSection:AddColorpicker("ESPColor", { Title = "Player Color", Default = espColor })
    :OnChanged(function(c)
        espColor = c
    end)

local nametagsSection = Tabs.ESP:AddSection("Nametags")
nametagsSection:AddToggle("NametagsToggle", { Title = "Nametags", Default = false })
    :OnChanged(function(state)
        NametagsActive = state
        if state then
            nametagTask = task.spawn(NametagsLoop)
        else
            if nametagTask then task.cancel(nametagTask) end
            nametagTask = nil
            RemoveNametags()
        end
    end)

-- 3) Item ESP + Chams
local itemESPActive = false
local itemColor = Color3.fromRGB(255,255,0)
local itemESPGuis = {}
local itemChamInstances = {}

local function createItemESP(item)
    if itemESPGuis[item] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ItemESP"
    billboard.Size = UDim2.new(0,100,0,20)
    billboard.StudsOffset = Vector3.new(0,2,0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = item.Name
    label.TextColor3 = itemColor
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.3
    label.Parent = billboard

    billboard.Parent = item
    itemESPGuis[item] = billboard
end

local function removeItemESP(item)
    if itemESPGuis[item] then
        itemESPGuis[item]:Destroy()
        itemESPGuis[item] = nil
    end
end

local function createItemChams(item)
    if itemChamInstances[item] then return end
    local target = item
    if item:IsA("Model") then
        target = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if not target then return end
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ItemChamHighlight"
    highlight.Adornee = target
    highlight.FillColor = itemColor
    highlight.OutlineColor = itemColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = target
    itemChamInstances[item] = highlight
end

local function removeItemChams(item)
    if itemChamInstances[item] then
        itemChamInstances[item]:Destroy()
        itemChamInstances[item] = nil
    end
end

local function removeAllItemESP()
    for item, gui in pairs(itemESPGuis) do
        if gui then gui:Destroy() end
    end
    table.clear(itemESPGuis)
    for item, instance in pairs(itemChamInstances) do
        if instance then instance:Destroy() end
    end
    table.clear(itemChamInstances)
end

local function updateItemESP()
    local spawnedLootFolder = Workspace:FindFirstChild("Spawned Loot")
    if not spawnedLootFolder then return end

    local currentItems = {}
    for _, child in pairs(spawnedLootFolder:GetChildren()) do
        currentItems[child] = true
        if not itemESPGuis[child] then createItemESP(child) end
        if not itemChamInstances[child] then createItemChams(child) end
    end

    for storedItem, _ in pairs(itemESPGuis) do
        if not currentItems[storedItem] then
            removeItemESP(storedItem)
            removeItemChams(storedItem)
        end
    end
end

local function itemESPLoop()
    while itemESPActive do
        updateItemESP()
        task.wait(2)
    end
end

local itemESPSection = Tabs.ESP:AddSection("Item ESP")
itemESPSection:AddToggle("ItemESPToggle", { Title = "Item ESP", Default = false })
    :OnChanged(function(state)
        itemESPActive = state
        if state then
            task.defer(itemESPLoop)
        else
            removeAllItemESP()
        end
    end)

itemESPSection:AddColorpicker("ItemColor", { Title = "Item Color", Default = itemColor })
    :OnChanged(function(c)
        itemColor = c
    end)

-- 4) Enemy ESP + Chams
local enemyESPActive = false
local enemyColor = Color3.fromRGB(255,0,0)
local enemyESPGuis = {}
local enemyChamInstances = {}

local function createEnemyESP(enemy)
    if enemyESPGuis[enemy] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EnemyESP"
    billboard.Size = UDim2.new(0,100,0,20)
    billboard.StudsOffset = Vector3.new(0,2,0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = enemy.Name
    label.TextColor3 = enemyColor
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.3
    label.Parent = billboard

    billboard.Parent = enemy
    enemyESPGuis[enemy] = billboard
end

local function removeEnemyESP(enemy)
    if enemyESPGuis[enemy] then
        enemyESPGuis[enemy]:Destroy()
        enemyESPGuis[enemy] = nil
    end
end

local function createEnemyChams(enemy)
    if enemyChamInstances[enemy] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "EnemyChamHighlight"
    highlight.Adornee = enemy
    highlight.FillColor = enemyColor
    highlight.OutlineColor = enemyColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = enemy
    enemyChamInstances[enemy] = highlight
end

local function removeEnemyChams(enemy)
    if enemyChamInstances[enemy] then
        enemyChamInstances[enemy]:Destroy()
        enemyChamInstances[enemy] = nil
    end
end

local function removeAllEnemyESP()
    for enemy, gui in pairs(enemyESPGuis) do
        if gui then gui:Destroy() end
    end
    table.clear(enemyESPGuis)
    for enemy, instance in pairs(enemyChamInstances) do
        if instance then instance:Destroy() end
    end
    table.clear(enemyChamInstances)
end

local function updateEnemyESP()
    local spawnedEnemiesFolder = Workspace:FindFirstChild("Spawned Enemies")
    if not spawnedEnemiesFolder then return end

    local currentEnemies = {}
    for _, child in pairs(spawnedEnemiesFolder:GetChildren()) do
        currentEnemies[child] = true
        if not enemyESPGuis[child] then createEnemyESP(child) end
        if not enemyChamInstances[child] then createEnemyChams(child) end
    end

    for storedEnemy, _ in pairs(enemyESPGuis) do
        if not currentEnemies[storedEnemy] then
            removeEnemyESP(storedEnemy)
            removeEnemyChams(storedEnemy)
        end
    end
end

local function enemyESPLoop()
    while enemyESPActive do
        updateEnemyESP()
        task.wait(2)
    end
end

local enemyESPSection = Tabs.ESP:AddSection("Enemy ESP")
enemyESPSection:AddToggle("EnemyESPToggle", { Title = "Enemy ESP", Default = false })
    :OnChanged(function(state)
        enemyESPActive = state
        if state then
            task.defer(enemyESPLoop)
        else
            removeAllEnemyESP()
        end
    end)

enemyESPSection:AddColorpicker("EnemyColor", { Title = "Enemy Color", Default = enemyColor })
    :OnChanged(function(c)
        enemyColor = c
    end)

-- 5) QuotaChecker ESP + Chams
local quotaCheckerESPActive = false
local quotaCheckerColor = Color3.fromRGB(255,128,64)
local quotaCheckerESPGuis = {}
local quotaCheckerChamInstances = {}

local function createQuotaCheckerESP(qcModel)
    if quotaCheckerESPGuis[qcModel] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuotaCheckerESP"
    billboard.Size = UDim2.new(0,120,0,30)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = "Quota Checker"
    label.TextColor3 = quotaCheckerColor
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.3
    label.Parent = billboard

    billboard.Parent = qcModel
    quotaCheckerESPGuis[qcModel] = billboard
end

local function removeQuotaCheckerESP(qcModel)
    if quotaCheckerESPGuis[qcModel] then
        quotaCheckerESPGuis[qcModel]:Destroy()
        quotaCheckerESPGuis[qcModel] = nil
    end
end

local function createQuotaCheckerChams(qcModel)
    if quotaCheckerChamInstances[qcModel] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "QuotaCheckerHighlight"
    highlight.Adornee = qcModel
    highlight.FillColor = quotaCheckerColor
    highlight.OutlineColor = quotaCheckerColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = qcModel
    quotaCheckerChamInstances[qcModel] = highlight
end

local function removeQuotaCheckerChams(qcModel)
    if quotaCheckerChamInstances[qcModel] then
        quotaCheckerChamInstances[qcModel]:Destroy()
        quotaCheckerChamInstances[qcModel] = nil
    end
end

local function removeAllQuotaCheckerESP()
    for qc, gui in pairs(quotaCheckerESPGuis) do
        if gui then gui:Destroy() end
    end
    table.clear(quotaCheckerESPGuis)
    for qc, instance in pairs(quotaCheckerChamInstances) do
        if instance then instance:Destroy() end
    end
    table.clear(quotaCheckerChamInstances)
end

local function updateQuotaCheckerESP()
    local spawnArea = Workspace:FindFirstChild("Spawn Area")
    if not spawnArea then return end
    local important = spawnArea:FindFirstChild("Important")
    if not important then return end
    local quotaCheckerFolder = important:FindFirstChild("QuotaChecker")
    if not quotaCheckerFolder then return end

    local qcModel = quotaCheckerFolder:FindFirstChild("Model")
    if not qcModel then return end
    if not quotaCheckerESPGuis[qcModel] then
        createQuotaCheckerESP(qcModel)
    end
    if not quotaCheckerChamInstances[qcModel] then
        createQuotaCheckerChams(qcModel)
    end
end

local function quotaCheckerESPLoop()
    while quotaCheckerESPActive do
        updateQuotaCheckerESP()
        task.wait(2)
    end
end

local quotaCheckerSection = Tabs.ESP:AddSection("QuotaChecker ESP")
quotaCheckerSection:AddToggle("QuotaCheckerESPToggle", { Title = "QuotaChecker ESP", Default = false })
    :OnChanged(function(state)
        quotaCheckerESPActive = state
        if state then
            task.defer(quotaCheckerESPLoop)
        else
            removeAllQuotaCheckerESP()
        end
    end)

quotaCheckerSection:AddColorpicker("QuotaCheckerColor", { Title = "QuotaChecker Color", Default = quotaCheckerColor })
    :OnChanged(function(c)
        quotaCheckerColor = c
    end)

---------------------------------------------------------
-- Tab: Info
---------------------------------------------------------
local InfoSection = Tabs.Info:AddSection("Info")
InfoSection:AddParagraph({
    Title = "Info",
    Content = "Made by Tapetenputzer\nDiscord: tapetenputzer"
})

---------------------------------------------------------
-- SETTINGS, SAVE, LOAD
---------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub_MicUp")
SaveManager:SetFolder("FluentScriptHub_MicUp/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)
