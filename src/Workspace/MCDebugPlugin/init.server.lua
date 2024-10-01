-------------------
--|| Variables ||--
-------------------
RunService = game:GetService('RunService')
UserInput = game:GetService('UserInputService')
PluginGui = game:GetService("PluginGuiService")
LocalizationService = game:GetService('LocalizationService')
CoreGui = game:GetService('CoreGui')
Players = game:GetService('Players')
ContentProvider = game:GetService('ContentProvider')

Util = script:WaitForChild('Util')
Gui = script:WaitForChild('MCDebugGui')
CurrentCam = workspace.CurrentCamera
Player = Players.LocalPlayer

local plugin:Plugin = plugin or getfenv().PluginManager():CreatePlugin(); plugin.Name = "MCDebugPlugin"
Toolbar = plugin:CreateToolbar("MC Debug Plugin")
-------------------
--|| Constants ||--
-------------------
RunTime = 0
GraphWidth = .005
-------------------
--|| Functions ||--
-------------------
createToolbarButton = require(Util.createToolbarButton)
roundpre = function(number,precision) precision = 10^precision; return math.round(number * precision) / precision; end;

function ToolbarEnableMenuButton()
	Gui.Enabled = not Gui.Enabled
	EnableMenuButton:SetActive(Gui.Enabled)
end

function convertToTimer(number)
	local hours = math.floor(number / 3600)
	local minutes = math.floor((number % 3600) / 60)
	local seconds = math.floor(number % 60)

	return string.format("%d:%02d:%02d", hours, minutes, seconds)
end

function NormalizeVector3(vector3:Vector3)
	local length = math.sqrt(vector3.x * vector3.x + vector3.z * vector3.z)  -- only considering x and z for direction
	return Vector3.new(vector3.x / length, vector3.y, vector3.z / length)
end

function RadToDeg(rad:number)
	return rad*180/math.pi
end

function getCameraDirection(forward)
	-- Normalize the forward vector
	local forwardNorm = NormalizeVector3(forward)

	-- Calculate the angle in radians from the X-axis
	local angle = math.atan2(forwardNorm.z, forwardNorm.x)  -- atan2 gives angle in radians
	local degrees = math.deg(angle)  -- Convert angle to degrees for easier comparison

	-- Adjust degrees to be in range [0, 360]
	if degrees < 0 then
		degrees = degrees + 360
	end

	-- Determine direction based on degrees
	if (degrees >= 337.5 or degrees < 22.5) then
		return "East"
	elseif (degrees >= 22.5 and degrees < 67.5) then
		return "North East"
	elseif (degrees >= 67.5 and degrees < 112.5) then
		return "North"
	elseif (degrees >= 112.5 and degrees < 157.5) then
		return "North West"
	elseif (degrees >= 157.5 and degrees < 202.5) then
		return "West"
	elseif (degrees >= 202.5 and degrees < 247.5) then
		return "South West"
	elseif (degrees >= 247.5 and degrees < 292.5) then
		return "South"
	elseif (degrees >= 292.5 and degrees < 337.5) then
		return "South East"
	end
end

function aspect(w:number,h:number): (string,string)
	local dividend,divisor,mode,remainder
	if w == h then return '1:1',"Square"
	else
		if(h>w) then
			dividend  = h;
			divisor   = w;
			mode      ='Portrait';
		elseif w>h then
			dividend   = w;
			divisor    = h;
			mode       = 'Landscape';
		end
		local gcd = -1
		while gcd == -1 do
			remainder = dividend%divisor;
			if(remainder == 0) then
				gcd = divisor;
			else
				dividend  = divisor;
				divisor   = remainder;
			end
			task.wait()
		end
		local hr         = w/gcd;
		local vr         = h/gcd;
		return (hr..':'..vr),mode
	end
end

function calculateAverage(numbers)
	local sum = 0
	local count = #numbers  -- Get the number of elements in the array

	for i = 1, count do
		sum = sum + numbers[i]
	end

	local average = sum / count
	return average
end

function MainInit()
	local function UpdateDisplayText()
		local as,mode = aspect(CurrentCam.ViewportSize.X,CurrentCam.ViewportSize.Y)
		Gui.RightFrame.Display.Text = `Display: {math.ceil(CurrentCam.ViewportSize.X)}x{math.ceil(CurrentCam.ViewportSize.Y)} ({as}) ({mode})`
	end

	local function UpdateCameraTexts()
		local angX,angY,angZ = CurrentCam.CFrame:ToOrientation()
		local focusX,focusY,focusZ = CurrentCam.Focus:ToOrientation()
		angX,angY,angZ = roundpre(RadToDeg(angX),4),roundpre(RadToDeg(angY),4),roundpre(RadToDeg(angZ),4)
		focusX,focusY,focusZ = roundpre(RadToDeg(focusX),4),roundpre(RadToDeg(focusY),4),roundpre(RadToDeg(focusZ),4)

		Gui.LeftFrame.CameraCFrame.Text = `XYZ: {roundpre(CurrentCam.CFrame.X,4)} / {roundpre(CurrentCam.CFrame.Y,4)} / {roundpre(CurrentCam.CFrame.Z,4)}`
		Gui.LeftFrame.CameraAngle.Text = `Angle: {angX} / {angY} / {angZ}`
		Gui.LeftFrame.CameraFocus.Text = `Focus (XYZ): {roundpre(CurrentCam.Focus.X,4)} / {roundpre(CurrentCam.Focus.Y,4)} / {roundpre(CurrentCam.Focus.Z,4)}`
		Gui.LeftFrame.Direction.Text = `Facing: {getCameraDirection(CurrentCam.CFrame.LookVector)} (from LookVector)  FOV: {CurrentCam.FieldOfView}`
	end
	
	task.spawn(UpdateCameraTexts); task.spawn(UpdateDisplayText)
	CurrentCam:GetPropertyChangedSignal('ViewportSize'):Connect(UpdateDisplayText)
	CurrentCam:GetPropertyChangedSignal('CFrame'):Connect(UpdateCameraTexts)

	while Gui and Gui.Parent do
		local FPS = math.ceil(1/RunService.RenderStepped:Wait() + 0.5)
		local HB = RunService.Heartbeat:Wait()
		Gui.LeftFrame.VersionDisplay.Text = `Roblox Studio - {version()} - {RunService:IsEdit() and 'Editing' or 'Running'} - ({game.PlaceVersion}/{LocalizationService.RobloxLocaleId})`
		Gui.LeftFrame.RunService.Text = `{FPS} fps  Ping: {Player and Player:GetNetworkPing() or 0}  T: {math.floor(HB*1000)}ms`
		Gui.LeftFrame.Rendering.Text = `Q: {settings().Rendering.EditQualityLevel.Name} ({settings().Rendering.QualityLevel.Name})  M: {settings().Rendering.GraphicsMode.Name}  MDL: {settings().Rendering.MeshPartDetailLevel.Name}`
		Gui.LeftFrame.Debug.Text = `I: {settings().Diagnostics.InstanceCount}  J: {settings().Diagnostics.JobCount}  P: {settings().Diagnostics.PlayerCount}`
		Gui.LeftFrame.Request.Text = `Queue: {ContentProvider.RequestQueueSize}  Lag: {settings().Network.IncomingReplicationLag}`
		Gui.LeftFrame.osDate.Text = `date: {os.date()}`
		Gui.LeftFrame.osTime.Text = `time: {os.time()} ({math.ceil(tick())})`
		Gui.LeftFrame.osClock.Text = `clock: {roundpre(os.clock(),4)}`
		Gui.LeftFrame.RunTime.Text = `run: {convertToTimer(RunTime)}`
		Gui.RightFrame.Script.Text = `{_VERSION} - {LocalizationService.SystemLocaleId}`
		Gui.RightFrame.Memory.Text = `Mem: {math.ceil((1-settings().Network.FreeMemoryMBytes/settings().Network.EmulatedTotalMemoryInMB)*100)}%  {math.floor(settings().Network.FreeMemoryMBytes)}/{settings().Network.EmulatedTotalMemoryInMB}MB`
	end
end

function V3CoordsInit()
	local Viewport = Gui:WaitForChild('3DGraph')
	local Model = Viewport:WaitForChild('XYZ')
	local camera = Instance.new("Camera")
	camera.FieldOfView = 60
	camera.Parent = Viewport
	Viewport.CurrentCamera = camera

	local function GetCameraZoom()
		local cf, size = Model:GetBoundingBox()
		return size.Magnitude
	end

	local function updateWindow(delta)
		if not Viewport.Visible then
			return
		end

		-- Update the camera
		local rootPart = Model.PrimaryPart or Model:WaitForChild('Dot')
		local extents = GetCameraZoom()

		local lookVector = CurrentCam.CFrame.LookVector
		local focus = rootPart.CFrame

		focus = focus.Position
		local goal = CFrame.new(focus - (lookVector * extents), focus)
		camera.CFrame = camera.CFrame:Lerp(goal, math.min(1, delta * 20))
		--Viewport.LightDirection = lookVector
	end

	RunService.Heartbeat:Connect(updateWindow)
end

function FPSGraphInit()
	local Graph = Gui:WaitForChild('FPSGraph')
	local Container = Graph:WaitForChild('Container')
	local Bars = {}
	local FPSList = {}

	local function CreateBar(fps)
		--if 1-fps/60 <= .005 then return end --had an idea to stop creating graphs if the Y size is less than .005 but the graph just wont move if it does
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = fps > 45 and Color3.new(0, 1, 0) or fps > 20 and Color3.new(1,1,0) or Color3.new(1,0,0)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.fromScale(GraphWidth, math.clamp(1-fps/60,0,1))
		bar.Parent = Container
		table.insert(Bars,bar)
	end

	while Graph and Graph.Parent do
		local FPS = math.ceil(1/RunService.RenderStepped:Wait() + 0.5)
		Graph.FPS.Text = `{FPS} FPS   {math.floor(1000/FPS)} ms`

		table.insert(FPSList,FPS); if #FPSList > 60 then table.remove(FPSList,1) end
		local minFPS,maxFPS,avgFPS = math.min(table.unpack(FPSList)),math.max(table.unpack(FPSList)),calculateAverage(FPSList)
		Graph.minFPS.Text = `{math.floor(1000/maxFPS)} ms min ({minFPS})`
		Graph.maxFPS.Text = `{math.floor(1000/minFPS)} ms max ({maxFPS})`
		Graph.avgFPS.Text = `{math.floor(1000/avgFPS)} ms avg ({math.floor(avgFPS)})`
		CreateBar(FPS)
		if #Bars > 1/GraphWidth+1 then
			if typeof(Bars[1])=='Instance' then Bars[1]:Destroy()	end
			table.remove(Bars,1)
		end
		
		task.wait()
	end
end

function HBGraphInit()
	local Graph = Gui:WaitForChild('HBGraph')
	local Container = Graph:WaitForChild('Container')
	local Bars = {}
	local HBList = {}

	local function CreateBar(ms)
		--if 1-fps/60 <= .005 then return end --had an idea to stop creating graphs if the Y size is less than .005 but the graph just wont move if it does
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = ms > 100 and Color3.new(1,0,0) or ms > 40 and Color3.new(1,1,0) or Color3.new(0,1,0)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.fromScale(GraphWidth, math.clamp(ms/120,0,1))
		bar.Parent = Container
		table.insert(Bars,bar)
	end

	while Graph and Graph.Parent do
		local MS = RunService.Heartbeat:Wait()*1000
		Graph.MS.Text = `{math.floor(MS)} ms`

		table.insert(HBList,MS); if #HBList > 60 then table.remove(HBList,1) end
		local minMS,maxMS,avgMS = math.min(table.unpack(HBList)),math.max(table.unpack(HBList)),calculateAverage(HBList)
		Graph.minMS.Text = `{math.floor(minMS)} ms min`
		Graph.maxMS.Text = `{math.floor(maxMS)} ms max`
		Graph.avgMS.Text = `{math.floor(avgMS)} ms avg`
		CreateBar(MS)
		if #Bars > 1/GraphWidth+1 then
			if typeof(Bars[1])=='Instance' then Bars[1]:Destroy()	end
			table.remove(Bars,1)
		end

		task.wait()
	end
end

function OnPluginUnloading()
	if Gui then Gui:Destroy() end
end
----------------------
--|| Plugin Logic ||--
----------------------
EnableMenuButton = createToolbarButton(Toolbar,"Menu","Toggles the debug screen.","rbxassetid://7562374548",nil,false,ToolbarEnableMenuButton) :: PluginToolbarButton
Gui.Enabled = false
Gui.Parent = CoreGui

task.spawn(V3CoordsInit); task.spawn(FPSGraphInit); task.spawn(HBGraphInit); task.spawn(MainInit)

plugin.Unloading:Connect(OnPluginUnloading)
UserInput.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.KeyCode == Enum.KeyCode.F4 then -- apparently inputbegan doesnt detect F3 for some reason 
		ToolbarEnableMenuButton()
	end
end)
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	CurrentCam = workspace.CurrentCamera
end)

while task.wait(1) do
	RunTime += 1
end