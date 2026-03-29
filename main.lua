-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings (Enabled by default)
local SETTINGS = {
	Smoothing = 0.15,
	Prediction = 0.135,
	FOV_Radius = 150,
	FOV_Color = Color3.fromRGB(255, 0, 0),
	LockKey = Enum.KeyCode.E,
	TriggerActive = false,
	FireDelay = 0.2,
	ESPEnabled = false,
	ShowFOV = false
}

local lockOn = false
local lastShot = 0

-- FOV Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Radius = SETTINGS.FOV_Radius
FOVCircle.Filled = false
FOVCircle.Visible = SETTINGS.ShowFOV
FOVCircle.Color = SETTINGS.FOV_Color
FOVCircle.Transparency = 0.7

local function setAimlockEnabled(state)
	lockOn = state
end

local function setTriggerEnabled(state)
	SETTINGS.TriggerActive = state
end

local function setFOVEnabled(state)
	SETTINGS.ShowFOV = state
	FOVCircle.Visible = state
end

local function setESPEnabled(state)
	SETTINGS.ESPEnabled = state
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local highlight = p.Character:FindFirstChild("CoreESP")
			if highlight then
				highlight.Enabled = state
			end
		end
	end
end

local function disableAllFeatures()
	setAimlockEnabled(false)
	setTriggerEnabled(false)
	setFOVEnabled(false)
	setESPEnabled(false)
end

-- Target Acquisition
local function getPrediction(part)
	if part.Parent:FindFirstChild("HumanoidRootPart") then
		return part.Position + (part.Parent.HumanoidRootPart.Velocity * SETTINGS.Prediction)
	end
	return part.Position
end

local function isVisible(part)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, Camera}
	local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
	return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function getBestTarget()
	local bestTarget, shortestDist = nil, math.huge
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
			local head = p.Character.Head
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			
			if hum and hum.Health > 0 and isVisible(head) then
				local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
				local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
				
				if onScreen and distFromCenter <= SETTINGS.FOV_Radius then
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local worldDist = (player.Character.HumanoidRootPart.Position - head.Position).Magnitude
						if worldDist < shortestDist then
							shortestDist = worldDist
							bestTarget = head
						end
					end
				end
			end
		end
	end
	return bestTarget
end

-- Aim & Combat
RunService.RenderStepped:Connect(function()
	FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	
	if not player.Character then return end

	if lockOn then
		local target = getBestTarget()
		if target then
			-- Aimlock
			local lookAt = CFrame.new(Camera.CFrame.Position, getPrediction(target))
			Camera.CFrame = Camera.CFrame:Lerp(lookAt, SETTINGS.Smoothing)
			
			-- Triggerbot
			if SETTINGS.TriggerActive and (tick() - lastShot) >= SETTINGS.FireDelay then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = {player.Character, Camera}
				local res = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 1000, params)
				
				if res and res.Instance:IsDescendantOf(target.Parent) then
					lastShot = tick()
					if mouse1click then mouse1click() end
				end
			end
		end
	end
end)

-- Input Handling
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == SETTINGS.LockKey then 
		lockOn = not lockOn 
	end
end)

-- ESP System
local function applyESP(p)
	if p == player then return end
	
	local function updateESP()
		local char = p.Character
		if char and char:FindFirstChild("Humanoid") then
			local highlight = char:FindFirstChild("CoreESP") or Instance.new("Highlight")
			highlight.Name = "CoreESP"
			highlight.FillColor = Color3.fromRGB(60, 160, 255)
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Enabled = SETTINGS.ESPEnabled
			highlight.Parent = char
		end
	end

	RunService.Heartbeat:Connect(updateESP)
end

Players.PlayerAdded:Connect(applyESP)
for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end

-- Integrated from gui.lua
do
    -- [[ SERVICES ]]
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")

    -- [[ THEME ]]
    local THEME = {
    	Background    = Color3.fromRGB(12, 12, 18),
    	Sidebar       = Color3.fromRGB(18, 20, 28),
    	Content       = Color3.fromRGB(22, 24, 32),
    	Accent        = Color3.fromRGB(0, 140, 255),
    	AccentDim     = Color3.fromRGB(0, 90, 180),
    	TextMain      = Color3.fromRGB(255, 255, 255),
    	TextDim       = Color3.fromRGB(160, 160, 180),
    	Stroke        = Color3.fromRGB(45, 50, 65),
    	FontBold      = Enum.Font.GothamBold,
    	FontSemi      = Enum.Font.GothamMedium,
    	FontReg       = Enum.Font.Gotham,
    	CornerRadius  = 12
    }

    -- [[ UTILS ]]
    local Library = {}
    local UI_OPEN = false

    local function create(class, props)
    	local inst = Instance.new(class)
    	for k, v in pairs(props) do inst[k] = v end
    	return inst
    end

    local function addCorner(parent, radius)
    	create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = parent})
    end

    local function addStroke(parent, color, thickness)
    	return create("UIStroke", {
    		Color = color, Thickness = thickness,
    		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent
    	})
    end

    local function makeDraggable(trigger, target)
    	local dragging, dragInput, dragStart, startPos
    	trigger.InputBegan:Connect(function(input)
    		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    			dragging, dragStart, startPos = true, input.Position, target.Position
    			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    		end
    	end)
    	trigger.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    	UserInputService.InputChanged:Connect(function(input)
    		if input == dragInput and dragging then
    			local delta = input.Position - dragStart
    			TweenService:Create(target, TweenInfo.new(0.08), {
    				Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    			}):Play()
    		end
    	end)
    end

    -- [[ CORE LIBRARY ]]

    function Library:Init()
    	local parent = (RunService:IsStudio() and Players.LocalPlayer:WaitForChild("PlayerGui")) or CoreGui
    	if parent:FindFirstChild("NexoHubUI") then parent.NexoHubUI:Destroy() end
    	
    	local ScreenGui = create("ScreenGui", {Name = "NexoHubUI", ResetOnSpawn = false, Parent = parent})
    	
    	-- [[ NOTIFICATIONS - BOTTOM RIGHT ]]
    	local NotifContainer = create("Frame", {
    		Name = "Notifications", Size = UDim2.new(0, 320, 1, -40),
    		Position = UDim2.new(1, -340, 0, 20), BackgroundTransparency = 1, Parent = ScreenGui
    	})
    	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), Parent = NotifContainer})

    	function Library:Notify(title, text)
    		local N = create("Frame", {
    			Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = THEME.Sidebar,
    			BackgroundTransparency = 0.05, Parent = NotifContainer
    		})
    		addCorner(N, 10)
    		local NStroke = addStroke(N, THEME.Stroke, 1.5)
    		
    		create("UIGradient", {
    			Color = ColorSequence.new{
    				ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 28, 38)),
    				ColorSequenceKeypoint.new(1, THEME.Sidebar)
    			}, Rotation = 45, Parent = N
    		})
    		
    		local IconBg = create("Frame", {
    			Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(0, 10, 0.5, -17.5),
    			BackgroundColor3 = Color3.fromRGB(30, 35, 45), Parent = N
    		})
    		addCorner(IconBg, 8)
    		local IconInd = create("Frame", {
    			Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0.5, -5, 0.5, -5),
    			BackgroundColor3 = THEME.Accent, Parent = IconBg
    		})
    		addCorner(IconInd, 10)
    		create("UIStroke", {Color = THEME.Accent, Thickness = 1, Parent = IconInd})

    		create("TextLabel", {
    			Text = title, Font = THEME.FontBold, TextSize = 13, TextColor3 = THEME.TextMain,
    			Position = UDim2.new(0, 55, 0, 10), Size = UDim2.new(1, -60, 0, 15),
    			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = N
    		})
    		create("TextLabel", {
    			Text = text, Font = THEME.FontReg, TextSize = 12, TextColor3 = THEME.TextDim,
    			Position = UDim2.new(0, 55, 0, 28), Size = UDim2.new(1, -60, 0, 15),
    			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = N
    		})
    		
    		N.Position = UDim2.new(1, 50, 0, 0) 
    		TweenService:Create(N, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
    		TweenService:Create(NStroke, TweenInfo.new(0.5), {Color = THEME.AccentDim}):Play()
    		
    		task.delay(3.5, function()
    			TweenService:Create(N, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, 0, 0)}):Play()
    			task.wait(0.5) N:Destroy()
    		end)
    	end

    	-- 1. Main Structure
    	local ShadowHolder = create("Frame", {
    		Name = "Shadow", Size = UDim2.new(0, 680, 0, 460), Position = UDim2.fromScale(0.5, 0.5),
    		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = ScreenGui
    	})
    	
    	local MainScale = create("UIScale", {Scale = 0, Parent = ShadowHolder})
    	
    	local MainFrame = create("Frame", {
    		Name = "MainFrame", Size = UDim2.fromScale(1, 1),
    		BackgroundColor3 = THEME.Background, Parent = ShadowHolder
    	})
    	addCorner(MainFrame, THEME.CornerRadius)
    	
    	local MainStroke = addStroke(MainFrame, THEME.Stroke, 2)
    	local StrokeGradient = create("UIGradient", {
    		Color = ColorSequence.new{
    			ColorSequenceKeypoint.new(0, THEME.Accent),
    			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 220)),
    			ColorSequenceKeypoint.new(1, THEME.Accent)
    		},
    		Rotation = 45, Parent = MainStroke
    	})
    	
    	task.spawn(function()
    		while MainFrame.Parent do
    			TweenService:Create(StrokeGradient, TweenInfo.new(3, Enum.EasingStyle.Linear), {Rotation = StrokeGradient.Rotation + 180}):Play()
    			task.wait(3)
    		end
    	end)

    	makeDraggable(MainFrame, ShadowHolder)

    	local PADDING = 14
    	local SIDEBAR_WIDTH = 170

    	-- 2. Sidebar
    	local Sidebar = create("Frame", {
    		Name = "Sidebar", 
    		Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -(PADDING * 2)),
    		Position = UDim2.new(0, PADDING, 0, PADDING),
    		BackgroundColor3 = THEME.Sidebar, Parent = MainFrame
    	})
    	addCorner(Sidebar, THEME.CornerRadius)
    	
    	local LogoContainer = create("Frame", {
    		Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1, Parent = Sidebar
    	})
    	
    	local LogoText = create("TextLabel", {
    		Text = "NEXO HUB", Font = THEME.FontBold, TextSize = 24, TextColor3 = Color3.new(1,1,1),
    		Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
    		TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 1, Parent = LogoContainer
    	})
    	
    	create("UIGradient", {Color = ColorSequence.new{
    		ColorSequenceKeypoint.new(0, THEME.Accent), 
    		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 220, 255))
    	}, Rotation = 0, Parent = LogoText})
    	
    	local TabContainer = create("ScrollingFrame", {
    		Size = UDim2.new(1, 0, 1, -115), Position = UDim2.new(0, 0, 0, 65),
    		BackgroundTransparency = 1, ScrollBarThickness = 0, Parent = Sidebar
    	})
    	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = TabContainer})
    	create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = TabContainer})

    	local UserFrame = create("Frame", {
    		Size = UDim2.new(1, -20, 0, 45), Position = UDim2.new(0, 10, 1, -55),
    		BackgroundColor3 = THEME.Background, Parent = Sidebar
    	})
    	addCorner(UserFrame, 10)
    	addStroke(UserFrame, THEME.Stroke, 1)
    	
    	local Avatar = create("ImageLabel", {
    		Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 8, 0.5, -14),
    		BackgroundColor3 = THEME.Content, Image = "rbxassetid://0", Parent = UserFrame
    	})
    	addCorner(Avatar, 28)
    	create("TextLabel", {
    		Text = Players.LocalPlayer.Name, Font = THEME.FontSemi, TextSize = 12, TextColor3 = THEME.TextMain,
    		Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -45, 1, 0),
    		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = UserFrame
    	})
    	task.spawn(function() Avatar.Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)

    	-- 3. Content Area
    	local ContentX = PADDING + SIDEBAR_WIDTH + PADDING
    	local ContentArea = create("Frame", {
    		Name = "Content", 
    		Size = UDim2.new(1, -(ContentX + PADDING), 1, -(PADDING * 2)), 
    		Position = UDim2.new(0, ContentX, 0, PADDING),
    		BackgroundColor3 = THEME.Content, Parent = MainFrame
    	})
    	addCorner(ContentArea, THEME.CornerRadius)
    	
    	-- 4. Toggle Button
    	local ToggleBtn = create("TextButton", {
    		Size = UDim2.fromOffset(45, 45), Position = UDim2.new(0, 20, 0.5, -22),
    		BackgroundColor3 = THEME.Sidebar, Text = "N", TextColor3 = THEME.Accent,
    		Font = THEME.FontBold, TextSize = 22, AutoButtonColor = false, Parent = ScreenGui
    	})
    	addCorner(ToggleBtn, 12)
    	addStroke(ToggleBtn, THEME.Accent, 2)
    	makeDraggable(ToggleBtn, ToggleBtn)

    	ToggleBtn.MouseButton1Click:Connect(function()
    		UI_OPEN = not UI_OPEN
    		if UI_OPEN then
    			MainFrame.Visible = true
    			TweenService:Create(MainScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    			TweenService:Create(MainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    		else
    			TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0}):Play()
    			task.delay(0.3, function() if not UI_OPEN then MainFrame.Visible = false end end)
    		end
    	end)

    	-- [[ TABS SYSTEM ]]
    	local Tabs = {}
    	
    	function Library:AddTab(name)
    		local Tab = {}
    		
    		local TabBtn = create("TextButton", {
    			Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1,
    			Text = name, TextColor3 = THEME.TextDim, 
    			Font = THEME.FontSemi, TextSize = 14, 
    			TextXAlignment = Enum.TextXAlignment.Center,
    			AutoButtonColor = false, Parent = TabContainer
    		})
    		addCorner(TabBtn, 8)
    		
    		local Page = create("ScrollingFrame", {
    			Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
    			BackgroundTransparency = 1, ScrollBarThickness = 0,
    			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0),
    			Visible = false, Parent = ContentArea
    		})
    		create("UIPadding", {PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), Parent = Page})
    		create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = Page})
    		
    		TabBtn.MouseButton1Click:Connect(function()
    			for _, t in pairs(Tabs) do
    				TweenService:Create(t.Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = THEME.TextDim}):Play()
    				t.Page.Visible = false
    			end
    			TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0, BackgroundColor3 = THEME.Background, TextColor3 = THEME.Accent}):Play()
    			Page.Visible = true
    		end)
    		
    		table.insert(Tabs, {Btn = TabBtn, Page = Page})
    		
    		if #Tabs == 1 then
    			TabBtn.BackgroundTransparency = 0
    			TabBtn.BackgroundColor3 = THEME.Background
    			TabBtn.TextColor3 = THEME.Accent
    			Page.Visible = true
    		end
    		
    		-- [[ COMPONENTS ]]
    		
    		function Tab:AddSection(text)
    			local S = create("Frame", {
    				Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Parent = Page
    			})
    			create("TextLabel", {
    				Text = text, Font = THEME.FontBold, TextSize = 14, TextColor3 = THEME.Accent,
    				Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
    				TextYAlignment = Enum.TextYAlignment.Bottom, BackgroundTransparency = 1, Parent = S
    			})
    		end
    		
    		function Tab:AddButton(text, callback)
    			local Btn = create("TextButton", {
    				Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = THEME.Background,
    				Text = text, TextColor3 = THEME.TextMain, Font = THEME.FontSemi, TextSize = 13,
    				AutoButtonColor = false, Parent = Page
    			})
    			addCorner(Btn, 10)
    			local Stroke = addStroke(Btn, THEME.Stroke, 1)
    			
    			Btn.MouseEnter:Connect(function() 
    				TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = THEME.Accent}):Play()
    				TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 30, 38)}):Play()
    			end)
    			Btn.MouseLeave:Connect(function() 
    				TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = THEME.Stroke}):Play() 
    				TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Background}):Play()
    			end)
    			Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    		end
    		
    		function Tab:AddToggle(text, bind, callback)
    			local State = false
    			local TglBtn = create("TextButton", {
    				Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = THEME.Background,
    				Text = "", AutoButtonColor = false, Parent = Page
    			})
    			addCorner(TglBtn, 10)
    			addStroke(TglBtn, THEME.Stroke, 1)
    			
    			create("TextLabel", {
    				Text = text, Font = THEME.FontReg, TextSize = 13, TextColor3 = THEME.TextMain,
    				Size = UDim2.new(0.7, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0),
    				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = TglBtn
    			})
    			
    			local SwitchBg = create("Frame", {
    				Size = UDim2.new(0, 36, 0, 20), Position = UDim2.new(1, -48, 0.5, -10),
    				BackgroundColor3 = Color3.fromRGB(15,15,20), Parent = TglBtn
    			})
    			addCorner(SwitchBg, 20)
    			local SwitchStroke = addStroke(SwitchBg, THEME.Stroke, 1)
    			
    			local Dot = create("Frame", {
    				Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 2, 0.5, -8),
    				BackgroundColor3 = THEME.TextDim, Parent = SwitchBg
    			})
    			addCorner(Dot, 16)
    			
    			local function Toggle()
    				State = not State
    				local targetPos = State and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    				TweenService:Create(Dot, TweenInfo.new(0.2), {Position = targetPos, BackgroundColor3 = State and THEME.Accent or THEME.TextDim}):Play()
    				TweenService:Create(SwitchStroke, TweenInfo.new(0.2), {Color = State and THEME.Accent or THEME.Stroke}):Play()
    				if callback then callback(State) end
    			end

    			TglBtn.MouseButton1Click:Connect(Toggle)
    			if bind then
    				UserInputService.InputBegan:Connect(function(input, gpe)
    					if not gpe and input.KeyCode == bind then Toggle() end
    				end)
    			end
    		end

    		return Tab
    	end
    	
    	return Library
    end

    -- [[ EXECUTION ]]

    local UI = Library:Init()

    local Main = UI:AddTab("Home")
    Main:AddSection("Combat")
    Main:AddToggle("Aimlock", nil, function(v)
    	setAimlockEnabled(v)
    end)
    Main:AddToggle("Triggerbot", nil, function(v)
    	setTriggerEnabled(v)
    end)

    Main:AddSection("Visuals")
    Main:AddToggle("ESP", nil, function(v)
    	setESPEnabled(v)
    end)
    Main:AddToggle("Show FOV", nil, function(v)
    	setFOVEnabled(v)
    end)

    Main:AddSection("Safety")
    Main:AddButton("Turn Everything Off", function()
    	disableAllFeatures()
    	Library:Notify("Nexo Hub", "All features are now OFF")
    end)

    Library:Notify("Nexo Hub", "Template GUI is now fully linked")
end
