--!strict

local rawGame = game

local function getGlobal(name: string): any?
	local ok, env = pcall(getfenv, 0)
	if ok and type(env) == "table" then
		if env[name] ~= nil then
			return env[name]
		end

		for _, getterName in ipairs({ "getgenv", "getrenv" }) do
			local getter = env[getterName]
			if type(getter) == "function" then
				local gotEnvOk, gotEnv = pcall(getter)
				if gotEnvOk and type(gotEnv) == "table" and gotEnv[name] ~= nil then
					return gotEnv[name]
				end
			end
		end
	end

	return nil
end

local executorCloneRef = getGlobal("cloneref")

local function cloneRef<T>(instance: T): T
	if type(executorCloneRef) ~= "function" then
		return instance
	end

	local ok, cloned = pcall(executorCloneRef, instance)
	if ok and cloned ~= nil then
		return cloned
	end

	return instance
end

local function getService<T>(serviceName: string): T
	return cloneRef((rawGame :: any):GetService(serviceName)) :: T
end

local Players = getService("Players") :: Players
local CoreGui = getService("CoreGui") :: CoreGui
local TweenService = getService("TweenService") :: TweenService
local UserInputService = getService("UserInputService") :: UserInputService
local Workspace = getService("Workspace") :: Workspace

local LOCAL_PLAYER = Players.LocalPlayer

local WindowUI = {}
WindowUI.__index = WindowUI

local App = {}
App.__index = App

export type Theme = {
	Accent: Color3?,
	Window: Color3?,
	Topbar: Color3?,
	TopbarText: Color3?,
	Surface: Color3?,
	SurfaceStrong: Color3?,
	Tile: Color3?,
	TileHover: Color3?,
	Button: Color3?,
	ButtonHover: Color3?,
	Text: Color3?,
	MutedText: Color3?,
	Stroke: Color3?,
	Shadow: Color3?,
	Danger: Color3?,
}

export type TopbarPlusConfig = {
	Enabled: boolean?,
	Source: string?,
	Icon: any?,
	Align: string?,
	Label: string?,
	Caption: string?,
	Order: number?,
	Width: number?,
	Image: number | string?,
	ImageScale: number?,
}

export type WindowConfig = {
	Name: string?,
	Title: string?,
	Parent: Instance?,
	Size: UDim2?,
	Position: UDim2?,
	Scale: number?,
	StartOpen: boolean?,
	DisplayOrder: number?,
	ResetOnSpawn: boolean?,
	TopbarPlus: boolean | TopbarPlusConfig?,
	Theme: Theme?,
}

export type AppConfig = {
	Name: string,
	Icon: string?,
	BackgroundImage: string?,
	TileImage: string?,
	Order: number?,
	StartOpen: boolean?,
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

local DEFAULT_TOPBARPLUS_SOURCE =
	"https://raw.githubusercontent.com/tanhoangviet/ToolForLua/refs/heads/main/TopbarPlus_Extended.lua"

local DEFAULT_THEME = {
	Accent = Color3.fromRGB(94, 151, 255),
	Window = Color3.fromRGB(24, 27, 36),
	Topbar = Color3.fromRGB(18, 20, 28),
	TopbarText = Color3.fromRGB(238, 241, 248),
	Surface = Color3.fromRGB(31, 35, 46),
	SurfaceStrong = Color3.fromRGB(42, 47, 61),
	Tile = Color3.fromRGB(32, 36, 47),
	TileHover = Color3.fromRGB(48, 54, 70),
	Button = Color3.fromRGB(38, 43, 56),
	ButtonHover = Color3.fromRGB(53, 60, 77),
	Text = Color3.fromRGB(238, 241, 247),
	MutedText = Color3.fromRGB(165, 173, 190),
	Stroke = Color3.fromRGB(73, 82, 104),
	Shadow = Color3.fromRGB(0, 0, 0),
	Danger = Color3.fromRGB(255, 91, 91),
}

local TWEEN_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SOFT = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function getPlayerGui(): Instance
	if LOCAL_PLAYER then
		return LOCAL_PLAYER:WaitForChild("PlayerGui")
	end

	error("WindowUILibrary must run from a LocalScript so Players.LocalPlayer exists.")
end

local function getExecutorGuiParent(): Instance
	local getHui = getGlobal("gethui")
	if type(getHui) == "function" then
		local ok, hui = pcall(getHui)
		if ok and typeof(hui) == "Instance" then
			return cloneRef(hui)
		end
	end

	return CoreGui
end

local function protectGui(gui: ScreenGui)
	local protect = getGlobal("protectgui")
	if type(protect) == "function" then
		pcall(protect, gui)
		return
	end

	local syn = getGlobal("syn")
	if type(syn) == "table" and type(syn.protect_gui) == "function" then
		pcall(syn.protect_gui, gui)
	end
end

local function create(className: string, props: { [string]: any }): any
	local instance = Instance.new(className)
	local parent = props.Parent

	for key, value in pairs(props) do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function tween(instance: Instance, info: TweenInfo, properties: { [string]: any })
	local created = TweenService:Create(instance, info, properties)
	created:Play()
	return created
end

local function mergeTheme(theme: Theme?): Theme
	local merged: { [string]: Color3 } = {}

	for key, value in pairs(DEFAULT_THEME) do
		merged[key] = value
	end

	if theme then
		for key, value in pairs(theme :: any) do
			if typeof(value) == "Color3" then
				merged[key] = value
			end
		end
	end

	return merged :: any
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

local function addList(parent: GuiObject, padding: number): UIListLayout
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, padding)
	list.Parent = parent
	return list
end

local function addShadow(parent: GuiObject, theme: Theme)
	pcall(function()
		local shadow = Instance.new("UIShadow")
		local anyShadow = shadow :: any
		anyShadow.BlurRadius = UDim.new(0, 18)
		anyShadow.Color = theme.Shadow or DEFAULT_THEME.Shadow
		anyShadow.Offset = UDim2.fromOffset(0, 10)
		anyShadow.Spread = UDim2.fromOffset(0, 2)
		anyShadow.Transparency = 0.45
		shadow.Parent = parent
	end)
end

local function setText(label: TextLabel | TextButton | TextBox, color: Color3, size: number, font: Enum.Font)
	label.Font = font
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

local function isPressInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMoveInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function pointer(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function getViewport(): Vector2
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

local function clampToViewport(frame: GuiObject, wanted: Vector2): Vector2
	local viewport = getViewport()
	local size = frame.AbsoluteSize
	local margin = 8
	local topMargin = 44
	local maxX = math.max(margin, viewport.X - size.X - margin)
	local maxY = math.max(topMargin, viewport.Y - size.Y - margin)

	return Vector2.new(math.clamp(wanted.X, margin, maxX), math.clamp(wanted.Y, topMargin, maxY))
end

local function formatNumber(value: number): string
	if math.abs(value - math.floor(value)) < 0.001 then
		return tostring(math.floor(value))
	end

	return string.format("%.2f", value)
end

local function drawWindowsGlyph(parent: GuiObject, name: string?)
	local old = parent:FindFirstChild(name or "WindowsGlyph")
	if old then
		old:Destroy()
	end

	local glyph = create("Frame", {
		Name = name or "WindowsGlyph",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = (parent.ZIndex or 1) + 2,
		Parent = parent,
	}) :: Frame

	local paneData = {
		UDim2.fromOffset(1, 1),
		UDim2.fromOffset(9, 1),
		UDim2.fromOffset(1, 9),
		UDim2.fromOffset(9, 9),
	}

	for index, position in ipairs(paneData) do
		create("Frame", {
			Name = "Pane" .. index,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Position = position,
			Size = UDim2.fromOffset(6, 6),
			ZIndex = glyph.ZIndex + 1,
			Parent = glyph,
		})
	end
end

local function bindButtonMotion(owner: any, button: GuiButton, normal: Color3, hover: Color3, down: Color3)
	owner:_track(button.MouseEnter:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = hover })
	end))

	owner:_track(button.MouseLeave:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = normal })
	end))

	owner:_track(button.MouseButton1Down:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = down })
	end))

	owner:_track(button.MouseButton1Up:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = hover })
	end))
end

local function loadTopbarIcon(source: string): any?
	local loader = getGlobal("loadstring")
	if type(loader) ~= "function" then
		return nil
	end

	local ok, result = pcall(function()
		local code = (cloneRef(rawGame) :: any):HttpGet(source)
		local chunk = loader(code)
		return chunk()
	end)

	if not ok or type(result) ~= "table" then
		return nil
	end

	if result.Icon and type(result.Icon.new) == "function" then
		return result.Icon
	end

	if type(result.get) == "function" then
		local gotIcon = result.get()
		if type(gotIcon) == "table" and type(gotIcon.new) == "function" then
			return gotIcon
		end
	end

	if type(result.new) == "function" then
		return result
	end

	return nil
end

local function normalizeTopbarConfig(config: boolean | TopbarPlusConfig?): TopbarPlusConfig?
	if config == false then
		return nil
	end

	if config == nil or config == true then
		return {
			Enabled = true,
			Source = DEFAULT_TOPBARPLUS_SOURCE,
			Align = "Left",
			Width = 44,
		}
	end

	if config.Enabled == false then
		return nil
	end

	local normalized = config
	normalized.Source = normalized.Source or DEFAULT_TOPBARPLUS_SOURCE
	normalized.Align = normalized.Align or "Left"
	normalized.Width = normalized.Width or 44
	return normalized
end

function WindowUI:_track(connection: RBXScriptConnection): RBXScriptConnection
	table.insert(self._connections, connection)
	return connection
end

function WindowUI:_buildRoot()
	local config = self._config
	local theme = self._theme

	self.ScreenGui = create("ScreenGui", {
		Name = config.Name or "WindowUILibrary",
		DisplayOrder = config.DisplayOrder or 999999,
		IgnoreGuiInset = false,
		ResetOnSpawn = config.ResetOnSpawn == true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	protectGui(self.ScreenGui)
	self.ScreenGui.Parent = config.Parent or getExecutorGuiParent() or getPlayerGui()

	self.Window = create("Frame", {
		Name = "FloatWindow",
		Active = true,
		BackgroundColor3 = theme.Window or DEFAULT_THEME.Window,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = config.Position or UDim2.new(0.5, -250, 0.5, -160),
		Size = config.Size or UDim2.fromOffset(500, 320),
		Visible = config.StartOpen ~= false,
		Parent = self.ScreenGui,
	}) :: Frame

	self._baseSize = self.Window.Size
	self._basePosition = self.Window.Position
	self.WindowScale = create("UIScale", {
		Scale = config.Scale or 0.94,
		Parent = self.Window,
	}) :: UIScale

	create("UISizeConstraint", {
		MinSize = Vector2.new(288, 238),
		MaxSize = Vector2.new(820, 560),
		Parent = self.Window,
	})

	addStroke(self.Window, theme.Stroke or DEFAULT_THEME.Stroke, 0.32, 1)
	addShadow(self.Window, theme)

	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Window or DEFAULT_THEME.Window),
			ColorSequenceKeypoint.new(1, theme.Surface or DEFAULT_THEME.Surface),
		}),
		Rotation = 90,
		Parent = self.Window,
	})
end

function WindowUI:_buildTopbar()
	local theme = self._theme

	self.Topbar = create("Frame", {
		Name = "Topbar",
		BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 10,
		Parent = self.Window,
	}) :: Frame

	local title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -74, 1, 0),
		Text = self.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 11,
		Parent = self.Topbar,
	}) :: TextLabel
	setText(title, theme.TopbarText or DEFAULT_THEME.TopbarText, 13, Enum.Font.GothamMedium)

	self.MinimizeButton = create("TextButton", {
		Name = "Minimize",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -36, 0, 0),
		Size = UDim2.fromOffset(36, 36),
		Text = "-",
		TextColor3 = theme.TopbarText or DEFAULT_THEME.TopbarText,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		ZIndex = 12,
		Parent = self.Topbar,
	}) :: TextButton

	bindButtonMotion(
		self,
		self.MinimizeButton,
		theme.Topbar or DEFAULT_THEME.Topbar,
		theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong,
		theme.Button or DEFAULT_THEME.Button
	)
	self:_track(self.MinimizeButton.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end))
end

function WindowUI:_buildBody()
	local theme = self._theme

	self.Body = create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -36),
		Parent = self.Window,
	}) :: Frame

	self.HomePage = create("Frame", {
		Name = "HomePage",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = true,
		Parent = self.Body,
	}) :: Frame

	local homeTitle = create("TextLabel", {
		Name = "HomeTitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.new(1, -32, 0, 22),
		Text = "Apps",
		ZIndex = 2,
		Parent = self.HomePage,
	}) :: TextLabel
	setText(homeTitle, theme.Text or DEFAULT_THEME.Text, 16, Enum.Font.GothamSemibold)

	self.AppGridScroll = create("ScrollingFrame", {
		Name = "AppGrid",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromOffset(10, 42),
		ScrollBarImageColor3 = theme.MutedText or DEFAULT_THEME.MutedText,
		ScrollBarThickness = 3,
		Size = UDim2.new(1, -20, 1, -52),
		ZIndex = 2,
		Parent = self.HomePage,
	}) :: ScrollingFrame
	addPadding(self.AppGridScroll, 5, 3, 5, 10)

	self.AppGrid = create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(9, 9),
		CellSize = UDim2.fromOffset(80, 82),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.AppGridScroll,
	}) :: UIGridLayout

	self.AppPage = create("Frame", {
		Name = "AppPage",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = self.Body,
	}) :: Frame

	self.AppBackground = create("ImageLabel", {
		Name = "AppBackground",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		ImageTransparency = 0.28,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 0,
		Parent = self.AppPage,
	}) :: ImageLabel

	local appShade = create("Frame", {
		Name = "Shade",
		BackgroundColor3 = theme.Window or DEFAULT_THEME.Window,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = self.AppPage,
	}) :: Frame

	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Window or DEFAULT_THEME.Window),
			ColorSequenceKeypoint.new(1, theme.Surface or DEFAULT_THEME.Surface),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(1, 0.32),
		}),
		Rotation = 90,
		Parent = appShade,
	})

	local appHeader = create("Frame", {
		Name = "AppHeader",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 38),
		ZIndex = 3,
		Parent = self.AppPage,
	}) :: Frame

	self.BackButton = create("TextButton", {
		Name = "Back",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(32, 32),
		Text = "<",
		TextColor3 = theme.Text or DEFAULT_THEME.Text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		ZIndex = 4,
		Parent = appHeader,
	}) :: TextButton
	addStroke(self.BackButton, theme.Stroke or DEFAULT_THEME.Stroke, 0.55, 1)
	bindButtonMotion(
		self,
		self.BackButton,
		theme.Button or DEFAULT_THEME.Button,
		theme.ButtonHover or DEFAULT_THEME.ButtonHover,
		theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong
	)
	self:_track(self.BackButton.MouseButton1Click:Connect(function()
		self:OpenHome()
	end))

	self.AppIcon = create("ImageLabel", {
		Name = "AppIcon",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(44, 3),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 4,
		Parent = appHeader,
	}) :: ImageLabel

	self.AppTitle = create("TextLabel", {
		Name = "AppTitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(78, 0),
		Size = UDim2.new(1, -82, 0, 32),
		Text = "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = appHeader,
	}) :: TextLabel
	setText(self.AppTitle, theme.Text or DEFAULT_THEME.Text, 16, Enum.Font.GothamSemibold)

	self.ContentScroll = create("ScrollingFrame", {
		Name = "Content",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromOffset(14, 50),
		ScrollBarImageColor3 = theme.MutedText or DEFAULT_THEME.MutedText,
		ScrollBarThickness = 3,
		Size = UDim2.new(1, -28, 1, -62),
		ZIndex = 3,
		Parent = self.AppPage,
	}) :: ScrollingFrame
	addPadding(self.ContentScroll, 0, 0, 8, 14)
	addList(self.ContentScroll, 10)
end

function WindowUI:_bindDrag()
	local dragging = false
	local dragStart = Vector2.zero
	local frameStart = Vector2.zero

	self:_track(self.Topbar.InputBegan:Connect(function(input)
		if not isPressInput(input) then
			return
		end

		dragging = true
		self._wasDragged = true
		dragStart = pointer(input)
		frameStart = self.Window.AbsolutePosition
	end))

	self:_track(UserInputService.InputChanged:Connect(function(input)
		if not dragging or not isMoveInput(input) then
			return
		end

		local delta = pointer(input) - dragStart
		local nextPosition = clampToViewport(self.Window, frameStart + delta)
		self.Window.Position = UDim2.fromOffset(nextPosition.X, nextPosition.Y)
	end))

	self:_track(UserInputService.InputEnded:Connect(function(input)
		if isPressInput(input) then
			dragging = false
		end
	end))
end

function WindowUI:_bindResponsiveLayout()
	local function apply()
		local viewport = getViewport()
		local mobile = viewport.X <= 700

		if mobile then
			self.WindowScale.Scale = 1
			self.Window.Size = UDim2.new(1, -22, 0, math.clamp(viewport.Y - 88, 286, 400))
			if not self._wasDragged then
				self.Window.Position = UDim2.fromOffset(12, 56)
			end
			self.AppGrid.CellSize = UDim2.fromOffset(76, 80)
		else
			self.WindowScale.Scale = self._config.Scale or 0.94
			self.Window.Size = self._baseSize
			if not self._wasDragged then
				self.Window.Position = self._basePosition
			end
			self.AppGrid.CellSize = UDim2.fromOffset(80, 82)
		end
	end

	apply()

	local camera = Workspace.CurrentCamera
	if camera then
		self:_track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply))
	end
end

function WindowUI:_connectIconSignal(signal: any, callback: (...any) -> ()): boolean
	if signal == nil then
		return false
	end

	local ok, connection = pcall(function()
		return signal:Connect(callback)
	end)

	if ok and connection then
		self:_track(connection)
		return true
	end

	return false
end

function WindowUI:_setupTopbarPlus(configValue: boolean | TopbarPlusConfig?)
	local config = normalizeTopbarConfig(configValue)
	if not config then
		return
	end

	local Icon = config.Icon or loadTopbarIcon(config.Source or DEFAULT_TOPBARPLUS_SOURCE)
	if type(Icon) ~= "table" or type(Icon.new) ~= "function" then
		return
	end

	local ok, icon = pcall(function()
		return Icon.new()
	end)
	if not ok or not icon then
		return
	end

	self._topbarIcon = icon

	pcall(function()
		icon:setLabel(config.Label or "⊞")
	end)
	pcall(function()
		icon:setWidth(config.Width or 44)
	end)
	pcall(function()
		icon:align(config.Align or "Left")
	end)
	pcall(function()
		icon:setCaption(config.Caption or self.Title)
	end)
	if config.Order then
		pcall(function()
			icon:setOrder(config.Order)
		end)
	end
	if config.Image then
		pcall(function()
			icon:setImage(config.Image)
			icon:setImageScale(config.ImageScale or 0.72)
			icon:setImageRatio(1)
		end)
	end

	local connected = self:_connectIconSignal(icon.toggled, function(isOn: boolean)
		if self._syncingTopbar then
			return
		end
		self:SetVisible(isOn)
	end)

	if not connected then
		self:_connectIconSignal(icon.selected, function()
			if not self._syncingTopbar then
				self:SetVisible(true)
			end
		end)
		self:_connectIconSignal(icon.deselected, function()
			if not self._syncingTopbar then
				self:SetVisible(false)
			end
		end)
	end

	self:_syncTopbarIcon(self.Window.Visible)
end

function WindowUI:_createFallbackTopbarButton()
	local button = create("TextButton", {
		Name = "FallbackTopbarButton",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 9),
		Size = UDim2.fromOffset(38, 30),
		Text = "",
		Visible = not self.Window.Visible,
		ZIndex = 100,
		Parent = self.ScreenGui,
	}) :: TextButton

	addStroke(button, Color3.fromRGB(255, 255, 255), 0.42, 1)
	drawWindowsGlyph(button, "WindowUITopbarGlyph")
	bindButtonMotion(self, button, Color3.fromRGB(0, 0, 0), Color3.fromRGB(22, 22, 22), Color3.fromRGB(36, 36, 36))

	self.FallbackButton = button
	self:_track(button.MouseButton1Click:Connect(function()
		self:SetVisible(true)
	end))
end

function WindowUI:_syncTopbarIcon(visible: boolean)
	local icon = self._topbarIcon
	if not icon then
		return
	end

	self._syncingTopbar = true

	if type(icon.setEnabled) == "function" then
		pcall(function()
			icon:setEnabled(not visible)
		end)
		if not visible and type(icon.deselect) == "function" then
			pcall(function()
				icon:deselect()
			end)
		end
	else
		local method = visible and icon.select or icon.deselect
		if type(method) == "function" then
			pcall(function()
				method(icon)
			end)
		end
	end

	self._syncingTopbar = false
end

function WindowUI.new(config: WindowConfig?)
	local resolvedConfig = config or {}
	local self = setmetatable({
		_config = resolvedConfig,
		_connections = {} :: ConnectionList,
		_apps = {},
		_appByName = {},
		_activeApp = nil,
		_activeContent = nil,
		_theme = mergeTheme(resolvedConfig.Theme),
		_topbarIcon = nil,
		_syncingTopbar = false,
		_wasDragged = false,
		Title = resolvedConfig.Title or resolvedConfig.Name or "Window UI",
	}, WindowUI)

	self:_buildRoot()
	self:_buildTopbar()
	self:_buildBody()
	self:_bindDrag()
	self:_bindResponsiveLayout()
	self:_setupTopbarPlus(resolvedConfig.TopbarPlus)
	if not self._topbarIcon then
		self:_createFallbackTopbarButton()
	end

	return self
end

function WindowUI:SetVisible(visible: boolean)
	if self.Window.Visible == visible then
		self:_syncTopbarIcon(visible)
		if self.FallbackButton then
			self.FallbackButton.Visible = not visible
		end
		return
	end

	if visible then
		self.Window.Visible = true
		self.Window.BackgroundTransparency = 1
		tween(self.Window, TWEEN_SOFT, { BackgroundTransparency = 0.03 })
	else
		self.Window.Visible = false
	end

	self:_syncTopbarIcon(visible)
	if self.FallbackButton then
		self.FallbackButton.Visible = not visible
	end
end

function WindowUI:Toggle()
	self:SetVisible(not self.Window.Visible)
end

function WindowUI:OpenHome()
	if self._activeContent then
		self._activeContent.Parent = nil
	end

	self._activeApp = nil
	self._activeContent = nil
	self.AppPage.Visible = false
	self.HomePage.Visible = true
	self.ContentScroll.CanvasPosition = Vector2.zero
end

function WindowUI:OpenApp(appName: string)
	local app = self._appByName[appName]
	if not app then
		warn(("[WindowUILibrary] app '%s' does not exist."):format(appName))
		return
	end

	if self._activeContent then
		self._activeContent.Parent = nil
	end

	self._activeApp = app
	self._activeContent = app.Content
	self._activeContent.Parent = self.ContentScroll
	self.AppTitle.Text = app.Name
	self.AppIcon.Image = app.Icon or ""
	self.AppIcon.Visible = app.Icon ~= nil and app.Icon ~= ""

	local backgroundImage = app.BackgroundImage
	self.AppBackground.Image = backgroundImage or ""
	self.AppBackground.Visible = backgroundImage ~= nil and backgroundImage ~= ""

	self.HomePage.Visible = false
	self.AppPage.Visible = true
	self.ContentScroll.CanvasPosition = Vector2.zero
	self:SetVisible(true)
end

function WindowUI:_sortAppTiles()
	table.sort(self._apps, function(left, right)
		if left.Order == right.Order then
			return left.Name < right.Name
		end
		return left.Order < right.Order
	end)

	for index, app in ipairs(self._apps) do
		if app.Tile then
			app.Tile.LayoutOrder = index
		end
	end
end

function WindowUI:CreateApp(config: AppConfig)
	assert(type(config.Name) == "string" and config.Name ~= "", "CreateApp requires a non-empty Name.")

	local app = setmetatable({
		Name = config.Name,
		Icon = config.Icon,
		BackgroundImage = config.BackgroundImage,
		TileImage = config.TileImage,
		Order = config.Order or (#self._apps + 1),
		_library = self,
		Content = nil,
		Tile = nil,
		_defaultSection = nil,
	}, App)

	app.Content = create("Frame", {
		Name = config.Name .. "Content",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 0, 0),
	}) :: Frame
	addList(app.Content, 10)

	table.insert(self._apps, app)
	self._appByName[app.Name] = app
	app:_createTile()
	self:_sortAppTiles()

	if config.StartOpen then
		self:OpenApp(app.Name)
	end

	return app
end

function WindowUI:Destroy()
	if self._topbarIcon then
		local destroy = self._topbarIcon.destroy
		if type(destroy) == "function" then
			pcall(function()
				destroy(self._topbarIcon)
			end)
		end
	end

	for _, connection in ipairs(self._connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	self.ScreenGui:Destroy()
end

function App:_track(connection: RBXScriptConnection): RBXScriptConnection
	return self._library:_track(connection)
end

function App:_createTile()
	local library = self._library
	local theme = library._theme

	local tile = create("TextButton", {
		Name = self.Name .. "Tile",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Tile or DEFAULT_THEME.Tile,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		LayoutOrder = self.Order,
		Text = "",
		ZIndex = 3,
		Parent = library.AppGridScroll,
	}) :: TextButton
	local tileScale = create("UIScale", {
		Scale = 1,
		Parent = tile,
	}) :: UIScale
	local tileStroke = addStroke(tile, theme.Stroke or DEFAULT_THEME.Stroke, 0.62, 1)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Accent or DEFAULT_THEME.Accent),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(142, 230, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}),
		Rotation = 35,
		Parent = tileStroke,
	})
	bindButtonMotion(
		library,
		tile,
		theme.Tile or DEFAULT_THEME.Tile,
		theme.TileHover or DEFAULT_THEME.TileHover,
		theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong
	)

	local holding = false
	local function renderHold(nextHolding: boolean)
		if holding == nextHolding then
			return
		end

		holding = nextHolding
		tween(tileScale, TWEEN_FAST, { Scale = if holding then 1.09 else 1 })
		tween(tileStroke, TWEEN_FAST, {
			Transparency = if holding then 0.06 else 0.62,
			Thickness = if holding then 2 else 1,
		})
	end

	library:_track(tile.InputBegan:Connect(function(input)
		if isPressInput(input) then
			renderHold(true)
		end
	end))
	library:_track(tile.MouseLeave:Connect(function()
		renderHold(false)
	end))
	library:_track(UserInputService.InputEnded:Connect(function(input)
		if isPressInput(input) then
			renderHold(false)
		end
	end))

	local tileImage = self.TileImage or self.BackgroundImage
	if tileImage and tileImage ~= "" then
		create("ImageLabel", {
			Name = "Background",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = tileImage,
			ImageTransparency = 0.3,
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
			Parent = tile,
		})

		create("Frame", {
			Name = "Shade",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.48,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
			Parent = tile,
		})
	end

	if self.Icon and self.Icon ~= "" then
		create("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = self.Icon,
			Position = UDim2.new(0.5, 0, 0, 10),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(30, 30),
			ZIndex = 5,
			Parent = tile,
		})
	else
		local iconBox = create("Frame", {
			Name = "GeneratedIcon",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0, 10),
			Size = UDim2.fromOffset(30, 30),
			ZIndex = 5,
			Parent = tile,
		}) :: Frame
		drawWindowsGlyph(iconBox, "AppGlyph")
	end

	local label = create("TextLabel", {
		Name = "Name",
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 1, -7),
		Size = UDim2.new(1, -8, 0, 28),
		Text = self.Name,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Parent = tile,
	}) :: TextLabel
	setText(label, theme.Text or DEFAULT_THEME.Text, 11, Enum.Font.GothamMedium)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center

	self.Tile = tile
	library:_track(tile.MouseButton1Click:Connect(function()
		library:OpenApp(self.Name)
	end))
end

function App:_resolveParent(parent: GuiObject?): GuiObject
	if parent then
		return parent
	end

	if not self._defaultSection then
		self._defaultSection = self:CreateSection("Main")
	end

	return self._defaultSection
end

function App:CreateSection(title: string): Frame
	local theme = self._library._theme
	local section = create("Frame", {
		Name = title .. "Section",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Surface or DEFAULT_THEME.Surface,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 5,
		Parent = self.Content,
	}) :: Frame
	addStroke(section, theme.Stroke or DEFAULT_THEME.Stroke, 0.64, 1)
	addPadding(section, 10, 8, 10, 10)
	addList(section, 7)

	local label = create("TextLabel", {
		Name = "SectionTitle",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Text = title,
		ZIndex = 6,
		Parent = section,
	}) :: TextLabel
	setText(label, theme.Text or DEFAULT_THEME.Text, 13, Enum.Font.GothamSemibold)

	return section
end

function App:AddLabel(text: string, parent: GuiObject?): TextLabel
	local theme = self._library._theme
	local label = create("TextLabel", {
		Name = "Label",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Text = text,
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: TextLabel
	setText(label, theme.MutedText or DEFAULT_THEME.MutedText, 12, Enum.Font.Gotham)
	return label
end

function App:AddButton(config: ButtonConfig, parent: GuiObject?): TextButton
	local theme = self._library._theme
	local button = create("TextButton", {
		Name = "Button",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34),
		Text = config.Text,
		TextColor3 = theme.Text or DEFAULT_THEME.Text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: TextButton
	button.TextXAlignment = Enum.TextXAlignment.Center
	addStroke(button, theme.Stroke or DEFAULT_THEME.Stroke, 0.62, 1)
	bindButtonMotion(
		self._library,
		button,
		theme.Button or DEFAULT_THEME.Button,
		theme.ButtonHover or DEFAULT_THEME.ButtonHover,
		theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong
	)

	self:_track(button.MouseButton1Click:Connect(function()
		safeCallback(config.Callback)
	end))

	return button
end

function App:AddToggle(config: ToggleConfig, parent: GuiObject?): Frame
	local theme = self._library._theme
	local enabled = config.Default == true

	local row = create("Frame", {
		Name = "Toggle",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: Frame

	local label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -54, 1, 0),
		Text = config.Text,
		ZIndex = 6,
		Parent = row,
	}) :: TextLabel
	setText(label, theme.Text or DEFAULT_THEME.Text, 12, Enum.Font.Gotham)

	local button = create("TextButton", {
		Name = "Switch",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(42, 22),
		Text = "",
		ZIndex = 7,
		Parent = row,
	}) :: TextButton
	addStroke(button, theme.Stroke or DEFAULT_THEME.Stroke, 0.6, 1)

	local knob = create("Frame", {
		Name = "Knob",
		BackgroundColor3 = theme.Text or DEFAULT_THEME.Text,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 8,
		Parent = button,
	}) :: Frame

	local function render(fire: boolean)
		button.BackgroundColor3 = if enabled
			then (theme.Accent or DEFAULT_THEME.Accent)
			else (theme.Button or DEFAULT_THEME.Button)
		knob.Position = if enabled then UDim2.new(1, -19, 0, 3) else UDim2.fromOffset(3, 3)
		if fire then
			safeValueCallback(config.Callback, enabled)
		end
	end

	render(false)
	self:_track(button.MouseButton1Click:Connect(function()
		enabled = not enabled
		render(true)
	end))

	return row
end

function App:AddSlider(config: SliderConfig, parent: GuiObject?): Frame
	local theme = self._library._theme
	local minValue = config.Min or 0
	local maxValue = config.Max or 100
	if maxValue <= minValue then
		maxValue = minValue + 1
	end

	local step = config.Step or 1
	local value = math.clamp(config.Default or minValue, minValue, maxValue)

	local row = create("Frame", {
		Name = "Slider",
		BackgroundColor3 = theme.Surface or DEFAULT_THEME.Surface,
		BackgroundTransparency = 0.14,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 64),
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: Frame
	addStroke(row, theme.Stroke or DEFAULT_THEME.Stroke, 0.7, 1)

	local label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -88, 0, 22),
		Text = config.Text,
		ZIndex = 6,
		Parent = row,
	}) :: TextLabel
	setText(label, theme.Text or DEFAULT_THEME.Text, 12, Enum.Font.GothamMedium)

	local valueLabel = create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(62, 22),
		Text = "",
		ZIndex = 6,
		Parent = row,
	}) :: TextLabel
	setText(valueLabel, theme.Text or DEFAULT_THEME.Text, 11, Enum.Font.GothamMedium)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	addStroke(valueLabel, theme.Stroke or DEFAULT_THEME.Stroke, 0.82, 1)

	local track = create("TextButton", {
		Name = "Track",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 42),
		Size = UDim2.new(1, -20, 0, 8),
		Text = "",
		ZIndex = 6,
		Parent = row,
	}) :: TextButton
	addStroke(track, theme.Stroke or DEFAULT_THEME.Stroke, 0.76, 1)

	local fill = create("Frame", {
		Name = "Fill",
		BackgroundColor3 = theme.Accent or DEFAULT_THEME.Accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 7,
		Parent = track,
	}) :: Frame
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Accent or DEFAULT_THEME.Accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 225, 255)),
		}),
		Rotation = 0,
		Parent = fill,
	})

	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Text or DEFAULT_THEME.Text,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(10, 16),
		ZIndex = 8,
		Parent = track,
	}) :: Frame
	addStroke(knob, theme.Window or DEFAULT_THEME.Window, 0.2, 1)

	local function snap(raw: number): number
		if step <= 0 then
			return raw
		end

		return minValue + math.floor(((raw - minValue) / step) + 0.5) * step
	end

	local function setValue(nextValue: number, fire: boolean)
		value = math.clamp(snap(nextValue), minValue, maxValue)
		local percent = (value - minValue) / (maxValue - minValue)
		fill.Size = UDim2.fromScale(percent, 1)
		knob.Position = UDim2.fromScale(percent, 0.5)
		valueLabel.Text = formatNumber(value)
		if fire then
			safeValueCallback(config.Callback, value)
		end
	end

	local function setFromX(x: number)
		local width = math.max(track.AbsoluteSize.X, 1)
		local percent = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		setValue(minValue + (maxValue - minValue) * percent, true)
	end

	local dragging = false
	setValue(value, false)

	self:_track(track.InputBegan:Connect(function(input)
		if not isPressInput(input) then
			return
		end

		dragging = true
		setFromX(input.Position.X)
	end))

	self:_track(UserInputService.InputChanged:Connect(function(input)
		if dragging and isMoveInput(input) then
			setFromX(input.Position.X)
		end
	end))

	self:_track(UserInputService.InputEnded:Connect(function(input)
		if isPressInput(input) then
			dragging = false
		end
	end))

	return row
end

function App:AddTextBox(config: TextBoxConfig, parent: GuiObject?): Frame
	local theme = self._library._theme

	local row = create("Frame", {
		Name = "TextBoxRow",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 60),
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: Frame

	local label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 22),
		Text = config.Text,
		ZIndex = 6,
		Parent = row,
	}) :: TextLabel
	setText(label, theme.Text or DEFAULT_THEME.Text, 12, Enum.Font.Gotham)

	local box = create("TextBox", {
		Name = "Input",
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		PlaceholderText = config.Placeholder or "",
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 30),
		Text = config.Default or "",
		TextColor3 = theme.Text or DEFAULT_THEME.Text,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		ZIndex = 6,
		Parent = row,
	}) :: TextBox
	box.TextXAlignment = Enum.TextXAlignment.Left
	addPadding(box, 10, 0, 10, 0)
	addStroke(box, theme.Stroke or DEFAULT_THEME.Stroke, 0.6, 1)

	self:_track(box.FocusLost:Connect(function()
		safeValueCallback(config.Callback, box.Text)
	end))

	return row
end

function App:AddDropdown(config: DropdownConfig, parent: GuiObject?): Frame
	local theme = self._library._theme
	local options = config.Options
	local selected = config.Default or options[1] or ""
	local open = false

	local row = create("Frame", {
		Name = "Dropdown",
		BackgroundColor3 = theme.Surface or DEFAULT_THEME.Surface,
		BackgroundTransparency = 0.14,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 64),
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: Frame
	addStroke(row, theme.Stroke or DEFAULT_THEME.Stroke, 0.7, 1)

	local label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 5),
		Size = UDim2.new(1, -20, 0, 22),
		Text = config.Text,
		ZIndex = 6,
		Parent = row,
	}) :: TextLabel
	setText(label, theme.MutedText or DEFAULT_THEME.MutedText, 12, Enum.Font.GothamMedium)

	local button = create("TextButton", {
		Name = "Button",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 29),
		Size = UDim2.new(1, -20, 0, 30),
		Text = selected,
		TextColor3 = theme.Text or DEFAULT_THEME.Text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		ZIndex = 6,
		Parent = row,
	}) :: TextButton
	button.TextXAlignment = Enum.TextXAlignment.Left
	addPadding(button, 10, 0, 10, 0)
	addStroke(button, theme.Stroke or DEFAULT_THEME.Stroke, 0.6, 1)
	bindButtonMotion(
		self._library,
		button,
		theme.Button or DEFAULT_THEME.Button,
		theme.ButtonHover or DEFAULT_THEME.ButtonHover,
		theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong
	)

	local arrow = create("TextLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -18, 0, 29),
		Size = UDim2.fromOffset(18, 30),
		Text = "v",
		TextColor3 = theme.MutedText or DEFAULT_THEME.MutedText,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		ZIndex = 7,
		Parent = row,
	}) :: TextLabel
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	arrow.TextYAlignment = Enum.TextYAlignment.Center

	local optionsFrame = create("Frame", {
		Name = "Options",
		BackgroundColor3 = theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 68),
		Size = UDim2.new(1, -20, 0, #options * 28),
		Visible = false,
		ZIndex = 7,
		Parent = row,
	}) :: Frame
	addStroke(optionsFrame, theme.Stroke or DEFAULT_THEME.Stroke, 0.6, 1)
	addList(optionsFrame, 0)

	local optionButtons: { TextButton } = {}
	local function paintOption(optionButton: TextButton, hovering: boolean)
		local isSelected = optionButton.Text == selected
		optionButton.BackgroundColor3 = if isSelected or hovering
			then (theme.ButtonHover or DEFAULT_THEME.ButtonHover)
			else (theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong)
		optionButton.TextColor3 = if isSelected
			then (theme.Text or DEFAULT_THEME.Text)
			else (theme.MutedText or DEFAULT_THEME.MutedText)
	end

	local function renderOpen()
		optionsFrame.Visible = open
		arrow.Text = if open then "^" else "v"
		row.Size = if open then UDim2.new(1, 0, 0, 74 + (#options * 28)) else UDim2.new(1, 0, 0, 64)

		for _, optionButton in ipairs(optionButtons) do
			paintOption(optionButton, false)
		end
	end

	for _, option in ipairs(options) do
		local optionButton = create("TextButton", {
			Name = option,
			AutoButtonColor = false,
			BackgroundColor3 = theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 28),
			Text = option,
			TextColor3 = theme.MutedText or DEFAULT_THEME.MutedText,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			ZIndex = 8,
			Parent = optionsFrame,
		}) :: TextButton
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		addPadding(optionButton, 10, 0, 10, 0)
		table.insert(optionButtons, optionButton)
		self:_track(optionButton.MouseEnter:Connect(function()
			paintOption(optionButton, true)
		end))
		self:_track(optionButton.MouseLeave:Connect(function()
			paintOption(optionButton, false)
		end))

		self:_track(optionButton.MouseButton1Click:Connect(function()
			selected = option
			button.Text = selected
			open = false
			renderOpen()
			safeValueCallback(config.Callback, selected)
		end))
	end

	renderOpen()
	self:_track(button.MouseButton1Click:Connect(function()
		open = not open
		renderOpen()
	end))

	return row
end

return WindowUI
