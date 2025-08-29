-- LocalScript в StarterPlayerScripts

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local SPIN_SPEED = 1
local spinning   = false
local running    = true
local connections = {}
local spinLoop

-- Безопасное подключение событий
local function bind(event, fn)
    local conn = event:Connect(function(...)
        if running then
            fn(...)
        end
    end)
    table.insert(connections, conn)
    return conn
end

-- Запускает цикл вращения для данного персонажа
local function startSpinFor(character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp      = character:WaitForChild("HumanoidRootPart")
    spinLoop = RunService.Heartbeat:Connect(function()
        if spinning and character.Parent then
            local dir = humanoid.MoveDirection
            if dir.Magnitude > 0 then
                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
                            * CFrame.Angles(0, math.rad(SPIN_SPEED), 0)
            end
        end
    end)
end

-- Включает вращение
local function startSpinning()
    if spinning then return end
    spinning = true
    if player.Character then
        startSpinFor(player.Character)
    end
end

-- Выключает вращение
local function stopSpinning()
    spinning = false
    if spinLoop then
        spinLoop:Disconnect()
        spinLoop = nil
    end
end

-- При респавне персонажа, если спин включён, перезапускаем цикл
bind(player.CharacterAdded, function(char)
    if spinning then
        if spinLoop then
            spinLoop:Disconnect()
            spinLoop = nil
        end
        startSpinFor(char)
    end
end)

-- === GUI ===
local gui = Instance.new("ScreenGui")
gui.Name         = "SpinGui"
gui.ResetOnSpawn = false
gui.Parent       = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Name             = "MainFrame"
frame.Size             = UDim2.new(0, 240, 0, 80)
frame.Position         = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
frame.BorderSizePixel  = 0

local outline = Instance.new("UIStroke", frame)
outline.Thickness    = 2
outline.Color        = Color3.fromRGB(255, 0, 0)
outline.Transparency = 0.4

-- Заголовок (драг и кнопка закрыть)
local header = Instance.new("Frame", frame)
header.Name                = "Header"
header.Size                = UDim2.new(1, 0, 0, 24)
header.Position            = UDim2.new(0, 0, 0, 0)
header.BackgroundTransparency = 1
header.Active              = true

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Text                   = "▢ SPIN SCRIPT"
titleLabel.Size                   = UDim2.new(1, -32, 1, 0)
titleLabel.Position               = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3             = Color3.fromRGB(255, 0, 0)
titleLabel.Font                   = Enum.Font.Code
titleLabel.TextSize               = 18
titleLabel.TextXAlignment         = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Name             = "CloseBtn"
closeBtn.Text             = "✕"
closeBtn.Size             = UDim2.new(0, 24, 0, 24)
closeBtn.Position         = UDim2.new(1, -28, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
closeBtn.BorderSizePixel  = 0
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.Font             = Enum.Font.Code
closeBtn.TextSize         = 18

-- Кнопка вкл/выкл спина
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Name             = "ToggleBtn"
toggleBtn.Text             = "SPIN: OFF"
toggleBtn.Size             = UDim2.new(0, 200, 0, 30)
toggleBtn.Position         = UDim2.new(0, 20, 0, 28)
toggleBtn.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
toggleBtn.BorderSizePixel  = 0
toggleBtn.TextColor3       = Color3.fromRGB(255, 0, 0)
toggleBtn.Font             = Enum.Font.Code
toggleBtn.TextSize         = 18

-- Переключатель спина
bind(toggleBtn.MouseButton1Click, function()
    if spinning then
        toggleBtn.Text             = "SPIN: OFF"
        toggleBtn.TextColor3       = Color3.fromRGB(255, 0, 0)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
        stopSpinning()
    else
        toggleBtn.Text             = "SPIN: ON"
        toggleBtn.TextColor3       = Color3.fromRGB(0, 255, 0)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
        startSpinning()
    end
end)

-- Обработка закрытия окна
bind(closeBtn.MouseButton1Click, function()
    running = false
    if spinning then
        stopSpinning()
    end
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    gui:Destroy()
    script:Destroy()
end)

-- Логика перетаскивания окна
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

bind(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

bind(header.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

bind(UserInputService.InputChanged, function(input)
    if dragging and input == dragInput then
        updateDrag(input)
    end
end)

-- Псевдо-фликер обводки
task.spawn(function()
    while running and RunService.Heartbeat:Wait() do
        outline.Transparency = 0.3 + math.noise(tick() * 5) * 0.2
    end
end)
