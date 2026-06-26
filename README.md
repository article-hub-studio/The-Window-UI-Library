# The Window UI Library

Roblox Luau UI library mô phỏng giao diện Windows 11 / Seelen UI:

- Desktop full-screen với wallpaper image tuỳ chỉnh.
- Start menu dạng floating window có topbar, nút `-` và `x`.
- App tab là tile kiểu Windows 11: icon ở trên, tên app ở dưới, tile background bằng image.
- Bấm app tile sẽ mở app window riêng.
- App window có topbar, icon, nút minimize, nút close, kéo để di chuyển và kéo góc dưới phải để resize.
- Có taskbar cong ở dưới để mở lại app.
- Tự đổi layout cho mobile hoặc màn hình nhỏ.
- Control cơ bản trong app: section, label, button, toggle, slider, textbox, dropdown.

## Cài Đặt

1. Tạo một `ModuleScript` trong `ReplicatedStorage` tên `WindowUILibrary`.
2. Dán nội dung file [src/WindowUILibrary.luau](src/WindowUILibrary.luau) vào ModuleScript đó.
3. Tạo một `LocalScript` trong `StarterPlayerScripts`.
4. Dán nội dung [examples/demo.client.luau](examples/demo.client.luau) vào LocalScript để chạy demo.
5. Thay `rbxassetid://0` bằng asset id image thật của bạn.

## Ví Dụ Nhanh

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WindowUI = require(ReplicatedStorage:WaitForChild("WindowUILibrary"))

local ui = WindowUI.new({
	Name = "MyWindowsUI",
	WallpaperImage = "rbxassetid://YOUR_WALLPAPER_ID",
	StartOpen = true,
})

local app = ui:CreateApp({
	Name = "Settings",
	Icon = "rbxassetid://YOUR_ICON_ID",
	BackgroundImage = "rbxassetid://YOUR_APP_BACKGROUND_ID",
	TileImage = "rbxassetid://YOUR_TILE_BACKGROUND_ID",
	Size = UDim2.fromOffset(560, 390),
	StartOpen = true,
})

local main = app:CreateSection("Main")
app:AddToggle({
	Text = "Enable feature",
	Default = true,
	Callback = function(enabled)
		print(enabled)
	end,
}, main)

app:AddButton({
	Text = "Run action",
	Callback = function()
		print("Clicked")
	end,
}, main)
```

## API Chính

### `WindowUI.new(config)`

`config`:

- `Name: string?`
- `Parent: Instance?` - mặc định là `Players.LocalPlayer.PlayerGui`.
- `WallpaperImage: string?`
- `WallpaperTransparency: number?`
- `StartOpen: boolean?`
- `DisplayOrder: number?`
- `ResetOnSpawn: boolean?`
- `Theme: Theme?`

### `ui:CreateApp(config)`

`config`:

- `Name: string`
- `Icon: string` - bắt buộc.
- `BackgroundImage: string` - bắt buộc, dùng cho window background nếu không truyền `WindowImage`.
- `TileImage: string?` - background riêng cho app tile.
- `WindowImage: string?` - background riêng cho app window.
- `Size: UDim2?`
- `Position: UDim2?`
- `MinSize: Vector2?`
- `StartOpen: boolean?`
- `Order: number?`

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

## Ghi Chú Thiết Kế

Library này chỉ tạo UI trong Roblox. Nó không chứa executor, injection, remote exploit, hoặc logic liên quan tới bypass game.

Để giống ảnh tham khảo hơn, hãy dùng:

- Wallpaper 16:9 hoặc 21:9 cho `WallpaperImage`.
- Icon vuông PNG có nền trong suốt cho `Icon`.
- Background tile sáng, gradient hoặc screenshot-style cho `TileImage`.
- Background riêng cho từng app nếu muốn mỗi window có chủ đề khác nhau.
