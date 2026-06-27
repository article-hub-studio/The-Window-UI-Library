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

local BASE64_BYTES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local WINDOW_ICON_PNG_BASE64 =
	"iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAAuklEQVR42u3bsQkAMAhFwb//0mYDOzHCBV4d8KqASZLSaoYAAIAAABAAAAIAQAAACAAAAQAgAAAEAIDOAUyd3+8GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYC/IYpYAAABgCAAACAAA+R/gJQwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAIAAABACAAAAQAgAAAEAAAAgBAAAAIAAA1PZlFf771RW3YAAAAAElFTkSuQmCC"
local BACK_ICON_PNG_BASE64 =
	"iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAACXBIWXMAAAsTAAALEwEAmpwYAAACUElEQVR4nO3cOYsUQRjG8RVR8Qg0ERMPDESMRAwVU0X9IuInMRNzwVhBEANFMF3WTDTygkXWZT22u556q2cR5BWHFjz2mKNnqpj9/2Dy5vnD7OxMd83NAQAAAAAAAAAAAAAwA+qYbkq2GGRrUnpS172Tua9p21BMtxST//2yhdzXNfPcfYdkt/8fP3mQ/ch9fTOtHf/OeuP/fuW+xpnl7jsV093NxifAhPTHV7q31fgEmAB33xWiPRhkfAJ0zN13h2gPBx2fAB1y971SejrM+AToyJL7vqD0bNjxCdCBlRU/EJSejzI+AcZUVdVBRZsfdXwCjKGu60OSvRhnfAKMKMZ4OCi9HHd8AozAzI4EpdddjE+AIa02zTFFe9vV+AQYwmrTHFe0912OT4ABhbB2Ksg+dj0+AQYg6XSQLU1ifAJswczOhpg+T2p8AmyiMjunmL5OcnwCbKBO6bxi+jbp8QmwDqm5qJg0jfEJ8A+puaRocVrjE+APwexKkDXTHJ8ArRDsWpD1pj0+Afrjp+tB9j3H+ATov+/bYq7xCUCA/HgLKkAIdpU/wpnVZpf5GJoZ/4gVQGouKKZAgIz4Mq4Av76ODjF9IUBGks4EpU8EyIifJAvAj/IFaG9LeUeAjJqmOapobwiQUXtr4isCZMTNuQXo354ebYEAGfGARgGWl30/jyhlxkN6BXD3PYr2iAAZ8aB2AdqjCu4TICMO6ygAx9UUgAObCsCRZYXY4NC++dzXta1I6YaifWhvfXlcVb0Tua8JAAAAAAAAAAAAADC7fgJYTBn/prTmhQAAAABJRU5ErkJggg=="

local function decodeBase64(data: string): string
	local output = table.create(math.floor(#data * 0.75))
	local buffer = 0
	local bits = 0

	for index = 1, #data do
		local char = data:sub(index, index)
		if char == "=" then
			break
		end

		local value = BASE64_BYTES:find(char, 1, true)
		if value then
			buffer = (buffer * 64) + (value - 1)
			bits += 6

			if bits >= 8 then
				bits -= 8
				local byte = math.floor(buffer / (2 ^ bits)) % 256
				table.insert(output, string.char(byte))
			end
		end
	end

	return table.concat(output)
end

local function sanitizeFileName(value: string): string
	return value:gsub("[^%w%._%-]", "_")
end

local function tryMakeFolder(path: string)
	local makefolder = getGlobal("makefolder")
	local isfolder = getGlobal("isfolder")
	if type(makefolder) ~= "function" then
		return
	end

	if type(isfolder) == "function" then
		local ok, exists = pcall(isfolder, path)
		if ok and exists then
			return
		end
	end

	pcall(makefolder, path)
end

local function tryMakeFolderPath(path: string)
	local current = ""
	for segment in path:gmatch("[^/]+") do
		current = if current == "" then segment else current .. "/" .. segment
		tryMakeFolder(current)
	end
end

local function writeExecutorAsset(path: string, content: string): string?
	local writefile = getGlobal("writefile")
	local readfile = getGlobal("readfile")
	local isfile = getGlobal("isfile")
	local getcustomasset = getGlobal("getcustomasset") or getGlobal("getsynasset")

	if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
		return nil
	end

	local folder = path:match("^(.*)/[^/]+$")
	if folder then
		tryMakeFolderPath(folder)
	end

	local shouldWrite = true
	if type(isfile) == "function" then
		local ok, exists = pcall(isfile, path)
		shouldWrite = not (ok and exists)
	end

	if type(readfile) == "function" then
		local ok, current = pcall(readfile, path)
		if ok and current ~= nil and #current > 0 then
			shouldWrite = false
		elseif shouldWrite == false then
			shouldWrite = true
		end
	end

	if shouldWrite then
		local ok = pcall(writefile, path, content)
		if not ok then
			return nil
		end
	end

	local ok, asset = pcall(getcustomasset, path)
	if ok and type(asset) == "string" then
		return asset
	end

	return nil
end

local function getWindowIconAsset(): string?
	return writeExecutorAsset("WindowUILibrary/icons/window_topbar.png", decodeBase64(WINDOW_ICON_PNG_BASE64))
end

local function getBackIconAsset(): string?
	return writeExecutorAsset("WindowUILibrary/icons/solar_back_arrow_left.png", decodeBase64(BACK_ICON_PNG_BASE64))
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

export type IconConfig = string | {
	Pack: string?,
	Name: string?,
	Url: string?,
	Image: string?,
	Color: Color3?,
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
	Icon: IconConfig?,
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
local DEFAULT_BACKGROUND_URL =
	"https://raw.githubusercontent.com/article-hub-studio/The-Window-UI-Library/refs/heads/main/assets/dark-stripe-background.jpg"
local DEFAULT_TOPBAR_GLASS_URL =
	"https://raw.githubusercontent.com/article-hub-studio/The-Window-UI-Library/refs/heads/main/assets/liquid-glass-topbar.jpg"

local DEFAULT_THEME = {
	Accent = Color3.fromRGB(88, 101, 242),
	Window = Color3.fromRGB(49, 51, 56),
	Topbar = Color3.fromRGB(30, 31, 34),
	TopbarText = Color3.fromRGB(242, 243, 245),
	Surface = Color3.fromRGB(43, 45, 49),
	SurfaceStrong = Color3.fromRGB(56, 58, 64),
	Tile = Color3.fromRGB(43, 45, 49),
	TileHover = Color3.fromRGB(63, 66, 73),
	Button = Color3.fromRGB(56, 58, 64),
	ButtonHover = Color3.fromRGB(72, 75, 83),
	Text = Color3.fromRGB(242, 243, 245),
	MutedText = Color3.fromRGB(181, 186, 193),
	Stroke = Color3.fromRGB(64, 66, 73),
	Shadow = Color3.fromRGB(18, 19, 22),
	Danger = Color3.fromRGB(255, 91, 91),
}

local THEME_PRESETS: { [string]: Theme } = {
	["Discord Dark"] = DEFAULT_THEME,
	Midnight = {
		Accent = Color3.fromRGB(79, 129, 255),
		Window = Color3.fromRGB(24, 27, 33),
		Topbar = Color3.fromRGB(15, 17, 22),
		TopbarText = Color3.fromRGB(245, 247, 255),
		Surface = Color3.fromRGB(31, 35, 43),
		SurfaceStrong = Color3.fromRGB(42, 47, 58),
		Tile = Color3.fromRGB(31, 35, 43),
		TileHover = Color3.fromRGB(48, 55, 68),
		Button = Color3.fromRGB(42, 47, 58),
		ButtonHover = Color3.fromRGB(56, 64, 80),
		Text = Color3.fromRGB(245, 247, 255),
		MutedText = Color3.fromRGB(170, 179, 194),
		Stroke = Color3.fromRGB(59, 66, 82),
		Shadow = Color3.fromRGB(7, 9, 13),
		Danger = Color3.fromRGB(255, 91, 91),
	},
	Graphite = {
		Accent = Color3.fromRGB(120, 132, 150),
		Window = Color3.fromRGB(39, 40, 43),
		Topbar = Color3.fromRGB(25, 26, 28),
		TopbarText = Color3.fromRGB(242, 242, 244),
		Surface = Color3.fromRGB(48, 49, 53),
		SurfaceStrong = Color3.fromRGB(60, 62, 67),
		Tile = Color3.fromRGB(48, 49, 53),
		TileHover = Color3.fromRGB(66, 68, 74),
		Button = Color3.fromRGB(60, 62, 67),
		ButtonHover = Color3.fromRGB(76, 78, 86),
		Text = Color3.fromRGB(242, 242, 244),
		MutedText = Color3.fromRGB(176, 179, 187),
		Stroke = Color3.fromRGB(75, 77, 84),
		Shadow = Color3.fromRGB(12, 13, 15),
		Danger = Color3.fromRGB(255, 91, 91),
	},
	Amoled = {
		Accent = Color3.fromRGB(88, 101, 242),
		Window = Color3.fromRGB(8, 8, 10),
		Topbar = Color3.fromRGB(0, 0, 0),
		TopbarText = Color3.fromRGB(245, 245, 245),
		Surface = Color3.fromRGB(14, 15, 18),
		SurfaceStrong = Color3.fromRGB(25, 26, 30),
		Tile = Color3.fromRGB(14, 15, 18),
		TileHover = Color3.fromRGB(33, 35, 42),
		Button = Color3.fromRGB(25, 26, 30),
		ButtonHover = Color3.fromRGB(42, 44, 52),
		Text = Color3.fromRGB(245, 245, 245),
		MutedText = Color3.fromRGB(168, 171, 180),
		Stroke = Color3.fromRGB(45, 47, 54),
		Shadow = Color3.fromRGB(0, 0, 0),
		Danger = Color3.fromRGB(255, 91, 91),
	},
}

local TWEEN_FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SOFT = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_WINDOW_IN = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_WINDOW_OUT = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
local TWEEN_BODY_OUT = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local TWEEN_SHEEN = TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local PAGE_BACKGROUND_TRANSPARENCY = 0.58

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

local function addCorner(parent: GuiObject, radius: UDim): UICorner?
	local ok, corner = pcall(function()
		local created = Instance.new("UICorner")
		created.CornerRadius = radius
		created.Parent = parent
		return created
	end)

	if ok then
		return corner
	end

	return nil
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

local function colorToHex(color: Color3): string
	return string.format(
		"%02X%02X%02X",
		math.clamp(math.floor(color.R * 255 + 0.5), 0, 255),
		math.clamp(math.floor(color.G * 255 + 0.5), 0, 255),
		math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
	)
end

local function urlEncode(value: string): string
	return (value:gsub("([^%w%-%._~])", function(char)
		return string.format("%%%02X", string.byte(char))
	end))
end

local function trimIconVariant(name: string): string
	local cleaned = name:lower()
	cleaned = cleaned:gsub("^solar:", ""):gsub("^craft:", "")
	cleaned = cleaned:gsub("%-line%-duotone$", ""):gsub("%-bold%-duotone$", ""):gsub("%-linear$", "")
	cleaned = cleaned:gsub("%-outline$", ""):gsub("%-broken$", ""):gsub("%-bold$", ""):gsub("%-duotone$", "")
	cleaned = cleaned:gsub("%-rounded$", ""):gsub("%-line$", "")
	cleaned = cleaned:gsub("%-minimalistic$", ""):gsub("%-angle$", "")
	return cleaned
end

local function getIconKind(pack: string, name: string): string
	local cleaned = trimIconVariant(name)
	for _, key in ipairs({
		"settings",
		"tool",
		"home",
		"folder",
		"terminal",
		"code",
		"user",
		"profile",
		"shield",
		"lock",
		"calendar",
		"chat",
		"message",
		"graph",
		"chart",
		"bell",
		"notification",
		"star",
		"sun",
		"moon",
	}) do
		if cleaned:find(key, 1, true) then
			return key
		end
	end

	return if pack == "craft" then "block" else "spark"
end

local function iconifyAsset(prefix: string, name: string, color: Color3): string?
	local httpName = name:gsub("^" .. prefix .. ":", "")
	local colorHex = colorToHex(color)

	local candidates = { httpName }
	if prefix == "solar" and not httpName:find("%-") then
		table.insert(candidates, httpName .. "-bold")
		table.insert(candidates, httpName .. "-linear")
		table.insert(candidates, httpName .. "-outline")
		table.insert(candidates, httpName .. "-broken")
	end

	for _, candidate in ipairs(candidates) do
		local path = ("WindowUILibrary/icons/%s_%s_%s.png"):format(prefix, sanitizeFileName(candidate), colorHex)
		local svgUrl = ("https://api.iconify.design/%s:%s.svg?color=%%23%s&width=96&height=96"):format(
			prefix,
			candidate,
			colorHex
		)
		local pngUrl = ("https://wsrv.nl/?url=%s&output=png&w=96&h=96"):format(urlEncode(svgUrl))

		local ok, content = pcall(function()
			return (cloneRef(rawGame) :: any):HttpGet(pngUrl)
		end)
		if ok and type(content) == "string" and #content > 8 and content:sub(1, 8) == "\137PNG\r\n\26\n" then
			return writeExecutorAsset(path, content)
		end
	end

	return nil
end

local function urlAsset(url: string, cachePath: string?): string?
	local extension = url:match("%.([%w]+)%??[^/]*$")
	if extension ~= "png" and extension ~= "jpg" and extension ~= "jpeg" and extension ~= "svg" then
		extension = "png"
	end

	local path = cachePath or ("WindowUILibrary/icons/url_%s.%s"):format(sanitizeFileName(url), extension)
	local isfile = getGlobal("isfile")
	local readfile = getGlobal("readfile")
	local getcustomasset = getGlobal("getcustomasset") or getGlobal("getsynasset")
	if type(getcustomasset) == "function" then
		local cached = false
		if type(isfile) == "function" then
			local ok, exists = pcall(isfile, path)
			cached = ok and exists
		end
		if not cached and type(readfile) == "function" then
			local ok, current = pcall(readfile, path)
			cached = ok and type(current) == "string" and #current > 0
		end

		if cached then
			local assetOk, asset = pcall(getcustomasset, path)
			if assetOk and type(asset) == "string" then
				return asset
			end
		end
	end

	local ok, content = pcall(function()
		return (cloneRef(rawGame) :: any):HttpGet(url)
	end)
	if not ok or type(content) ~= "string" or #content == 0 then
		return nil
	end

	return writeExecutorAsset(path, content)
end

local cachedDefaultBackground: string? = nil
local triedDefaultBackground = false
local cachedTopbarGlass: string? = nil
local triedTopbarGlass = false

local function getDefaultBackgroundAsset(): string?
	if triedDefaultBackground then
		return cachedDefaultBackground
	end

	triedDefaultBackground = true
	cachedDefaultBackground = urlAsset(DEFAULT_BACKGROUND_URL, "WindowUILibrary/backgrounds/dark_stripe_background.jpg")
	return cachedDefaultBackground
end

function WindowUI.GetDefaultBackground(): string?
	return getDefaultBackgroundAsset()
end

local function getPageBackgroundAsset(): string?
	return getDefaultBackgroundAsset()
end

function WindowUI.GetPageBackground(): string?
	return getPageBackgroundAsset()
end

local function getTopbarGlassAsset(): string?
	if triedTopbarGlass then
		return cachedTopbarGlass
	end

	triedTopbarGlass = true
	cachedTopbarGlass = urlAsset(DEFAULT_TOPBAR_GLASS_URL, "WindowUILibrary/backgrounds/liquid_glass_topbar.jpg")
	return cachedTopbarGlass
end

function WindowUI.GetTopbarGlass(): string?
	return getTopbarGlassAsset()
end

local function resolveIcon(spec: any, color: Color3): (string?, string?, string?)
	if type(spec) == "string" then
		if spec == "" then
			return nil, nil, nil
		end

		if spec:match("^%d+$") then
			return "rbxassetid://" .. spec, nil, nil
		end

		if spec:match("^rbxasset") or spec:match("^rbasset") then
			return spec, nil, nil
		end

		local pack, name = spec:match("^(%w+):(.+)$")
		if pack then
			pack = pack:lower()
			if pack == "solar" then
				return iconifyAsset("solar", name, color), pack, name
			end
			if pack == "craft" then
				return nil, pack, name
			end
		end

		if spec:match("^https?://") then
			return urlAsset(spec), nil, nil
		end

		return spec, nil, nil
	end

	if type(spec) == "table" then
		local image = spec.Image
		if type(image) == "string" and image ~= "" then
			return image, nil, nil
		end

		local url = spec.Url
		if type(url) == "string" and url ~= "" then
			return urlAsset(url), nil, nil
		end

		local pack = spec.Pack
		local name = spec.Name
		if type(pack) == "string" and type(name) == "string" then
			pack = pack:lower()
			if pack == "solar" then
				return iconifyAsset("solar", name, color), pack, name
			end
			if pack == "craft" then
				return nil, pack, name
			end
		end
	end

	return nil, nil, nil
end

local function renderGeneratedIcon(
	parent: GuiObject,
	pack: string,
	name: string,
	size: number,
	zIndex: number,
	theme: Theme
)
	local shell = create("Frame", {
		Name = "RenderedIcon",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = if pack == "craft"
			then (theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong)
			else Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = if pack == "craft" then 0.04 else 0,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(size, size),
		ZIndex = zIndex,
		Parent = parent,
	}) :: Frame
	addStroke(shell, theme.Stroke or DEFAULT_THEME.Stroke, if pack == "craft" then 0.56 else 0.7, 1)

	local accent = theme.Accent or DEFAULT_THEME.Accent
	local kind = getIconKind(pack, name)
	for index, offset in ipairs({
		Vector2.new(5, 5),
		Vector2.new(size - 13, 5),
		Vector2.new(5, size - 13),
		Vector2.new(size - 13, size - 13),
	}) do
		create("Frame", {
			Name = "CraftBlock" .. index,
			BackgroundColor3 = theme.Accent or DEFAULT_THEME.Accent,
			BackgroundTransparency = if index == 1 then 0 else 0.18,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(offset.X, offset.Y),
			Size = UDim2.fromOffset(8, 8),
			ZIndex = zIndex + 1,
			Parent = shell,
		})
	end

	if kind == "settings" or kind == "tool" then
		create("Frame", {
			Name = "CraftBarA",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = -38,
			Size = UDim2.fromOffset(math.max(16, size - 14), 4),
			ZIndex = zIndex + 2,
			Parent = shell,
		})
		create("Frame", {
			Name = "CraftBarB",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = 38,
			Size = UDim2.fromOffset(math.max(14, size - 18), 4),
			ZIndex = zIndex + 2,
			Parent = shell,
		})
	elseif kind == "shield" or kind == "lock" then
		create("Frame", {
			Name = "CraftShield",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.52),
			Rotation = 45,
			Size = UDim2.fromOffset(math.max(13, size - 16), math.max(13, size - 16)),
			ZIndex = zIndex + 2,
			Parent = shell,
		})
	elseif kind == "folder" then
		create("Frame", {
			Name = "CraftFolderTab",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(9, 11),
			Size = UDim2.fromOffset(math.max(8, size // 3), 5),
			ZIndex = zIndex + 2,
			Parent = shell,
		})
		create("Frame", {
			Name = "CraftFolderBody",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 16),
			Size = UDim2.fromOffset(size - 16, size - 24),
			ZIndex = zIndex + 2,
			Parent = shell,
		})
	elseif kind == "user" or kind == "profile" then
		create("Frame", {
			Name = "CraftUserHead",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0, 9),
			Size = UDim2.fromOffset(math.max(8, size // 4), math.max(8, size // 4)),
			ZIndex = zIndex + 2,
			Parent = shell,
		})
		create("Frame", {
			Name = "CraftUserBody",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.fromOffset(math.max(16, size - 16), math.max(9, size // 4)),
			ZIndex = zIndex + 2,
			Parent = shell,
		})
	end
end

local function renderIcon(parent: GuiObject, spec: any, size: number, position: UDim2, zIndex: number, theme: Theme)
	local old = parent:FindFirstChild("RenderedIcon")
	if old then
		old:Destroy()
	end

	local color = theme.Text or DEFAULT_THEME.Text
	if type(spec) == "table" and typeof(spec.Color) == "Color3" then
		color = spec.Color
	end

	local asset, pack, name = resolveIcon(spec, color)
	if asset then
		local image = create("ImageLabel", {
			Name = "RenderedIcon",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = asset,
			Position = position,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size, size),
			ZIndex = zIndex,
			Parent = parent,
		}) :: ImageLabel
		image.ImageColor3 = color
		if pack and name then
			task.delay(0.45, function()
				if image.Parent and image.IsLoaded == false then
					image:Destroy()
					if pack == "craft" then
						renderGeneratedIcon(parent, pack, name, size, zIndex, theme)
						local rendered = parent:FindFirstChild("RenderedIcon")
						if rendered and rendered:IsA("GuiObject") then
							rendered.Position = position
						end
					end
				end
			end)
		end
		return
	end

	if pack == "craft" then
		renderGeneratedIcon(parent, pack, name or "star", size, zIndex, theme)
		local rendered = parent:FindFirstChild("RenderedIcon")
		if rendered and rendered:IsA("GuiObject") then
			rendered.Position = position
		end
	end
end

local function drawBackFallbackIcon(parent: GuiObject, color: Color3, zIndex: number)
	local old = parent:FindFirstChild("BackIcon")
	if old then
		old:Destroy()
	end

	local glyph = create("Frame", {
		Name = "BackIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = zIndex,
		Parent = parent,
	}) :: Frame

	for index, rotation in ipairs({ -42, 42 }) do
		local arm = create("Frame", {
			Name = "Arm" .. index,
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(5, if index == 1 then 9 else 8),
			Rotation = rotation,
			Size = UDim2.fromOffset(11, 2),
			ZIndex = zIndex + 1,
			Parent = glyph,
		}) :: Frame
		addCorner(arm, UDim.new(1, 0))
	end
end

local function renderBackIcon(parent: GuiObject, theme: Theme)
	local oldRendered = parent:FindFirstChild("RenderedIcon")
	if oldRendered then
		oldRendered:Destroy()
	end
	local oldBack = parent:FindFirstChild("BackIcon")
	if oldBack then
		oldBack:Destroy()
	end

	local color = theme.Text or DEFAULT_THEME.Text
	local asset = getBackIconAsset() or iconifyAsset("solar", "alt-arrow-left-bold", color)
	if not asset then
		drawBackFallbackIcon(parent, color, (parent.ZIndex or 1) + 2)
		return
	end

	local image = create("ImageLabel", {
		Name = "BackIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = asset,
		ImageColor3 = color,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(18, 18),
		ZIndex = (parent.ZIndex or 1) + 2,
		Parent = parent,
	}) :: ImageLabel

	task.delay(0.45, function()
		if image.Parent and image.IsLoaded == false then
			image:Destroy()
			drawBackFallbackIcon(parent, color, (parent.ZIndex or 1) + 2)
		end
	end)
end

local function bindButtonMotion(
	owner: any,
	button: GuiButton,
	normal: Color3,
	hover: Color3,
	down: Color3,
	animateScale: boolean?
)
	local buttonScale: UIScale? = nil
	if animateScale ~= false then
		buttonScale = create("UIScale", {
			Name = "ButtonMotionScale",
			Scale = 1,
			Parent = button,
		}) :: UIScale
	end

	owner:_track(button.MouseEnter:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = hover })
		if buttonScale then
			tween(buttonScale, TWEEN_FAST, { Scale = 1.015 })
		end
	end))

	owner:_track(button.MouseLeave:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = normal })
		if buttonScale then
			tween(buttonScale, TWEEN_FAST, { Scale = 1 })
		end
	end))

	owner:_track(button.MouseButton1Down:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = down })
		if buttonScale then
			tween(buttonScale, TWEEN_FAST, { Scale = 0.965 })
		end
	end))

	owner:_track(button.MouseButton1Up:Connect(function()
		tween(button, TWEEN_FAST, { BackgroundColor3 = hover })
		if buttonScale then
			tween(buttonScale, TWEEN_FAST, { Scale = 1.01 })
		end
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
			Align = "Center",
			Label = "",
			Width = 44,
		}
	end

	if config.Enabled == false then
		return nil
	end

	local normalized = config
	normalized.Source = normalized.Source or DEFAULT_TOPBARPLUS_SOURCE
	normalized.Align = normalized.Align or "Center"
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
		Scale = self._windowBaseScale,
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

function WindowUI:_createTopbarAction(name: string, iconSpec: IconConfig, xOffset: number, callback: () -> ())
	local theme = self._theme
	local button = create("TextButton", {
		Name = name,
		AutoButtonColor = false,
		BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar,
		BackgroundTransparency = 0.58,
		BorderSizePixel = 0,
		Position = UDim2.new(1, xOffset, 0, 0),
		Size = UDim2.fromOffset(34, 36),
		Text = "",
		ZIndex = 12,
		Parent = self.Topbar,
	}) :: TextButton
	renderIcon(button, iconSpec, 18, UDim2.new(0.5, 0, 0, 9), 13, theme)
	bindButtonMotion(
		self,
		button,
		theme.Topbar or DEFAULT_THEME.Topbar,
		theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong,
		theme.Button or DEFAULT_THEME.Button
	)
	self:_track(button.MouseButton1Click:Connect(callback))
	return button
end

function WindowUI:_startTopbarSheen()
	if self._topbarSheenRunning or not self.TopbarSheenGradient then
		return
	end

	self._topbarSheenRunning = true
	task.spawn(function()
		while not self._destroyed and self.TopbarSheenGradient do
			self.TopbarSheenGradient.Offset = Vector2.new(-1.15, 0)
			tween(self.TopbarSheenGradient, TWEEN_SHEEN, { Offset = Vector2.new(1.15, 0) })
			task.wait(4.2)
		end
	end)
end

function WindowUI:_buildTopbar()
	local theme = self._theme

	self.Topbar = create("Frame", {
		Name = "Topbar",
		BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 10,
		Parent = self.Window,
	}) :: Frame

	local glassTexture = getTopbarGlassAsset()
	self.TopbarGlass = create("ImageLabel", {
		Name = "LiquidGlass",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = glassTexture or "",
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		Visible = glassTexture ~= nil,
		ZIndex = 10,
		Parent = self.Topbar,
	}) :: ImageLabel

	self.TopbarTint = create("Frame", {
		Name = "GlassTint",
		BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar,
		BackgroundTransparency = 0.38,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = self.Topbar,
	}) :: Frame

	local topbarHighlight = create("Frame", {
		Name = "GlassHighlight",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 1),
		Size = UDim2.new(1, 0, 0, 12),
		ZIndex = 10,
		Parent = self.Topbar,
	}) :: Frame
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.52, Color3.fromRGB(130, 190, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.42),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 0,
		Parent = topbarHighlight,
	})

	local topbarSheen = create("Frame", {
		Name = "GlassSheen",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(-0.2, 0),
		Size = UDim2.new(1.4, 0, 1, 0),
		ZIndex = 10,
		Parent = self.Topbar,
	}) :: Frame
	self.TopbarSheenGradient = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 220, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}),
		Offset = Vector2.new(-1.15, 0),
		Rotation = 18,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.48, 0.86),
			NumberSequenceKeypoint.new(0.52, 0.55),
			NumberSequenceKeypoint.new(0.56, 0.88),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = topbarSheen,
	}) :: UIGradient
	self:_startTopbarSheen()

	local title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -142, 1, 0),
		Text = self.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 11,
		Parent = self.Topbar,
	}) :: TextLabel
	self.TitleLabel = title
	setText(title, theme.TopbarText or DEFAULT_THEME.TopbarText, 13, Enum.Font.GothamMedium)

	self.UserButton = self:_createTopbarAction("UserAction", "solar:user-bold", -104, function()
		self:OpenApp("__WindowUI_User")
	end)

	self.SettingsButton = self:_createTopbarAction("SettingsAction", "solar:settings-bold", -70, function()
		self:OpenApp("__WindowUI_Settings")
	end)

	self.MinimizeButton = create("TextButton", {
		Name = "Minimize",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar,
		BackgroundTransparency = 0.58,
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
	self.BodyScale = create("UIScale", {
		Scale = 1,
		Parent = self.Body,
	}) :: UIScale

	local pageBackground = getPageBackgroundAsset()

	self.HomePage = create("Frame", {
		Name = "HomePage",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = true,
		Parent = self.Body,
	}) :: Frame
	create("UIScale", {
		Name = "PageMotionScale",
		Scale = 1,
		Parent = self.HomePage,
	})

	self.HomeBackground = create("ImageLabel", {
		Name = "HomeBackground",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = pageBackground or "",
		ImageTransparency = PAGE_BACKGROUND_TRANSPARENCY,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		Visible = pageBackground ~= nil,
		ZIndex = 0,
		Parent = self.HomePage,
	}) :: ImageLabel

	local homeShade = create("Frame", {
		Name = "HomeShade",
		BackgroundColor3 = theme.Window or DEFAULT_THEME.Window,
		BackgroundTransparency = 0.34,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = self.HomePage,
	}) :: Frame
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Window or DEFAULT_THEME.Window),
			ColorSequenceKeypoint.new(1, theme.Surface or DEFAULT_THEME.Surface),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.58, 0.42),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
		Rotation = 115,
		Parent = homeShade,
	})

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
	create("UIScale", {
		Name = "PageMotionScale",
		Scale = 1,
		Parent = self.AppPage,
	})

	self.AppPageBackground = create("ImageLabel", {
		Name = "PageBackground",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = pageBackground or "",
		ImageTransparency = PAGE_BACKGROUND_TRANSPARENCY,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		Visible = pageBackground ~= nil,
		ZIndex = 0,
		Parent = self.AppPage,
	}) :: ImageLabel

	self.AppBackground = create("ImageLabel", {
		Name = "AppBackground",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		ImageTransparency = 0.28,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 1,
		Parent = self.AppPage,
	}) :: ImageLabel

	local appShade = create("Frame", {
		Name = "Shade",
		BackgroundColor3 = theme.Window or DEFAULT_THEME.Window,
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
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
		ZIndex = 4,
		Parent = self.AppPage,
	}) :: Frame

	self.BackButton = create("TextButton", {
		Name = "Back",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(34, 32),
		Text = "",
		ZIndex = 5,
		Parent = appHeader,
	}) :: TextButton
	renderBackIcon(self.BackButton, theme)
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

	self.AppIcon = create("Frame", {
		Name = "AppIcon",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(48, 3),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 5,
		Parent = appHeader,
	}) :: Frame

	self.AppTitle = create("TextLabel", {
		Name = "AppTitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(82, 0),
		Size = UDim2.new(1, -86, 0, 32),
		Text = "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
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
		ZIndex = 4,
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
			self._windowBaseScale = 1
			if self.Window.Visible then
				self.WindowScale.Scale = self._windowBaseScale
			end
			self.Window.Size = UDim2.new(1, -22, 0, math.clamp(viewport.Y - 88, 286, 400))
			if not self._wasDragged then
				self.Window.Position = UDim2.fromOffset(12, 56)
			end
			self.AppGrid.CellSize = UDim2.fromOffset(76, 80)
		else
			self._windowBaseScale = self._config.Scale or 0.94
			if self.Window.Visible then
				self.WindowScale.Scale = self._windowBaseScale
			end
			self.Window.Size = self._baseSize
			if not self._wasDragged then
				self.Window.Position = self._basePosition
			end
			self.AppGrid.CellSize = UDim2.fromOffset(80, 82)
		end

		if self.FallbackButton and not self.Window.Visible then
			self.FallbackButton.Position = self:_getCollapsedTopbarPosition()
		end
		if not self.Window.Visible then
			self._windowRestoreSize = self.Window.Size
			self._windowRestorePosition = self.Window.Position
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
	self._topbarAlign = config.Align or "Center"

	local ok, icon = pcall(function()
		return Icon.new()
	end)
	if not ok or not icon then
		return
	end

	self._topbarIcon = icon

	pcall(function()
		icon:setLabel(config.Label or "")
	end)
	pcall(function()
		icon:setWidth(config.Width or 44)
	end)
	pcall(function()
		icon:align(config.Align or "Center")
	end)
	pcall(function()
		icon:setCaption(config.Caption or self.Title)
	end)
	if config.Order then
		pcall(function()
			icon:setOrder(config.Order)
		end)
	end

	local topbarImage = config.Image
	if not topbarImage then
		topbarImage = getWindowIconAsset()
	end

	if topbarImage then
		pcall(function()
			icon:setImage(topbarImage)
			icon:setImageScale(config.ImageScale or 0.82)
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
		Position = self:_getCollapsedTopbarPosition(),
		Size = UDim2.fromOffset(44, 30),
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

function WindowUI:_animatePage(page: GuiObject, offsetX: number)
	page.Position = UDim2.fromOffset(offsetX, 0)
	page.Visible = true
	local pageScale = page:FindFirstChild("PageMotionScale")
	if pageScale and pageScale:IsA("UIScale") then
		pageScale.Scale = 0.975
		tween(pageScale, TWEEN_SOFT, { Scale = 1 })
	end
	local pageBackground = page:FindFirstChild("HomeBackground") or page:FindFirstChild("PageBackground")
	if pageBackground and pageBackground:IsA("ImageLabel") and pageBackground.Visible then
		pageBackground.ImageTransparency = 1
		tween(pageBackground, TWEEN_SOFT, { ImageTransparency = PAGE_BACKGROUND_TRANSPARENCY })
	end
	tween(page, TWEEN_SOFT, { Position = UDim2.fromOffset(0, 0) })
end

function WindowUI:_getDefaultBackground(): string?
	return getDefaultBackgroundAsset()
end

function WindowUI:_getPageBackground(): string?
	if self._usePageBackground == false then
		return nil
	end

	return getPageBackgroundAsset()
end

function WindowUI:_refreshThemeVisuals()
	local theme = self._theme

	if self.Window then
		tween(self.Window, TWEEN_FAST, { BackgroundColor3 = theme.Window or DEFAULT_THEME.Window })
	end
	if self.Topbar then
		tween(self.Topbar, TWEEN_FAST, { BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar })
	end
	if self.TopbarTint then
		tween(self.TopbarTint, TWEEN_FAST, { BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar })
	end
	if self.TitleLabel then
		self.TitleLabel.TextColor3 = theme.TopbarText or DEFAULT_THEME.TopbarText
	end
	if self.MinimizeButton then
		self.MinimizeButton.BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar
		self.MinimizeButton.TextColor3 = theme.TopbarText or DEFAULT_THEME.TopbarText
	end
	if self.UserButton then
		self.UserButton.BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar
		renderIcon(self.UserButton, "solar:user-bold", 18, UDim2.new(0.5, 0, 0, 9), 13, theme)
	end
	if self.SettingsButton then
		self.SettingsButton.BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar
		renderIcon(self.SettingsButton, "solar:settings-bold", 18, UDim2.new(0.5, 0, 0, 9), 13, theme)
	end
	if self.BackButton then
		self.BackButton.BackgroundColor3 = theme.Button or DEFAULT_THEME.Button
		renderBackIcon(self.BackButton, theme)
	end

	for _, descendant in ipairs(self.Window:GetDescendants()) do
		if descendant:IsA("UIStroke") then
			descendant.Color = theme.Stroke or DEFAULT_THEME.Stroke
		elseif descendant:IsA("TextLabel") then
			local textColor = theme.Text or DEFAULT_THEME.Text
			if descendant == self.TitleLabel then
				textColor = theme.TopbarText or DEFAULT_THEME.TopbarText
			elseif descendant.Name == "Label" or descendant.Name == "Arrow" then
				textColor = theme.MutedText or DEFAULT_THEME.MutedText
			end
			descendant.TextColor3 = textColor
		elseif descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			local gui = descendant :: GuiObject
			if
				descendant.Name == "Minimize"
				or descendant.Name == "UserAction"
				or descendant.Name == "SettingsAction"
			then
				gui.BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar
			elseif descendant.Name:find("Tile", 1, true) then
				gui.BackgroundColor3 = theme.Tile or DEFAULT_THEME.Tile
			else
				gui.BackgroundColor3 = theme.Button or DEFAULT_THEME.Button
			end

			if descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				(descendant :: any).TextColor3 = if descendant.Name == "Minimize"
					then (theme.TopbarText or DEFAULT_THEME.TopbarText)
					else (theme.Text or DEFAULT_THEME.Text)
			end
		elseif descendant:IsA("Frame") then
			if descendant.Name == "Topbar" then
				descendant.BackgroundColor3 = theme.Topbar or DEFAULT_THEME.Topbar
			elseif
				descendant.Name:find("Section", 1, true)
				or descendant.Name == "Dropdown"
				or descendant.Name == "Slider"
			then
				descendant.BackgroundColor3 = theme.Surface or DEFAULT_THEME.Surface
			elseif descendant.Name == "Options" then
				descendant.BackgroundColor3 = theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong
			end
		end
	end
end

function WindowUI:SetThemePreset(name: string)
	local preset = THEME_PRESETS[name]
	if not preset then
		warn(("[WindowUILibrary] theme '%s' does not exist."):format(name))
		return
	end

	self._theme = mergeTheme(preset)
	self:_refreshThemeVisuals()
end

function WindowUI:SetScale(scale: number)
	self._windowBaseScale = math.clamp(scale, 0.82, 1)
	self._config.Scale = self._windowBaseScale
	if self.Window.Visible then
		tween(self.WindowScale, TWEEN_SOFT, { Scale = self._windowBaseScale })
	end
end

function WindowUI:_getCollapsedTopbarPosition(visualWidth: number?, topOffset: number?): UDim2
	local viewport = getViewport()
	local align = tostring(self._topbarAlign or "Center"):lower()
	local width = visualWidth or 44
	local y = topOffset or 9

	if align == "left" then
		return UDim2.fromOffset(12, y)
	end
	if align == "right" then
		return UDim2.fromOffset(math.max(12, viewport.X - width - 12), y)
	end

	return UDim2.fromOffset(math.max(12, (viewport.X - width) / 2), y)
end

function WindowUI:_buildSystemPages()
	local settings = self:_registerApp(
		{
			Id = "__WindowUI_Settings",
			Name = "Settings",
			Icon = "solar:settings-bold",
			Order = -999,
		} :: any,
		false
	)

	local appearance = settings:CreateSection("Appearance")
	settings:AddDropdown({
		Text = "Theme",
		Options = { "Discord Dark", "Midnight", "Graphite", "Amoled" },
		Default = "Discord Dark",
		Callback = function(value)
			self:SetThemePreset(value)
		end,
	}, appearance)
	settings:AddSlider({
		Text = "DPI",
		Min = 82,
		Max = 100,
		Default = math.floor(self._windowBaseScale * 100 + 0.5),
		Step = 1,
		Callback = function(value)
			self:SetScale(value / 100)
		end,
	}, appearance)
	settings:AddToggle({
		Text = "Page background",
		Default = true,
		Callback = function(enabled)
			self._usePageBackground = enabled
			local pageBackground = self:_getPageBackground()
			if self.HomeBackground then
				self.HomeBackground.Image = pageBackground or ""
				self.HomeBackground.ImageTransparency = PAGE_BACKGROUND_TRANSPARENCY
				self.HomeBackground.Visible = pageBackground ~= nil
			end
			if self.AppPageBackground then
				self.AppPageBackground.Image = pageBackground or ""
				self.AppPageBackground.ImageTransparency = PAGE_BACKGROUND_TRANSPARENCY
				self.AppPageBackground.Visible = pageBackground ~= nil
			end
		end,
	}, appearance)

	local behavior = settings:CreateSection("Window")
	settings:AddLabel("Topbar collapse follows TopbarPlus Align", behavior)
	settings:AddLabel("TopbarPlus theme: untouched", behavior)

	local user = self:_registerApp(
		{
			Id = "__WindowUI_User",
			Name = "User",
			Icon = "solar:user-bold",
			Order = -998,
		} :: any,
		false
	)

	local profile = user:CreateSection("Profile")
	local playerName = if LOCAL_PLAYER then LOCAL_PLAYER.Name else "Unknown"
	local displayName = if LOCAL_PLAYER then LOCAL_PLAYER.DisplayName else "Unknown"
	user:AddLabel("Username: " .. playerName, profile)
	user:AddLabel("Display name: " .. displayName, profile)
	user:AddButton({
		Text = "Copy Username",
		Callback = function()
			local setclipboard = getGlobal("setclipboard")
			if type(setclipboard) == "function" then
				pcall(setclipboard, playerName)
			end
		end,
	}, profile)
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
		_topbarAlign = "Center",
		_topbarSheenRunning = false,
		_syncingTopbar = false,
		_destroyed = false,
		_usePageBackground = true,
		_wasDragged = false,
		_windowBaseScale = resolvedConfig.Scale or 0.94,
		_visibleIntent = resolvedConfig.StartOpen ~= false,
		Title = resolvedConfig.Title or resolvedConfig.Name or "Window UI",
	}, WindowUI)

	self:_buildRoot()
	self:_buildTopbar()
	self:_buildBody()
	self:_buildSystemPages()
	self:_bindDrag()
	self:_bindResponsiveLayout()
	self:_setupTopbarPlus(resolvedConfig.TopbarPlus)
	if not self._topbarIcon then
		self:_createFallbackTopbarButton()
	end

	return self
end

function WindowUI:SetVisible(visible: boolean)
	self._visibleIntent = visible

	if self.Window.Visible == visible then
		if visible then
			self:_syncTopbarIcon(true)
		end
		if self.FallbackButton then
			self.FallbackButton.Visible = not visible
		end
		return
	end

	if visible then
		if self.FallbackButton then
			self.FallbackButton.Visible = false
		end
		self:_syncTopbarIcon(true)

		local restoreSize = self._windowRestoreSize or self._baseSize
		local restorePosition = self._windowRestorePosition or self._basePosition
		local openingScale = self._windowBaseScale * 0.78
		self.Window.Size = UDim2.fromOffset(44, 36)
		self.Window.Position = self:_getCollapsedTopbarPosition(44 * openingScale, 9)
		self.Window.Visible = true
		self.WindowScale.Scale = openingScale
		self.Window.BackgroundTransparency = 0.16
		if self.Body then
			self.Body.Visible = false
			self.Body.Position = UDim2.fromOffset(0, 42)
		end
		if self.BodyScale then
			self.BodyScale.Scale = 0.9
		end
		tween(self.Window, TWEEN_WINDOW_IN, {
			BackgroundTransparency = 0.03,
			Position = restorePosition,
			Size = restoreSize,
		})
		tween(self.WindowScale, TWEEN_WINDOW_IN, { Scale = self._windowBaseScale })
		task.delay(0.12, function()
			if self._visibleIntent == true then
				if self.Body then
					self.Body.Visible = true
					tween(self.Body, TWEEN_SOFT, { Position = UDim2.fromOffset(0, 36) })
				end
				if self.BodyScale then
					tween(self.BodyScale, TWEEN_SOFT, { Scale = 1 })
				end
			end
		end)
	else
		self._windowRestoreSize = self.Window.Size
		self._windowRestorePosition = self.Window.Position
		if self.FallbackButton then
			self.FallbackButton.Visible = false
		end
		if self.BodyScale then
			tween(self.BodyScale, TWEEN_BODY_OUT, { Scale = 0.86 })
		end
		local collapseDelay = TWEEN_BODY_OUT.Time * 0.78
		if self.Body then
			tween(self.Body, TWEEN_BODY_OUT, { Position = UDim2.fromOffset(0, 48) })
			task.delay(collapseDelay, function()
				if self._visibleIntent == false and self.Body then
					self.Body.Visible = false
				end
			end)
		end
		task.delay(collapseDelay, function()
			if self._visibleIntent == false then
				local collapsedScale = self._windowBaseScale * 0.74
				tween(self.WindowScale, TWEEN_WINDOW_OUT, { Scale = collapsedScale })
				tween(self.Window, TWEEN_WINDOW_OUT, {
					BackgroundTransparency = 0.16,
					Position = self:_getCollapsedTopbarPosition(44 * collapsedScale, 9),
					Size = UDim2.fromOffset(44, 36),
				})
			end
		end)
		task.delay(collapseDelay + TWEEN_WINDOW_OUT.Time, function()
			if self._visibleIntent == false then
				self.Window.Visible = false
				self.Window.Size = self._windowRestoreSize or self._baseSize
				self.Window.Position = self._windowRestorePosition or self._basePosition
				self.Window.BackgroundTransparency = 0.03
				self.WindowScale.Scale = self._windowBaseScale
				if self.Body then
					self.Body.Visible = true
					self.Body.Position = UDim2.fromOffset(0, 36)
				end
				if self.BodyScale then
					self.BodyScale.Scale = 1
				end
				if self.FallbackButton then
					self.FallbackButton.Visible = true
				end
				self:_syncTopbarIcon(false)
			end
		end)
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
	self:_animatePage(self.HomePage, -18)
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
	self.AppIcon.Visible = true
	renderIcon(self.AppIcon, app.Icon or "solar:star-bold", 26, UDim2.new(0.5, 0, 0, 0), 4, self._theme)

	local backgroundImage = app.BackgroundImage
	self.AppBackground.Image = backgroundImage or ""
	self.AppBackground.Visible = backgroundImage ~= nil and backgroundImage ~= ""

	self.HomePage.Visible = false
	self:_animatePage(self.AppPage, 18)
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

function WindowUI:_registerApp(config: AppConfig, createTile: boolean)
	assert(type(config.Name) == "string" and config.Name ~= "", "CreateApp requires a non-empty Name.")
	local configAny = config :: any
	local appId = if type(configAny.Id) == "string" and configAny.Id ~= "" then configAny.Id else config.Name

	local app = setmetatable({
		Id = appId,
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

	self._appByName[app.Id] = app
	self._appByName[app.Name] = app

	if createTile then
		table.insert(self._apps, app)
		app:_createTile()
		self:_sortAppTiles()
	end

	if config.StartOpen then
		self:OpenApp(app.Id)
	end

	return app
end

function WindowUI:CreateApp(config: AppConfig)
	return self:_registerApp(config, true)
end

function WindowUI:Destroy()
	self._destroyed = true
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
		theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong,
		false
	)

	local holding = false
	local function renderHold(nextHolding: boolean)
		if holding == nextHolding then
			return
		end

		holding = nextHolding
		tween(tileScale, TWEEN_FAST, { Scale = if holding then 0.94 else 1 })
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

	local tileImage = self.TileImage or self.BackgroundImage or library:_getDefaultBackground()
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

	renderIcon(tile, self.Icon or "solar:star-bold", 30, UDim2.new(0.5, 0, 0, 10), 5, theme)

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
		library:OpenApp(self.Id or self.Name)
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
	addCorner(section, UDim.new(0, 10))
	addStroke(section, theme.Stroke or DEFAULT_THEME.Stroke, 0.58, 1)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong),
			ColorSequenceKeypoint.new(1, theme.Surface or DEFAULT_THEME.Surface),
		}),
		Rotation = 90,
		Parent = section,
	})
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
	addCorner(button, UDim.new(0, 9))
	addStroke(button, theme.Stroke or DEFAULT_THEME.Stroke, 0.58, 1)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.ButtonHover or DEFAULT_THEME.ButtonHover),
			ColorSequenceKeypoint.new(1, theme.Button or DEFAULT_THEME.Button),
		}),
		Rotation = 90,
		Parent = button,
	})
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
		Size = UDim2.new(1, -62, 1, 0),
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
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(50, 24),
		Text = "",
		ZIndex = 7,
		Parent = row,
	}) :: TextButton
	addCorner(button, UDim.new(1, 0))
	local switchStroke = addStroke(button, theme.Stroke or DEFAULT_THEME.Stroke, 0.5, 1)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.ButtonHover or DEFAULT_THEME.ButtonHover),
			ColorSequenceKeypoint.new(1, theme.Button or DEFAULT_THEME.Button),
		}),
		Rotation = 90,
		Parent = button,
	})

	local knob = create("Frame", {
		Name = "Knob",
		BackgroundColor3 = theme.Text or DEFAULT_THEME.Text,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 8,
		Parent = button,
	}) :: Frame
	addCorner(knob, UDim.new(1, 0))
	addStroke(knob, theme.Window or DEFAULT_THEME.Window, 0.72, 1)
	local knobScale = create("UIScale", {
		Scale = 1,
		Parent = knob,
	}) :: UIScale

	local function render(fire: boolean)
		local activeTheme = self._library._theme
		tween(button, TWEEN_FAST, {
			BackgroundColor3 = if enabled
				then (activeTheme.Accent or DEFAULT_THEME.Accent)
				else (activeTheme.Button or DEFAULT_THEME.Button),
		})
		tween(switchStroke, TWEEN_FAST, {
			Transparency = if enabled then 0.32 else 0.6,
		})
		tween(knob, TWEEN_SOFT, {
			BackgroundColor3 = activeTheme.Text or DEFAULT_THEME.Text,
			Position = if enabled then UDim2.new(1, -21, 0, 3) else UDim2.fromOffset(3, 3),
		})
		if fire then
			knobScale.Scale = 0.84
			tween(knobScale, TWEEN_SOFT, { Scale = 1 })
		end
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
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 70),
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: Frame
	addCorner(row, UDim.new(0, 10))
	addStroke(row, theme.Stroke or DEFAULT_THEME.Stroke, 0.62, 1)

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
		Position = UDim2.new(1, -10, 0, 7),
		Size = UDim2.fromOffset(66, 22),
		Text = "",
		ZIndex = 6,
		Parent = row,
	}) :: TextLabel
	setText(valueLabel, theme.Text or DEFAULT_THEME.Text, 11, Enum.Font.GothamMedium)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	addCorner(valueLabel, UDim.new(0, 8))
	addStroke(valueLabel, theme.Stroke or DEFAULT_THEME.Stroke, 0.76, 1)

	local track = create("TextButton", {
		Name = "Track",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button or DEFAULT_THEME.Button,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 45),
		Size = UDim2.new(1, -24, 0, 10),
		Text = "",
		ZIndex = 6,
		Parent = row,
	}) :: TextButton
	addCorner(track, UDim.new(1, 0))
	addStroke(track, theme.Stroke or DEFAULT_THEME.Stroke, 0.76, 1)

	local fill = create("Frame", {
		Name = "Fill",
		BackgroundColor3 = theme.Accent or DEFAULT_THEME.Accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 7,
		Parent = track,
	}) :: Frame
	addCorner(fill, UDim.new(1, 0))
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
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 8,
		Parent = track,
	}) :: Frame
	addCorner(knob, UDim.new(1, 0))
	addStroke(knob, theme.Window or DEFAULT_THEME.Window, 0.16, 2)
	local knobScale = create("UIScale", {
		Scale = 1,
		Parent = knob,
	}) :: UIScale

	local function snap(raw: number): number
		if step <= 0 then
			return raw
		end

		return minValue + math.floor(((raw - minValue) / step) + 0.5) * step
	end

	local function setValue(nextValue: number, fire: boolean)
		value = math.clamp(snap(nextValue), minValue, maxValue)
		local percent = (value - minValue) / (maxValue - minValue)
		local fillSize = UDim2.fromScale(percent, 1)
		local knobPosition = UDim2.fromScale(percent, 0.5)
		if fire then
			tween(fill, TWEEN_FAST, { Size = fillSize })
			tween(knob, TWEEN_FAST, { Position = knobPosition })
		else
			fill.Size = fillSize
			knob.Position = knobPosition
		end
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
		tween(knobScale, TWEEN_FAST, { Scale = 1.14 })
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
			tween(knobScale, TWEEN_SOFT, { Scale = 1 })
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
	addCorner(box, UDim.new(0, 8))
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
		ClipsDescendants = false,
		Size = UDim2.new(1, 0, 0, 64),
		ZIndex = 6,
		Parent = self:_resolveParent(parent),
	}) :: Frame
	addCorner(row, UDim.new(0, 10))
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
	addCorner(button, UDim.new(0, 8))
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
	addCorner(optionsFrame, UDim.new(0, 8))
	addStroke(optionsFrame, theme.Stroke or DEFAULT_THEME.Stroke, 0.6, 1)
	addList(optionsFrame, 0)
	local optionsScale = create("UIScale", {
		Scale = 0.96,
		Parent = optionsFrame,
	}) :: UIScale

	local optionButtons: { TextButton } = {}
	local function paintOption(optionButton: TextButton, hovering: boolean)
		local activeTheme = self._library._theme
		local isSelected = optionButton.Text == selected
		optionButton.BackgroundColor3 = if isSelected or hovering
			then (activeTheme.ButtonHover or DEFAULT_THEME.ButtonHover)
			else (activeTheme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong)
		optionButton.TextColor3 = if isSelected
			then (activeTheme.Text or DEFAULT_THEME.Text)
			else (activeTheme.MutedText or DEFAULT_THEME.MutedText)
	end

	local renderId = 0
	local function renderOpen()
		renderId += 1
		local currentRenderId = renderId
		local activeTheme = self._library._theme
		local optionHeight = #options * 28
		optionsFrame.BackgroundColor3 = activeTheme.SurfaceStrong or DEFAULT_THEME.SurfaceStrong
		arrow.Text = "v"
		tween(arrow, TWEEN_FAST, { Rotation = if open then 180 else 0 })
		tween(row, TWEEN_SOFT, {
			Size = if open then UDim2.new(1, 0, 0, 74 + optionHeight) else UDim2.new(1, 0, 0, 64),
		})
		if open then
			optionsFrame.Visible = true
			optionsFrame.BackgroundTransparency = 0.16
			optionsScale.Scale = 0.96
			tween(optionsFrame, TWEEN_FAST, { BackgroundTransparency = 0.03 })
			tween(optionsScale, TWEEN_SOFT, { Scale = 1 })
		else
			tween(optionsFrame, TWEEN_FAST, { BackgroundTransparency = 0.18 })
			tween(optionsScale, TWEEN_FAST, { Scale = 0.96 })
			task.delay(TWEEN_FAST.Time, function()
				if renderId == currentRenderId and not open then
					optionsFrame.Visible = false
				end
			end)
		end

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
