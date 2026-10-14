# Os-UI (WinUI & MacUI)

A collection of lightweight, feature-rich Roblox UI libraries inspired by Windows 10 and macOS Big Sur/Sonoma design systems.

---

## ⚡ Quick Load

```lua
-- Windows 10 Style (v2.0.0)
local WinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"))()

-- macOS Style
local MacUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"))()
```

---

## 🍎 MacUI (v2.0.0)

Gives your script a clean macOS aesthetic complete with a functional Dock, glassmorphism on every control (not just the window), boot sequence, Lucide icon support, an executor-ready config system, and a drop-in Settings tab.

> **Changelog highlights:** the hub no longer appears (or is clickable) underneath the boot screen - it stays hidden until boot finishes; dock icons actually jump/bounce on selection now (they previously animated a property the dock's layout silently overrode); dock sizing no longer depends on fragile nested auto-sizing; liquid glass (translucent fill + frost + sheen + border) now applies to every control, not just buttons; and the color picker opens a real draggable hue/saturation board instead of cycling a 5-color palette.

### Starter Template

```lua
local Window = MacUI:CreateWindow({
    Name = "Admin Panel",
    Subtitle = "v2.0",
    Theme = "Liquid Glass Dark", -- see Themes below
    Boot = true, -- Apple boot animation on load (hub stays hidden until it finishes)
    Dock = true, -- Show bottom tab dock
    Acrylic = true, -- Glassmorphism effect
    Size = UDim2.new(0, 760, 0, 500),
    MinSize = Vector2.new(480, 320),
    ConfigurationSaving = {              -- optional, executor-only (see Config section)
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
    Flag = "AutoFarm",                   -- persisted + auto-restored if config is on
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

-- Optional: a ready-made Settings tab (theme switcher, reduce-motion toggle,
-- Save/Reload/Reset Config buttons when ConfigurationSaving is enabled)
Window:CreateSettingsTab()
```

### Window Options

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `Name` | string | `"MacUI"` | Main window header text |
| `Subtitle` | string | `""` | Secondary header text |
| `Theme` | string | `"Liquid Glass Dark"` | Preset palette to use (see Themes below) |
| `Boot` | boolean | `true` | Runs startup sequence; the window is hidden until it finishes |
| `Dock` | boolean | `true` | Dock-style navigation bar |
| `Acrylic` | boolean | `true` | Background translucency |
| `Size` | UDim2 | `760x500` | Initial UI bounds |
| `MinSize` | Vector2 | `480x320` | Reserved for future resize-clamping |
| `ConfigurationSaving` | table | `{ Enabled = false }` | `{ Enabled, Folder, File }` - see Config section |

### Themes

Built in: `"Liquid Glass Dark"` (alias `Dark`), `"Liquid Glass Light"` (alias `Light`), `"Graphite"`, `"Midnight"`, `"Blue"`, `"Purple"`, `"Nord"`, `"Solarized"`, `"Rose Pine"`, `"Forest"`, `"Classic Aqua"`.

```lua
MacUI:SetTheme("Nord")
```

### Available Controls

Every control below renders as a liquid-glass card (translucent fill, frost, sheen, border). `Flag` is optional on the controls that hold state - set it to persist/restore that control's value through the config system (falls back to `Name` if omitted).

```lua
-- Toggle
local Toggle = Section:CreateToggle({ Name = "Enable", CurrentValue = false, Flag = "Enable", Callback = function(val) end })
Toggle:Set(true)

-- Slider
local Slider = Section:CreateSlider({ Name = "Speed", Range = {0, 100}, Increment = 1, CurrentValue = 16, Flag = "Speed", Callback = function(val) end })
Slider:Set(50)

-- Dropdown
local Dropdown = Section:CreateDropdown({ Name = "Select Mode", Options = {"Mode A", "Mode B"}, CurrentOption = "Mode A", Flag = "Mode", Callback = function(opt) end })

-- Input
local Input = Section:CreateInput({ Name = "Target User", PlaceholderText = "Username...", Flag = "TargetUser", Callback = function(text) end })

-- Keybind
Section:CreateKeybind({ Name = "Toggle UI Key", CurrentKeybind = Enum.KeyCode.RightShift, Flag = "ToggleKey", Callback = function() Window:Toggle() end })

-- Color Picker: click the swatch to open a draggable hue + saturation/value board
local ColorPicker = Section:CreateColorPicker({ Name = "ESP Color", Color = Color3.fromRGB(255, 0, 0), Flag = "ESPColor", Callback = function(color) end })

-- Segmented Control
Section:CreateSegmentedControl({ Options = {"Day", "Night"}, Default = "Day", Callback = function(choice) end })

-- Paragraph (also glass now)
Section:CreateParagraph({ Title = "Info", Content = "Longer description that wraps." })
```

### Animation Utilities

These are the same tweening helpers the library itself uses internally - handy if you're building custom elements:

```lua
MacUI.Tween(instance, { Time = 0.3, EasingStyle = Enum.EasingStyle.Quint }, { Size = newSize })
MacUI.Bounce(instance, height, duration)       -- classic dock "jump"
MacUI.PulseScale(instance, scale, duration)    -- grow-then-settle pop
MacUI.PressSquish(instance, scale, duration)   -- quick down-scale click feedback
MacUI.Shake(instance, distance, duration)      -- horizontal error shake
MacUI.PopIn(instance, delaySeconds)            -- staggered fade/scale entrance

-- Turn all of the above off (accessibility)
MacUI:SetAccessibility({ ReducedMotion = true })
```

### Config System (Executors)

```lua
-- Either pass ConfigurationSaving into CreateWindow (auto-creates + auto-loads on open), or:
MacUI:CreateConfig({ Folder = "MyScriptHub", File = "settings" })
MacUI:SaveConfig()    -- creates the folder if needed, then writes every Flag value
MacUI:LoadConfig()    -- reads the saved file into MacUI.Config.Data

-- Re-apply loaded values onto controls that already exist (handled automatically for
-- controls created after a load; use this if you load mid-session):
Window:ApplyConfig()
-- or, equivalently:
Window:LoadConfig()   -- MacUI:LoadConfig() + Window:ApplyConfig() in one call
```

Any control created with a `Flag` (or just `Name`, as a fallback) restores its saved value automatically the moment it's created - no extra wiring needed as long as `ConfigurationSaving.Enabled` is set (or you called `MacUI:LoadConfig()` before creating the tab). `Window:CreateSettingsTab()` adds Save/Reload/Reset buttons for free when config is enabled.

---

## 🪟 WinUI (v2.0.0)

Windows 10 Fluent UI with a bottom taskbar (Lucide icons), Windows-style boot loading animation, richer tweens, and built-in config saving.

### Basic Setup

```lua
local Window = WinUI:CreateWindow({
    Name = "Windows 10 Hub",
    LoadingTitle = "WinUI",
    LoadingSubtitle = "Starting...",
    Theme = "Windows10Dark",      -- see themes below
    ShowBoot = true,              -- Windows 10 boot spinner
    BootDuration = 1.8,           -- seconds
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "WinUI_Configs",
        FileName = "default"
    }
})

-- Tabs appear as Lucide icons on the bottom taskbar
local Tab = Window:CreateTab("General", "home")   -- name, icon key (or rbxassetid)

Tab:CreateSection("Player Tweaks")

Tab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",           -- used by config saving
    Callback = function(val)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
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
    Callback = function(key)
        -- fires when a new key is bound; use Window:Toggle() for hide
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
| `ShowBoot` | boolean | `true` | Windows 10 orbiting-dots boot animation |
| `BootDuration` | number | `1.8` | How long the boot screen stays (seconds) |
| `ToggleKey` | KeyCode | `RightControl` | Key to show/hide the window |
| `ConfigurationSaving` | table | `{ Enabled = false }` | See config section |

### Creating Tabs

```lua
-- Icon can be a Lucide key or a full rbxassetid:// URL
local Tab = Window:CreateTab("Combat", "sword")
local Tab2 = Window:CreateTab("Visuals", "eye")
local Tab3 = Window:CreateTab("Settings", "settings")
```

> **Built-in Lucide keys:** `home`, `settings`, `player` / `user`, `visual` / `eye`, `combat` / `sword`, `misc` / `box`, `about` / `info`, `search`, `close` / `x`, `minimize`, `maximize`, `menu`, `cog`, `users`, `swords`, and more.

### Available Controls

> **Note:** All controls live on the tab (not on sections). Sections are visual headers only.

```lua
-- Section (header + accent underline)
Tab:CreateSection("Main")

-- Label
Tab:CreateLabel({ Text = "Some helper text" })

-- Paragraph card
Tab:CreateParagraph({
    Title = "Info",
    Content = "Longer description that wraps."
})

-- Button
Tab:CreateButton({
    Name = "Click me",
    Description = "Optional subtitle",   -- makes the button taller
    Callback = function() end
})

-- Toggle  → returns { Set = fn, Get = fn }
local Toggle = Tab:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "EnableFlag",                 -- persisted if config is on
    Callback = function(val) end
})
Toggle:Set(true)

-- Slider  → returns { Set = fn, Get = fn }
local Slider = Tab:CreateSlider({
    Name = "Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedFlag",
    Callback = function(val) end
})
Slider:Set(50)

-- Dropdown  → returns { Set = fn, Get = fn }
Tab:CreateDropdown({
    Name = "Select Mode",
    Options = {"Mode A", "Mode B"},
    CurrentOption = "Mode A",
    Flag = "ModeFlag",
    Callback = function(opt) end
})

-- Input (TextBox)
Tab:CreateInput({
    Name = "Target User",
    PlaceholderText = "Username...",
    Flag = "UserFlag",
    Callback = function(text) end
})

-- Keybind  → returns { Get = fn, Set = fn }
Tab:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = Enum.KeyCode.RightShift,
    Callback = function(key) end          -- called when a new key is chosen
})

-- Color Picker (cycles preset accents) → returns { Set = fn, Get = fn }
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
    Icon = "settings",   -- optional Lucide key
    Duration = 4
})
```

### Config Saving (Executors)

```lua
-- Enabled via CreateWindow options (see above)
WinUI:SaveConfiguration()   -- write all Flag values to JSON
WinUI:LoadConfiguration()   -- restore Flag values (called automatically when available)
```

> Flags on Toggle / Slider / Dropdown / Input are stored under `window.ConfigValues` and written when `ConfigurationSaving.Enabled = true`.

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

See **Config System (Executors)** under the MacUI section above for the full picture (including `ConfigurationSaving`, `Flag`, and `Window:CreateSettingsTab()`). Minimal version:

```lua
MacUI:CreateConfig({ Folder = "MyScriptHub", File = "settings" })
MacUI:SaveConfig()  -- creates the folder automatically if it doesn't exist
MacUI:LoadConfig()
```

---

## 📜 License

MIT License. Free to use, modify, and distribute for any Roblox client project.
