local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Erstelle ein neues Fenster
local Window = Fluent:CreateWindow({
    Title = "Info",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(400, 300),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Füge einen einzelnen Tab hinzu, der "Info" heißt
local InfoTab = Window:AddTab({ Title = "Info", Icon = "heart" })

-- Füge einen Paragraph in den Info-Tab ein
InfoTab:AddParagraph({
    Title = "Info",
    Content = "tp get the updated script join my discord server https://discord.gg/2xDHnGg6cJ"
})

-- Wähle den Info-Tab aus
Window:SelectTab(1)
