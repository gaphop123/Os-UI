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

Gives your script a clean macOS aesthetic complete with a functional Dock, glassmorphism, boot sequence, and Lucide icon support.

### Starter Template

```lua
local Window = MacUI:CreateWindow({
    Name = "Admin Panel",
    Subtitle = "v2.0",
    Theme = "Dark", -- Dark, Light, Graphite, Midnight, Blue, Purple
    Boot = true, -- Apple boot animation on load
    Dock = true, -- Show bottom tab dock
    Acrylic = true, -- Glassmorphism effect
    Size = UDim2.new(0, 760, 0, 500)
})

local HomeTab = Window:CreateTab({
    Name = "Home",
    Icon = "home"
})

local MainSection = HomeTab:CreateSection("Main Features")

MainSection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
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
```

### Window Options

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `Name` | string | `"MacUI"` | Main window header text |
| `Subtitle` | string | `""` | Secondary header text |
| `Theme` | string | `"Dark"` | Preset palette to use |
| `Boot` | boolean | `true` | Runs startup sequence |
| `Dock` | boolean | `true` | Dock-style navigation bar |
| `Acrylic` | boolean | `true` | Background translucency |
| `Size` | UDim2 | `760x500` | Initial UI bounds |

### Available Controls & Callbacks

```lua
-- Button
Section:CreateButton({
    Name = "Click Me",
    Description = "Optional subtitle",
    Callback = function()
        -- Fires when clicked (no arguments)
    end
})

-- Toggle
local Toggle = Section:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Callback = function(state)
        -- state: boolean (true / false)
        print("Toggle state:", state)
    end
})
Toggle:Set(true)

-- Slider
local Slider = Section:CreateSlider({
    Name = "Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(val)
        -- val: number
        print("Slider value:", val)
    end
})
Slider:Set(50)

-- Dropdown
Section:CreateDropdown({
    Name = "Select Mode",
    Options = {"Mode A", "Mode B"},
    CurrentOption = "Mode A",
    Callback = function(opt)
        -- opt: string (selected option)
        print("Selected mode:", opt)
    end
})

-- Input
Section:CreateInput({
    Name = "Target User",
    PlaceholderText = "Username...",
    Callback = function(text)
        -- text: string (current input text on focus lost)
        print("Input text:", text)
    end
})

-- Keybind
Section:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = Enum.KeyCode.RightShift,
    Callback = function()
        -- Fires when the bound key is pressed
        Window:Toggle()
    end
})

-- Color Picker
Section:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        -- color: Color3
        print("Selected color:", color)
    end
})

-- Segmented Control
Section:CreateSegmentedControl({
    Options = {"Day", "Night"},
    Default = "Day",
    Callback = function(choice)
        -- choice: string
        print("Segment choice:", choice)
    end
})
```

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
    Callback = function()
        -- Fires when the assigned key is pressed
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

### Available Controls & Callbacks

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
    Callback = function()
        -- Fires when clicked (no arguments)
    end
})

-- Toggle  → returns { Set = fn, Get = fn }
local Toggle = Tab:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "EnableFlag",                 -- persisted if config is on
    Callback = function(val)
        -- val: boolean
    end
})
Toggle:Set(true)

-- Slider  → returns { Set = fn, Get = fn }
local Slider = Tab:CreateSlider({
    Name = "Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedFlag",
    Callback = function(val)
        -- val: number
    end
})
Slider:Set(50)

-- Dropdown  → returns { Set = fn, Get = fn }
Tab:CreateDropdown({
    Name = "Select Mode",
    Options = {"Mode A", "Mode B"},
    CurrentOption = "Mode A",
    Flag = "ModeFlag",
    Callback = function(opt)
        -- opt: string
    end
})

-- Input (TextBox)
Tab:CreateInput({
    Name = "Target User",
    PlaceholderText = "Username...",
    Flag = "UserFlag",
    Callback = function(text)
        -- text: string
    end
})

-- Keybind  → returns { Get = fn, Set = fn }
Tab:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = Enum.KeyCode.RightShift,
    Callback = function()
        -- Fires when the bound key is pressed
    end
})

-- Color Picker (cycles preset accents) → returns { Set = fn, Get = fn }
Tab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(0, 120, 215),
    Callback = function(color)
        -- color: Color3
    end
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

### Save System (Executors)

```lua
MacUI:CreateConfig({ Folder = "MyScriptHub", File = "settings" })
MacUI:LoadConfig()
```

---

## 📜 License

MIT License. Free to use, modify, and distribute for any Roblox client project.
