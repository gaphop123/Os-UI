# Os-UI — MacUI & WinUI for Roblox

Two visual-language sibling libraries sharing one `CreateWindow → CreateTab → CreateSection → Create<Element>` API:

| Library | Style | File |
| --- | --- | --- |
| **MacUI** | macOS Tahoe liquid glass | `MacUI.luau` |
| **WinUI** | Windows 11 Fluent / PowerToys settings app | `WinUI.luau` |

---

## MacUI v2.7 — Tahoe Liquid Glass

MacUI is a macOS-inspired Roblox UI library with Tahoe-style liquid glass, Golden Gate warmth, animated dock navigation, a boot screen, Lucide icons, settings/config support, and polished SFX.

### Load

```lua
local MacUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"
))()
```

### What's new in v2.7

- Touch-only players get a floating **Open UI** button after minimizing; PC and keyboard-capable players keep the existing hotkey flow.
- A Welcome tab now opens first, with the player's headshot, account name, device type, live player count, FPS, and ping.
- Set `WelcomeTab = false` in `CreateWindow` if you want to opt out of the built-in dashboard.

### v2.6 highlights

- Tahoe glass refresh: a refractive inner edge, accent bloom, stronger specular depth, and an optional window-only light sweep.
- Two new themes: `Tahoe Dawn` and `Golden Gate Dawn`.
- New elements: `CreateStepper`, `CreateRating`, and `CreateCallout`.
- New sound hooks: `Tick`, `Sparkle`, and `Callout`; existing SFX remain compatible.
- Progress bars now use a subtle animated sheen when their value changes.

### Quick start

```lua
local MacUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"
))()

local Window = MacUI:CreateWindow({
    Name = "Tahoe Hub",
    Subtitle = "v2.7",
    Theme = "Tahoe Dawn",
    Boot = true,
    Dock = true,
    Acrylic = true,
    TahoeMotion = true,
    Metaballs = true,
    Size = UDim2.new(0, 760, 0, 500),
    MinSize = Vector2.new(480, 320),
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigurationSaving = { Enabled = true, Folder = "MyHub", File = "settings" }
})

local Home = Window:CreateTab({Name = "Home", Icon = "home"})
local Main = Home:CreateSection({Name = "Controls", Collapsible = true})

Main:CreateToggle({
    Name = "Auto Farm", CurrentValue = false, Flag = "AutoFarm",
    Callback = function(enabled) print("Auto farm:", enabled) end
})

Window:CreateSettingsTab()
```

### Window options

| Option | Default | Purpose |
| --- | --- | --- |
| `Name` | `"MacUI"` | Window title |
| `Theme` | `"Golden Gate"` | Starting theme |
| `Boot` | `true` | Show the Apple-style boot sequence |
| `Dock` | `true` | Show bottom dock navigation |
| `Acrylic` | `true` | Use translucent window glass |
| `TahoeMotion` | `false` | Animate one subtle light sweep across the window |
| `Metaballs` | `false` | Add drifting liquid blobs behind the window tint |
| `WelcomeTab` | `true` | Open the built-in player/server dashboard first |

### Themes

`Golden Gate`, `Golden Gate Dawn`, `Tahoe Dawn`, `Liquid Glass Dark`, `Liquid Glass Light`, `Graphite`, `Midnight`, `Blue`, `Purple`, `Nord`, `Solarized`, `Rose Pine`, `Forest`, `Classic Aqua`, `Crimson`, `Ocean`, `Lavender`, `Monochrome`, `Sunset`, `Arctic`, `Halloween`.

### Elements

`CreateButton`, `CreateToggle`, `CreateCheckbox`, `CreateSlider`, `CreateStepper`, `CreateDropdown`, `CreateRadioGroup`, `CreateSegmentedControl`, `CreateInput`, `CreateKeybind`, `CreateColorPicker`, `CreateRating`, `CreateProgressBar`, `CreateLabel`, `CreateParagraph`, `CreateCallout`.

Full details (key system, window helpers, motion/accessibility, sound keys) are unchanged from prior releases — see inline doc comments in `MacUI.luau`.

---

## WinUI v3.0 — Windows 11 Fluent / PowerToys

WinUI is reskinned from the ground up for a **Windows 11 Mica + PowerToys settings-app** look: a left `NavigationView` with icon+label tabs and a sliding accent selection indicator, `SettingsCard`-style sections with divided rows, Win11 toggle pills, a real title bar with hover-highlighted minimize/maximize/close buttons, and InfoBar-style callouts.

### Load

```lua
local WinUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"
))()
```

### What's new in v3.0

- Full Windows 11 / PowerToys visual rewrite (previous releases looked like Windows 10).
- Left `NavigationView` tabs (collapsible to icon-only via the hamburger button) replace the old taskbar-style tab bar.
- Sections are now `SettingsCard` groups: a card per section, with each element rendered as a divided row (label + description on the left, control on the right) — matching PowerToys' module pages exactly.
- New elements: `CreateNumberBox` (spinner), `CreateCallout` (InfoBar banner with Info/Success/Warning/Danger styles), `CreateSegmentedControl`.
- New themes: `Windows 11 Dark`, `Windows 11 Light`, `PowerToys Dark`, `Mica Blue`.

### Quick start

```lua
local WinUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"
))()

local Window = WinUI:CreateWindow({
    Name = "My Hub",
    Subtitle = "v3.0",
    Theme = "PowerToys Dark",
    Size = UDim2.new(0, 840, 0, 540),
    MinSize = Vector2.new(620, 400),
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigurationSaving = { Enabled = true, Folder = "MyHub", File = "settings" }
})

local Tab1 = Window:CreateTab({ Name = "General", Icon = "home" })
local Section1 = Tab1:CreateSection({ Name = "Core" })
local Section2 = Tab1:CreateSection({ Name = "Advanced", Collapsible = true })

Section1:CreateToggle({
    Name = "Auto Farm", Description = "Automatically farm nearby nodes",
    CurrentValue = false, Flag = "AutoFarm",
    Callback = function(enabled) print("Auto farm:", enabled) end
})

Section1:CreateSlider({
    Name = "Walk Speed", Description = "Character movement speed",
    Min = 16, Max = 120, Increment = 4, CurrentValue = 24, Flag = "WalkSpeed",
    Callback = function(value) print("Speed:", value) end
})

Section2:CreateNumberBox({
    Name = "Retry Count", Min = 0, Max = 10, Step = 1, CurrentValue = 3,
    Callback = function(value) print("Retries:", value) end
})

Section2:CreateCallout({
    Style = "Warning", Title = "Experimental",
    Content = "This section changes server-side behavior."
})

local Tab2 = Window:CreateTab({ Name = "Visuals", Icon = "eye" })
local VisSection = Tab2:CreateSection({ Name = "Display" })

VisSection:CreateDropdown({
    Name = "Theme Preview", Options = {"Windows 11 Dark", "Windows 11 Light", "PowerToys Dark", "Mica Blue"},
    CurrentOption = "PowerToys Dark",
    Callback = function(v) WinUI:SetTheme(v) end
})

Window:CreateSettingsTab()
```

### Window options

| Option | Default | Purpose |
| --- | --- | --- |
| `Name` | `"WinUI"` | Window title (rendered in the title bar) |
| `Subtitle` | `""` | Appended after the title, matching Win11 title bars |
| `Theme` | `"Windows 11 Dark"` | Starting theme |
| `Accent` | Theme default | Override the accent color used for selection, toggles, and fills |
| `Size` | `840 × 540` | Initial `UDim2` size |
| `MinSize` | `620 × 400` | Resize floor (`UISizeConstraint`) |
| `ToggleKey` | `RightControl` | Hide/show key |
| `NavCollapsed` | `false` | Start the left nav in icon-only mode |
| `ConfigurationSaving` | — | `{ Enabled, Folder, File }`, same shape as MacUI |

### Themes

`Windows 11 Dark`, `Windows 11 Light`, `PowerToys Dark`, `Mica Blue`. Register more with `WinUI:RegisterTheme(name, themeTable)` and switch at runtime with `WinUI:SetTheme(name)`.

### Layout — Tab → Section → Elements

```
Window
 └─ Tab1 (left nav item, icon + label)
     ├─ Section ("SettingsCard" group with a title bar)
     │    ├─ element row
     │    ├─ divider
     │    └─ element row
     └─ Section (Collapsible = true → chevron toggles the card)
 └─ Tab2
     └─ Section
         └─ ...
```

### Elements

Every element lives on a `Section` and takes `Name`, `Description` (optional, shown as secondary text under the label like PowerToys), `Flag` (for config persistence), and `Callback`.

| Element | Use |
| --- | --- |
| `CreateToggle` | Win11 pill switch |
| `CreateCheckbox` | Square checkbox |
| `CreateButton` | Accent-filled action button |
| `CreateSlider` | Drag-to-set numeric slider with live value label |
| `CreateNumberBox` | PowerToys-style spinner with up/down steppers |
| `CreateDropdown` | Combo box that opens a flyout list |
| `CreateSegmentedControl` | Horizontal pivot/segmented buttons |
| `CreateInput` | Single-line text box |
| `CreateKeybind` | Click-to-rebind key capture |
| `CreateColorPicker` | Swatch that cycles an accent palette |
| `CreateProgressBar` | Thin animated progress fill |
| `CreateLabel`, `CreateParagraph` | Plain and title+body text rows |
| `CreateCallout` | InfoBar banner (`Style = "Info"/"Success"/"Warning"/"Danger"`) |

### Window helpers

```lua
Window:SetTitle("New title", "New subtitle")
Window:Minimize()
Window:Maximize()
Window:Toggle()
Window:SaveConfig()
Window:LoadConfig()
Window:Destroy()
```

### Notifications

```lua
WinUI:Notify({
    Title = "Saved",
    Content = "Your settings were saved.",
    Style = "Success", -- Info, Success, Warning, Danger/Error
    Duration = 4
})
```

WinUI runs in Roblox Studio and executor environments. File-backed configuration is used only when the host provides `writefile`/`readfile`/`isfile`/`makefolder`/`isfolder`; the interface continues to work without them.
