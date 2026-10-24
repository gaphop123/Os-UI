# MacUI v2.6 — Tahoe Liquid Glass for Roblox

MacUI is a macOS-inspired Roblox UI library with Tahoe-style liquid glass, Golden Gate warmth, animated dock navigation, a boot screen, Lucide icons, settings/config support, and polished SFX.

## Load

```lua
local MacUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"
))()
```

## What’s new in v2.6

- Tahoe glass refresh: a refractive inner edge, accent bloom, stronger specular depth, and an optional window-only light sweep.
- Two new themes: `Tahoe Dawn` and `Golden Gate Dawn`.
- New elements: `CreateStepper`, `CreateRating`, and `CreateCallout`.
- New sound hooks: `Tick`, `Sparkle`, and `Callout`; existing SFX remain compatible.
- Progress bars now use a subtle animated sheen when their value changes.

## Quick start

```lua
local MacUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"
))()

local Window = MacUI:CreateWindow({
    Name = "Tahoe Hub",
    Subtitle = "v2.6",
    Theme = "Tahoe Dawn",
    Boot = true,
    Dock = true,
    Acrylic = true,
    TahoeMotion = true, -- slow, window-only glass light sweep
    Metaballs = true,
    Size = UDim2.new(0, 760, 0, 500),
    MinSize = Vector2.new(480, 320),
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigurationSaving = {
        Enabled = true,
        Folder = "MyHub",
        File = "settings"
    }
})

local Home = Window:CreateTab({Name = "Home", Icon = "home"})
local Main = Home:CreateSection({Name = "Controls", Collapsible = true})

Main:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(enabled)
        print("Auto farm:", enabled)
    end
})

Main:CreateStepper({
    Name = "Walk Speed",
    Min = 16,
    Max = 120,
    Step = 4,
    CurrentValue = 24,
    Suffix = " studs/s",
    Flag = "WalkSpeed",
    Callback = function(value)
        print("Speed:", value)
    end
})

Main:CreateRating({
    Name = "Experience",
    Max = 5,
    CurrentValue = 4,
    Flag = "ExperienceRating",
    Callback = function(stars)
        print("Rating:", stars)
    end
})

Main:CreateCallout({
    Style = "Info", -- Info, Success, Warning, Danger or Error
    Title = "Tahoe glass enabled",
    Content = "The ambient sweep respects Reduce Motion."
})

local Progress = Main:CreateProgressBar({Name = "Loading", CurrentValue = 0})
Progress:Set(65)

Window:CreateSettingsTab()
```

## Window options

| Option | Default | Purpose |
| --- | --- | --- |
| `Name` | `"MacUI"` | Window title |
| `Subtitle` | `""` | Title-bar supporting text |
| `Theme` | `"Golden Gate"` | Starting theme |
| `Boot` | `true` | Show the Apple-style boot sequence |
| `Dock` | `true` | Show bottom dock navigation |
| `Acrylic` | `true` | Use translucent window glass |
| `TahoeMotion` | `false` | Animate one subtle light sweep across the window |
| `Metaballs` | `false` | Add drifting liquid blobs behind the window tint |
| `Size` | `760 × 500` | Initial `UDim2` size |
| `MinSize` / `MaxSize` | `480 × 320` / `nil` | Resize bounds |
| `Resizable` | `true` | Show the bottom-right resize grip |
| `ToggleKey` | `RightControl` | Hide/show key |

## Themes

Built in: `Golden Gate`, `Golden Gate Dawn`, `Tahoe Dawn`, `Liquid Glass Dark`, `Liquid Glass Light`, `Graphite`, `Midnight`, `Blue`, `Purple`, `Nord`, `Solarized`, `Rose Pine`, `Forest`, `Classic Aqua`, `Crimson`, `Ocean`, `Lavender`, `Monochrome`, `Sunset`, `Arctic`, and `Halloween`.

```lua
MacUI:SetTheme("Golden Gate Dawn")
MacUI:SetTheme("Tahoe Dawn")

-- Classic three-layer glass remains available for minimal UIs.
MacUI:SetGlassStyle({Tahoe = false})
```

`MacUI:SetTheme(name)` recolors existing windows. Register a palette with `MacUI:RegisterTheme(name, themeTable)`, or attach an optional PixelJSON background with:

```lua
MacUI:SetThemeImage("Tahoe Dawn", "https://example.com/background.json", {
    Transparency = 0.42,
    Fit = "cover"
})
```

## Elements

Every interactive element uses `Callback`, and most accept `Flag` for config persistence. Returned handles provide `Set(...)` / `Get()` where applicable.

| Element | Use |
| --- | --- |
| `CreateButton` | Button with optional description |
| `CreateToggle`, `CreateCheckbox` | Boolean inputs |
| `CreateSlider`, `CreateStepper` | Numeric inputs; use `Stepper` for exact increments |
| `CreateDropdown`, `CreateRadioGroup`, `CreateSegmentedControl` | Single-choice inputs |
| `CreateInput`, `CreateKeybind` | Text and key input |
| `CreateColorPicker` | Hue/saturation/value picker |
| `CreateRating` | 1–N star rating with hover preview |
| `CreateProgressBar` | Animated non-interactive progress indicator |
| `CreateLabel`, `CreateParagraph`, `CreateCallout` | Informational content |

### Stepper

```lua
local Amount = Section:CreateStepper({
    Name = "Amount",
    Min = 0,
    Max = 50,
    Step = 5,
    CurrentValue = 10,
    Suffix = "x",
    Flag = "Amount"
})

Amount:Set(25)
print(Amount:Get())
```

### Rating

```lua
Section:CreateRating({
    Name = "Rate this UI",
    Max = 5,
    CurrentValue = 0,
    Callback = function(value)
        MacUI:Notify({
            Title = "Thanks!",
            Content = "You chose " .. value .. " stars.",
            Icon = "star"
        })
    end
})
```

### Callout

```lua
Section:CreateCallout({
    Style = "Warning",
    Title = "Experimental setting",
    Content = "This action may change how your character moves."
})
```

## Motion, accessibility, and sound

All library motion goes through `MacUI.Tween`, which immediately resolves when reduced motion is enabled. SFX also respect this setting.

```lua
MacUI:SetAccessibility({
    ReducedMotion = true,
    HighContrast = false,
    Scale = 1
})

MacUI:SetSFXVolume(0.45) -- 0–1; use 0 to mute
MacUI.PlaySound("Sparkle")
```

Available sound keys include `Click`, `Hover`, `ToggleOn`, `ToggleOff`, `Success`, `Error`, `Notify`, `Boot`, `Dock`, `Open`, `Close`, `Tab`, `Slider`, `Focus`, `Dropdown`, `Segment`, `Grab`, `Release`, `Search`, `Color`, `Check`, `Radio`, `Rating`, `Progress`, `Expand`, `Collapse`, `Stepper`, `Tick`, `Sparkle`, and `Callout`.

## Window helpers

```lua
Window:SetTitle("New title", "New subtitle")
Window:Minimize()
Window:Maximize()
Window:Toggle()
Window:SaveConfig()
Window:LoadConfig()
Window:Destroy()
```

Sections can collapse cleanly without changing their content’s layout:

```lua
local Section = Tab:CreateSection({
    Name = "Advanced",
    Collapsible = true,
    Collapsed = false
})

Section:Toggle()
Section:SetCollapsed(true)
print(Section:IsCollapsed())
```

## Key system

```lua
MacUI:SetupKeySystem({
    Enabled = true,
    Key = "ABC-123",
    Timer = 3600,
    Title = "My Hub",
    Note = "Enter your access key"
})

MacUI:RunKeySystem(function()
    -- Create the window here.
end, function(reason)
    warn("Key system:", reason) -- invalid_key or closed
end)
```

MacUI runs in Roblox Studio and executor environments. File-backed configuration is used only when the host provides file APIs; the interface continues to work without them.
