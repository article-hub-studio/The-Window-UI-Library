# The Window UI Library

Roblox Luau UI library kiểu floating window cho executor LocalScript. Bản này chỉ là UI:

- Executor-only: service được lấy qua `cloneref` nếu executor hỗ trợ.
- Ưu tiên parent GUI bằng `gethui()`, fallback `CoreGui`, và gọi `protectgui`/`syn.protect_gui` nếu có.
- Theme mặc định kiểu Discord dark, float window chính vẫn vuông, control như toggle/slider dùng corner nhẹ.
- Topbar có title và nút `-`; bấm `-` sẽ hide window. Khi window hide, nút TopbarPlus/fallback hiện; bấm nút đó thì window hiện lại và nút tự ẩn.
- Topbar trong window có nút User và Settings; Settings có chọn theme, DPI và toggle background.
- App ở màn hình chính là tile kiểu Windows: icon ở trên, tên app ở dưới, có thể dùng image background.
- Home/Tabs, App page và tile fallback dùng background sọc đen generate sẵn ở [assets/dark-stripe-background.jpg](assets/dark-stripe-background.jpg); page background được render mờ/transparency để không lấn nội dung.
- Topbar window có overlay liquid-glass generate sẵn ở [assets/liquid-glass-topbar.jpg](assets/liquid-glass-topbar.jpg); Button/Toggle/Dropdown/GroupBox/TabBox dùng texture control ở [assets/liquid-glass-controls.jpg](assets/liquid-glass-controls.jpg).
- Giữ app tile sẽ shrink nhẹ và hiện stroke gradient highlight.
- Bấm app sẽ đổi cùng float window sang page của app đó, không mở thêm window riêng.
- Window hide sẽ co page còn topbar, rồi topbar thu nhỏ và chạy về vị trí TopbarPlus theo `Align`; page/app transition có slide, scale và background fade.
- Button, toggle và dropdown có liquid-glass hover/open animation, sweep sheen và spark nhỏ khi click.
- Có `CreateGroupBox` và `CreateTabBox` để gom control thành cụm hoặc tab nội bộ trong page.
- Có nút back icon-only dùng Solar icon PNG/fallback để quay lại app grid.
- Kéo topbar để di chuyển window, tự co layout cho mobile.
- Hỗ trợ icon dạng `solar:<name>`, `craft:<name>`, URL ảnh, `rbxassetid://...`.
- Nếu executor có `writefile`, `readfile`, `getcustomasset`, library sẽ cache icon Windows topbar, liquid-glass topbar/control texture và icon URL/Iconify về file local.
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
	Icon = "solar:settings-bold",
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

Trả về `getcustomasset` path của tile background sọc đen generate sẵn nếu executor hỗ trợ `writefile/readfile/getcustomasset`.

### `WindowUI.GetPageBackground()`

Trả về `getcustomasset` path của page background sọc đen dùng cho Home/Tabs và App page.

### `WindowUI.GetTopbarGlass()`

Trả về `getcustomasset` path của liquid-glass topbar texture generate sẵn.

### `WindowUI.GetControlGlass()`

Trả về `getcustomasset` path của liquid-glass texture dùng cho Button/Toggle/Dropdown/GroupBox/TabBox.

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
Icon = "solar:settings-bold"
Icon = "solar:settings" -- auto thử settings/settings-bold/settings-linear/settings-outline/settings-broken
Icon = "craft:tools"
Icon = "https://example.com/icon.png"
Icon = { Pack = "Solar", Name = "user-bold" }
Icon = { Pack = "Craft", Name = "shield" }
```

Solar icon dùng Iconify API dạng `https://api.iconify.design/solar:settings-bold.svg`, sau đó render SVG thành PNG và cache bằng `writefile/getcustomasset`. Craft icon trong executor vẫn có fallback shape local để không phụ thuộc Figma runtime.

### App Controls

```lua
local section = app:CreateSection("Section title")
local group = app:CreateGroupBox("Group title", section)
app:AddLabel("Text", section)
app:AddButton({ Text = "Button", Callback = function() end }, section)
app:AddToggle({ Text = "Toggle", Default = false, Callback = function(value) end }, group)
app:AddSlider({ Text = "Slider", Min = 0, Max = 100, Default = 50, Step = 1, Callback = function(value) end }, section)
app:AddTextBox({ Text = "Input", Placeholder = "Type here", Callback = function(text) end }, section)
app:AddDropdown({ Text = "Mode", Options = { "A", "B" }, Default = "A", Callback = function(value) end }, section)

local tabBox = app:CreateTabBox({
	Title = "Toolbox",
	Tabs = { "Main", "Modes" },
	Default = "Main",
}, section)

local mainPage = tabBox:GetPage("Main")
local modesPage = tabBox:GetPage("Modes")
app:AddButton({ Text = "Run", Callback = function() end }, mainPage)
app:AddDropdown({ Text = "Mode", Options = { "A", "B" } }, modesPage)
```

## Notes

Roblox `UIShadow` mới render shadow dưới parent UI instance và có các property như `BlurRadius`, `Color`, `Offset`, `Spread`, `Transparency`. Library dùng `pcall` khi tạo `UIShadow` để vẫn chạy được trên client chưa có capability này.
