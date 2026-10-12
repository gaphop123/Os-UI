--[[
    WinUI - Windows 10 inspired Luau UI Library for Roblox
    Architecture inspired by Rayfield Gen2 style API
    Visual language: Windows 10 (Settings, title bar, Metro/Fluent controls + Taskbar)
    Pure Luau • Modular • Production-oriented

    v2.0.0 – Windows 10 boot loading, Taskbar tabs (Lucide icons),
             richer animations, smoother transitions, improved polish
]]

local WinUI = {}
WinUI.__index = WinUI

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Constants
local ACCENT_DEFAULT = Color3.fromRGB(0, 120, 215)
local LIBRARY_NAME = "WinUI"
local VERSION = "2.0.0"

-- Utility
local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        warn("[WinUI] Error:", result)
    end
    return ok, result
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function clamp(n, min, max)
    return math.clamp(n, min, max)
end

local function create(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                inst[k] = v
            end
        end
        if props.Parent then
            inst.Parent = props.Parent
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

-- Enhanced tween helper with common presets
local function tween(obj, props, duration, style, dir)
    duration = duration or 0.2
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(duration, style, dir), props)
    t:Play()
    return t
end

local function tweenIn(obj, props, duration)
    return tween(obj, props, duration or 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

local function tweenOut(obj, props, duration)
    return tween(obj, props, duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

local function spring(obj, props, duration)
    return tween(obj, props, duration or 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- Safe parent for ScreenGuis (CoreGui may be restricted)
local function getGuiParent()
    local ok = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
    end)
    if ok then
        return CoreGui
    end
    return PlayerGui
end

-- Theme Engine
local Themes = {
    Windows10 = {
        Name = "Windows10",
        Accent = Color3.fromRGB(0, 120, 215),
        Background = Color3.fromRGB(243, 243, 243),
        SecondaryBackground = Color3.fromRGB(255, 255, 255),
        Sidebar = Color3.fromRGB(230, 230, 230),
        TitleBar = Color3.fromRGB(255, 255, 255),
        Taskbar = Color3.fromRGB(16, 16, 16),
        TaskbarHover = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(32, 32, 32),
        TextSecondary = Color3.fromRGB(90, 90, 90),
        Border = Color3.fromRGB(200, 200, 200),
        Hover = Color3.fromRGB(0, 0, 0),
        HoverTransparency = 0.92,
        Selected = Color3.fromRGB(0, 120, 215),
        ToggleOn = Color3.fromRGB(0, 120, 215),
        ToggleOff = Color3.fromRGB(180, 180, 180),
        InputBackground = Color3.fromRGB(255, 255, 255),
        NotificationBackground = Color3.fromRGB(45, 45, 45),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(255, 255, 255),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    Windows10Dark = {
        Name = "Windows10Dark",
        Accent = Color3.fromRGB(0, 120, 215),
        Background = Color3.fromRGB(32, 32, 32),
        SecondaryBackground = Color3.fromRGB(45, 45, 45),
        Sidebar = Color3.fromRGB(25, 25, 25),
        TitleBar = Color3.fromRGB(32, 32, 32),
        Taskbar = Color3.fromRGB(16, 16, 16),
        TaskbarHover = Color3.fromRGB(50, 50, 50),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Border = Color3.fromRGB(60, 60, 60),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.92,
        Selected = Color3.fromRGB(0, 120, 215),
        ToggleOn = Color3.fromRGB(0, 120, 215),
        ToggleOff = Color3.fromRGB(100, 100, 100),
        InputBackground = Color3.fromRGB(50, 50, 50),
        NotificationBackground = Color3.fromRGB(40, 40, 40),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(45, 45, 45),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    Windows10Light = {
        Name = "Windows10Light",
        Accent = Color3.fromRGB(0, 120, 215),
        Background = Color3.fromRGB(245, 245, 245),
        SecondaryBackground = Color3.fromRGB(255, 255, 255),
        Sidebar = Color3.fromRGB(235, 235, 235),
        TitleBar = Color3.fromRGB(255, 255, 255),
        Taskbar = Color3.fromRGB(230, 230, 230),
        TaskbarHover = Color3.fromRGB(210, 210, 210),
        Text = Color3.fromRGB(32, 32, 32),
        TextSecondary = Color3.fromRGB(100, 100, 100),
        Border = Color3.fromRGB(210, 210, 210),
        Hover = Color3.fromRGB(0, 0, 0),
        HoverTransparency = 0.94,
        Selected = Color3.fromRGB(0, 120, 215),
        ToggleOn = Color3.fromRGB(0, 120, 215),
        ToggleOff = Color3.fromRGB(180, 180, 180),
        InputBackground = Color3.fromRGB(255, 255, 255),
        NotificationBackground = Color3.fromRGB(50, 50, 50),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(255, 255, 255),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    Blue = {
        Name = "Blue",
        Accent = Color3.fromRGB(0, 99, 177),
        Background = Color3.fromRGB(32, 32, 32),
        SecondaryBackground = Color3.fromRGB(40, 40, 45),
        Sidebar = Color3.fromRGB(25, 25, 30),
        TitleBar = Color3.fromRGB(32, 32, 32),
        Taskbar = Color3.fromRGB(18, 18, 24),
        TaskbarHover = Color3.fromRGB(45, 45, 55),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Border = Color3.fromRGB(55, 55, 60),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.92,
        Selected = Color3.fromRGB(0, 99, 177),
        ToggleOn = Color3.fromRGB(0, 99, 177),
        ToggleOff = Color3.fromRGB(90, 90, 95),
        InputBackground = Color3.fromRGB(48, 48, 52),
        NotificationBackground = Color3.fromRGB(35, 35, 40),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(40, 40, 45),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    Gray = {
        Name = "Gray",
        Accent = Color3.fromRGB(120, 120, 120),
        Background = Color3.fromRGB(40, 40, 40),
        SecondaryBackground = Color3.fromRGB(50, 50, 50),
        Sidebar = Color3.fromRGB(30, 30, 30),
        TitleBar = Color3.fromRGB(40, 40, 40),
        Taskbar = Color3.fromRGB(22, 22, 22),
        TaskbarHover = Color3.fromRGB(55, 55, 55),
        Text = Color3.fromRGB(240, 240, 240),
        TextSecondary = Color3.fromRGB(170, 170, 170),
        Border = Color3.fromRGB(70, 70, 70),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.9,
        Selected = Color3.fromRGB(120, 120, 120),
        ToggleOn = Color3.fromRGB(120, 120, 120),
        ToggleOff = Color3.fromRGB(90, 90, 90),
        InputBackground = Color3.fromRGB(55, 55, 55),
        NotificationBackground = Color3.fromRGB(45, 45, 45),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(50, 50, 50),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    DarkBlue = {
        Name = "DarkBlue",
        Accent = Color3.fromRGB(0, 153, 255),
        Background = Color3.fromRGB(18, 22, 32),
        SecondaryBackground = Color3.fromRGB(28, 34, 48),
        Sidebar = Color3.fromRGB(14, 18, 28),
        TitleBar = Color3.fromRGB(22, 28, 40),
        Taskbar = Color3.fromRGB(12, 16, 26),
        TaskbarHover = Color3.fromRGB(35, 45, 65),
        Text = Color3.fromRGB(240, 244, 255),
        TextSecondary = Color3.fromRGB(150, 160, 185),
        Border = Color3.fromRGB(45, 55, 75),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.9,
        Selected = Color3.fromRGB(0, 153, 255),
        ToggleOn = Color3.fromRGB(0, 153, 255),
        ToggleOff = Color3.fromRGB(70, 80, 100),
        InputBackground = Color3.fromRGB(32, 40, 55),
        NotificationBackground = Color3.fromRGB(24, 30, 42),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(28, 34, 48),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    Purple = {
        Name = "Purple",
        Accent = Color3.fromRGB(136, 23, 152),
        Background = Color3.fromRGB(30, 28, 36),
        SecondaryBackground = Color3.fromRGB(42, 38, 52),
        Sidebar = Color3.fromRGB(24, 22, 30),
        TitleBar = Color3.fromRGB(30, 28, 36),
        Taskbar = Color3.fromRGB(18, 16, 24),
        TaskbarHover = Color3.fromRGB(50, 45, 65),
        Text = Color3.fromRGB(245, 240, 255),
        TextSecondary = Color3.fromRGB(170, 160, 190),
        Border = Color3.fromRGB(60, 55, 75),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.9,
        Selected = Color3.fromRGB(136, 23, 152),
        ToggleOn = Color3.fromRGB(136, 23, 152),
        ToggleOff = Color3.fromRGB(90, 85, 105),
        InputBackground = Color3.fromRGB(48, 44, 58),
        NotificationBackground = Color3.fromRGB(36, 32, 44),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(42, 38, 52),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    Green = {
        Name = "Green",
        Accent = Color3.fromRGB(16, 137, 62),
        Background = Color3.fromRGB(28, 32, 28),
        SecondaryBackground = Color3.fromRGB(38, 44, 38),
        Sidebar = Color3.fromRGB(22, 26, 22),
        TitleBar = Color3.fromRGB(28, 32, 28),
        Taskbar = Color3.fromRGB(16, 20, 16),
        TaskbarHover = Color3.fromRGB(40, 50, 40),
        Text = Color3.fromRGB(240, 255, 245),
        TextSecondary = Color3.fromRGB(160, 180, 165),
        Border = Color3.fromRGB(55, 70, 58),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.9,
        Selected = Color3.fromRGB(16, 137, 62),
        ToggleOn = Color3.fromRGB(16, 137, 62),
        ToggleOff = Color3.fromRGB(80, 95, 85),
        InputBackground = Color3.fromRGB(44, 52, 44),
        NotificationBackground = Color3.fromRGB(32, 38, 32),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(38, 44, 38),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    Orange = {
        Name = "Orange",
        Accent = Color3.fromRGB(247, 99, 12),
        Background = Color3.fromRGB(36, 30, 26),
        SecondaryBackground = Color3.fromRGB(48, 40, 34),
        Sidebar = Color3.fromRGB(28, 24, 20),
        TitleBar = Color3.fromRGB(36, 30, 26),
        Taskbar = Color3.fromRGB(22, 18, 14),
        TaskbarHover = Color3.fromRGB(55, 45, 35),
        Text = Color3.fromRGB(255, 248, 240),
        TextSecondary = Color3.fromRGB(190, 170, 150),
        Border = Color3.fromRGB(70, 58, 48),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.9,
        Selected = Color3.fromRGB(247, 99, 12),
        ToggleOn = Color3.fromRGB(247, 99, 12),
        ToggleOff = Color3.fromRGB(100, 85, 70),
        InputBackground = Color3.fromRGB(54, 46, 40),
        NotificationBackground = Color3.fromRGB(40, 34, 28),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(48, 40, 34),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
    FluentDark = {
        Name = "FluentDark",
        Accent = Color3.fromRGB(96, 205, 255),
        Background = Color3.fromRGB(32, 32, 32),
        SecondaryBackground = Color3.fromRGB(44, 44, 44),
        Sidebar = Color3.fromRGB(26, 26, 26),
        TitleBar = Color3.fromRGB(32, 32, 32),
        Taskbar = Color3.fromRGB(20, 20, 20),
        TaskbarHover = Color3.fromRGB(50, 50, 50),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200),
        Border = Color3.fromRGB(58, 58, 58),
        Hover = Color3.fromRGB(255, 255, 255),
        HoverTransparency = 0.9,
        Selected = Color3.fromRGB(96, 205, 255),
        ToggleOn = Color3.fromRGB(96, 205, 255),
        ToggleOff = Color3.fromRGB(100, 100, 100),
        InputBackground = Color3.fromRGB(52, 52, 52),
        NotificationBackground = Color3.fromRGB(40, 40, 40),
        NotificationText = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        StatusBar = Color3.fromRGB(44, 44, 44),
        BootBackground = Color3.fromRGB(0, 0, 0),
    },
}

local CurrentTheme = deepCopy(Themes.Windows10)
local AccentColor = ACCENT_DEFAULT

-- Lucide icon asset IDs (reliable, widely used in Roblox UI libs)
local Icons = {
    home     = "rbxassetid://10723407389",
    settings = "rbxassetid://10734950309",
    player   = "rbxassetid://10747373176",
    user     = "rbxassetid://10747373176",
    visual   = "rbxassetid://10723346959",
    eye      = "rbxassetid://10723346959",
    combat   = "rbxassetid://10734975486",
    sword    = "rbxassetid://10734975486",
    misc     = "rbxassetid://10709782497",
    box      = "rbxassetid://10709782497",
    about    = "rbxassetid://10723415903",
    info     = "rbxassetid://10723415903",
    search   = "rbxassetid://10734943674",
    close    = "rbxassetid://10747384394",
    x        = "rbxassetid://10747384394",
    minimize = "rbxassetid://10734895698",
    maximize = "rbxassetid://10734886735",
    minus    = "rbxassetid://10734896206",
    menu     = "rbxassetid://10734886735",
    cog      = "rbxassetid://10709810948",
    users    = "rbxassetid://10747373426",
    swords   = "rbxassetid://10734975692",
    star     = "rbxassetid://10734950309",
    heart    = "rbxassetid://10723407389",
    code     = "rbxassetid://10709782497",
    game     = "rbxassetid://10734975486",
    world    = "rbxassetid://10723346959",
    shield   = "rbxassetid://10734975486",
}

local function resolveIcon(name)
    if not name or name == "" then
        return Icons.home
    end
    if typeof(name) == "string" and (string.find(name, "rbxassetid://") or string.find(name, "rbxasset://")) then
        return name
    end
    local key = string.lower(tostring(name))
    return Icons[key] or Icons.home
end

-- Global state
local Windows = {}
local Notifications = {}
local ConfigData = {}
local Connections = {}
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
-- Windows 10 style boot / loading animation
-- ============================================================
local function createBootLoader(parent, title, subtitle, accent)
    local boot = create("Frame", {
        Name = "BootLoader",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 200,
        Parent = parent,
    })

    -- Soft vignette / glow
    local glow = create("ImageLabel", {
        Name = "Glow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = accent or ACCENT_DEFAULT,
        ImageTransparency = 0.85,
        Size = UDim2.new(0, 420, 0, 420),
        Position = UDim2.new(0.5, 0, 0.42, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 201,
        Parent = boot,
    })

    -- Windows-style circular dots (orbiting)
    local spinner = create("Frame", {
        Name = "Spinner",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 64, 0, 64),
        Position = UDim2.new(0.5, 0, 0.42, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 202,
        Parent = boot,
    })

    local dots = {}
    local DOT_COUNT = 6
    for i = 1, DOT_COUNT do
        local angle = (i - 1) * (360 / DOT_COUNT)
        local rad = math.rad(angle)
        local r = 22
        local dot = create("Frame", {
            Name = "Dot" .. i,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 8, 0, 8),
            Position = UDim2.new(0.5, math.cos(rad) * r - 4, 0.5, math.sin(rad) * r - 4),
            AnchorPoint = Vector2.new(0, 0),
            ZIndex = 203,
            Parent = spinner,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
        dots[i] = { frame = dot, baseAngle = angle, phase = (i - 1) / DOT_COUNT }
    end

    local titleLbl = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 0, 28),
        Position = UDim2.new(0, 20, 0.58, 0),
        Font = Enum.Font.GothamSemibold,
        Text = title or "WinUI",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        TextTransparency = 1,
        ZIndex = 202,
        Parent = boot,
    })

    local subLbl = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.new(0, 20, 0.58, 32),
        Font = Enum.Font.Gotham,
        Text = subtitle or "Starting...",
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 13,
        TextTransparency = 1,
        ZIndex = 202,
        Parent = boot,
    })

    -- Fade titles in
    tween(titleLbl, { TextTransparency = 0 }, 0.6)
    tween(subLbl, { TextTransparency = 0 }, 0.7)

    -- Animate orbiting dots with brightness pulse (classic Win10 feel)
    local startTime = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not spinner or not spinner.Parent then
            if conn then conn:Disconnect() end
            return
        end
        local t = os.clock() - startTime
        local speed = 2.2
        for i, d in ipairs(dots) do
            local angle = d.baseAngle + t * 180 * speed
            local rad = math.rad(angle)
            local r = 22
            d.frame.Position = UDim2.new(0.5, math.cos(rad) * r - 4, 0.5, math.sin(rad) * r - 4)
            -- Pulse opacity based on phase
            local pulse = (math.sin(t * 6 + d.phase * math.pi * 2) + 1) / 2
            d.frame.BackgroundTransparency = 0.15 + pulse * 0.65
            local s = 6 + pulse * 3
            d.frame.Size = UDim2.new(0, s, 0, s)
        end
        -- Subtle glow breathe
        if glow and glow.Parent then
            glow.ImageTransparency = 0.82 + math.sin(t * 1.8) * 0.08
        end
    end)

    return boot, function()
        if conn then conn:Disconnect() end
        -- Exit animation
        tween(titleLbl, { TextTransparency = 1 }, 0.25)
        tween(subLbl, { TextTransparency = 1 }, 0.25)
        tween(spinner, { BackgroundTransparency = 1 }, 0.3)
        for _, d in ipairs(dots) do
            tween(d.frame, { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }, 0.25)
        end
        tween(glow, { ImageTransparency = 1 }, 0.3)
        tween(boot, { BackgroundTransparency = 1 }, 0.4)
        task.delay(0.45, function()
            if boot and boot.Parent then
                boot:Destroy()
            end
        end)
    end
end

-- Notification system
local NotificationContainer
local function ensureNotificationContainer()
    if NotificationContainer and NotificationContainer.Parent then
        return NotificationContainer
    end
    NotificationContainer = create("ScreenGui", {
        Name = "WinUI_Notifications",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = getGuiParent(),
    })
    local holder = create("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 340, 1, 0),
        Position = UDim2.new(1, -350, 0, 0),
        AnchorPoint = Vector2.new(0, 0),
        Parent = NotificationContainer,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder,
    })
    create("UIPadding", {
        PaddingBottom = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 10),
        Parent = holder,
    })
    return NotificationContainer
end

function WinUI:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "WinUI"
    local content = opts.Content or ""
    local duration = opts.Duration or 4
    local icon = opts.Icon

    ensureNotificationContainer()
    local holder = NotificationContainer:FindFirstChild("Holder")

    local notif = create("Frame", {
        Name = "Notification",
        BackgroundColor3 = CurrentTheme.NotificationBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 320, 0, 70),
        ClipsDescendants = true,
        Parent = holder,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = notif })
    create("UIStroke", {
        Color = CurrentTheme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = notif,
    })

    -- Accent bar with slide-in
    local accentBar = create("Frame", {
        BackgroundColor3 = AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = notif,
    })
    tween(accentBar, { Size = UDim2.new(0, 4, 1, 0) }, 0.3, Enum.EasingStyle.Back)

    if icon then
        local ic = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 14, 0, 10),
            Image = resolveIcon(icon),
            ImageColor3 = CurrentTheme.NotificationText,
            ImageTransparency = 1,
            Parent = notif,
        })
        tween(ic, { ImageTransparency = 0 }, 0.25)
    end

    local titleOffset = icon and 40 or 16
    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, titleOffset, 0, 10),
        Size = UDim2.new(1, -titleOffset - 30, 0, 20),
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = CurrentTheme.NotificationText,
        TextSize = 14,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local contentLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 32),
        Size = UDim2.new(1, -30, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = CurrentTheme.NotificationText,
        TextSize = 13,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = notif,
    })

    local closeBtn = create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -28, 0, 6),
        Size = UDim2.new(0, 22, 0, 22),
        Text = "✕",
        TextColor3 = CurrentTheme.NotificationText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextTransparency = 0.4,
        Parent = notif,
    })
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { TextTransparency = 0 }, 0.12)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { TextTransparency = 0.4 }, 0.12)
    end)

    task.defer(function()
        if not notif or not notif.Parent then return end
        local h = math.max(70, 42 + contentLabel.TextBounds.Y + 14)
        notif.Size = UDim2.new(0, 320, 0, h)
    end)

    -- Slide + fade in
    notif.Position = UDim2.new(1, 40, 0, 0)
    notif.BackgroundTransparency = 0.3
    tween(notif, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.32, Enum.EasingStyle.Quart)
    tween(titleLabel, { TextTransparency = 0 }, 0.25)
    tween(contentLabel, { TextTransparency = 0.15 }, 0.3)

    local closed = false
    local function close()
        if closed then return end
        closed = true
        tween(notif, { Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1 }, 0.22)
        task.delay(0.25, function()
            if notif and notif.Parent then
                notif:Destroy()
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(close)
    task.delay(duration, close)

    table.insert(Notifications, notif)
    return notif
end

-- Configuration helpers
local function getConfigPath(folder, file)
    return folder .. "/" .. file .. ".json"
end

function WinUI:SaveConfiguration()
    if not writefile then
        warn("[WinUI] writefile not available – configuration not saved")
        return
    end
    for _, window in pairs(Windows) do
        if window.Config and window.Config.Enabled then
            local data = {}
            for id, value in pairs(window.ConfigValues or {}) do
                data[id] = value
            end
            local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
            if ok then
                local path = getConfigPath(window.Config.FolderName or "WinUI", window.Config.FileName or "Settings")
                pcall(writefile, path, encoded)
            end
        end
    end
end

function WinUI:LoadConfiguration()
    if not readfile or not isfile then
        warn("[WinUI] readfile/isfile not available – configuration not loaded")
        return
    end
    for _, window in pairs(Windows) do
        if window.Config and window.Config.Enabled then
            local path = getConfigPath(window.Config.FolderName or "WinUI", window.Config.FileName or "Settings")
            if isfile(path) then
                local ok, content = pcall(readfile, path)
                if ok and content then
                    local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
                    if ok2 and type(data) == "table" then
                        window.ConfigValues = data
                    end
                end
            end
        end
    end
end

-- Theme API
function WinUI:SetTheme(themeName)
    local theme = Themes[themeName]
    if not theme then
        warn("[WinUI] Invalid theme:", themeName, "– available:", table.concat((function()
            local names = {}
            for k in pairs(Themes) do table.insert(names, k) end
            table.sort(names)
            return names
        end)(), ", "))
        return
    end
    CurrentTheme = deepCopy(theme)
    AccentColor = CurrentTheme.Accent
    for _, window in pairs(Windows) do
        if window.ApplyTheme then
            window:ApplyTheme()
        end
    end
end

function WinUI:SetAccentColor(color)
    if typeof(color) ~= "Color3" then
        warn("[WinUI] Invalid accent color")
        return
    end
    AccentColor = color
    CurrentTheme.Accent = color
    CurrentTheme.Selected = color
    CurrentTheme.ToggleOn = color
    for _, window in pairs(Windows) do
        if window.ApplyTheme then
            window:ApplyTheme()
        end
    end
end

function WinUI:GetTheme()
    return CurrentTheme
end

function WinUI:GetThemes()
    local names = {}
    for k in pairs(Themes) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

function WinUI:GetIcons()
    return Icons
end

-- ============================================================
-- Main Window Creator
-- ============================================================
function WinUI:CreateWindow(options)
    options = options or {}
    local name = options.Name or "WinUI"
    local loadingTitle = options.LoadingTitle or name
    local loadingSubtitle = options.LoadingSubtitle or "Windows 10 UI Library"
    local themeName = options.Theme or "Windows10"
    local config = options.ConfigurationSaving or { Enabled = false }
    local showBoot = options.ShowBoot ~= false -- default true
    local bootDuration = options.BootDuration or 1.8

    if Themes[themeName] then
        CurrentTheme = deepCopy(Themes[themeName])
        AccentColor = CurrentTheme.Accent
    end

    local windowId = HttpService:GenerateGUID(false)
    local window = {
        Id = windowId,
        Name = name,
        Tabs = {},
        CurrentTab = nil,
        Config = config,
        ConfigValues = {},
        Visible = true,
        Minimized = false,
        Connections = {},
        ThemeElements = {},
    }
    setmetatable(window, { __index = WinUI })

    local guiParent = getGuiParent()

    local screenGui = create("ScreenGui", {
        Name = "WinUI_" .. name,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        IgnoreGuiInset = true,
        Parent = guiParent,
    })
    window.ScreenGui = screenGui

    local TASKBAR_H = IsMobile and 52 or 48
    local TITLEBAR_H = 32
    local mainSize = IsMobile and UDim2.new(0.96, 0, 0.88, 0) or UDim2.new(0, 760, 0, 520)

    local main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = CurrentTheme.Background,
        BorderSizePixel = 0,
        Size = mainSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        Parent = screenGui,
    })
    window.Main = main
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = main })
    local mainStroke = create("UIStroke", {
        Color = CurrentTheme.Border,
        Thickness = 1,
        Parent = main,
    })

    -- Soft shadow
    create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = CurrentTheme.Shadow,
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 48, 1, 48),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 0,
        Parent = main,
    })

    -- Title Bar
    local titleBar = create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = CurrentTheme.TitleBar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, TITLEBAR_H),
        Parent = main,
    })
    window.TitleBar = titleBar

    local titleText = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -130, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextColor3 = CurrentTheme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })
    window.TitleText = titleText

    local controls = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 138, 1, 0),
        Position = UDim2.new(1, -138, 0, 0),
        Parent = titleBar,
    })

    local function makeControlButton(text, order, isClose)
        local btn = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 46, 1, 0),
            Position = UDim2.new(0, (order - 1) * 46, 0, 0),
            Text = text,
            TextColor3 = CurrentTheme.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            Parent = controls,
        })
        local hover = create("Frame", {
            BackgroundColor3 = isClose and Color3.fromRGB(232, 17, 35) or CurrentTheme.Hover,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0,
            Parent = btn,
        })
        btn.MouseEnter:Connect(function()
            if isClose then
                tween(hover, { BackgroundTransparency = 0 }, 0.12)
                tween(btn, { TextColor3 = Color3.new(1, 1, 1) }, 0.12)
            else
                tween(hover, { BackgroundTransparency = CurrentTheme.HoverTransparency }, 0.12)
            end
        end)
        btn.MouseLeave:Connect(function()
            tween(hover, { BackgroundTransparency = 1 }, 0.15)
            tween(btn, { TextColor3 = CurrentTheme.Text }, 0.15)
        end)
        return btn
    end

    local minBtn = makeControlButton("─", 1, false)
    local maxBtn = makeControlButton("☐", 2, false)
    local closeBtn = makeControlButton("✕", 3, true)

    -- Dragging
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    minBtn.MouseButton1Click:Connect(function()
        window.Minimized = not window.Minimized
        if window.Minimized then
            tween(main, { Size = UDim2.new(0, main.AbsoluteSize.X, 0, TITLEBAR_H) }, 0.25, Enum.EasingStyle.Quart)
        else
            tween(main, { Size = mainSize }, 0.28, Enum.EasingStyle.Quart)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        -- Smooth close animation
        tweenOut(main, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.22)
        task.delay(0.25, function()
            window:Destroy()
        end)
    end)

    maxBtn.MouseButton1Click:Connect(function()
        if main.Size.X.Scale > 0.9 then
            tween(main, { Size = mainSize, Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.28, Enum.EasingStyle.Quart)
        else
            tween(main, { Size = UDim2.new(1, -24, 1, -24), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.28, Enum.EasingStyle.Quart)
        end
    end)

    -- Body (content area above taskbar)
    local body = create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, TITLEBAR_H),
        Size = UDim2.new(1, 0, 1, -(TITLEBAR_H + TASKBAR_H)),
        Parent = main,
    })
    window.Body = body

    -- Content area (full width now – no sidebar)
    local content = create("Frame", {
        Name = "Content",
        BackgroundColor3 = CurrentTheme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        Parent = body,
    })
    window.Content = content

    local contentScroll = create("ScrollingFrame", {
        Name = "Scroll",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = AccentColor,
        BorderSizePixel = 0,
        Parent = content,
    })
    window.ContentScroll = contentScroll

    local contentLayout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = contentScroll,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 18),
        PaddingRight = UDim.new(0, 18),
        PaddingBottom = UDim.new(0, 18),
        Parent = contentScroll,
    })
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 28)
    end)

    -- ============================================================
    -- TASKBAR (bottom) – tabs as Lucide icons
    -- ============================================================
    local taskbar = create("Frame", {
        Name = "Taskbar",
        BackgroundColor3 = CurrentTheme.Taskbar or Color3.fromRGB(16, 16, 16),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, TASKBAR_H),
        Position = UDim2.new(0, 0, 1, -TASKBAR_H),
        Parent = main,
    })
    window.Taskbar = taskbar

    -- Subtle top border line
    create("Frame", {
        Name = "TopLine",
        BackgroundColor3 = AccentColor,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = taskbar,
    })

    local taskbarIcons = create("Frame", {
        Name = "Icons",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Parent = taskbar,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = taskbarIcons,
    })

    -- Status / version chip on the right of taskbar
    local statusChip = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 90, 1, 0),
        Position = UDim2.new(1, -100, 0, 0),
        Font = Enum.Font.Gotham,
        Text = "v" .. VERSION,
        TextColor3 = Color3.fromRGB(160, 160, 160),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = taskbar,
    })

    function window:ApplyTheme()
        main.BackgroundColor3 = CurrentTheme.Background
        mainStroke.Color = CurrentTheme.Border
        titleBar.BackgroundColor3 = CurrentTheme.TitleBar
        titleText.TextColor3 = CurrentTheme.Text
        content.BackgroundColor3 = CurrentTheme.Background
        contentScroll.ScrollBarImageColor3 = AccentColor
        taskbar.BackgroundColor3 = CurrentTheme.Taskbar or Color3.fromRGB(16, 16, 16)

        for _, tab in ipairs(window.Tabs) do
            local selected = (window.CurrentTab == tab)
            if tab.IconImage then
                tab.IconImage.ImageColor3 = selected and AccentColor or Color3.fromRGB(200, 200, 200)
            end
            if tab.Indicator then
                tab.Indicator.BackgroundColor3 = AccentColor
                tab.Indicator.BackgroundTransparency = selected and 0 or 1
            end
            if tab.HoverBg then
                tab.HoverBg.BackgroundColor3 = CurrentTheme.TaskbarHover or Color3.fromRGB(50, 50, 50)
            end
        end
    end

    function window:Toggle()
        window.Visible = not window.Visible
        if window.Visible then
            main.Visible = true
            main.Size = UDim2.new(0, 0, 0, 0)
            main.BackgroundTransparency = 0.4
            tweenIn(main, { Size = mainSize, BackgroundTransparency = 0 }, 0.3)
        else
            tweenOut(main, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.2)
            task.delay(0.22, function()
                if not window.Visible then
                    main.Visible = false
                end
            end)
        end
    end

    local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == toggleKey then
            window:Toggle()
        end
    end))

    -- ============================================================
    -- CreateTab  →  adds a Lucide icon button on the Taskbar
    -- ============================================================
    function window:CreateTab(tabName, iconName)
        local tabId = HttpService:GenerateGUID(false)
        local tab = {
            Name = tabName,
            Id = tabId,
            Elements = {},
            Container = nil,
        }

        -- Taskbar icon button
        local item = create("TextButton", {
            Name = tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, IsMobile and 48 or 44, 0, IsMobile and 44 or 40),
            Text = "",
            AutoButtonColor = false,
            Parent = taskbarIcons,
        })

        local hoverBg = create("Frame", {
            Name = "Hover",
            BackgroundColor3 = CurrentTheme.TaskbarHover or Color3.fromRGB(50, 50, 50),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0,
            Parent = item,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = hoverBg })

        local icon = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(0.5, 0, 0.5, -2),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = resolveIcon(iconName),
            ImageColor3 = Color3.fromRGB(200, 200, 200),
            ZIndex = 2,
            Parent = item,
        })

        -- Active indicator (bottom underline, Windows style)
        local indicator = create("Frame", {
            Name = "Indicator",
            BackgroundColor3 = AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0.55, 0, 0, 3),
            Position = UDim2.new(0.5, 0, 1, -4),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            ZIndex = 3,
            Parent = item,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })

        -- Tooltip on hover (desktop)
        local tooltip
        item.MouseEnter:Connect(function()
            if window.CurrentTab ~= tab then
                tween(hoverBg, { BackgroundTransparency = 0.35 }, 0.12)
                tween(icon, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, 0.12)
            end
            if not IsMobile then
                tooltip = create("TextLabel", {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    Size = UDim2.new(0, 0, 0, 24),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Position = UDim2.new(0.5, 0, 0, -30),
                    AnchorPoint = Vector2.new(0.5, 1),
                    Font = Enum.Font.Gotham,
                    Text = "  " .. tabName .. "  ",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 12,
                    ZIndex = 100,
                    Parent = item,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tooltip })
                tooltip.BackgroundTransparency = 1
                tooltip.TextTransparency = 1
                tween(tooltip, { BackgroundTransparency = 0.1, TextTransparency = 0 }, 0.15)
            end
        end)
        item.MouseLeave:Connect(function()
            if window.CurrentTab ~= tab then
                tween(hoverBg, { BackgroundTransparency = 1 }, 0.15)
                tween(icon, { ImageColor3 = Color3.fromRGB(200, 200, 200) }, 0.15)
            end
            if tooltip then
                local t = tooltip
                tooltip = nil
                tween(t, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.1)
                task.delay(0.12, function()
                    if t and t.Parent then t:Destroy() end
                end)
            end
        end)

        -- Content container for this tab
        local container = create("Frame", {
            Name = tabName .. "_Content",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = contentScroll,
        })
        local contLayout = create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = container,
        })
        contLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.Size = UDim2.new(1, 0, 0, contLayout.AbsoluteContentSize.Y)
        end)
        tab.Container = container
        tab.Layout = contLayout
        tab.Item = item
        tab.IconImage = icon
        tab.Indicator = indicator
        tab.HoverBg = hoverBg

        local function selectTab()
            if window.CurrentTab == tab then return end

            -- Deselect previous with animation
            if window.CurrentTab then
                local prev = window.CurrentTab
                if prev.Container then
                    prev.Container.Visible = false
                end
                if prev.Indicator then
                    tween(prev.Indicator, { BackgroundTransparency = 1, Size = UDim2.new(0.2, 0, 0, 3) }, 0.18)
                end
                if prev.IconImage then
                    tween(prev.IconImage, { ImageColor3 = Color3.fromRGB(200, 200, 200) }, 0.18)
                end
                if prev.HoverBg then
                    tween(prev.HoverBg, { BackgroundTransparency = 1 }, 0.15)
                end
            end

            -- Select new
            indicator.Size = UDim2.new(0.2, 0, 0, 3)
            indicator.BackgroundTransparency = 0
            tween(indicator, { Size = UDim2.new(0.55, 0, 0, 3) }, 0.25, Enum.EasingStyle.Back)
            tween(icon, { ImageColor3 = AccentColor }, 0.2)
            tween(hoverBg, { BackgroundTransparency = 0.55 }, 0.15)

            -- Content fade-in
            container.Visible = true
            container.BackgroundTransparency = 1
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("GuiObject") and child ~= contLayout then
                    local orig = child.BackgroundTransparency
                    child.BackgroundTransparency = 1
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                        local tOrig = child.TextTransparency
                        child.TextTransparency = 1
                        tween(child, { TextTransparency = tOrig or 0 }, 0.25)
                    end
                    tween(child, { BackgroundTransparency = orig }, 0.28)
                end
            end

            window.CurrentTab = tab
        end

        item.MouseButton1Click:Connect(selectTab)

        if #window.Tabs == 0 then
            task.defer(selectTab)
        end

        table.insert(window.Tabs, tab)

        -- ========== Components (with better animations) ==========

        function tab:CreateSection(text)
            local section = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = container,
            })
            local lbl = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamSemibold,
                Text = text or "Section",
                TextColor3 = CurrentTheme.Text,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section,
            })
            -- Underline accent
            local line = create("Frame", {
                BackgroundColor3 = AccentColor,
                BackgroundTransparency = 0.6,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 0, 0, 2),
                Position = UDim2.new(0, 0, 1, -2),
                Parent = section,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
            task.defer(function()
                tween(line, { Size = UDim2.new(0, math.min(80, lbl.TextBounds.X), 0, 2) }, 0.35, Enum.EasingStyle.Quart)
            end)
            return section
        end

        function tab:CreateLabel(opts)
            opts = opts or {}
            local labelFrame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = opts.Text or "",
                TextColor3 = CurrentTheme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = labelFrame,
            })
            return labelFrame
        end

        function tab:CreateParagraph(opts)
            opts = opts or {}
            local para = create("Frame", {
                BackgroundColor3 = CurrentTheme.SecondaryBackground,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = container,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = para })
            create("UIPadding", {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
                Parent = para,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.GothamSemibold,
                Text = opts.Title or "",
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = para,
            })
            local contentLbl = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Gotham,
                Text = opts.Content or "",
                TextColor3 = CurrentTheme.TextSecondary,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Parent = para,
            })
            local function updateSize()
                local h = 34 + contentLbl.TextBounds.Y
                para.Size = UDim2.new(1, 0, 0, math.max(52, h))
            end
            contentLbl:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
            task.defer(updateSize)
            return para
        end

        function tab:CreateButton(opts)
            opts = opts or {}
            local btnName = opts.Name or "Button"
            local desc = opts.Description
            local callback = opts.Callback or function() end

            local height = desc and 54 or 38
            local btn = create("TextButton", {
                BackgroundColor3 = CurrentTheme.SecondaryBackground,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, height),
                Text = "",
                AutoButtonColor = false,
                Parent = container,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
            local stroke = create("UIStroke", {
                Color = CurrentTheme.Border,
                Thickness = 1,
                Parent = btn,
            })

            local nameLbl = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, desc and 7 or 0),
                Size = UDim2.new(1, -28, 0, 20),
                Font = Enum.Font.GothamSemibold,
                Text = btnName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btn,
            })
            if desc then
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0, 28),
                    Size = UDim2.new(1, -28, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = desc,
                    TextColor3 = CurrentTheme.TextSecondary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = btn,
                })
            end

            btn.MouseEnter:Connect(function()
                tween(btn, { BackgroundColor3 = AccentColor }, 0.15)
                tween(nameLbl, { TextColor3 = Color3.new(1, 1, 1) }, 0.15)
                tween(stroke, { Transparency = 1 }, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, { BackgroundColor3 = CurrentTheme.SecondaryBackground }, 0.18)
                tween(nameLbl, { TextColor3 = CurrentTheme.Text }, 0.18)
                tween(stroke, { Transparency = 0 }, 0.18)
            end)
            btn.MouseButton1Down:Connect(function()
                tween(btn, { BackgroundColor3 = AccentColor:Lerp(Color3.new(0, 0, 0), 0.18) }, 0.06)
            end)
            btn.MouseButton1Up:Connect(function()
                tween(btn, { BackgroundColor3 = AccentColor }, 0.08)
            end)
            btn.MouseButton1Click:Connect(function()
                safeCall(callback)
            end)
            return btn
        end

        function tab:CreateToggle(opts)
            opts = opts or {}
            local tName = opts.Name or "Toggle"
            local current = opts.CurrentValue or false
            local callback = opts.Callback or function() end
            local flag = opts.Flag or tName

            local frame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -64, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local track = create("Frame", {
                BackgroundColor3 = current and AccentColor or CurrentTheme.ToggleOff,
                Size = UDim2.new(0, 42, 0, 22),
                Position = UDim2.new(1, -48, 0.5, -11),
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
            local knob = create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(0, 16, 0, 16),
                Position = current and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                Parent = track,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local function set(val)
                current = val
                window.ConfigValues[flag] = val
                tween(track, { BackgroundColor3 = val and AccentColor or CurrentTheme.ToggleOff }, 0.18)
                tween(knob, {
                    Position = val and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                }, 0.22, Enum.EasingStyle.Back)
                safeCall(callback, val)
            end

            local btn = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                Parent = frame,
            })
            btn.MouseButton1Click:Connect(function()
                set(not current)
            end)

            if window.ConfigValues[flag] ~= nil then
                set(window.ConfigValues[flag])
            end

            return { Set = set, Get = function() return current end }
        end

        function tab:CreateSlider(opts)
            opts = opts or {}
            local sName = opts.Name or "Slider"
            local range = opts.Range or { 0, 100 }
            local increment = opts.Increment or 1
            local current = opts.CurrentValue or range[1]
            local callback = opts.Callback or function() end
            local flag = opts.Flag or sName

            local frame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 54),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -60, 0, 20),
                Font = Enum.Font.Gotham,
                Text = sName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })
            local valueLbl = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -54, 0, 0),
                Size = UDim2.new(0, 54, 0, 20),
                Font = Enum.Font.GothamMedium,
                Text = tostring(current),
                TextColor3 = AccentColor,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = frame,
            })

            local track = create("Frame", {
                BackgroundColor3 = CurrentTheme.Border,
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 0, 34),
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
            local fill = create("Frame", {
                BackgroundColor3 = AccentColor,
                Size = UDim2.new((current - range[1]) / math.max(range[2] - range[1], 1), 0, 1, 0),
                Parent = track,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
            local knob = create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new((current - range[1]) / math.max(range[2] - range[1], 1), -8, 0.5, -8),
                Parent = track,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
            create("UIStroke", { Color = AccentColor, Thickness = 2, Parent = knob })

            local sliding = false
            local function update(val, animate)
                val = clamp(math.floor(val / increment + 0.5) * increment, range[1], range[2])
                current = val
                window.ConfigValues[flag] = val
                local pct = (val - range[1]) / math.max(range[2] - range[1], 1)
                if animate then
                    tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.12)
                    tween(knob, { Position = UDim2.new(pct, -8, 0.5, -8) }, 0.12)
                else
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    knob.Position = UDim2.new(pct, -8, 0.5, -8)
                end
                valueLbl.Text = tostring(val)
                safeCall(callback, val)
            end

            local function onInput(input)
                local rel = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
                update(range[1] + rel * (range[2] - range[1]), false)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    onInput(input)
                    tween(knob, { Size = UDim2.new(0, 18, 0, 18) }, 0.1)
                end
            end)
            table.insert(window.Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if sliding then
                        sliding = false
                        tween(knob, { Size = UDim2.new(0, 16, 0, 16) }, 0.12)
                    end
                end
            end))
            table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    onInput(input)
                end
            end))

            if window.ConfigValues[flag] ~= nil then
                update(window.ConfigValues[flag], true)
            end
            return { Set = function(v) update(v, true) end, Get = function() return current end }
        end

        function tab:CreateDropdown(opts)
            opts = opts or {}
            local dName = opts.Name or "Dropdown"
            local optionsList = opts.Options or { "Option 1" }
            local current = opts.CurrentOption or optionsList[1]
            local callback = opts.Callback or function() end
            local flag = opts.Flag or dName

            local frame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38),
                ClipsDescendants = false,
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.42, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = dName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local dropBtn = create("TextButton", {
                BackgroundColor3 = CurrentTheme.InputBackground,
                Size = UDim2.new(0.55, 0, 0, 30),
                Position = UDim2.new(0.45, 0, 0.5, -15),
                Text = tostring(current) .. "  ▾",
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = dropBtn })
            create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = dropBtn })

            local open = false
            local listFrame
            dropBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    if listFrame then listFrame:Destroy() end
                    listFrame = create("Frame", {
                        BackgroundColor3 = CurrentTheme.SecondaryBackground,
                        Size = UDim2.new(0.55, 0, 0, 0),
                        Position = UDim2.new(0.45, 0, 1, 6),
                        ZIndex = 50,
                        ClipsDescendants = true,
                        Parent = frame,
                    })
                    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = listFrame })
                    create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = listFrame })
                    local listLayout = create("UIListLayout", { Parent = listFrame })

                    local targetH = math.min(#optionsList * 30, 150)
                    tween(listFrame, { Size = UDim2.new(0.55, 0, 0, targetH) }, 0.22, Enum.EasingStyle.Quart)

                    for i, opt in ipairs(optionsList) do
                        local optBtn = create("TextButton", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 30),
                            Text = "  " .. tostring(opt),
                            TextColor3 = CurrentTheme.Text,
                            TextSize = 12,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 51,
                            Parent = listFrame,
                        })
                        optBtn.MouseEnter:Connect(function()
                            tween(optBtn, { BackgroundTransparency = 0.85, BackgroundColor3 = AccentColor }, 0.1)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            tween(optBtn, { BackgroundTransparency = 1 }, 0.1)
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            current = opt
                            window.ConfigValues[flag] = opt
                            dropBtn.Text = tostring(current) .. "  ▾"
                            safeCall(callback, opt)
                            if listFrame then
                                tween(listFrame, { Size = UDim2.new(0.55, 0, 0, 0) }, 0.15)
                                task.delay(0.16, function()
                                    if listFrame then listFrame:Destroy() end
                                end)
                            end
                            open = false
                        end)
                    end
                else
                    if listFrame then
                        tween(listFrame, { Size = UDim2.new(0.55, 0, 0, 0) }, 0.15)
                        task.delay(0.16, function()
                            if listFrame then listFrame:Destroy() end
                        end)
                    end
                end
            end)

            if window.ConfigValues[flag] ~= nil then
                current = window.ConfigValues[flag]
                dropBtn.Text = tostring(current) .. "  ▾"
            end

            return {
                Set = function(v)
                    current = v
                    dropBtn.Text = tostring(v) .. "  ▾"
                    window.ConfigValues[flag] = v
                end,
                Get = function() return current end,
            }
        end

        function tab:CreateInput(opts)
            opts = opts or {}
            local iName = opts.Name or "Input"
            local placeholder = opts.PlaceholderText or "Enter text..."
            local callback = opts.Callback or function() end
            local flag = opts.Flag or iName

            local frame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.38, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = iName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })
            local box = create("TextBox", {
                BackgroundColor3 = CurrentTheme.InputBackground,
                Size = UDim2.new(0.58, 0, 0, 30),
                Position = UDim2.new(0.42, 0, 0.5, -15),
                Font = Enum.Font.Gotham,
                PlaceholderText = placeholder,
                PlaceholderColor3 = CurrentTheme.TextSecondary,
                Text = window.ConfigValues[flag] or "",
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                ClearTextOnFocus = false,
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
            local stroke = create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = box })
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = box })

            box.Focused:Connect(function()
                tween(stroke, { Color = AccentColor, Thickness = 1.5 }, 0.15)
            end)
            box.FocusLost:Connect(function()
                tween(stroke, { Color = CurrentTheme.Border, Thickness = 1 }, 0.15)
                window.ConfigValues[flag] = box.Text
                safeCall(callback, box.Text)
            end)
            return box
        end

        function tab:CreateKeybind(opts)
            opts = opts or {}
            local kName = opts.Name or "Keybind"
            local current = opts.CurrentKeybind or Enum.KeyCode.RightControl
            local callback = opts.Callback or function() end

            local frame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = kName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })
            local keyBtn = create("TextButton", {
                BackgroundColor3 = CurrentTheme.InputBackground,
                Size = UDim2.new(0, 110, 0, 28),
                Position = UDim2.new(1, -118, 0.5, -14),
                Text = current.Name,
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = keyBtn })
            create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = keyBtn })

            local listening = false
            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
                tween(keyBtn, { BackgroundColor3 = AccentColor }, 0.12)
                keyBtn.TextColor3 = Color3.new(1, 1, 1)
            end)
            table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, gp)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    current = input.KeyCode
                    keyBtn.Text = current.Name
                    listening = false
                    tween(keyBtn, { BackgroundColor3 = CurrentTheme.InputBackground }, 0.15)
                    keyBtn.TextColor3 = CurrentTheme.Text
                    safeCall(callback, current)
                end
            end))
            return { Get = function() return current end, Set = function(k) current = k; keyBtn.Text = k.Name end }
        end

        function tab:CreateColorPicker(opts)
            opts = opts or {}
            local cName = opts.Name or "Color"
            local color = opts.Color or AccentColor
            local callback = opts.Callback or function() end

            local frame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = cName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })
            local preview = create("TextButton", {
                BackgroundColor3 = color,
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -38, 0.5, -15),
                Text = "",
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = preview })
            create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = preview })

            local accents = {
                Color3.fromRGB(0, 120, 215),
                Color3.fromRGB(18, 140, 42),
                Color3.fromRGB(232, 17, 35),
                Color3.fromRGB(136, 23, 152),
                Color3.fromRGB(247, 99, 12),
                Color3.fromRGB(0, 153, 188),
                Color3.fromRGB(96, 205, 255),
                Color3.fromRGB(120, 120, 120),
            }
            local idx = 1
            for i, c in ipairs(accents) do
                if c == color then idx = i break end
            end
            preview.MouseButton1Click:Connect(function()
                idx = idx % #accents + 1
                color = accents[idx]
                tween(preview, { BackgroundColor3 = color }, 0.15)
                safeCall(callback, color)
            end)
            return {
                Set = function(c)
                    color = c
                    preview.BackgroundColor3 = c
                end,
                Get = function() return color end,
            }
        end

        return tab
    end

    function window:CreateSearch()
        -- Optional search box that can be placed in content if needed
        local searchFrame = create("Frame", {
            BackgroundColor3 = CurrentTheme.InputBackground,
            Size = UDim2.new(1, 0, 0, 32),
            Parent = contentScroll,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchFrame })
        create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = searchFrame })
        local box = create("TextBox", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -14, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Font = Enum.Font.Gotham,
            PlaceholderText = "Search...",
            PlaceholderColor3 = CurrentTheme.TextSecondary,
            Text = "",
            TextColor3 = CurrentTheme.Text,
            TextSize = 13,
            Parent = searchFrame,
        })
        return box
    end

    function window:Destroy()
        for _, conn in ipairs(window.Connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        if screenGui then
            screenGui:Destroy()
        end
        Windows[windowId] = nil
    end

    -- ============================================================
    -- Boot loading animation + open sequence
    -- ============================================================
    main.Visible = false
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1

    if showBoot then
        local boot, closeBoot = createBootLoader(screenGui, loadingTitle, loadingSubtitle, AccentColor)
        task.delay(bootDuration, function()
            closeBoot()
            task.wait(0.35)
            main.Visible = true
            main.Size = UDim2.new(0, 0, 0, 0)
            main.BackgroundTransparency = 0.5
            spring(main, { Size = mainSize, BackgroundTransparency = 0 }, 0.4)
        end)
    else
        main.Visible = true
        spring(main, { Size = mainSize, BackgroundTransparency = 0 }, 0.35)
    end

    Windows[windowId] = window
    return window
end

return WinUI
