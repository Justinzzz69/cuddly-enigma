local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local Window = Fluent:CreateWindow({
	Title = "Banana Eats Script",
	SubTitle = "by Tapetenputzer",
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

local nametagWidth = 150
local nametagHeight = 50
local nametagOffsetY = 3
local nametagTextSize = 16
local labelWidth = 150
local labelHeight = 50
local labelOffsetY = 3
local labelTextSize = 16

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
local puzzleNumberEspColor = Color3.fromRGB(255, 255, 255)
local puzzleNumbers = {["23"] = true, ["34"] = true, ["31"] = true}
local puzzleEspActive = false
local puzzleEspLoop = nil
local puzzleEspColor = Color3.fromRGB(0, 255, 0)
local noFogActive = false
local noFogLoop = nil

local flyActive = false
local flySpeed = 50
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnection = nil

local antiAfkConnection = nil
local function enableAntiAfk()
	if antiAfkConnection then return end
	antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end)
end
local function disableAntiAfk()
	if antiAfkConnection then
		antiAfkConnection:Disconnect()
		antiAfkConnection = nil
	end
end

local xrayActive = false
local xrayTransparency = 0.5
local function enableXray()
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and not part:IsDescendantOf(Players.LocalPlayer.Character) then
			part.LocalTransparencyModifier = xrayTransparency
		end
	end
end
local function disableXray()
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and not part:IsDescendantOf(Players.LocalPlayer.Character) then
			part.LocalTransparencyModifier = 0
		end
	end
end
local function xrayLoopFunction()
	while xrayActive do
		enableXray()
		wait(1)
	end
end

local bloomActive = false
local bloomEffect = nil
local bloomIntensity = 1
local function enableBloom()
	if not game.Lighting:FindFirstChild("BloomEffect") then
		bloomEffect = Instance.new("BloomEffect")
		bloomEffect.Parent = game.Lighting
	else
		bloomEffect = game.Lighting:FindFirstChild("BloomEffect")
	end
	bloomEffect.Intensity = bloomIntensity
end
local function disableBloom()
	if bloomEffect then
		bloomEffect:Destroy()
		bloomEffect = nil
	end
end

local ccActive = false
local ccEffect = nil
local ccBrightness = 0
local ccContrast = 0
local ccSaturation = 1
local function enableColorCorrection()
	if not game.Lighting:FindFirstChild("ColorCorrectionEffect") then
		ccEffect = Instance.new("ColorCorrectionEffect")
		ccEffect.Parent = game.Lighting
	else
		ccEffect = game.Lighting:FindFirstChild("ColorCorrectionEffect")
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

local dofActive = false
local dofEffect = nil
local dofFocalDistance = 15
local dofInFocusRadius = 20
local function enableDOF()
	if not game.Lighting:FindFirstChild("DepthOfFieldEffect") then
		dofEffect = Instance.new("DepthOfFieldEffect")
		dofEffect.Parent = game.Lighting
	else
		dofEffect = game.Lighting:FindFirstChild("DepthOfFieldEffect")
	end
	dofEffect.FarIntensity = 0
	dofEffect.FocusDistance = dofFocalDistance
	dofEffect.InFocusRadius = dofInFocusRadius
end
local function disableDOF()
	if dofEffect then
		dofEffect:Destroy()
		dofEffect = nil
	end
end

local sunRaysActive = false
local sunRaysEffect = nil
local sunRaysIntensity = 0.3
local function enableSunRays()
	if not game.Lighting:FindFirstChild("SunRaysEffect") then
		sunRaysEffect = Instance.new("SunRaysEffect")
		sunRaysEffect.Parent = game.Lighting
	else
		sunRaysEffect = game.Lighting:FindFirstChild("SunRaysEffect")
	end
	sunRaysEffect.Intensity = sunRaysIntensity
end
local function disableSunRays()
	if sunRaysEffect then
		sunRaysEffect:Destroy()
		sunRaysEffect = nil
	end
end

local function createBillboard(text, isNametag)
	local billboard = Instance.new("BillboardGui")
	if isNametag then
		billboard.Size = UDim2.new(0, nametagWidth, 0, nametagHeight)
		billboard.StudsOffset = Vector3.new(0, nametagOffsetY, 0)
	else
		billboard.Size = UDim2.new(0, labelWidth, 0, labelHeight)
		billboard.StudsOffset = Vector3.new(0, labelOffsetY, 0)
	end
	billboard.AlwaysOnTop = true
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextScaled = false
	textLabel.Font = Enum.Font.GothamSemibold
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.3
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	if isNametag then
		textLabel.TextSize = nametagTextSize
	else
		textLabel.TextSize = labelTextSize
	end
	textLabel.Parent = billboard
	return billboard
end

local function removeCakeEsp()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj:FindFirstChild("CakeESP") then obj.CakeESP:Destroy() end
			if obj:FindFirstChild("CakeLabel") then obj.CakeLabel:Destroy() end
		end
	end
end
local function removeCoinEsp()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj:FindFirstChild("CoinESP") then obj.CoinESP:Destroy() end
			if obj:FindFirstChild("CoinLabel") then obj.CoinLabel:Destroy() end
		end
	end
end
local function removeChams()
	for _, player in pairs(Players:GetPlayers()) do
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
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("Head") then
			local tag = player.Character.Head:FindFirstChild("Nametag")
			if tag then tag:Destroy() end
		end
	end
end
local function removeValveEsp()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj:FindFirstChild("ValveESP") then obj.ValveESP:Destroy() end
			if obj:FindFirstChild("ValveLabel") then obj.ValveLabel:Destroy() end
		end
	end
	labeledValves = {}
end
local function removePuzzleNumberEsp()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Parent and obj.Parent.Name == "Buttons" and puzzleNumbers[obj.Name] then
			if obj:FindFirstChild("PuzzleNumberESP") then obj.PuzzleNumberESP:Destroy() end
			if obj:FindFirstChild("PuzzleNumberLabel") then obj.PuzzleNumberLabel:Destroy() end
		end
	end
end
local function removePuzzleEsp()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj:FindFirstChild("PuzzleLabel") then obj.PuzzleLabel:Destroy() end
		end
	end
end

local function checkCakeEsp(obj)
	if not obj:IsA("BasePart") then return end
	if (obj.Parent and obj.Parent.Name == "Cake" and tonumber(obj.Name)) or (obj.Parent and obj.Parent.Name == "CakePlate" and obj.Name == "Plate") then
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
				if num and num >= 1 and num <= 6 then labelText = "Main Plate" end
			end
			local billboard = createBillboard(labelText, false)
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
		wait(2)
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
			local billboard = createBillboard("Coin", false)
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
		wait(0.5)
	end
end
local function checkChams()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer and player.Character then
			local sameTeam = (player.TeamColor == Players.LocalPlayer.TeamColor)
			local color = sameTeam and teamChamColor or enemyChamColor
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
						cham.Transparency = 0.4
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
		wait(2)
	end
end
local function checkNametags()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local sameTeam = (player.TeamColor == Players.LocalPlayer.TeamColor)
			local color = sameTeam and teamChamColor or enemyChamColor
			local head = player.Character.Head
			local existingTag = head:FindFirstChild("Nametag")
			if not existingTag then
				local billboard = createBillboard(player.Name, true)
				billboard.Name = "Nametag"
				billboard.Parent = head
			else
				local txt = existingTag:FindFirstChildOfClass("TextLabel")
				if txt then
					txt.TextColor3 = color
				end
			end
		end
	end
end
local function nametagLoopFunction()
	while nametagActive do
		checkNametags()
		wait(2)
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
	if labeledValves[parent] then return end
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
		local billboard = createBillboard("Valve", false)
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
		wait(2)
	end
end
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
			local billboard = createBillboard("Cube Puzzle", false)
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
		wait(2)
	end
end
local function checkCodePuzzleEsp(obj)
	if not obj:IsA("BasePart") then return end
	local fullname = obj:GetFullName():lower()
	if fullname:find("combinationpuzzle") then
		if not obj:FindFirstChild("PuzzleLabel") then
			local billboard = createBillboard("Code Puzzle", false)
			billboard.Name = "PuzzleLabel"
			billboard.Parent = obj
		end
	end
end
local function codePuzzleEspLoopFunction()
	while puzzleEspActive do
		for _, obj in pairs(workspace:GetDescendants()) do
			checkCodePuzzleEsp(obj)
		end
		wait(2)
	end
end
local function noFogLoopFunction()
	while noFogActive do
		game.Lighting.FogStart = 0
		game.Lighting.FogEnd = 1e9
		wait(0.5)
	end
end

local function enableFly()
	local character = Players.LocalPlayer.Character
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

local ESPSection = Tabs.ESP:AddSection("ESP Toggles")
local ESPColorsSection = Tabs.ESP:AddSection("ESP Colors")
ESPSection:AddToggle("CakeEspToggle", { Title = "Cake ESP", Default = false, Callback = function(state)
	cakeEspActive = state
	if state then
		if cakeEspLoop then task.cancel(cakeEspLoop) end
		cakeEspLoop = task.spawn(cakeEspLoopFunction)
	else
		if cakeEspLoop then task.cancel(cakeEspLoop) end
		cakeEspLoop = nil
		removeCakeEsp()
	end
end})
ESPSection:AddToggle("CoinEspToggle", { Title = "Coin ESP", Default = false, Callback = function(state)
	coinEspActive = state
	if state then
		if coinEspLoop then task.cancel(coinEspLoop) end
		coinEspLoop = task.spawn(coinEspLoopFunction)
	else
		if coinEspLoop then task.cancel(coinEspLoop) end
		coinEspLoop = nil
		removeCoinEsp()
	end
end})
ESPSection:AddToggle("ChamsToggle", { Title = "Player Chams", Default = false, Callback = function(state)
	chamsActive = state
	if state then
		if chamsLoop then task.cancel(chamsLoop) end
		chamsLoop = task.spawn(chamsLoopFunction)
	else
		if chamsLoop then task.cancel(chamsLoop) end
		chamsLoop = nil
		removeChams()
	end
end})
ESPSection:AddToggle("NametagToggle", { Title = "Nametags", Default = false, Callback = function(state)
	nametagActive = state
	if state then
		if nametagLoop then task.cancel(nametagLoop) end
		nametagLoop = task.spawn(nametagLoopFunction)
	else
		if nametagLoop then task.cancel(nametagLoop) end
		nametagLoop = nil
		removeNametags()
	end
end})
ESPSection:AddToggle("ValveEspToggle", { Title = "Valve ESP", Default = false, Callback = function(state)
	valveEspActive = state
	if state then
		if valveEspLoop then task.cancel(valveEspLoop) end
		valveEspLoop = task.spawn(valveEspLoopFunction)
	else
		if valveEspLoop then task.cancel(valveEspLoop) end
		valveEspLoop = nil
		removeValveEsp()
	end
end})
ESPSection:AddToggle("CubePuzzleEspToggle", { Title = "Cube Puzzle ESP", Default = false, Callback = function(state)
	puzzleNumberEspActive = state
	if state then
		if puzzleNumberEspLoop then task.cancel(puzzleNumberEspLoop) end
		puzzleNumberEspLoop = task.spawn(puzzleNumberEspLoopFunction)
	else
		if puzzleNumberEspLoop then task.cancel(puzzleNumberEspLoop) end
		puzzleNumberEspLoop = nil
		removePuzzleNumberEsp()
	end
end})
ESPSection:AddToggle("CodePuzzleEspToggle", { Title = "Code Puzzle ESP", Default = false, Callback = function(state)
	puzzleEspActive = state
	if state then
		if puzzleEspLoop then task.cancel(puzzleEspLoop) end
		puzzleEspLoop = task.spawn(codePuzzleEspLoopFunction)
	else
		if puzzleEspLoop then task.cancel(puzzleEspLoop) end
		puzzleEspLoop = nil
		removePuzzleEsp()
	end
end})
ESPColorsSection:AddColorpicker("CakeEspColor", { Title = "Cake ESP", Default = cakeEspColor, Callback = function(color) cakeEspColor = color end})
ESPColorsSection:AddColorpicker("CoinEspColor", { Title = "Coin ESP", Default = coinEspColor, Callback = function(color) coinEspColor = color end})
ESPColorsSection:AddColorpicker("EnemyChamsColor", { Title = "Enemy Chams", Default = enemyChamColor, Callback = function(color) enemyChamColor = color end})
ESPColorsSection:AddColorpicker("TeamChamsColor", { Title = "Team Chams", Default = teamChamColor, Callback = function(color) teamChamColor = color end})
ESPColorsSection:AddColorpicker("ValveEspColor", { Title = "Valve ESP", Default = valveEspColor, Callback = function(color) valveEspColor = color end})
ESPColorsSection:AddColorpicker("PuzzleNumberEspColor", { Title = "Cube Puzzle ESP", Default = puzzleNumberEspColor, Callback = function(color) puzzleNumberEspColor = color end})
ESPColorsSection:AddColorpicker("PuzzleObjectEspColor", { Title = "Code Puzzle ESP", Default = puzzleEspColor, Callback = function(color) puzzleEspColor = color end})

local PlayerSpeedInput = Tabs.Player:AddInput("SpeedInput", { Title = "Set Speed", Placeholder = "Default = 16", Numeric = true })
Tabs.Player:AddButton({ Title = "Set Player Speed", Description = "Set speed of Player", Callback = function()
	local speed = tonumber(PlayerSpeedInput.Value)
	if speed and speed > 0 then
		currentSpeed = speed
		local char = Players.LocalPlayer.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.WalkSpeed = currentSpeed
		end
		if speedLoop then task.cancel(speedLoop) end
		speedLoop = task.spawn(function()
			while true do
				local c = Players.LocalPlayer.Character
				if c and c:FindFirstChild("Humanoid") then
					c.Humanoid.WalkSpeed = currentSpeed
				end
				wait(2)
			end
		end)
	end
end})
Tabs.Player:AddButton({ Title = "Reset Speed", Description = "Sets the speed to 16", Callback = function()
	currentSpeed = 16
	local char = Players.LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = currentSpeed
	end
	if speedLoop then
		task.cancel(speedLoop)
		speedLoop = nil
	end
end})
Tabs.Player:AddToggle("FlyToggle", { Title = "Fly (Local)", Default = false, Callback = function(state)
	if state then enableFly() else disableFly() end
end})
local FlySpeedInput = Tabs.Player:AddInput("FlySpeedInput", { Title = "Set Fly Speed", Placeholder = "Default = 50", Numeric = true })
Tabs.Player:AddButton({ Title = "Set Fly Speed", Description = "Set fly speed of Player", Callback = function()
	local fSpeed = tonumber(FlySpeedInput.Value)
	if fSpeed and fSpeed > 0 then
		flySpeed = fSpeed
	end
end})
Tabs.Player:AddToggle("AntiAFKToggle", { Title = "Anti-AFK", Default = false, Callback = function(state)
	if state then enableAntiAfk() else disableAntiAfk() end
end})

local VisualSection = Tabs.Visual
VisualSection:AddToggle("FullbrightToggle", { Title = "Fullbright", Default = false, Callback = function(state)
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
end})
VisualSection:AddToggle("NoFogToggle", { Title = "No Fog", Default = false, Callback = function(state)
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
end})
VisualSection:AddToggle("XrayToggle", { Title = "Xray Mode", Default = false, Callback = function(state)
	xrayActive = state
	if state then
		task.spawn(xrayLoopFunction)
	else
		disableXray()
	end
end})
VisualSection:AddToggle("BloomToggle", { Title = "Bloom", Default = false, Callback = function(state)
	bloomActive = state
	if state then
		enableBloom()
	else
		disableBloom()
	end
end})
VisualSection:AddToggle("ColorCorrectionToggle", { Title = "Color Correction", Default = false, Callback = function(state)
	ccActive = state
	if state then
		enableColorCorrection()
	else
		disableColorCorrection()
	end
end})
VisualSection:AddToggle("DOFToggle", { Title = "Depth Of Field", Default = false, Callback = function(state)
	dofActive = state
	if state then
		enableDOF()
	else
		disableDOF()
	end
end})
VisualSection:AddToggle("SunRaysToggle", { Title = "SunRays", Default = false, Callback = function(state)
	sunRaysActive = state
	if state then
		enableSunRays()
	else
		disableSunRays()
	end
end})

local AutoSection = Tabs.Player:AddSection("Auto Features")
local autoDeletePeelsActive = false
local autoDeletePeelsThread = nil
local autoCollectTokensActive = false
local autoCollectTokensThread = nil
local autoDeleteLockersActive = false
local autoDeleteLockersThread = nil
local antiKickConnection = nil
local function startAntiKick()
	if not antiKickConnection then
		antiKickConnection = Players.LocalPlayer.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0, 0))
		end)
	end
end
local function stopAntiKick()
	if antiKickConnection then
		antiKickConnection:Disconnect()
		antiKickConnection = nil
	end
end
local function autoDeletePeelsFunc()
	while autoDeletePeelsActive do
		local peelsRoot = workspace:FindFirstChild("GameProperties") and workspace.GameProperties:FindFirstChild("Displays") and workspace.GameProperties.Displays:FindFirstChild("PeelsRoot")
		if peelsRoot then
			for _, obj in ipairs(peelsRoot:GetChildren()) do
				if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Folder") then
					obj:Destroy()
				end
			end
		end
		task.wait(2)
	end
end
local function autoCollectTokensFunc()
	while autoCollectTokensActive do
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj.Name:lower():find("token") and obj:IsA("BasePart") then
				if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					Players.LocalPlayer.Character:MoveTo(obj.Position + Vector3.new(0, 2, 0))
					task.wait(0.5)
				end
			end
		end
		task.wait(2)
	end
end
local function autoDeleteLockersFunc()
	while autoDeleteLockersActive do
		for _, desc in ipairs(workspace:GetDescendants()) do
			if desc.Name:lower():find("locker") then
				desc:Destroy()
			end
		end
		task.wait(3)
	end
end
AutoSection:AddToggle("AutoCollectTokens", { Title = "Auto Collect Tokens", Default = false, Callback = function(state)
	autoCollectTokensActive = state
	if state then
		if autoCollectTokensThread then task.cancel(autoCollectTokensThread) end
		autoCollectTokensThread = task.spawn(autoCollectTokensFunc)
	else
		if autoCollectTokensThread then task.cancel(autoCollectTokensThread) end
		autoCollectTokensThread = nil
	end
end})
AutoSection:AddToggle("AutoDeletePeels", { Title = "Auto Delete Peels", Default = false, Callback = function(state)
	autoDeletePeelsActive = state
	if state then
		if autoDeletePeelsThread then task.cancel(autoDeletePeelsThread) end
		autoDeletePeelsThread = task.spawn(autoDeletePeelsFunc)
	else
		if autoDeletePeelsThread then task.cancel(autoDeletePeelsThread) end
		autoDeletePeelsThread = nil
	end
end})
AutoSection:AddToggle("AutoDeleteLockers", { Title = "Auto Delete Lockers", Default = false, Callback = function(state)
	autoDeleteLockersActive = state
	if state then
		if autoDeleteLockersThread then task.cancel(autoDeleteLockersThread) end
		autoDeleteLockersThread = task.spawn(autoDeleteLockersFunc)
	else
		if autoDeleteLockersThread then task.cancel(autoDeleteLockersThread) end
		autoDeleteLockersThread = nil
	end
end})
AutoSection:AddToggle("AntiKickBypass", { Title = "Anti Kick Bypass", Default = true, Callback = function(state)
	if state then
		startAntiKick()
	else
		stopAntiKick()
	end
end})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
Fluent:Notify({ Title = "Tapetenputzer", Content = "Script Loaded!", Duration = 5 })
Window:SelectTab(1)
