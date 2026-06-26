--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LOCAL_PLAYER = Players.LocalPlayer

local WindowUI = {}
WindowUI.__index = WindowUI

local AppWindow = {}
AppWindow.__index = AppWindow

export type Theme = {
	Accent: Color3?,
	DesktopTopbar: Color3?,
	Glass: Color3?,
	GlassStrong: Color3?,
	Text: Color3?,
	MutedText: Color3?,
	Stroke: Color3?,
	Shadow: Color3?,
}

export type WindowConfig = {
	Name: string?,
	Parent: Instance?,
	WallpaperImage: string?,
	WallpaperTransparency: number?,
	StartOpen: boolean?,
	DisplayOrder: number?,
	ResetOnSpawn: boolean?,
	Theme: Theme?,
}

export type AppConfig = {
	Name: string,
	Icon: string,
	BackgroundImage: string,
	TileImage: string?,
	WindowImage: string?,
	Size: UDim2?,
	Position: UDim2?,
	MinSize: Vector2?,
	StartOpen: boolean?,
	Order: number?,
}

export type ButtonConfig = {
	Text: string,
	Callback: (() -> ())?,
}

export type ToggleConfig = {
	Text: string,
	Default: boolean?,
	Callback: ((boolean) -> ())?,
}

export type SliderConfig = {
	Text: string,
	Min: number?,
	Max: number?,
	Default: number?,
	Step: number?,
	Callback: ((number) -> ())?,
}

export type TextBoxConfig = {
	Text: string,
	Placeholder: string?,
	Default: string?,
	Callback: ((string) -> ())?,
}

export type DropdownConfig = {
	Text: string,
	Options: { string },
	Default: string?,
	Callback: ((string) -> ())?,
}

type ConnectionList = { RBXScriptConnection }

local DEFAULT_THEME = {
	Accent = Color3.fromRGB(46, 118, 255),
	DesktopTopbar = Color3.fromRGB(13, 15, 20),
	Glass = Color3.fromRGB(238, 244, 255),
	GlassStrong = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(17, 20, 28),
	MutedText = Color3.fromRGB(92, 99, 116),
	Stroke = Color3.fromRGB(255, 255, 255),
	Shadow = Color3.fromRGB(10, 12, 18),
}

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SOFT = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local START_MENU_DESKTOP_SIZE = UDim2.fromOffset(620, 440)
local START_MENU_MOBILE_HEIGHT = 520
local TASKBAR_DESKTOP_SIZE = UDim2.fromOffset(430, 58)
local TASKBAR_MOBILE_SIZE = UDim2.new(1, -28, 0, 58)

local function mergeTheme(theme: Theme?): Theme
	local merged = {}

	for key, value in DEFAULT_THEME do
		merged[key] = value
	end

	if theme then
		for key, value in theme do
			merged[key] = value
		end
	end

	return merged :: Theme
end

local function getPlayerGui(): Instance
	if LOCAL_PLAYER then
		return LOCAL_PLAYER:WaitForChild("PlayerGui")
	end

	error("WindowUILibrary must be required from a LocalScript so Players.LocalPlayer exists.")
end

local function tween(instance: Instance, info: TweenInfo, properties: { [string]: any })
	local created = TweenService:Create(instance, info, properties)
	created:Play()
	return created
end

local function pointer(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function isPressInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMoveInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function addCorner(parent: GuiObject, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent: GuiObject, color: Color3, transparency: number, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent: GuiObject, left: number, top: number, right: number, bottom: number): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingBottom = UDim.new(0, bottom)
	padding.Parent = parent
	return padding
end

local function setTextStyle(label: TextLabel | TextButton | TextBox, color: Color3, size: number, weight: Enum.Font)
	label.Font = weight
	label.TextColor3 = color
	label.TextSize = size
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
end

local function safeCallback(callback: (() -> ())?)
	if not callback then
		return
	end

	local ok, err = pcall(callback)
	if not ok then
		warn("[WindowUILibrary] callback failed:", err)
	end
end

local function safeValueCallback<T>(callback: ((T) -> ())?, value: T)
	if not callback then
		return
	end

	local ok, err = pcall(callback, value)
	if not ok then
		warn("[WindowUILibrary] callback failed:", err)
	end
end

local function addButtonMotion(button: GuiButton, normal: Color3, hover: Color3, pressed: Color3, scale: UIScale?)
	local entered = button.MouseEnter:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = hover })
		if scale then
			tween(scale, TWEEN_FAST, { Scale = 1.025 })
		end
	end)

	local left = button.MouseLeave:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = normal })
		if scale then
			tween(scale, TWEEN_FAST, { Scale = 1 })
		end
	end)

	local down = button.MouseButton1Down:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = pressed })
		if scale then
			tween(scale, TWEEN_FAST, { Scale = 0.975 })
		end
	end)

	local up = button.MouseButton1Up:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = hover })
		if scale then
			tween(scale, TWEEN_FAST, { Scale = 1.025 })
		end
	end)

	return { entered, left, down, up }
end

local function makeDraggable(handle: GuiObject, target: GuiObject, onStart: (() -> ())?): ConnectionList
	local dragging = false
	local dragInput: InputObject? = nil
	local startPointer = Vector2.zero
	local startPosition = target.Position

	local connections: ConnectionList = {}

	table.insert(
		connections,
		handle.InputBegan:Connect(function(input: InputObject)
			if not isPressInput(input) then
				return
			end

			dragging = true
			dragInput = input
			startPointer = pointer(input)
			startPosition = target.Position

			if onStart then
				onStart()
			end
		end)
	)

	table.insert(
		connections,
		handle.InputChanged:Connect(function(input: InputObject)
			if isMoveInput(input) then
				dragInput = input
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if not dragging or not dragInput then
				return
			end

			if input ~= dragInput and input.UserInputType ~= dragInput.UserInputType then
				return
			end

			local delta = pointer(input) - startPointer
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end)
	)

	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if input == dragInput or isPressInput(input) then
				dragging = false
				dragInput = nil
			end
		end)
	)

	return connections
end

local function makeResizable(
	handle: GuiObject,
	target: GuiObject,
	minSize: Vector2,
	onStart: (() -> ())?
): ConnectionList
	local resizing = false
	local resizeInput: InputObject? = nil
	local startPointer = Vector2.zero
	local startSize = target.Size

	local connections: ConnectionList = {}

	table.insert(
		connections,
		handle.InputBegan:Connect(function(input: InputObject)
			if not isPressInput(input) then
				return
			end

			resizing = true
			resizeInput = input
			startPointer = pointer(input)
			startSize = target.Size

			if onStart then
				onStart()
			end
		end)
	)

	table.insert(
		connections,
		handle.InputChanged:Connect(function(input: InputObject)
			if isMoveInput(input) then
				resizeInput = input
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if not resizing or not resizeInput then
				return
			end

			if input ~= resizeInput and input.UserInputType ~= resizeInput.UserInputType then
				return
			end

			local delta = pointer(input) - startPointer
			local width = math.max(minSize.X, startSize.X.Offset + delta.X)
			local height = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
			local parent = target.Parent

			if parent and parent:IsA("GuiObject") then
				width = math.min(width, math.max(minSize.X, parent.AbsoluteSize.X - 24))
				height = math.min(height, math.max(minSize.Y, parent.AbsoluteSize.Y - 92))
			end

			target.Size = UDim2.new(startSize.X.Scale, width, startSize.Y.Scale, height)
		end)
	)

	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if input == resizeInput or isPressInput(input) then
				resizing = false
				resizeInput = nil
			end
		end)
	)

	return connections
end

local function disconnectAll(connections: ConnectionList)
	for _, connection in connections do
		connection:Disconnect()
	end

	table.clear(connections)
end

local function createTopButton(text: string, theme: Theme): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = theme.GlassStrong or DEFAULT_THEME.GlassStrong
	button.BackgroundTransparency = 0.28
	button.BorderSizePixel = 0
	button.Size = UDim2.fromOffset(28, 24)
	button.Text = text
	button.TextColor3 = theme.Text or DEFAULT_THEME.Text
	button.TextSize = 14
	button.Font = Enum.Font.GothamMedium
	addCorner(button, 7)
	addStroke(button, theme.Stroke or DEFAULT_THEME.Stroke, 0.62)
	return button
end

local function createStatusPill(text: string, width: number, theme: Theme): TextLabel
	local pill = Instance.new("TextLabel")
	pill.BackgroundColor3 = theme.DesktopTopbar or DEFAULT_THEME.DesktopTopbar
	pill.BackgroundTransparency = 0.08
	pill.BorderSizePixel = 0
	pill.Size = UDim2.fromOffset(width, 28)
	pill.Text = text
	pill.TextColor3 = Color3.fromRGB(250, 252, 255)
	pill.TextSize = 12
	pill.Font = Enum.Font.GothamMedium
	pill.TextXAlignment = Enum.TextXAlignment.Center
	pill.TextYAlignment = Enum.TextYAlignment.Center
	pill.ZIndex = 901
	addCorner(pill, 999)
	return pill
end

function WindowUI.new(config: WindowConfig?)
	local parent = if config and config.Parent then config.Parent else getPlayerGui()
	local theme = mergeTheme(if config then config.Theme else nil)

	local gui = Instance.new("ScreenGui")
	gui.Name = (config and config.Name) or "WindowUILibrary"
	gui.DisplayOrder = (config and config.DisplayOrder) or 1000
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = if config and config.ResetOnSpawn ~= nil then config.ResetOnSpawn else false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local self = setmetatable({
		Gui = gui,
		Theme = theme,
		Desktop = nil :: Frame?,
		StartMenu = nil :: Frame?,
		StartBody = nil :: ScrollingFrame?,
		AppGrid = nil :: UIGridLayout?,
		Taskbar = nil :: Frame?,
		TaskbarList = nil :: Frame?,
		StartButton = nil :: TextButton?,
		Wallpaper = nil :: ImageLabel?,
		Connections = {} :: ConnectionList,
		Apps = {} :: { any },
		AppByName = {} :: { [string]: any },
		ZCounter = 220,
		Mobile = false,
		Config = config or {},
	}, WindowUI)

	self:_buildShell()
	gui.Parent = parent
	self:_updateResponsiveLayout()

	return self
end

function WindowUI:_buildShell()
	local theme: Theme = self.Theme
	local config: WindowConfig = self.Config

	local desktop = Instance.new("Frame")
	desktop.Name = "Desktop"
	desktop.BackgroundColor3 = Color3.fromRGB(177, 207, 232)
	desktop.BorderSizePixel = 0
	desktop.Size = UDim2.fromScale(1, 1)
	desktop.ClipsDescendants = true
	desktop.Parent = self.Gui
	self.Desktop = desktop

	local wallpaper = Instance.new("ImageLabel")
	wallpaper.Name = "Wallpaper"
	wallpaper.BackgroundTransparency = 1
	wallpaper.BorderSizePixel = 0
	wallpaper.Image = config.WallpaperImage or ""
	wallpaper.ImageTransparency = config.WallpaperTransparency or 0
	wallpaper.ScaleType = Enum.ScaleType.Crop
	wallpaper.Size = UDim2.fromScale(1, 1)
	wallpaper.Parent = desktop
	self.Wallpaper = wallpaper

	local fallback = Instance.new("UIGradient")
	fallback.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(187, 226, 255)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(245, 222, 233)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 201, 183)),
	})
	fallback.Rotation = 18
	fallback.Parent = desktop

	self:_buildStatusBar()
	self:_buildStartMenu()
	self:_buildTaskbar()

	table.insert(
		self.Connections,
		desktop:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:_updateResponsiveLayout()
		end)
	)
end

function WindowUI:_buildStatusBar()
	local theme: Theme = self.Theme
	local desktop: Frame = self.Desktop

	local left = Instance.new("Frame")
	left.Name = "StatusLeft"
	left.BackgroundTransparency = 1
	left.Position = UDim2.fromOffset(14, 8)
	left.Size = UDim2.fromOffset(270, 28)
	left.ZIndex = 900
	left.Parent = desktop

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.FillDirection = Enum.FillDirection.Horizontal
	leftLayout.Padding = UDim.new(0, 8)
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Parent = left

	local user = createStatusPill("Window UI", 88, theme)
	user.LayoutOrder = 1
	user.Parent = left

	local active = createStatusPill("Start", 64, theme)
	active.LayoutOrder = 2
	active.Parent = left

	local settings = createStatusPill("Settings", 82, theme)
	settings.LayoutOrder = 3
	settings.Parent = left

	local clock = createStatusPill("", 170, theme)
	clock.Name = "Clock"
	clock.AnchorPoint = Vector2.new(0.5, 0)
	clock.Position = UDim2.new(0.5, 0, 0, 8)
	clock.ZIndex = 900
	clock.Parent = desktop

	local right = Instance.new("Frame")
	right.Name = "StatusRight"
	right.AnchorPoint = Vector2.new(1, 0)
	right.BackgroundTransparency = 1
	right.Position = UDim2.new(1, -14, 0, 8)
	right.Size = UDim2.fromOffset(226, 28)
	right.ZIndex = 900
	right.Parent = desktop

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.FillDirection = Enum.FillDirection.Horizontal
	rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rightLayout.Padding = UDim.new(0, 8)
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Parent = right

	for index, label in { "...", "Net", "Sound", "100%" } do
		local width = if index == 4 then 58 else 44
		local pill = createStatusPill(label, width, theme)
		pill.LayoutOrder = index
		pill.Parent = right
	end

	task.spawn(function()
		while clock.Parent do
			clock.Text = os.date("%a %d %b, %I:%M %p")
			task.wait(30)
		end
	end)
end

function WindowUI:_buildStartMenu()
	local theme: Theme = self.Theme
	local desktop: Frame = self.Desktop

	local menu = Instance.new("Frame")
	menu.Name = "StartMenu"
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.BackgroundColor3 = theme.Glass or DEFAULT_THEME.Glass
	menu.BackgroundTransparency = 0.08
	menu.BorderSizePixel = 0
	menu.ClipsDescendants = true
	menu.Position = UDim2.fromScale(0.5, 0.5)
	menu.Size = START_MENU_DESKTOP_SIZE
	menu.Visible = if self.Config.StartOpen == nil then true else self.Config.StartOpen
	menu.ZIndex = self.ZCounter
	addCorner(menu, 12)
	addStroke(menu, theme.Stroke or DEFAULT_THEME.Stroke, 0.48, 1)
	menu.Parent = desktop
	self.StartMenu = menu

	local shade = Instance.new("Frame")
	shade.Name = "InnerHighlight"
	shade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shade.BackgroundTransparency = 0.72
	shade.BorderSizePixel = 0
	shade.Size = UDim2.fromScale(1, 1)
	addCorner(shade, 12)
	shade.Parent = menu

	local topbar = Instance.new("Frame")
	topbar.Name = "Topbar"
	topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topbar.BackgroundTransparency = 0.38
	topbar.BorderSizePixel = 0
	topbar.Size = UDim2.new(1, 0, 0, 42)
	topbar.Parent = menu

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 0)
	title.Size = UDim2.new(1, -116, 1, 0)
	title.Text = "Window UI Library"
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.TextYAlignment = Enum.TextYAlignment.Center
	setTextStyle(title, theme.Text or DEFAULT_THEME.Text, 14, Enum.Font.GothamMedium)
	title.Parent = topbar

	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.AnchorPoint = Vector2.new(1, 0.5)
	controls.BackgroundTransparency = 1
	controls.Position = UDim2.new(1, -10, 0.5, 0)
	controls.Size = UDim2.fromOffset(66, 24)
	controls.Parent = topbar

	local controlLayout = Instance.new("UIListLayout")
	controlLayout.FillDirection = Enum.FillDirection.Horizontal
	controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlLayout.Padding = UDim.new(0, 6)
	controlLayout.Parent = controls

	local minimize = createTopButton("-", theme)
	minimize.LayoutOrder = 1
	minimize.Parent = controls

	local close = createTopButton("x", theme)
	close.LayoutOrder = 2
	close.Parent = controls

	table.insert(
		self.Connections,
		minimize.MouseButton1Click:Connect(function()
			local body = self.StartBody
			if not body then
				return
			end

			body.Visible = not body.Visible
			local height = if body.Visible then self:_preferredStartHeight() else 42
			tween(menu, TWEEN_SOFT, { Size = UDim2.new(menu.Size.X.Scale, menu.Size.X.Offset, 0, height) })
		end)
	)

	table.insert(
		self.Connections,
		close.MouseButton1Click:Connect(function()
			self:ToggleStart(false)
		end)
	)

	for _, connection in
		makeDraggable(topbar, menu, function()
			self:_raiseStartMenu()
		end)
	do
		table.insert(self.Connections, connection)
	end

	local body = Instance.new("ScrollingFrame")
	body.Name = "Apps"
	body.Active = true
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.CanvasSize = UDim2.fromOffset(0, 0)
	body.Position = UDim2.fromOffset(0, 42)
	body.ScrollBarImageColor3 = theme.Accent or DEFAULT_THEME.Accent
	body.ScrollBarImageTransparency = 0.38
	body.ScrollBarThickness = 4
	body.Size = UDim2.new(1, 0, 1, -42)
	body.Parent = menu
	self.StartBody = body

	addPadding(body, 22, 22, 22, 22)

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(16, 16)
	grid.CellSize = UDim2.fromOffset(86, 96)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = body
	self.AppGrid = grid

	if menu.Visible then
		self:_raiseStartMenu()
	end
end

function WindowUI:_buildTaskbar()
	local theme: Theme = self.Theme
	local desktop: Frame = self.Desktop

	local taskbar = Instance.new("Frame")
	taskbar.Name = "Taskbar"
	taskbar.AnchorPoint = Vector2.new(0.5, 1)
	taskbar.BackgroundColor3 = theme.Glass or DEFAULT_THEME.Glass
	taskbar.BackgroundTransparency = 0.08
	taskbar.BorderSizePixel = 0
	taskbar.Position = UDim2.new(0.5, 0, 1, -16)
	taskbar.Size = TASKBAR_DESKTOP_SIZE
	taskbar.ZIndex = 850
	addCorner(taskbar, 18)
	addStroke(taskbar, theme.Stroke or DEFAULT_THEME.Stroke, 0.46, 1)
	taskbar.Parent = desktop
	self.Taskbar = taskbar

	addPadding(taskbar, 10, 8, 10, 8)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = taskbar

	local start = Instance.new("TextButton")
	start.Name = "StartButton"
	start.AutoButtonColor = false
	start.BackgroundColor3 = theme.GlassStrong or DEFAULT_THEME.GlassStrong
	start.BackgroundTransparency = 0.08
	start.BorderSizePixel = 0
	start.LayoutOrder = 1
	start.Size = UDim2.fromOffset(72, 42)
	start.Text = "Start"
	start.TextColor3 = theme.Text or DEFAULT_THEME.Text
	start.TextSize = 13
	start.Font = Enum.Font.GothamMedium
	start.ZIndex = taskbar.ZIndex + 1
	addCorner(start, 12)
	addStroke(start, theme.Stroke or DEFAULT_THEME.Stroke, 0.52, 1)
	start.Parent = taskbar
	self.StartButton = start

	local taskList = Instance.new("Frame")
	taskList.Name = "TaskList"
	taskList.AutomaticSize = Enum.AutomaticSize.X
	taskList.BackgroundTransparency = 1
	taskList.LayoutOrder = 2
	taskList.Size = UDim2.fromOffset(0, 42)
	taskList.ZIndex = taskbar.ZIndex + 1
	taskList.Parent = taskbar
	self.TaskbarList = taskList

	local taskLayout = Instance.new("UIListLayout")
	taskLayout.FillDirection = Enum.FillDirection.Horizontal
	taskLayout.Padding = UDim.new(0, 8)
	taskLayout.SortOrder = Enum.SortOrder.LayoutOrder
	taskLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	taskLayout.Parent = taskList

	table.insert(
		self.Connections,
		start.MouseButton1Click:Connect(function()
			self:ToggleStart()
		end)
	)

	for _, connection in
		addButtonMotion(
			start,
			theme.GlassStrong or DEFAULT_THEME.GlassStrong,
			Color3.fromRGB(245, 249, 255),
			Color3.fromRGB(229, 238, 255),
			nil
		)
	do
		table.insert(self.Connections, connection)
	end
end

function WindowUI:_preferredStartHeight(): number
	if self.Mobile then
		return math.min(START_MENU_MOBILE_HEIGHT, math.max(360, self.Desktop.AbsoluteSize.Y - 112))
	end

	return START_MENU_DESKTOP_SIZE.Y.Offset
end

function WindowUI:_raiseStartMenu()
	self.ZCounter += 1
	if self.StartMenu then
		self.StartMenu.ZIndex = self.ZCounter
		for _, descendant in self.StartMenu:GetDescendants() do
			if descendant:IsA("GuiObject") then
				descendant.ZIndex = self.ZCounter + 1
			end
		end
	end
end

function WindowUI:_updateResponsiveLayout()
	local desktop: Frame = self.Desktop
	local viewport = desktop.AbsoluteSize
	local mobile = UserInputService.TouchEnabled or viewport.X < 760
	self.Mobile = mobile

	if self.StartMenu then
		if mobile then
			self.StartMenu.AnchorPoint = Vector2.new(0.5, 0)
			self.StartMenu.Position = UDim2.new(0.5, 0, 0, 54)
			self.StartMenu.Size = UDim2.new(1, -24, 0, self:_preferredStartHeight())
		else
			self.StartMenu.AnchorPoint = Vector2.new(0.5, 0.5)
			self.StartMenu.Position = UDim2.fromScale(0.5, 0.5)
			self.StartMenu.Size = START_MENU_DESKTOP_SIZE
		end
	end

	if self.AppGrid then
		self.AppGrid.CellPadding = if mobile then UDim2.fromOffset(12, 14) else UDim2.fromOffset(16, 16)
		self.AppGrid.CellSize = if mobile then UDim2.fromOffset(78, 92) else UDim2.fromOffset(86, 96)
	end

	if self.Taskbar then
		self.Taskbar.Size = if mobile then TASKBAR_MOBILE_SIZE else TASKBAR_DESKTOP_SIZE
		self.Taskbar.Position = UDim2.new(0.5, 0, 1, if mobile then -10 else -16)
	end

	for _, app in self.Apps do
		app:_fitForViewport(mobile)
	end
end

function WindowUI:ToggleStart(force: boolean?)
	local menu: Frame? = self.StartMenu
	if not menu then
		return
	end

	local nextVisible = if force ~= nil then force else not menu.Visible
	menu.Visible = nextVisible

	if nextVisible then
		self:_raiseStartMenu()
		local scale = menu:FindFirstChild("OpenScale") :: UIScale?
		if not scale then
			scale = Instance.new("UIScale")
			scale.Name = "OpenScale"
			scale.Parent = menu
		end

		scale.Scale = 0.965
		menu.BackgroundTransparency = 0.2
		tween(scale, TWEEN_SOFT, { Scale = 1 })
		tween(menu, TWEEN_SOFT, { BackgroundTransparency = 0.08 })
	end
end

function WindowUI:CreateApp(config: AppConfig)
	assert(typeof(config.Name) == "string" and config.Name ~= "", "AppConfig.Name is required.")
	assert(typeof(config.Icon) == "string" and config.Icon ~= "", "AppConfig.Icon is required.")
	assert(
		typeof(config.BackgroundImage) == "string" and config.BackgroundImage ~= "",
		"AppConfig.BackgroundImage is required."
	)

	local app = AppWindow.new(self, config)
	table.insert(self.Apps, app)
	self.AppByName[config.Name] = app
	self:_updateResponsiveLayout()
	return app
end

function WindowUI:OpenApp(name: string)
	local app = self.AppByName[name]
	if app then
		app:Open()
	else
		warn(`[WindowUILibrary] app "{name}" does not exist.`)
	end
end

function WindowUI:Destroy()
	for _, app in self.Apps do
		app:Destroy()
	end

	disconnectAll(self.Connections)

	if self.Gui then
		self.Gui:Destroy()
	end
end

function AppWindow.new(library: any, config: AppConfig)
	local self = setmetatable({
		Library = library,
		Name = config.Name,
		Config = config,
		Frame = nil :: Frame?,
		Content = nil :: ScrollingFrame?,
		Tile = nil :: Frame?,
		TaskButton = nil :: TextButton?,
		Scale = nil :: UIScale?,
		Connections = {} :: ConnectionList,
		MinSize = config.MinSize or Vector2.new(340, 260),
		LastDesktopSize = config.Size or UDim2.fromOffset(560, 390),
		LastDesktopPosition = config.Position,
		Minimized = false,
		OpenState = false,
		MobileFit = false,
	}, AppWindow)

	self:_buildTile()
	self:_buildWindow()
	self:_buildTaskButton()

	if config.StartOpen then
		self:Open()
	end

	return self
end

function AppWindow:_buildTile()
	local library = self.Library
	local theme: Theme = library.Theme
	local config: AppConfig = self.Config

	local tile = Instance.new("Frame")
	tile.Name = config.Name
	tile.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tile.BackgroundTransparency = 0.2
	tile.BorderSizePixel = 0
	tile.LayoutOrder = config.Order or (#library.Apps + 1)
	tile.ClipsDescendants = true
	tile.ZIndex = library.StartMenu.ZIndex + 1
	addCorner(tile, 14)
	addStroke(tile, theme.Stroke or DEFAULT_THEME.Stroke, 0.55, 1)
	tile.Parent = library.StartBody
	self.Tile = tile

	local image = Instance.new("ImageLabel")
	image.Name = "TileImage"
	image.BackgroundTransparency = 1
	image.Image = config.TileImage or config.BackgroundImage
	image.ImageTransparency = 0.22
	image.ScaleType = Enum.ScaleType.Crop
	image.Size = UDim2.fromScale(1, 1)
	image.ZIndex = tile.ZIndex
	image.Parent = tile

	local overlay = Instance.new("Frame")
	overlay.Name = "GlassOverlay"
	overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	overlay.BackgroundTransparency = 0.34
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = tile.ZIndex + 1
	overlay.Parent = tile

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Image = config.Icon
	icon.Position = UDim2.new(0.5, 0, 0, 11)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Size = UDim2.fromOffset(40, 40)
	icon.ZIndex = tile.ZIndex + 2
	icon.Parent = tile

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 7, 0, 56)
	label.Size = UDim2.new(1, -14, 0, 34)
	label.Text = config.Name
	label.TextColor3 = theme.Text or DEFAULT_THEME.Text
	label.TextSize = 11
	label.Font = Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.ZIndex = tile.ZIndex + 2
	label.Parent = tile

	local hit = Instance.new("TextButton")
	hit.Name = "Hitbox"
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.Size = UDim2.fromScale(1, 1)
	hit.Text = ""
	hit.ZIndex = tile.ZIndex + 3
	hit.Parent = tile

	local scale = Instance.new("UIScale")
	scale.Parent = tile

	table.insert(
		self.Connections,
		hit.MouseButton1Click:Connect(function()
			library:ToggleStart(false)
			self:Open()
		end)
	)

	for _, connection in
		addButtonMotion(
			hit,
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(238, 244, 255),
			scale
		)
	do
		table.insert(self.Connections, connection)
	end
end

function AppWindow:_buildWindow()
	local library = self.Library
	local theme: Theme = library.Theme
	local config: AppConfig = self.Config
	local desktop: Frame = library.Desktop

	local frame = Instance.new("Frame")
	frame.Name = `{config.Name}Window`
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = theme.Glass or DEFAULT_THEME.Glass
	frame.BackgroundTransparency = 0.06
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Position = config.Position or UDim2.new(0.5, (#library.Apps % 4) * 22, 0.5, (#library.Apps % 4) * 18)
	frame.Size = config.Size or UDim2.fromOffset(560, 390)
	frame.Visible = false
	frame.ZIndex = library.ZCounter
	addCorner(frame, 12)
	addStroke(frame, theme.Stroke or DEFAULT_THEME.Stroke, 0.48, 1)
	frame.Parent = desktop
	self.Frame = frame

	local openScale = Instance.new("UIScale")
	openScale.Name = "OpenScale"
	openScale.Parent = frame
	self.Scale = openScale

	local background = Instance.new("ImageLabel")
	background.Name = "WindowImage"
	background.BackgroundTransparency = 1
	background.Image = config.WindowImage or config.BackgroundImage
	background.ImageTransparency = 0.78
	background.ScaleType = Enum.ScaleType.Crop
	background.Size = UDim2.fromScale(1, 1)
	background.ZIndex = frame.ZIndex
	background.Parent = frame

	local veil = Instance.new("Frame")
	veil.Name = "GlassVeil"
	veil.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	veil.BackgroundTransparency = 0.36
	veil.BorderSizePixel = 0
	veil.Size = UDim2.fromScale(1, 1)
	veil.ZIndex = frame.ZIndex + 1
	veil.Parent = frame

	local topbar = Instance.new("Frame")
	topbar.Name = "Topbar"
	topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topbar.BackgroundTransparency = 0.28
	topbar.BorderSizePixel = 0
	topbar.Size = UDim2.new(1, 0, 0, 44)
	topbar.ZIndex = frame.ZIndex + 2
	topbar.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Image = config.Icon
	icon.Position = UDim2.fromOffset(12, 9)
	icon.Size = UDim2.fromOffset(26, 26)
	icon.ZIndex = topbar.ZIndex + 1
	icon.Parent = topbar

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(48, 0)
	title.Size = UDim2.new(1, -138, 1, 0)
	title.Text = config.Name
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.ZIndex = topbar.ZIndex + 1
	setTextStyle(title, theme.Text or DEFAULT_THEME.Text, 14, Enum.Font.GothamMedium)
	title.Parent = topbar

	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.AnchorPoint = Vector2.new(1, 0.5)
	controls.BackgroundTransparency = 1
	controls.Position = UDim2.new(1, -10, 0.5, 0)
	controls.Size = UDim2.fromOffset(66, 24)
	controls.ZIndex = topbar.ZIndex + 1
	controls.Parent = topbar

	local controlLayout = Instance.new("UIListLayout")
	controlLayout.FillDirection = Enum.FillDirection.Horizontal
	controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlLayout.Padding = UDim.new(0, 6)
	controlLayout.Parent = controls

	local minimize = createTopButton("-", theme)
	minimize.LayoutOrder = 1
	minimize.ZIndex = controls.ZIndex + 1
	minimize.Parent = controls

	local close = createTopButton("x", theme)
	close.LayoutOrder = 2
	close.ZIndex = controls.ZIndex + 1
	close.Parent = controls

	table.insert(
		self.Connections,
		minimize.MouseButton1Click:Connect(function()
			self:Minimize()
		end)
	)

	table.insert(
		self.Connections,
		close.MouseButton1Click:Connect(function()
			self:Close()
		end)
	)

	for _, connection in
		makeDraggable(topbar, frame, function()
			self:BringToFront()
		end)
	do
		table.insert(self.Connections, connection)
	end

	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Active = true
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.CanvasSize = UDim2.fromOffset(0, 0)
	content.Position = UDim2.fromOffset(0, 44)
	content.ScrollBarImageColor3 = theme.Accent or DEFAULT_THEME.Accent
	content.ScrollBarImageTransparency = 0.38
	content.ScrollBarThickness = 4
	content.Size = UDim2.new(1, 0, 1, -44)
	content.ZIndex = frame.ZIndex + 2
	content.Parent = frame
	self.Content = content

	addPadding(content, 16, 16, 16, 20)

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 12)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = content

	local resize = Instance.new("TextButton")
	resize.Name = "ResizeGrip"
	resize.AnchorPoint = Vector2.new(1, 1)
	resize.AutoButtonColor = false
	resize.BackgroundColor3 = theme.Accent or DEFAULT_THEME.Accent
	resize.BackgroundTransparency = 0.2
	resize.BorderSizePixel = 0
	resize.Position = UDim2.fromScale(1, 1)
	resize.Size = UDim2.fromOffset(26, 26)
	resize.Text = "/"
	resize.TextColor3 = Color3.fromRGB(255, 255, 255)
	resize.TextSize = 18
	resize.Font = Enum.Font.GothamBold
	resize.ZIndex = frame.ZIndex + 4
	addCorner(resize, 8)
	resize.Parent = frame

	for _, connection in
		makeResizable(resize, frame, self.MinSize, function()
			self:BringToFront()
		end)
	do
		table.insert(self.Connections, connection)
	end

	table.insert(
		self.Connections,
		frame.InputBegan:Connect(function(input: InputObject)
			if isPressInput(input) then
				self:BringToFront()
			end
		end)
	)
end

function AppWindow:_buildTaskButton()
	local library = self.Library
	local theme: Theme = library.Theme
	local config: AppConfig = self.Config

	local button = Instance.new("TextButton")
	button.Name = `{config.Name}Task`
	button.AutoButtonColor = false
	button.BackgroundColor3 = theme.GlassStrong or DEFAULT_THEME.GlassStrong
	button.BackgroundTransparency = 0.12
	button.BorderSizePixel = 0
	button.LayoutOrder = config.Order or (#library.Apps + 10)
	button.Size = UDim2.fromOffset(46, 42)
	button.Text = ""
	button.ZIndex = 852
	addCorner(button, 12)
	addStroke(button, theme.Stroke or DEFAULT_THEME.Stroke, 0.56, 1)
	button.Parent = library.TaskbarList
	self.TaskButton = button

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = config.Icon
	icon.Position = UDim2.fromOffset(9, 7)
	icon.Size = UDim2.fromOffset(28, 28)
	icon.ZIndex = button.ZIndex + 1
	icon.Parent = button

	table.insert(
		self.Connections,
		button.MouseButton1Click:Connect(function()
			if self.Frame and self.Frame.Visible then
				self:Minimize()
			else
				self:Open()
			end
		end)
	)

	for _, connection in
		addButtonMotion(
			button,
			theme.GlassStrong or DEFAULT_THEME.GlassStrong,
			Color3.fromRGB(245, 249, 255),
			Color3.fromRGB(229, 238, 255),
			nil
		)
	do
		table.insert(self.Connections, connection)
	end
end

function AppWindow:_fitForViewport(mobile: boolean)
	local frame: Frame? = self.Frame
	if not frame then
		return
	end

	if mobile then
		if not self.MobileFit then
			self.LastDesktopSize = frame.Size
			self.LastDesktopPosition = frame.Position
		end

		self.MobileFit = true
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.Position = UDim2.new(0.5, 0, 0, 56)
		frame.Size = UDim2.new(1, -24, 1, -128)
	else
		self.MobileFit = false
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		if self.LastDesktopPosition then
			frame.Position = self.LastDesktopPosition
		else
			frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		end
		frame.Size = self.LastDesktopSize
	end
end

function AppWindow:_syncZ()
	local frame: Frame? = self.Frame
	if not frame then
		return
	end

	local base = frame.ZIndex
	for _, descendant in frame:GetDescendants() do
		if descendant:IsA("GuiObject") then
			if descendant.Name == "WindowImage" then
				descendant.ZIndex = base
			elseif descendant.Name == "GlassVeil" then
				descendant.ZIndex = base + 1
			elseif descendant.Name == "ResizeGrip" then
				descendant.ZIndex = base + 4
			else
				descendant.ZIndex = base + 2
			end
		end
	end
end

function AppWindow:BringToFront()
	local library = self.Library
	library.ZCounter += 1

	if self.Frame then
		self.Frame.ZIndex = library.ZCounter
		self:_syncZ()
	end
end

function AppWindow:Open()
	local frame: Frame? = self.Frame
	if not frame then
		return
	end

	self.Minimized = false
	self.OpenState = true
	frame.Visible = true
	self:BringToFront()

	if self.Scale then
		self.Scale.Scale = 0.965
		tween(self.Scale, TWEEN_SOFT, { Scale = 1 })
	end

	frame.BackgroundTransparency = 0.18
	tween(frame, TWEEN_SOFT, { BackgroundTransparency = 0.06 })

	if self.TaskButton then
		tween(self.TaskButton, TWEEN_FAST, { BackgroundTransparency = 0.02 })
	end
end

function AppWindow:Minimize()
	local frame: Frame? = self.Frame
	if not frame then
		return
	end

	self.Minimized = true
	self.OpenState = false
	frame.Visible = false

	if self.TaskButton then
		tween(self.TaskButton, TWEEN_FAST, { BackgroundTransparency = 0.18 })
	end
end

function AppWindow:Close()
	local frame: Frame? = self.Frame
	if not frame then
		return
	end

	self.Minimized = false
	self.OpenState = false
	frame.Visible = false

	if self.TaskButton then
		tween(self.TaskButton, TWEEN_FAST, { BackgroundTransparency = 0.3 })
	end
end

function AppWindow:Destroy()
	disconnectAll(self.Connections)

	if self.Frame then
		self.Frame:Destroy()
	end

	if self.Tile then
		self.Tile:Destroy()
	end

	if self.TaskButton then
		self.TaskButton:Destroy()
	end
end

function AppWindow:CreateSection(titleText: string): Frame
	local library = self.Library
	local theme: Theme = library.Theme
	local content: ScrollingFrame = self.Content

	local section = Instance.new("Frame")
	section.Name = titleText
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	section.BackgroundTransparency = 0.18
	section.BorderSizePixel = 0
	section.Size = UDim2.new(1, 0, 0, 0)
	section.ClipsDescendants = true
	addCorner(section, 12)
	addStroke(section, theme.Stroke or DEFAULT_THEME.Stroke, 0.56, 1)
	addPadding(section, 12, 12, 12, 12)
	section.Parent = content

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = section

	local title = Instance.new("TextLabel")
	title.Name = "SectionTitle"
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 0)
	title.Text = titleText
	title.TextYAlignment = Enum.TextYAlignment.Center
	setTextStyle(title, theme.Text or DEFAULT_THEME.Text, 14, Enum.Font.GothamBold)
	title.Parent = section

	self:_syncZ()

	return section
end

function AppWindow:_controlParent(section: Frame?): Instance
	return section or self.Content
end

function AppWindow:AddLabel(text: string, section: Frame?): TextLabel
	local library = self.Library
	local theme: Theme = library.Theme

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.Text = text
	label.TextYAlignment = Enum.TextYAlignment.Top
	setTextStyle(label, theme.MutedText or DEFAULT_THEME.MutedText, 13, Enum.Font.Gotham)
	label.Parent = self:_controlParent(section)

	self:_syncZ()

	return label
end

function AppWindow:AddButton(config: ButtonConfig, section: Frame?): TextButton
	local library = self.Library
	local theme: Theme = library.Theme

	local button = Instance.new("TextButton")
	button.Name = config.Text
	button.AutoButtonColor = false
	button.BackgroundColor3 = theme.Accent or DEFAULT_THEME.Accent
	button.BorderSizePixel = 0
	button.Size = UDim2.new(1, 0, 0, 42)
	button.Text = config.Text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.GothamMedium
	button.TextXAlignment = Enum.TextXAlignment.Center
	addCorner(button, 10)
	button.Parent = self:_controlParent(section)

	table.insert(
		self.Connections,
		button.MouseButton1Click:Connect(function()
			safeCallback(config.Callback)
		end)
	)

	self:_syncZ()

	return button
end

function AppWindow:AddToggle(config: ToggleConfig, section: Frame?): TextButton
	local library = self.Library
	local theme: Theme = library.Theme
	local enabled = config.Default == true

	local row = Instance.new("TextButton")
	row.Name = config.Text
	row.AutoButtonColor = false
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = 0.16
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 46)
	row.Text = ""
	addCorner(row, 10)
	addStroke(row, theme.Stroke or DEFAULT_THEME.Stroke, 0.58, 1)
	row.Parent = self:_controlParent(section)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -74, 1, 0)
	label.Text = config.Text
	label.TextYAlignment = Enum.TextYAlignment.Center
	setTextStyle(label, theme.Text or DEFAULT_THEME.Text, 13, Enum.Font.GothamMedium)
	label.Parent = row

	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.BackgroundColor3 = if enabled then (theme.Accent or DEFAULT_THEME.Accent) else Color3.fromRGB(190, 198, 213)
	track.BorderSizePixel = 0
	track.Position = UDim2.new(1, -12, 0.5, 0)
	track.Size = UDim2.fromOffset(44, 24)
	addCorner(track, 999)
	track.Parent = row

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Position = if enabled then UDim2.new(1, -12, 0.5, 0) else UDim2.new(0, 12, 0.5, 0)
	knob.Size = UDim2.fromOffset(18, 18)
	addCorner(knob, 999)
	knob.Parent = track

	local function render()
		tween(track, TWEEN_FAST, {
			BackgroundColor3 = if enabled
				then (theme.Accent or DEFAULT_THEME.Accent)
				else Color3.fromRGB(190, 198, 213),
		})
		tween(knob, TWEEN_FAST, {
			Position = if enabled then UDim2.new(1, -12, 0.5, 0) else UDim2.new(0, 12, 0.5, 0),
		})
	end

	table.insert(
		self.Connections,
		row.MouseButton1Click:Connect(function()
			enabled = not enabled
			render()
			safeValueCallback(config.Callback, enabled)
		end)
	)

	self:_syncZ()

	return row
end

function AppWindow:AddSlider(config: SliderConfig, section: Frame?): Frame
	local library = self.Library
	local theme: Theme = library.Theme
	local min = config.Min or 0
	local max = config.Max or 100
	local step = config.Step or 1
	local value = math.clamp(config.Default or min, min, max)

	local shell = Instance.new("Frame")
	shell.Name = config.Text
	shell.AutomaticSize = Enum.AutomaticSize.Y
	shell.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shell.BackgroundTransparency = 0.16
	shell.BorderSizePixel = 0
	shell.Size = UDim2.new(1, 0, 0, 0)
	addCorner(shell, 10)
	addStroke(shell, theme.Stroke or DEFAULT_THEME.Stroke, 0.58, 1)
	addPadding(shell, 12, 10, 12, 12)
	shell.Parent = self:_controlParent(section)

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = shell

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 20)
	header.Text = ""
	setTextStyle(header, theme.Text or DEFAULT_THEME.Text, 13, Enum.Font.GothamMedium)
	header.Parent = shell

	local bar = Instance.new("TextButton")
	bar.AutoButtonColor = false
	bar.BackgroundColor3 = Color3.fromRGB(202, 212, 231)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 0, 10)
	bar.Text = ""
	addCorner(bar, 999)
	bar.Parent = shell

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = theme.Accent or DEFAULT_THEME.Accent
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	addCorner(fill, 999)
	fill.Parent = bar

	local function snap(raw: number): number
		local snapped = math.round(raw / step) * step
		return math.clamp(snapped, min, max)
	end

	local function render(nextValue: number, fire: boolean)
		value = snap(nextValue)
		local alpha = if max == min then 0 else (value - min) / (max - min)
		header.Text = `{config.Text}: {value}`
		fill.Size = UDim2.fromScale(alpha, 1)

		if fire then
			safeValueCallback(config.Callback, value)
		end
	end

	local dragging = false
	local function updateFromInput(input: InputObject, fire: boolean)
		local x = math.clamp(pointer(input).X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
		local alpha = if bar.AbsoluteSize.X == 0 then 0 else x / bar.AbsoluteSize.X
		render(min + ((max - min) * alpha), fire)
	end

	table.insert(
		self.Connections,
		bar.InputBegan:Connect(function(input: InputObject)
			if not isPressInput(input) then
				return
			end

			dragging = true
			updateFromInput(input, true)
		end)
	)

	table.insert(
		self.Connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if dragging and isMoveInput(input) then
				updateFromInput(input, true)
			end
		end)
	)

	table.insert(
		self.Connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if isPressInput(input) then
				dragging = false
			end
		end)
	)

	render(value, false)
	self:_syncZ()
	return shell
end

function AppWindow:AddTextBox(config: TextBoxConfig, section: Frame?): TextBox
	local library = self.Library
	local theme: Theme = library.Theme

	local box = Instance.new("TextBox")
	box.Name = config.Text
	box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	box.BackgroundTransparency = 0.12
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.PlaceholderText = config.Placeholder or config.Text
	box.PlaceholderColor3 = theme.MutedText or DEFAULT_THEME.MutedText
	box.Size = UDim2.new(1, 0, 0, 42)
	box.Text = config.Default or ""
	setTextStyle(box, theme.Text or DEFAULT_THEME.Text, 13, Enum.Font.Gotham)
	box.TextXAlignment = Enum.TextXAlignment.Left
	addCorner(box, 10)
	addStroke(box, theme.Stroke or DEFAULT_THEME.Stroke, 0.58, 1)
	addPadding(box, 12, 0, 12, 0)
	box.Parent = self:_controlParent(section)

	table.insert(
		self.Connections,
		box.FocusLost:Connect(function(enterPressed: boolean)
			if enterPressed then
				safeValueCallback(config.Callback, box.Text)
			end
		end)
	)

	self:_syncZ()

	return box
end

function AppWindow:AddDropdown(config: DropdownConfig, section: Frame?): Frame
	local library = self.Library
	local theme: Theme = library.Theme
	local selected = config.Default or config.Options[1] or ""

	local shell = Instance.new("Frame")
	shell.Name = config.Text
	shell.AutomaticSize = Enum.AutomaticSize.Y
	shell.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shell.BackgroundTransparency = 0.16
	shell.BorderSizePixel = 0
	shell.Size = UDim2.new(1, 0, 0, 0)
	addCorner(shell, 10)
	addStroke(shell, theme.Stroke or DEFAULT_THEME.Stroke, 0.58, 1)
	addPadding(shell, 8, 8, 8, 8)
	shell.Parent = self:_controlParent(section)

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = shell

	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.fromRGB(245, 249, 255)
	button.BorderSizePixel = 0
	button.Size = UDim2.new(1, 0, 0, 38)
	button.Text = `{config.Text}: {selected}`
	button.TextColor3 = theme.Text or DEFAULT_THEME.Text
	button.TextSize = 13
	button.Font = Enum.Font.GothamMedium
	button.TextXAlignment = Enum.TextXAlignment.Left
	addCorner(button, 8)
	addPadding(button, 10, 0, 10, 0)
	button.Parent = shell

	local optionsFrame = Instance.new("Frame")
	optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Size = UDim2.new(1, 0, 0, 0)
	optionsFrame.Visible = false
	optionsFrame.Parent = shell

	local optionsList = Instance.new("UIListLayout")
	optionsList.Padding = UDim.new(0, 6)
	optionsList.SortOrder = Enum.SortOrder.LayoutOrder
	optionsList.Parent = optionsFrame

	table.insert(
		self.Connections,
		button.MouseButton1Click:Connect(function()
			optionsFrame.Visible = not optionsFrame.Visible
		end)
	)

	for index, option in config.Options do
		local optionButton = Instance.new("TextButton")
		optionButton.AutoButtonColor = false
		optionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		optionButton.BackgroundTransparency = 0.1
		optionButton.BorderSizePixel = 0
		optionButton.LayoutOrder = index
		optionButton.Size = UDim2.new(1, 0, 0, 34)
		optionButton.Text = option
		optionButton.TextColor3 = theme.Text or DEFAULT_THEME.Text
		optionButton.TextSize = 13
		optionButton.Font = Enum.Font.Gotham
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		addCorner(optionButton, 8)
		addPadding(optionButton, 10, 0, 10, 0)
		optionButton.Parent = optionsFrame

		table.insert(
			self.Connections,
			optionButton.MouseButton1Click:Connect(function()
				selected = option
				button.Text = `{config.Text}: {selected}`
				optionsFrame.Visible = false
				safeValueCallback(config.Callback, selected)
			end)
		)
	end

	self:_syncZ()

	return shell
end

return WindowUI
