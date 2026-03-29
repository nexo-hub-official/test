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

-- WindUI integration
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Nexo Hub",
    Icon = "crosshair",
    Author = "Combat Suite",
    Folder = "NexoHub",
    Size = UDim2.fromOffset(520, 410),
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true
})

local Main = Window:Tab({
    Title = "Home",
    Icon = "home"
})

Main:Section({
    Title = "Combat"
})

Main:Toggle({
    Title = "Aimlock",
    Value = false,
    Callback = function(v)
        setAimlockEnabled(v)
    end
})

Main:Toggle({
    Title = "Triggerbot",
    Value = false,
    Callback = function(v)
        setTriggerEnabled(v)
    end
})

Main:Section({
    Title = "Visuals"
})

Main:Toggle({
    Title = "ESP",
    Value = false,
    Callback = function(v)
        setESPEnabled(v)
    end
})

Main:Toggle({
    Title = "Show FOV",
    Value = false,
    Callback = function(v)
        setFOVEnabled(v)
    end
})

Main:Section({
    Title = "Safety"
})

Main:Button({
    Title = "Turn Everything Off",
    Callback = function()
        disableAllFeatures()
        WindUI:Notify({
            Title = "Nexo Hub",
            Content = "All features are now OFF",
            Duration = 3
        })
    end
})

WindUI:Notify({
    Title = "Nexo Hub",
    Content = "WindUI loaded and linked",
    Duration = 3
})
