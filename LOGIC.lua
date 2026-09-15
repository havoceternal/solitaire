local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Character, Humanoid, HumanoidRootPart
local NotificationTime = 3

local Logic = {}

local Library, Toggles, Options

local function Setup(c)
	Character = c
	Humanoid = c:WaitForChild("Humanoid")
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end

Player.CharacterAdded:Connect(Setup)
Setup(Player.Character or Player.CharacterAdded:Wait())

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

    runLoop("VelocityKey", function()
		if Humanoid and HumanoidRootPart then
			local direction = Humanoid.MoveDirection
			local velocity = HumanoidRootPart.AssemblyLinearVelocity
			local vertical = velocity.Y
			local horizontal = direction * Options.VelocitySpeed.Value
			HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(horizontal.X,vertical, horizontal.Z)
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
