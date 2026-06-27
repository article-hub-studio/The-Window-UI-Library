# The Window UI Library

Roblox Luau UI library kiểu floating window cho executor LocalScript. Bản này chỉ là UI:

- Executor-only: service được lấy qua `cloneref` nếu executor hỗ trợ.
- Ưu tiên parent GUI bằng `gethui()`, fallback `CoreGui`, và gọi `protectgui`/`syn.protect_gui` nếu có.
- Theme mặc định kiểu Discord dark, một float window đơn giản, không dùng `UICorner`, DPI gọn hơn qua `Scale`.
- Topbar có title và nút `-`; bấm `-` sẽ hide window. Khi window hide, nút TopbarPlus/fallback hiện; bấm nút đó thì window hiện lại và nút tự ẩn.
- Topbar trong window có nút User và Settings; Settings có chọn theme, DPI và toggle background.
- App ở màn hình chính là tile kiểu Windows: icon ở trên, tên app ở dưới, có thể dùng image background.
- Nếu app không truyền background riêng, library dùng background sọc đen generate sẵn ở [assets/dark-stripe-background.jpg](assets/dark-stripe-background.jpg).
- Giữ app tile sẽ shrink nhẹ và hiện stroke gradient highlight.
- Bấm app sẽ đổi cùng float window sang page của app đó, không mở thêm window riêng.
- Window show/hide và đổi page có animation chắc hơn bằng scale/slide tween.
- Toggle và dropdown có animation khi đổi trạng thái.
- Có nút back để quay lại app grid.
- Kéo topbar để di chuyển window, tự co layout cho mobile.
- Hỗ trợ icon dạng `solar:<name>`, `craft:<name>`, URL ảnh, `rbxassetid://...`.
- Nếu executor có `writefile`, `readfile`, `getcustomasset`, library sẽ cache icon Windows topbar và icon URL/Iconify về file local.
- Tự dùng `UIShadow` nếu client hỗ trợ shadow mới của Roblox.
- Tự tạo nút TopbarPlus theo docs của `tanhoangviet/ToolForLua`, nhưng không gọi `modifyTheme` để giữ theme TopbarPlus nguyên bản.
- Nếu môi trường không hỗ trợ `loadstring/HttpGet` hoặc bạn tắt TopbarPlus, library sẽ vẽ fallback icon Windows nền đen, icon trắng.

Library không chứa executor, injection, remote exploit, bypass, hoặc logic can thiệp game.

## Cài Đặt

1. Dùng executor chạy [examples/demo.client.luau](examples/demo.client.luau).
2. Example sẽ tự load library từ raw GitHub bằng `loadstring(game:HttpGet(...))()`.
3. Background mặc định đã dùng ảnh sọc đen generate sẵn; bạn vẫn có thể truyền `BackgroundImage`/`TileImage` riêng nếu muốn.

## Ví Dụ Nhanh

```lua
local WindowUI = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/article-hub-studio/The-Window-UI-Library/refs/heads/main/src/WindowUILibrary.luau"
))()

local DEFAULT_BACKGROUND = WindowUI.GetDefaultBackground()

local ui = WindowUI.new({
	Name = "MyWindowUI",
	Title = "Window UI",
	Scale = 0.94,
	StartOpen = true,
	TopbarPlus = {
		Align = "Center",
		Caption = "Toggle Window UI",
	},
})

local app = ui:CreateApp({
	Name = "Home",
	Icon = "solar:settings-linear",
	BackgroundImage = DEFAULT_BACKGROUND,
	TileImage = DEFAULT_BACKGROUND,
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
- `TopbarPlus = { Source = "...", Align = "Center", Label = "", Caption = "..." }`: đổi source/position/label/caption.

Library không modify theme TopbarPlus. Khi window đang mở, TopbarPlus icon sẽ được `setEnabled(false)`; khi window hide, icon `setEnabled(true)` để làm nút mở lại. Icon fallback mặc định được vẽ dạng Windows: nền đen, 4 ô trắng. Nếu bạn truyền `Image`, TopbarPlus sẽ dùng image đó.

## API Chính

### `WindowUI.new(config)`

- `Name: string?`
- `Title: string?`
- `Parent: Instance?` - mặc định là `gethui()` nếu có, fallback `CoreGui`.
- `Size: UDim2?`
- `Position: UDim2?`
- `Scale: number?` - mặc định `0.94` để UI gọn hơn trên executor.
- `StartOpen: boolean?`
- `DisplayOrder: number?`
- `ResetOnSpawn: boolean?`
- `TopbarPlus: boolean | table?`
- `Theme: table?`

### `WindowUI.GetDefaultBackground()`

Trả về `getcustomasset` path của background sọc đen generate sẵn nếu executor hỗ trợ `writefile/readfile/getcustomasset`.

### `ui:CreateApp(config)`

- `Name: string`
- `Icon: string | table?`
- `BackgroundImage: string?`
- `TileImage: string?`
- `Order: number?`
- `StartOpen: boolean?`

Icon formats:

```lua
Icon = "rbxassetid://123456"
Icon = "solar:settings-linear"
Icon = "solar:settings" -- auto thử settings/settings-linear/settings-outline/settings-broken
Icon = "craft:tools"
Icon = "https://example.com/icon.png"
Icon = { Pack = "Solar", Name = "user-rounded-linear" }
Icon = { Pack = "Craft", Name = "shield" }
```

Solar icon dùng Iconify API theo collection `solar`. Craft icon trong executor được render bằng fallback shape local để không phụ thuộc Figma runtime.

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
