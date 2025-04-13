-- =============== FLUENT / LIBRARY SETUP ===============
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Hilfsfunktion, um Movement wieder zu aktivieren (Entankern, PlatformStand deaktivieren)
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

-- Acrylic false, damit kein Blur erzeugt wird
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
	Functions = Window:AddTab({ Title = "Functions", Icon = "zap" }),
	Info      = Window:AddTab({ Title = "Info",      Icon = "heart" }),
	Settings  = Window:AddTab({ Title = "Settings",  Icon = "settings" })
}

-- =============== PLAYER / FLY / SPEED / ANTI AFK ===============
local currentSpeed = 16
local flySpeed = 50
local flyBodyVelocity, flyBodyGyro, flyConnection

---------------------------------------------------------
-- Hilfsfunktionen
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
-- AUTO REVIVE (Neu):
-- Bei Aktivierung sucht der Code im Ordner Workspace.PlayerHeads nach einem Objekt namens "Model".
-- Wird es gefunden, wird der Spieler-Charakter (HumanoidRootPart) an den Zielpunkt teleportiert,
-- der im ReviveChecker unter Workspace.Spawn Area.Important.ReviveChecker.Hitbox liegt.
-- Zusätzlich wird ein Y-Offset von 5 Einheiten hinzugefügt (also _über_ dem Ziel).
-------------------------------
local autoReviveActive = false
local autoReviveConnection

local function AutoReviveCallback()
	local playerHeads = Workspace:FindFirstChild("PlayerHeads")
	if not playerHeads then return end
	local modelObj = playerHeads:FindFirstChild("Model")
	if modelObj then
		local spawnArea = Workspace:FindFirstChild("Spawn Area")
		if not spawnArea then return end
		local important = spawnArea:FindFirstChild("Important")
		if not important then return end
		local reviveChecker = important:FindFirstChild("ReviveChecker")
		if not reviveChecker then return end
		local hitbox = reviveChecker:FindFirstChild("Hitbox")
		if hitbox and hitbox:IsA("BasePart") and LocalPlayer.Character then
			local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if root then
				-- Teleportiere den Charakter etwas über dem Hitbox (Y-Offset von 5)
				root.CFrame = hitbox.CFrame * CFrame.new(0,5,0)
				print("Auto Revive: Teleported above the ReviveChecker-Hitbox!")
			end
		else
			warn("Hitbox im ReviveChecker nicht gefunden oder ungültig!")
		end
	end
end

FunctionsSection:AddToggle("AutoReviveToggle", { Title = "Auto Revive", Default = false })
	:OnChanged(function(state)
		if state then
			autoReviveConnection = RunService.RenderStepped:Connect(function()
				AutoReviveCallback()
			end)
			print("Auto Revive aktiviert.")
		else
			if autoReviveConnection then
				autoReviveConnection:Disconnect()
				autoReviveConnection = nil
			end
			print("Auto Revive deaktiviert.")
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
		if not targetPart then
			warn("Kein Part im QuotaChecker Model gefunden!")
			return
		end

		local spawnedLootFolder = Workspace:FindFirstChild("Spawned Loot")
		if spawnedLootFolder then
			for _, item in ipairs(spawnedLootFolder:GetChildren()) do
				if item:IsA("Model") then
					local itemPrimary = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
					if itemPrimary then
						local offset = CFrame.new(math.random(-3,3), math.random(5,8), math.random(-3,3))
						itemPrimary.CFrame = targetPart.CFrame * offset
					end
				elseif item:IsA("BasePart") then
					local offset = CFrame.new(math.random(-3,3), math.random(5,8), math.random(-3,3))
					item.CFrame = targetPart.CFrame * offset
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
	if not targetPart then
		warn("Kein Ziel-Part im PlayerSpawn gefunden!")
		return
	end
	if LocalPlayer.Character then
		local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = targetPart.CFrame
			print("Teleported to Ship (PlayerSpawn)!")
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
-- Teleportiert alle Objekte aus "Shop Items" (inklusive Unterordner "Consumable", "Items" und "Weapons")
-- zum Ziel: Workspace.Store.Store.ItemChecker.Hitbox, mit einem kleinen Zufallsoffset (inkl. Y-Offset, sodass sie etwas darüber spawnen).
local function AutoShopping()
	local shopItems = Workspace:FindFirstChild("Shop Items")
	if not shopItems then
		warn("Ordner 'Shop Items' nicht gefunden!")
		return
	end
	local targetContainer = Workspace:FindFirstChild("Store")
	if not targetContainer then
		warn("Ordner 'Store' nicht gefunden!")
		return
	end
	local storeStore = targetContainer:FindFirstChild("Store")
	if not storeStore then
		warn("Unterordner 'Store' im 'Store' nicht vorhanden!")
		return
	end
	local itemChecker = storeStore:FindFirstChild("ItemChecker")
	if not itemChecker then
		warn("ItemChecker nicht gefunden!")
		return
	end
	local hitbox = itemChecker:FindFirstChild("Hitbox")
	if not hitbox or not hitbox:IsA("BasePart") then
		warn("Hitbox im ItemChecker nicht gefunden oder ungültig!")
		return
	end
	local targetCF = hitbox.CFrame

	local function getRandomOffset()
		-- Hier wird ein zufälliger Offset erzeugt, mit Y-Werten zwischen 5 und 8,
		-- sodass die Items etwas über dem Ziel spawnen.
		return CFrame.new(math.random(-3,3), math.random(5,8), math.random(-3,3))
	end

	local function teleportFolder(folder)
		for _, obj in ipairs(folder:GetChildren()) do
			if obj:IsA("Folder") then
				teleportFolder(obj)
			else
				if obj:IsA("BasePart") then
					obj.CFrame = targetCF * getRandomOffset()
				elseif obj:IsA("Model") then
					local base = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
					if base then
						base.CFrame = targetCF * getRandomOffset()
					end
				end
			end
		end
	end

	teleportFolder(shopItems)
	print("Auto Shopping: Alle Shop Items wurden zum ItemChecker-Hitbox (mit Offset) teleportiert!")
end

FunctionsSection:AddButton({
	Title = "Auto Shopping",
	Callback = function()
		AutoShopping()
	end
})

---------------------------------------------------------
-- ESP TAB – Sortiert nach Funktion
---------------------------------------------------------
local espActive = false
local espColor = Color3.fromRGB(255,255,255)

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
			if highlight then highlight:Destroy() end
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
			if tag then tag:Destroy() end
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
					if lbl then lbl.TextColor3 = espColor end
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

local espSection = Tabs.ESP:AddSection("Spieler ESP")
espSection:AddToggle("ESPToggle", { Title = "Spieler ESP (Chams)", Default = false })
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

espSection:AddColorpicker("ESPColor", { Title = "Spieler Farbe", Default = espColor })
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

---------------------------------------------------------
-- Tab: Info
---------------------------------------------------------
local InfoSection = Tabs.Info:AddSection("Info")
InfoSection:AddParagraph({
	Title = "Info",
	Content = "Made by Tapetenputzer\nDiscord: tapetenputzer"
})

---------------------------------------------------------
-- SETTINGS, SPEICHERN, LADEN
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

Fluent:Notify({
	Title = "ERPO Script",
	Content = "Script Loaded!",
	Duration = 5
})
Window:SelectTab(1)
