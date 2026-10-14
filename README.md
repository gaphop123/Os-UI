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

> **Changelog highlights:** the hub no longer appears (or is clickable) underneath the boot screen; dock icons actually jump/bounce on selection now; dock sizing no longer depends on fragile nested auto-sizing; liquid glass is an explicit 3-layer system (tint + diagonal depth gradient + specular sheen) applied to every control, not just buttons, with an optional 4th "metaball" layer of slow-drifting liquid blobs; every glass panel clips its own contents by default so children can't poke a square corner out past a rounded edge; dropdown lists and the color picker board render on a dedicated overlay layer instead of inside the scrollable tab content, so they're no longer cut off (corners included); the color picker opens a real draggable hue/saturation board; **switching themes now actually recolors every control already on screen**, not just the window chrome; **Minimize now really hides the hub** instead of shrinking to a stuck-open pill, notifies once with the key to bring it back, and that key is rebindable from Settings; and there's a full **Key System** (remote or static key, optional remote timer, re-entry countdown shown as a draining battery badge). See the sections below for each.

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
| `Metaballs` | boolean | `false` | Slow-drifting liquid blobs behind the window tint (see below) |
| `ToggleKey` | KeyCode | `RightControl` | Hides/shows the hub; rebindable live from `Window:CreateSettingsTab()` |

### Hiding & Theming

- **Minimize** (the dock-style yellow traffic light, `Window:Minimize()`) and **`Window.ToggleKey`** now do the same thing: hide the whole hub with an animation. The first time it hides, you get a one-time notification telling you which key brings it back - it won't repeat on later hides. `Window:Toggle()` is just an alias for `Window:Minimize()`.
- `MacUI:SetTheme(name)` / the Settings tab's theme dropdown now recolor every control already on the window, not just the title bar and dock - switching themes mid-session actually works.

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

## 🔑 Key System (MacUI)

Gates a script behind a key before the hub loads. The key can be a static string or fetched live from a site; how long a successful entry stays valid (the re-entry timer) can likewise be static or fetched from a site; and a battery-style badge in the title bar shows how much of that timer is left - it only appears when the key system is enabled.

```lua
MacUI:SetupKeySystem({
    Enabled = true,
    Key = "ABC-123",                               -- static key; ignored if GetKeySite is set
    GetKeySite = nil,                               -- e.g. "https://yoursite.com/key.txt" - plain-text response
    KeyLink = "https://discord.gg/yourserver",       -- shown as a "Copy Link" button (uses setclipboard)
    Timer = 3600,                                    -- seconds the key stays valid; 0 = never expires
    GetTimeSite = nil,                               -- e.g. "https://yoursite.com/time.txt" - plain-text seconds
    GetTimeFromSite = false,                         -- fetch the timer length from GetTimeSite instead of using Timer
    Title = "My Hub",
    Note = "Join the Discord below to get a key"
})

-- Wrap your hub in RunKeySystem instead of calling CreateWindow directly:
MacUI:RunKeySystem(function()
    local Window = MacUI:CreateWindow({ Name = "My Hub" })
    -- ... tabs, sections, controls ...
end, function(reason)
    print("Key rejected:", reason)
end)
```

`RunKeySystem(onSuccess, onFail)` is the whole flow in one call: if the key system is off, or a saved session is still inside its timer window, it calls `onSuccess()` immediately with no prompt. Otherwise it shows the key-entry modal and calls `onSuccess()` once a correct key is submitted (`onFail(reason)` fires on each rejected attempt, modal stays open). A correct entry is saved to disk (on executors that support it), so the next session skips the prompt until the timer runs out - at which point it's required again.

Lower-level pieces, if you want to build your own flow instead of `RunKeySystem`:

```lua
MacUI:VerifyKey(input)     -- bool; also (re)starts the timer on success
MacUI:GetKeyStatus()       -- { Valid, Remaining, Total } - Remaining/Total in seconds, nil if no timer
MacUI:PromptKeySystem(onSuccess, onFail)  -- just the modal, no session check first
```

---

## 📜 License

MIT License. Free to use, modify, and distribute for any Roblox client project.
