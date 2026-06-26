--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WindowUI = require(ReplicatedStorage:WaitForChild("WindowUILibrary"))

local PLACEHOLDER_IMAGE = "rbxassetid://0" -- Replace with your uploaded image asset id.
local PLACEHOLDER_ICON = "rbxasset://textures/ui/GuiImagePlaceholder.png"

local ui = WindowUI.new({
	Name = "SeelenWindowDemo",
	WallpaperImage = PLACEHOLDER_IMAGE,
	StartOpen = true,
	Theme = {
		Accent = Color3.fromRGB(53, 125, 255),
		Glass = Color3.fromRGB(238, 245, 255),
		GlassStrong = Color3.fromRGB(255, 255, 255),
		Text = Color3.fromRGB(16, 20, 29),
		MutedText = Color3.fromRGB(91, 99, 118),
	},
})

local settings = ui:CreateApp({
	Name = "Settings",
	Icon = PLACEHOLDER_ICON,
	BackgroundImage = PLACEHOLDER_IMAGE,
	TileImage = PLACEHOLDER_IMAGE,
	Size = UDim2.fromOffset(560, 390),
	StartOpen = true,
	Order = 1,
})

local settingsSection = settings:CreateSection("Desktop")
settings:AddLabel(
	"Window-style floating menu with app tiles, taskbar restore buttons, drag, resize, and mobile layout.",
	settingsSection
)
settings:AddToggle({
	Text = "Glass panels",
	Default = true,
	Callback = function(enabled)
		print("Glass panels:", enabled)
	end,
}, settingsSection)
settings:AddSlider({
	Text = "Opacity",
	Min = 0,
	Max = 100,
	Default = 72,
	Step = 1,
	Callback = function(value)
		print("Opacity:", value)
	end,
}, settingsSection)

local explorer = ui:CreateApp({
	Name = "Explorer",
	Icon = PLACEHOLDER_ICON,
	BackgroundImage = PLACEHOLDER_IMAGE,
	TileImage = PLACEHOLDER_IMAGE,
	Size = UDim2.fromOffset(610, 420),
	Order = 2,
})

local explorerSection = explorer:CreateSection("File Explorer")
explorer:AddDropdown({
	Text = "View",
	Options = { "Details", "Icons", "Compact" },
	Default = "Icons",
	Callback = function(value)
		print("Explorer view:", value)
	end,
}, explorerSection)
explorer:AddButton({
	Text = "Refresh",
	Callback = function()
		print("Refresh clicked")
	end,
}, explorerSection)

local terminal = ui:CreateApp({
	Name = "Terminal",
	Icon = PLACEHOLDER_ICON,
	BackgroundImage = PLACEHOLDER_IMAGE,
	TileImage = PLACEHOLDER_IMAGE,
	Size = UDim2.fromOffset(540, 340),
	Order = 3,
})

local terminalSection = terminal:CreateSection("Console")
terminal:AddTextBox({
	Text = "Command",
	Placeholder = "Type a safe command label",
	Callback = function(text)
		print("Command label:", text)
	end,
}, terminalSection)
terminal:AddButton({
	Text = "Run",
	Callback = function()
		print("Run clicked")
	end,
}, terminalSection)
