## WinUI Lib
# Load Libary
---
```lua
local WinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"))()
```
---
---
```lua
local WinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"))()
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
