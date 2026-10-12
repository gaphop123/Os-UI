# Os-UI (WinUI & MacUI)

A collection of lightweight, feature-rich Roblox UI libraries inspired by **Windows 10** and **macOS Big Sur/Sonoma** design systems.

---

## ⚡ Quick Load

```lua
-- Windows 10 Style
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
    Theme = "Dark",      -- Dark, Light, Graphite, Midnight, Blue, Purple
    Boot = true,         -- Apple boot animation on load
    Dock = true,         -- Show bottom tab dock
    Acrylic = true,      -- Glassmorphism effect
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
| `Name` | `string` | `"MacUI"` | Main window header text |
| `Subtitle` | `string` | `""` | Secondary header text |
| `Theme` | `string` | `"Dark"` | Preset palette to use |
| `Boot` | `boolean` | `true` | Runs startup sequence |
| `Dock` | `boolean` | `true` | Dock-style navigation bar |
| `Acrylic` | `boolean` | `true` | Background translucency |
| `Size` | `UDim2` | `760x500` | Initial UI bounds |

### Available Controls

```lua
-- Toggle
local Toggle = Section:CreateToggle({ Name = "Enable", CurrentValue = false, Callback = function(val) end })
Toggle:Set(true)

-- Slider
local Slider = Section:CreateSlider({ Name = "Speed", Range = {0, 100}, Increment = 1, CurrentValue = 16, Callback = function(val) end })
Slider:Set(50)

-- Dropdown
Section:CreateDropdown({ Name = "Select Mode", Options = {"Mode A", "Mode B"}, CurrentOption = "Mode A", Callback = function(opt) end })

-- Input
Section:CreateInput({ Name = "Target User", PlaceholderText = "Username...", Callback = function(text) end })

-- Keybind
Section:CreateKeybind({ Name = "Toggle UI Key", CurrentKeybind = Enum.KeyCode.RightShift, Callback = function() Window:Toggle() end })

-- Color Picker
Section:CreateColorPicker({ Name = "ESP Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(color) end })

-- Segmented Control
Section:CreateSegmentedControl({ Options = {"Day", "Night"}, Default = "Day", Callback = function(choice) end })
```

---

## 🪟 WinUI (v1.0)

A traditional Windows 10 Fluent UI structure with embedded sidebar tabs and built-in config saving.

### Basic Setup

```lua
local Window = WinUI:CreateWindow({
    Name = "Windows 10 Hub",
    LoadingTitle = "WinUI",
    LoadingSubtitle = "Loading assets...",
    Theme = "Windows10Dark",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "WinUI_Configs",
        FileName = "default"
    }
})

local Tab = Window:CreateTab("General")
Tab:CreateSection("Player Tweaks")

Tab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(val)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
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
