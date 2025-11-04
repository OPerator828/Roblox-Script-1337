--[[
    ================================================
    Продвинутый GUI с Табами и Функциями
    (Версия v2 - Финальная + ESP Игроков)
    ================================================
    - Анимированное меню
    - Кнопка "X" (Закрыть и Выгрузить)
    - Система Вкладок (Табов)
    - ESP на таймеры (RemainingTime) с кнопкой Вкл/Выкл
    - ESP на игроков (Имена) с кнопкой Вкл/Выкл
]]

-- --- СЕРВИСЫ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ---
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isOpen = false

-- ESP на таймеры
local isTimerEspActive = false 
local timerEspFolder = nil
local timerEspConnections = {} 

-- [[НОВОЕ]] ESP на игроков
local isPlayerEspActive = false
local playerEspFolder = nil
local playerEspConnections = {}

-- --- СОЗДАНИЕ GUI ---

-- 1. Главный ScreenGui
local MyScreenGui = Instance.new("ScreenGui")
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
