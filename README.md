## WinUI Lib + MacUI Lib
# Load Libary
---
```lua
local WinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"))()
```
---
```lua
local MacUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"))()
```
---
# Window
```lua
local Window = WinUI:CreateWindow({
    Name = "Windows 10",
    LoadingTitle = "WinUI",
    LoadingSubtitle = "Windows 10 UI Library",
    Theme = "Windows10Dark",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "WinUI",
        FileName = "Config"
    }
})
```
---
```lua
MacUI:CreateConfig({Folder = "MacUI", File = "DemoConfig"})
MacUI:LoadConfig()

local Window = MacUI:CreateWindow({
    Name = "MacUI",
    Subtitle = "Demo Application",
    Theme = "Dark",
    Acrylic = true,
    Size = UDim2.new(0, 760, 0, 520)
})

Window:CreateSearch()
```
---

# Button
---
```lua
Tab:CreateButton({
    Name = "Button",
    Description = "Example",
    Callback = function()
    end
})
```
---
# Toggle
---
```lua
Tab:CreateToggle({
    Name = "Enable Feature",
    CurrentValue = false,

    Callback = function(Value)
        print(Value)
    end
})
```
----
# Slider
---
```lua
Tab:CreateSlider({
    Name = "WalkSpeed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,

    Callback = function(Value)
        print(Value)
    end
})
```
---
# Dropdown
---
```lua
Tab:CreateDropdown({
    Name = "Select Player",
    Options = {"Player1", "Player2"},
    CurrentOption = "Player1",

    Callback = function(Value)
        print(Value)
    end
})
```
---
# Input
---
```lua
Tab:CreateInput({
    Name = "Username",
    PlaceholderText = "Enter username...",

    Callback = function(Text)
        print(Text)
    end
})
```
---
# Label
---
```lua
Tab:CreateLabel({
    Text = "Welcome to WinUI"
})
```
---
# Paragraph
---
```lua
Tab:CreateParagraph({
    Title = "Information",
    Content = "Windows 10 inspired Roblox interface."
})
```
---
# Section
---
```lua
Tab:CreateSection("Settings")
```
---
# Keybind
---
```lua
Tab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = Enum.KeyCode.RightControl,

    Callback = function()
        Window:Toggle()
    end
})
```
---
# Color Picker
---
```lua
Tab:CreateColorPicker({
    Name = "Accent Color",
    Color = Color3.fromRGB(0, 120, 215),

    Callback = function(Color)
        print(Color)
    end
})
```


MacUI v2.0.0

A modern macOS-inspired Roblox UI library.

Liquid Glass · Dock · Boot Sequence · Lucide Icons · Rich Animations



Features







Feature



Description





Liquid Glass



Multi-layer frosted glass (base + frost + sheen + shadow)





Boot Sequence



Apple logo + progress bar, then window open





Dock



Bottom macOS-style dock with Lucide icons





Jump Animation



Classic dock bounce on tab select





Maximize



Raises DisplayOrder to 99999 + smooth slide





Themes



Dark, Light, Graphite, Midnight, Blue, Purple





Controls



Button, Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Segmented, Label, Paragraph





Notifications



Glass toast notifications with slide-in





Config



Optional writefile / readfile save system





Accessibility



Reduced motion support



Installation





Place MacUI.luau in your project (e.g. ReplicatedStorage or a ModuleScript).



Require it from a LocalScript:

local MacUI = require(path.to.MacUI)

Works in both Studio and common executor environments (uses CoreGui when available, otherwise PlayerGui).



Quick Start

local MacUI = require(path.to.MacUI)

local Window = MacUI:CreateWindow({
    Name = "My App",
    Subtitle = "v2.0",
    Theme = "Dark",      -- Dark | Light | Graphite | Midnight | Blue | Purple
    Boot = true,         -- Apple logo boot sequence (default: true)
    Dock = true,         -- Bottom dock for tabs (default: true)
    Acrylic = true,      -- Liquid glass transparency
    Size = UDim2.new(0, 760, 0, 500)
})

local Home = Window:CreateTab({
    Name = "Home",
    Icon = "home"        -- Lucide icon name
})

local Section = Home:CreateSection("General")

Section:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Callback = function(value)
        print("Toggle:", value)
    end
})

Section:CreateButton({
    Name = "Click Me",
    Description = "Does something cool",
    Callback = function()
        MacUI:Notify({
            Title = "Success",
            Content = "Button was pressed!",
            Icon = "check",
            Duration = 3
        })
    end
})

Section:CreateSlider({
    Name = "Volume",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(value)
        print("Volume:", value)
    end
})



Window Options







Option



Type



Default



Description





Name



string



"MacUI"



Window title





Subtitle



string



""



Shown next to title





Theme



string



"Dark"



Initial theme





Boot



boolean



true



Play Apple logo boot





Dock



boolean



true



Use bottom dock for tabs





Acrylic



boolean



true



Liquid glass look





Size



UDim2



760×500



Initial window size





MinSize



Vector2



480×320



Reserved for future use



Tabs & Dock

local Tab = Window:CreateTab({
    Name = "Settings",
    Icon = "settings"   -- see Icons section
})

When Dock = true:





Tabs appear as icons in the bottom dock



Hover → slight magnification



Click → jump bounce + accent indicator

When Dock = false, tabs are not shown in a sidebar (content only). You can still switch programmatically via the returned Tab objects.



Sections & Controls

All controls are created on a Section:

local Section = Tab:CreateSection("My Section")

Button

Section:CreateButton({
    Name = "Action",
    Description = "Optional subtitle",  -- makes the button taller
    Callback = function() end
})

Toggle

local Toggle = Section:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Callback = function(value) end
})
Toggle:Set(true)
print(Toggle:Get())

Slider

local Slider = Section:CreateSlider({
    Name = "Speed",
    Range = {0, 100},
    Increment = 5,
    CurrentValue = 25,
    Callback = function(value) end
})
Slider:Set(50)
print(Slider:Get())

Dropdown

Section:CreateDropdown({
    Name = "Mode",
    Options = {"Easy", "Normal", "Hard"},
    CurrentOption = "Normal",
    Callback = function(option) end
})

Input

Section:CreateInput({
    Name = "Username",
    PlaceholderText = "Enter name...",
    Callback = function(text) end   -- fires on FocusLost
})

Keybind

Section:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = Enum.KeyCode.RightShift,
    Callback = function()
        Window:Toggle()
    end
})

Color Picker

Section:CreateColorPicker({
    Name = "Accent",
    Color = Color3.fromRGB(10, 132, 255),
    Callback = function(color) end
})
-- Cycles through a small preset palette on click

Segmented Control

Section:CreateSegmentedControl({
    Options = {"Day", "Week", "Month"},
    Default = "Week",
    Callback = function(selected) end
})

Label & Paragraph

Section:CreateLabel({ Name = "Status: Ready" })

Section:CreateParagraph({
    Title = "About",
    Content = "This is a longer description that wraps."
})



Notifications

MacUI:Notify({
    Title = "MacUI",
    Content = "Something happened",
    Icon = "info",      -- or "check", "home", etc.
    Duration = 4
})



Themes

MacUI:SetTheme("Midnight")

-- Or register your own
MacUI:RegisterTheme("Custom", {
    Background = Color3.fromRGB(20, 20, 25),
    SecondaryBackground = Color3.fromRGB(30, 30, 35),
    TertiaryBackground = Color3.fromRGB(40, 40, 45),
    Text = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(160, 160, 170),
    Accent = Color3.fromRGB(100, 180, 255),
    Border = Color3.fromRGB(60, 60, 70),
    Glass = Color3.fromRGB(35, 35, 40),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(25, 25, 30)
})

Built-in themes: Dark, Light, Graphite, Midnight, Blue, Purple.



Liquid Glass Style

MacUI:SetGlassStyle({
    Transparency = 0.22,
    Border = true,
    Shadow = true,
    Layers = true,          -- frost + sheen
    Tint = Color3.fromRGB(30, 30, 35)
})



Icons (Lucide)

Use short names with GetIcon / tab Icon:







Name



Use





apple



Boot logo





home / house



Home





settings



Settings





search



Search





user / person



Profile





info



Info





check



Success





close / x



Close





bell



Notifications





lock / unlock



Security





file / folder



Files





download / upload



Transfer

local id = MacUI.GetIcon("settings")
MacUI.AddIcon("custom", "rbxassetid://123456789")

Icons are white-line Lucide assets and tint cleanly with ImageColor3.



Boot Sequence (standalone)

MacUI:PlayBootSequence({
    Duration = 2.8,
    OnComplete = function()
        print("Boot finished")
    end
})



Window Methods







Method



Description





Window:Maximize()



Toggle fullscreen-ish (DisplayOrder 99999 + slide)





Window:Minimize()



Shrink to title bar in corner





Window:Toggle()



Show / hide





Window:Destroy()



Animated close + cleanup





Window:CreateTab(opts)



Add a tab (and dock icon)





Window:CreateSearch()



Enable top-right search overlay





Window:ApplyTheme(theme)



Re-apply colors



Config System

MacUI:CreateConfig({ Folder = "MacUI", File = "Config" })
MacUI:LoadConfig()
-- Values are written into MacUI.Config.Data by toggles/sliders/etc.
MacUI:SaveConfig()
MacUI:ResetConfig()

Uses writefile / readfile / isfile when available (common in executors). Fails silently in pure Studio.



Accessibility

MacUI:SetAccessibility({
    ReducedMotion = true,   -- skips most tweens
    Scale = 1,
    HighContrast = false
})



Traffic Lights





Red → Close (destroy)



Yellow → Minimize



Green → Maximize (DisplayOrder 99999 + slide animation)



Notes





Designed for LocalScripts (client UI).



Z-order: Notifications 50000, Boot 100000, Maximized window 99999.



All callbacks are wrapped in pcall so one error does not break the UI.



Compatible with the v1 API surface; new options are additive.



License

Free to use and modify in your Roblox projects.
