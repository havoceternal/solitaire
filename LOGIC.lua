local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera	

local LocalCharacter, LocalHumanoid, LocalHumanoidRootPart
local NotificationTime = 3

local Logic = {}

local Library, Toggles, Options

local function Setup(newCharacter)
	LocalCharacter = newCharacter
	LocalHumanoid = newCharacter:WaitForChild("Humanoid")
	LocalHumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(Setup)
Setup(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

local function checkWall(target)
    if not LocalHumanoidRootPart then
        return false
    end

    local targetRootPart = target:FindFirstChild("HumanoidRootPart")
    if not targetRootPart then
        return false
    end

    local Origin = LocalHumanoidRootPart.Position
    local Direction = targetRootPart.Position - Origin

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {
        LocalCharacter,
        target
    }

    local Result = workspace:Raycast(Origin, Direction, Params)

    return Result ~= nil
end

local function checkFriend(target)
	return LocalPlayer:IsFriendsWith(target.UserId)
end

local function FindPlayerToMouse(radius,configurations)
	if not LocalHumanoidRootPart then
        return false
    end
	local ClosestPlayer = nil
	local shortestDistance = math.huge
	local mousePos = Vector2.new(Mouse.X, Mouse.Y)
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= LocalPlayer and target.Character then
			local targetRootPart = target.Character:FindFirstChild("HumanoidRootPart")
			if targetRootPart then
				if configurations.CameraFriendCheck and checkFriend(target) then
					continue
				end

				if configurations.CameraWallCheck and checkWall(target) then
					continue
				end

				local screenPos, onScreen = Camera:WorldToViewportPoint(targetRootPart.Position)
				if onScreen then
					local screenVector = Vector2.new(screenPos.X, screenPos.Y)
					local distance = (screenVector - mousePos).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						ClosestPlayer = target
					end
				end
			end
		end
	end
	return ClosestPlayer
end

local function runLoop(controlObj, loopFn)
	if type(controlObj) == "string" then
		local keybind
		if controlObj:sub(1,1) == "!" then
			keybind = Options[controlObj:sub(2)]
		else
			keybind = Options[controlObj]
		end
		task.spawn(function()
			pcall(function()
			if controlObj:sub(1,1) == "!" then
				while true do
					local state = keybind:GetState()
					if state then
						loopFn()
					end
					RunService.Heartbeat:Wait()
				end
			end
			while task.wait() do
				local state = keybind:GetState()
				if state then
					loopFn()
				end
			end
			end)
		end)
		return
	end
	if controlObj.OnChanged then
		local loopTask
		controlObj:OnChanged(function()
			if controlObj.Value then
				if not loopTask then
					loopTask = task.spawn(function()
						pcall(function()
						while controlObj.Value do
							task.wait()
							loopFn()
						end
						loopTask = nil
						end)
					end)
				end
			else
				loopTask = nil
			end
		end)
	end
end

function Logic:Initialize(UIReference)
    _G.Toggles = UIReference.Toggles
	_G.Options = UIReference.Options
	Toggles = UIReference.Toggles
	Options = UIReference.Options
	Library = UIReference.Library

	pcall(function()
		LPH_NO_VIRTUALIZE = function(...) return (...) end
		local newindex; newindex = hookmetamethod(game, "__newindex", LPH_NO_VIRTUALIZE(function(self, key, value)
			if key == 'WalkSpeed' then 
				if Toggles.WalkSpeedToggle.Value then
					value = Options.WalkSpeed.Value
				end
			end
			if key == "JumpPower" then 
				if Toggles.JumpPowerToggle.Value then
					value = Options.JumpPower.Value
				end
			end
			return newindex(self, key, value)
		end))
	end)
	-- MAIN TAB
	runLoop("CameraLockKey", function()
		local Target = FindPlayerToMouse(nil, {
		CameraFriendCheck = Toggles.CameraFriendCheck.Value,
		CameraWallCheck = Toggles.CameraWallCheck.Value
		})

		if Target and Target.Character then
			local targetHeadPart = Target.Character:FindFirstChild("Head")
			if targetHeadPart then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHeadPart.Position)
			end
		end
	end)

	-- CHARACTER TAB
    runLoop("VelocityKey", function()
		if LocalHumanoid and LocalHumanoidRootPart then
			local direction = LocalHumanoid.MoveDirection
			local velocity = LocalHumanoidRootPart.AssemblyLinearVelocity
			local vertical = velocity.Y
			local horizontal = direction * Options.VelocitySpeed.Value
			LocalHumanoidRootPart.AssemblyLinearVelocity = Vector3.new(horizontal.X,vertical, horizontal.Z)
		end
	end)

	Toggles.WalkSpeedToggle:OnChanged(function()
		if Toggles.WalkSpeedToggle.Value then
			Library:Notify("USE AT YOUR OWN RISK!", NotificationTime)
		end
	end)

	Toggles.JumpPowerToggle:OnChanged(function()
		if Toggles.JumpPowerToggle.Value then
			Library:Notify("USE AT YOUR OWN RISK!", NotificationTime)
		end
	end)
end

return Logic
