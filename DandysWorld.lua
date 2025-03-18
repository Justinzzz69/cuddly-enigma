local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Window = Fluent:CreateWindow({
    Title = "Dandys World Script",
    SubTitle = "by Tapetenputzer",
    TabWidth = 160,
    Size = UDim2.fromOffset(580,460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local ESPSection = Tabs.ESP:AddSection("ESP")
local ColorSection = Tabs.ESP:AddSection("ESP Colors")
local VisualsSection = Tabs.Settings:AddSection("Visuals")

local function createBillboard(text, size, textColor)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = size or UDim2.new(0,100,0,40)
    billboard.AlwaysOnTop = true
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1,0,1,0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = textColor or Color3.new(1,1,1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    return billboard
end

-- MONSTER ESP
local monsterESPActive = false
local monsterESPColor = Color3.fromRGB(255,0,0)
local monsterNametagColor = Color3.new(1,1,1)
local monsterESPLoop

local function processMonsterModel(model)
    if not model or not model:IsA("Model") then return end
    local lowerName = string.lower(model.Name)
    if not string.find(lowerName, "monster") then return end
    if not model:FindFirstChild("MonsterHighlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "MonsterHighlight"
        hl.Adornee = model
        hl.FillColor = monsterESPColor
        hl.OutlineColor = monsterESPColor
        hl.Parent = model
    else
        model.MonsterHighlight.FillColor = monsterESPColor
        model.MonsterHighlight.OutlineColor = monsterESPColor
    end
    local head = model:FindFirstChild("Head")
    if head and not head:FindFirstChild("MonsterNametag") then
        local billboard = createBillboard(model.Name, UDim2.new(0,100,0,40), monsterNametagColor)
        billboard.Name = "MonsterNametag"
        billboard.Adornee = head
        billboard.Parent = head
    end
end

local function monsterESPUpdateLoop()
    while monsterESPActive do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not monsterESPActive then break end
            if obj:IsA("Model") then
                processMonsterModel(obj)
            end
        end
        if not monsterESPActive then break end
        wait(2)
    end
end

local function removeMonsterESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            for _, child in ipairs(obj:GetChildren()) do
                if child.Name == "MonsterHighlight" then
                    child:Destroy()
                end
            end
        end
        if obj:IsA("BasePart") then
            for _, child in ipairs(obj:GetChildren()) do
                if child.Name == "MonsterNametag" then
                    child:Destroy()
                end
            end
        end
    end
end

local function toggleMonsterESP(state)
    monsterESPActive = state
    if monsterESPActive then
        monsterESPLoop = task.spawn(monsterESPUpdateLoop)
    else
        if monsterESPLoop then
            task.cancel(monsterESPLoop)
            monsterESPLoop = nil
        end
        task.delay(0.5, removeMonsterESP)
    end
end

ESPSection:AddToggle("MonsterESPToggle", { Title = "Activate Monster ESP", Default = false, Callback = function(state) toggleMonsterESP(state) end })
ColorSection:AddColorpicker("MonsterHighlightColor", { Title = "Monster Highlight Color", Default = monsterESPColor, Callback = function(color) monsterESPColor = color end })
ColorSection:AddColorpicker("MonsterNametagColor", { Title = "Monster Nametag Color", Default = monsterNametagColor, Callback = function(color) monsterNametagColor = color end })

-- MACHINE ESP
local machineESPActive = false
local machineESPColor = Color3.fromRGB(0,255,0)
local machineNametagColor = Color3.new(1,1,1)
local machineESPLoop

local function processMachineModel(model)
    if not model or not model:IsA("Model") then return end
    local lowerName = string.lower(model.Name)
    if not string.find(lowerName, "generator") then return end
    if not model:FindFirstChild("MachineHighlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "MachineHighlight"
        hl.Adornee = model
        hl.FillColor = machineESPColor
        hl.OutlineColor = machineESPColor
        hl.Parent = model
    else
        model.MachineHighlight.FillColor = machineESPColor
        model.MachineHighlight.OutlineColor = machineESPColor
    end
    local target = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if target and not target:FindFirstChild("MachineNametag") then
        local billboard = createBillboard(model.Name, UDim2.new(0,100,0,40), machineNametagColor)
        billboard.Name = "MachineNametag"
        billboard.Adornee = target
        billboard.Parent = target
    end
end

local function machineESPUpdateLoop()
    while machineESPActive do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not machineESPActive then break end
            if obj:IsA("Model") then
                processMachineModel(obj)
            end
        end
        if not machineESPActive then break end
        wait(2)
    end
end

local function removeMachineESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            for _, child in ipairs(obj:GetChildren()) do
                if child.Name == "MachineHighlight" then child:Destroy() end
            end
        end
        if obj:IsA("BasePart") then
            for _, child in ipairs(obj:GetChildren()) do
                if child.Name == "MachineNametag" then child:Destroy() end
            end
        end
    end
end

local function toggleMachineESP(state)
    machineESPActive = state
    if machineESPActive then
        machineESPLoop = task.spawn(machineESPUpdateLoop)
    else
        if machineESPLoop then
            task.cancel(machineESPLoop)
            machineESPLoop = nil
        end
        task.delay(0.5, removeMachineESP)
    end
end

ESPSection:AddToggle("MachineESPToggle", { Title = "Activate Machine ESP", Default = false, Callback = function(state) toggleMachineESP(state) end })
ColorSection:AddColorpicker("MachineHighlightColor", { Title = "Machine Highlight Color", Default = machineESPColor, Callback = function(color) machineESPColor = color end })
ColorSection:AddColorpicker("MachineNametagColor", { Title = "Machine Nametag Color", Default = machineNametagColor, Callback = function(color) machineNametagColor = color end })

-- ITEM ESP
local itemESPActive = false
local itemNametagColor = Color3.new(1,1,1)
local itemESPLoop = nil

local function isInItems(obj)
    local current = obj.Parent
    while current do
        if string.find(string.lower(current.Name), "items") then return true end
        current = current.Parent
    end
    return false
end

local function getItemModel(part)
    local current = part
    while current do
        if current:IsA("Model") and string.lower(current.Name) ~= "items" then return current end
        current = current.Parent
    end
    return nil
end

local function getDisplayPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part end
    end
    return nil
end

local function createItemNametag(part, displayName)
    if not part or not part:IsA("BasePart") then return end
    if part:FindFirstChild("ItemNametag") then return end
    local billboard = createBillboard(displayName or part.Name, UDim2.new(0,100,0,40), itemNametagColor)
    billboard.Name = "ItemNametag"
    billboard.Adornee = part
    billboard.Parent = part
end

local function processItem(part)
    if typeof(part) ~= "Instance" or not part:IsA("BasePart") then return end
    if not isInItems(part) then return end
    local model = getItemModel(part) or part
    if model:FindFirstChild("ItemNametag") then return end
    local displayPart = getDisplayPart(model) or part
    local displayName = model.Name
    createItemNametag(displayPart, displayName)
end

local function itemESPUpdateLoop()
    while itemESPActive do
        for _, obj in ipairs(workspace:GetDescendants()) do
            processItem(obj)
        end
        wait(2)
    end
end

local function removeItemESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _, child in ipairs(obj:GetChildren()) do
                if child.Name == "ItemNametag" then child:Destroy() end
            end
        end
        if obj:IsA("Model") then
            local tag = obj:FindFirstChild("ItemNametag")
            if tag then tag:Destroy() end
        end
    end
end

local function toggleItemESP(state)
    itemESPActive = state
    if itemESPActive then
        itemESPLoop = task.spawn(itemESPUpdateLoop)
    else
        if itemESPLoop then
            task.cancel(itemESPLoop)
            itemESPLoop = nil
        end
        task.delay(0.5, removeItemESP)
    end
end

ESPSection:AddToggle("ItemESPToggle", { Title = "Activate Item ESP", Default = false, Callback = function(state) toggleItemESP(state) end })
ColorSection:AddColorpicker("ItemNametagColor", { Title = "Item Nametag Color", Default = itemNametagColor, Callback = function(color) itemNametagColor = color end })

-- PLAYER ESP
local playerESPActive = false
local playerESPColor = Color3.fromRGB(0,0,255)
local playerNametagColor = Color3.new(1,1,1)
local playerESPLoop

local function processPlayerModel(model)
    if not model or not model:IsA("Model") then return end
    if model.Parent ~= workspace.InGamePlayers then return end
    if not model:FindFirstChild("PlayerHighlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "PlayerHighlight"
        hl.Adornee = model
        hl.FillColor = playerESPColor
        hl.OutlineColor = playerESPColor
        hl.Parent = model
    else
        model.PlayerHighlight.FillColor = playerESPColor
        model.PlayerHighlight.OutlineColor = playerESPColor
    end
    local target = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    if target and not target:FindFirstChild("PlayerNametag") then
        local billboard = createBillboard(model.Name, UDim2.new(0,100,0,40), playerNametagColor)
        billboard.Name = "PlayerNametag"
        billboard.Adornee = target
        billboard.Parent = target
    end
end

local function playerESPUpdateLoop()
    while playerESPActive do
        for _, obj in ipairs(workspace.InGamePlayers:GetChildren()) do
            if not playerESPActive then break end
            if obj:IsA("Model") then
                processPlayerModel(obj)
            end
        end
        if not playerESPActive then break end
        wait(2)
    end
end

local function removePlayerESP()
    for _, obj in ipairs(workspace.InGamePlayers:GetChildren()) do
        if obj:IsA("Model") then
            if obj:FindFirstChild("PlayerHighlight") then obj.PlayerHighlight:Destroy() end
            local target = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if target and target:FindFirstChild("PlayerNametag") then target.PlayerNametag:Destroy() end
        end
    end
end

local function togglePlayerESP(state)
    playerESPActive = state
    if playerESPActive then
        playerESPLoop = task.spawn(playerESPUpdateLoop)
    else
        if playerESPLoop then
            task.cancel(playerESPLoop)
            playerESPLoop = nil
        end
        task.delay(0.5, removePlayerESP)
    end
end

ESPSection:AddToggle("PlayerESPToggle", { Title = "Activate Player ESP", Default = false, Callback = function(state) togglePlayerESP(state) end })
ColorSection:AddColorpicker("PlayerHighlightColor", { Title = "Player Highlight Color", Default = playerESPColor, Callback = function(color) playerESPColor = color end })
ColorSection:AddColorpicker("PlayerNametagColor", { Title = "Player Nametag Color", Default = playerNametagColor, Callback = function(color) playerNametagColor = color end })

-- FULLBRIGHT TOGGLE
local fullbrightActive = false

local function toggleFullbright(state)
    fullbrightActive = state
    if fullbrightActive then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.new(0,0,0)
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000
        Lighting.GlobalShadows = true
    end
end

VisualsSection:AddToggle("FullbrightToggle", { Title = "Enable Fullbright", Default = false, Callback = function(state) toggleFullbright(state) end })

local Options = Fluent.Options
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)
Fluent:Notify({ Title = "ESP", Content = "Script loaded", Duration = 8 })
print("Script successfully loaded!")
