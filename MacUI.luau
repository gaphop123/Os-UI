--[[
    MacUI v2.3.0
    A modern macOS-inspired Roblox UI library
    Liquid Glass + Golden Gate UI + Dock + Boot Sequence + Lucide Icons + Rich Animations + SFX

    v2.3.0:
      - More SFX wired in: Tab, Slider, Type, Focus, Dropdown, Segment, Restore.
        Slider ticks while dragging, inputs tick on type, tabs use Tab (not only Dock),
        dropdown open/select, segmented control clicks, window restore from minimize.
      - Theme images support Transparency / ImageTransparency (0–1) from code via
        Image.Options or MacUI:SetThemeImage(..., { Transparency = 0.4 }).
        Applied to the rendered pixel container so the glass/tint still shows through.
      - Callback docs expanded in README (OnChange, silent Set, KeySystem onFail reasons).

    v2.2.0:
      - More SFX (Minimize, Maximize, Drag, Switch, Copy, Deny) wired into window
        chrome, theme switching and the key-system modal.
      - Key-system modal: 0.5s submit cooldown, a close (x) button, and a "Get Link"
        button that appears whenever KeySystem.GetKeySite is configured (alongside
        the existing KeyLink "Copy Link" button).
      - Themes can set an optional Image = { URL = "...", Options = {...} } table to
        render a PixelJSON (https://github.com/gaphop123/PixelJSON-Pro) pixel-art
        background behind window content. Only fetched/rendered when a theme sets
        Image.URL at boot/CreateWindow time - themes with no Image stay exactly as
        before (plain color/glass, no network call, no image).
]]

local MacUI = {
    Version = "2.3.0",
    Themes = {},
    CurrentTheme = "Golden Gate",
    Windows = {},
    Notifications = {},
    Config = {
        Folder = "MacUI",
        File = "Config",
        Data = {}
    },
    Accessibility = {
        ReducedMotion = false,
        Scale = 1,
        HighContrast = false
    },
    GlassStyle = {
        Transparency = 0.32,
        Border = true,
        Shadow = true,
        ShadowImage = "rbxassetid://6014261993", -- override if this decal doesn't render for you
        Tint = Color3.fromRGB(30, 30, 35),
        Layers = true
    },
    -- Global SFX master volume (0–1). Set to 0 to mute all UI sounds.
    SFXVolume = 0.55
}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")

-- Utility: Safe parent (executor vs studio)
local function GetUIParent()
    local success, result = pcall(function()
        return CoreGui
    end)
    if success and result then return result end
    return PlayerGui
end

-- Connection manager
local Connections = {}
local function TrackConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local function DisconnectAll(conns)
    if not conns then return end
    for _, c in ipairs(conns) do
        if typeof(c) == "RBXScriptConnection" and c.Connected then
            c:Disconnect()
        end
    end
    table.clear(conns)
end

-- ============================================================
-- SFX SYSTEM (macOS-style UI sounds)
-- Uses short public Roblox library assets. Volume is gated by
-- MacUI.SFXVolume and Accessibility.ReducedMotion (muted when true).
-- ============================================================
MacUI.Sounds = {
    Click      = "rbxassetid://6895079853",   -- soft click
    Hover      = "rbxassetid://9119713951",   -- subtle hover tick
    ToggleOn   = "rbxassetid://9114076550",   -- pop on
    ToggleOff  = "rbxassetid://9114076550",   -- pop off (same, pitched later)
    Success    = "rbxassetid://6026984224",   -- success chime
    Error      = "rbxassetid://9119713951",   -- error / shake
    Notify     = "rbxassetid://6895079853",   -- notification slide
    Boot       = "rbxassetid://6026984224",   -- boot complete
    Dock       = "rbxassetid://9114076550",   -- dock bounce
    Open       = "rbxassetid://6895079853",   -- window open
    Close      = "rbxassetid://9119713951",   -- window close
    Tab        = "rbxassetid://6895079853",   -- tab switch
    Type       = "rbxassetid://9119713951",   -- key type tick
    Slider     = "rbxassetid://6895079853",   -- slider tick while dragging
    Minimize   = "rbxassetid://9114076550",   -- window minimize (lower pitch)
    Maximize   = "rbxassetid://9114076550",   -- window maximize (higher pitch)
    Drag       = "rbxassetid://9119713951",   -- window drag start, very quiet
    Switch     = "rbxassetid://6895079853",   -- theme switch
    Copy       = "rbxassetid://6026984224",   -- copied to clipboard
    Deny       = "rbxassetid://9119713951",   -- blocked action / cooldown
    Focus      = "rbxassetid://9119713951",   -- textbox / control focus
    Dropdown   = "rbxassetid://6895079853",   -- dropdown open or option select
    Segment    = "rbxassetid://9114076550",   -- segmented control click
    Restore    = "rbxassetid://9114076550",   -- window restore from minimize
}

local function PlaySFX(name, pitch, volumeMul)
    if MacUI.Accessibility.ReducedMotion then return end
    local vol = (MacUI.SFXVolume or 0.55) * (volumeMul or 1)
    if vol <= 0 then return end
    local id = MacUI.Sounds[name]
    if not id then return end
    local ok, sound = pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = math.clamp(vol, 0, 1)
        s.PlaybackSpeed = pitch or 1
        s.Parent = SoundService
        s:Play()
        s.Ended:Connect(function()
            if s and s.Parent then s:Destroy() end
        end)
        task.delay(3, function()
            if s and s.Parent then s:Destroy() end
        end)
        return s
    end)
    return ok and sound or nil
end

function MacUI.PlaySound(name, pitch, volumeMul)
    return PlaySFX(name, pitch, volumeMul)
end

function MacUI:SetSFXVolume(v)
    self.SFXVolume = math.clamp(tonumber(v) or 0, 0, 1)
end

-- Spring-like tween helper
function MacUI.Tween(object, info, properties)
    if MacUI.Accessibility.ReducedMotion then
        for prop, value in pairs(properties) do
            object[prop] = value
        end
        return nil
    end
    local tweenInfo = TweenInfo.new(
        info.Time or 0.28,
        info.EasingStyle or Enum.EasingStyle.Quint,
        info.EasingDirection or Enum.EasingDirection.Out,
        info.RepeatCount or 0,
        info.Reverses or false,
        info.DelayTime or 0
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Bounce / jump animation (classic Mac dock feel)
function MacUI.Bounce(object, height, duration)
    if MacUI.Accessibility.ReducedMotion then return end
    height = height or 18
    duration = duration or 0.45
    local original = object.Position
    local up = original - UDim2.new(0, 0, 0, height)
    local t1 = MacUI.Tween(object, {Time = duration * 0.35, EasingStyle = Enum.EasingStyle.Quad, EasingDirection = Enum.EasingDirection.Out}, {
        Position = up
    })
    if t1 then
        t1.Completed:Connect(function()
            MacUI.Tween(object, {Time = duration * 0.65, EasingStyle = Enum.EasingStyle.Bounce, EasingDirection = Enum.EasingDirection.Out}, {
                Position = original
            })
        end)
    end
end

-- Scale pulse
function MacUI.PulseScale(object, scale, duration)
    if MacUI.Accessibility.ReducedMotion then return end
    scale = scale or 1.12
    duration = duration or 0.22
    local uiScale = object:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = object
    end
    MacUI.Tween(uiScale, {Time = duration * 0.4, EasingStyle = Enum.EasingStyle.Back}, {Scale = scale})
    task.delay(duration * 0.4, function()
        MacUI.Tween(uiScale, {Time = duration * 0.6, EasingStyle = Enum.EasingStyle.Quint}, {Scale = 1})
    end)
end

-- Press squish (quick down-scale on click, snaps back)
function MacUI.PressSquish(object, scale, duration)
    if MacUI.Accessibility.ReducedMotion then return end
    scale = scale or 0.9
    duration = duration or 0.18
    local uiScale = object:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = object
    end
    MacUI.Tween(uiScale, {Time = duration * 0.35, EasingStyle = Enum.EasingStyle.Quad}, {Scale = scale})
    task.delay(duration * 0.35, function()
        MacUI.Tween(uiScale, {Time = duration * 0.65, EasingStyle = Enum.EasingStyle.Elastic}, {Scale = 1})
    end)
end

-- Horizontal shake (error / invalid input feedback)
function MacUI.Shake(object, distance, duration)
    if MacUI.Accessibility.ReducedMotion then return end
    distance = distance or 6
    duration = duration or 0.35
    local original = object.Position
    local step = duration / 4
    local t1 = MacUI.Tween(object, {Time = step, EasingStyle = Enum.EasingStyle.Sine}, {
        Position = original + UDim2.new(0, distance, 0, 0)
    })
    if not t1 then return end
    t1.Completed:Connect(function()
        local t2 = MacUI.Tween(object, {Time = step, EasingStyle = Enum.EasingStyle.Sine}, {
            Position = original - UDim2.new(0, distance, 0, 0)
        })
        if t2 then
            t2.Completed:Connect(function()
                local t3 = MacUI.Tween(object, {Time = step, EasingStyle = Enum.EasingStyle.Sine}, {
                    Position = original + UDim2.new(0, distance * 0.4, 0, 0)
                })
                if t3 then
                    t3.Completed:Connect(function()
                        MacUI.Tween(object, {Time = step, EasingStyle = Enum.EasingStyle.Sine}, {
                            Position = original
                        })
                    end)
                end
            end)
        end
    end)
end

-- Fade + rise entrance, used for staggered dock icons / list items
function MacUI.PopIn(object, delayTime)
    if MacUI.Accessibility.ReducedMotion then return end
    local uiScale = object:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = object
    end
    uiScale.Scale = 0.4
    task.delay(delayTime or 0, function()
        if object and object.Parent then
            MacUI.Tween(uiScale, {Time = 0.35, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out}, {
                Scale = 1
            })
        end
    end)
end

-- ============================================================
-- METABALL-STYLE LIQUID BLOBS
-- Roblox's UI renderer has no blend-mode or shader support, so there's no way to do true
-- isosurface metaball merging (where two blobs actually fuse into one shape as they touch).
-- This fakes the *look* of it instead: a few soft, layered-circle glows drift slowly around
-- behind a glass panel's tint and brighten where they overlap, giving a lava-lamp-ish liquid
-- motion. Opt-in (pass Metaballs = true to CreateGlassFrame, or call this directly) since
-- it's extra always-running tweens per blob.
-- ============================================================
function MacUI.AddMetaballs(parent, opts)
    opts = opts or {}
    if MacUI.Accessibility.ReducedMotion then return {} end
    local count = opts.Count or 3
    local theme = MacUI.Themes[MacUI.CurrentTheme] or MacUI.Themes["Liquid Glass Dark"]
    local color = opts.Color or theme.Accent or Color3.fromRGB(10, 132, 255)
    local sizeRange = opts.Size or {40, 80}

    local holder = Instance.new("Frame")
    holder.Name = "Metaballs"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.ClipsDescendants = true
    holder.ZIndex = opts.ZIndex or 1
    holder.Parent = parent

    local blobs = {}
    for i = 1, count do
        local size = sizeRange[1] + math.random() * (sizeRange[2] - sizeRange[1])
        local blob = Instance.new("Frame")
        blob.Name = "Blob"
        blob.Size = UDim2.new(0, size, 0, size)
        blob.AnchorPoint = Vector2.new(0.5, 0.5)
        blob.Position = UDim2.new(math.random(), 0, math.random(), 0)
        blob.BackgroundTransparency = 1
        blob.ZIndex = holder.ZIndex
        blob.Parent = holder

        -- Three concentric, decreasingly-transparent circles fake a soft blurred glow
        -- (Roblox has no real blur filter to apply to a UI element).
        for ring = 1, 3 do
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1 - (ring - 1) * 0.28, 0, 1 - (ring - 1) * 0.28, 0)
            r.AnchorPoint = Vector2.new(0.5, 0.5)
            r.Position = UDim2.new(0.5, 0, 0.5, 0)
            r.BackgroundColor3 = color
            r.BackgroundTransparency = 0.94 - (ring * 0.03)
            r.BorderSizePixel = 0
            r.ZIndex = blob.ZIndex
            r.Parent = blob
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(1, 0)
            rc.Parent = r
        end

        table.insert(blobs, blob)

        local function Drift()
            if not (blob and blob.Parent) then return end
            local targetPos = UDim2.new(math.random(), 0, math.random(), 0)
            local t = MacUI.Tween(blob, {
                Time = (opts.Speed or 6) + math.random() * 3,
                EasingStyle = Enum.EasingStyle.Sine,
                EasingDirection = Enum.EasingDirection.InOut
            }, {Position = targetPos})
            if t then
                t.Completed:Connect(Drift)
            else
                Drift()
            end
        end
        task.delay(i * 0.4, Drift)
    end

    return blobs
end

-- ============================================================
-- Lucide Icons via GaphopUI spritesheet pack
-- https://raw.githubusercontent.com/gaphop123/GaphopUI/refs/heads/main/icon.lua
-- ============================================================
local LucideSprites = nil
local EmojiIcons = nil

local function LoadLucidePack()
    if LucideSprites then return true end
    local ok, pack = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/GaphopUI/refs/heads/main/icon.lua"))()
    end)
    if ok and type(pack) == "table" and pack.LucideSprites then
        LucideSprites = pack.LucideSprites
        EmojiIcons = pack.Icons
        return true
    end
    -- Offline / failed fallback: minimal single-asset icons
    LucideSprites = {}
    EmojiIcons = {}
    return false
end

-- Normalize icon name: "home", "lucide-home", "Home", "house" → key used in pack
local function NormalizeIconKey(name)
    if not name then return "home" end
    local key = string.lower(tostring(name))
    key = string.gsub(key, "^lucide%-", "")
    key = string.gsub(key, "%-", "") -- home-icon → homeicon (pack uses no hyphens mostly)
    -- common aliases
    if key == "house" then key = "home" end
    if key == "person" then key = "user" end
    if key == "cog" then key = "settings" end
    if key == "close" then key = "x" end
    return key
end

--[[
    Returns either:
      - spritesheet data: { Image = "rbxassetid://...", ImageRectSize = Vector2, ImageRectOffset = Vector2 }
      - or plain: { Image = "rbxassetid://..." }
]]
function MacUI.GetIconData(name)
    LoadLucidePack()
    local key = NormalizeIconKey(name)

    if LucideSprites and LucideSprites[key] then
        local d = LucideSprites[key]
        -- format: { assetId, {w, h}, {ox, oy} }
        return {
            Image = "rbxassetid://" .. tostring(d[1]),
            ImageRectSize = Vector2.new(d[2][1], d[2][2]),
            ImageRectOffset = Vector2.new(d[3][1], d[3][2]),
            IsSprite = true
        }
    end

    -- try without stripping hyphens (e.g. if pack has keys with hyphens - it doesn't)
    -- fallback: empty / default apple or home sprite if available
    if LucideSprites and LucideSprites.home then
        local d = LucideSprites.home
        return {
            Image = "rbxassetid://" .. tostring(d[1]),
            ImageRectSize = Vector2.new(d[2][1], d[2][2]),
            ImageRectOffset = Vector2.new(d[3][1], d[3][2]),
            IsSprite = true
        }
    end

    return { Image = "rbxassetid://0", IsSprite = false }
end

-- Backward-compatible: returns image string only
function MacUI.GetIcon(name)
    local data = MacUI.GetIconData(name)
    return data.Image
end

-- Apply full spritesheet icon onto an ImageLabel / ImageButton
function MacUI.ApplyIcon(imageObject, name)
    if not imageObject then return end
    local data = MacUI.GetIconData(name)
    imageObject.Image = data.Image
    if data.IsSprite then
        imageObject.ImageRectSize = data.ImageRectSize
        imageObject.ImageRectOffset = data.ImageRectOffset
    else
        imageObject.ImageRectSize = Vector2.new(0, 0)
        imageObject.ImageRectOffset = Vector2.new(0, 0)
    end
end

function MacUI.AddIcon(name, assetIdOrData)
    LoadLucidePack()
    local key = NormalizeIconKey(name)
    if type(assetIdOrData) == "table" then
        LucideSprites[key] = assetIdOrData
    else
        -- plain asset id string or number
        local id = tonumber(tostring(assetIdOrData):match("%d+")) or 0
        LucideSprites[key] = { id, {48, 48}, {0, 0} }
    end
end

-- ============================================================
-- Theme background image via PixelJSON Pro
-- https://github.com/gaphop123/PixelJSON-Pro
--
-- A theme can optionally carry an Image = { URL = "...", Options = {...} }
-- table, where URL points to a PixelJSON (.json) image. This is ONLY ever
-- fetched and rendered when a theme actually sets Image.URL. Themes with no
-- Image configured (the default for every built-in theme below) never touch
-- the network and never show an image — the window just keeps its plain
-- color/glass look, exactly as before.
-- ============================================================
local PixelJSONModule = nil
local function LoadPixelJSON()
    if PixelJSONModule then return PixelJSONModule end
    local ok, mod = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/gaphop123/PixelJSON-Pro/refs/heads/main/main.luau"))()
    end)
    if ok and type(mod) == "table" and mod.LoadJSONFromURL and mod.Render then
        PixelJSONModule = mod
        return PixelJSONModule
    end
    warn("[MacUI] Couldn't load PixelJSON Pro for theme image:", mod)
    return nil
end

-- Renders theme.Image.URL into `parent`, sat behind everything else (ZIndex 0) and
-- clipped to the window's rounded corners. No-ops with zero network calls and zero
-- instances created if the theme has no Image.URL set. Returns the holder Frame (or nil)
-- so callers (theme switching) can destroy it before re-applying.
function MacUI.ApplyThemeImage(theme, parent)
    if not theme or not theme.Image or not theme.Image.URL or theme.Image.URL == "" then
        return nil -- default theme: no image configured, nothing to load
    end

    local holder = Instance.new("Frame")
    holder.Name = "ThemeImage"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.ZIndex = 0
    holder.ClipsDescendants = true
    holder.Parent = parent

    task.spawn(function()
        local PixelJSON = LoadPixelJSON()
        if not PixelJSON then
            if holder and holder.Parent then holder:Destroy() end
            return
        end

        -- Fetch with game:HttpGet rather than PixelJSON.LoadJSONFromURL (which uses
        -- HttpService:RequestAsync internally) -- RequestAsync errors or is simply
        -- unavailable on most executors, whereas game:HttpGet is the same HTTP call
        -- used everywhere else in MacUI (Lucide pack, KeySystem GetKeySite/GetTimeSite).
        local getOk, body = pcall(function()
            return game:HttpGet(theme.Image.URL)
        end)
        if not (holder and holder.Parent) then return end -- window/theme changed before fetch finished
        if not getOk or type(body) ~= "string" or body == "" then
            warn("[MacUI] Theme image HTTP request failed, falling back to no image:", body)
            holder:Destroy()
            return
        end

        local data, decodeErr = PixelJSON.Decode(body, theme.Image.Options or {})
        if not (holder and holder.Parent) then return end -- window/theme changed before decode finished
        if not data then
            warn("[MacUI] Theme image failed to decode, falling back to no image:", decodeErr)
            holder:Destroy()
            return
        end

        -- AutoScale (default on) fills `holder` with the image regardless of the image's
        -- native pixel size vs the window's actual on-screen size, so a 32x32 pixel-art
        -- image and a 4K photo both end up correctly sized instead of either rendering
        -- tiny in a corner or overflowing the window. Set Options.Scale explicitly to opt
        -- out and get the old fixed-pixel-scale behavior; Options.AutoScale = false also
        -- opts out. Options.Fit controls HOW it's fit when auto-scaling: "cover" (default)
        -- fills the whole window and crops any overflow; "contain" fits the whole image
        -- inside the window, letterboxed, with nothing cropped.
        -- Options.Transparency or Options.ImageTransparency (0–1) fades the whole image
        -- so glass/tint shows through; 0 = fully opaque, 1 = invisible.
        local userOptions = theme.Image.Options or {}
        local explicitScale = userOptions.Scale ~= nil
        local autoFit = userOptions.AutoScale ~= false and not explicitScale
        local fitMode = userOptions.Fit or "cover"
        local imageTransparency = tonumber(userOptions.Transparency or userOptions.ImageTransparency) or 0
        imageTransparency = math.clamp(imageTransparency, 0, 1)

        local renderOpts = {}
        for k, v in pairs(userOptions) do
            -- Don't pass MacUI-only keys through to PixelJSON.Render
            if k ~= "Transparency" and k ~= "ImageTransparency" and k ~= "AutoScale" and k ~= "Fit" then
                renderOpts[k] = v
            end
        end
        renderOpts.Parent = holder
        renderOpts.Scale = renderOpts.Scale or 1 -- base pixel-exact render; AutoScale rescales it below
        renderOpts.BackgroundTransparency = 1
        local handle, rErr = PixelJSON.Render(data, renderOpts)
        if not handle then
            warn("[MacUI] Theme image render failed, falling back to no image:", rErr)
            return
        end

        local container = handle.Container
        if container then
            -- Fade every child frame (pixel blocks) so the image itself is translucent;
            -- the holder stays fully transparent so only the art is affected.
            if imageTransparency > 0 then
                local function ApplyPixelTransparency(root)
                    for _, desc in ipairs(root:GetDescendants()) do
                        if desc:IsA("GuiObject") and desc.BackgroundTransparency < 1 then
                            desc.BackgroundTransparency = math.clamp(
                                desc.BackgroundTransparency + (1 - desc.BackgroundTransparency) * imageTransparency,
                                0, 1
                            )
                        end
                    end
                end
                ApplyPixelTransparency(container)
                -- Late-spawned run frames (async render) pick up transparency too
                container.DescendantAdded:Connect(function(desc)
                    if desc:IsA("GuiObject") and desc.BackgroundTransparency < 1 then
                        task.defer(function()
                            if not desc.Parent then return end
                            desc.BackgroundTransparency = math.clamp(
                                desc.BackgroundTransparency + (1 - desc.BackgroundTransparency) * imageTransparency,
                                0, 1
                            )
                        end)
                    end
                end)
            end
        end

        if autoFit and container then
            container.AnchorPoint = Vector2.new(0.5, 0.5)
            container.Position = UDim2.new(0.5, 0, 0.5, 0)

            local function ApplyAutoFit()
                if not (holder and holder.Parent and container and container.Parent) then return end
                local holderSize = holder.AbsoluteSize
                local containerSize = container.AbsoluteSize
                if holderSize.X <= 0 or holderSize.Y <= 0 or containerSize.X <= 0 or containerSize.Y <= 0 then
                    return -- layout not settled yet; the next AbsoluteSize change will retry
                end
                local scaleX = holderSize.X / containerSize.X
                local scaleY = holderSize.Y / containerSize.Y
                local factor = (fitMode == "contain") and math.min(scaleX, scaleY) or math.max(scaleX, scaleY)
                local uiScale = container:FindFirstChildOfClass("UIScale")
                if not uiScale then
                    uiScale = Instance.new("UIScale")
                    uiScale.Parent = container
                end
                uiScale.Scale = factor
            end

            ApplyAutoFit()
            -- Keep filling correctly if the window is resized/restored later.
            local resizeConn
            resizeConn = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if not (holder and holder.Parent) then
                    if resizeConn then resizeConn:Disconnect() end
                    return
                end
                ApplyAutoFit()
            end)
        end
    end)

    return holder
end

-- Theme system — Liquid Glass first (matches macOS Sequoia style)
-- IconColor: tint for Lucide icons | TabInactive: dock/tab idle icon color

MacUI.Themes["Liquid Glass Dark"] = {
    Background = Color3.fromRGB(22, 22, 26),
    SecondaryBackground = Color3.fromRGB(32, 32, 38),
    TertiaryBackground = Color3.fromRGB(44, 44, 52),
    Text = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(170, 170, 180),
    Accent = Color3.fromRGB(10, 132, 255),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.78,
    Glass = Color3.fromRGB(28, 28, 34),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(30, 30, 36),
    DockTransparency = 0.28,
    IconColor = Color3.fromRGB(240, 240, 245),
    TabInactive = Color3.fromRGB(160, 160, 170),
    Sheen = Color3.fromRGB(255, 255, 255),
    Widget = Color3.fromRGB(18, 18, 22)
}

MacUI.Themes["Liquid Glass Light"] = {
    Background = Color3.fromRGB(245, 245, 250),
    SecondaryBackground = Color3.fromRGB(255, 255, 255),
    TertiaryBackground = Color3.fromRGB(230, 230, 238),
    Text = Color3.fromRGB(20, 20, 28),
    SecondaryText = Color3.fromRGB(90, 90, 100),
    Accent = Color3.fromRGB(0, 122, 255),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.35,
    Glass = Color3.fromRGB(255, 255, 255),
    GlassTransparency = 0.38,
    Success = Color3.fromRGB(52, 199, 89),
    Warning = Color3.fromRGB(255, 149, 0),
    Danger = Color3.fromRGB(255, 59, 48),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(250, 250, 255),
    DockTransparency = 0.35,
    IconColor = Color3.fromRGB(40, 40, 50),
    TabInactive = Color3.fromRGB(110, 110, 125),
    Sheen = Color3.fromRGB(255, 255, 255),
    Widget = Color3.fromRGB(240, 240, 248)
}

-- Aliases + legacy themes
MacUI.Themes.Dark = MacUI.Themes["Liquid Glass Dark"]
MacUI.Themes.Light = MacUI.Themes["Liquid Glass Light"]

MacUI.Themes.Graphite = {
    Background = Color3.fromRGB(40, 40, 42),
    SecondaryBackground = Color3.fromRGB(50, 50, 53),
    TertiaryBackground = Color3.fromRGB(60, 60, 64),
    Text = Color3.fromRGB(245, 245, 247),
    SecondaryText = Color3.fromRGB(160, 160, 165),
    Accent = Color3.fromRGB(120, 120, 130),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.75,
    Glass = Color3.fromRGB(55, 55, 58),
    GlassTransparency = 0.28,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(45, 45, 48),
    DockTransparency = 0.25,
    IconColor = Color3.fromRGB(235, 235, 240),
    TabInactive = Color3.fromRGB(150, 150, 155),
    Sheen = Color3.fromRGB(255, 255, 255),
    Widget = Color3.fromRGB(38, 38, 40)
}

MacUI.Themes.Midnight = {
    Background = Color3.fromRGB(12, 12, 18),
    SecondaryBackground = Color3.fromRGB(20, 20, 28),
    TertiaryBackground = Color3.fromRGB(30, 30, 40),
    Text = Color3.fromRGB(240, 240, 250),
    SecondaryText = Color3.fromRGB(150, 150, 165),
    Accent = Color3.fromRGB(94, 92, 230),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.82,
    Glass = Color3.fromRGB(20, 20, 28),
    GlassTransparency = 0.35,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(16, 16, 24),
    DockTransparency = 0.3,
    IconColor = Color3.fromRGB(230, 230, 245),
    TabInactive = Color3.fromRGB(140, 140, 160),
    Sheen = Color3.fromRGB(200, 200, 255),
    Widget = Color3.fromRGB(14, 14, 20)
}

MacUI.Themes.Blue = {
    Background = Color3.fromRGB(18, 28, 48),
    SecondaryBackground = Color3.fromRGB(26, 38, 62),
    TertiaryBackground = Color3.fromRGB(34, 48, 78),
    Text = Color3.fromRGB(240, 245, 255),
    SecondaryText = Color3.fromRGB(160, 180, 210),
    Accent = Color3.fromRGB(10, 132, 255),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.8,
    Glass = Color3.fromRGB(28, 42, 68),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(22, 34, 55),
    DockTransparency = 0.3,
    IconColor = Color3.fromRGB(230, 240, 255),
    TabInactive = Color3.fromRGB(140, 160, 190),
    Sheen = Color3.fromRGB(180, 210, 255),
    Widget = Color3.fromRGB(16, 26, 45)
}

MacUI.Themes.Purple = {
    Background = Color3.fromRGB(28, 18, 42),
    SecondaryBackground = Color3.fromRGB(38, 26, 55),
    TertiaryBackground = Color3.fromRGB(48, 34, 68),
    Text = Color3.fromRGB(245, 240, 255),
    SecondaryText = Color3.fromRGB(180, 160, 200),
    Accent = Color3.fromRGB(175, 82, 222),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.78,
    Glass = Color3.fromRGB(42, 28, 60),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(34, 24, 50),
    DockTransparency = 0.3,
    IconColor = Color3.fromRGB(240, 230, 255),
    TabInactive = Color3.fromRGB(160, 140, 180),
    Sheen = Color3.fromRGB(220, 180, 255),
    Widget = Color3.fromRGB(24, 16, 38)
}

MacUI.Themes.Nord = {
    Background = Color3.fromRGB(32, 36, 48),
    SecondaryBackground = Color3.fromRGB(40, 46, 60),
    TertiaryBackground = Color3.fromRGB(52, 59, 75),
    Text = Color3.fromRGB(236, 239, 244),
    SecondaryText = Color3.fromRGB(165, 173, 190),
    Accent = Color3.fromRGB(136, 192, 208),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.8,
    Glass = Color3.fromRGB(46, 52, 68),
    GlassTransparency = 0.3,
    Success = Color3.fromRGB(163, 190, 140),
    Warning = Color3.fromRGB(235, 203, 139),
    Danger = Color3.fromRGB(191, 97, 106),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(36, 41, 54),
    DockTransparency = 0.28,
    IconColor = Color3.fromRGB(229, 233, 240),
    TabInactive = Color3.fromRGB(150, 160, 178),
    Sheen = Color3.fromRGB(216, 222, 233),
    Widget = Color3.fromRGB(28, 32, 42)
}

MacUI.Themes.Solarized = {
    Background = Color3.fromRGB(0, 43, 54),
    SecondaryBackground = Color3.fromRGB(7, 54, 66),
    TertiaryBackground = Color3.fromRGB(16, 65, 79),
    Text = Color3.fromRGB(238, 232, 213),
    SecondaryText = Color3.fromRGB(131, 148, 150),
    Accent = Color3.fromRGB(38, 139, 210),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.82,
    Glass = Color3.fromRGB(7, 54, 66),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(133, 153, 0),
    Warning = Color3.fromRGB(181, 137, 0),
    Danger = Color3.fromRGB(220, 50, 47),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(4, 48, 59),
    DockTransparency = 0.26,
    IconColor = Color3.fromRGB(238, 232, 213),
    TabInactive = Color3.fromRGB(110, 136, 138),
    Sheen = Color3.fromRGB(147, 161, 161),
    Widget = Color3.fromRGB(0, 36, 45)
}

MacUI.Themes["Rose Pine"] = {
    Background = Color3.fromRGB(25, 23, 36),
    SecondaryBackground = Color3.fromRGB(33, 32, 46),
    TertiaryBackground = Color3.fromRGB(42, 40, 58),
    Text = Color3.fromRGB(224, 222, 244),
    SecondaryText = Color3.fromRGB(144, 140, 170),
    Accent = Color3.fromRGB(235, 188, 186),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.8,
    Glass = Color3.fromRGB(38, 35, 52),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(49, 116, 143),
    Warning = Color3.fromRGB(246, 193, 119),
    Danger = Color3.fromRGB(235, 111, 146),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(31, 29, 46),
    DockTransparency = 0.28,
    IconColor = Color3.fromRGB(228, 227, 244),
    TabInactive = Color3.fromRGB(144, 140, 170),
    Sheen = Color3.fromRGB(246, 193, 119),
    Widget = Color3.fromRGB(21, 19, 31)
}

MacUI.Themes.Forest = {
    Background = Color3.fromRGB(20, 30, 24),
    SecondaryBackground = Color3.fromRGB(27, 40, 32),
    TertiaryBackground = Color3.fromRGB(36, 52, 42),
    Text = Color3.fromRGB(232, 240, 232),
    SecondaryText = Color3.fromRGB(165, 185, 168),
    Accent = Color3.fromRGB(96, 189, 115),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.8,
    Glass = Color3.fromRGB(30, 44, 35),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(96, 189, 115),
    Warning = Color3.fromRGB(222, 180, 90),
    Danger = Color3.fromRGB(206, 92, 80),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(23, 34, 27),
    DockTransparency = 0.28,
    IconColor = Color3.fromRGB(226, 236, 226),
    TabInactive = Color3.fromRGB(150, 170, 154),
    Sheen = Color3.fromRGB(200, 230, 205),
    Widget = Color3.fromRGB(16, 24, 19)
}

MacUI.Themes["Classic Aqua"] = {
    Background = Color3.fromRGB(236, 242, 250),
    SecondaryBackground = Color3.fromRGB(246, 250, 255),
    TertiaryBackground = Color3.fromRGB(222, 233, 246),
    Text = Color3.fromRGB(20, 30, 45),
    SecondaryText = Color3.fromRGB(90, 105, 125),
    Accent = Color3.fromRGB(0, 140, 230),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.3,
    Glass = Color3.fromRGB(255, 255, 255),
    GlassTransparency = 0.35,
    Success = Color3.fromRGB(52, 199, 89),
    Warning = Color3.fromRGB(255, 149, 0),
    Danger = Color3.fromRGB(255, 59, 48),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(250, 253, 255),
    DockTransparency = 0.32,
    IconColor = Color3.fromRGB(30, 45, 65),
    TabInactive = Color3.fromRGB(120, 140, 165),
    Sheen = Color3.fromRGB(255, 255, 255),
    Widget = Color3.fromRGB(230, 240, 250)
}

-- Golden Gate — warm SF fog + bridge gold (default macOS Golden Gate UI)
MacUI.Themes["Golden Gate"] = {
    Background = Color3.fromRGB(28, 26, 24),
    SecondaryBackground = Color3.fromRGB(38, 35, 32),
    TertiaryBackground = Color3.fromRGB(52, 48, 42),
    Text = Color3.fromRGB(250, 245, 235),
    SecondaryText = Color3.fromRGB(180, 170, 155),
    Accent = Color3.fromRGB(212, 160, 70),
    Border = Color3.fromRGB(255, 240, 210),
    BorderTransparency = 0.72,
    Glass = Color3.fromRGB(36, 33, 28),
    GlassTransparency = 0.30,
    Success = Color3.fromRGB(90, 200, 120),
    Warning = Color3.fromRGB(230, 170, 60),
    Danger = Color3.fromRGB(220, 80, 70),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(32, 30, 26),
    DockTransparency = 0.26,
    IconColor = Color3.fromRGB(245, 235, 220),
    TabInactive = Color3.fromRGB(160, 150, 135),
    Sheen = Color3.fromRGB(255, 230, 180),
    Widget = Color3.fromRGB(24, 22, 20)
}

MacUI.Themes.Crimson = {
    Background = Color3.fromRGB(28, 16, 18),
    SecondaryBackground = Color3.fromRGB(40, 22, 26),
    TertiaryBackground = Color3.fromRGB(55, 30, 36),
    Text = Color3.fromRGB(255, 240, 242),
    SecondaryText = Color3.fromRGB(190, 150, 155),
    Accent = Color3.fromRGB(220, 60, 80),
    Border = Color3.fromRGB(255, 200, 210),
    BorderTransparency = 0.78,
    Glass = Color3.fromRGB(38, 20, 24),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(32, 18, 22),
    DockTransparency = 0.28,
    IconColor = Color3.fromRGB(250, 230, 235),
    TabInactive = Color3.fromRGB(170, 130, 140),
    Sheen = Color3.fromRGB(255, 180, 190),
    Widget = Color3.fromRGB(22, 12, 14)
}

MacUI.Themes.Ocean = {
    Background = Color3.fromRGB(12, 24, 36),
    SecondaryBackground = Color3.fromRGB(18, 34, 50),
    TertiaryBackground = Color3.fromRGB(26, 48, 68),
    Text = Color3.fromRGB(230, 245, 255),
    SecondaryText = Color3.fromRGB(140, 180, 200),
    Accent = Color3.fromRGB(0, 180, 220),
    Border = Color3.fromRGB(180, 230, 255),
    BorderTransparency = 0.78,
    Glass = Color3.fromRGB(16, 32, 48),
    GlassTransparency = 0.30,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(14, 28, 42),
    DockTransparency = 0.26,
    IconColor = Color3.fromRGB(220, 240, 255),
    TabInactive = Color3.fromRGB(120, 160, 180),
    Sheen = Color3.fromRGB(160, 220, 255),
    Widget = Color3.fromRGB(10, 20, 32)
}

MacUI.Themes.Lavender = {
    Background = Color3.fromRGB(30, 26, 42),
    SecondaryBackground = Color3.fromRGB(42, 36, 58),
    TertiaryBackground = Color3.fromRGB(56, 48, 74),
    Text = Color3.fromRGB(245, 240, 255),
    SecondaryText = Color3.fromRGB(180, 170, 200),
    Accent = Color3.fromRGB(160, 120, 255),
    Border = Color3.fromRGB(220, 200, 255),
    BorderTransparency = 0.76,
    Glass = Color3.fromRGB(38, 32, 54),
    GlassTransparency = 0.32,
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(34, 30, 48),
    DockTransparency = 0.28,
    IconColor = Color3.fromRGB(235, 230, 250),
    TabInactive = Color3.fromRGB(150, 140, 180),
    Sheen = Color3.fromRGB(200, 180, 255),
    Widget = Color3.fromRGB(24, 20, 36)
}

MacUI.Themes.Monochrome = {
    Background = Color3.fromRGB(18, 18, 18),
    SecondaryBackground = Color3.fromRGB(28, 28, 28),
    TertiaryBackground = Color3.fromRGB(42, 42, 42),
    Text = Color3.fromRGB(250, 250, 250),
    SecondaryText = Color3.fromRGB(160, 160, 160),
    Accent = Color3.fromRGB(220, 220, 220),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.82,
    Glass = Color3.fromRGB(24, 24, 24),
    GlassTransparency = 0.28,
    Success = Color3.fromRGB(180, 180, 180),
    Warning = Color3.fromRGB(200, 200, 200),
    Danger = Color3.fromRGB(120, 120, 120),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(22, 22, 22),
    DockTransparency = 0.25,
    IconColor = Color3.fromRGB(240, 240, 240),
    TabInactive = Color3.fromRGB(140, 140, 140),
    Sheen = Color3.fromRGB(255, 255, 255),
    Widget = Color3.fromRGB(14, 14, 14)
}

MacUI.Themes.Sunset = {
    Background = Color3.fromRGB(32, 20, 28),
    SecondaryBackground = Color3.fromRGB(48, 28, 36),
    TertiaryBackground = Color3.fromRGB(64, 38, 48),
    Text = Color3.fromRGB(255, 240, 230),
    SecondaryText = Color3.fromRGB(200, 160, 150),
    Accent = Color3.fromRGB(255, 120, 80),
    Border = Color3.fromRGB(255, 200, 180),
    BorderTransparency = 0.75,
    Glass = Color3.fromRGB(42, 26, 34),
    GlassTransparency = 0.30,
    Success = Color3.fromRGB(100, 200, 120),
    Warning = Color3.fromRGB(255, 180, 60),
    Danger = Color3.fromRGB(240, 70, 80),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(36, 22, 30),
    DockTransparency = 0.26,
    IconColor = Color3.fromRGB(255, 235, 220),
    TabInactive = Color3.fromRGB(180, 140, 130),
    Sheen = Color3.fromRGB(255, 200, 160),
    Widget = Color3.fromRGB(26, 16, 22)
}

MacUI.Themes.Arctic = {
    Background = Color3.fromRGB(230, 238, 245),
    SecondaryBackground = Color3.fromRGB(245, 250, 255),
    TertiaryBackground = Color3.fromRGB(210, 222, 235),
    Text = Color3.fromRGB(20, 30, 45),
    SecondaryText = Color3.fromRGB(80, 100, 120),
    Accent = Color3.fromRGB(0, 140, 200),
    Border = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.28,
    Glass = Color3.fromRGB(250, 252, 255),
    GlassTransparency = 0.36,
    Success = Color3.fromRGB(40, 180, 100),
    Warning = Color3.fromRGB(230, 150, 20),
    Danger = Color3.fromRGB(220, 50, 50),
    Shadow = Color3.fromRGB(0, 0, 0),
    Dock = Color3.fromRGB(240, 246, 252),
    DockTransparency = 0.32,
    IconColor = Color3.fromRGB(30, 45, 60),
    TabInactive = Color3.fromRGB(110, 130, 150),
    Sheen = Color3.fromRGB(255, 255, 255),
    Widget = Color3.fromRGB(220, 230, 240)
}

MacUI.CurrentTheme = "Golden Gate"

function MacUI:RegisterTheme(name, themeTable)
    self.Themes[name] = themeTable
end

-- Sets (or clears, with url = nil) the PixelJSON background image for a theme. If that
-- theme is the one currently applied to an open window, the image is swapped immediately;
-- otherwise it just takes effect the next time this theme is applied/booted into.
-- options (optional): forwarded to PixelJSON.Render, plus MacUI keys:
--   Transparency / ImageTransparency (0–1) — fade the image so glass shows through
--   AutoScale, Fit ("cover"|"contain"), Scale, etc.
-- e.g. MacUI:SetThemeImage("Golden Gate", url, { Transparency = 0.45, Fit = "cover" })
function MacUI:SetThemeImage(themeName, url, options)
    local t = self.Themes[themeName]
    if not t then
        warn("[MacUI] Warning: Theme '" .. tostring(themeName) .. "' does not exist")
        return
    end
    if url and url ~= "" then
        t.Image = { URL = url, Options = options }
    else
        t.Image = nil
    end
    if self.CurrentTheme == themeName then
        self:SetTheme(themeName, true)
    end
end

-- silent: true suppresses the "Switch" SFX — used internally when a window first boots
-- into its starting theme, so opening a hub doesn't itself play a theme-switch sound.
function MacUI:SetTheme(name, silent)
    if not self.Themes[name] then
        warn("[MacUI] Warning: Theme '" .. tostring(name) .. "' does not exist")
        return
    end
    self.CurrentTheme = name
    local theme = self.Themes[name]
    if not silent then
        PlaySFX("Switch", 1.0, 0.5)
    end
    for _, window in pairs(self.Windows) do
        if window and window.ApplyTheme then
            window:ApplyTheme(theme)
        end
    end
end

function MacUI:SetGlassStyle(style)
    for k, v in pairs(style) do
        self.GlassStyle[k] = v
    end
end

function MacUI:SetAccessibility(opts)
    for k, v in pairs(opts) do
        self.Accessibility[k] = v
    end
end

-- ============================================================
-- LIQUID GLASS FRAME (multi-layer approximation)
-- ============================================================
local function CreateGlassFrame(parent, props)
    props = props or {}
    local theme = MacUI.Themes[MacUI.CurrentTheme] or MacUI.Themes["Liquid Glass Dark"]
    local radius = props.Radius or 16
    local transparency = props.Transparency
        or theme.GlassTransparency
        or MacUI.GlassStyle.Transparency
    local color = props.Color or theme.Glass or theme.Background

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.Parent = parent

    -- Shadow layer
    if MacUI.GlassStyle.Shadow then
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "GlassShadow"
        shadow.BackgroundTransparency = 1
        shadow.Image = MacUI.GlassStyle.ShadowImage or "rbxassetid://6014261993"
        shadow.ImageColor3 = Color3.new(0, 0, 0)
        shadow.ImageTransparency = 0.55
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(49, 49, 450, 450)
        shadow.Size = UDim2.new(1, 48, 1, 48)
        shadow.Position = UDim2.new(0, -24, 0, -20)
        shadow.ZIndex = -2
        shadow.Parent = container
    end

    -- Base glass (Layer 1: tint). ClipsDescendants defaults on so nothing - a child frame,
    -- a hover-grown element, an overlong gradient - can poke a square edge out past the
    -- rounded corner; pass props.Clip = false to opt a specific frame out (the dock does,
    -- since its hover-magnified icons are meant to bulge slightly past the dock's edge).
    local base = Instance.new("Frame")
    base.Name = "GlassBase"
    base.Size = UDim2.new(1, 0, 1, 0)
    base.BackgroundColor3 = color
    base.BackgroundTransparency = transparency
    base.BorderSizePixel = 0
    base.ZIndex = 1
    base.ClipsDescendants = props.Clip ~= false
    base.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = base

    -- ============================================================
    -- 3-LAYER LIQUID GLASS
    --   Layer 1: Base        - the tinted translucent fill set above
    --   Layer 2: Frost/Depth - a diagonal refraction wash that gives the glass body
    --   Layer 3: Sheen       - a top specular highlight band, like light hitting the surface
    -- props.Layers lets a specific call opt out of layers 2 & 3 entirely (e.g. content that
    -- needs AutomaticSize - Frost/Sheen are Scale-sized to the base, so letting the base
    -- auto-size off its own children while they're present would make its size depend on
    -- itself - see the dock fix and the Paragraph card above for the concrete case).
    -- ============================================================
    local useLayers = props.Layers
    if useLayers == nil then useLayers = MacUI.GlassStyle.Layers end
    if useLayers then
        -- Layer 2: Frost / Depth - diagonal gradient instead of a flat wash, so the glass
        -- actually reads as glass instead of a slightly-different-colored flat panel.
        local frost = Instance.new("Frame")
        frost.Name = "Frost"
        frost.Size = UDim2.new(1, 0, 1, 0)
        frost.BackgroundColor3 = theme.Glass or color
        frost.BackgroundTransparency = 0
        frost.BorderSizePixel = 0
        frost.ZIndex = 2
        frost.Parent = base

        local frostCorner = Instance.new("UICorner")
        frostCorner.CornerRadius = UDim.new(0, radius)
        frostCorner.Parent = frost

        local frostGradient = Instance.new("UIGradient")
        frostGradient.Name = "FrostGradient"
        frostGradient.Rotation = 115
        frostGradient.Color = ColorSequence.new(theme.Glass or color)
        frostGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.62),
            NumberSequenceKeypoint.new(0.45, 0.88),
            NumberSequenceKeypoint.new(0.55, 0.88),
            NumberSequenceKeypoint.new(1, 0.7)
        })
        frostGradient.Parent = frost

        -- Layer 3: Sheen - top specular highlight, tuned brighter/taller than before so it
        -- actually reads instead of disappearing into the base tint.
        local sheen = Instance.new("Frame")
        sheen.Name = "Sheen"
        sheen.Size = UDim2.new(1, 0, 0.5, 0)
        sheen.BackgroundColor3 = theme.Sheen or Color3.new(1, 1, 1)
        sheen.BackgroundTransparency = 0.78
        sheen.BorderSizePixel = 0
        sheen.ZIndex = 3
        sheen.Parent = base

        local sheenCorner = Instance.new("UICorner")
        sheenCorner.CornerRadius = UDim.new(0, radius)
        sheenCorner.Parent = sheen

        local sheenGradient = Instance.new("UIGradient")
        sheenGradient.Rotation = 90
        sheenGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.55, 0.82),
            NumberSequenceKeypoint.new(1, 1)
        })
        sheenGradient.Parent = sheen

        -- Optional 4th layer: slow-drifting liquid blobs behind the tint (opt-in; see
        -- MacUI.AddMetaballs). Off by default since it's extra always-running tweens.
        if props.Metaballs then
            MacUI.AddMetaballs(base, {
                Count = props.MetaballCount or 3,
                Color = props.MetaballColor or theme.Accent,
                Size = props.MetaballSize or {40, 80},
                Speed = props.MetaballSpeed or 5,
                ZIndex = 1
            })
        end
    end

    -- Border stroke (soft white edge like macOS liquid glass)
    if MacUI.GlassStyle.Border then
        local stroke = Instance.new("UIStroke")
        stroke.Name = "GlassStroke"
        stroke.Color = theme.Border or Color3.fromRGB(255, 255, 255)
        stroke.Transparency = theme.BorderTransparency or 0.7
        stroke.Thickness = 1
        stroke.Parent = base
    end

    return container
end

-- Safe accessor (Instances cannot hold custom .GlassBase fields)
local function GetGlassBase(container)
    if not container then return nil end
    return container:FindFirstChild("GlassBase")
end

-- ============================================================
-- BOOT SEQUENCE (Apple logo + loading)
-- ============================================================
function MacUI:PlayBootSequence(options)
    options = options or {}
    local duration = options.Duration or 2.8
    local onComplete = options.OnComplete

    local theme = self.Themes[self.CurrentTheme] or self.Themes.Dark

    local bootGui = Instance.new("ScreenGui")
    bootGui.Name = "MacUI_Boot"
    bootGui.ResetOnSpawn = false
    bootGui.IgnoreGuiInset = true
    bootGui.DisplayOrder = 100000
    bootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bootGui.Parent = GetUIParent()

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = bootGui

    -- Apple logo
    local logo = Instance.new("ImageLabel")
    logo.Name = "AppleLogo"
    logo.Size = UDim2.new(0, 72, 0, 72)
    logo.Position = UDim2.new(0.5, -36, 0.42, -36)
    logo.BackgroundTransparency = 1
    MacUI.ApplyIcon(logo, "apple")
    logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    logo.ImageTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = bg

    local logoScale = Instance.new("UIScale")
    logoScale.Scale = 0.6
    logoScale.Parent = logo

    -- Progress bar track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(0, 160, 0, 4)
    track.Position = UDim2.new(0.5, -80, 0.58, 0)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.BackgroundTransparency = 1
    track.Parent = bg

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Fade in logo
    MacUI.Tween(logo, {Time = 0.55, EasingStyle = Enum.EasingStyle.Quint}, {
        ImageTransparency = 0
    })
    MacUI.Tween(logoScale, {Time = 0.6, EasingStyle = Enum.EasingStyle.Back}, {
        Scale = 1
    })

    -- Idle "breathing" pulse while the progress bar fills, so the boot screen doesn't sit
    -- static for the couple of seconds it's on screen.
    if not MacUI.Accessibility.ReducedMotion then
        task.delay(0.7, function()
            if logoScale and logoScale.Parent then
                MacUI.Tween(logoScale, {
                    Time = 1.1, EasingStyle = Enum.EasingStyle.Sine, EasingDirection = Enum.EasingDirection.InOut,
                    RepeatCount = -1, Reverses = true
                }, {Scale = 1.06})
            end
        end)
    end

    task.delay(0.45, function()
        MacUI.Tween(track, {Time = 0.3}, {BackgroundTransparency = 0.35})
        -- Progress fill
        MacUI.Tween(fill, {Time = duration - 0.9, EasingStyle = Enum.EasingStyle.Quad}, {
            Size = UDim2.new(1, 0, 1, 0)
        })
    end)

    -- Finish
    task.delay(duration, function()
        PlaySFX("Boot", 1.05, 0.7)
        MacUI.Tween(logo, {Time = 0.35}, {ImageTransparency = 1})
        MacUI.Tween(track, {Time = 0.3}, {BackgroundTransparency = 1})
        MacUI.Tween(fill, {Time = 0.3}, {BackgroundTransparency = 1})
        MacUI.Tween(bg, {Time = 0.45}, {BackgroundTransparency = 1})

        task.wait(0.5)
        if bootGui and bootGui.Parent then
            bootGui:Destroy()
        end
        if onComplete then
            pcall(onComplete)
        end
    end)

    return bootGui
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
function MacUI:Notify(options)
    options = options or {}
    local title = options.Title or "MacUI"
    local content = options.Content or ""
    local duration = options.Duration or 4
    local icon = options.Icon or "info"

    local theme = self.Themes[self.CurrentTheme]
    local screenGui = GetUIParent():FindFirstChild("MacUI_Notifications")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MacUI_Notifications"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 50000
        screenGui.Parent = GetUIParent()
    end

    local notifContainer = CreateGlassFrame(screenGui, {Radius = 14, Transparency = 0.12})
    notifContainer.Size = UDim2.new(0, 320, 0, 72)
    notifContainer.Position = UDim2.new(1, 40, 0, 20 + (#self.Notifications * 84))
    notifContainer.AnchorPoint = Vector2.new(1, 0)
    notifContainer.ZIndex = 100

    local notif = GetGlassBase(notifContainer)

    local iconImg = Instance.new("ImageLabel")
    iconImg.Size = UDim2.new(0, 28, 0, 28)
    iconImg.Position = UDim2.new(0, 14, 0.5, -14)
    iconImg.BackgroundTransparency = 1
    MacUI.ApplyIcon(iconImg, icon)
    iconImg.ImageColor3 = theme.Accent
    iconImg.Parent = notif

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -60, 0, 22)
    titleLbl.Position = UDim2.new(0, 52, 0, 12)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = theme.Text
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 15
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = notif

    local contentLbl = Instance.new("TextLabel")
    contentLbl.Size = UDim2.new(1, -60, 0, 24)
    contentLbl.Position = UDim2.new(0, 52, 0, 34)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text = content
    contentLbl.TextColor3 = theme.SecondaryText
    contentLbl.Font = Enum.Font.Gotham
    contentLbl.TextSize = 13
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextWrapped = true
    contentLbl.Parent = notif

    table.insert(self.Notifications, notifContainer)
    PlaySFX("Notify", 1.1, 0.55)

    -- Slide in + pop/scale bounce
    local notifScale = Instance.new("UIScale")
    notifScale.Scale = 0.85
    notifScale.Parent = notifContainer
    MacUI.Tween(notifContainer, {Time = 0.4, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out}, {
        Position = UDim2.new(1, -20, 0, 20 + ((#self.Notifications - 1) * 84))
    })
    MacUI.Tween(notifScale, {Time = 0.35, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out}, {
        Scale = 1
    })

    task.delay(duration, function()
        if notifContainer and notifContainer.Parent then
            MacUI.Tween(notifContainer, {Time = 0.3}, {
                Position = UDim2.new(1, 50, 0, notifContainer.Position.Y.Offset),
            })
            MacUI.Tween(notif, {Time = 0.3}, {BackgroundTransparency = 1})
            task.wait(0.35)
            notifContainer:Destroy()
            for i, n in ipairs(self.Notifications) do
                if n == notifContainer then
                    table.remove(self.Notifications, i)
                    break
                end
            end
            for i, n in ipairs(self.Notifications) do
                MacUI.Tween(n, {Time = 0.25}, {
                    Position = UDim2.new(1, -20, 0, 20 + ((i - 1) * 84))
                })
            end
        end
    end)
end

-- Configuration
function MacUI:CreateConfig(opts)
    opts = opts or {}
    self.Config.Folder = opts.Folder or "MacUI"
    self.Config.File = opts.File or "Config"
end

-- Returns true if this executor exposes the file functions MacUI needs for config saving.
function MacUI:HasFileSupport()
    return writefile ~= nil and readfile ~= nil and isfile ~= nil
end

function MacUI:SaveConfig()
    local success, err = pcall(function()
        if writefile then
            -- Create the save folder first - writefile fails on most executors if the
            -- target folder doesn't exist yet, which silently dropped every save before.
            if makefolder and isfolder and not isfolder(self.Config.Folder) then
                makefolder(self.Config.Folder)
            end
            local data = HttpService:JSONEncode(self.Config.Data)
            writefile(self.Config.Folder .. "/" .. self.Config.File .. ".json", data)
        end
    end)
    if not success then
        warn("[MacUI] Config save unavailable in this environment:", err)
    end
    return success
end

function MacUI:LoadConfig()
    local success, result = pcall(function()
        if isfile and isfile(self.Config.Folder .. "/" .. self.Config.File .. ".json") then
            local data = readfile(self.Config.Folder .. "/" .. self.Config.File .. ".json")
            self.Config.Data = HttpService:JSONDecode(data)
            return true
        end
        return false
    end)
    if not success then
        warn("[MacUI] Config load unavailable")
    end
    return success and result
end

function MacUI:ResetConfig()
    self.Config.Data = {}
    self:SaveConfig()
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
function MacUI:CreateWindow(options)
    options = options or {}

    -- Shadows the module-level TrackConnection for the rest of this function (including
    -- every nested Section:CreateX closure defined below): connections now land in this
    -- window's own table instead of the module-level one, which nothing ever disconnected.
    -- Window:Destroy() reads this same table, so destroying a window now actually cleans up
    -- its input connections instead of leaking all of them.
    local windowConnections = {}
    local function TrackConnection(conn)
        table.insert(windowConnections, conn)
        return conn
    end

    local name = options.Name or "MacUI"
    local subtitle = options.Subtitle or ""
    local themeName = options.Theme or "Golden Gate"
    local acrylic = options.Acrylic ~= false
    local size = options.Size or UDim2.new(0, 760, 0, 500)
    local minSize = options.MinSize or Vector2.new(480, 320)
    local showBoot = options.Boot ~= false
    local useDock = options.Dock ~= false
    local configSaving = options.ConfigurationSaving
    local useMetaballs = options.Metaballs == true
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl

    -- Executor config support: creates (or reuses) the save folder/file and schedules an
    -- automatic load once the window finishes opening.
    local pendingConfigLoad = false
    if type(configSaving) == "table" and configSaving.Enabled then
        self:CreateConfig({
            Folder = configSaving.Folder or configSaving.FolderName or self.Config.Folder,
            File = configSaving.File or configSaving.FileName or self.Config.File
        })
        pendingConfigLoad = true
    end

    self:SetTheme(themeName, true)
    local theme = self.Themes[themeName]

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MacUI_" .. name
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100
    screenGui.Parent = GetUIParent()

    -- Main window container (liquid glass)
    local windowContainer = CreateGlassFrame(screenGui, {
        Radius = 20,
        Transparency = acrylic and (theme.GlassTransparency or MacUI.GlassStyle.Transparency) or 0.08,
        Color = theme.Background,
        Metaballs = useMetaballs -- opt-in: slow-drifting liquid blobs behind the window tint
    })
    windowContainer.Name = "Window"
    windowContainer.Size = size
    windowContainer.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    windowContainer.ClipsDescendants = true
    -- Hidden until the boot sequence finishes (OpenWindow reveals it). Previously the hub
    -- was fully built, visible and clickable underneath the boot overlay the whole time it
    -- played, since the boot background never actually covered input. Now nothing shows or
    -- receives input until boot (if any) has completed.
    windowContainer.Visible = false

    local window = GetGlassBase(windowContainer)
    window.ClipsDescendants = true

    -- Theme background image (no-op unless the starting theme sets Image.URL)
    local themeImageHolder = MacUI.ApplyThemeImage(theme, window)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 10
    titleBar.Parent = window

    -- Traffic lights
    local function CreateTrafficLight(color, posX)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 13, 0, 13)
        btn.Position = UDim2.new(0, posX, 0.5, -6.5)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 11
        btn.Parent = titleBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(0, 0, 0)
        stroke.Transparency = 0.65
        stroke.Thickness = 0.6
        stroke.Parent = btn

        return btn
    end

    local closeBtn = CreateTrafficLight(Color3.fromRGB(255, 95, 87), 16)
    local minBtn = CreateTrafficLight(Color3.fromRGB(255, 189, 46), 36)
    local maxBtn = CreateTrafficLight(Color3.fromRGB(40, 200, 64), 56)

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -180, 1, 0)
    titleLabel.Position = UDim2.new(0, 90, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = name
    titleLabel.TextColor3 = theme.Text
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 11
    titleLabel.Parent = titleBar

    if subtitle ~= "" then
        titleLabel.Text = name .. "  —  " .. subtitle
    end

    -- Search button
    local searchBtn = Instance.new("ImageButton")
    searchBtn.Size = UDim2.new(0, 20, 0, 20)
    searchBtn.Position = UDim2.new(1, -36, 0.5, -10)
    searchBtn.BackgroundTransparency = 1
    MacUI.ApplyIcon(searchBtn, "search")
    searchBtn.ImageColor3 = theme.IconColor or theme.SecondaryText
    searchBtn.ZIndex = 11
    searchBtn.Parent = titleBar

    -- Key-system battery indicator — styled like the real macOS menu-bar battery:
    -- percentage text + battery body outline + inner fill + tip nub.
    -- Only created when a key system is actually configured.
    if MacUI.KeySystem.Enabled then
        local keyBattery = Instance.new("Frame")
        keyBattery.Name = "KeyBattery"
        keyBattery.Size = UDim2.new(0, 72, 0, 18)
        keyBattery.Position = UDim2.new(1, -112, 0.5, -9)
        keyBattery.BackgroundTransparency = 1
        keyBattery.ZIndex = 11
        keyBattery.Parent = titleBar

        -- Percentage label (left of the icon, like macOS)
        local pctLbl = Instance.new("TextLabel")
        pctLbl.Name = "Percent"
        pctLbl.Size = UDim2.new(0, 32, 1, 0)
        pctLbl.Position = UDim2.new(0, 0, 0, 0)
        pctLbl.BackgroundTransparency = 1
        pctLbl.Text = "--%"
        pctLbl.TextColor3 = theme.Text
        pctLbl.Font = Enum.Font.GothamMedium
        pctLbl.TextSize = 11
        pctLbl.TextXAlignment = Enum.TextXAlignment.Right
        pctLbl.ZIndex = 12
        pctLbl.Parent = keyBattery

        -- Battery body (rounded rectangle outline)
        local body = Instance.new("Frame")
        body.Name = "Body"
        body.Size = UDim2.new(0, 28, 0, 12)
        body.Position = UDim2.new(0, 36, 0.5, -6)
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.ZIndex = 12
        body.Parent = keyBattery

        local bodyStroke = Instance.new("UIStroke")
        bodyStroke.Color = theme.Text
        bodyStroke.Transparency = 0.25
        bodyStroke.Thickness = 1.25
        bodyStroke.Parent = body

        local bodyCorner = Instance.new("UICorner")
        bodyCorner.CornerRadius = UDim.new(0, 2.5)
        bodyCorner.Parent = body

        -- Inner fill (grows from left, inset so it doesn't touch the stroke)
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new(1, -4, 1, -4)
        fill.Position = UDim2.new(0, 2, 0, 2)
        fill.BackgroundColor3 = theme.Success
        fill.BorderSizePixel = 0
        fill.ZIndex = 13
        fill.Parent = body

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 1.5)
        fillCorner.Parent = fill

        -- Battery tip / positive terminal (small nub on the right)
        local tip = Instance.new("Frame")
        tip.Name = "Tip"
        tip.Size = UDim2.new(0, 2, 0, 5)
        tip.Position = UDim2.new(0, 64, 0.5, -2.5)
        tip.BackgroundColor3 = theme.Text
        tip.BackgroundTransparency = 0.25
        tip.BorderSizePixel = 0
        tip.ZIndex = 12
        tip.Parent = keyBattery

        local tipCorner = Instance.new("UICorner")
        tipCorner.CornerRadius = UDim.new(0, 1)
        tipCorner.Parent = tip

        local function RefreshBattery()
            if not (keyBattery and keyBattery.Parent) then return false end
            local status = MacUI:GetKeyStatus()
            if status.Remaining and status.Total and status.Total > 0 then
                local pct = math.clamp(status.Remaining / status.Total, 0, 1)
                local pctInt = math.floor(pct * 100 + 0.5)
                pctLbl.Text = pctInt .. "%"
                -- Fill width scales inside the body (full width of fill frame = 1)
                -- Inner width leaves 2px padding on each side of the 28px body
                local innerW = math.max(0, math.floor((28 - 4) * pct + 0.5))
                MacUI.Tween(fill, {Time = 0.35, EasingStyle = Enum.EasingStyle.Quint}, {
                    Size = UDim2.new(0, innerW, 1, -4)
                })
                local color = theme.Text
                if pct <= 0.15 then
                    color = theme.Danger
                elseif pct <= 0.30 then
                    color = theme.Warning
                else
                    color = theme.Success
                end
                fill.BackgroundColor3 = color
                -- Low battery: make outline match fill color (macOS does this in red)
                if pct <= 0.15 then
                    bodyStroke.Color = theme.Danger
                    tip.BackgroundColor3 = theme.Danger
                else
                    bodyStroke.Color = theme.Text
                    tip.BackgroundColor3 = theme.Text
                end
            else
                pctLbl.Text = status.Valid and "100%" or "--%"
                fill.Size = UDim2.new(0, status.Valid and 24 or 0, 1, -4)
                fill.BackgroundColor3 = status.Valid and theme.Success or theme.SecondaryText
            end
            return true
        end
        RefreshBattery()
        task.spawn(function()
            while RefreshBattery() do
                task.wait(1)
            end
        end)
    end

    -- Content area (full width when using dock, otherwise with sidebar)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -44)
    content.Position = UDim2.new(0, 0, 0, 44)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.ZIndex = 5
    content.Parent = window

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "Scroll"
    contentScroll.Size = UDim2.new(1, 0, 1, useDock and -70 or 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 5
    contentScroll.ScrollBarImageColor3 = theme.Border
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.ZIndex = 6
    contentScroll.Parent = content

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 16)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentScroll

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 20)
    contentPadding.PaddingLeft = UDim.new(0, 28)
    contentPadding.PaddingRight = UDim.new(0, 28)
    contentPadding.PaddingBottom = UDim.new(0, 28)
    contentPadding.Parent = contentScroll

    -- ============================================================
    -- DOCK (bottom, Lucide icons, jump animation)
    -- ============================================================
    -- DOCK_ITEM_SIZE / DOCK_ITEM_GAP / DOCK_PAD_X must match the values used below
    local DOCK_ITEM_SIZE = 44
    local DOCK_ITEM_GAP = 6
    local DOCK_PAD_X = 12

    local dockContainer, dockFrame, dockItems, dockLayout
    if useDock then
        dockContainer = CreateGlassFrame(window, {
            Radius = 18,
            Transparency = theme.DockTransparency or theme.GlassTransparency or 0.28,
            Color = theme.Dock or theme.SecondaryBackground,
            Clip = false -- hover-magnified icons are meant to bulge slightly past the edge
        })
        dockContainer.Name = "Dock"
        -- Fixed, manually-computed size (see Window:_UpdateDockWidth). AutomaticSize chained
        -- through the glass frame's own Scale-sized children caused the dock to size itself
        -- against its own content, which is unreliable - manual width is predictable.
        dockContainer.Size = UDim2.new(0, DOCK_PAD_X * 2, 0, 62)
        dockContainer.Position = UDim2.new(0.5, 0, 1, -14)
        dockContainer.AnchorPoint = Vector2.new(0.5, 1)
        dockContainer.ZIndex = 20

        dockFrame = GetGlassBase(dockContainer)

        -- Dedicated sub-frame to hold the dock buttons + their UIListLayout. This is
        -- IMPORTANT: dockFrame ("GlassBase") also parents the Frost and Sheen decorative
        -- overlay frames created by CreateGlassFrame. A UIListLayout arranges every GuiObject
        -- child of its parent, so if the layout were placed directly on dockFrame it would
        -- also try to lay out Frost/Sheen as if they were dock icons, corrupting the dock's
        -- spacing. Keeping the layout on its own frame avoids that entirely.
        dockItems = Instance.new("Frame")
        dockItems.Name = "DockItems"
        dockItems.Size = UDim2.new(1, 0, 1, 0)
        dockItems.BackgroundTransparency = 1
        dockItems.ZIndex = 20
        dockItems.Parent = dockFrame

        local dockPad = Instance.new("UIPadding")
        dockPad.PaddingLeft = UDim.new(0, DOCK_PAD_X)
        dockPad.PaddingRight = UDim.new(0, DOCK_PAD_X)
        dockPad.PaddingTop = UDim.new(0, 8)
        dockPad.PaddingBottom = UDim.new(0, 8)
        dockPad.Parent = dockItems

        dockLayout = Instance.new("UIListLayout")
        dockLayout.FillDirection = Enum.FillDirection.Horizontal
        dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        dockLayout.Padding = UDim.new(0, DOCK_ITEM_GAP)
        dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
        dockLayout.Parent = dockItems
    end

    -- Overlay layer for floating popups (dropdown lists, the color picker board). These
    -- used to be parented inside the scrollable tab content, whose ClipsDescendants = true
    -- would cut them off - including clipping their rounded corners - whenever they
    -- extended past the visible content area. The overlay sits directly on the window's
    -- own GlassBase instead, so popups are still bounded by the window's rounded edge but
    -- are no longer clipped by the inner scroll view.
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 200
    overlay.Parent = window

    -- Positions `frame` (already parented to `overlay`) directly under `anchor`, converting
    -- from screen-space AbsolutePosition into the overlay's own offset space.
    local function AnchorOverlayFrame(frame, anchor, offsetX, offsetY)
        local x = anchor.AbsolutePosition.X - window.AbsolutePosition.X + (offsetX or 0)
        local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y - window.AbsolutePosition.Y + (offsetY or 4)
        frame.Position = UDim2.new(0, x, 0, y)
    end

    -- Window object
    local Window = {
        ScreenGui = screenGui,
        Frame = windowContainer,
        GlassBase = window, -- direct reference to the Frame named GlassBase
        TitleBar = titleBar,
        Content = contentScroll,
        Dock = dockContainer,
        Overlay = overlay,
        Tabs = {},
        TabOrder = {},
        CurrentTab = nil,
        OriginalSize = size,
        OriginalPos = windowContainer.Position,
        IsMaximized = false,
        IsMinimized = false,
        Connections = windowConnections,
        Elements = {},
        FlagElements = {},
        UseDock = useDock,
        ToggleKey = toggleKey,
        _NotifiedHidden = false,
        _PendingConfigLoad = pendingConfigLoad
    }

    -- Show/hide hotkey. Reads Window.ToggleKey live each press, so rebinding it from the
    -- Settings tab (see CreateSettingsTab) takes effect immediately without reconnecting.
    TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Window.ToggleKey then
            Window:Minimize()
        end
    end))

    -- Dragging
    local dragging, dragStart, startPos
    TrackConnection(titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = windowContainer.Position
            PlaySFX("Drag", 1.4, 0.15)
        end
    end))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            windowContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    -- Traffic light actions
    TrackConnection(closeBtn.MouseButton1Click:Connect(function()
        PlaySFX("Close", 0.95, 0.6)
        MacUI.PulseScale(closeBtn, 0.85, 0.15)
        task.delay(0.12, function()
            Window:Destroy()
        end)
    end))
    TrackConnection(minBtn.MouseButton1Click:Connect(function()
        MacUI.PulseScale(minBtn, 0.85, 0.15)
        Window:Minimize() -- plays Minimize or Restore SFX internally
    end))
    TrackConnection(maxBtn.MouseButton1Click:Connect(function()
        PlaySFX(Window.IsMaximized and "Restore" or "Maximize", Window.IsMaximized and 1.05 or 1.25, 0.55)
        MacUI.PulseScale(maxBtn, 0.85, 0.15)
        Window:Maximize()
    end))

    local function SetupHover(btn, baseColor)
        TrackConnection(btn.MouseEnter:Connect(function()
            MacUI.Tween(btn, {Time = 0.12}, {BackgroundColor3 = baseColor:Lerp(Color3.new(1,1,1), 0.18)})
        end))
        TrackConnection(btn.MouseLeave:Connect(function()
            MacUI.Tween(btn, {Time = 0.12}, {BackgroundColor3 = baseColor})
        end))
    end
    SetupHover(closeBtn, Color3.fromRGB(255, 95, 87))
    SetupHover(minBtn, Color3.fromRGB(255, 189, 46))
    SetupHover(maxBtn, Color3.fromRGB(40, 200, 64))

    -- Recolors every control already on the window when the theme changes. Controls bake
    -- their colors in as plain Color3 values at creation time (no live binding), so
    -- switching themes previously only recolored the window chrome (title bar, dock) and
    -- left every Button/Toggle/Slider/etc already on screen in the old colors - this is
    -- what "theme not working on UI" was actually describing. This walks every tracked
    -- element and swaps any color that still exactly matches a role from the OLD theme
    -- (Text, SecondaryText, TertiaryBackground, SecondaryBackground, Accent, Glass, Sheen,
    -- Border) for the same role in the new one. A control's own picked value (e.g. a
    -- ColorPicker's current color) essentially never exactly equals a theme color, so it's
    -- safely left alone.
    local function RethemeInstance(inst, oldTheme, newTheme)
        if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
            if inst.TextColor3 == oldTheme.Text then
                inst.TextColor3 = newTheme.Text
            elseif inst.TextColor3 == (oldTheme.SecondaryText) then
                inst.TextColor3 = newTheme.SecondaryText
            end
            if inst:IsA("TextBox") and inst.PlaceholderColor3 == oldTheme.SecondaryText then
                inst.PlaceholderColor3 = newTheme.SecondaryText
            end
        end
        if inst.Name == "GlassBase" then
            local old = inst.BackgroundColor3
            if old == oldTheme.TertiaryBackground then inst.BackgroundColor3 = newTheme.TertiaryBackground
            elseif old == oldTheme.SecondaryBackground then inst.BackgroundColor3 = newTheme.SecondaryBackground
            elseif old == oldTheme.Background then inst.BackgroundColor3 = newTheme.Background
            end
            local frost = inst:FindFirstChild("Frost")
            if frost then
                frost.BackgroundColor3 = newTheme.Glass or newTheme.Background
                local fg = frost:FindFirstChild("FrostGradient")
                if fg then fg.Color = ColorSequence.new(newTheme.Glass or newTheme.Background) end
            end
            local sheen = inst:FindFirstChild("Sheen")
            if sheen then sheen.BackgroundColor3 = newTheme.Sheen or Color3.new(1, 1, 1) end
            local stroke = inst:FindFirstChild("GlassStroke")
            if stroke then
                stroke.Color = newTheme.Border or Color3.fromRGB(255, 255, 255)
                stroke.Transparency = newTheme.BorderTransparency or 0.7
            end
        elseif inst:IsA("Frame") and inst.Name ~= "Frost" and inst.Name ~= "Sheen" then
            local old = inst.BackgroundColor3
            if old == oldTheme.TertiaryBackground then inst.BackgroundColor3 = newTheme.TertiaryBackground
            elseif old == oldTheme.SecondaryBackground then inst.BackgroundColor3 = newTheme.SecondaryBackground
            elseif old == oldTheme.Accent then inst.BackgroundColor3 = newTheme.Accent
            end
        end
    end

    local function RethemeTree(root, oldTheme, newTheme)
        if not root then return end
        RethemeInstance(root, oldTheme, newTheme)
        for _, inst in ipairs(root:GetDescendants()) do
            RethemeInstance(inst, oldTheme, newTheme)
        end
    end

    function Window:ApplyTheme(t)
        local oldTheme = theme
        theme = t
        if oldTheme and oldTheme ~= t then
            for _, el in ipairs(self.Elements) do
                if el.Object then RethemeTree(el.Object, oldTheme, t) end
            end
        end
        local winBase = GetGlassBase(windowContainer)
        if winBase then
            winBase.BackgroundColor3 = t.Background
            winBase.BackgroundTransparency = t.GlassTransparency or MacUI.GlassStyle.Transparency
            local stroke = winBase:FindFirstChild("GlassStroke")
            if stroke then
                stroke.Color = t.Border or Color3.fromRGB(255, 255, 255)
                stroke.Transparency = t.BorderTransparency or 0.7
            end
            local frost = winBase:FindFirstChild("Frost")
            if frost then
                frost.BackgroundColor3 = t.Glass or t.Background
            end
            local sheen = winBase:FindFirstChild("Sheen")
            if sheen then
                sheen.BackgroundColor3 = t.Sheen or Color3.fromRGB(255, 255, 255)
            end
        end

        -- Swap (or clear) the theme background image. Destroying the old holder first
        -- means a new theme with no Image.URL correctly ends up with no image at all.
        if themeImageHolder and themeImageHolder.Parent then
            themeImageHolder:Destroy()
        end
        themeImageHolder = MacUI.ApplyThemeImage(t, window)

        titleLabel.TextColor3 = t.Text
        searchBtn.ImageColor3 = t.IconColor or t.SecondaryText

        -- Dock glass + icons
        if dockContainer then
            local dockBase = GetGlassBase(dockContainer)
            if dockBase then
                dockBase.BackgroundColor3 = t.Dock or t.SecondaryBackground
                dockBase.BackgroundTransparency = t.DockTransparency or t.GlassTransparency or 0.3
                local stroke = dockBase:FindFirstChild("GlassStroke")
                if stroke then
                    stroke.Color = t.Border or Color3.fromRGB(255, 255, 255)
                    stroke.Transparency = t.BorderTransparency or 0.7
                end
            end
        end

        -- Tab / dock icon colors follow theme
        for _, tab in pairs(self.Tabs) do
            if tab.DockButton then
                local icon = tab.DockButton:FindFirstChild("Icon")
                local indicator = tab.DockButton:FindFirstChild("Indicator")
                if icon then
                    if self.CurrentTab == tab then
                        icon.ImageColor3 = t.Accent
                    else
                        icon.ImageColor3 = t.TabInactive or t.SecondaryText
                    end
                end
                if indicator then
                    indicator.BackgroundColor3 = t.Accent
                end
            end
        end

        -- Scrollbar
        if contentScroll then
            contentScroll.ScrollBarImageColor3 = t.Border
        end
    end

    -- Minimize now actually hides the hub (it used to shrink to a small pill that stayed
    -- on screen, which read as broken/half-hidden). The first time it's hidden, it notifies
    -- the person once with the key that brings it back; it won't repeat that notification
    -- on later hides. The same key (Window.ToggleKey, rebindable from Settings) calls this
    -- same method, so pressing it or clicking the dock-minimize button behave identically.
    function Window:Minimize()
        if self.IsMinimized then
            PlaySFX("Restore", 1.15, 0.5)
            windowContainer.Visible = true
            windowContainer.Size = UDim2.new(0, 0, 0, 0)
            MacUI.Tween(windowContainer, {Time = 0.3, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out}, {
                Size = self.OriginalSize
            })
            self.IsMinimized = false
        else
            PlaySFX("Minimize", 0.85, 0.5)
            self.OriginalSize = windowContainer.Size
            local t = MacUI.Tween(windowContainer, {Time = 0.25, EasingStyle = Enum.EasingStyle.Quint}, {
                Size = UDim2.new(0, 0, 0, 0)
            })
            local function HideNow()
                windowContainer.Visible = false
            end
            if t then t.Completed:Connect(HideNow) else HideNow() end
            self.IsMinimized = true

            if not self._NotifiedHidden then
                self._NotifiedHidden = true
                MacUI:Notify({
                    Title = "Hub Hidden",
                    Content = "Press " .. self.ToggleKey.Name .. " to show it again.",
                    Icon = "eye-off",
                    Duration = 5
                })
            end
        end
    end

    function Window:Maximize()
        if self.IsMaximized then
            -- Restore
            screenGui.DisplayOrder = 100
            MacUI.Tween(windowContainer, {
                Time = 0.42,
                EasingStyle = Enum.EasingStyle.Quint,
                EasingDirection = Enum.EasingDirection.Out
            }, {
                Size = self.OriginalSize,
                Position = self.OriginalPos
            })
            self.IsMaximized = false
        else
            -- Maximize: raise layer + sliding animation
            self.OriginalSize = windowContainer.Size
            self.OriginalPos = windowContainer.Position
            screenGui.DisplayOrder = 99999

            -- Slide + expand from current position
            MacUI.Tween(windowContainer, {
                Time = 0.45,
                EasingStyle = Enum.EasingStyle.Quint,
                EasingDirection = Enum.EasingDirection.Out
            }, {
                Size = UDim2.new(1, -32, 1, -32),
                Position = UDim2.new(0, 16, 0, 16)
            })
            self.IsMaximized = true
        end
    end

    -- Toggle is now just an alias for Minimize - a single hide/show path (with the
    -- animation and one-time notice) instead of two inconsistent ones.
    function Window:Toggle()
        self:Minimize()
    end

    function Window:Destroy()
        DisconnectAll(self.Connections)
        if self.ScreenGui then
            -- Fade out
            MacUI.Tween(windowContainer, {Time = 0.25}, {
                Size = UDim2.new(0, 0, 0, 0)
            })
            task.delay(0.28, function()
                if self.ScreenGui then
                    self.ScreenGui:Destroy()
                end
            end)
        end
        for i, w in ipairs(MacUI.Windows) do
            if w == self then
                table.remove(MacUI.Windows, i)
                break
            end
        end
    end

    -- Recompute + smoothly animate the dock's width to fit its current icon count
    function Window:_UpdateDockWidth()
        if not dockContainer then return end
        local count = #self.TabOrder
        if count < 1 then count = 1 end
        local width = (DOCK_PAD_X * 2) + (DOCK_ITEM_SIZE * count) + (DOCK_ITEM_GAP * math.max(count - 1, 0))
        MacUI.Tween(dockContainer, {Time = 0.3, EasingStyle = Enum.EasingStyle.Quint}, {
            Size = UDim2.new(0, width, 0, 62)
        })
    end

    -- Re-applies MacUI.Config.Data onto every flagged control currently on the window.
    -- Controls that are created after this runs apply their own saved value immediately
    -- on creation (see the Flag handling inside each CreateX function), so this is mainly
    -- useful for a manual "Reload Config" button or re-syncing after MacUI:LoadConfig().
    function Window:ApplyConfig()
        for _, el in ipairs(self.Elements) do
            if el.Flag and el.Set and MacUI.Config.Data[el.Flag] ~= nil then
                local val = MacUI.Config.Data[el.Flag]
                if el.Type == "ColorPicker" and type(val) == "table" then
                    val = Color3.fromRGB(val.r or 0, val.g or 0, val.b or 0)
                end
                pcall(el.Set, val)
            end
        end
    end

    -- Convenience wrapper: loads config from disk, then applies it to existing controls.
    function Window:LoadConfig()
        MacUI:LoadConfig()
        self:ApplyConfig()
    end

    function Window:SaveConfig()
        MacUI:SaveConfig()
    end

    -- Builds a ready-made "Settings" tab: theme switcher, reduced-motion toggle, and
    -- (when config saving is enabled) Save / Reload / Reset buttons.
    function Window:CreateSettingsTab(opts)
        opts = opts or {}
        local tab = self:CreateTab({Name = opts.Name or "Settings", Icon = opts.Icon or "settings"})

        local appearance = tab:CreateSection("Appearance")
        local themeNames = {}
        for themeName in pairs(MacUI.Themes) do
            table.insert(themeNames, themeName)
        end
        table.sort(themeNames)
        appearance:CreateDropdown({
            Name = "Theme",
            Options = themeNames,
            CurrentOption = MacUI.CurrentTheme,
            Callback = function(choice)
                MacUI:SetTheme(choice)
            end
        })

        local accessibility = tab:CreateSection("Accessibility")
        accessibility:CreateToggle({
            Name = "Reduce Motion",
            CurrentValue = MacUI.Accessibility.ReducedMotion,
            Callback = function(val)
                MacUI:SetAccessibility({ReducedMotion = val})
            end
        })
        accessibility:CreateSlider({
            Name = "SFX Volume",
            Range = {0, 100},
            Increment = 5,
            CurrentValue = math.floor((MacUI.SFXVolume or 0.55) * 100),
            Callback = function(val)
                MacUI:SetSFXVolume(val / 100)
            end
        })
        accessibility:CreateKeybind({
            Name = "Hide/Show Hub",
            CurrentKeybind = self.ToggleKey,
            OnChange = function(key)
                self.ToggleKey = key
            end
        })

        if MacUI.Config.Folder and MacUI.Config.File then
            local configSection = tab:CreateSection("Configuration")
            configSection:CreateButton({
                Name = "Save Config",
                Description = "Writes current settings to " .. MacUI.Config.Folder .. "/" .. MacUI.Config.File .. ".json",
                Callback = function()
                    MacUI:SaveConfig()
                    MacUI:Notify({Title = "Config Saved", Content = "Your settings were saved.", Icon = "check", Duration = 2.5})
                end
            })
            configSection:CreateButton({
                Name = "Reload Config",
                Description = "Re-reads the saved file and applies it to this window",
                Callback = function()
                    self:LoadConfig()
                    MacUI:Notify({Title = "Config Reloaded", Content = "Settings re-applied.", Icon = "refresh-cw", Duration = 2.5})
                end
            })
            configSection:CreateButton({
                Name = "Reset Config",
                Description = "Clears all saved values",
                Callback = function()
                    MacUI:ResetConfig()
                    MacUI:Notify({Title = "Config Reset", Content = "Saved settings cleared.", Icon = "trash", Duration = 2.5})
                end
            })
        end

        return tab
    end

    -- ============================================================
    -- TABS (with Dock integration)
    -- ============================================================
    function Window:CreateTab(opts)
        opts = opts or {}
        local tabName = opts.Name or "Tab"
        local iconName = opts.Icon or "home"

        local tabContent = Instance.new("Frame")
        tabContent.Name = tabName
        tabContent.Size = UDim2.new(1, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.AutomaticSize = Enum.AutomaticSize.Y
        tabContent.Parent = contentScroll

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Padding = UDim.new(0, 14)
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Parent = tabContent

        local Tab = {
            Content = tabContent,
            Name = tabName,
            Icon = iconName,
            Sections = {},
            Window = Window,
            DockButton = nil
        }

        local function SelectTab()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                if t.DockButton then
                    local icon = t.DockIcon or t.DockButton:FindFirstChild("Icon")
                    local indicator = t.DockButton:FindFirstChild("Indicator")
                    if icon then
                        MacUI.Tween(icon, {Time = 0.2}, {
                            ImageColor3 = theme.TabInactive or theme.SecondaryText
                        })
                    end
                    if indicator then
                        MacUI.Tween(indicator, {Time = 0.2}, {BackgroundTransparency = 1})
                    end
                end
            end
            tabContent.Visible = true
            Window.CurrentTab = Tab

            -- Content switch animation: fade/slide the newly shown tab in
            if not MacUI.Accessibility.ReducedMotion then
                local contentScale = tabContent:FindFirstChildOfClass("UIScale")
                if not contentScale then
                    contentScale = Instance.new("UIScale")
                    contentScale.Parent = tabContent
                end
                contentScale.Scale = 0.98
                local original = tabContent.Position
                tabContent.Position = original + UDim2.new(0, 0, 0, 10)
                MacUI.Tween(contentScale, {Time = 0.26, EasingStyle = Enum.EasingStyle.Quint}, {Scale = 1})
                MacUI.Tween(tabContent, {Time = 0.26, EasingStyle = Enum.EasingStyle.Quint}, {Position = original})
            end

            if Tab.DockButton then
                -- Animate the Icon (a plain child of the dock button) rather than the
                -- DockButton itself. DockButton's Position is owned by the dock's
                -- UIListLayout; tweening it directly produced no visible motion, which is
                -- why the dock icons never appeared to "jump". The icon is a free child of
                -- the button and isn't managed by any layout, so it animates cleanly.
                local icon = Tab.DockIcon or Tab.DockButton:FindFirstChild("Icon")
                local indicator = Tab.DockButton:FindFirstChild("Indicator")
                if icon then
                    PlaySFX("Tab", 1.1, 0.4)
                    PlaySFX("Dock", 1.15, 0.35)
                    MacUI.Tween(icon, {Time = 0.2}, {ImageColor3 = theme.Accent})
                    MacUI.Bounce(icon, 14, 0.42)
                end
                if indicator then
                    MacUI.Tween(indicator, {Time = 0.2}, {BackgroundTransparency = 0})
                end
            end
        end

        Window.Tabs[tabName] = Tab
        table.insert(Window.TabOrder, Tab)

        -- Dock button
        if useDock and dockItems then
            local dockBtn = Instance.new("TextButton")
            dockBtn.Name = tabName
            dockBtn.Size = UDim2.new(0, DOCK_ITEM_SIZE, 0, DOCK_ITEM_SIZE)
            dockBtn.BackgroundTransparency = 1
            dockBtn.Text = ""
            dockBtn.AutoButtonColor = false
            dockBtn.ZIndex = 21
            dockBtn.Parent = dockItems

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.Size = UDim2.new(0, 26, 0, 26)
            icon.Position = UDim2.new(0.5, -13, 0.5, -15)
            icon.BackgroundTransparency = 1
            MacUI.ApplyIcon(icon, iconName)
            icon.ImageColor3 = theme.TabInactive or theme.SecondaryText
            icon.ZIndex = 22
            icon.Parent = dockBtn

            local indicator = Instance.new("Frame")
            indicator.Name = "Indicator"
            indicator.Size = UDim2.new(0, 5, 0, 5)
            indicator.Position = UDim2.new(0.5, -2.5, 1, -6)
            indicator.BackgroundColor3 = theme.Accent
            indicator.BackgroundTransparency = 1
            indicator.ZIndex = 22
            indicator.Parent = dockBtn

            local indCorner = Instance.new("UICorner")
            indCorner.CornerRadius = UDim.new(1, 0)
            indCorner.Parent = indicator

            -- Hover magnification (classic dock feel)
            TrackConnection(dockBtn.MouseEnter:Connect(function()
                if Window.CurrentTab ~= Tab then
                    MacUI.Tween(icon, {Time = 0.18, EasingStyle = Enum.EasingStyle.Back}, {
                        Size = UDim2.new(0, 30, 0, 30),
                        Position = UDim2.new(0.5, -15, 0.5, -18)
                    })
                end
            end))
            TrackConnection(dockBtn.MouseLeave:Connect(function()
                if Window.CurrentTab ~= Tab then
                    MacUI.Tween(icon, {Time = 0.18}, {
                        Size = UDim2.new(0, 26, 0, 26),
                        Position = UDim2.new(0.5, -13, 0.5, -15)
                    })
                end
            end))
            TrackConnection(dockBtn.MouseButton1Click:Connect(function()
                MacUI.PressSquish(icon, 0.82, 0.2)
                SelectTab()
            end))

            Tab.DockButton = dockBtn
            Tab.DockIcon = icon

            MacUI.PopIn(icon, (#Window.TabOrder - 1) * 0.04)
            Window:_UpdateDockWidth()
        end

        function Tab:CreateSection(sectionName)
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(1, 0, 0, 0)
            sectionFrame.BackgroundTransparency = 1
            sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            sectionFrame.Parent = tabContent

            local sectionTitle = Instance.new("TextLabel")
            sectionTitle.Size = UDim2.new(1, 0, 0, 22)
            sectionTitle.BackgroundTransparency = 1
            sectionTitle.Text = sectionName
            sectionTitle.TextColor3 = theme.SecondaryText
            sectionTitle.Font = Enum.Font.GothamMedium
            sectionTitle.TextSize = 13
            sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            sectionTitle.Parent = sectionFrame

            local sectionContent = Instance.new("Frame")
            sectionContent.Size = UDim2.new(1, 0, 0, 0)
            sectionContent.Position = UDim2.new(0, 0, 0, 28)
            sectionContent.BackgroundTransparency = 1
            sectionContent.AutomaticSize = Enum.AutomaticSize.Y
            sectionContent.Parent = sectionFrame

            local secLayout = Instance.new("UIListLayout")
            secLayout.Padding = UDim.new(0, 10)
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Parent = sectionContent

            local Section = {
                Frame = sectionFrame,
                Content = sectionContent,
                Name = sectionName
            }

            -- Button
            function Section:CreateButton(opts)
                opts = opts or {}
                local btnContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                btnContainer.Size = UDim2.new(1, 0, 0, opts.Description and 54 or 40)

                local btnBase = GetGlassBase(btnContainer)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.Parent = btnBase

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -20, opts.Description and 0 or 1, opts.Description and 22 or 0)
                lbl.Position = UDim2.new(0, 14, 0, opts.Description and 8 or 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Button"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = btn

                if opts.Description then
                    local desc = Instance.new("TextLabel")
                    desc.Size = UDim2.new(1, -20, 0, 18)
                    desc.Position = UDim2.new(0, 14, 0, 30)
                    desc.BackgroundTransparency = 1
                    desc.Text = opts.Description
                    desc.TextColor3 = theme.SecondaryText
                    desc.Font = Enum.Font.Gotham
                    desc.TextSize = 12
                    desc.TextXAlignment = Enum.TextXAlignment.Left
                    desc.Parent = btn
                end

                local btnScale = Instance.new("UIScale")
                btnScale.Parent = btnContainer
                TrackConnection(btn.MouseEnter:Connect(function()
                    PlaySFX("Hover", 1.3, 0.25)
                    MacUI.Tween(btnBase, {Time = 0.15}, {BackgroundTransparency = 0.15})
                    MacUI.Tween(btnScale, {Time = 0.15, EasingStyle = Enum.EasingStyle.Quint}, {Scale = 1.015})
                end))
                TrackConnection(btn.MouseLeave:Connect(function()
                    MacUI.Tween(btnBase, {Time = 0.15}, {BackgroundTransparency = 0.35})
                    MacUI.Tween(btnScale, {Time = 0.15, EasingStyle = Enum.EasingStyle.Quint}, {Scale = 1})
                end))
                TrackConnection(btn.MouseButton1Click:Connect(function()
                    PlaySFX("Click", 1.0, 0.55)
                    MacUI.PulseScale(btnContainer, 0.97, 0.18)
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "Button", Name = opts.Name, Object = btnContainer})
                return btn
            end

            -- Toggle (macOS style)
            function Section:CreateToggle(opts)
                opts = opts or {}
                local flag = opts.Flag or opts.Name
                local current = opts.CurrentValue or false
                local hasSaved = flag ~= nil and MacUI.Config.Data[flag] ~= nil
                if hasSaved then current = MacUI.Config.Data[flag] end

                local rowContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                rowContainer.Size = UDim2.new(1, 0, 0, 44)
                local row = GetGlassBase(rowContainer)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -90, 1, 0)
                lbl.Position = UDim2.new(0, 14, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Toggle"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(0, 44, 0, 26)
                track.Position = UDim2.new(1, -58, 0.5, -13)
                track.BackgroundColor3 = current and theme.Accent or theme.TertiaryBackground
                track.Parent = row

                local trackCorner = Instance.new("UICorner")
                trackCorner.CornerRadius = UDim.new(1, 0)
                trackCorner.Parent = track

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 22, 0, 22)
                knob.Position = current and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.Parent = track

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local function SetState(val, silent)
                    current = val
                    if not silent then
                        PlaySFX(val and "ToggleOn" or "ToggleOff", val and 1.2 or 0.9, 0.5)
                    end
                    MacUI.Tween(track, {Time = 0.22}, {BackgroundColor3 = val and theme.Accent or theme.TertiaryBackground})
                    MacUI.Tween(knob, {Time = 0.3, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out}, {
                        Position = val and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
                    })
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, val)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                    if flag then MacUI.Config.Data[flag] = val end
                end

                TrackConnection(track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        MacUI.PressSquish(knob, 0.8, 0.16)
                        SetState(not current)
                    end
                end))

                -- Apply a config value restored for this flag without re-animating visuals
                -- that already render the restored state - just fire the real effect.
                if hasSaved and opts.Callback then
                    local ok, err = pcall(opts.Callback, current)
                    if not ok then warn("[MacUI] Callback error:", err) end
                end

                table.insert(Window.Elements, {Type = "Toggle", Name = opts.Name, Flag = flag, Set = SetState, Object = rowContainer})
                return {Set = SetState, Get = function() return current end}
            end

            -- Slider
            function Section:CreateSlider(opts)
                opts = opts or {}
                local flag = opts.Flag or opts.Name
                local min, max = opts.Range[1] or 0, opts.Range[2] or 100
                local increment = opts.Increment or 1
                local current = opts.CurrentValue or min
                local hasSaved = flag ~= nil and MacUI.Config.Data[flag] ~= nil
                if hasSaved then current = MacUI.Config.Data[flag] end

                local rowContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                rowContainer.Size = UDim2.new(1, 0, 0, 60)
                local row = GetGlassBase(rowContainer)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.7, -14, 0, 20)
                lbl.Position = UDim2.new(0, 14, 0, 8)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Slider"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local valueLbl = Instance.new("TextLabel")
                valueLbl.Size = UDim2.new(0.3, -14, 0, 20)
                valueLbl.Position = UDim2.new(0.7, 0, 0, 8)
                valueLbl.BackgroundTransparency = 1
                valueLbl.Text = tostring(current)
                valueLbl.TextColor3 = theme.SecondaryText
                valueLbl.Font = Enum.Font.Gotham
                valueLbl.TextSize = 13
                valueLbl.TextXAlignment = Enum.TextXAlignment.Right
                valueLbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, -28, 0, 6)
                track.Position = UDim2.new(0, 14, 0, 40)
                track.BackgroundColor3 = theme.TertiaryBackground
                track.Parent = row

                local trackCorner = Instance.new("UICorner")
                trackCorner.CornerRadius = UDim.new(1, 0)
                trackCorner.Parent = track

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
                fill.BackgroundColor3 = theme.Accent
                fill.Parent = track

                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(1, 0)
                fillCorner.Parent = fill

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 16, 0, 16)
                knob.Position = UDim2.new((current - min) / (max - min), -8, 0.5, -8)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.Parent = track

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local sliding = false
                local lastTickVal = current
                local function Update(val, silent)
                    val = math.clamp(math.floor(val / increment + 0.5) * increment, min, max)
                    local changed = val ~= current
                    current = val
                    local alpha = (val - min) / (max - min)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, -8, 0.5, -8)
                    valueLbl.Text = tostring(val)
                    if changed and not silent then
                        -- Soft tick only when the stepped value actually moves
                        if val ~= lastTickVal then
                            lastTickVal = val
                            PlaySFX("Slider", 0.95 + (alpha * 0.25), 0.22)
                        end
                        if opts.Callback then
                            local ok, err = pcall(opts.Callback, val)
                            if not ok then warn("[MacUI] Callback error:", err) end
                        end
                    end
                    if flag then MacUI.Config.Data[flag] = val end
                end

                TrackConnection(track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        MacUI.Tween(knob, {Time = 0.14, EasingStyle = Enum.EasingStyle.Back}, {Size = UDim2.new(0, 20, 0, 20)})
                        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        Update(min + rel * (max - min))
                    end
                end))
                TrackConnection(UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        Update(min + rel * (max - min))
                    end
                end))
                TrackConnection(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                        MacUI.Tween(knob, {Time = 0.18, EasingStyle = Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 16, 0, 16)})
                    end
                end))

                if hasSaved and opts.Callback then
                    local ok, err = pcall(opts.Callback, current)
                    if not ok then warn("[MacUI] Callback error:", err) end
                end

                table.insert(Window.Elements, {Type = "Slider", Name = opts.Name, Flag = flag, Set = Update, Object = rowContainer})
                return {Set = Update, Get = function() return current end}
            end

            -- Dropdown
            function Section:CreateDropdown(opts)
                opts = opts or {}
                local flag = opts.Flag or opts.Name
                local options = opts.Options or {}
                local current = opts.CurrentOption or options[1]
                local hasSaved = flag ~= nil and MacUI.Config.Data[flag] ~= nil
                if hasSaved then current = MacUI.Config.Data[flag] end

                local rowContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                rowContainer.Size = UDim2.new(1, 0, 0, 44)
                local row = GetGlassBase(rowContainer)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.4, -14, 1, 0)
                lbl.Position = UDim2.new(0, 14, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Dropdown"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local dropBtn = Instance.new("TextButton")
                dropBtn.Size = UDim2.new(0.5, 0, 0, 30)
                dropBtn.Position = UDim2.new(0.45, 0, 0.5, -15)
                dropBtn.BackgroundColor3 = theme.TertiaryBackground
                dropBtn.BackgroundTransparency = 0.3
                dropBtn.Text = current or ""
                dropBtn.TextColor3 = theme.Text
                dropBtn.Font = Enum.Font.Gotham
                dropBtn.TextSize = 13
                dropBtn.AutoButtonColor = false
                dropBtn.Parent = row

                local dropCorner = Instance.new("UICorner")
                dropCorner.CornerRadius = UDim.new(0, 8)
                dropCorner.Parent = dropBtn

                local open = false
                local listFrame

                local function SelectOption(opt, silent)
                    current = opt
                    dropBtn.Text = opt
                    if not silent then
                        PlaySFX("Dropdown", 1.15, 0.4)
                        if opts.Callback then
                            local ok, err = pcall(opts.Callback, opt)
                            if not ok then warn("[MacUI] Callback error:", err) end
                        end
                    end
                    if flag then MacUI.Config.Data[flag] = opt end
                end

                TrackConnection(dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        PlaySFX("Dropdown", 0.95, 0.35)
                        -- Parented to the window's overlay layer (not `row`) so the list
                        -- isn't clipped - rounded corners included - by the scrollable tab
                        -- content it would otherwise sit inside.
                        listFrame = CreateGlassFrame(Window.Overlay, {Radius = 8, Transparency = 0.08, Color = theme.SecondaryBackground})
                        listFrame.Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, math.min(#options, 6) * 30)
                        listFrame.ZIndex = 50
                        AnchorOverlayFrame(listFrame, dropBtn)
                        local listBase = GetGlassBase(listFrame)
                        listBase.ClipsDescendants = true

                        local listScroll = Instance.new("ScrollingFrame")
                        listScroll.Size = UDim2.new(1, 0, 1, 0)
                        listScroll.BackgroundTransparency = 1
                        listScroll.BorderSizePixel = 0
                        listScroll.ScrollBarThickness = 3
                        listScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
                        listScroll.ZIndex = 51
                        listScroll.Parent = listBase

                        for i, opt in ipairs(options) do
                            local item = Instance.new("TextButton")
                            item.Size = UDim2.new(1, 0, 0, 30)
                            item.Position = UDim2.new(0, 0, 0, (i-1)*30)
                            item.BackgroundTransparency = (opt == current) and 0.85 or 1
                            item.BackgroundColor3 = theme.Accent
                            item.Text = opt
                            item.TextColor3 = theme.Text
                            item.Font = Enum.Font.Gotham
                            item.TextSize = 13
                            item.AutoButtonColor = false
                            item.ZIndex = 52
                            item.Parent = listScroll
                            TrackConnection(item.MouseEnter:Connect(function()
                                MacUI.Tween(item, {Time = 0.1}, {BackgroundTransparency = 0.78})
                            end))
                            TrackConnection(item.MouseLeave:Connect(function()
                                MacUI.Tween(item, {Time = 0.1}, {BackgroundTransparency = (opt == current) and 0.85 or 1})
                            end))
                            TrackConnection(item.MouseButton1Click:Connect(function()
                                SelectOption(opt)
                                if listFrame then listFrame:Destroy() end
                                open = false
                            end))
                        end
                    else
                        if listFrame then listFrame:Destroy() end
                    end
                end))

                if hasSaved and opts.Callback then
                    local ok, err = pcall(opts.Callback, current)
                    if not ok then warn("[MacUI] Callback error:", err) end
                end

                table.insert(Window.Elements, {Type = "Dropdown", Name = opts.Name, Flag = flag, Set = SelectOption, Object = rowContainer})
                return {Set = function(v) SelectOption(v, true) end, Get = function() return current end}
            end

            -- Input
            function Section:CreateInput(opts)
                opts = opts or {}
                local flag = opts.Flag or opts.Name
                local hasSaved = flag ~= nil and type(MacUI.Config.Data[flag]) == "string"

                local rowContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                rowContainer.Size = UDim2.new(1, 0, 0, 44)
                local row = GetGlassBase(rowContainer)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.35, -14, 1, 0)
                lbl.Position = UDim2.new(0, 14, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Input"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.56, 0, 0, 30)
                box.Position = UDim2.new(0.4, 0, 0.5, -15)
                box.BackgroundColor3 = theme.TertiaryBackground
                box.BackgroundTransparency = 0.3
                box.Text = hasSaved and MacUI.Config.Data[flag] or ""
                box.PlaceholderText = opts.PlaceholderText or "Enter text..."
                box.TextColor3 = theme.Text
                box.PlaceholderColor3 = theme.SecondaryText
                box.Font = Enum.Font.Gotham
                box.TextSize = 13
                box.ClearTextOnFocus = false
                box.Parent = row

                local boxCorner = Instance.new("UICorner")
                boxCorner.CornerRadius = UDim.new(0, 8)
                boxCorner.Parent = box

                local function Commit(fireCallback)
                    if fireCallback and opts.Callback then
                        local ok, err = pcall(opts.Callback, box.Text)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                    if flag then MacUI.Config.Data[flag] = box.Text end
                end

                TrackConnection(box.Focused:Connect(function()
                    PlaySFX("Focus", 1.2, 0.28)
                end))
                TrackConnection(box:GetPropertyChangedSignal("Text"):Connect(function()
                    if box:IsFocused() then
                        PlaySFX("Type", 1.35, 0.18)
                    end
                end))
                TrackConnection(box.FocusLost:Connect(function()
                    Commit(true)
                end))

                if hasSaved then
                    Commit(opts.Callback ~= nil)
                end

                table.insert(Window.Elements, {Type = "Input", Name = opts.Name, Flag = flag, Set = function(v) box.Text = v; Commit(false) end, Object = rowContainer})
                return box
            end

            -- Label
            function Section:CreateLabel(opts)
                opts = opts or {}
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 24)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Label"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = sectionContent
                table.insert(Window.Elements, {Type = "Label", Name = opts.Name, Object = lbl})
                return lbl
            end

            -- Paragraph (liquid glass card). Layers = false here: Frost/Sheen are Scale-sized
            -- to the base, which would make AutomaticSize circular (see CreateGlassFrame).
            -- The card still reads as glass from its translucent fill + border stroke.
            function Section:CreateParagraph(opts)
                opts = opts or {}
                local cardContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground,
                    Layers = false
                })
                cardContainer.Size = UDim2.new(1, 0, 0, 0)
                cardContainer.AutomaticSize = Enum.AutomaticSize.Y
                local frame = GetGlassBase(cardContainer)
                frame.AutomaticSize = Enum.AutomaticSize.Y

                local pad = Instance.new("UIPadding")
                pad.PaddingTop = UDim.new(0, 12)
                pad.PaddingBottom = UDim.new(0, 12)
                pad.PaddingLeft = UDim.new(0, 14)
                pad.PaddingRight = UDim.new(0, 14)
                pad.Parent = frame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 20)
                title.BackgroundTransparency = 1
                title.Text = opts.Title or ""
                title.TextColor3 = theme.Text
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 14
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = frame

                local contentLbl = Instance.new("TextLabel")
                contentLbl.Size = UDim2.new(1, 0, 0, 0)
                contentLbl.Position = UDim2.new(0, 0, 0, 24)
                contentLbl.BackgroundTransparency = 1
                contentLbl.Text = opts.Content or ""
                contentLbl.TextColor3 = theme.SecondaryText
                contentLbl.Font = Enum.Font.Gotham
                contentLbl.TextSize = 13
                contentLbl.TextXAlignment = Enum.TextXAlignment.Left
                contentLbl.TextWrapped = true
                contentLbl.AutomaticSize = Enum.AutomaticSize.Y
                contentLbl.Parent = frame

                table.insert(Window.Elements, {Type = "Paragraph", Name = opts.Title, Object = cardContainer})
                return frame
            end

            -- Keybind
            function Section:CreateKeybind(opts)
                opts = opts or {}
                local flag = opts.Flag or opts.Name
                local current = opts.CurrentKeybind or Enum.KeyCode.RightShift
                local saved = flag and MacUI.Config.Data[flag]
                if type(saved) == "string" then
                    local ok, keyEnum = pcall(function() return Enum.KeyCode[saved] end)
                    if ok and keyEnum then current = keyEnum end
                end

                local rowContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                rowContainer.Size = UDim2.new(1, 0, 0, 44)
                local row = GetGlassBase(rowContainer)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, -14, 1, 0)
                lbl.Position = UDim2.new(0, 14, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Keybind"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local keyBtn = Instance.new("TextButton")
                keyBtn.Size = UDim2.new(0, 90, 0, 28)
                keyBtn.Position = UDim2.new(1, -104, 0.5, -14)
                keyBtn.BackgroundColor3 = theme.TertiaryBackground
                keyBtn.BackgroundTransparency = 0.3
                keyBtn.Text = current.Name
                keyBtn.TextColor3 = theme.Text
                keyBtn.Font = Enum.Font.Gotham
                keyBtn.TextSize = 12
                keyBtn.AutoButtonColor = false
                keyBtn.Parent = row

                local kc = Instance.new("UICorner")
                kc.CornerRadius = UDim.new(0, 6)
                kc.Parent = keyBtn

                local listening = false
                TrackConnection(keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text = "..."
                end))
                TrackConnection(UserInputService.InputBegan:Connect(function(input, gp)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        keyBtn.Text = current.Name
                        listening = false
                        if flag then MacUI.Config.Data[flag] = current.Name end
                        -- OnChange fires when the binding itself changes (rebinding), as
                        -- opposed to Callback, which fires each time the bound key is
                        -- pressed. Use OnChange when something else (like Window.ToggleKey)
                        -- needs to track which key is currently assigned.
                        if opts.OnChange then
                            local ok, err = pcall(opts.OnChange, current)
                            if not ok then warn("[MacUI] OnChange error:", err) end
                        end
                    end
                    if not gp and input.KeyCode == current and opts.Callback then
                        local ok, err = pcall(opts.Callback)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {
                    Type = "Keybind", Name = opts.Name, Flag = flag,
                    Set = function(v)
                        if typeof(v) == "string" then v = Enum.KeyCode[v] end
                        current = v
                        keyBtn.Text = current.Name
                    end,
                    Object = rowContainer
                })
                return {Get = function() return current end}
            end

            -- Color Picker (simplified cycle)
            -- Color Picker: click the swatch to open a real hue + saturation/value board and
            -- drag to pick a color, instead of cycling a fixed 5-color palette.
            function Section:CreateColorPicker(opts)
                opts = opts or {}
                local flag = opts.Flag or opts.Name
                local current = opts.Color or Color3.fromRGB(0, 122, 255)
                local saved = flag and MacUI.Config.Data[flag]
                if type(saved) == "table" and saved.r then
                    current = Color3.fromRGB(saved.r, saved.g, saved.b)
                end
                local hue, sat, val = Color3.toHSV(current)

                local rowContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.35,
                    Color = theme.TertiaryBackground
                })
                rowContainer.Size = UDim2.new(1, 0, 0, 44)
                local row = GetGlassBase(rowContainer)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, -14, 1, 0)
                lbl.Position = UDim2.new(0, 14, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Color"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local swatchContainer = CreateGlassFrame(row, {Radius = 6, Transparency = 0, Color = current, Layers = false})
                swatchContainer.Size = UDim2.new(0, 36, 0, 24)
                swatchContainer.Position = UDim2.new(1, -50, 0.5, -12)
                local swatchBase = GetGlassBase(swatchContainer)
                local swatchBtn = Instance.new("TextButton")
                swatchBtn.Size = UDim2.new(1, 0, 1, 0)
                swatchBtn.BackgroundTransparency = 1
                swatchBtn.Text = ""
                swatchBtn.Parent = swatchBase

                local open = false
                local panel

                local function UpdateVisual()
                    current = Color3.fromHSV(hue, sat, val)
                    swatchBase.BackgroundColor3 = current
                end

                local function Commit()
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, current)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                    if flag then
                        MacUI.Config.Data[flag] = {
                            r = math.floor(current.R * 255 + 0.5),
                            g = math.floor(current.G * 255 + 0.5),
                            b = math.floor(current.B * 255 + 0.5)
                        }
                    end
                end

                local function ClosePanel()
                    if panel then panel:Destroy(); panel = nil end
                    open = false
                end

                local function OpenPanel()
                    -- Parented to the window's overlay layer so the board isn't clipped by
                    -- the scrollable tab content (same fix as the dropdown list above).
                    panel = CreateGlassFrame(Window.Overlay, {Radius = 12, Transparency = 0.06, Color = theme.SecondaryBackground})
                    panel.Size = UDim2.new(0, 190, 0, 152)
                    panel.ZIndex = 60
                    -- Right-align the panel's edge with the swatch's edge (panel is wider).
                    AnchorOverlayFrame(panel, swatchContainer, swatchContainer.AbsoluteSize.X - 190)
                    local base = GetGlassBase(panel)
                    base.ClipsDescendants = true

                    local svSquare = Instance.new("Frame")
                    svSquare.Size = UDim2.new(1, -16, 0, 96)
                    svSquare.Position = UDim2.new(0, 8, 0, 8)
                    svSquare.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    svSquare.BorderSizePixel = 0
                    svSquare.ZIndex = 61
                    svSquare.Parent = base
                    local svCorner = Instance.new("UICorner")
                    svCorner.CornerRadius = UDim.new(0, 8)
                    svCorner.Parent = svSquare

                    local whiteOverlay = Instance.new("Frame")
                    whiteOverlay.Size = UDim2.new(1, 0, 1, 0)
                    whiteOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
                    whiteOverlay.BorderSizePixel = 0
                    whiteOverlay.ZIndex = 62
                    whiteOverlay.Parent = svSquare
                    local wc = Instance.new("UICorner")
                    wc.CornerRadius = UDim.new(0, 8)
                    wc.Parent = whiteOverlay
                    local wg = Instance.new("UIGradient")
                    wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
                    wg.Parent = whiteOverlay

                    local blackOverlay = Instance.new("Frame")
                    blackOverlay.Size = UDim2.new(1, 0, 1, 0)
                    blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
                    blackOverlay.BorderSizePixel = 0
                    blackOverlay.ZIndex = 63
                    blackOverlay.Parent = svSquare
                    local bc = Instance.new("UICorner")
                    bc.CornerRadius = UDim.new(0, 8)
                    bc.Parent = blackOverlay
                    local bg = Instance.new("UIGradient")
                    bg.Rotation = 90
                    bg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
                    bg.Parent = blackOverlay

                    local svCursor = Instance.new("Frame")
                    svCursor.Size = UDim2.new(0, 12, 0, 12)
                    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                    svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                    svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
                    svCursor.ZIndex = 64
                    svCursor.Parent = svSquare
                    local svcc = Instance.new("UICorner")
                    svcc.CornerRadius = UDim.new(1, 0)
                    svcc.Parent = svCursor
                    local svcs = Instance.new("UIStroke")
                    svcs.Color = Color3.new(0, 0, 0)
                    svcs.Thickness = 1.5
                    svcs.Parent = svCursor

                    local hueStrip = Instance.new("Frame")
                    hueStrip.Size = UDim2.new(1, -16, 0, 16)
                    hueStrip.Position = UDim2.new(0, 8, 0, 112)
                    hueStrip.BorderSizePixel = 0
                    hueStrip.ZIndex = 61
                    hueStrip.Parent = base
                    local hueCorner = Instance.new("UICorner")
                    hueCorner.CornerRadius = UDim.new(0, 8)
                    hueCorner.Parent = hueStrip
                    local hueGradient = Instance.new("UIGradient")
                    local hueKeypoints = {}
                    for i = 0, 6 do
                        table.insert(hueKeypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
                    end
                    hueGradient.Color = ColorSequence.new(hueKeypoints)
                    hueGradient.Parent = hueStrip

                    local hueCursor = Instance.new("Frame")
                    hueCursor.Size = UDim2.new(0, 4, 1, 4)
                    hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                    hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
                    hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
                    hueCursor.ZIndex = 62
                    hueCursor.Parent = hueStrip
                    local hcCorner = Instance.new("UICorner")
                    hcCorner.CornerRadius = UDim.new(1, 0)
                    hcCorner.Parent = hueCursor
                    local hcStroke = Instance.new("UIStroke")
                    hcStroke.Color = Color3.new(0, 0, 0)
                    hcStroke.Thickness = 1
                    hcStroke.Parent = hueCursor

                    local hexLbl = Instance.new("TextLabel")
                    hexLbl.Size = UDim2.new(1, -16, 0, 16)
                    hexLbl.Position = UDim2.new(0, 8, 0, 132)
                    hexLbl.BackgroundTransparency = 1
                    hexLbl.Text = string.format("#%02X%02X%02X", math.floor(current.R*255+0.5), math.floor(current.G*255+0.5), math.floor(current.B*255+0.5))
                    hexLbl.TextColor3 = theme.SecondaryText
                    hexLbl.Font = Enum.Font.Code
                    hexLbl.TextSize = 12
                    hexLbl.ZIndex = 61
                    hexLbl.Parent = base

                    local function RefreshPanel()
                        svSquare.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                        svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                        hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
                        hexLbl.Text = string.format("#%02X%02X%02X", math.floor(current.R*255+0.5), math.floor(current.G*255+0.5), math.floor(current.B*255+0.5))
                    end

                    local draggingSV, draggingHue = false, false
                    TrackConnection(svSquare.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingSV = true
                        end
                    end))
                    TrackConnection(hueStrip.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingHue = true
                        end
                    end))
                    TrackConnection(UserInputService.InputChanged:Connect(function(input)
                        if not (draggingSV or draggingHue) then return end
                        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                        if draggingSV then
                            local relX = math.clamp((input.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X, 0, 1)
                            local relY = math.clamp((input.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y, 0, 1)
                            sat = relX
                            val = 1 - relY
                        elseif draggingHue then
                            local relX = math.clamp((input.Position.X - hueStrip.AbsolutePosition.X) / hueStrip.AbsoluteSize.X, 0, 1)
                            hue = relX
                        end
                        UpdateVisual()
                        RefreshPanel()
                        Commit()
                    end))
                    TrackConnection(UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingSV = false
                            draggingHue = false
                        end
                    end))
                end

                TrackConnection(swatchBtn.MouseButton1Click:Connect(function()
                    if open then
                        ClosePanel()
                    else
                        OpenPanel()
                        open = true
                        MacUI.PopIn(panel, 0)
                    end
                end))

                local function SetColor(c)
                    hue, sat, val = Color3.toHSV(c)
                    UpdateVisual()
                end

                table.insert(Window.Elements, {Type = "ColorPicker", Name = opts.Name, Flag = flag, Set = SetColor, Object = rowContainer})

                if saved and opts.Callback then
                    local ok, err = pcall(opts.Callback, current)
                    if not ok then warn("[MacUI] Callback error:", err) end
                end

                return {Set = SetColor, Get = function() return current end}
            end

            -- Segmented Control
            function Section:CreateSegmentedControl(opts)
                opts = opts or {}
                local options = opts.Options or {"One", "Two"}
                local current = opts.Default or options[1]

                local frameContainer = CreateGlassFrame(sectionContent, {
                    Radius = 10,
                    Transparency = 0.4,
                    Color = theme.TertiaryBackground
                })
                frameContainer.Size = UDim2.new(1, 0, 0, 36)
                local frame = GetGlassBase(frameContainer)

                local buttons = {}
                local width = 1 / #options
                for i, opt in ipairs(options) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(width, -4, 1, -4)
                    b.Position = UDim2.new(width * (i-1), 2, 0, 2)
                    b.BackgroundColor3 = (opt == current) and theme.Accent or Color3.new(0,0,0)
                    b.BackgroundTransparency = (opt == current) and 0.2 or 1
                    b.Text = opt
                    b.TextColor3 = theme.Text
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 13
                    b.AutoButtonColor = false
                    b.Parent = frame
                    local bc = Instance.new("UICorner")
                    bc.CornerRadius = UDim.new(0, 6)
                    bc.Parent = b
                    buttons[opt] = b

                    TrackConnection(b.MouseButton1Click:Connect(function()
                        if current == opt then return end
                        current = opt
                        PlaySFX("Segment", 1.2, 0.4)
                        for name, btn in pairs(buttons) do
                            MacUI.Tween(btn, {Time = 0.18}, {
                                BackgroundTransparency = (name == opt) and 0.2 or 1,
                                BackgroundColor3 = (name == opt) and theme.Accent or Color3.new(0,0,0)
                            })
                        end
                        MacUI.PulseScale(b, 0.95, 0.15)
                        if opts.Callback then
                            local ok, err = pcall(opts.Callback, opt)
                            if not ok then warn("[MacUI] Callback error:", err) end
                        end
                    end))
                end
                return {Get = function() return current end}
            end

            table.insert(Tab.Sections, Section)
            return Section
        end

        if not Window.CurrentTab then
            SelectTab()
        end
        return Tab
    end

    function Window:CreateSearch()
        local searchFrame = CreateGlassFrame(window, {Radius = 10, Transparency = 0.1})
        searchFrame.Size = UDim2.new(0, 280, 0, 36)
        searchFrame.Position = UDim2.new(1, -300, 0, 4)
        searchFrame.Visible = false
        searchFrame.ZIndex = 50

        local searchBase = GetGlassBase(searchFrame)
        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -12, 1, -8)
        searchBox.Position = UDim2.new(0, 6, 0, 4)
        searchBox.BackgroundTransparency = 1
        searchBox.Text = ""
        searchBox.PlaceholderText = "Search..."
        searchBox.TextColor3 = theme.Text
        searchBox.PlaceholderColor3 = theme.SecondaryText
        searchBox.Font = Enum.Font.Gotham
        searchBox.TextSize = 14
        searchBox.Parent = searchBase

        TrackConnection(searchBtn.MouseButton1Click:Connect(function()
            searchFrame.Visible = not searchFrame.Visible
            if searchFrame.Visible then searchBox:CaptureFocus() end
        end))

        TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = string.lower(searchBox.Text)
            for _, el in ipairs(Window.Elements) do
                if el.Object and el.Object.Parent then
                    local match = query == "" or string.find(string.lower(el.Name or ""), query)
                    el.Object.Visible = match and true or false
                end
            end
        end))
    end

    -- Opening animation
    local function OpenWindow()
        PlaySFX("Open", 1.0, 0.55)
        local winBase = GetGlassBase(windowContainer)
        windowContainer.Visible = true
        windowContainer.Size = UDim2.new(0, 0, 0, 0)
        if winBase then
            winBase.BackgroundTransparency = 1
        end
        MacUI.Tween(windowContainer, {Time = 0.45, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out}, {
            Size = size
        })
        if winBase then
            MacUI.Tween(winBase, {Time = 0.4}, {
                BackgroundTransparency = acrylic and (theme.GlassTransparency or MacUI.GlassStyle.Transparency) or 0.08
            })
        end

        -- Dock slides up + fades in slightly after the window pops open
        if dockContainer then
            local dockOriginalPos = dockContainer.Position
            dockContainer.Position = dockOriginalPos + UDim2.new(0, 0, 0, 24)
            local dockBase = GetGlassBase(dockContainer)
            local baseTransparency = dockBase and dockBase.BackgroundTransparency or 0.3
            if dockBase then dockBase.BackgroundTransparency = 1 end
            task.delay(0.18, function()
                MacUI.Tween(dockContainer, {Time = 0.4, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out}, {
                    Position = dockOriginalPos
                })
                if dockBase then
                    MacUI.Tween(dockBase, {Time = 0.35}, {BackgroundTransparency = baseTransparency})
                end
            end)
        end

        -- Auto-load saved config (if configured) once everything that will exist by
        -- default has been created; elements created afterward self-apply their own
        -- saved value as they're built (see the Flag handling in each control).
        if Window._PendingConfigLoad then
            Window._PendingConfigLoad = nil
            MacUI:LoadConfig()
            Window:ApplyConfig()
        end
    end

    if showBoot then
        self:PlayBootSequence({
            Duration = 2.6,
            OnComplete = OpenWindow
        })
    else
        OpenWindow()
    end

    table.insert(self.Windows, Window)
    return Window
end

-- ============================================================
-- KEY SYSTEM
-- Gate a script behind a key, with the key and/or its validity window optionally fetched
-- from a site instead of hardcoded, a re-entry timer, and a battery-style indicator of how
-- much of that timer is left. All network/file calls are pcall-wrapped: a site being down
-- or an executor lacking file functions degrades gracefully instead of erroring.
--
-- Sessions are GLOBAL (SaveFolder/SaveFile default to MacUI/KeySystem/session.json).
-- Changing the hub Name, KeySystem.Title, or Note has ZERO effect on an already-valid
-- session — retyping the same key in another hub just refreshes the timer. Only changing
-- the actual Key (or remote GetKeySite value) invalidates a previous session.
-- ============================================================
MacUI.KeySystem = {
    Enabled = false,
    Key = nil,              -- static expected key (ignored if GetKeySite is set)
    GetKeySite = nil,        -- URL returning the current valid key as plain text
    KeyLink = nil,            -- URL for a "Copy Key Link" button (uses setclipboard)
    Timer = 0,                 -- seconds the key stays valid once entered; 0 = never expires
    GetTimeSite = nil,          -- URL returning the timer length (seconds) as plain text
    GetTimeFromSite = false,
    Title = "Key System",
    Note = "Enter your key to continue",
    -- Shared across every hub that uses the default path so different Titles / script names
    -- still share one valid session.
    SaveFolder = "MacUI/KeySystem",
    SaveFile = "session"
}

function MacUI:SetupKeySystem(opts)
    opts = opts or {}
    for k, v in pairs(opts) do
        self.KeySystem[k] = v
    end
end

local function HttpGetTrimmed(url)
    if not url then return nil end
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(result) == "string" then
        return (result:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    return nil
end

-- Resolves the expected key: the remote site's response if GetKeySite is set and reachable,
-- otherwise the static Key. Returns nil if neither is usable.
function MacUI:_ResolveExpectedKey()
    local ks = self.KeySystem
    if ks.GetKeySite then
        local remote = HttpGetTrimmed(ks.GetKeySite)
        if remote and remote ~= "" then return remote end
        warn("[MacUI] KeySystem: couldn't reach GetKeySite, falling back to KeySystem.Key")
    end
    return ks.Key
end

-- Resolves how long (seconds) a successful key entry stays valid.
function MacUI:_ResolveTimerSeconds()
    local ks = self.KeySystem
    if ks.GetTimeFromSite and ks.GetTimeSite then
        local remote = HttpGetTrimmed(ks.GetTimeSite)
        local n = remote and tonumber(remote)
        if n then return n end
        warn("[MacUI] KeySystem: couldn't reach GetTimeSite, falling back to KeySystem.Timer")
    end
    return ks.Timer or 0
end

local function KeySessionPath()
    local ks = MacUI.KeySystem
    return (ks.SaveFolder or "MacUI/KeySystem") .. "/" .. (ks.SaveFile or "session") .. ".json"
end

local function SaveKeySession(keyUsed, timerSeconds)
    local ok = pcall(function()
        local folder = MacUI.KeySystem.SaveFolder or "MacUI/KeySystem"
        if makefolder and isfolder and not isfolder(folder) then
            makefolder(folder)
        end
        writefile(KeySessionPath(), HttpService:JSONEncode({
            key = keyUsed,
            timer = timerSeconds,
            timestamp = os.time()
        }))
    end)
    return ok
end

local function LoadKeySession()
    local ok, result = pcall(function()
        local path = KeySessionPath()
        if isfile and isfile(path) then
            return HttpService:JSONDecode(readfile(path))
        end
        return nil
    end)
    if ok then return result end
    return nil
end

-- Checks the entered key against the expected one. On success, starts (or restarts) the
-- re-entry timer by saving a session file, so RunKeySystem/GetKeyStatus can skip the prompt
-- next time until that timer runs out. Retyping the *same* key always succeeds and simply
-- refreshes the timer — Title / hub name changes are irrelevant.
function MacUI:VerifyKey(input)
    local expected = self:_ResolveExpectedKey()
    if not expected or expected == "" then
        warn("[MacUI] KeySystem: no expected key configured (set KeySystem.Key or GetKeySite)")
        return false
    end
    local trimmedInput = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if trimmedInput == "" then return false end
    if trimmedInput:lower() ~= tostring(expected):lower() then
        return false
    end
    local timerSeconds = self:_ResolveTimerSeconds()
    SaveKeySession(trimmedInput, timerSeconds)
    return true
end

-- Returns {Valid, Remaining, Total}. Valid is true when KeySystem is off (nothing to check),
-- or when a saved session exists, the stored key still matches the *current* expected key,
-- and (Timer == 0 or time remains). Title / Note / hub Name never affect validity.
function MacUI:GetKeyStatus()
    if not self.KeySystem.Enabled then
        return {Valid = true}
    end
    local session = LoadKeySession()
    if not session or not session.timestamp then
        return {Valid = false}
    end
    -- If the expected key has changed since the session was written, treat as invalid
    -- so a different product key can't ride on an old session. Matching is case-insensitive.
    local expected = self:_ResolveExpectedKey()
    if expected and session.key and tostring(session.key):lower() ~= tostring(expected):lower() then
        return {Valid = false}
    end
    local total = session.timer or 0
    if total <= 0 then
        return {Valid = true, Remaining = nil, Total = 0}
    end
    local elapsed = os.time() - session.timestamp
    local remaining = math.max(total - elapsed, 0)
    return {Valid = remaining > 0, Remaining = remaining, Total = total}
end

-- Builds the key-entry modal. onSuccess/onFail are the "remade" callback pair: onSuccess()
-- fires once a correct key is entered (and the modal closes itself); onFail(reason) fires on
-- every rejected attempt (reason is a short string) and does NOT close the modal, so the
-- person can just try again.
-- Submissions are rate-limited: SUBMIT_COOLDOWN seconds must pass between Submit() calls
-- (whether triggered by the button or by pressing Enter in the box), so spamming the
-- button/key can't hammer GetKeySite or spam onFail.
local KEY_SUBMIT_COOLDOWN = 0.5

function MacUI:PromptKeySystem(onSuccess, onFail)
    local ks = self.KeySystem
    local theme = self.Themes[self.CurrentTheme] or self.Themes["Liquid Glass Dark"]

    -- A "Get Link" button is offered whenever a remote key site (GetKeySite) is configured,
    -- in addition to (or instead of) the existing KeyLink "Copy Link" button. The panel
    -- grows a bit to fit a dedicated row for these when either is present.
    local hasKeyLink = ks.KeyLink ~= nil and ks.KeyLink ~= ""
    local hasGetKeySite = ks.GetKeySite ~= nil and ks.GetKeySite ~= ""
    local hasLinks = hasKeyLink or hasGetKeySite
    local panelHeight = hasLinks and 264 or 220

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MacUI_KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100001
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetUIParent()

    local dim = Instance.new("Frame")
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.new(0, 0, 0)
    dim.BackgroundTransparency = 0.45
    dim.Active = true -- blocks clicks to anything behind the modal
    dim.Parent = screenGui

    local panel = CreateGlassFrame(screenGui, {Radius = 18, Transparency = 0.1, Color = theme.Background})
    panel.Size = UDim2.new(0, 340, 0, panelHeight)
    panel.Position = UDim2.new(0.5, -170, 0.5, -panelHeight / 2)
    local base = GetGlassBase(panel)
    base.ClipsDescendants = true

    -- Shared close path: used by the close (x) button, and reusable if a future caller
    -- wants to dismiss the modal programmatically. reason is passed through to onFail.
    local closed = false
    local function CloseModal(reason)
        if closed then return end
        closed = true
        MacUI.Tween(panel, {Time = 0.2}, {Size = UDim2.new(0, 0, 0, 0)})
        task.delay(0.2, function()
            if screenGui and screenGui.Parent then screenGui:Destroy() end
        end)
        if onFail then
            local callOk, err = pcall(onFail, reason or "closed")
            if not callOk then warn("[MacUI] KeySystem OnFail error:", err) end
        end
    end

    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -34, 0, 14)
    closeBtn.BackgroundTransparency = 1
    MacUI.ApplyIcon(closeBtn, "x")
    closeBtn.ImageColor3 = theme.SecondaryText
    closeBtn.ZIndex = 5
    closeBtn.Parent = base
    closeBtn.MouseEnter:Connect(function()
        MacUI.Tween(closeBtn, {Time = 0.12}, {ImageColor3 = theme.Text})
    end)
    closeBtn.MouseLeave:Connect(function()
        MacUI.Tween(closeBtn, {Time = 0.12}, {ImageColor3 = theme.SecondaryText})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        PlaySFX("Close", 0.95, 0.6)
        MacUI.PulseScale(closeBtn, 0.8, 0.12)
        CloseModal("closed")
    end)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -60, 0, 26)
    titleLbl.Position = UDim2.new(0, 16, 0, 18)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = ks.Title or "Key System"
    titleLbl.TextColor3 = theme.Text
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 18
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = base

    local noteLbl = Instance.new("TextLabel")
    noteLbl.Size = UDim2.new(1, -32, 0, 36)
    noteLbl.Position = UDim2.new(0, 16, 0, 46)
    noteLbl.BackgroundTransparency = 1
    noteLbl.Text = ks.Note or "Enter your key to continue"
    noteLbl.TextColor3 = theme.SecondaryText
    noteLbl.Font = Enum.Font.Gotham
    noteLbl.TextSize = 13
    noteLbl.TextWrapped = true
    noteLbl.TextXAlignment = Enum.TextXAlignment.Left
    noteLbl.Parent = base

    local inputContainer = CreateGlassFrame(base, {Radius = 8, Transparency = 0.3, Color = theme.TertiaryBackground, Layers = false})
    inputContainer.Size = UDim2.new(1, -32, 0, 36)
    inputContainer.Position = UDim2.new(0, 16, 0, 92)
    local inputBase = GetGlassBase(inputContainer)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = ""
    box.PlaceholderText = "Key..."
    box.TextColor3 = theme.Text
    box.PlaceholderColor3 = theme.SecondaryText
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = inputBase

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -32, 0, 18)
    statusLbl.Position = UDim2.new(0, 16, 0, 132)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = ""
    statusLbl.TextColor3 = theme.Danger
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 12
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = base

    -- Optional link row: "Copy Link" (KeyLink) and/or "Get Link" (GetKeySite), stacked
    -- side-by-side when both exist. Sits just above the submit button, bottom-anchored so
    -- it doesn't need to know the submit button's exact position.
    if hasLinks then
        local linkRow = Instance.new("Frame")
        linkRow.Name = "LinkRow"
        linkRow.BackgroundTransparency = 1
        linkRow.Size = UDim2.new(1, -32, 0, 32)
        linkRow.Position = UDim2.new(0, 16, 1, -100)
        linkRow.Parent = base

        local function CreateLinkButton(label, sizeUDim, posUDim, onClick)
            local container = CreateGlassFrame(linkRow, {Radius = 8, Transparency = 0.3, Color = theme.TertiaryBackground, Layers = false})
            container.Size = sizeUDim
            container.Position = posUDim
            local linkBase = GetGlassBase(container)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = label
            btn.TextColor3 = theme.Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.Parent = linkBase
            btn.MouseButton1Click:Connect(onClick)
            return btn
        end

        local bothLinks = hasKeyLink and hasGetKeySite
        local fullWidth = UDim2.new(1, 0, 1, 0)
        local leftHalf = UDim2.new(0.5, -4, 1, 0)
        local rightHalf = UDim2.new(0.5, -4, 1, 0)

        if hasKeyLink then
            CreateLinkButton(
                "Copy Link",
                bothLinks and leftHalf or fullWidth,
                UDim2.new(0, 0, 0, 0),
                function()
                    local ok = pcall(function() setclipboard(ks.KeyLink) end)
                    PlaySFX(ok and "Copy" or "Error", 1.1, 0.5)
                    statusLbl.TextColor3 = ok and theme.Success or theme.Danger
                    statusLbl.Text = ok and "Key link copied to clipboard." or "Couldn't copy - link: " .. ks.KeyLink
                end
            )
        end

        if hasGetKeySite then
            CreateLinkButton(
                "Get Link",
                bothLinks and rightHalf or fullWidth,
                bothLinks and UDim2.new(0.5, 4, 0, 0) or UDim2.new(0, 0, 0, 0),
                function()
                    local ok = pcall(function() setclipboard(ks.GetKeySite) end)
                    PlaySFX(ok and "Copy" or "Error", 1.1, 0.5)
                    statusLbl.TextColor3 = ok and theme.Success or theme.Danger
                    statusLbl.Text = ok and "Key site link copied to clipboard." or "Couldn't copy - link: " .. ks.GetKeySite
                end
            )
        end
    end

    local submitContainer = CreateGlassFrame(base, {Radius = 8, Transparency = 0.1, Color = theme.Accent, Layers = false})
    submitContainer.Size = UDim2.new(1, -32, 0, 38)
    submitContainer.Position = UDim2.new(0, 16, 1, -54)
    local submitBase = GetGlassBase(submitContainer)
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(1, 0, 1, 0)
    submitBtn.BackgroundTransparency = 1
    submitBtn.Text = "Submit"
    submitBtn.TextColor3 = Color3.new(1, 1, 1)
    submitBtn.Font = Enum.Font.GothamMedium
    submitBtn.TextSize = 14
    submitBtn.Parent = submitBase

    -- 0.5s cooldown between submit attempts (button click or Enter in the box), so a
    -- spammed key/click can't hammer VerifyKey (and, transitively, GetKeySite) repeatedly.
    local lastSubmitAt = 0
    local function Submit()
        local now = os.clock()
        if now - lastSubmitAt < KEY_SUBMIT_COOLDOWN then
            PlaySFX("Deny", 0.9, 0.35)
            return
        end
        lastSubmitAt = now

        local ok = self:VerifyKey(box.Text)
        if ok then
            PlaySFX("Success", 1.1, 0.7)
            statusLbl.TextColor3 = theme.Success
            statusLbl.Text = "Key accepted."
            task.delay(0.25, function()
                MacUI.Tween(panel, {Time = 0.25}, {Size = UDim2.new(0, 0, 0, 0)})
                task.delay(0.25, function()
                    closed = true
                    if screenGui and screenGui.Parent then screenGui:Destroy() end
                end)
            end)
            if onSuccess then
                local callOk, err = pcall(onSuccess)
                if not callOk then warn("[MacUI] KeySystem OnSuccess error:", err) end
            end
        else
            PlaySFX("Error", 0.85, 0.65)
            statusLbl.TextColor3 = theme.Danger
            statusLbl.Text = "Invalid key - try again."
            MacUI.Shake(inputContainer, 6, 0.3)
            if onFail then
                local callOk, err = pcall(onFail, "invalid_key")
                if not callOk then warn("[MacUI] KeySystem OnFail error:", err) end
            end
        end
    end

    submitBtn.MouseButton1Click:Connect(Submit)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then Submit() end
    end)

    MacUI.PopIn(panel, 0)
end

-- The entry point: call this instead of (or before) CreateWindow when a key system is
-- configured. If KeySystem.Enabled is false, or a still-valid session already exists, it
-- calls onReady() immediately with no prompt. Otherwise it shows PromptKeySystem and calls
-- onReady() only once a correct key is entered.
function MacUI:RunKeySystem(onReady, onFail)
    local status = self:GetKeyStatus()
    if status.Valid then
        if onReady then onReady() end
        return
    end
    self:PromptKeySystem(onReady, onFail)
end

return MacUI
