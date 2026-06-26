--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WindowUI = require(ReplicatedStorage:WaitForChild("WindowUILibrary"))

local PLACEHOLDER_IMAGE = "rbxassetid://0"
local PLACEHOLDER_ICON = "rbxasset://textures/ui/GuiImagePlaceholder.png"

local ui = WindowUI.new({
	Name = "ExecutorFloatWindow",
	Title = "Window UI",
	Scale = 0.94,
	StartOpen = true,
	TopbarPlus = {
		Align = "Left",
		Label = "⊞",
		Caption = "Toggle Window UI",
	},
	Theme = {
		Accent = Color3.fromRGB(94, 151, 255),
		Window = Color3.fromRGB(24, 27, 36),
		Topbar = Color3.fromRGB(18, 20, 28),
		Surface = Color3.fromRGB(31, 35, 46),
		SurfaceStrong = Color3.fromRGB(42, 47, 61),
	},
})

local home = ui:CreateApp({
	Name = "Settings",
	Icon = PLACEHOLDER_ICON,
	BackgroundImage = PLACEHOLDER_IMAGE,
	TileImage = PLACEHOLDER_IMAGE,
	StartOpen = true,
	Order = 1,
})

local settings = home:CreateSection("Settings")
home:AddLabel("Executor-only floating UI. App tiles switch this same window to another page.", settings)
home:AddToggle({
	Text = "Example toggle",
	Default = true,
	Callback = function(enabled)
		print("Example toggle:", enabled)
	end,
}, settings)
home:AddSlider({
	Text = "Opacity",
	Min = 0,
	Max = 100,
	Default = 60,
	Step = 5,
	Callback = function(value)
		print("Opacity:", value)
	end,
}, settings)

local tools = ui:CreateApp({
	Name = "Tools",
	Icon = PLACEHOLDER_ICON,
	BackgroundImage = PLACEHOLDER_IMAGE,
	TileImage = PLACEHOLDER_IMAGE,
	Order = 2,
})

local actions = tools:CreateSection("Actions")
tools:AddButton({
	Text = "Refresh",
	Callback = function()
		print("Refresh clicked")
	end,
}, actions)
tools:AddDropdown({
	Text = "Mode",
	Options = { "Normal", "Compact", "Focus" },
	Default = "Normal",
	Callback = function(value)
		print("Mode:", value)
	end,
}, actions)

local profile = ui:CreateApp({
	Name = "Profile",
	Icon = PLACEHOLDER_ICON,
	Order = 3,
})

local profileSection = profile:CreateSection("Profile")
profile:AddTextBox({
	Text = "Nickname",
	Placeholder = "Type a display name",
	Callback = function(text)
		print("Nickname:", text)
	end,
}, profileSection)
