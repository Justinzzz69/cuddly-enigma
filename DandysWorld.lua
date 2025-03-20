local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local Window = Fluent:CreateWindow({
	Title = "Dandy's World Script",
	SubTitle = "by Tapetenputzer",
	TabWidth = 160,
	Size = UDim2.fromOffset(580,460),
	Acrylic = true,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
	ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
	Movement = Window:AddTab({ Title = "Movement", Icon = "run" }),
	Visuals = Window:AddTab({ Title = "Visuals", Icon = "sun" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

---------------------
-- ESP SECTION
---------------------
local ESPSection = Tabs.ESP:AddSection("ESP Toggles")
local ColorSection = Tabs.ESP:AddSection("ESP Colors")

local monsterESPActive = false
local monsterESPColor = Color3.fromRGB(255,0,0)
local monsterNametagColor = Color3.new(1,1,1)
local monsterESPLoop = nil
local function processMonster(model)
	if not model or not model:IsA("Model") then return end
	local lowerName = string.lower(model.Name)
	if not lowerName:find("monster") then return end
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
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0,100,0,40)
		bb.AlwaysOnTop = true
		local tl = Instance.new("TextLabel", bb)
		tl.Size = UDim2.new(1,0,1,0)
		tl.BackgroundTransparency = 1
		tl.Text = model.Name
		tl.TextColor3 = monsterNametagColor
		tl.TextScaled = true
		tl.Font = Enum.Font.SourceSansBold
		bb.Name = "MonsterNametag"
		bb.Adornee = head
		bb.Parent = head
	end
end
local function monsterESPLoop()
	while monsterESPActive do
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") then
				processMonster(obj)
			end
		end
		task.wait(2)
	end
end
local function removeMonsterESP()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			if obj:FindFirstChild("MonsterHighlight") then obj.MonsterHighlight:Destroy() end
		end
		if obj:IsA("BasePart") then
			if obj:FindFirstChild("MonsterNametag") then obj.MonsterNametag:Destroy() end
		end
	end
end
local function toggleMonsterESP(state)
	monsterESPActive = state
	if state then
		monsterESPLoop = task.spawn(monsterESPLoop)
	else
		if monsterESPLoop then task.cancel(monsterESPLoop) end
		task.delay(0.5, removeMonsterESP)
	end
end
ESPSection:AddToggle("MonsterESPToggle", { Title = "Monster ESP", Default = false, Callback = toggleMonsterESP })
ColorSection:AddColorpicker("MonsterHighlightColor", { Title = "Monster Highlight", Default = monsterESPColor, Callback = function(c) monsterESPColor = c end })
ColorSection:AddColorpicker("MonsterNametagColor", { Title = "Monster Nametag", Default = monsterNametagColor, Callback = function(c) monsterNametagColor = c end })

local machineESPActive = false
local machineESPColor = Color3.fromRGB(0,255,0)
local machineNametagColor = Color3.new(1,1,1)
local machineESPLoop = nil
local function processMachine(model)
	if not model or not model:IsA("Model") then return end
	local lowerName = string.lower(model.Name)
	if not lowerName:find("generator") then return end
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
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0,100,0,40)
		bb.AlwaysOnTop = true
		local tl = Instance.new("TextLabel", bb)
		tl.Size = UDim2.new(1,0,1,0)
		tl.BackgroundTransparency = 1
		tl.Text = model.Name
		tl.TextColor3 = machineNametagColor
		tl.TextScaled = true
		tl.Font = Enum.Font.SourceSansBold
		bb.Name = "MachineNametag"
		bb.Adornee = target
		bb.Parent = target
	end
end
local function machineESPLoop()
	while machineESPActive do
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") then
				processMachine(obj)
			end
		end
		task.wait(2)
	end
end
local function removeMachineESP()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			if obj:FindFirstChild("MachineHighlight") then obj.MachineHighlight:Destroy() end
		end
		if obj:IsA("BasePart") then
			if obj:FindFirstChild("MachineNametag") then obj.MachineNametag:Destroy() end
		end
	end
end
local function toggleMachineESP(state)
	machineESPActive = state
	if state then
		machineESPLoop = task.spawn(machineESPLoop)
	else
		if machineESPLoop then task.cancel(machineESPLoop) end
		task.delay(0.5, removeMachineESP)
	end
end
ESPSection:AddToggle("MachineESPToggle", { Title = "Machine ESP", Default = false, Callback = toggleMachineESP })
ColorSection:AddColorpicker("MachineHighlightColor", { Title = "Machine Highlight", Default = machineESPColor, Callback = function(c) machineESPColor = c end })
ColorSection:AddColorpicker("MachineNametagColor", { Title = "Machine Nametag", Default = machineNametagColor, Callback = function(c) machineNametagColor = c end })

local itemESPActive = false
local itemNametagColor = Color3.new(1,1,1)
local itemESPLoop = nil
local function isInItems(obj)
	local cur = obj.Parent
	while cur do
		if string.find(string.lower(cur.Name), "items") then return true end
		cur = cur.Parent
	end
	return false
end
local function getItemModel(part)
	local cur = part
	while cur do
		if cur:IsA("Model") and string.lower(cur.Name) ~= "items" then return cur end
		cur = cur.Parent
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
local function createItemNametag(part, dispName)
	if not part or not part:IsA("BasePart") then return end
	if part:FindFirstChild("ItemNametag") then return end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0,100,0,40)
	bb.AlwaysOnTop = true
	local tl = Instance.new("TextLabel", bb)
	tl.Size = UDim2.new(1,0,1,0)
	tl.BackgroundTransparency = 1
	tl.Text = dispName or part.Name
	tl.TextColor3 = itemNametagColor
	tl.TextScaled = true
	tl.Font = Enum.Font.SourceSansBold
	bb.Name = "ItemNametag"
	bb.Adornee = part
	bb.Parent = part
end
local function processItem(part)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then return end
	if not isInItems(part) then return end
	local model = getItemModel(part) or part
	if model:FindFirstChild("ItemNametag") then return end
	local dp = getDisplayPart(model) or part
	createItemNametag(dp, model.Name)
end
local function itemESPLoop()
	while itemESPActive do
		for _, obj in ipairs(workspace:GetDescendants()) do
			processItem(obj)
		end
		task.wait(2)
	end
end
local function removeItemESP()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj:FindFirstChild("ItemNametag") then obj.ItemNametag:Destroy() end
		end
		if obj:IsA("Model") then
			local tag = obj:FindFirstChild("ItemNametag")
			if tag then tag:Destroy() end
		end
	end
end
local function toggleItemESP(state)
	itemESPActive = state
	if state then
		itemESPLoop = task.spawn(itemESPLoop)
	else
		if itemESPLoop then task.cancel(itemESPLoop) end
		task.delay(0.5, removeItemESP)
	end
end
ESPSection:AddToggle("ItemESPToggle", { Title = "Item ESP", Default = false, Callback = toggleItemESP })
ColorSection:AddColorpicker("ItemNametagColor", { Title = "Item Nametag", Default = itemNametagColor, Callback = function(c) itemNametagColor = c end })

local playerESPActive = false
local playerESPColor = Color3.fromRGB(0,0,255)
local playerNametagColor = Color3.new(1,1,1)
local playerESPLoop = nil
local function processPlayer(model)
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
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0,100,0,40)
		bb.AlwaysOnTop = true
		local tl = Instance.new("TextLabel", bb)
		tl.Size = UDim2.new(1,0,1,0)
		tl.BackgroundTransparency = 1
		tl.Text = model.Name
		tl.TextColor3 = playerNametagColor
		tl.TextScaled = true
		tl.Font = Enum.Font.SourceSansBold
		bb.Name = "PlayerNametag"
		bb.Adornee = target
		bb.Parent = target
	end
end
local function playerESPLoopFunc()
	while playerESPActive do
		for _, obj in ipairs(workspace.InGamePlayers:GetChildren()) do
			if obj:IsA("Model") then
				processPlayer(obj)
			end
		end
		task.wait(2)
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
		playerESPLoop = task.spawn(playerESPLoopFunc)
	else
		if playerESPLoop then task.cancel(playerESPLoop) end
		task.delay(0.5, removePlayerESP)
	end
end
ESPSection:AddToggle("PlayerESPToggle", { Title = "Player ESP", Default = false, Callback = togglePlayerESP })
ColorSection:AddColorpicker("PlayerHighlightColor", { Title = "Player Highlight", Default = playerESPColor, Callback = function(c) playerESPColor = c end })
ColorSection:AddColorpicker("PlayerNametagColor", { Title = "Player Nametag", Default = playerNametagColor, Callback = function(c) playerNametagColor = c end })

---------------------
-- MOVEMENT / AUTO ITEMS
---------------------
local MovementSection = Tabs.Movement:AddSection("Movement & Items")
local speedLoopActive = false
local speedLoopThread = nil
local currentSpeed = 16
local function enforceSpeed()
	while speedLoopActive do
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.WalkSpeed = currentSpeed
		end
		task.wait(1)
	end
end
local SpeedInput = Tabs.Movement:AddInput("SpeedInput", { Title = "Set Walk Speed", Placeholder = "e.g. 30", Numeric = true })
Tabs.Movement:AddButton({ Title = "Apply Speed", Callback = function()
	local s = tonumber(SpeedInput.Value)
	if s and s > 0 then
		currentSpeed = s
		speedLoopActive = true
		if speedLoopThread then task.cancel(speedLoopThread) end
		speedLoopThread = task.spawn(enforceSpeed)
	end
end})
Tabs.Movement:AddButton({ Title = "Reset Speed", Callback = function()
	currentSpeed = 16
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = 16
	end
	speedLoopActive = false
	if speedLoopThread then task.cancel(speedLoopThread) end
end})

local autoPickupActive = false
local autoPickupThread = nil
local function autoPickupLoop()
	while autoPickupActive do
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and (string.lower(obj.Name):find("item") or string.lower(obj.Name):find("capsule")) then
				local char = workspace.InGamePlayers:FindFirstChild(player.Name)
				if char and char:FindFirstChild("HumanoidRootPart") then
					char.HumanoidRootPart.CFrame = obj.CFrame + Vector3.new(0,2,0)
					task.wait(0.3)
				end
			end
		end
		task.wait(3)
	end
end
Tabs.Movement:AddToggle("AutoPickupToggle", { Title = "Auto Item Pickup", Default = false, Callback = function(state)
	autoPickupActive = state
	if state then
		if autoPickupThread then task.cancel(autoPickupThread) end
		autoPickupThread = task.spawn(autoPickupLoop)
	else
		if autoPickupThread then task.cancel(autoPickupThread) end
		autoPickupThread = nil
	end
end})

local autoItemUseActive = false
local autoItemUseThread = nil
local function autoItemUseLoop()
	while autoItemUseActive do
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") and obj.Parent and string.lower(obj.Parent.Name):find("use") then
				-- Versuche den ProximityPrompt zu feuern
				pcall(function() fireproximityprompt(obj) end)
			end
		end
		task.wait(2)
	end
end
Tabs.Movement:AddToggle("AutoItemUseToggle", { Title = "Auto Item Use", Default = false, Callback = function(state)
	autoItemUseActive = state
	if state then
		if autoItemUseThread then task.cancel(autoItemUseThread) end
		autoItemUseThread = task.spawn(autoItemUseLoop)
	else
		if autoItemUseThread then task.cancel(autoItemUseThread) end
		autoItemUseThread = nil
	end
end})

Tabs.Movement:AddButton({ Title = "Pickup Research Capsules", Callback = function()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and string.lower(obj.Name):find("researchcapsule") then
			local char = workspace.InGamePlayers:FindFirstChild(player.Name)
			if char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.CFrame = obj.CFrame + Vector3.new(0,2,0)
				if obj:FindFirstChildOfClass("ProximityPrompt") then
					pcall(function() fireproximityprompt(obj:FindFirstChildOfClass("ProximityPrompt")) end)
				end
				task.wait(0.2)
			end
		end
	end
end})

---------------------
-- VISUALS
---------------------
local VisualsSection = Tabs.Visuals:AddSection("Visual Options")
local fullbrightActive = false
local fullbrightThread = nil
local function fullbrightLoop()
	while fullbrightActive do
		Lighting.Ambient = Color3.new(1,1,1)
		Lighting.Brightness = 2
		Lighting.ClockTime = 12
		Lighting.FogEnd = 1e9
		Lighting.GlobalShadows = false
		task.wait(1)
	end
end
VisualsSection:AddToggle("FullbrightToggle", { Title = "Fullbright", Default = false, Callback = function(state)
	fullbrightActive = state
	if state then
		if fullbrightThread then task.cancel(fullbrightThread) end
		fullbrightThread = task.spawn(fullbrightLoop)
	else
		if fullbrightThread then task.cancel(fullbrightThread) end
		Lighting.Ambient = Color3.new(0,0,0)
		Lighting.Brightness = 1
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1000
		Lighting.GlobalShadows = true
	end
end})

---------------------
-- SETTINGS
---------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/dandy-world")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)
Fluent:Notify({ Title = "Dandy's World", Content = "Script Loaded!", Duration = 8 })
print("Script successfully loaded!")
