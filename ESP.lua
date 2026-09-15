local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local HeadOff = Vector3.new(0, 0.5, 0)
local LegOff = Vector3.new(0, 3, 0)

local Style = {
	Box = {
		Thickness = 1,
		Transparency = 1,

		OutlineThickness = 3,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		OutlineTransparency = 1
	},

	Name = {
		Size = 16,
		Center = true,
		Font = 3,
		Outline = true,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Transparency = 1
	},

	Distance = {
		Size = 10,
		Center = true,
		Font = 3,
		Outline = true,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Transparency = 1
	},

	Weapon = {
		Size = 10,
		Center = true,
		Font = 3,
		Outline = true,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Transparency = 1
	},

	Health = {
		BackgroundColor = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.15,

		OutlineColor = Color3.fromRGB(0, 0, 0),
		OutlineThickness = 1.5,

		Width = 4,
		BackgroundWidth = 6,
		Gap = 5,
		Padding = 1
	}
}

local ESP = {}
local Data = {}

local Toggles, Options, Library

local function ApplyStyle(Object, StyleProperties)
	for Property, Value in pairs(StyleProperties) do
		pcall(function()
			Object[Property] = Value
		end)
	end
end

local function GetHealthColor(HealthPercent)
	HealthPercent = math.clamp(HealthPercent, 0, 1)

	local HealthColor = Options.ESPHealthUpperColor.Value
	local MidColor = Options.ESPHealthMidColor.Value
	local LowColor = Options.ESPHealthLowerColor.Value

	if HealthPercent >= 0.5 then
		local Alpha = (HealthPercent - 0.5) * 2
		return Color3.new(MidColor.R + (HealthColor.R - MidColor.R) * Alpha, MidColor.G + (HealthColor.G - MidColor.G) * Alpha, MidColor.B + (HealthColor.B - MidColor.B) * Alpha)
	end

	local Alpha = HealthPercent * 2
	return Color3.new(LowColor.R + (MidColor.R - LowColor.R) * Alpha, LowColor.G + (MidColor.G - LowColor.G) * Alpha, LowColor.B + (MidColor.B - LowColor.B) * Alpha)
end

local function GetEquippedToolName(Character)
	local Tool = Character:FindFirstChildOfClass("Tool")
	return Tool and Tool.Name or nil
end

local function HideESP(EspData)
	for _, Object in pairs(EspData) do
		if Object then
			Object.Visible = false
		end
	end
end

local function CreateESP(Player)
	if Data[Player] then
		return
	end

	local EspData = {
		BoxOutline = Drawing.new("Square"),
		Box = Drawing.new("Square"),

		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Weapon = Drawing.new("Text"),

		HealthBackground = Drawing.new("Square"),
		Health = Drawing.new("Square"),
		HealthOutline = Drawing.new("Square")
	}

	ApplyStyle(EspData.BoxOutline, Style.Box)
	ApplyStyle(EspData.Box, Style.Box)

	ApplyStyle(EspData.Name, Style.Name)
	ApplyStyle(EspData.Distance, Style.Distance)
	ApplyStyle(EspData.Weapon, Style.Weapon)

	EspData.HealthBackground.Filled = true
	EspData.HealthBackground.Transparency = Style.Health.BackgroundTransparency
	EspData.HealthBackground.Color = Style.Health.BackgroundColor

	EspData.Health.Filled = true
	EspData.Health.Transparency = 1

	EspData.HealthOutline.Filled = false
	EspData.HealthOutline.Thickness = Style.Health.OutlineThickness
	EspData.HealthOutline.Transparency = 1
	EspData.HealthOutline.Color = Style.Health.OutlineColor

	Data[Player] = EspData
end

local function RemoveESP(Player)
	local EspData = Data[Player]
	if not EspData then
		return
	end

	for _, Object in pairs(EspData) do
		if Object then
			pcall(function()
				Object:Remove()
			end)
		end
	end

	Data[Player] = nil
end

local function UpdateESP(Player, EspData)
	local Character = Player.Character
	if not Character then
		HideESP(EspData)
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	local Head = Character:FindFirstChild("Head")

	if not Humanoid or not RootPart or not Head then
		HideESP(EspData)
		return
	end

	local RootPosition, RootVis = Camera.WorldToViewportPoint(Camera, RootPart.Position)
	local HeadPosition = Camera.WorldToViewportPoint(Camera, Head.Position + HeadOff)
	local LegPosition = Camera.WorldToViewportPoint(Camera, RootPart.Position - LegOff)

	if not RootVis or RootPosition.Z <= 0 then
		HideESP(EspData)
		return
	end

	-- ============================================
	-- BOX
	-- ============================================

	if Toggles.ESPBox.Value then
		local OutlineThickness = Style.Box.OutlineThickness

		-- Outline
		EspData.BoxOutline.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
		EspData.BoxOutline.Position = Vector2.new(RootPosition.X - EspData.BoxOutline.Size.X / 2, RootPosition.Y - EspData.BoxOutline.Size.Y / 2)

		EspData.BoxOutline.Color = Style.Box.OutlineColor
		EspData.BoxOutline.Thickness = OutlineThickness
		EspData.BoxOutline.Transparency = Style.Box.OutlineTransparency
		EspData.BoxOutline.Visible = true

		-- Main box
		EspData.Box.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
		EspData.Box.Position = Vector2.new(RootPosition.X - EspData.Box.Size.X / 2, RootPosition.Y - EspData.Box.Size.Y / 2)

		EspData.Box.Color = Options.ESPBoxColor.Value
		EspData.Box.Thickness = Style.Box.Thickness
		EspData.Box.Transparency = Style.Box.Transparency
		EspData.Box.Visible = true
	else
		EspData.Box.Visible = false
		EspData.BoxOutline.Visible = false
	end

	-- ============================================
	-- NAME
	-- ============================================

	if Toggles.ESPName.Value then
		local NameType = Options.ESPNametype.Value
	
		EspData.Name.Text = (NameType == "displayname") and Player.DisplayName or Player.Name
		EspData.Name.Position = Vector2.new(RootPosition.X, RootPosition.Y - 30)
		EspData.Name.Color = Options.ESPNameColor.Value
		EspData.Name.Visible = true
	else
		EspData.Name.Visible = false
	end
	
	-- ============================================
	-- DISTANCE
	-- ============================================
	
	local DistanceShown = false
	
	if Toggles.ESPDistance.Value then
		local LocalCharacter = LocalPlayer.Character
		local LocalRoot = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
	
		if LocalRoot then
			local Distance = (LocalRoot.Position - RootPart.Position).Magnitude
	
			EspData.Distance.Text = string.format("%d studs", math.floor(Distance + 0.5))
			EspData.Distance.Position = Vector2.new(RootPosition.X, RootPosition.Y + 30)
			EspData.Distance.Color = Options.ESPDistanceColor.Value
			EspData.Distance.Visible = true
	
			DistanceShown = true
		else
			EspData.Distance.Visible = false
		end
	else
		EspData.Distance.Visible = false
	end
	
	-- ============================================
	-- WEAPON
	-- ============================================
	
	if Toggles.ESPWeapon.Value then
		local WeaponName = GetEquippedToolName(Character)
	
		if WeaponName then
			EspData.Weapon.Text = "[" .. WeaponName .. "]"
	
			local WeaponY
	
			if DistanceShown then
				WeaponY = RootPosition.Y + 30 + EspData.Distance.TextBounds.Y + 2
			else
				WeaponY = RootPosition.Y + 30
			end
	
			EspData.Weapon.Position = Vector2.new(RootPosition.X, WeaponY)
			EspData.Weapon.Color = Options.ESPWeaponColor.Value
			EspData.Weapon.Visible = true
		else
			EspData.Weapon.Visible = false
		end
	else
		EspData.Weapon.Visible = false
	end

	-- ============================================
	-- HEALTH
	-- ============================================

	if Toggles.ESPHealth.Value then
		local Health = Humanoid.Health
		local MaxHealth = Humanoid.MaxHealth
		local HealthPercent = math.clamp(Health / MaxHealth, 0, 1)
	
		local BackgroundWidth = Style.Health.BackgroundWidth
		local HealthWidth = Style.Health.Width
		local HealthX = EspData.Box.Position.X - Style.Health.Gap - BackgroundWidth
	
		-- Background
		EspData.HealthBackground.Position = Vector2.new(HealthX, EspData.Box.Position.Y)
		EspData.HealthBackground.Size = Vector2.new(BackgroundWidth, EspData.Box.Size.Y)
		EspData.HealthBackground.Visible = true
	
		-- Green health bar
		local InnerHeight = EspData.Box.Size.Y - Style.Health.Padding * 2
		local HealthHeight = InnerHeight * HealthPercent
		local HealthXInner = HealthX + (BackgroundWidth - HealthWidth) / 2
		local HealthY = EspData.Box.Position.Y + Style.Health.Padding + InnerHeight - HealthHeight
	
		EspData.Health.Position = Vector2.new(HealthXInner, HealthY)
		EspData.Health.Size = Vector2.new(HealthWidth, HealthHeight)
		EspData.Health.Color = GetHealthColor(HealthPercent)
		EspData.Health.Visible = true
	
		-- Outline
		EspData.HealthOutline.Position = Vector2.new(HealthXInner, EspData.Box.Position.Y + Style.Health.Padding)
		EspData.HealthOutline.Size = Vector2.new(HealthWidth, InnerHeight)
		EspData.HealthOutline.Visible = true
	else
		EspData.HealthBackground.Visible = false
		EspData.Health.Visible = false
		EspData.HealthOutline.Visible = false
	end
end

function ESP:Initialize(SharedRefs)
	Toggles = SharedRefs.Toggles
	Options = SharedRefs.Options
	Library = SharedRefs.Library

	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			CreateESP(Player)
		end
	end

	Players.PlayerAdded:Connect(function(Player)
		if Player ~= LocalPlayer then
			CreateESP(Player)
		end
	end)

	Players.PlayerRemoving:Connect(RemoveESP)

	RunService.RenderStepped:Connect(function()
		for Player, EspData in pairs(Data) do
			if Player.Parent == Players then
				UpdateESP(Player, EspData)
			else
				RemoveESP(Player)
			end
		end
	end)
end

return ESP
