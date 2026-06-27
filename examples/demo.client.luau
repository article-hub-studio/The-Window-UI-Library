--!strict

local WindowUI = loadstring(
	game:HttpGet(
		"https://raw.githubusercontent.com/article-hub-studio/The-Window-UI-Library/refs/heads/main/src/WindowUILibrary.luau"
	)
)()

local DEFAULT_BACKGROUND = WindowUI.GetDefaultBackground()

local ui = WindowUI.new({
	Name = "ExecutorFloatWindow",
	Title = "Window UI",
	Scale = 0.94,
	StartOpen = true,
	TopbarPlus = {
		Align = "Center",
		Caption = "Toggle Window UI",
	},
	Theme = {
		Accent = Color3.fromRGB(88, 101, 242),
		Window = Color3.fromRGB(49, 51, 56),
		Topbar = Color3.fromRGB(30, 31, 34),
		Surface = Color3.fromRGB(43, 45, 49),
		SurfaceStrong = Color3.fromRGB(56, 58, 64),
	},
})

local home = ui:CreateApp({
	Name = "Home",
	Icon = "solar:settings-bold",
	TileImage = DEFAULT_BACKGROUND,
	StartOpen = true,
	Order = 1,
})

local settings = home:CreateSection("Settings")
home:AddLabel("Executor-only floating UI. App tiles switch this same window to another page.", settings)
local glassGroup = home:CreateGroupBox("Liquid Controls")
home:AddToggle({
	Text = "Example toggle",
	Default = true,
	Callback = function(enabled)
		print("Example toggle:", enabled)
	end,
}, glassGroup)
home:AddSlider({
	Text = "Opacity",
	Min = 0,
	Max = 100,
	Default = 60,
	Step = 5,
	Callback = function(value)
		print("Opacity:", value)
	end,
}, glassGroup)

local tools = ui:CreateApp({
	Name = "Tools",
	Icon = "craft:tools",
	TileImage = DEFAULT_BACKGROUND,
	Order = 2,
})

local actions = tools:CreateSection("Actions")
local toolsTabs = tools:CreateTabBox({
	Title = "Toolbox",
	Tabs = { "Main", "Modes" },
	Default = "Main",
}, actions)
local mainTools = toolsTabs:GetPage("Main")
local modeTools = toolsTabs:GetPage("Modes")
tools:AddButton({
	Text = "Refresh",
	Callback = function()
		print("Refresh clicked")
	end,
}, mainTools)
tools:AddDropdown({
	Text = "Mode",
	Options = { "Normal", "Compact", "Focus" },
	Default = "Normal",
	Callback = function(value)
		print("Mode:", value)
	end,
}, modeTools)

local profile = ui:CreateApp({
	Name = "Profile",
	Icon = "solar:user-bold",
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
