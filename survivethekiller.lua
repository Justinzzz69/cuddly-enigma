local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local Window = Fluent:CreateWindow({
    Title = "Killer/Survivor & Player Script",
    SubTitle = "Combined Features",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "sun" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options

Fluent:Notify({
    Title = "Loaded",
    Content = "All features script loaded.",
    Duration = 5
})

-----------------------------------------------------------
-- PLAYER ESP (Chams & Nametags)
-----------------------------------------------------------
local chamsActive = false
local nametagActive = false
local killerColor = Color3.fromRGB(255, 0, 0)
local survivorColor = Color3.fromRGB(0, 255, 0)
local playerEspRefs = {}

local function removePlayerESP(plr)
    local ref = playerEspRefs[plr]
    if ref then
        if ref.chams then pcall(function() ref.chams:Destroy() end) end
        if ref.nametag then pcall(function() ref.nametag:Destroy() end) end
        playerEspRefs[plr] = nil
    end
end

local function updatePlayerChamsColor(plr, hl)
    if hl then
        if plr.Team and plr.Team.Name == "Killer" then
            hl.FillColor = killerColor
        else
            hl.FillColor = survivorColor
        end
    end
end

local function createChams(plr, char)
    local hl = Instance.new("Highlight")
    hl.Adornee = char
    updatePlayerChamsColor(plr, hl)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 1
    hl.Parent = char
    return hl
end

local function createNametag(plr, char)
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bg = Instance.new("BillboardGui")
    bg.Name = "NametagESP"
    bg.Adornee = head
    bg.Size = UDim2.new(0, 100, 0, 40)
    bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.AlwaysOnTop = true

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = plr.Name
    txt.TextScaled = true
    txt.Font = Enum.Font.SourceSansBold
    if plr.Team and plr.Team.Name == "Killer" then
        txt.TextColor3 = killerColor
    else
        txt.TextColor3 = survivorColor
    end
    txt.Parent = bg

    bg.Parent = head
    return bg
end

local function applyPlayerESP(plr)
    removePlayerESP(plr)
    local char = plr.Character or plr.CharacterAdded:Wait()
    local ref = {}
    if chamsActive then
        ref.chams = createChams(plr, char)
    end
    if nametagActive then
        ref.nametag = createNametag(plr, char)
    end
    playerEspRefs[plr] = ref
end

local function updateAllPlayerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            applyPlayerESP(p)
        end
    end
end

local function onTeamChanged(plr)
    local ref = playerEspRefs[plr]
    if ref and ref.chams then
        updatePlayerChamsColor(plr, ref.chams)
    end
end

local function onPlayerAdded(plr)
    plr:GetPropertyChangedSignal("Team"):Connect(function()
        onTeamChanged(plr)
    end)
    plr.CharacterAdded:Connect(function()
        task.wait(0.1)
        applyPlayerESP(plr)
    end)
    if plr.Character then
        applyPlayerESP(plr)
    end
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p) removePlayerESP(p) end)

task.spawn(function()
    while true do
        updateAllPlayerESP()
        task.wait(5)
    end
end)

-----------------------------------------------------------
-- ITEM ESP (Only "Border" objects with "Item" nametag)
-----------------------------------------------------------
local itemESPActive = false
local itemESPColor = Color3.fromRGB(0, 170, 255)
local itemTagged = {}
local descAddConn, descRemConn
local scanRadius = 50

local function isBorderObject(obj)
    return obj.Name:lower() == "border"
end

local function removeItem(obj)
    if itemTagged[obj] then
        itemTagged[obj] = nil
        if obj:IsA("BasePart") then
            local tag = obj:FindFirstChild("ItemNametag")
            if tag then tag:Destroy() end
        elseif obj:IsA("Model") and obj.PrimaryPart then
            local p = obj.PrimaryPart
            local tag = p:FindFirstChild("ItemNametag")
            if tag then tag:Destroy() end
        end
    end
end

local function createItemNametag(part)
    local bg = Instance.new("BillboardGui")
    bg.Name = "ItemNametag"
    bg.Adornee = part
    bg.Size = UDim2.new(0, 100, 0, 40)
    bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.AlwaysOnTop = true

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Item"
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextColor3 = itemESPColor
    lbl.Parent = bg

    bg.Parent = part
end

local function tagItem(obj)
    if itemTagged[obj] then return end
    local part
    if obj:IsA("BasePart") then
        part = obj
    elseif obj:IsA("Model") and obj.PrimaryPart then
        part = obj.PrimaryPart
    else
        return
    end
    local plrChar = Players.LocalPlayer.Character
    if plrChar and plrChar:FindFirstChild("HumanoidRootPart") then
        local dist = (part.Position - plrChar.HumanoidRootPart.Position).Magnitude
        if dist > scanRadius then
            -- Uncomment to enforce strict distance: return
        end
    end
    if part:FindFirstChild("ItemNametag") then return end
    createItemNametag(part)
    itemTagged[obj] = true
end

local function processForItemESP(obj)
    if not itemESPActive then return end
    if isBorderObject(obj) then
        tagItem(obj)
    end
end

local function startItemWatchers()
    for _, obj in ipairs(workspace:GetDescendants()) do
        processForItemESP(obj)
    end
    descAddConn = workspace.DescendantAdded:Connect(function(o)
        processForItemESP(o)
    end)
    descRemConn = workspace.DescendantRemoving:Connect(function(o)
        if itemTagged[o] then
            removeItem(o)
        end
    end)
end

local function stopItemWatchers()
    if descAddConn then descAddConn:Disconnect() descAddConn = nil end
    if descRemConn then descRemConn:Disconnect() descRemConn = nil end
    for obj in pairs(itemTagged) do
        removeItem(obj)
    end
    itemTagged = {}
end

local function setItemESP(state)
    itemESPActive = state
    if state then
        startItemWatchers()
    else
        stopItemWatchers()
    end
end

task.spawn(function()
    while true do
        if itemESPActive then
            for obj in pairs(itemTagged) do
                local part
                if obj:IsA("BasePart") then
                    part = obj
                elseif obj:IsA("Model") and obj.PrimaryPart then
                    part = obj.PrimaryPart
                end
                if part then
                    local tag = part:FindFirstChild("ItemNametag")
                    if tag then
                        local lbl = tag:FindFirstChildOfClass("TextLabel")
                        if lbl then
                            lbl.TextColor3 = itemESPColor
                        end
                    end
                end
            end
        end
        task.wait(5)
    end
end)

-----------------------------------------------------------
-- BEARTRAP ESP
-----------------------------------------------------------
local beartrapESPActive = false
local beartrapESPColor = Color3.fromRGB(255, 100, 0)
local beartrapTagged = {}
local bearDescAddConn, bearDescRemConn

local function isBeartrap(obj)
    return obj.Name:lower():find("beartrap")
end

local function removeBeartrapESP(obj)
    if beartrapTagged[obj] then
        beartrapTagged[obj] = nil
        if obj:IsA("BasePart") then
            local tag = obj:FindFirstChild("BeartrapNametag")
            if tag then tag:Destroy() end
        elseif obj:IsA("Model") and obj.PrimaryPart then
            local p = obj.PrimaryPart
            local tag = p:FindFirstChild("BeartrapNametag")
            if tag then tag:Destroy() end
        end
    end
end

local function createBeartrapNametag(part)
    local bg = Instance.new("BillboardGui")
    bg.Name = "BeartrapNametag"
    bg.Adornee = part
    bg.Size = UDim2.new(0, 100, 0, 40)
    bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.AlwaysOnTop = true

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "BearTrap"
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextColor3 = beartrapESPColor
    lbl.Parent = bg

    bg.Parent = part
end

local function tagBeartrap(obj)
    if beartrapTagged[obj] then return end
    local part
    if obj:IsA("BasePart") then
        part = obj
    elseif obj:IsA("Model") and obj.PrimaryPart then
        part = obj.PrimaryPart
    else
        return
    end
    local plrChar = Players.LocalPlayer.Character
    if plrChar and plrChar:FindFirstChild("HumanoidRootPart") then
        local dist = (part.Position - plrChar.HumanoidRootPart.Position).Magnitude
        if dist > scanRadius then
            -- Uncomment to enforce radius: return
        end
    end
    if part:FindFirstChild("BeartrapNametag") then return end
    createBeartrapNametag(part)
    beartrapTagged[obj] = true
end

local function processForBeartrapESP(obj)
    if not beartrapESPActive then return end
    if isBeartrap(obj) then
        tagBeartrap(obj)
    end
end

local function startBeartrapWatchers()
    for _, obj in ipairs(workspace:GetDescendants()) do
        processForBeartrapESP(obj)
    end
    bearDescAddConn = workspace.DescendantAdded:Connect(function(o)
        processForBeartrapESP(o)
    end)
    bearDescRemConn = workspace.DescendantRemoving:Connect(function(o)
        if beartrapTagged[o] then
            removeBeartrapESP(o)
        end
    end)
end

local function stopBeartrapWatchers()
    if bearDescAddConn then bearDescAddConn:Disconnect() bearDescAddConn = nil end
    if bearDescRemConn then bearDescRemConn:Disconnect() bearDescRemConn = nil end
    for obj in pairs(beartrapTagged) do
        removeBeartrapESP(obj)
    end
    beartrapTagged = {}
end

local function setBeartrapESP(state)
    beartrapESPActive = state
    if state then
        startBeartrapWatchers()
    else
        stopBeartrapWatchers()
    end
end

task.spawn(function()
    while true do
        if beartrapESPActive then
            for obj in pairs(beartrapTagged) do
                local part
                if obj:IsA("BasePart") then
                    part = obj
                elseif obj:IsA("Model") and obj.PrimaryPart then
                    part = obj.PrimaryPart
                end
                if part then
                    local tag = part:FindFirstChild("BeartrapNametag")
                    if tag then
                        local lbl = tag:FindFirstChildOfClass("TextLabel")
                        if lbl then
                            lbl.TextColor3 = beartrapESPColor
                        end
                    end
                end
            end
        end
        task.wait(5)
    end
end)

-----------------------------------------------------------
-- ESP Tab UI
-----------------------------------------------------------
-- CHAMS
local ChamsToggle = Tabs.ESP:AddToggle("ChamsToggle", {
	Title = "Player Chams",
	Default = false,
	Callback = function(state)
		chamsActive = state
		updateAllPlayerESP()
	end
})
function ChamsToggle:UpdateColors() end  -- Prevent "attempt to call nil" error

-- NAMETAGS
local NametagToggle = Tabs.ESP:AddToggle("NametagToggle", {
	Title = "Player Nametags",
	Default = false,
	Callback = function(state)
		nametagActive = state
		if not state then
			-- remove all existing nametags
			for _, plyr in ipairs(Players:GetPlayers()) do
				if plyr.Character and plyr.Character:FindFirstChild("Head") then
					local tag = plyr.Character.Head:FindFirstChild("NametagESP")
					if tag then tag:Destroy() end
				end
			end
		end
		updateAllPlayerESP()
	end
})
function NametagToggle:UpdateColors() end

-- ITEM
local ItemToggle = Tabs.ESP:AddToggle("ItemESPToggle", {
	Title = "Item ESP (Border->Item)",
	Default = false,
	Callback = function(state)
		setItemESP(state)
	end
})
function ItemToggle:UpdateColors() end

-- BEARTRAP
local BeartrapToggle = Tabs.ESP:AddToggle("BeartrapESPToggle", {
	Title = "Beartrap ESP",
	Default = false,
	Callback = function(state)
		setBeartrapESP(state)
	end
})
function BeartrapToggle:UpdateColors() end

-----------------------------------------------------------
-- ESP COLORS
-----------------------------------------------------------
local ESPColorsSection = Tabs.ESP:AddSection("ESP Colors")
local killerColorPicker = ESPColorsSection:AddColorpicker("KillerColor", {
	Title = "Killer Color",
	Default = killerColor,
	Callback = function(col)
		killerColor = col
		updateAllPlayerESP()
	end
})
killerColorPicker:SetValueRGB(killerColor)
function killerColorPicker:UpdateColors() end

local survivorColorPicker = ESPColorsSection:AddColorpicker("SurvivorColor", {
	Title = "Survivor Color",
	Default = survivorColor,
	Callback = function(col)
		survivorColor = col
		updateAllPlayerESP()
	end
})
survivorColorPicker:SetValueRGB(survivorColor)
function survivorColorPicker:UpdateColors() end

local itemColorPicker = ESPColorsSection:AddColorpicker("ItemColor", {
	Title = "Item ESP Color",
	Default = itemESPColor,
	Callback = function(col)
		itemESPColor = col
	end
})
itemColorPicker:SetValueRGB(itemESPColor)
function itemColorPicker:UpdateColors() end

local beartrapColorPicker = ESPColorsSection:AddColorpicker("BeartrapColor", {
	Title = "Beartrap ESP Color",
	Default = beartrapESPColor,
	Callback = function(col)
		beartrapESPColor = col
	end
})
beartrapColorPicker:SetValueRGB(beartrapESPColor)
function beartrapColorPicker:UpdateColors() end

-----------------------------------------------------------
-- PLAYER Tab
-----------------------------------------------------------
local currentSpeed = 16
local speedLoop

local PlayerSpeedInput = Tabs.Player:AddInput("SpeedInput", {
	Title = "Set Speed",
	Placeholder = "16",
	Numeric = true
})
local SpeedButton = Tabs.Player:AddButton({
	Title = "Set Player Speed",
	Callback = function()
		local spd = tonumber(PlayerSpeedInput.Value)
		if spd and spd > 0 then
			currentSpeed = spd
			local plr = Players.LocalPlayer
			if plr.Character and plr.Character:FindFirstChild("Humanoid") then
				plr.Character.Humanoid.WalkSpeed = currentSpeed
			end
			if speedLoop then task.cancel(speedLoop) end
			speedLoop = task.spawn(function()
				while true do
					local c = plr.Character
					if c and c:FindFirstChild("Humanoid") then
						c.Humanoid.WalkSpeed = currentSpeed
					end
					task.wait(3)
				end
			end)
		end
	end
})
function SpeedButton:UpdateColors() end  -- stub

local ResetSpeedButton = Tabs.Player:AddButton({
	Title = "Reset Speed",
	Callback = function()
		currentSpeed = 16
		local plr = Players.LocalPlayer
		if plr.Character and plr.Character:FindFirstChild("Humanoid") then
			plr.Character.Humanoid.WalkSpeed = currentSpeed
		end
		if speedLoop then task.cancel(speedLoop) end
		speedLoop = nil
		PlayerSpeedInput:SetValue("16")
	end
})
function ResetSpeedButton:UpdateColors() end  -- stub

-- Fly
local flyActive = false
local flySpeed = 50
local flyBodyVelocity, flyBodyGyro, flyConnection

local function enableFly()
	local plr = Players.LocalPlayer
	if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		local root = plr.Character.HumanoidRootPart
		flyBodyVelocity = Instance.new("BodyVelocity", root)
		flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
		flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyBodyGyro = Instance.new("BodyGyro", root)
		flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		flyBodyGyro.CFrame = root.CFrame
		flyActive = true

		flyConnection = RunService.RenderStepped:Connect(function()
			local dir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				dir += workspace.CurrentCamera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				dir -= workspace.CurrentCamera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				dir -= workspace.CurrentCamera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				dir += workspace.CurrentCamera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				dir += Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				dir -= Vector3.new(0, 1, 0)
			end
			if dir.Magnitude > 0 then
				flyBodyVelocity.Velocity = dir.Unit * flySpeed
			else
				flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
			end
			flyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
		end)
	end
end

local function disableFly()
	flyActive = false
	if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
	if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end
end

local FlyToggle = Tabs.Player:AddToggle("FlyToggle", {
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
function FlyToggle:UpdateColors() end

local FlySpeedInput = Tabs.Player:AddInput("FlySpeedInput", {
	Title = "Set Fly Speed",
	Placeholder = "50",
	Numeric = true
})
local FlySpeedButton = Tabs.Player:AddButton({
	Title = "Set Fly Speed",
	Callback = function()
		local val = tonumber(FlySpeedInput.Value)
		if val and val > 0 then
			flySpeed = val
		end
	end
})
function FlySpeedButton:UpdateColors() end

local AntiAFKToggle = Tabs.Player:AddToggle("AntiAFKToggle", {
	Title = "Anti-AFK",
	Default = false,
	Callback = function(state)
		if state then
			Players.LocalPlayer.Idled:Connect(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0,0))
			end)
		end
	end
})
function AntiAFKToggle:UpdateColors() end

-----------------------------------------------------------
-- VISUAL Tab
-----------------------------------------------------------
local VisualSection = Tabs.Visual
local function noFogLoopFunction()
	while true do
		if Lighting.FogEnd < 1e9 then
			Lighting.FogStart = 0
			Lighting.FogEnd = 1e9
		end
		task.wait(1)
	end
end

local fullbrightActive
VisualSection:AddToggle("FullbrightToggle", {
	Title = "Fullbright",
	Default = false,
	Callback = function(state)
		if state then
			Lighting.Brightness = 10
			Lighting.ClockTime = 12
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
		else
			Lighting.Brightness = 1
			Lighting.ClockTime = 14
			Lighting.FogEnd = 1000
			Lighting.GlobalShadows = true
		end
	end
})

local noFogActive
VisualSection:AddToggle("NoFogToggle", {
	Title = "No Fog",
	Default = false,
	Callback = function(state)
		noFogActive = state
		if state then
			task.spawn(noFogLoopFunction)
		else
			Lighting.FogStart = 0
			Lighting.FogEnd = 1000
		end
	end
})

local ccActive
local ccEffect
local ccBrightness = 0
local ccContrast = 0
local ccSaturation = 1
local function enableColorCorrection()
	if not Lighting:FindFirstChild("ColorCorrectionEffect") then
		ccEffect = Instance.new("ColorCorrectionEffect")
		ccEffect.Parent = Lighting
	else
		ccEffect = Lighting:FindFirstChild("ColorCorrectionEffect")
	end
	ccEffect.Brightness = ccBrightness
	ccEffect.Contrast = ccContrast
	ccEffect.Saturation = ccSaturation
end
local function disableColorCorrection()
	if ccEffect then
		ccEffect:Destroy()
		ccEffect = nil
	end
end

VisualSection:AddToggle("ColorCorrectionToggle", {
	Title = "Color Correction",
	Default = false,
	Callback = function(state)
		ccActive = state
		if state then
			enableColorCorrection()
		else
			disableColorCorrection()
		end
	end
})

local sunRaysActive
local sunRaysEffect
local sunRaysIntensity = 0.3
local function enableSunRays()
	if not Lighting:FindFirstChild("SunRaysEffect") then
		sunRaysEffect = Instance.new("SunRaysEffect")
		sunRaysEffect.Parent = Lighting
	else
		sunRaysEffect = Lighting:FindFirstChild("SunRaysEffect")
	end
	sunRaysEffect.Intensity = sunRaysIntensity
end
local function disableSunRays()
	if sunRaysEffect then
		sunRaysEffect:Destroy()
		sunRaysEffect = nil
	end
end

VisualSection:AddToggle("SunRaysToggle", {
	Title = "SunRays",
	Default = false,
	Callback = function(state)
		sunRaysActive = state
		if state then
			enableSunRays()
		else
			disableSunRays()
		end
	end
})

-----------------------------------------------------------
-- SETTINGS Tab
-----------------------------------------------------------
Tabs.Settings:AddParagraph({
	Title = "General Settings",
	Content = "Configure your settings here."
})

local function toggleUI()
	Window:ToggleMinimize()
end

local UIColorPicker = Tabs.Settings:AddColorpicker("UIColor", {
	Title = "UI Color",
	Default = Color3.fromRGB(96,205,255),
	Callback = function(c)
		Fluent.AccentColor = c
	end
})
UIColorPicker:SetValueRGB(Color3.fromRGB(255,100,100))

local InterfaceKeybind = Tabs.Settings:AddKeybind("InterfaceKeybind", {
	Title = "Toggle UI",
	Mode = "Toggle",
	Default = "F",
	Callback = function() toggleUI() end
})
InterfaceKeybind:OnChanged(function() end)
InterfaceKeybind:SetValue("G", "Toggle")

local PlayerNameInput = Tabs.Settings:AddInput("PlayerName", {
	Title = "Player Name",
	Default = "Player",
	Placeholder = "Enter your name",
	Numeric = false,
	Finished = false,
	Callback = function(_) end
})
PlayerNameInput:OnChanged(function() end)

-----------------------------------------------------------
-- SaveManager & InterfaceManager
-----------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- Added Credits and Discord Notify (ENGLISH ONLY)
Fluent:Notify({
    Title = "Credits",
    Content = "Made by Tapetenputzer. Please add me on Discord!",
    Duration = 10
})

Window:SelectTab(1)
print("Script successfully loaded! | Credits: Made by Tapetenputzer | Add me on Discord!")
