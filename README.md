# Os-UI (WinUI & MacUI)

A collection of lightweight, feature-rich Roblox UI libraries inspired by Windows 10 and macOS Big Sur / Sonoma / Sequoia design systems.

---

## ⚡ Quick Load

```lua
-- Windows 10 Style (v2.0.0)
local WinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"))()

-- macOS Style (v2.1.0)
local MacUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"))()
```

---

## 🍎 MacUI (v2.1.0)

Gives your script a clean macOS aesthetic complete with a functional Dock, **true 3-layer liquid glass** on every control, boot sequence, Lucide icon support, an executor-ready config system, a drop-in Settings tab, **metaball-style dock indicators**, and a fully fixed dropdown.

> **v2.1.0 highlights**
> - **3-layer liquid glass** — Base fill → Frost (diffusion + depth gradient) → Specular sheen + inner rim light
> - **UI corners fixed** — consistent radius on every glass layer, rim, buttons and list items
> - **Dropdown fixed** — no longer clipped by scroll/section, outside-click closes, smooth open/close, chevron, proper glass panel
> - **Metaball dock indicators** — overlapping soft blobs under the active tab for an organic liquid look
> - Hub stays hidden until boot finishes; dock icons bounce correctly; liquid glass applies to every control

### Starter Template

```lua
local Window = MacUI:CreateWindow({
    Name = "Admin Panel",
    Subtitle = "v2.1",
    Theme = "Liquid Glass Dark", -- see Themes below
    Boot = true,                 -- Apple boot animation (hub hidden until it finishes)
    Dock = true,                 -- Bottom tab dock with metaball indicators
    Acrylic = true,              -- 3-layer glassmorphism
    Size = UDim2.new(0, 760, 0, 500),
    MinSize = Vector2.new(480, 320),
    ConfigurationSaving = {      -- optional, executor-only
        Enabled = true,
        Folder = "MyScriptHub",
        File = "default"
    }
})

local HomeTab = Window:CreateTab({
    Name = "Home",
    Icon = "home"
})

local MainSection = HomeTab:CreateSection("Main Features")

MainSection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(state)
        print("Auto Farm:", state)
    end
})

MainSection:CreateButton({
    Name = "Teleport to Spawn",
    Description = "Sends your character back to spawn",
    Callback = function()
        MacUI:Notify({
            Title = "Teleported",
            Content = "Successfully moved to spawn.",
            Icon = "check",
            Duration = 3
        })
    end
})

MainSection:CreateDropdown({
    Name = "Select Mode",
    Options = {"Mode A", "Mode B", "Mode C"},
    CurrentOption = "Mode A",
    Flag = "Mode",
    Callback = function(opt)
        print("Mode:", opt)
    end
})

-- Optional ready-made Settings tab (theme switcher, reduce-motion, Save/Reload/Reset)
Window:CreateSettingsTab()
```

### Window Options

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `Name` | string | `"MacUI"` | Main window header text |
| `Subtitle` | string | `""` | Secondary header text |
| `Theme` | string | `"Liquid Glass Dark"` | Preset palette (see Themes) |
| `Boot` | boolean | `true` | Startup sequence; window stays hidden until finished |
| `Dock` | boolean | `true` | Dock-style navigation bar with metaball indicators |
| `Acrylic` | boolean | `true` | 3-layer liquid glass background |
| `Size` | UDim2 | `760×500` | Initial UI bounds |
| `MinSize` | Vector2 | `480×320` | Reserved for future resize clamping |
| `ConfigurationSaving` | table | `{ Enabled = false }` | `{ Enabled, Folder, File }` — see Config |

### Themes

Built-in: `"Liquid Glass Dark"` (alias `Dark`), `"Liquid Glass Light"` (alias `Light`), `"Graphite"`, `"Midnight"`, `"Blue"`, `"Purple"`, `"Nord"`, `"Solarized"`, `"Rose Pine"`, `"Forest"`, `"Classic Aqua"`.

```lua
MacUI:SetTheme("Nord")
```

### Available Controls

Every control renders as a **3-layer liquid-glass card** (base + frost + specular sheen + rim).  
`Flag` is optional on stateful controls — set it to persist/restore values through the config system (falls back to `Name` if omitted).

```lua
-- Toggle
local Toggle = Section:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "Enable",
    Callback = function(val) end
})
Toggle:Set(true)

-- Slider
local Slider = Section:CreateSlider({
    Name = "Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "Speed",
    Callback = function(val) end
})
Slider:Set(50)

-- Dropdown (fixed in v2.1 — overlay list, outside-click close, smooth animation)
local Dropdown = Section:CreateDropdown({
    Name = "Select Mode",
    Options = {"Mode A", "Mode B"},
    CurrentOption = "Mode A",
    Flag = "Mode",
    Callback = function(opt) end
})

-- Input
local Input = Section:CreateInput({
    Name = "Target User",
    PlaceholderText = "Username...",
    Flag = "TargetUser",
    Callback = function(text) end
})

-- Keybind
Section:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = Enum.KeyCode.RightShift,
    Flag = "ToggleKey",
    Callback = function() Window:Toggle() end
})

-- Color Picker — click the swatch for a real draggable hue + saturation/value board
local ColorPicker = Section:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color) end
})

-- Segmented Control
Section:CreateSegmentedControl({
    Options = {"Day", "Night"},
    Default = "Day",
    Callback = function(choice) end
})

-- Paragraph (also glass)
Section:CreateParagraph({
    Title = "Info",
    Content = "Longer description that wraps."
})
```

### 3-Layer Liquid Glass

Every glass surface is built from three stacked layers:

| Layer | Purpose |
| :--- | :--- |
| **1 – Base** | Tinted translucent fill + outer soft-white stroke |
| **2 – Frost** | Diffusion overlay with vertical depth gradient |
| **3 – Specular** | Top sheen gradient + soft inner rim light |

Optional soft drop shadow sits behind the stack.  
You can still opt out of the decorative layers (needed for `AutomaticSize` content) with:

```lua
CreateGlassFrame(parent, { Radius = 10, Layers = false })
```

Optional organic edge glow (metaball soft bloom):

```lua
CreateGlassFrame(parent, { Radius = 12, Metaball = true })
```

### Metaball Dock Indicators

The active tab indicator under the dock is no longer a single hard dot.  
It is three overlapping soft blobs that fade in with a short stagger, giving an organic “liquid” under-dot that matches the glass aesthetic.

### Animation Utilities

These are the same tweening helpers the library uses internally:

```lua
MacUI.Tween(instance, { Time = 0.3, EasingStyle = Enum.EasingStyle.Quint }, { Size = newSize })
MacUI.Bounce(instance, height, duration)       -- classic dock jump
MacUI.PulseScale(instance, scale, duration)    -- grow-then-settle pop
MacUI.PressSquish(instance, scale, duration)   -- quick down-scale click feedback
MacUI.Shake(instance, distance, duration)      -- horizontal error shake
MacUI.PopIn(instance, delaySeconds)            -- staggered fade/scale entrance

-- Accessibility
MacUI:SetAccessibility({ ReducedMotion = true })
```

### Config System (Executors)

```lua
-- Pass ConfigurationSaving into CreateWindow (auto-creates + auto-loads on open), or:
MacUI:CreateConfig({ Folder = "MyScriptHub", File = "settings" })
MacUI:SaveConfig()    -- creates the folder if needed, then writes every Flag value
MacUI:LoadConfig()    -- reads the saved file into MacUI.Config.Data

-- Re-apply loaded values onto existing controls:
Window:ApplyConfig()
-- or
Window:LoadConfig()   -- MacUI:LoadConfig() + Window:ApplyConfig()
```

Any control created with a `Flag` (or just `Name`) restores its saved value automatically the moment it is created when config is enabled.  
`Window:CreateSettingsTab()` adds Save / Reload / Reset buttons for free.

---

## 🪟 WinUI (v2.0.0)

Windows 10 Fluent UI with a bottom taskbar (Lucide icons), Windows-style boot loading animation, richer tweens, and built-in config saving.

### Basic Setup

```lua
local Window = WinUI:CreateWindow({
    Name = "Windows 10 Hub",
    LoadingTitle = "WinUI",
    LoadingSubtitle = "Starting...",
    Theme = "Windows10Dark",
    ShowBoot = true,
    BootDuration = 1.8,
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "WinUI_Configs",
        FileName = "default"
    }
})

local Tab = Window:CreateTab("General", "home")

Tab:CreateSection("Player Tweaks")

Tab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(val)
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = val
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(state)
        print("Auto Farm:", state)
    end
})

Tab:CreateButton({
    Name = "Teleport to Spawn",
    Description = "Sends your character back to spawn",
    Callback = function()
        WinUI:Notify({
            Title = "Teleported",
            Content = "Successfully moved to spawn.",
            Icon = "home",
            Duration = 3
        })
    end
})

Tab:CreateKeybind({
    Name = "Hide UI",
    CurrentKeybind = Enum.KeyCode.RightControl,
    Callback = function()
        Window:Toggle()
    end
})
```

### Window Options

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `Name` | string | `"WinUI"` | Title bar text |
| `LoadingTitle` | string | Name | Boot screen title |
| `LoadingSubtitle` | string | `"Windows 10 UI…"` | Boot screen subtitle |
| `Theme` | string | `"Windows10"` | Preset palette |
| `ShowBoot` | boolean | `true` | Windows 10 orbiting-dots boot |
| `BootDuration` | number | `1.8` | Boot screen duration (seconds) |
| `ToggleKey` | KeyCode | `RightControl` | Key to show/hide the window |
| `ConfigurationSaving` | table | `{ Enabled = false }` | See config section |

### Creating Tabs

```lua
local Tab = Window:CreateTab("Combat", "sword")
local Tab2 = Window:CreateTab("Visuals", "eye")
local Tab3 = Window:CreateTab("Settings", "settings")
```

> **Built-in Lucide keys:** `home`, `settings`, `player` / `user`, `visual` / `eye`, `combat` / `sword`, `misc` / `box`, `about` / `info`, `search`, `close` / `x`, `minimize`, `maximize`, `menu`, `cog`, `users`, `swords`, and more.

### Available Controls

> All controls live on the tab (not on sections). Sections are visual headers only.

```lua
Tab:CreateSection("Main")
Tab:CreateLabel({ Text = "Some helper text" })
Tab:CreateParagraph({ Title = "Info", Content = "Longer description that wraps." })

Tab:CreateButton({
    Name = "Click me",
    Description = "Optional subtitle",
    Callback = function() end
})

local Toggle = Tab:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "EnableFlag",
    Callback = function(val) end
})
Toggle:Set(true)

local Slider = Tab:CreateSlider({
    Name = "Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedFlag",
    Callback = function(val) end
})
Slider:Set(50)

Tab:CreateDropdown({
    Name = "Select Mode",
    Options = {"Mode A", "Mode B"},
    CurrentOption = "Mode A",
    Flag = "ModeFlag",
    Callback = function(opt) end
})

Tab:CreateInput({
    Name = "Target User",
    PlaceholderText = "Username...",
    Flag = "UserFlag",
    Callback = function(text) end
})

Tab:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = Enum.KeyCode.RightShift,
    Callback = function(key) end
})

Tab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(0, 120, 215),
    Callback = function(color) end
})
```

### Themes

```lua
WinUI:GetThemes()
-- "Blue", "DarkBlue", "FluentDark", "Gray", "Green", "Orange",
-- "Purple", "Windows10", "Windows10Dark", "Windows10Light"

WinUI:SetTheme("Windows10Dark")
WinUI:SetAccentColor(Color3.fromRGB(0, 153, 255))
```

### Notifications

```lua
WinUI:Notify({
    Title = "Success",
    Content = "Settings saved.",
    Icon = "settings",
    Duration = 4
})
```

### Config Saving (Executors)

```lua
WinUI:SaveConfiguration()
WinUI:LoadConfiguration()
```

Flags on Toggle / Slider / Dropdown / Input are stored under `window.ConfigValues` when `ConfigurationSaving.Enabled = true`.

---

## 🎨 Custom Themes & Configs

### Creating Custom Themes (MacUI)

```lua
MacUI:RegisterTheme("Dracula", {
    Background = Color3.fromRGB(40, 42, 54),
    SecondaryBackground = Color3.fromRGB(68, 71, 90),
    TertiaryBackground = Color3.fromRGB(98, 114, 164),
    Text = Color3.fromRGB(248, 248, 242),
    SecondaryText = Color3.fromRGB(189, 147, 249),
    Accent = Color3.fromRGB(255, 121, 198),
    Border = Color3.fromRGB(98, 114, 164),
    Glass = Color3.fromRGB(40, 42, 54),
    Success = Color3.fromRGB(80, 250, 123),
    Warning = Color3.fromRGB(255, 184, 108),
    Danger = Color3.fromRGB(255, 85, 85),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(40, 42, 54)
})

MacUI:SetTheme("Dracula")
```

> Built-in MacUI themes: `Liquid Glass Dark` / `Dark`, `Liquid Glass Light` / `Light`, `Graphite`, `Midnight`, `Blue`, `Purple`, `Nord`, `Solarized`, `Rose Pine`, `Forest`, `Classic Aqua`.

### Save System (Executors)

See **Config System (Executors)** under the MacUI section for the full picture (`ConfigurationSaving`, `Flag`, `Window:CreateSettingsTab()`). Minimal version:

```lua
MacUI:CreateConfig({ Folder = "MyScriptHub", File = "settings" })
MacUI:SaveConfig()
MacUI:LoadConfig()
```

---

## 📜 License

MIT License. Free to use, modify, and distribute for any Roblox client project.
