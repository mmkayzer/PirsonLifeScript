local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local UserInputService = game:GetService("UserInputService") 
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer 
local Camera = workspace.CurrentCamera 

-- Базовые конфигурации
_G.Disabled = false 
_G.AimBot = false 
_G.ShowTracers = true 
_G.ShowESP = true
_G.FOV_Radius = 90 
_G.AimSmoothness = 0.1 
_G.CustomSpeed = 16
_G.AimPart = "HumanoidRootPart" 

-- Премиум настройки
_G.AimTeamFilter = "All" 
_G.AimTargetName = "" 
_G.WallCheck = true 
_G.RainbowMode = false 
_G.RMB_Lock = true 
_G.TriggerBot = false 
_G.IgnoreFriends = true 

local tracers = {} 
local distanceLabels = {}
local highlights = {}
local isRightClickPressed = false
local scriptConnections = {}

-- Создание круга FOV (Белый цвет)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Radius = _G.FOV_Radius
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = true
FOVCircle.Transparency = 0.7

-- Отслеживание ввода мыши
local inputBegan = UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClickPressed = true
	end
end)
table.insert(scriptConnections, inputBegan)

local inputEnded = UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClickPressed = false
	end
end)
table.insert(scriptConnections, inputEnded)

-- Функция цвета (Строгий монохром + RGB режим если включен)
local function getTeamColor(player)
	if _G.RainbowMode then return Color3.fromHSV(tick() % 5 / 5, 1, 1) end
	if player.Team then
		local teamName = player.Team.Name
		if teamName == "Guards" then return Color3.fromRGB(100, 150, 255)
		elseif teamName == "Inmates" then return Color3.fromRGB(200, 140, 90)
		elseif teamName == "Criminals" then return Color3.fromRGB(255, 100, 100)
		end
	end
	return Color3.fromRGB(240, 240, 240)
end

-- Создание ИНТЕРФЕЙСА
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EmptyDev_Scripts"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- КВАДРАТНАЯ КНОПКА ДЛЯ ТЕЛЕФОНОВ (с мягкими углами)
local MobileToggleBtn = Instance.new("TextButton")
MobileToggleBtn.Size = UDim2.new(0, 48, 0, 48)
MobileToggleBtn.Position = UDim2.new(0, 20, 0.4, 0)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MobileToggleBtn.Text = "E"
MobileToggleBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
MobileToggleBtn.Font = Enum.Font.GothamBold
MobileToggleBtn.TextSize = 20
MobileToggleBtn.Active = true
MobileToggleBtn.Draggable = true
MobileToggleBtn.Parent = ScreenGui

Instance.new("UICorner", MobileToggleBtn).CornerRadius = UDim.new(0, 10) -- Квадратная с скруглением
local MobileStroke = Instance.new("UIStroke")
MobileStroke.Color = Color3.fromRGB(60, 60, 65)
MobileStroke.Thickness = 1.5
MobileStroke.Parent = MobileToggleBtn

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 600)
MainFrame.Position = UDim2.new(0.5, -180, 0.25, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12) -- Глубокий черный
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 65) -- Серая стильная обводка
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Открытие/скрытие меню по нажатию на мобильную кнопку
MobileToggleBtn.MouseButton1Click:Connect(function()
	if MainFrame then
		MainFrame.Visible = not MainFrame.Visible
	end
end)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.65, 0, 1, 0)
Title.Position = UDim2.new(0, 16)
Title.BackgroundTransparency = 1
Title.Text = "EmptyDev Scripts"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- КНОПКА СВЕРНУТЬ (_)
local CollapseBtn = Instance.new("TextButton")
CollapseBtn.Size = UDim2.new(0, 32, 0, 32)
CollapseBtn.Position = UDim2.new(1, -85, 0.5, -16)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
CollapseBtn.Text = "_"
CollapseBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
CollapseBtn.Font = Enum.Font.GothamBold
CollapseBtn.TextSize = 16
CollapseBtn.Parent = Header
Instance.new("UICorner", CollapseBtn).CornerRadius = UDim.new(0, 8)

-- КНОПКА ЗАКРЫТИЯ (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -45, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local Elements = Instance.new("ScrollingFrame")
Elements.Size = UDim2.new(1, -20, 1, -65)
Elements.Position = UDim2.new(0, 10, 0, 55)
Elements.BackgroundTransparency = 1
Elements.BorderSizePixel = 0
Elements.ScrollBarThickness = 2
Elements.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 105)
Elements.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = Elements

-- Функция самоуничтожения
local function selfDestruct()
	_G.Disabled = true
	_G.AimBot = false
	pcall(function() FOVCircle.Visible = false; FOVCircle:Remove() end)
	
	for _, connection in ipairs(scriptConnections) do
		if connection then connection:Disconnect() end
	end
	
	for _, p in ipairs(Players:GetPlayers()) do
		if tracers[p] then tracers[p]:Remove() end
		if distanceLabels[p] then distanceLabels[p]:Remove() end
		if highlights[p] then highlights[p]:Destroy() end
	end
	
	TweenService:Create(MainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 360, 0, 0), BackgroundTransparency = 1}):Play()
	task.wait(0.25)
	ScreenGui:Destroy()
end
CloseBtn.MouseButton1Click:Connect(selfDestruct)

-- Сворачивание
local isCollapsed = false
CollapseBtn.MouseButton1Click:Connect(function()
	isCollapsed = not isCollapsed
	local targetHeight = isCollapsed and 50 or 600
	CollapseBtn.Text = isCollapsed and "[]" or "_"
	TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, targetHeight)}):Play()
end)

-- Конструкторы элементов меню (в черно-белой гамме)
local function createToggle(text, startState, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -5, 0, 36)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Elements

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.7, 0, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(210, 210, 215)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0, 46, 0, 20)
	Button.Position = UDim2.new(1, -50, 0.5, -10)
	-- Белый цвет при включении, темно-серый при выключении
	Button.BackgroundColor3 = startState and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(25, 25, 30)
	Button.Text = ""
	Button.Parent = Frame
	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)

	Button.MouseButton1Click:Connect(function()
		startState = not startState
		TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = startState and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(25, 25, 30)}):Play()
		callback(startState)
	end)
end

local function createSlider(text, min, max, start, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -5, 0, 48)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Elements

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, 16)
	Label.BackgroundTransparency = 1
	Label.Text = text .. ": " .. tostring(start)
	Label.TextColor3 = Color3.fromRGB(210, 210, 215)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame

	local SliderBar = Instance.new("Frame")
	SliderBar.Size = UDim2.new(1, 0, 0, 4)
	SliderBar.Position = UDim2.new(0, 0, 0, 24)
	SliderBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	SliderBar.BorderSizePixel = 0
	SliderBar.Parent = Frame
	Instance.new("UICorner", SliderBar)

	local SliderFill = Instance.new("Frame")
	SliderFill.Size = UDim2.new((start - min) / (max - min), 0, 1, 0)
	SliderFill.BackgroundColor3 = Color3.fromRGB(200, 200, 205)
	SliderFill.BorderSizePixel = 0
	SliderFill.Parent = SliderBar
	Instance.new("UICorner", SliderFill)

	local SliderBtn = Instance.new("TextButton")
	SliderBtn.Size = UDim2.new(0, 12, 0, 12)
	SliderBtn.Position = UDim2.new((start - min) / (max - min), -6, 0.5, -6)
	SliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SliderBtn.Text = ""
	SliderBtn.Parent = SliderBar
	Instance.new("UICorner", SliderBtn)

	local dragging = false
	SliderBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)

	local function update()
		local mousePos = UserInputService:GetMouseLocation().X
		local barX = SliderBar.AbsolutePosition.X
		local barWidth = SliderBar.AbsoluteSize.X
		local percentage = math.clamp((mousePos - barX) / barWidth, 0, 1)
		local value = min + (max - min) * percentage
		if min < 1 and max <= 1 then value = tonumber(string.format("%.2f", value)) else value = math.floor(value) end
		SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
		SliderBtn.Position = UDim2.new(percentage, -6, 0.5, -6)
		Label.Text = text .. ": " .. tostring(value)
		callback(value)
	end
	local connection = RunService.RenderStepped:Connect(function() if dragging then update() end end)
	table.insert(scriptConnections, connection)
end

-- Селекторы команд и частей тела
local function createTeamSelector()
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -5, 0, 36)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Elements
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.5, 0, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = "Фильтр Команд"
	Label.TextColor3 = Color3.fromRGB(210, 210, 215)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0, 110, 0, 24)
	Button.Position = UDim2.new(1, -115, 0.5, -12)
	Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	Button.Text = "ВСЕ"
	Button.TextColor3 = Color3.fromRGB(240, 240, 245)
	Button.Font = Enum.Font.GothamBold
	Button.TextSize = 11
	Button.Parent = Frame
	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
	local list = {"All", "Guards", "Inmates", "Criminals"}
	local rusText = {All = "ВСЕ", Guards = "ОХРАНА", Inmates = "ЗЕКИ", Criminals = "КРИМИНАЛ"}
	local currentIdx = 1
	Button.MouseButton1Click:Connect(function()
		currentIdx = currentIdx + 1
		if currentIdx > #list then currentIdx = 1 end
		_G.AimTeamFilter = list[currentIdx]
		Button.Text = rusText[_G.AimTeamFilter]
	end)
end

local function createNameTargeter()
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -5, 0, 38)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Elements
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.4, 0, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = "Цель по Нику:"
	Label.TextColor3 = Color3.fromRGB(210, 210, 215)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	local TextBox = Instance.new("TextBox")
	TextBox.Size = UDim2.new(0, 140, 0, 24)
	TextBox.Position = UDim2.new(1, -145, 0.5, -12)
	TextBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	TextBox.Text = ""
	TextBox.PlaceholderText = "Введите ник..."
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.Font = Enum.Font.Gotham
	TextBox.TextSize = 11
	TextBox.Parent = Frame
	Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", TextBox).Color = Color3.fromRGB(45, 45, 50)
	TextBox.FocusLost:Connect(function() _G.AimTargetName = string.lower(TextBox.Text) end)
end

local function createPartSelector()
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -5, 0, 36)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Elements
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.5, 0, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = "Цель Аимбота"
	Label.TextColor3 = Color3.fromRGB(210, 210, 215)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0, 90, 0, 24)
	Button.Position = UDim2.new(1, -95, 0.5, -12)
	Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	Button.Text = "ТЕЛО"
	Button.TextColor3 = Color3.fromRGB(240, 240, 245)
	Button.Font = Enum.Font.GothamBold
	Button.TextSize = 11
	Button.Parent = Frame
	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
	Button.MouseButton1Click:Connect(function()
		if _G.AimPart == "Head" then _G.AimPart = "HumanoidRootPart" Button.Text = "ТЕЛО"
		else _G.AimPart = "Head" Button.Text = "ГОЛОВА" end
	end)
end

-- Сборка элементов панели
createToggle("Авто Настройки (НЕ ОТКЛЮЧАТЬ!)", true, function(v) _G.Disabled = not v end)
createToggle("Аимбот", _G.AimBot, function(v) _G.AimBot = v end)
createToggle("Только видимые (Wall Check)", _G.WallCheck, function(v) _G.WallCheck = v end)
createToggle("Аим на зажатую ПКМ или Тач", _G.RMB_Lock, function(v) _G.RMB_Lock = v end)
createToggle("Авто-Выстрел (TriggerBot)", _G.TriggerBot, function(v) _G.TriggerBot = v end)
createToggle("Игнорировать Друзей (Не Аимит Друга)", _G.IgnoreFriends, function(v) _G.IgnoreFriends = v end)
createPartSelector()
createTeamSelector()
createNameTargeter()
createToggle("Линии Трейсеров до игроков", _G.ShowTracers, function(v) _G.ShowTracers = v end)
createToggle("Свечение ESP игроков", _G.ShowESP, function(v) _G.ShowESP = v end)
createToggle("Радужный RGB Мод интерфейса", _G.RainbowMode, function(v) _G.RainbowMode = v end)
createSlider("Радиус Аим круга", 30, 250, _G.FOV_Radius, function(v) _G.FOV_Radius = v FOVCircle.Radius = v end)
createSlider("Плавность доводки Аима", 0.01, 1, _G.AimSmoothness, function(v) _G.AimSmoothness = v end)
createSlider("Скорость бега персонажа", 16, 120, _G.CustomSpeed, function(v) _G.CustomSpeed = v end)

-- Переключение на RightShift (для ПК)
local toggleKeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift and MainFrame then MainFrame.Visible = not MainFrame.Visible end
end)
table.insert(scriptConnections, toggleKeyConnection)

-- Wall Check
local function isPlayerVisible(targetPart)
	if not _G.WallCheck then return true end
	local origin = Camera.CFrame.Position
	local direction = targetPart.Position - origin
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
	local result = workspace:Raycast(origin, direction, raycastParams)
	return not result
end

-- Поиск цели
local function getClosestPlayerToCursor()
	local closestPlayer = nil
	local shortestDistance = _G.FOV_Radius
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(_G.AimPart) and player.Character:FindFirstChild("Humanoid") then
			if player.Character.Humanoid.Health > 0 then
				if _G.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then continue end
				if _G.AimTargetName ~= "" and not string.find(string.lower(player.Name), _G.AimTargetName) then continue end
				if _G.AimTeamFilter ~= "All" and (player.Team and player.Team.Name or "") ~= _G.AimTeamFilter then continue end
				local part = player.Character[_G.AimPart]
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if mouseDist < shortestDistance then
						if isPlayerVisible(part) then
							shortestDistance = mouseDist
							closestPlayer = player
						end
					end
				end
			end
		end
	end
	return closestPlayer
end

-- Очистка визуалов
local function removeVisuals(player)
	if tracers[player] then tracers[player]:Remove() tracers[player] = nil end
	if distanceLabels[player] then distanceLabels[player]:Remove() distanceLabels[player] = nil end
	if highlights[player] then highlights[player]:Destroy() highlights[player] = nil end
end
Players.PlayerRemoving:Connect(removeVisuals)

-- Исполнительный цикл
local loopConnection = RunService.RenderStepped:Connect(function()
	if _G.Disabled then
		FOVCircle.Visible = false
		for _, p in ipairs(Players:GetPlayers()) do removeVisuals(p) end
		return
	end
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	FOVCircle.Position = center
	
	if _G.RainbowMode then
		local rgb = Color3.fromHSV(tick() % 5 / 5, 1, 1)
		UIStroke.Color = rgb
		FOVCircle.Color = rgb
		CollapseBtn.TextColor3 = rgb
		MobileStroke.Color = rgb
		MobileToggleBtn.TextColor3 = rgb
	else
		UIStroke.Color = Color3.fromRGB(60, 60, 65)
		FOVCircle.Color = Color3.fromRGB(255, 255, 255)
		CollapseBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
		MobileStroke.Color = Color3.fromRGB(60, 60, 65)
		MobileToggleBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
	end
	
	FOVCircle.Visible = _G.AimBot
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = _G.CustomSpeed
	end
	
	for _, v in ipairs(Players:GetPlayers()) do
		if v ~= LocalPlayer then
			if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
				local root = v.Character.HumanoidRootPart
				local color = getTeamColor(v)
				if _G.ShowESP then
					if not highlights[v] then
						local h = Instance.new("Highlight")
						h.FillColor = color
						h.FillTransparency = 0.5
						h.OutlineColor = Color3.new(1,1,1)
						h.Adornee = v.Character
						h.Parent = v.Character
						highlights[v] = h
					else
						highlights[v].FillColor = color
					end
				elseif highlights[v] then
					highlights[v]:Destroy() highlights[v] = nil
				end
				if _G.ShowTracers then
					if not tracers[v] then
						tracers[v] = Drawing.new("Line")
						tracers[v].Thickness = 1.5
						tracers[v].Transparency = 0.8
						distanceLabels[v] = Drawing.new("Text")
						distanceLabels[v].Size = 14
						distanceLabels[v].Center = true
						distanceLabels[v].Outline = true
						distanceLabels[v].Color = Color3.new(1, 1, 1)
					end
					local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
					if onScreen then
						local dist = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
						tracers[v].From = center
						tracers[v].To = Vector2.new(screenPos.X, screenPos.Y)
						tracers[v].Color = color
						tracers[v].Visible = true
						distanceLabels[v].Position = Vector2.new(screenPos.X, screenPos.Y + 12)
						distanceLabels[v].Text = dist .. " studs"
						distanceLabels[v].Color = color
						distanceLabels[v].Visible = true
					else
						tracers[v].Visible = false
						distanceLabels[v].Visible = false
					end
				elseif tracers[v] then
					tracers[v].Visible = false
					distanceLabels[v].Visible = false
				end
			else
				removeVisuals(v)
			end
		end
	end
	
	-- Логика Аима и Триггербота
	if _G.AimBot then
		local canAim = true
		if _G.RMB_Lock and not isRightClickPressed then canAim = false end
		if canAim then
			local closest = getClosestPlayerToCursor()
			if closest and closest.Character and closest.Character:FindFirstChild(_G.AimPart) then
				local targetPart = closest.Character[_G.AimPart]
				local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
				Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.AimSmoothness)
				
				if _G.TriggerBot then
					local mouseTarget = LocalPlayer:GetMouse().Target
					if mouseTarget and mouseTarget:IsDescendantOf(closest.Character) then
						pcall(function() mouse1click() end)
					end
				end
			end
		end
	end
end)

table.insert(scriptConnections, loopConnection)
