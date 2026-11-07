# Os-UI — MacUI &  for Roblox


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


