--[[
    ================================================
    Продвинутый GUI с Табами и Функциями
    (Версия v5 - 2D Corner Box ESP)
    ================================================
    - Анимированное меню
    - Кнопка "X" (Закрыть и Выгрузить)
    - Система Вкладок (Visuals, Main)
    - Вкладка Visuals:
        - ESP на таймеры (RemainingTime)
        - ESP на игроков (Имена)
        - ESP на игроков (2D Box - "полоски")
    - Вкладка Main (пустая)
]]

-- --- СЕРВИСЫ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ---
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService") -- [[НОВОЕ]]
local Camera = Workspace.CurrentCamera -- [[НОВОЕ]]

local isOpen = false

-- ESP на таймеры
local isTimerEspActive = false 
local timerEspFolder = nil
local timerEspConnections = {} 

-- ESP на игроков (Имена)
local isPlayerEspActive = false
local playerEspFolder = nil
local playerEspConnections = {}

-- [[ИЗМЕНЕНО]] ESP на игроков (2D Боксы)
local isPlayerBoxEspActive = false
local playerBoxEspFolder = nil -- Теперь это будет ScreenGui
local playerBoxEspConnections = {} -- Для сигналов PlayerRemoving
local boxRenderConnection = nil -- Для сигнала RenderStepped
local activeBoxGuis = {} -- Таблица для хранения активных GUI боксов

-- --- СОЗДАНИЕ GUI ---

-- [Остальная часть GUI (кнопки, фреймы, табы) остается без изменений]
-- ... (пропущено для краткости, код идентичен v4) ...

-- 1. Главный ScreenGui
local MyScreenGui = Instance.new("ScreenGui")
MyScreenGui.Name = "MyMenu_v5"
MyScreenGui.Parent = PlayerGui
MyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 2. Кнопка Открытия (Круглая кнопка "M")
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = MyScreenGui
OpenButton.Size = UDim2.new(0, 60, 0, 60)
OpenButton.Position = UDim2.new(0.02, 0, 0.5, -30)
OpenButton.AnchorPoint = Vector2.new(0, 0.5)
OpenButton.Text = "M"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
OpenButton.Font = Enum.Font.GothamSemibold
OpenButton.TextSize = 24
OpenButton.ZIndex = 3

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = OpenButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(80, 80, 80)
btnStroke.Thickness = 2
btnStroke.Parent = OpenButton

-- 3. Главное Меню (Frame)
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Parent = MyScreenGui
MenuFrame.Size = UDim2.new(0, 400, 0, 350)
MenuFrame.Position = UDim2.new(-0.5, 0, 0.5, 0) 
MenuFrame.AnchorPoint = Vector2.new(0, 0.5)
MenuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MenuFrame.BorderSizePixel = 0
MenuFrame.ClipsDescendants = true
MenuFrame.ZIndex = 2

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = MenuFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(80, 80, 80)
frameStroke.Thickness = 2
frameStroke.Parent = MenuFrame

local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
})
frameGradient.Rotation = 90
frameGradient.Parent = MenuFrame

-- 4. Заголовок Меню
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = MenuFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleLabel.Text = "My Cool Menu"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleLabel

-- 5. Кнопка Закрытия (Крестик)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = MenuFrame
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -10, 0, 7.5)
CloseButton.AnchorPoint = Vector2.new(1, 0)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CloseButton.BackgroundTransparency = 0.5
CloseButton.ZIndex = 3

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseButton

-- Анимация наведения на крестик
local closeHoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local closeHoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    BackgroundTransparency = 0,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
local closeUnhoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.5,
    TextColor3 = Color3.fromRGB(200, 200, 200)
})

CloseButton.MouseEnter:Connect(function() closeHoverTween:Play() end)
CloseButton.MouseLeave:Connect(function() closeUnhoverTween:Play() end)


-- 6. СИСТЕМА ТАБОВ (ВКЛАДОК)

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = MenuFrame
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundTransparency = 1

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MenuFrame
ContentContainer.Size = UDim2.new(1, -20, 1, -85)
ContentContainer.Position = UDim2.new(0, 10, 0, 75)
ContentContainer.BackgroundTransparency = 1

-- Кнопки-табы
local TabButtonVisuals = Instance.new("TextButton")
TabButtonVisuals.Name = "TabVisuals"
TabButtonVisuals.Parent = TabContainer
TabButtonVisuals.Size = UDim2.new(0, 100, 1, 0)
TabButtonVisuals.Position = UDim2.new(0, 10, 0, 0)
TabButtonVisuals.Font = Enum.Font.GothamSemibold
TabButtonVisuals.Text = "Visuals"
TabButtonVisuals.TextSize = 16
TabButtonVisuals.TextColor3 = Color3.fromRGB(255, 255, 255) -- Активный
TabButtonVisuals.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local tabVisualsCorner = Instance.new("UICorner", TabButtonVisuals)
tabVisualsCorner.CornerRadius = UDim.new(0, 6)

-- Таб "Main"
local TabButtonMain = Instance.new("TextButton")
TabButtonMain.Name = "TabMain"
TabButtonMain.Parent = TabContainer
TabButtonMain.Size = UDim2.new(0, 100, 1, 0)
TabButtonMain.Position = UDim2.new(0, 115, 0, 0)
TabButtonMain.Font = Enum.Font.Gotham
TabButtonMain.Text = "Main" 
TabButtonMain.TextSize = 16
TabButtonMain.TextColor3 = Color3.fromRGB(150, 150, 150) -- Неактивный
TabButtonMain.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
local tabMainCorner = Instance.new("UICorner", TabButtonMain)
tabMainCorner.CornerRadius = UDim.new(0, 6)

-- Страницы (содержимое)
local VisualsFrame = Instance.new("Frame")
VisualsFrame.Name = "VisualsFrame"
VisualsFrame.Parent = ContentContainer
VisualsFrame.Size = UDim2.new(1, 0, 1, 0)
VisualsFrame.BackgroundTransparency = 1
VisualsFrame.Visible = true 

-- Фрейм "Main" (пустой)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ContentContainer
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.Visible = false 

-- Логика переключения табов
local tabs = {TabButtonVisuals, TabButtonMain} 
local pages = {VisualsFrame, MainFrame} 

local function switchTab(tabToSelect)
    for i, tab in ipairs(tabs) do
        local page = pages[i]
        if tab == tabToSelect then
            page.Visible = true
            tab.Font = Enum.Font.GothamSemibold
            tab.TextColor3 = Color3.fromRGB(255, 255, 255)
            tab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            page.Visible = false
            tab.Font = Enum.Font.Gotham
            tab.TextColor3 = Color3.fromRGB(150, 150, 150)
            tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        end
    end
end

TabButtonVisuals.MouseButton1Click:Connect(function() switchTab(TabButtonVisuals) end)
TabButtonMain.MouseButton1Click:Connect(function() switchTab(TabButtonMain) end) 

-- --- СЕКЦИЯ: VISUALS (Все ESP) ---

-- Кнопка-переключатель для ESP на таймеры
local timerEspToggle = Instance.new("TextButton")
timerEspToggle.Name = "TimerESPToggle"
timerEspToggle.Parent = VisualsFrame 
timerEspToggle.Size = UDim2.new(1, 0, 0, 30)
timerEspToggle.Position = UDim2.new(0, 0, 0, 10) -- Позиция 1
timerEspToggle.Font = Enum.Font.GothamSemibold
timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
timerEspToggle.TextSize = 16
timerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 
local espToggleCorner = Instance.new("UICorner", timerEspToggle)
espToggleCorner.CornerRadius = UDim.new(0, 8)

-- Кнопка-переключатель для ESP на Игроков (Имена)
local playerEspToggle = Instance.new("TextButton")
playerEspToggle.Name = "PlayerESPToggle"
playerEspToggle.Parent = VisualsFrame 
playerEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerEspToggle.Position = UDim2.new(0, 0, 0, 50) -- Позиция 2
playerEspToggle.Font = Enum.Font.GothamSemibold
playerEspToggle.Text = "ESP (Игроки) [OFF]"
playerEspToggle.TextSize = 16
playerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 
local playerEspToggleCorner = Instance.new("UICorner", playerEspToggle)
playerEspToggleCorner.CornerRadius = UDim.new(0, 8)

-- Кнопка-переключатель для ESP 2D Боксов
local playerBoxEspToggle = Instance.new("TextButton")
playerBoxEspToggle.Name = "PlayerBoxESPToggle"
playerBoxEspToggle.Parent = VisualsFrame 
playerBoxEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerBoxEspToggle.Position = UDim2.new(0, 0, 0, 90) -- Позиция 3
playerBoxEspToggle.Font = Enum.Font.GothamSemibold
playerBoxEspToggle.Text = "ESP (2D Box) [OFF]" -- [[ИЗМЕНЕНО]]
playerBoxEspToggle.TextSize = 16
playerBoxEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 
local playerBoxEspToggleCorner = Instance.new("UICorner", playerBoxEspToggle)
playerBoxEspToggleCorner.CornerRadius = UDim.new(0, 8)


-- --- ЛОГИКА ФУНКЦИЙ ESP ---

-- 1. Функция ESP Таймеров (Без изменений)
local function ToggleTimerESP(state)
    if state == true then
        if isTimerEspActive then return end
        isTimerEspActive = true
        timerEspToggle.Text = "ESP (RemainingTime) [ON]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50) 
        
        timerEspFolder = CoreGui:FindFirstChild("ESP_RemainingTimers") or Instance.new("Folder", CoreGui)
        timerEspFolder.Name = "ESP_RemainingTimers"

        local textColor = Color3.fromRGB(0, 255, 255)
        local textSize = 12
        local maxY = 50

        local function isFirstFloor(part)
            return part and part.Position.Y <= maxY
        end
        
        local function makeESP(hitbox, sourceText)
            if not hitbox or not sourceText then return end
            local id = sourceText:GetFullName()
            if timerEspFolder:FindFirstChild(id) or not isFirstFloor(hitbox) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = id; gui.Adornee = hitbox; gui.Size = UDim2.new(0, 100, 0, 20)
            gui.StudsOffset = Vector3.new(0, 3, 0); gui.AlwaysOnTop = true; gui.Parent = timerEspFolder

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
            label.TextColor3 = textColor; label.TextStrokeTransparency = 0.5
            label.Font = Enum.Font.Gotham; label.TextSize = textSize
            label.Text = sourceText.Text; label.Parent = gui

            local propConn, ancConn
            
            propConn = sourceText:GetPropertyChangedSignal("Text"):Connect(function()
                if label and label.Parent then
                    label.Text = sourceText.Text
                else
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)

            ancConn = sourceText.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if gui then gui:Destroy() end
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)
            
            table.insert(timerEspConnections, propConn)
            table.insert(timerEspConnections, ancConn)
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end

        local descConn = Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end)
        table.insert(timerEspConnections, descConn)

    elseif state == false then
        if not isTimerEspActive then return end
        isTimerEspActive = false
        timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        
        for _, conn in ipairs(timerEspConnections) do
            if conn then conn:Disconnect() end
        end
        timerEspConnections = {} 
        
        if timerEspFolder then
            timerEspFolder:Destroy()
            timerEspFolder = nil
        end
    end
end

-- 2. Функция ESP Игроков (Имена) (Без изменений)
local function TogglePlayerESP(state)
    if state == true then
        if isPlayerEspActive then return end
        isPlayerEspActive = true
        playerEspToggle.Text = "ESP (Игроки) [ON]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        playerEspFolder = CoreGui:FindFirstChild("ESP_Players") or Instance.new("Folder", CoreGui)
        playerEspFolder.Name = "ESP_Players"

        local function makePlayerESP(character)
            local player = Players:GetPlayerFromCharacter(character)
            if not player or player == LocalPlayer then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not hrp or playerEspFolder:FindFirstChild(player.Name) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = player.Name
            gui.Adornee = hrp
            gui.Size = UDim2.new(0, 120, 0, 30)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.AlwaysOnTop = true
            gui.Parent = playerEspFolder
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0.4
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 14
            label.Text = player.Name
            label.Parent = gui
            
            local deathConn = humanoid.Died:Connect(function()
                if gui then gui:Destroy() end
            end)
            
            table.insert(playerEspConnections, deathConn)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                makePlayerESP(player.Character)
            end
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end
        
        local playerConn = Players.PlayerAdded:Connect(function(player)
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end)
        table.insert(playerEspConnections, playerConn)

    elseif state == false then
        if not isPlayerEspActive then return end
        isPlayerEspActive = false
        playerEspToggle.Text = "ESP (Игроки) [OFF]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)

        for _, conn in ipairs(playerEspConnections) do
            if conn then conn:Disconnect() end
        end
        playerEspConnections = {}
        
        if playerEspFolder then
            playerEspFolder:Destroy()
            playerEspFolder = nil
        end
    end
end

-- 3. [[ПЕРЕПИСАНО]] Функция ESP 2D Боксов
local function TogglePlayerBoxESP(state)
    
    -- Вспомогательная функция для создания "уголков"
    local function createCornerBox(name, parent)
        local box = Instance.new("Frame")
        box.Name = name
        box.BackgroundTransparency = 1
        box.Parent = parent
        box.ZIndex = 10
        
        local color = Color3.fromRGB(255, 255, 0)
        local thickness = 2
        local cornerSize = UDim.new(0.2, 0) -- 20%
        
        --[[
            v = vertical line (|)
            h = horizontal line (—)
        ]]
        
        -- TopLeft
        local tl = Instance.new("Frame", box)
        tl.Position = UDim2.new(0, 0, 0, 0)
        tl.Size = UDim2.new(cornerSize.Scale, 0, cornerSize.Scale, 0)
        tl.BackgroundTransparency = 1
        local tlv = Instance.new("Frame", tl); tlv.BackgroundColor3 = color; tlv.BorderSizePixel = 0
        tlv.Size = UDim2.new(0, thickness, 1, 0)
        local tlh = Instance.new("Frame", tl); tlh.BackgroundColor3 = color; tlh.BorderSizePixel = 0
        tlh.Size = UDim2.new(1, 0, 0, thickness)
        
        -- TopRight
        local tr = Instance.new("Frame", box)
        tr.AnchorPoint = Vector2.new(1, 0)
        tr.Position = UDim2.new(1, 0, 0, 0)
        tr.Size = UDim2.new(cornerSize.Scale, 0, cornerSize.Scale, 0)
        tr.BackgroundTransparency = 1
        local trv = Instance.new("Frame", tr); trv.BackgroundColor3 = color; trv.BorderSizePixel = 0
        trv.Position = UDim2.new(1, -thickness, 0, 0)
        trv.Size = UDim2.new(0, thickness, 1, 0)
        local trh = Instance.new("Frame", tr); trh.BackgroundColor3 = color; trh.BorderSizePixel = 0
        trh.Size = UDim2.new(1, 0, 0, thickness)

        -- BottomLeft
        local bl = Instance.new("Frame", box)
        bl.AnchorPoint = Vector2.new(0, 1)
        bl.Position = UDim2.new(0, 0, 1, 0)
        bl.Size = UDim2.new(cornerSize.Scale, 0, cornerSize.Scale, 0)
        bl.BackgroundTransparency = 1
        local blv = Instance.new("Frame", bl); blv.BackgroundColor3 = color; blv.BorderSizePixel = 0
        blv.Size = UDim2.new(0, thickness, 1, 0)
        local blh = Instance.new("Frame", bl); blh.BackgroundColor3 = color; blh.BorderSizePixel = 0
        blh.Position = UDim2.new(0, 0, 1, -thickness)
        blh.Size = UDim2.new(1, 0, 0, thickness)
        
        -- BottomRight
        local br = Instance.new("Frame", box)
        br.AnchorPoint = Vector2.new(1, 1)
        br.Position = UDim2.new(1, 0, 1, 0)
        br.Size = UDim2.new(cornerSize.Scale, 0, cornerSize.Scale, 0)
        br.BackgroundTransparency = 1
        local brv = Instance.new("Frame", br); brv.BackgroundColor3 = color; brv.BorderSizePixel = 0
        brv.Position = UDim2.new(1, -thickness, 0, 0)
        brv.Size = UDim2.new(0, thickness, 1, 0)
        local brh = Instance.new("Frame", br); brh.BackgroundColor3 = color; brh.BorderSizePixel = 0
        brh.Position = UDim2.new(0, 0, 1, -thickness)
        brh.Size = UDim2.new(1, 0, 0, thickness)

        return box
    end
    
    -- Вспомогательная функция, которая будет работать каждый кадр
    local function updateBox(player, boxGui)
        local character = player.Character
        
        -- Проверка, жив ли игрок и есть ли у него модель
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            boxGui.Visible = false
            return
        end
        
        local hrp = character.HumanoidRootPart
        
        -- Оценка "верха" и "низа"
        local headPos = character.Head.Position + Vector3.new(0, 1, 0)
        local feetPos = hrp.Position - Vector3.new(0, 3, 0)
        
        -- Проекция 3D -> 2D
        local headScreen, headOnScreen = Camera:WorldToScreenPoint(headPos)
        local feetScreen, feetOnScreen = Camera:WorldToScreenPoint(feetPos)
        
        if not headOnScreen or not feetOnScreen then
            boxGui.Visible = false
            return
        end
        
        -- Расчет размера и позиции
        local height = math.abs(headScreen.Y - feetScreen.Y)
        local width = height / 2 -- Типичное соотношение
        
        local topLeft = Vector2.new(headScreen.X - (width / 2), headScreen.Y)
        local size = Vector2.new(width, height)
        
        -- Обновление GUI
        boxGui.Visible = true
        boxGui.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
        boxGui.Size = UDim2.fromOffset(size.X, size.Y)
    end
    
    
    -- Главная логика Вкл/Выкл
    if state == true then
        -- --- ВКЛЮЧАЕМ ESP 2D БОКСОВ ---
        if isPlayerBoxEspActive then return end
        isPlayerBoxEspActive = true
        playerBoxEspToggle.Text = "ESP (2D Box) [ON]"
        playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        -- Создаем ScreenGui, на котором будем рисовать
        playerBoxEspFolder = CoreGui:FindFirstChild("ESP_PlayerBoxes") or Instance.new("ScreenGui", CoreGui)
        playerBoxEspFolder.Name = "ESP_PlayerBoxes"
        playerBoxEspFolder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        playerBoxEspFolder.ResetOnSpawn = false

        -- Подключаем главный цикл отрисовки
        boxRenderConnection = RunService.RenderStepped:Connect(function()
            for player, boxGui in pairs(activeBoxGuis) do
                updateBox(player, boxGui)
            end
        end)
        
        -- Создаем боксы для тех, кто уже в игре
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not activeBoxGuis[player] then
                activeBoxGuis[player] = createCornerBox(player.Name, playerBoxEspFolder)
            end
        end
        
        -- Отслеживаем новых и ушедших
        local playerAddedConn = Players.PlayerAdded:Connect(function(player)
            if player ~= LocalPlayer and not activeBoxGuis[player] then
                activeBoxGuis[player] = createCornerBox(player.Name, playerBoxEspFolder)
            end
        end)
        
        local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
            if activeBoxGuis[player] then
                activeBoxGuis[player]:Destroy()
                activeBoxGuis[player] = nil
            end
        end)
        
        table.insert(playerBoxEspConnections, playerAddedConn)
        table.insert(playerBoxEspConnections, playerRemovingConn)

    elseif state == false then
        -- --- ВЫКЛЮЧАЕМ ESP 2D БОКСОВ ---
        if not isPlayerBoxEspActive then return end
        isPlayerBoxEspActive = false
        playerBoxEspToggle.Text = "ESP (2D Box) [OFF]"
        playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)

        -- Отключаем главный цикл отрисовки
        if boxRenderConnection then
            boxRenderConnection:Disconnect()
            boxRenderConnection = nil
        end
        
        -- Отключаем отслеживание игроков
        for _, conn in ipairs(playerBoxEspConnections) do
            if conn then conn:Disconnect() end
        end
        playerBoxEspConnections = {}
        
        -- Уничтожаем ScreenGui
        if playerBoxEspFolder then
            playerBoxEspFolder:Destroy()
            playerBoxEspFolder = nil
        end
        
        -- Очищаем таблицу
        activeBoxGuis = {}
    end
end


-- --- ПОДКЛЮЧЕНИЕ КНОПОК ---

timerEspToggle.MouseButton1Click:Connect(function()
    ToggleTimerESP(not isTimerEspActive) 
end)

playerEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerESP(not isPlayerEspActive) 
end)

playerBoxEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerBoxESP(not isPlayerBoxEspActive) 
end)


-- --- ГЛАВНАЯ ЛОГИКА АНИМАЦИЙ (Open/Close) ---
-- (Без изменений)
local animationInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local closedPosition = UDim2.new(-0.5, 0, 0.5, 0)
local openPosition = UDim2.new(0.02, 70, 0.5, 0)

local openTween = TweenService:Create(MenuFrame, animationInfo, {Position = openPosition})
local closeTween = TweenService:Create(MenuFrame, animationInfo, {Position = closedPosition})

local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local originalBtnColor = OpenButton.BackgroundColor3
local hoverBtnColor = Color3.fromRGB(60, 60, 60)
local hoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = hoverBtnColor})
local unhoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = originalBtnColor})

OpenButton.MouseEnter:Connect(function() hoverTween:Play() end)
OpenButton.MouseLeave:Connect(function() unhoverTween:Play() end)

OpenButton.MouseButton1Click:Connect(function()
    if isOpen then
        closeTween:Play()
        isOpen = false
    else
        openTween:Play()
        isOpen = true
    end
end)

-- ЛОГИКА ЗАКРЫТИЯ (КРЕСТИК)
CloseButton.MouseButton1Click:Connect(function()
    -- Сначала выключаем ВСЕ функции
    ToggleTimerESP(false)
    TogglePlayerESP(false) 
    TogglePlayerBoxESP(false) -- Новая функция тоже отключится
    
    -- Затем уничтожаем GUI
    MyScreenGui:Destroy()
end)

-- Безопасная очистка при выгрузке скрипта
MyScreenGui.Destroying:Connect(function()
    ToggleTimerESP(false)
    TogglePlayerESP(false)
    TogglePlayerBoxESP(false)
end)
local isPlayerBoxEspActive = false
local playerBoxEspFolder = nil
local playerBoxEspConnections = {}

-- --- СОЗДАНИЕ GUI ---

-- 1. Главный ScreenGui
local MyScreenGui = Instance.new("ScreenGui")
MyScreenGui.Name = "MyMenu_v4"
MyScreenGui.Parent = PlayerGui
MyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 2. Кнопка Открытия (Круглая кнопка "M")
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = MyScreenGui
OpenButton.Size = UDim2.new(0, 60, 0, 60)
OpenButton.Position = UDim2.new(0.02, 0, 0.5, -30)
OpenButton.AnchorPoint = Vector2.new(0, 0.5)
OpenButton.Text = "M"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
OpenButton.Font = Enum.Font.GothamSemibold
OpenButton.TextSize = 24
OpenButton.ZIndex = 3

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = OpenButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(80, 80, 80)
btnStroke.Thickness = 2
btnStroke.Parent = OpenButton

-- 3. Главное Меню (Frame)
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Parent = MyScreenGui
MenuFrame.Size = UDim2.new(0, 400, 0, 350)
MenuFrame.Position = UDim2.new(-0.5, 0, 0.5, 0) 
MenuFrame.AnchorPoint = Vector2.new(0, 0.5)
MenuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MenuFrame.BorderSizePixel = 0
MenuFrame.ClipsDescendants = true
MenuFrame.ZIndex = 2

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = MenuFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(80, 80, 80)
frameStroke.Thickness = 2
frameStroke.Parent = MenuFrame

local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
})
frameGradient.Rotation = 90
frameGradient.Parent = MenuFrame

-- 4. Заголовок Меню
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = MenuFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleLabel.Text = "My Cool Menu"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleLabel

-- 5. Кнопка Закрытия (Крестик)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = MenuFrame
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -10, 0, 7.5)
CloseButton.AnchorPoint = Vector2.new(1, 0)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CloseButton.BackgroundTransparency = 0.5
CloseButton.ZIndex = 3

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseButton

-- Анимация наведения на крестик
local closeHoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local closeHoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    BackgroundTransparency = 0,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
local closeUnhoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.5,
    TextColor3 = Color3.fromRGB(200, 200, 200)
})

CloseButton.MouseEnter:Connect(function() closeHoverTween:Play() end)
CloseButton.MouseLeave:Connect(function() closeUnhoverTween:Play() end)


-- 6. СИСТЕМА ТАБОВ (ВКЛАДОК)

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = MenuFrame
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundTransparency = 1

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MenuFrame
ContentContainer.Size = UDim2.new(1, -20, 1, -85)
ContentContainer.Position = UDim2.new(0, 10, 0, 75)
ContentContainer.BackgroundTransparency = 1

-- Кнопки-табы
local TabButtonVisuals = Instance.new("TextButton")
TabButtonVisuals.Name = "TabVisuals"
TabButtonVisuals.Parent = TabContainer
TabButtonVisuals.Size = UDim2.new(0, 100, 1, 0)
TabButtonVisuals.Position = UDim2.new(0, 10, 0, 0)
TabButtonVisuals.Font = Enum.Font.GothamSemibold
TabButtonVisuals.Text = "Visuals"
TabButtonVisuals.TextSize = 16
TabButtonVisuals.TextColor3 = Color3.fromRGB(255, 255, 255) -- Активный
TabButtonVisuals.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local tabVisualsCorner = Instance.new("UICorner", TabButtonVisuals)
tabVisualsCorner.CornerRadius = UDim.new(0, 6)

-- [[ИЗМЕНЕНО]] Таб "Main"
local TabButtonMain = Instance.new("TextButton")
TabButtonMain.Name = "TabMain"
TabButtonMain.Parent = TabContainer
TabButtonMain.Size = UDim2.new(0, 100, 1, 0)
TabButtonMain.Position = UDim2.new(0, 115, 0, 0)
TabButtonMain.Font = Enum.Font.Gotham
TabButtonMain.Text = "Main" -- [[ИЗМЕНЕНО]]
TabButtonMain.TextSize = 16
TabButtonMain.TextColor3 = Color3.fromRGB(150, 150, 150) -- Неактивный
TabButtonMain.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
local tabMainCorner = Instance.new("UICorner", TabButtonMain)
tabMainCorner.CornerRadius = UDim.new(0, 6)

-- Страницы (содержимое)
local VisualsFrame = Instance.new("Frame")
VisualsFrame.Name = "VisualsFrame"
VisualsFrame.Parent = ContentContainer
VisualsFrame.Size = UDim2.new(1, 0, 1, 0)
VisualsFrame.BackgroundTransparency = 1
VisualsFrame.Visible = true -- Показываем по умолчанию

-- [[ИЗМЕНЕНО]] Фрейм "Main" (пустой)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ContentContainer
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.Visible = false -- Скрываем

-- Логика переключения табов
local tabs = {TabButtonVisuals, TabButtonMain} -- [[ИЗМЕНЕНО]]
local pages = {VisualsFrame, MainFrame} -- [[ИЗМЕНЕНО]]

local function switchTab(tabToSelect)
    for i, tab in ipairs(tabs) do
        local page = pages[i]
        if tab == tabToSelect then
            -- Активировать
            page.Visible = true
            tab.Font = Enum.Font.GothamSemibold
            tab.TextColor3 = Color3.fromRGB(255, 255, 255)
            tab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            -- Деактивировать
            page.Visible = false
            tab.Font = Enum.Font.Gotham
            tab.TextColor3 = Color3.fromRGB(150, 150, 150)
            tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        end
    end
end

TabButtonVisuals.MouseButton1Click:Connect(function() switchTab(TabButtonVisuals) end)
TabButtonMain.MouseButton1Click:Connect(function() switchTab(TabButtonMain) end) -- [[ИЗМЕНЕНО]]

-- --- СЕКЦИЯ: VISUALS (Все ESP) ---

-- Кнопка-переключатель для ESP на таймеры
local timerEspToggle = Instance.new("TextButton")
timerEspToggle.Name = "TimerESPToggle"
timerEspToggle.Parent = VisualsFrame 
timerEspToggle.Size = UDim2.new(1, 0, 0, 30)
timerEspToggle.Position = UDim2.new(0, 0, 0, 10) -- Позиция 1
timerEspToggle.Font = Enum.Font.GothamSemibold
timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
timerEspToggle.TextSize = 16
timerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 

local espToggleCorner = Instance.new("UICorner", timerEspToggle)
espToggleCorner.CornerRadius = UDim.new(0, 8)

-- Кнопка-переключатель для ESP на Игроков (Имена)
local playerEspToggle = Instance.new("TextButton")
playerEspToggle.Name = "PlayerESPToggle"
playerEspToggle.Parent = VisualsFrame -- [[ИЗМЕНЕНО]]
playerEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerEspToggle.Position = UDim2.new(0, 0, 0, 50) -- [[ИЗМЕНЕНО]] Позиция 2 (10+30+10)
playerEspToggle.Font = Enum.Font.GothamSemibold
playerEspToggle.Text = "ESP (Игроки) [OFF]"
playerEspToggle.TextSize = 16
playerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 

local playerEspToggleCorner = Instance.new("UICorner", playerEspToggle)
playerEspToggleCorner.CornerRadius = UDim.new(0, 8)

-- Кнопка-переключатель для ESP 3D Боксов
local playerBoxEspToggle = Instance.new("TextButton")
playerBoxEspToggle.Name = "PlayerBoxESPToggle"
playerBoxEspToggle.Parent = VisualsFrame -- [[ИЗМЕНЕНО]]
playerBoxEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerBoxEspToggle.Position = UDim2.new(0, 0, 0, 90) -- [[ИЗМЕНЕНО]] Позиция 3 (50+30+10)
playerBoxEspToggle.Font = Enum.Font.GothamSemibold
playerBoxEspToggle.Text = "ESP (3D Box) [OFF]"
playerBoxEspToggle.TextSize = 16
playerBoxEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 

local playerBoxEspToggleCorner = Instance.new("UICorner", playerBoxEspToggle)
playerBoxEspToggleCorner.CornerRadius = UDim.new(0, 8)


-- --- ЛОГИКА ФУНКЦИЙ ESP ---

-- 1. Функция ESP Таймеров
local function ToggleTimerESP(state)
    if state == true then
        if isTimerEspActive then return end
        isTimerEspActive = true
        timerEspToggle.Text = "ESP (RemainingTime) [ON]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50) 
        
        timerEspFolder = CoreGui:FindFirstChild("ESP_RemainingTimers") or Instance.new("Folder", CoreGui)
        timerEspFolder.Name = "ESP_RemainingTimers"

        local textColor = Color3.fromRGB(0, 255, 255)
        local textSize = 12
        local maxY = 50

        local function isFirstFloor(part)
            return part and part.Position.Y <= maxY
        end
        
        local function makeESP(hitbox, sourceText)
            if not hitbox or not sourceText then return end
            local id = sourceText:GetFullName()
            if timerEspFolder:FindFirstChild(id) or not isFirstFloor(hitbox) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = id; gui.Adornee = hitbox; gui.Size = UDim2.new(0, 100, 0, 20)
            gui.StudsOffset = Vector3.new(0, 3, 0); gui.AlwaysOnTop = true; gui.Parent = timerEspFolder

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
            label.TextColor3 = textColor; label.TextStrokeTransparency = 0.5
            label.Font = Enum.Font.Gotham; label.TextSize = textSize
            label.Text = sourceText.Text; label.Parent = gui

            local propConn, ancConn
            
            propConn = sourceText:GetPropertyChangedSignal("Text"):Connect(function()
                if label and label.Parent then
                    label.Text = sourceText.Text
                else
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)

            ancConn = sourceText.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if gui then gui:Destroy() end
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)
            
            table.insert(timerEspConnections, propConn)
            table.insert(timerEspConnections, ancConn)
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end

        local descConn = Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end)
        table.insert(timerEspConnections, descConn)

    elseif state == false then
        if not isTimerEspActive then return end
        isTimerEspActive = false
        timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        
        for _, conn in ipairs(timerEspConnections) do
            if conn then conn:Disconnect() end
        end
        timerEspConnections = {} 
        
        if timerEspFolder then
            timerEspFolder:Destroy()
            timerEspFolder = nil
        end
    end
end

-- 2. Функция ESP Игроков (Имена)
local function TogglePlayerESP(state)
    if state == true then
        if isPlayerEspActive then return end
        isPlayerEspActive = true
        playerEspToggle.Text = "ESP (Игроки) [ON]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        playerEspFolder = CoreGui:FindFirstChild("ESP_Players") or Instance.new("Folder", CoreGui)
        playerEspFolder.Name = "ESP_Players"

        local function makePlayerESP(character)
            local player = Players:GetPlayerFromCharacter(character)
            if not player or player == LocalPlayer then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not hrp or playerEspFolder:FindFirstChild(player.Name) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = player.Name
            gui.Adornee = hrp
            gui.Size = UDim2.new(0, 120, 0, 30)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.AlwaysOnTop = true
            gui.Parent = playerEspFolder
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0.4
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 14
            label.Text = player.Name
            label.Parent = gui
            
            local deathConn = humanoid.Died:Connect(function()
                if gui then gui:Destroy() end
            end)
            
            table.insert(playerEspConnections, deathConn)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                makePlayerESP(player.Character)
            end
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end
        
        local playerConn = Players.PlayerAdded:Connect(function(player)
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end)
        table.insert(playerEspConnections, playerConn)

    elseif state == false then
        if not isPlayerEspActive then return end
        isPlayerEspActive = false
        playerEspToggle.Text = "ESP (Игроки) [OFF]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)

        for _, conn in ipairs(playerEspConnections) do
            if conn then conn:Disconnect() end
        end
        playerEspConnections = {}
        
        if playerEspFolder then
            playerEspFolder:Destroy()
            playerEspFolder = nil
        end
    end
end

-- 3. Функция ESP 3D Боксов
local function TogglePlayerBoxESP(state)
    if state == true then
        if isPlayerBoxEspActive then return end
        isPlayerBoxEspActive = true
        playerBoxEspToggle.Text = "ESP (3D Box) [ON]"
        playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        playerBoxEspFolder = CoreGui:FindFirstChild("ESP_PlayerBoxes") or Instance.new("Folder", CoreGui)
        playerBoxEspFolder.Name = "ESP_PlayerBoxes"

        local function makePlayerBoxESP(character)
            local player = Players:GetPlayerFromCharacter(character)
            if not player or player == LocalPlayer then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not hrp or playerBoxEspFolder:FindFirstChild(player.Name) then return end

            local box = Instance.new("BoxHandleAdornment")
            box.Name = player.Name
            box.Adornee = hrp
            box.Size = Vector3.new(4, 6.5, 2) 
            box.Color3 = Color3.fromRGB(255, 255, 0) 
            box.Transparency = 0.6
            box.AlwaysOnTop = true
            box.Parent = playerBoxEspFolder
            
            local deathConn = humanoid.Died:Connect(function()
                if box then box:Destroy() end
            end)
            
            table.insert(playerBoxEspConnections, deathConn)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                makePlayerBoxESP(player.Character)
            end
            local charConn = player.CharacterAdded:Connect(makePlayerBoxESP)
            table.insert(playerBoxEspConnections, charConn)
        end
        
        local playerConn = Players.PlayerAdded:Connect(function(player)
            local charConn = player.CharacterAdded:Connect(makePlayerBoxESP)
            table.insert(playerBoxEspConnections, charConn)
        end)
        table.insert(playerBoxEspConnections, playerConn)

    elseif state == false then
        if not isPlayerBoxEspActive then return end
        isPlayerBoxEspActive = false
        playerBoxEspToggle.Text = "ESP (3D Box) [OFF]"
        playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)

        for _, conn in ipairs(playerBoxEspConnections) do
            if conn then conn:Disconnect() end
        end
        playerBoxEspConnections = {}
        
        if playerBoxEspFolder then
            playerBoxEspFolder:Destroy()
            playerBoxEspFolder = nil
        end
    end
end

-- --- ПОДКЛЮЧЕНИЕ КНОПОК ---

timerEspToggle.MouseButton1Click:Connect(function()
    ToggleTimerESP(not isTimerEspActive) 
end)

playerEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerESP(not isPlayerEspActive) 
end)

playerBoxEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerBoxESP(not isPlayerBoxEspActive) 
end)


-- --- ГЛАВНАЯ ЛОГИКА АНИМАЦИЙ (Open/Close) ---

local animationInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local closedPosition = UDim2.new(-0.5, 0, 0.5, 0)
local openPosition = UDim2.new(0.02, 70, 0.5, 0)

local openTween = TweenService:Create(MenuFrame, animationInfo, {Position = openPosition})
local closeTween = TweenService:Create(MenuFrame, animationInfo, {Position = closedPosition})

-- Анимация наведения на кнопку "M"
local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local originalBtnColor = OpenButton.BackgroundColor3
local hoverBtnColor = Color3.fromRGB(60, 60, 60)
local hoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = hoverBtnColor})
local unhoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = originalBtnColor})

OpenButton.MouseEnter:Connect(function() hoverTween:Play() end)
OpenButton.MouseLeave:Connect(function() unhoverTween:Play() end)

-- Открытие/Закрытие по кнопке "M"
OpenButton.MouseButton1Click:Connect(function()
    if isOpen then
        closeTween:Play()
        isOpen = false
    else
        openTween:Play()
        isOpen = true
    end
end)

-- ЛОГИКА ЗАКРЫТИЯ (КРЕСТИК)
CloseButton.MouseButton1Click:Connect(function()
    -- Сначала выключаем ВСЕ функции
    ToggleTimerESP(false)
    TogglePlayerESP(false) 
    TogglePlayerBoxESP(false)
    
    -- Затем уничтожаем GUI
    MyScreenGui:Destroy()
end)

-- Безопасная очистка при выгрузке скрипта
MyScreenGui.Destroying:Connect(function()
    ToggleTimerESP(false)
    TogglePlayerESP(false)
    TogglePlayerBoxESP(false)
end)
local playerBoxEspConnections = {}

-- --- СОЗДАНИЕ GUI ---

-- 1. Главный ScreenGui
local MyScreenGui = Instance.new("ScreenGui")
MyScreenGui.Name = "MyMenu_v3"
MyScreenGui.Parent = PlayerGui
MyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 2. Кнопка Открытия (Круглая кнопка "M")
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = MyScreenGui
OpenButton.Size = UDim2.new(0, 60, 0, 60)
OpenButton.Position = UDim2.new(0.02, 0, 0.5, -30)
OpenButton.AnchorPoint = Vector2.new(0, 0.5)
OpenButton.Text = "M"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
OpenButton.Font = Enum.Font.GothamSemibold
OpenButton.TextSize = 24
OpenButton.ZIndex = 3

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = OpenButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(80, 80, 80)
btnStroke.Thickness = 2
btnStroke.Parent = OpenButton

-- 3. Главное Меню (Frame)
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Parent = MyScreenGui
MenuFrame.Size = UDim2.new(0, 400, 0, 350)
MenuFrame.Position = UDim2.new(-0.5, 0, 0.5, 0) -- Стартовая позиция (за экраном)
MenuFrame.AnchorPoint = Vector2.new(0, 0.5)
MenuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MenuFrame.BorderSizePixel = 0
MenuFrame.ClipsDescendants = true
MenuFrame.ZIndex = 2

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = MenuFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(80, 80, 80)
frameStroke.Thickness = 2
frameStroke.Parent = MenuFrame

local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
})
frameGradient.Rotation = 90
frameGradient.Parent = MenuFrame

-- 4. Заголовок Меню
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = MenuFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleLabel.Text = "My Cool Menu"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleLabel

-- 5. Кнопка Закрытия (Крестик)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = MenuFrame
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -10, 0, 7.5)
CloseButton.AnchorPoint = Vector2.new(1, 0)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CloseButton.BackgroundTransparency = 0.5
CloseButton.ZIndex = 3

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseButton

-- Анимация наведения на крестик
local closeHoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local closeHoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    BackgroundTransparency = 0,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
local closeUnhoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.5,
    TextColor3 = Color3.fromRGB(200, 200, 200)
})

CloseButton.MouseEnter:Connect(function() closeHoverTween:Play() end)
CloseButton.MouseLeave:Connect(function() closeUnhoverTween:Play() end)


-- 6. СИСТЕМА ТАБОВ (ВКЛАДОК)

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = MenuFrame
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundTransparency = 1

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MenuFrame
ContentContainer.Size = UDim2.new(1, -20, 1, -85)
ContentContainer.Position = UDim2.new(0, 10, 0, 75)
ContentContainer.BackgroundTransparency = 1

-- Кнопки-табы
local TabButtonVisuals = Instance.new("TextButton")
TabButtonVisuals.Name = "TabVisuals"
TabButtonVisuals.Parent = TabContainer
TabButtonVisuals.Size = UDim2.new(0, 100, 1, 0)
TabButtonVisuals.Position = UDim2.new(0, 10, 0, 0)
TabButtonVisuals.Font = Enum.Font.GothamSemibold
TabButtonVisuals.Text = "Visuals"
TabButtonVisuals.TextSize = 16
TabButtonVisuals.TextColor3 = Color3.fromRGB(255, 255, 255) -- Активный
TabButtonVisuals.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local tabVisualsCorner = Instance.new("UICorner", TabButtonVisuals)
tabVisualsCorner.CornerRadius = UDim.new(0, 6)

-- [[ИЗМЕНЕНО]] Таб для Игроков
local TabButtonPlayers = Instance.new("TextButton")
TabButtonPlayers.Name = "TabPlayers"
TabButtonPlayers.Parent = TabContainer
TabButtonPlayers.Size = UDim2.new(0, 100, 1, 0)
TabButtonPlayers.Position = UDim2.new(0, 115, 0, 0)
TabButtonPlayers.Font = Enum.Font.Gotham
TabButtonPlayers.Text = "Players" -- [[ИЗМЕНЕНО]]
TabButtonPlayers.TextSize = 16
TabButtonPlayers.TextColor3 = Color3.fromRGB(150, 150, 150) -- Неактивный
TabButtonPlayers.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
local tabPlayersCorner = Instance.new("UICorner", TabButtonPlayers)
tabPlayersCorner.CornerRadius = UDim.new(0, 6)

-- Страницы (содержимое)
local VisualsFrame = Instance.new("Frame")
VisualsFrame.Name = "VisualsFrame"
VisualsFrame.Parent = ContentContainer
VisualsFrame.Size = UDim2.new(1, 0, 1, 0)
VisualsFrame.BackgroundTransparency = 1
VisualsFrame.Visible = true -- Показываем по умолчанию

-- [[ИЗМЕНЕНО]] Фрейм для Игроков
local PlayersFrame = Instance.new("Frame")
PlayersFrame.Name = "PlayersFrame"
PlayersFrame.Parent = ContentContainer
PlayersFrame.Size = UDim2.new(1, 0, 1, 0)
PlayersFrame.BackgroundTransparency = 1
PlayersFrame.Visible = false -- Скрываем

-- Логика переключения табов
local tabs = {TabButtonVisuals, TabButtonPlayers} -- [[ИЗМЕНЕНО]]
local pages = {VisualsFrame, PlayersFrame} -- [[ИЗМЕНЕНО]]

local function switchTab(tabToSelect)
    for i, tab in ipairs(tabs) do
        local page = pages[i]
        if tab == tabToSelect then
            -- Активировать
            page.Visible = true
            tab.Font = Enum.Font.GothamSemibold
            tab.TextColor3 = Color3.fromRGB(255, 255, 255)
            tab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            -- Деактивировать
            page.Visible = false
            tab.Font = Enum.Font.Gotham
            tab.TextColor3 = Color3.fromRGB(150, 150, 150)
            tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        end
    end
end

TabButtonVisuals.MouseButton1Click:Connect(function() switchTab(TabButtonVisuals) end)
TabButtonPlayers.MouseButton1Click:Connect(function() switchTab(TabButtonPlayers) end) -- [[ИЗМЕНЕНО]]

-- --- СЕКЦИЯ: VISUALS (ESP Таймеры) ---

-- Кнопка-переключатель для ESP на таймеры
local timerEspToggle = Instance.new("TextButton")
timerEspToggle.Name = "TimerESPToggle"
timerEspToggle.Parent = VisualsFrame -- [[ИЗМЕНЕНО]] Остается в Visuals
timerEspToggle.Size = UDim2.new(1, 0, 0, 30)
timerEspToggle.Position = UDim2.new(0, 0, 0, 10)
timerEspToggle.Font = Enum.Font.GothamSemibold
timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
timerEspToggle.TextSize = 16
timerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 

local espToggleCorner = Instance.new("UICorner", timerEspToggle)
espToggleCorner.CornerRadius = UDim.new(0, 8)

-- Главная функция для Вкл/Выкл ESP Таймеров
local function ToggleTimerESP(state)
    if state == true then
        -- --- ВКЛЮЧАЕМ ESP ---
        if isTimerEspActive then return end
        isTimerEspActive = true
        timerEspToggle.Text = "ESP (RemainingTime) [ON]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50) 
        
        timerEspFolder = CoreGui:FindFirstChild("ESP_RemainingTimers") or Instance.new("Folder", CoreGui)
        timerEspFolder.Name = "ESP_RemainingTimers"

        local textColor = Color3.fromRGB(0, 255, 255)
        local textSize = 12
        local maxY = 50

        local function isFirstFloor(part)
            return part and part.Position.Y <= maxY
        end
        
        local function makeESP(hitbox, sourceText)
            if not hitbox or not sourceText then return end
            local id = sourceText:GetFullName()
            if timerEspFolder:FindFirstChild(id) or not isFirstFloor(hitbox) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = id; gui.Adornee = hitbox; gui.Size = UDim2.new(0, 100, 0, 20)
            gui.StudsOffset = Vector3.new(0, 3, 0); gui.AlwaysOnTop = true; gui.Parent = timerEspFolder

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
            label.TextColor3 = textColor; label.TextStrokeTransparency = 0.5
            label.Font = Enum.Font.Gotham; label.TextSize = textSize
            label.Text = sourceText.Text; label.Parent = gui

            local propConn, ancConn
            
            propConn = sourceText:GetPropertyChangedSignal("Text"):Connect(function()
                if label and label.Parent then
                    label.Text = sourceText.Text
                else
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)

            ancConn = sourceText.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if gui then gui:Destroy() end
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)
            
            table.insert(timerEspConnections, propConn)
            table.insert(timerEspConnections, ancConn)
        end

        -- Обработка существующих
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end

        -- Обработка новых (главный сигнал)
        local descConn = Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end)
        table.insert(timerEspConnections, descConn)

    elseif state == false then
        -- --- ВЫКЛЮЧАЕМ ESP ---
        if not isTimerEspActive then return end
        isTimerEspActive = false
        timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        
        for _, conn in ipairs(timerEspConnections) do
            if conn then conn:Disconnect() end
        end
        timerEspConnections = {} 
        
        if timerEspFolder then
            timerEspFolder:Destroy()
            timerEspFolder = nil
        end
    end
end

-- Подключаем функцию к кнопке-переключателю
timerEspToggle.MouseButton1Click:Connect(function()
    ToggleTimerESP(not isTimerEspActive) -- Инвертируем состояние
end)


-- --- [[НОВОЕ]] СЕКЦИЯ: PLAYERS (ESP Имен и Боксов) ---

-- Кнопка-переключатель для ESP на Игроков (Имена)
local playerEspToggle = Instance.new("TextButton")
playerEspToggle.Name = "PlayerESPToggle"
playerEspToggle.Parent = PlayersFrame -- [[ИЗМЕНЕНО]] Перенесено во вкладку Players
playerEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerEspToggle.Position = UDim2.new(0, 0, 0, 10) -- [[ИЗМЕНЕНО]] Новая позиция
playerEspToggle.Font = Enum.Font.GothamSemibold
playerEspToggle.Text = "ESP (Игроки) [OFF]"
playerEspToggle.TextSize = 16
playerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 

local playerEspToggleCorner = Instance.new("UICorner", playerEspToggle)
playerEspToggleCorner.CornerRadius = UDim.new(0, 8)

-- Главная функция для Вкл/Выкл ESP Игроков (Имена)
local function TogglePlayerESP(state)
    if state == true then
        if isPlayerEspActive then return end
        isPlayerEspActive = true
        playerEspToggle.Text = "ESP (Игроки) [ON]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        playerEspFolder = CoreGui:FindFirstChild("ESP_Players") or Instance.new("Folder", CoreGui)
        playerEspFolder.Name = "ESP_Players"

        local function makePlayerESP(character)
            local player = Players:GetPlayerFromCharacter(character)
            if not player or player == LocalPlayer then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not hrp or playerEspFolder:FindFirstChild(player.Name) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = player.Name
            gui.Adornee = hrp
            gui.Size = UDim2.new(0, 120, 0, 30)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.AlwaysOnTop = true
            gui.Parent = playerEspFolder
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0.4
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 14
            label.Text = player.Name
            label.Parent = gui
            
            local deathConn = humanoid.Died:Connect(function()
                if gui then gui:Destroy() end
            end)
            
            table.insert(playerEspConnections, deathConn)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                makePlayerESP(player.Character)
            end
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end
        
        local playerConn = Players.PlayerAdded:Connect(function(player)
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end)
        table.insert(playerEspConnections, playerConn)

    elseif state == false then
        if not isPlayerEspActive then return end
        isPlayerEspActive = false
        playerEspToggle.Text = "ESP (Игроки) [OFF]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)

        for _, conn in ipairs(playerEspConnections) do
            if conn then conn:Disconnect() end
        end
        playerEspConnections = {}
        
        if playerEspFolder then
            playerEspFolder:Destroy()
            playerEspFolder = nil
        end
    end
end

-- Подключаем функцию к кнопке-переключателю
playerEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerESP(not isPlayerEspActive) 
end)


-- --- [[НОВОЕ]] ESP 3D Боксы ---

-- [[НОВОЕ]] Кнопка-переключатель для ESP 3D Боксов
local playerBoxEspToggle = Instance.new("TextButton")
playerBoxEspToggle.Name = "PlayerBoxESPToggle"
playerBoxEspToggle.Parent = PlayersFrame -- Во вкладке Players
playerBoxEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerBoxEspToggle.Position = UDim2.new(0, 0, 0, 50) -- Ставим ниже (10 + 30 + 10 = 50)
playerBoxEspToggle.Font = Enum.Font.GothamSemibold
playerBoxEspToggle.Text = "ESP (3D Box) [OFF]"
playerBoxEspToggle.TextSize = 16
playerBoxEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- [OFF] цвет

local playerBoxEspToggleCorner = Instance.new("UICorner", playerBoxEspToggle)
playerBoxEspToggleCorner.CornerRadius = UDim.new(0, 8)

-- [[НОВАЯ]] Главная функция для Вкл/Выкл ESP 3D Боксов
local function TogglePlayerBoxESP(state)
    if state == true then
        -- --- ВКЛЮЧАЕМ ESP БОКСОВ ---
        if isPlayerBoxEspActive then return end
        isPlayerBoxEspActive = true
        playerBoxEspToggle.Text = "ESP (3D Box) [ON]"
        playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        playerBoxEspFolder = CoreGui:FindFirstChild("ESP_PlayerBoxes") or Instance.new("Folder", CoreGui)
        playerBoxEspFolder.Name = "ESP_PlayerBoxes"

        local function makePlayerBoxESP(character)
            local player = Players:GetPlayerFromCharacter(character)
            if not player or player == LocalPlayer then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not hrp or playerBoxEspFolder:FindFirstChild(player.Name) then return end

            -- Создаем BoxHandleAdornment
            local box = Instance.new("BoxHandleAdornment")
            box.Name = player.Name
            box.Adornee = hrp
            box.Size = Vector3.new(4, 6.5, 2) -- Средний размер для игрока
            box.Color3 = Color3.fromRGB(255, 255, 0) -- Желтый
            box.Transparency = 0.6
            box.AlwaysOnTop = true
            box.Parent = playerBoxEspFolder
            
            -- Подключаем сигнал смерти, чтобы удалить ESP
            local deathConn = humanoid.Died:Connect(function()
                if box then box:Destroy() end
            end)
            
            table.insert(playerBoxEspConnections, deathConn)
        end

        -- Обработка существующих игроков
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                makePlayerBoxESP(player.Character)
            end
            local charConn = player.CharacterAdded:Connect(makePlayerBoxESP)
            table.insert(playerBoxEspConnections, charConn)
        end
        
        -- Обработка новых игроков
        local playerConn = Players.PlayerAdded:Connect(function(player)
            local charConn = player.CharacterAdded:Connect(makePlayerBoxESP)
            table.insert(playerBoxEspConnections, charConn)
        end)
        table.insert(playerBoxEspConnections, playerConn)

    elseif state == false then
        -- --- ВЫКЛЮЧАЕМ ESP БОКСОВ ---
        if not isPlayerBoxEspActive then return end
        isPlayerBoxEspActive = false
        playerBoxEspToggle.Text = "ESP (3D Box) [OFF]"
        playerBoxEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)

        for _, conn in ipairs(playerBoxEspConnections) do
            if conn then conn:Disconnect() end
        end
        playerBoxEspConnections = {}
        
        if playerBoxEspFolder then
            playerBoxEspFolder:Destroy()
            playerBoxEspFolder = nil
        end
    end
end

-- [[НОВОЕ]] Подключаем функцию к кнопке-переключателю
playerBoxEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerBoxESP(not isPlayerBoxEspActive) -- Инвертируем состояние
end)


-- --- ГЛАВНАЯ ЛОГИКА АНИМАЦИЙ (Open/Close) ---

local animationInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local closedPosition = UDim2.new(-0.5, 0, 0.5, 0)
local openPosition = UDim2.new(0.02, 70, 0.5, 0)

local openTween = TweenService:Create(MenuFrame, animationInfo, {Position = openPosition})
local closeTween = TweenService:Create(MenuFrame, animationInfo, {Position = closedPosition})

-- Анимация наведения на кнопку "M"
local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local originalBtnColor = OpenButton.BackgroundColor3
local hoverBtnColor = Color3.fromRGB(60, 60, 60)
local hoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = hoverBtnColor})
local unhoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = originalBtnColor})

OpenButton.MouseEnter:Connect(function() hoverTween:Play() end)
OpenButton.MouseLeave:Connect(function() unhoverTween:Play() end)

-- Открытие/Закрытие по кнопке "M"
OpenButton.MouseButton1Click:Connect(function()
    if isOpen then
        closeTween:Play()
        isOpen = false
    else
        openTween:Play()
        isOpen = true
    end
end)

-- ЛОГИКА ЗАКРЫТИЯ (КРЕСТИК)
CloseButton.MouseButton1Click:Connect(function()
    -- [[ИЗМЕНЕНО]] Сначала выключаем ВСЕ функции
    ToggleTimerESP(false)
    TogglePlayerESP(false) 
    TogglePlayerBoxESP(false) -- [[НОВОЕ]]
    
    -- Затем уничтожаем GUI
    MyScreenGui:Destroy()
end)

-- Безопасная очистка при выгрузке скрипта
MyScreenGui.Destroying:Connect(function()
    -- [[ИЗМЕНЕНО]]
    ToggleTimerESP(false)
    TogglePlayerESP(false)
    TogglePlayerBoxESP(false) -- [[НОВОЕ]]
end)
MyScreenGui.Name = "MyMenu_v2"
MyScreenGui.Parent = PlayerGui
MyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 2. Кнопка Открытия (Круглая кнопка "M")
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = MyScreenGui
OpenButton.Size = UDim2.new(0, 60, 0, 60)
OpenButton.Position = UDim2.new(0.02, 0, 0.5, -30)
OpenButton.AnchorPoint = Vector2.new(0, 0.5)
OpenButton.Text = "M"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
OpenButton.Font = Enum.Font.GothamSemibold
OpenButton.TextSize = 24
OpenButton.ZIndex = 3

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = OpenButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(80, 80, 80)
btnStroke.Thickness = 2
btnStroke.Parent = OpenButton

-- 3. Главное Меню (Frame)
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Parent = MyScreenGui
MenuFrame.Size = UDim2.new(0, 400, 0, 350)
MenuFrame.Position = UDim2.new(-0.5, 0, 0.5, 0) -- Стартовая позиция (за экраном)
MenuFrame.AnchorPoint = Vector2.new(0, 0.5)
MenuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MenuFrame.BorderSizePixel = 0
MenuFrame.ClipsDescendants = true
MenuFrame.ZIndex = 2

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = MenuFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(80, 80, 80)
frameStroke.Thickness = 2
frameStroke.Parent = MenuFrame

local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
})
frameGradient.Rotation = 90
frameGradient.Parent = MenuFrame

-- 4. Заголовок Меню
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = MenuFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleLabel.Text = "My Cool Menu"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleLabel

-- 5. Кнопка Закрытия (Крестик)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = MenuFrame
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -10, 0, 7.5)
CloseButton.AnchorPoint = Vector2.new(1, 0)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CloseButton.BackgroundTransparency = 0.5
CloseButton.ZIndex = 3

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseButton

-- Анимация наведения на крестик
local closeHoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local closeHoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    BackgroundTransparency = 0,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
local closeUnhoverTween = TweenService:Create(CloseButton, closeHoverInfo, {
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.5,
    TextColor3 = Color3.fromRGB(200, 200, 200)
})

CloseButton.MouseEnter:Connect(function() closeHoverTween:Play() end)
CloseButton.MouseLeave:Connect(function() closeUnhoverTween:Play() end)


-- 6. СИСТЕМА ТАБОВ (ВКЛАДОК)

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = MenuFrame
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundTransparency = 1

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MenuFrame
ContentContainer.Size = UDim2.new(1, -20, 1, -85)
ContentContainer.Position = UDim2.new(0, 10, 0, 75)
ContentContainer.BackgroundTransparency = 1

-- Кнопки-табы
local TabButtonVisuals = Instance.new("TextButton")
TabButtonVisuals.Name = "TabVisuals"
TabButtonVisuals.Parent = TabContainer
TabButtonVisuals.Size = UDim2.new(0, 100, 1, 0)
TabButtonVisuals.Position = UDim2.new(0, 10, 0, 0)
TabButtonVisuals.Font = Enum.Font.GothamSemibold
TabButtonVisuals.Text = "Visuals"
TabButtonVisuals.TextSize = 16
TabButtonVisuals.TextColor3 = Color3.fromRGB(255, 255, 255) -- Активный
TabButtonVisuals.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local tabVisualsCorner = Instance.new("UICorner", TabButtonVisuals)
tabVisualsCorner.CornerRadius = UDim.new(0, 6)

local TabButtonMain = Instance.new("TextButton")
TabButtonMain.Name = "TabMain"
TabButtonMain.Parent = TabContainer
TabButtonMain.Size = UDim2.new(0, 100, 1, 0)
TabButtonMain.Position = UDim2.new(0, 115, 0, 0)
TabButtonMain.Font = Enum.Font.Gotham
TabButtonMain.Text = "Main"
TabButtonMain.TextSize = 16
TabButtonMain.TextColor3 = Color3.fromRGB(150, 150, 150) -- Неактивный
TabButtonMain.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
local tabMainCorner = Instance.new("UICorner", TabButtonMain)
tabMainCorner.CornerRadius = UDim.new(0, 6)

-- Страницы (содержимое)
local VisualsFrame = Instance.new("Frame")
VisualsFrame.Name = "VisualsFrame"
VisualsFrame.Parent = ContentContainer
VisualsFrame.Size = UDim2.new(1, 0, 1, 0)
VisualsFrame.BackgroundTransparency = 1
VisualsFrame.Visible = true -- Показываем по умолчанию

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ContentContainer
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.Visible = false -- Скрываем

-- Логика переключения табов
local tabs = {TabButtonVisuals, TabButtonMain}
local pages = {VisualsFrame, MainFrame}

local function switchTab(tabToSelect)
    for i, tab in ipairs(tabs) do
        local page = pages[i]
        if tab == tabToSelect then
            -- Активировать
            page.Visible = true
            tab.Font = Enum.Font.GothamSemibold
            tab.TextColor3 = Color3.fromRGB(255, 255, 255)
            tab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            -- Деактивировать
            page.Visible = false
            tab.Font = Enum.Font.Gotham
            tab.TextColor3 = Color3.fromRGB(150, 150, 150)
            tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        end
    end
end

TabButtonVisuals.MouseButton1Click:Connect(function() switchTab(TabButtonVisuals) end)
TabButtonMain.MouseButton1Click:Connect(function() switchTab(TabButtonMain) end)

-- --- ИНТЕГРАЦИЯ ESP (Таймеры) ---

-- Кнопка-переключатель для ESP на таймеры
local timerEspToggle = Instance.new("TextButton")
timerEspToggle.Name = "TimerESPToggle"
timerEspToggle.Parent = VisualsFrame -- Добавляем во вкладку Visuals
timerEspToggle.Size = UDim2.new(1, 0, 0, 30)
timerEspToggle.Position = UDim2.new(0, 0, 0, 10)
timerEspToggle.Font = Enum.Font.GothamSemibold
timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
timerEspToggle.TextSize = 16
timerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- [OFF] цвет

local espToggleCorner = Instance.new("UICorner", timerEspToggle)
espToggleCorner.CornerRadius = UDim.new(0, 8)

-- Главная функция для Вкл/Выкл ESP Таймеров
local function ToggleTimerESP(state)
    if state == true then
        -- --- ВКЛЮЧАЕМ ESP ---
        if isTimerEspActive then return end
        isTimerEspActive = true
        timerEspToggle.Text = "ESP (RemainingTime) [ON]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50) -- [ON] цвет
        
        timerEspFolder = CoreGui:FindFirstChild("ESP_RemainingTimers") or Instance.new("Folder", CoreGui)
        timerEspFolder.Name = "ESP_RemainingTimers"

        local textColor = Color3.fromRGB(0, 255, 255)
        local textSize = 12
        local maxY = 50

        local function isFirstFloor(part)
            return part and part.Position.Y <= maxY
        end
        
        local function makeESP(hitbox, sourceText)
            if not hitbox or not sourceText then return end
            local id = sourceText:GetFullName()
            if timerEspFolder:FindFirstChild(id) or not isFirstFloor(hitbox) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = id; gui.Adornee = hitbox; gui.Size = UDim2.new(0, 100, 0, 20)
            gui.StudsOffset = Vector3.new(0, 3, 0); gui.AlwaysOnTop = true; gui.Parent = timerEspFolder

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
            label.TextColor3 = textColor; label.TextStrokeTransparency = 0.5
            label.Font = Enum.Font.Gotham; label.TextSize = textSize
            label.Text = sourceText.Text; label.Parent = gui

            local propConn, ancConn
            
            propConn = sourceText:GetPropertyChangedSignal("Text"):Connect(function()
                if label and label.Parent then
                    label.Text = sourceText.Text
                else
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)

            ancConn = sourceText.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if gui then gui:Destroy() end
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)
            
            table.insert(timerEspConnections, propConn)
            table.insert(timerEspConnections, ancConn)
        end

        -- Обработка существующих
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end

        -- Обработка новых (главный сигнал)
        local descConn = Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end)
        table.insert(timerEspConnections, descConn)

    elseif state == false then
        -- --- ВЫКЛЮЧАЕМ ESP ---
        if not isTimerEspActive then return end
        isTimerEspActive = false
        timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        
        for _, conn in ipairs(timerEspConnections) do
            if conn then conn:Disconnect() end
        end
        timerEspConnections = {} 
        
        if timerEspFolder then
            timerEspFolder:Destroy()
            timerEspFolder = nil
        end
    end
end

-- Подключаем функцию к кнопке-переключателю
timerEspToggle.MouseButton1Click:Connect(function()
    ToggleTimerESP(not isTimerEspActive) -- Инвертируем состояние
end)


-- --- [[НОВОЕ]] ИНТЕГРАЦИЯ ESP (Игроки) ---

-- [[НОВОЕ]] Кнопка-переключатель для ESP на Игроков
local playerEspToggle = Instance.new("TextButton")
playerEspToggle.Name = "PlayerESPToggle"
playerEspToggle.Parent = VisualsFrame -- Добавляем во вкладку Visuals
playerEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerEspToggle.Position = UDim2.new(0, 0, 0, 50) -- Ставим ниже (10 + 30 + 10 = 50)
playerEspToggle.Font = Enum.Font.GothamSemibold
playerEspToggle.Text = "ESP (Игроки) [OFF]"
playerEspToggle.TextSize = 16
playerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- [OFF] цвет

local playerEspToggleCorner = Instance.new("UICorner", playerEspToggle)
playerEspToggleCorner.CornerRadius = UDim.new(0, 8)

-- [[НОВАЯ]] Главная функция для Вкл/Выкл ESP Игроков
local function TogglePlayerESP(state)
    if state == true then
        -- --- ВКЛЮЧАЕМ ESP ИГРОКОВ ---
        if isPlayerEspActive then return end
        isPlayerEspActive = true
        playerEspToggle.Text = "ESP (Игроки) [ON]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        playerEspFolder = CoreGui:FindFirstChild("ESP_Players") or Instance.new("Folder", CoreGui)
        playerEspFolder.Name = "ESP_Players"

        local function makePlayerESP(character)
            local player = Players:GetPlayerFromCharacter(character)
            if not player or player == LocalPlayer then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not hrp or playerEspFolder:FindFirstChild(player.Name) then return end

            local gui = Instance.new("BillboardGui")
            gui.Name = player.Name
            gui.Adornee = hrp
            gui.Size = UDim2.new(0, 120, 0, 30)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.AlwaysOnTop = true
            gui.Parent = playerEspFolder
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0.4
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 14
            label.Text = player.Name
            label.Parent = gui
            
            -- Подключаем сигнал смерти, чтобы удалить ESP
            local deathConn = humanoid.Died:Connect(function()
                if gui then gui:Destroy() end
            end)
            
            table.insert(playerEspConnections, deathConn)
        end

        -- Обработка существующих игроков
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                makePlayerESP(player.Character)
            end
            -- [[НОВОЕ]] Добавляем обработчик для CharacterAdded на случай, если персонаж еще не загрузился
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end
        
        -- Обработка новых игроков
        local playerConn = Players.PlayerAdded:Connect(function(player)
            local charConn = player.CharacterAdded:Connect(makePlayerESP)
            table.insert(playerEspConnections, charConn)
        end)
        table.insert(playerEspConnections, playerConn)

    elseif state == false then
        -- --- ВЫКЛЮЧАЕМ ESP ИГРОКОВ ---
        if not isPlayerEspActive then return end
        isPlayerEspActive = false
        playerEspToggle.Text = "ESP (Игроки) [OFF]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)

        for _, conn in ipairs(playerEspConnections) do
            if conn then conn:Disconnect() end
        end
        playerEspConnections = {}
        
        if playerEspFolder then
            playerEspFolder:Destroy()
            playerEspFolder = nil
        end
    end
end

-- [[НОВОЕ]] Подключаем функцию к кнопке-переключателю
playerEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerESP(not isPlayerEspActive) -- Инвертируем состояние
end)


-- --- ГЛАВНАЯ ЛОГИКА АНИМАЦИЙ (Open/Close) ---

local animationInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local closedPosition = UDim2.new(-0.5, 0, 0.5, 0)
local openPosition = UDim2.new(0.02, 70, 0.5, 0)

local openTween = TweenService:Create(MenuFrame, animationInfo, {Position = openPosition})
local closeTween = TweenService:Create(MenuFrame, animationInfo, {Position = closedPosition})

-- Анимация наведения на кнопку "M"
local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local originalBtnColor = OpenButton.BackgroundColor3
local hoverBtnColor = Color3.fromRGB(60, 60, 60)
local hoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = hoverBtnColor})
local unhoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = originalBtnColor})

OpenButton.MouseEnter:Connect(function() hoverTween:Play() end)
OpenButton.MouseLeave:Connect(function() unhoverTween:Play() end)

-- Открытие/Закрытие по кнопке "M"
OpenButton.MouseButton1Click:Connect(function()
    if isOpen then
        closeTween:Play()
        isOpen = false
    else
        openTween:Play()
        isOpen = true
    end
end)

-- ЛОГИКА ЗАКРЫТИЯ (КРЕСТИК)
CloseButton.MouseButton1Click:Connect(function()
    -- Сначала выключаем все функции
    ToggleTimerESP(false)
    TogglePlayerESP(false) -- [[ИЗМЕНЕНО]]
    -- Затем уничтожаем GUI
    MyScreenGui:Destroy()
end)

-- Безопасная очистка при выгрузке скрипта
MyScreenGui.Destroying:Connect(function()
    ToggleTimerESP(false)
    TogglePlayerESP(false) -- [[ИЗМЕНЕНО]]
end)
TitleLabel.Name = "Title"; TitleLabel.Parent = MenuFrame; TitleLabel.Size = UDim2.new(1, 0, 0, 40); TitleLabel.Position = UDim2.new(0, 0, 0, 0); TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TitleLabel.Text = "My Cool Menu"; TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.TextSize = 18; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
local titleCorner = Instance.new("UICorner"); titleCorner.CornerRadius = UDim.new(0, 12); titleCorner.Parent = TitleLabel

-- 5. Кнопка Закрытия (Крестик)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"; CloseButton.Parent = MenuFrame; CloseButton.Size = UDim2.new(0, 25, 0, 25); CloseButton.Position = UDim2.new(1, -10, 0, 7.5); CloseButton.AnchorPoint = Vector2.new(1, 0); CloseButton.Text = "X"; CloseButton.Font = Enum.Font.GothamBold; CloseButton.TextSize = 16; CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200); CloseButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25); CloseButton.BackgroundTransparency = 0.5; CloseButton.ZIndex = 3
local closeCorner = Instance.new("UICorner"); closeCorner.CornerRadius = UDim.new(0, 6); closeCorner.Parent = CloseButton
local closeHoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local closeHoverTween = TweenService:Create(CloseButton, closeHoverInfo, {BackgroundColor3 = Color3.fromRGB(200, 50, 50), BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255, 255, 255)})
local closeUnhoverTween = TweenService:Create(CloseButton, closeHoverInfo, {BackgroundColor3 = Color3.fromRGB(25, 25, 25), BackgroundTransparency = 0.5, TextColor3 = Color3.fromRGB(200, 200, 200)})
CloseButton.MouseEnter:Connect(function() closeHoverTween:Play() end)
CloseButton.MouseLeave:Connect(function() closeUnhoverTween:Play() end)

-- 6. СИСТЕМА ТАБОВ
local TabContainer = Instance.new("Frame"); TabContainer.Name = "TabContainer"; TabContainer.Parent = MenuFrame; TabContainer.Size = UDim2.new(1, 0, 0, 35); TabContainer.Position = UDim2.new(0, 0, 0, 40); TabContainer.BackgroundTransparency = 1
local ContentContainer = Instance.new("Frame"); ContentContainer.Name = "ContentContainer"; ContentContainer.Parent = MenuFrame; ContentContainer.Size = UDim2.new(1, -20, 1, -85); ContentContainer.Position = UDim2.new(0, 10, 0, 75); ContentContainer.BackgroundTransparency = 1
local TabButtonVisuals = Instance.new("TextButton"); TabButtonVisuals.Name = "TabVisuals"; TabButtonVisuals.Parent = TabContainer; TabButtonVisuals.Size = UDim2.new(0, 100, 1, 0); TabButtonVisuals.Position = UDim2.new(0, 10, 0, 0); TabButtonVisuals.Font = Enum.Font.GothamSemibold; TabButtonVisuals.Text = "Visuals"; TabButtonVisuals.TextSize = 16; TabButtonVisuals.TextColor3 = Color3.fromRGB(255, 255, 255); TabButtonVisuals.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local tabVisualsCorner = Instance.new("UICorner", TabButtonVisuals); tabVisualsCorner.CornerRadius = UDim.new(0, 6)
local TabButtonMain = Instance.new("TextButton"); TabButtonMain.Name = "TabMain"; TabButtonMain.Parent = TabContainer; TabButtonMain.Size = UDim2.new(0, 100, 1, 0); TabButtonMain.Position = UDim2.new(0, 115, 0, 0); TabButtonMain.Font = Enum.Font.Gotham; TabButtonMain.Text = "Main"; TabButtonMain.TextSize = 16; TabButtonMain.TextColor3 = Color3.fromRGB(150, 150, 150); TabButtonMain.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
local tabMainCorner = Instance.new("UICorner", TabButtonMain); tabMainCorner.CornerRadius = UDim.new(0, 6)
local VisualsFrame = Instance.new("Frame"); VisualsFrame.Name = "VisualsFrame"; VisualsFrame.Parent = ContentContainer; VisualsFrame.Size = UDim2.new(1, 0, 1, 0); VisualsFrame.BackgroundTransparency = 1; VisualsFrame.Visible = true
local MainFrame = Instance.new("Frame"); MainFrame.Name = "MainFrame"; MainFrame.Parent = ContentContainer; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false
local tabs = {TabButtonVisuals, TabButtonMain}; local pages = {VisualsFrame, MainFrame}
local function switchTab(tabToSelect)
    for i, tab in ipairs(tabs) do
        local page = pages[i]
        if tab == tabToSelect then
            page.Visible = true; tab.Font = Enum.Font.GothamSemibold; tab.TextColor3 = Color3.fromRGB(255, 255, 255); tab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            page.Visible = false; tab.Font = Enum.Font.Gotham; tab.TextColor3 = Color3.fromRGB(150, 150, 150); tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        end
    end
end
TabButtonVisuals.MouseButton1Click:Connect(function() switchTab(TabButtonVisuals) end)
TabButtonMain.MouseButton1Click:Connect(function() switchTab(TabButtonMain) end)

-- --- СЕКЦИЯ ФУНКЦИЙ ---

-- == 7.1. Функция ESP на Таймеры (Твой код) ==
local timerEspToggle = Instance.new("TextButton")
timerEspToggle.Name = "TimerESPToggle"
timerEspToggle.Parent = VisualsFrame -- Во вкладке Visuals
timerEspToggle.Size = UDim2.new(1, 0, 0, 30)
timerEspToggle.Position = UDim2.new(0, 0, 0, 10) -- Позиция (сверху)
timerEspToggle.Font = Enum.Font.GothamSemibold
timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
timerEspToggle.TextSize = 16
timerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
local timerEspToggleCorner = Instance.new("UICorner", timerEspToggle)
timerEspToggleCorner.CornerRadius = UDim.new(0, 8)

local function ToggleTimerESP(state)
    if state == true then
        if isTimerEspActive then return end
        isTimerEspActive = true
        timerEspToggle.Text = "ESP (RemainingTime) [ON]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        
        timerEspFolder = CoreGui:FindFirstChild("ESP_RemainingTimers") or Instance.new("Folder", CoreGui)
        timerEspFolder.Name = "ESP_RemainingTimers"

        local textColor = Color3.fromRGB(0, 255, 255); local textSize = 12; local maxY = 50
        local function isFirstFloor(part) return part and part.Position.Y <= maxY end
        
        local function makeESP(hitbox, sourceText)
            if not hitbox or not sourceText then return end
            local id = sourceText:GetFullName()
            if timerEspFolder:FindFirstChild(id) or not isFirstFloor(hitbox) then return end
            local gui = Instance.new("BillboardGui"); gui.Name = id; gui.Adornee = hitbox; gui.Size = UDim2.new(0, 100, 0, 20); gui.StudsOffset = Vector3.new(0, 3, 0); gui.AlwaysOnTop = true; gui.Parent = timerEspFolder
            local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.TextColor3 = textColor; label.TextStrokeTransparency = 0.5; label.Font = Enum.Font.Gotham; label.TextSize = textSize; label.Text = sourceText.Text; label.Parent = gui
            local propConn, ancConn
            propConn = sourceText:GetPropertyChangedSignal("Text"):Connect(function()
                if label and label.Parent then label.Text = sourceText.Text
                else
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)
            ancConn = sourceText.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if gui then gui:Destroy() end
                    if propConn then propConn:Disconnect() end
                    if ancConn then ancConn:Disconnect() end
                end
            end)
            table.insert(timerEspConnections, propConn); table.insert(timerEspConnections, ancConn)
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model"); local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end
        local descConn = Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") and obj.Name == "RemainingTime" then
                local model = obj:FindFirstAncestorWhichIsA("Model"); local hitbox = model and model:FindFirstChild("Hitbox")
                if hitbox then makeESP(hitbox, obj) end
            end
        end)
        table.insert(timerEspConnections, descConn)
    elseif state == false then
        if not isTimerEspActive then return end
        isTimerEspActive = false
        timerEspToggle.Text = "ESP (RemainingTime) [OFF]"
        timerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        for _, conn in ipairs(timerEspConnections) do
            if conn then conn:Disconnect() end
        end
        timerEspConnections = {}
        if timerEspFolder then timerEspFolder:Destroy(); timerEspFolder = nil end
    end
end
timerEspToggle.MouseButton1Click:Connect(function() ToggleTimerESP(not isTimerEspActive) end)


-- == 7.2. *** НОВОЕ: Переключатель Player ESP (только GUI) *** ==
local playerEspToggle = Instance.new("TextButton")
playerEspToggle.Name = "PlayerESPToggle"
playerEspToggle.Parent = VisualsFrame -- Также во вкладке Visuals
playerEspToggle.Size = UDim2.new(1, 0, 0, 30)
playerEspToggle.Position = UDim2.new(0, 0, 0, 50) -- Позиция (ниже первой кнопки)
playerEspToggle.Font = Enum.Font.GothamSemibold
playerEspToggle.Text = "Player ESP [OFF]"
playerEspToggle.TextSize = 16
playerEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
local playerEspToggleCorner = Instance.new("UICorner", playerEspToggle)
playerEspToggleCorner.CornerRadius = UDim.new(0, 8)

-- Это "пустая" функция. Сюда нужно будет вставить сам код ESP.
local function TogglePlayerESP(state)
    if state == true then
        -- --- ВКЛЮЧАЕМ PLAYER ESP ---
        if isPlayerEspActive then return end
        isPlayerEspActive = true
        playerEspToggle.Text = "Player ESP [ON]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        
        -- Сюда нужно вставить код, который создает Player ESP
        -- (Например, создает папку в CoreGui и запускает цикл RenderStepped)
        print("Player ESP включен (концепт)")
        
    elseif state == false then
        -- --- ВЫКЛЮЧАЕМ PLAYER ESP ---
        if not isPlayerEspActive then return end
        isPlayerEspActive = false
        playerEspToggle.Text = "Player ESP [OFF]"
        playerEspToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        
        -- Сюда нужно вставить код, который отключает ESP
        -- (Например, отключает сигнал RenderStepped и удаляет папку из CoreGui)
        print("Player ESP выключен (концепт)")
    end
end

-- Подключаем функцию к кнопке
playerEspToggle.MouseButton1Click:Connect(function()
    TogglePlayerESP(not isPlayerEspActive)
end)


-- --- ГЛАВНАЯ ЛОГИКА АНИМАЦИЙ (Open/Close) ---
-- (Здесь код для OpenButton.MouseButton1Click, .MouseEnter, .MouseLeave... он не изменился)
-- ...
local animationInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local closedPosition = UDim2.new(-0.5, 0, 0.5, 0); local openPosition = UDim2.new(0.02, 70, 0.5, 0)
local openTween = TweenService:Create(MenuFrame, animationInfo, {Position = openPosition})
local closeTween = TweenService:Create(MenuFrame, animationInfo, {Position = closedPosition})
local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local originalBtnColor = OpenButton.BackgroundColor3; local hoverBtnColor = Color3.fromRGB(60, 60, 60)
local hoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = hoverBtnColor})
local unhoverTween = TweenService:Create(OpenButton, hoverInfo, {BackgroundColor3 = originalBtnColor})
OpenButton.MouseEnter:Connect(function() hoverTween:Play() end)
OpenButton.MouseLeave:Connect(function() unhoverTween:Play() end)
OpenButton.MouseButton1Click:Connect(function()
    if isOpen then closeTween:Play(); isOpen = false else openTween:Play(); isOpen = true end
end)

-- --- ЛОГИКА ЗАКРЫТИЯ (КРЕСТИК) ---
CloseButton.MouseButton1Click:Connect(function()
    -- Выключаем ВСЕ функции перед закрытием
    ToggleTimerESP(false)
    TogglePlayerESP(false)
    
    MyScreenGui:Destroy()
end)

MyScreenGui.Destroying:Connect(function()
    -- Безопасная очистка на случай, если GUI удалят иначе
    ToggleTimerESP(false)
    TogglePlayerESP(false)
end)
