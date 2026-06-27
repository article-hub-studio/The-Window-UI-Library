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
	Icon = "solar:settings-linear",
	BackgroundImage = DEFAULT_BACKGROUND,
	TileImage = DEFAULT_BACKGROUND,
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
	Icon = "craft:tools",
	BackgroundImage = DEFAULT_BACKGROUND,
	TileImage = DEFAULT_BACKGROUND,
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
	Icon = "solar:user-rounded-linear",
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
