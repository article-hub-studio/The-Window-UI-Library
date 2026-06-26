# The Window UI Library

Roblox Luau UI library kiểu floating window cho executor-style LocalScript. Bản này chỉ là UI:

- Một float window đơn giản, không dùng `UICorner`.
- Topbar có title và nút `-`; bấm `-` sẽ hide window.
- App ở màn hình chính là tile kiểu Windows: icon ở trên, tên app ở dưới, có thể dùng image background.
- Bấm app sẽ đổi cùng float window sang page của app đó, không mở thêm window riêng.
- Có nút back để quay lại app grid.
- Kéo topbar để di chuyển window, tự co layout cho mobile.
- Tự dùng `UIShadow` nếu client hỗ trợ shadow mới của Roblox.
- Tự tạo nút TopbarPlus theo docs của `tanhoangviet/ToolForLua`; nếu môi trường không hỗ trợ `loadstring/HttpGet`, library sẽ vẽ fallback icon Windows nền đen, icon trắng.

Library không chứa executor, injection, remote exploit, bypass, hoặc logic can thiệp game.

## Cài Đặt

1. Tạo `ModuleScript` trong `ReplicatedStorage` tên `WindowUILibrary`.
2. Dán nội dung [src/WindowUILibrary.luau](src/WindowUILibrary.luau) vào ModuleScript đó.
3. Tạo `LocalScript` trong `StarterPlayerScripts`.
4. Dán nội dung [examples/demo.client.luau](examples/demo.client.luau) vào LocalScript để chạy demo.
5. Thay `rbxassetid://0` bằng image asset id thật nếu muốn background riêng cho app.

## Ví Dụ Nhanh

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WindowUI = require(ReplicatedStorage:WaitForChild("WindowUILibrary"))

local ui = WindowUI.new({
	Name = "MyWindowUI",
	Title = "Window UI",
	StartOpen = true,
	TopbarPlus = {
		Align = "Left",
		Caption = "Toggle Window UI",
	},
})

local app = ui:CreateApp({
	Name = "Settings",
	Icon = "rbxassetid://YOUR_ICON_ID",
	BackgroundImage = "rbxassetid://YOUR_BACKGROUND_ID",
	TileImage = "rbxassetid://YOUR_TILE_BACKGROUND_ID",
	StartOpen = true,
})

local section = app:CreateSection("Main")
app:AddToggle({
	Text = "Enable feature",
	Default = true,
	Callback = function(enabled)
		print(enabled)
	end,
}, section)

app:AddButton({
	Text = "Run action",
	Callback = function()
		print("Clicked")
	end,
}, section)
```

## TopbarPlus

Mặc định `WindowUI.new()` sẽ thử load TopbarPlus Extended theo docs:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/tanhoangviet/ToolForLua/refs/heads/main/TopbarPlus_Extended.lua"))()
```

Config:

- `TopbarPlus = true` hoặc bỏ trống: auto-load TopbarPlus Extended.
- `TopbarPlus = false`: không load TopbarPlus, chỉ dùng fallback button trong `ScreenGui`.
- `TopbarPlus = { Icon = Icon }`: dùng `Icon` class bạn đã load sẵn.
- `TopbarPlus = { Source = "...", Align = "Left", Caption = "..." }`: đổi source/position/caption.

Icon mặc định được vẽ dạng Windows: nền đen, 4 ô trắng. Nếu bạn truyền `Image`, library sẽ dùng image đó thay icon tự vẽ.

## API Chính

### `WindowUI.new(config)`

- `Name: string?`
- `Title: string?`
- `Parent: Instance?` - mặc định là `Players.LocalPlayer.PlayerGui`.
- `Size: UDim2?`
- `Position: UDim2?`
- `StartOpen: boolean?`
- `DisplayOrder: number?`
- `ResetOnSpawn: boolean?`
- `TopbarPlus: boolean | table?`
- `Theme: table?`

### `ui:CreateApp(config)`

- `Name: string`
- `Icon: string?`
- `BackgroundImage: string?`
- `TileImage: string?`
- `Order: number?`
- `StartOpen: boolean?`

### App Controls

```lua
local section = app:CreateSection("Section title")
app:AddLabel("Text", section)
app:AddButton({ Text = "Button", Callback = function() end }, section)
app:AddToggle({ Text = "Toggle", Default = false, Callback = function(value) end }, section)
app:AddSlider({ Text = "Slider", Min = 0, Max = 100, Default = 50, Step = 1, Callback = function(value) end }, section)
app:AddTextBox({ Text = "Input", Placeholder = "Type here", Callback = function(text) end }, section)
app:AddDropdown({ Text = "Mode", Options = { "A", "B" }, Default = "A", Callback = function(value) end }, section)
```

## Notes

Roblox `UIShadow` mới render shadow dưới parent UI instance và có các property như `BlurRadius`, `Color`, `Offset`, `Spread`, `Transparency`. Library dùng `pcall` khi tạo `UIShadow` để vẫn chạy được trên client chưa có capability này.
