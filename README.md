# Os-UI (WinUI & MacUI)

A collection of lightweight, feature-rich Roblox UI libraries inspired by Windows 10 and macOS design systems.

---

## ⚡ Quick Load

```lua
-- Windows 10 Style (v2.0.0)
local WinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"))()

-- macOS Style (v2.3.0) — Golden Gate UI + Liquid Glass + SFX + Theme Images
local MacUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"))()
```

---

## 🍎 MacUI (v2.3.0)

Gives your script a clean macOS aesthetic complete with a functional Dock, **3-layer liquid glass** on every control, optional **metaballs**, optional **PixelJSON theme background images** (with code-set transparency), boot sequence, Lucide icon support, an executor-ready config system, a drop-in Settings tab, a full **Key System**, **macOS-style battery indicator**, and rich **UI sound effects**.

### Changelog (v2.3.0)

- **More SFX wired in**:
  - `Tab` — dock tab switch (alongside the existing dock bounce)
  - `Slider` — soft tick while dragging (pitch follows value)
  - `Type` / `Focus` — text input focus + character typing ticks
  - `Dropdown` — open list + select option
  - `Segment` — segmented control selection
  - `Restore` — window un-minimize / un-maximize (distinct from Minimize / Maximize)
- **Theme image transparency from code**: set `Transparency` or `ImageTransparency` (0–1) in `Image.Options` or via `MacUI:SetThemeImage(name, url, { Transparency = 0.4 })` so the pixel art fades and glass/tint shows through
- **Callback reference** expanded below (silent `Set`, `OnChange` on keybinds, KeySystem `onFail` reasons)

### Changelog (v2.2.0)

- **More SFX**: `Minimize`, `Maximize`, `Drag`, `Switch`, `Copy`, `Deny` — wired into window chrome (min/max are now distinct from close), window dragging, theme switching, and clipboard-copy feedback
- **Key System modal upgrades**:
  - 0.5s cooldown between submit attempts (button click or Enter) — spamming now just plays a quiet "Deny" tick instead of re-checking the key
  - A **close (×) button** on the modal — closing it fires `onFail("closed")` instead of leaving the script stuck waiting on a key
  - A **"Get Link" button** that appears automatically whenever `KeySystem.GetKeySite` is set, alongside the existing `KeyLink` "Copy Link" button (both show side-by-side if you set both)
- **Theme background images**: themes can set `Image = { URL = "...", Options = {...} }` to render a pixel-art background via [PixelJSON-Pro](https://github.com/gaphop123/PixelJSON-Pro), loaded only when a theme actually sets `Image.URL` — every built-in theme still has no image and behaves exactly as before
- New `MacUI:SetThemeImage(themeName, url, options)` helper to set/clear a theme's image without hand-editing the theme table

### Changelog (v2.1.0)

- **Golden Gate UI** — new default theme (warm SF fog + bridge gold)
- **7 new themes**: Golden Gate, Crimson, Ocean, Lavender, Monochrome, Sunset, Arctic
- **macOS battery indicator** — percentage + outline body + tip nub + color stages (green → orange → red)
- **Shared key sessions** — changing hub Name / KeySystem.Title / Note does **not** invalidate a valid session; retyping the same key only refreshes the timer
- **SFX system** — click, hover, toggle, success, error, notify, boot, dock, open/close sounds
- SFX Volume slider in Settings; `MacUI:SetSFXVolume(0–1)` or `MacUI.SFXVolume = 0` to mute
- Sounds respect **Reduce Motion** (muted when enabled)

### Changelog highlights (v2.0.0)

- Hub stays hidden (and non-clickable) until the boot sequence finishes
- Dock icons jump / bounce on selection
- Dock sizing is reliable (no fragile nested AutomaticSize)
- **3-layer liquid glass** on every control:
  1. Base tint
  2. Diagonal frost / depth gradient
  3. Specular sheen
- Optional **4th metaball layer** – slow-drifting liquid blobs
- Glass panels clip their own contents by default (no square corners poking out)
- Dropdown lists & color-picker board render on a dedicated overlay layer (no clipping)
- Real draggable hue + saturation/value color picker
- Theme switching recolors **every** control already on screen
- Minimize truly hides the hub (with one-time notification of the toggle key)
- Toggle key is rebindable live from Settings
- Full **Key System** (static or remote key, static or remote timer, battery badge)

---

### Starter Template

```lua
local MacUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/MacUI.luau"))()

-- Optional Key System
MacUI:SetupKeySystem({
    Enabled = true,
    Key = "ABC-123",                                    -- static key (ignored if GetKeySite is set)
    GetKeySite = nil,                                   -- e.g. "https://yoursite.com/key.txt"
    KeyLink = "https://discord.gg/yourserver",          -- "Copy Link" button
    Timer = 3600,                                       -- seconds the key stays valid (0 = never expires)
    GetTimeSite = nil,                                  -- e.g. "https://yoursite.com/time.txt"
    GetTimeFromSite = false,                            -- fetch timer length from GetTimeSite
    Title = "My Hub",                                   -- can differ per hub; does not break sessions
    Note = "Join the Discord below to get a key"
})

MacUI:RunKeySystem(function()
    local Window = MacUI:CreateWindow({
        Name = "Admin Panel",
        Subtitle = "v2.2",
        Theme = "Golden Gate",      -- default; or "Liquid Glass Dark", "Nord", etc.
        Boot = true,                -- Apple boot animation
        Dock = true,                -- bottom tab dock
        Acrylic = true,             -- glassmorphism
        Metaballs = true,           -- optional liquid blobs behind the window
        Size = UDim2.new(0, 760, 0, 500),
        MinSize = Vector2.new(480, 320),
        ToggleKey = Enum.KeyCode.RightControl,
        ConfigurationSaving = {
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

    -- Ready-made Settings tab (theme switcher, reduce-motion, SFX volume, Save/Reload/Reset Config)
    Window:CreateSettingsTab()
end, function(reason)
    -- "invalid_key" (wrong key, modal stays open) or "closed" (user hit the × button)
    print("Key rejected:", reason)
end)
```

---

### Window Options

| Parameter              | Type     | Default                  | Notes |
|------------------------|----------|--------------------------|-------|
| `Name`                 | string   | `"MacUI"`                | Main window header text |
| `Subtitle`             | string   | `""`                     | Secondary header text |
| `Theme`                | string   | `"Golden Gate"`          | Preset palette (see Themes) |
| `Boot`                 | boolean  | `true`                   | Startup sequence; window stays hidden until finished |
| `Dock`                 | boolean  | `true`                   | Dock-style navigation bar |
| `Acrylic`              | boolean  | `true`                   | Background translucency |
| `Metaballs`            | boolean  | `false`                  | Slow-drifting liquid blobs behind the window tint |
| `Size`                 | UDim2    | `760×500`                | Initial UI bounds |
| `MinSize`              | Vector2  | `480×320`                | Reserved for future resize clamping |
| `ToggleKey`            | KeyCode  | `RightControl`           | Hides / shows the hub (rebindable from Settings) |
| `ConfigurationSaving`  | table    | `{ Enabled = false }`    | `{ Enabled, Folder, File }` |

---

### Hiding & Theming

- **Minimize** (yellow traffic light or `Window:Minimize()`) and **`Window.ToggleKey`** both hide the entire hub with animation.
- First hide shows a one-time notification with the key that brings it back.
- `Window:Toggle()` is an alias for `Window:Minimize()`.
- `MacUI:SetTheme(name)` / Settings tab theme dropdown recolors **every** control already on the window.

---

### Themes

Built-in:

| Name                    | Alias   | Notes |
|-------------------------|---------|-------|
| `Golden Gate`           |         | **Default** — warm SF fog + bridge gold |
| `Liquid Glass Dark`     | `Dark`  | Classic Sequoia dark glass |
| `Liquid Glass Light`    | `Light` | Classic Sequoia light glass |
| `Graphite`              |         | Neutral grey |
| `Midnight`              |         | Deep purple-black |
| `Blue`                  |         | Cool blue |
| `Purple`                |         | Vivid purple |
| `Nord`                  |         | Nord palette |
| `Solarized`             |         | Solarized dark |
| `Rose Pine`             |         | Rose Pine |
| `Forest`                |         | Green nature |
| `Classic Aqua`          |         | Classic macOS Aqua light |
| `Crimson`               |         | Deep red |
| `Ocean`                 |         | Cool teal |
| `Lavender`              |         | Soft purple |
| `Monochrome`            |         | Black / white |
| `Sunset`                |         | Orange–coral |
| `Arctic`                |         | Light icy blue |

```lua
MacUI:SetTheme("Golden Gate")
MacUI:SetTheme("Nord")
```

#### Custom Themes

```lua
MacUI:RegisterTheme("Dracula", {
    Background          = Color3.fromRGB(40, 42, 54),
    SecondaryBackground = Color3.fromRGB(68, 71, 90),
    TertiaryBackground  = Color3.fromRGB(98, 114, 164),
    Text                = Color3.fromRGB(248, 248, 242),
    SecondaryText       = Color3.fromRGB(189, 147, 249),
    Accent              = Color3.fromRGB(255, 121, 198),
    Border              = Color3.fromRGB(98, 114, 164),
    Glass               = Color3.fromRGB(40, 42, 54),
    Success             = Color3.fromRGB(80, 250, 123),
    Warning             = Color3.fromRGB(255, 184, 108),
    Danger              = Color3.fromRGB(255, 85, 85),
    Shadow              = Color3.fromRGB(0, 0, 0),
    Dock                = Color3.fromRGB(40, 42, 54),
    IconColor           = Color3.fromRGB(248, 248, 242),
    TabInactive         = Color3.fromRGB(150, 150, 160),
    Sheen               = Color3.fromRGB(255, 255, 255),
    Widget              = Color3.fromRGB(30, 32, 40)
})

MacUI:SetTheme("Dracula")
```

---

### Available Controls

Every control renders as a **3-layer liquid-glass card**.  
`Flag` is optional on stateful controls — set it to persist / restore the value through the config system (falls back to `Name` if omitted).

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

-- Dropdown
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
    Callback = function() Window:Toggle() end,
    OnChange = function(newKey) end   -- optional: fires when the binding itself changes
})

-- Color Picker (real hue + saturation/value board)
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

---

### Callback reference (v2.3.0)

All control callbacks are wrapped in `pcall` — a throw inside your function only logs a warning; it never breaks the UI.

| Control / API | Callback | Args | When it fires |
|---------------|----------|------|----------------|
| **Toggle** | `Callback` | `(boolean)` | User flips the switch, or `Set(val)` without the silent flag |
| **Slider** | `Callback` | `(number)` | Value changes while dragging / clicking the track (stepped by `Increment`) |
| **Dropdown** | `Callback` | `(string)` | User picks an option; not when `Set(opt, true)` / silent programmatic set |
| **Input** | `Callback` | `(string)` | Text box loses focus (Enter or click away) |
| **Keybind** | `Callback` | *(none)* | The bound key is pressed (not while rebinding) |
| **Keybind** | `OnChange` | `(Enum.KeyCode)` | User finishes rebinding to a new key |
| **ColorPicker** | `Callback` | `(Color3)` | Color changes while dragging the SV board or hue strip |
| **SegmentedControl** | `Callback` | `(string)` | A different segment is selected |
| **Button** | `Callback` | *(none)* | Click |
| **Key System** | `onSuccess` | *(none)* | Correct key entered (modal closes) **or** a still-valid session already exists |
| **Key System** | `onFail` | `(reason: string)` | `"invalid_key"` (modal stays open) or `"closed"` (user hit ×) |

**Silent / programmatic sets**

```lua
Toggle:Set(true)              -- fires Callback (and SFX) by default
-- Dropdown / Toggle accept a second "silent" argument where implemented:
Dropdown:Set("Mode B", true)  -- updates UI + Flag, skips Callback + SFX

-- Keybind OnChange vs Callback
Section:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = Enum.KeyCode.RightShift,
    Callback = function()
        Window:Toggle()          -- fires every time the key is pressed
    end,
    OnChange = function(newKey)
        Window.ToggleKey = newKey -- fires only when the user rebinds
    end
})
```

**Key System flow**

```lua
MacUI:RunKeySystem(
    function()                  -- onSuccess
        -- build window / tabs here
    end,
    function(reason)            -- onFail
        -- reason == "invalid_key"  → wrong key, modal still open
        -- reason == "closed"       → user dismissed with ×
        print("Key rejected:", reason)
    end
)
```

---

### Animation Utilities

The same tween helpers the library uses internally:

```lua
MacUI.Tween(instance, { Time = 0.3, EasingStyle = Enum.EasingStyle.Quint }, { Size = newSize })
MacUI.Bounce(instance, height, duration)       -- classic dock "jump"
MacUI.PulseScale(instance, scale, duration)    -- grow-then-settle pop
MacUI.PressSquish(instance, scale, duration)   -- quick down-scale click feedback
MacUI.Shake(instance, distance, duration)      -- horizontal error shake
MacUI.PopIn(instance, delaySeconds)            -- staggered fade/scale entrance

-- Accessibility
MacUI:SetAccessibility({ ReducedMotion = true })
```

---

### Sound Effects (SFX)

```lua
-- Master volume (0–1). Default 0.55. Set to 0 to mute everything.
MacUI:SetSFXVolume(0.7)
-- or
MacUI.SFXVolume = 0

-- Play a named sound manually
MacUI.PlaySound("Click")           -- name, optional pitch, optional volumeMul
MacUI.PlaySound("Success", 1.1, 0.8)

-- Built-in sound keys (v2.3.0)
-- Click, Hover, ToggleOn, ToggleOff, Success, Error,
-- Notify, Boot, Dock, Open, Close, Tab, Type, Slider,
-- Minimize, Maximize, Restore, Drag, Switch, Copy, Deny,
-- Focus, Dropdown, Segment
```

Sounds fire automatically on:
- Boot complete, notifications
- Traffic lights — **close**, **minimize**, **maximize**, and **restore** (un-min / un-max) each have distinct sounds
- Starting to drag a window by its title bar
- Dock tab selection (`Tab` + dock bounce)
- Buttons (hover + click)
- Toggles (on / off)
- **Slider** ticks while dragging (pitch follows value)
- **Dropdown** open + option select
- **Segmented control** selection
- **Input** focus + typing ticks (`Focus` / `Type`)
- Theme switching (`MacUI:SetTheme`, including from the Settings dropdown — silent on the window's initial boot theme)
- Key system: accept / reject / closing the modal / a submit blocked by the cooldown / copying a key or key-site link
- Window open

Reduce Motion mutes all SFX. Settings tab includes an **SFX Volume** slider.

---

### Config System (Executors)

```lua
-- Option A: pass into CreateWindow (auto-creates + auto-loads)
ConfigurationSaving = {
    Enabled = true,
    Folder  = "MyScriptHub",
    File    = "default"
}

-- Option B: manual
MacUI:CreateConfig({ Folder = "MyScriptHub", File = "settings" })
MacUI:SaveConfig()    -- creates the folder if needed
MacUI:LoadConfig()    -- reads into MacUI.Config.Data

-- Re-apply loaded values onto already-created controls
Window:ApplyConfig()
-- or
Window:LoadConfig()   -- LoadConfig + ApplyConfig in one call
```

Any control created with a `Flag` (or just `Name`) restores its saved value automatically the moment it is created.  
`Window:CreateSettingsTab()` adds Save / Reload / Reset buttons when config is enabled.

---

### 🔑 Key System

Gates a script behind a key before the hub loads.

| Option            | Type    | Description |
|-------------------|---------|-------------|
| `Enabled`         | boolean | Turn the whole system on/off |
| `Key`             | string  | Static expected key |
| `GetKeySite`      | string  | URL that returns the current valid key (plain text). Overrides `Key` when reachable. Also shows a **“Get Link” button** on the modal (copies this URL via `setclipboard`) |
| `KeyLink`         | string  | Shown as a “Copy Link” button (uses `setclipboard`). Shows alongside “Get Link” if both are set |
| `Timer`           | number  | Seconds the key stays valid after entry (`0` = never expires) |
| `GetTimeSite`     | string  | URL that returns the timer length in seconds (plain text) |
| `GetTimeFromSite` | boolean | Use `GetTimeSite` instead of the static `Timer` |
| `Title`           | string  | Modal title (changing this does **not** break sessions) |
| `Note`            | string  | Helper text under the title |

**Modal controls**

- **Submit** — checks the entered key. Rate-limited to one attempt every **0.5s**; spamming it (or mashing Enter) just plays a quiet “denied” tick instead of re-checking.
- **× (close)** — dismisses the modal without a key and fires `onFail("closed")`, so you can let people back out of a key-gated hub instead of being stuck.
- **Copy Link** — only shown when `KeyLink` is set.
- **Get Link** — only shown when `GetKeySite` is set. Copies the site URL itself (not the key) so the person can go fetch their key.

```lua
MacUI:SetupKeySystem({ ... })

MacUI:RunKeySystem(function()          -- onSuccess
    -- create your window / tabs here
end, function(reason)                  -- onFail (modal stays open)
    print("Rejected:", reason)
end)
```

**How it works**

1. If Key System is disabled **or** a still-valid session exists → `onSuccess` is called immediately (no prompt).
2. Otherwise the key-entry modal appears.
3. Correct key → session saved to disk → `onSuccess` fires.
4. Wrong key → `onFail("invalid_key")` fires, modal stays open so the user can retry.
5. User clicks the **×** close button → `onFail("closed")` fires and the modal tweens away. Nothing is saved, so the modal reappears next run.
6. When the timer expires the next launch requires the key again.

`onFail`'s `reason` is one of: `"invalid_key"` (wrong key, modal stays open) or `"closed"` (user dismissed the modal via ×).

**Shared sessions across hubs**

- Sessions are stored globally under `MacUI/KeySystem/session.json` by default.
- Changing the hub **Name**, **KeySystem.Title**, or **Note** has **zero effect** on a valid session.
- Retyping the **same key** in another hub simply refreshes the timer.
- Only changing the actual **Key** (or remote `GetKeySite` value) invalidates a previous session.

**macOS battery badge**

- Appears in the title bar **only when** `KeySystem.Enabled == true`.
- Looks like the real macOS menu-bar battery: percentage text + outline body + tip.
- Fill drains left → right; color stages: green → orange (≤30%) → red (≤15%).
- Drain speed is proportional to the timer length (short timer = faster drain).

Lower-level helpers (if you want a custom flow):

```lua
MacUI:VerifyKey(input)          -- bool; also (re)starts the timer on success
MacUI:GetKeyStatus()            -- { Valid, Remaining, Total }
MacUI:PromptKeySystem(onSuccess, onFail)  -- just the modal
```

---

### Liquid Glass & Metaballs

Every glass panel is built with three layers by default:

1. **Base** – tinted translucent fill  
2. **Frost** – diagonal depth / refraction gradient  
3. **Sheen** – top specular highlight  

Optional fourth layer:

```lua
-- On the main window
Metaballs = true

-- Or manually
MacUI.AddMetaballs(parentFrame, {
    Count  = 3,
    Color  = Color3.fromRGB(212, 160, 70),  -- Golden Gate accent
    Size   = {40, 80},
    Speed  = 5,
    ZIndex = 1
})
```

Soft concentric circles drift slowly and brighten where they overlap, giving a lava-lamp / liquid feel. Respects `ReducedMotion`.

---

### 🖼️ Theme Background Images

Any theme can optionally render a pixel-art background behind window content, decoded with [PixelJSON-Pro](https://github.com/gaphop123/PixelJSON-Pro). This is **fully opt-in at the theme level**: a theme with no `Image` set never makes a network request and never shows an image — it looks exactly like before. The image is only fetched/rendered when `CreateWindow` boots into a theme (or `SetTheme` switches to one) that has `Image.URL` configured.

```lua
-- Set it on a theme table directly...
MacUI.Themes["Golden Gate"].Image = {
    URL = "https://yoursite.com/background.json",  -- a PixelJSON (.json) image
    Options = {
        Scale = 2,              -- optional fixed pixel scale (disables AutoScale)
        Fit = "cover",          -- "cover" (default) or "contain"
        AutoScale = true,       -- fill the window (default on unless Scale is set)
        Transparency = 0.4,     -- 0 = opaque, 1 = invisible (also accepts ImageTransparency)
    }
}

-- ...or use the helper (also clears it when url is nil)
MacUI:SetThemeImage("Golden Gate", "https://yoursite.com/background.json", {
    Transparency = 0.45,        -- fade the art so liquid glass still reads through
    Fit = "cover",
})
MacUI:SetThemeImage("Golden Gate", nil)  -- back to no image
```

| Option | Type | Default | Notes |
|--------|------|---------|-------|
| `Transparency` / `ImageTransparency` | number 0–1 | `0` | Fades every pixel block so the theme glass/tint shows through |
| `Fit` | `"cover"` \| `"contain"` | `"cover"` | How AutoScale fits the image to the window |
| `AutoScale` | boolean | `true` | Off when you set `Scale` explicitly |
| `Scale` | number | `1` | Fixed pixel scale (opts out of AutoScale) |

If the URL fails to load or decode, MacUI logs a warning and silently falls back to the plain themed background — no image, no error shown to the player. Switching themes (via `MacUI:SetTheme` or the Settings dropdown) automatically swaps the image, or clears it if the new theme doesn't have one.

---

## 🪟 WinUI (v2.0.0)

Windows 10 Fluent UI with a bottom taskbar (Lucide icons), Windows-style boot loading animation, richer tweens, and built-in config saving.

### Basic Setup

```lua
local WinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/Os-UI/refs/heads/main/WinUI.luau"))()

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
        if hum then hum.WalkSpeed = val end
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
```

### Window Options

| Parameter             | Type    | Default              | Notes |
|-----------------------|---------|----------------------|-------|
| `Name`                | string  | `"WinUI"`            | Title bar text |
| `LoadingTitle`        | string  | Name                 | Boot screen title |
| `LoadingSubtitle`     | string  | `"Windows 10 UI…"`   | Boot screen subtitle |
| `Theme`               | string  | `"Windows10"`        | Preset palette |
| `ShowBoot`            | boolean | `true`               | Orbiting-dots boot animation |
| `BootDuration`        | number  | `1.8`                | Seconds the boot screen stays |
| `ToggleKey`           | KeyCode | `RightControl`       | Show / hide key |
| `ConfigurationSaving` | table   | `{ Enabled = false }`| See config section |

### Creating Tabs

```lua
local Tab  = Window:CreateTab("Combat", "sword")
local Tab2 = Window:CreateTab("Visuals", "eye")
local Tab3 = Window:CreateTab("Settings", "settings")
```

> **Built-in Lucide keys:** `home`, `settings`, `player` / `user`, `visual` / `eye`, `combat` / `sword`, `misc` / `box`, `about` / `info`, `search`, `close` / `x`, `minimize`, `maximize`, `menu`, `cog`, `users`, `swords`, and more.

### Available Controls

> All controls live on the tab (sections are visual headers only).

```lua
Tab:CreateSection("Main")
Tab:CreateLabel({ Text = "Some helper text" })
Tab:CreateParagraph({ Title = "Info", Content = "Longer description that wraps." })
Tab:CreateButton({ Name = "Click me", Description = "Optional subtitle", Callback = function() end })

local Toggle = Tab:CreateToggle({ Name = "Enable", CurrentValue = false, Flag = "EnableFlag", Callback = function(val) end })
Toggle:Set(true)

local Slider = Tab:CreateSlider({ Name = "Speed", Range = {0, 100}, Increment = 1, CurrentValue = 16, Flag = "SpeedFlag", Callback = function(val) end })
Slider:Set(50)

Tab:CreateDropdown({ Name = "Select Mode", Options = {"Mode A", "Mode B"}, CurrentOption = "Mode A", Flag = "ModeFlag", Callback = function(opt) end })
Tab:CreateInput({ Name = "Target User", PlaceholderText = "Username...", Flag = "UserFlag", Callback = function(text) end })
Tab:CreateKeybind({ Name = "Toggle UI Key", CurrentKeybind = Enum.KeyCode.RightShift, Callback = function(key) end })
Tab:CreateColorPicker({ Name = "ESP Color", Color = Color3.fromRGB(0, 120, 215), Callback = function(color) end })
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
WinUI:SaveConfiguration()   -- write all Flag values to JSON
WinUI:LoadConfiguration()   -- restore Flag values (auto-called when available)
```

Flags on Toggle / Slider / Dropdown / Input are stored under `window.ConfigValues` and written when `ConfigurationSaving.Enabled = true`.

---

## 📜 License

MIT License. Free to use, modify, and distribute for any Roblox client project.
