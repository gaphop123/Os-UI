--[[
    WinUI - Windows 10 inspired Luau UI Library for Roblox
    Architecture inspired by Rayfield Gen2 style API
    Visual language: Windows 10 (Settings, title bar, Metro/Fluent controls)
    Pure Luau • Modular • Production-oriented

    v1.1.0 – Fixed icons, expanded themes, tab selection, theme apply, CoreGui fallback
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
local VERSION = "1.1.0"

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

local function tween(obj, props, duration, style, dir)
    duration = duration or 0.18
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(duration, style, dir), props)
    t:Play()
    return t
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
    },
    Windows10Dark = {
        Name = "Windows10Dark",
        Accent = Color3.fromRGB(0, 120, 215),
        Background = Color3.fromRGB(32, 32, 32),
        SecondaryBackground = Color3.fromRGB(45, 45, 45),
        Sidebar = Color3.fromRGB(25, 25, 25),
        TitleBar = Color3.fromRGB(32, 32, 32),
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
    },
    Windows10Light = {
        Name = "Windows10Light",
        Accent = Color3.fromRGB(0, 120, 215),
        Background = Color3.fromRGB(245, 245, 245),
        SecondaryBackground = Color3.fromRGB(255, 255, 255),
        Sidebar = Color3.fromRGB(235, 235, 235),
        TitleBar = Color3.fromRGB(255, 255, 255),
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
    },
    Blue = {
        Name = "Blue",
        Accent = Color3.fromRGB(0, 99, 177),
        Background = Color3.fromRGB(32, 32, 32),
        SecondaryBackground = Color3.fromRGB(40, 40, 45),
        Sidebar = Color3.fromRGB(25, 25, 30),
        TitleBar = Color3.fromRGB(32, 32, 32),
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
    },
    Gray = {
        Name = "Gray",
        Accent = Color3.fromRGB(120, 120, 120),
        Background = Color3.fromRGB(40, 40, 40),
        SecondaryBackground = Color3.fromRGB(50, 50, 50),
        Sidebar = Color3.fromRGB(30, 30, 30),
        TitleBar = Color3.fromRGB(40, 40, 40),
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
    },
    -- Extra themes
    DarkBlue = {
        Name = "DarkBlue",
        Accent = Color3.fromRGB(0, 153, 255),
        Background = Color3.fromRGB(18, 22, 32),
        SecondaryBackground = Color3.fromRGB(28, 34, 48),
        Sidebar = Color3.fromRGB(14, 18, 28),
        TitleBar = Color3.fromRGB(22, 28, 40),
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
    },
    Purple = {
        Name = "Purple",
        Accent = Color3.fromRGB(136, 23, 152),
        Background = Color3.fromRGB(30, 28, 36),
        SecondaryBackground = Color3.fromRGB(42, 38, 52),
        Sidebar = Color3.fromRGB(24, 22, 30),
        TitleBar = Color3.fromRGB(30, 28, 36),
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
    },
    Green = {
        Name = "Green",
        Accent = Color3.fromRGB(16, 137, 62),
        Background = Color3.fromRGB(28, 32, 28),
        SecondaryBackground = Color3.fromRGB(38, 44, 38),
        Sidebar = Color3.fromRGB(22, 26, 22),
        TitleBar = Color3.fromRGB(28, 32, 28),
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
    },
    Orange = {
        Name = "Orange",
        Accent = Color3.fromRGB(247, 99, 12),
        Background = Color3.fromRGB(36, 30, 26),
        SecondaryBackground = Color3.fromRGB(48, 40, 34),
        Sidebar = Color3.fromRGB(28, 24, 20),
        TitleBar = Color3.fromRGB(36, 30, 26),
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
    },
    FluentDark = {
        Name = "FluentDark",
        Accent = Color3.fromRGB(96, 205, 255),
        Background = Color3.fromRGB(32, 32, 32),
        SecondaryBackground = Color3.fromRGB(44, 44, 44),
        Sidebar = Color3.fromRGB(26, 26, 26),
        TitleBar = Color3.fromRGB(32, 32, 32),
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
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = notif })
    create("UIStroke", {
        Color = CurrentTheme.Border,
        Thickness = 1,
        Transparency = 0.4,
        Parent = notif,
    })

    create("Frame", {
        BackgroundColor3 = AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = notif,
    })

    if icon then
        create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 14, 0, 10),
            Image = resolveIcon(icon),
            ImageColor3 = CurrentTheme.NotificationText,
            Parent = notif,
        })
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
        Parent = notif,
    })

    -- Proper size after layout
    task.defer(function()
        if not notif or not notif.Parent then return end
        local h = math.max(70, 42 + contentLabel.TextBounds.Y + 14)
        notif.Size = UDim2.new(0, 320, 0, h)
    end)

    notif.Position = UDim2.new(1, 20, 0, 0)
    tween(notif, { Position = UDim2.new(0, 0, 0, 0) }, 0.25, Enum.EasingStyle.Quart)

    local closed = false
    local function close()
        if closed then return end
        closed = true
        tween(notif, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 }, 0.22)
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

-- Main Window Creator
function WinUI:CreateWindow(options)
    options = options or {}
    local name = options.Name or "WinUI"
    local loadingTitle = options.LoadingTitle or name
    local loadingSubtitle = options.LoadingSubtitle or "Windows 10 UI Library"
    local themeName = options.Theme or "Windows10"
    local config = options.ConfigurationSaving or { Enabled = false }

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
        ThemeElements = {}, -- track elements for full theme reapply
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

    local mainSize = IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 720, 0, 480)
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
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = main })
    local mainStroke = create("UIStroke", {
        Color = CurrentTheme.Border,
        Thickness = 1,
        Parent = main,
    })

    create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = CurrentTheme.Shadow,
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 40, 1, 40),
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
        Size = UDim2.new(1, 0, 0, 32),
        Parent = main,
    })
    window.TitleBar = titleBar

    local titleText = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -120, 1, 0),
        Font = Enum.Font.Gotham,
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
                hover.BackgroundTransparency = 0
                btn.TextColor3 = Color3.new(1, 1, 1)
            else
                hover.BackgroundTransparency = CurrentTheme.HoverTransparency
            end
        end)
        btn.MouseLeave:Connect(function()
            hover.BackgroundTransparency = 1
            btn.TextColor3 = CurrentTheme.Text
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
            tween(main, { Size = UDim2.new(0, main.AbsoluteSize.X, 0, 32) }, 0.2)
        else
            tween(main, { Size = mainSize }, 0.2)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        window:Destroy()
    end)

    maxBtn.MouseButton1Click:Connect(function()
        if main.Size.X.Scale > 0.9 then
            tween(main, { Size = mainSize, Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        else
            tween(main, { Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        end
    end)

    -- Body
    local body = create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 1, -56),
        Parent = main,
    })

    local sidebarWidth = IsMobile and 0 or 180
    local sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = CurrentTheme.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        Parent = body,
    })
    window.Sidebar = sidebar

    create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = sidebar,
    })

    local content = create("Frame", {
        Name = "Content",
        BackgroundColor3 = CurrentTheme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, sidebarWidth, 0, 0),
        Size = UDim2.new(1, -sidebarWidth, 1, 0),
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
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
        Parent = contentScroll,
    })
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 24)
    end)

    local statusBar = create("Frame", {
        Name = "StatusBar",
        BackgroundColor3 = CurrentTheme.StatusBar or CurrentTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -24),
        Parent = main,
    })
    local statusLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Font = Enum.Font.Gotham,
        Text = name .. " • " .. VERSION,
        TextColor3 = CurrentTheme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusBar,
    })

    if IsMobile then
        local mobileToggle = create("TextButton", {
            Name = "MobileNav",
            BackgroundColor3 = AccentColor,
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(0, 8, 0, 40),
            Text = "≡",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            Parent = main,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = mobileToggle })
        local sidebarOpen = false
        mobileToggle.MouseButton1Click:Connect(function()
            sidebarOpen = not sidebarOpen
            if sidebarOpen then
                sidebar.Size = UDim2.new(0, 180, 1, 0)
                content.Position = UDim2.new(0, 180, 0, 0)
                content.Size = UDim2.new(1, -180, 1, 0)
            else
                sidebar.Size = UDim2.new(0, 0, 1, 0)
                content.Position = UDim2.new(0, 0, 0, 0)
                content.Size = UDim2.new(1, 0, 1, 0)
            end
        end)
    end

    function window:ApplyTheme()
        main.BackgroundColor3 = CurrentTheme.Background
        mainStroke.Color = CurrentTheme.Border
        titleBar.BackgroundColor3 = CurrentTheme.TitleBar
        titleText.TextColor3 = CurrentTheme.Text
        sidebar.BackgroundColor3 = CurrentTheme.Sidebar
        content.BackgroundColor3 = CurrentTheme.Background
        statusBar.BackgroundColor3 = CurrentTheme.StatusBar or CurrentTheme.SecondaryBackground
        statusLabel.TextColor3 = CurrentTheme.TextSecondary
        contentScroll.ScrollBarImageColor3 = AccentColor

        for _, tab in ipairs(window.Tabs) do
            if tab.Icon then
                tab.Icon.ImageColor3 = (window.CurrentTab == tab) and AccentColor or CurrentTheme.TextSecondary
            end
            if tab.Label then
                tab.Label.TextColor3 = (window.CurrentTab == tab) and AccentColor or CurrentTheme.Text
            end
            if tab.Indicator then
                tab.Indicator.BackgroundColor3 = AccentColor
            end
        end
    end

    function window:Toggle()
        window.Visible = not window.Visible
        main.Visible = window.Visible
    end

    local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == toggleKey then
            window:Toggle()
        end
    end))

    -- CreateTab
    function window:CreateTab(tabName, iconName)
        local tabId = HttpService:GenerateGUID(false)
        local tab = {
            Name = tabName,
            Id = tabId,
            Elements = {},
            Container = nil,
        }

        local item = create("TextButton", {
            Name = tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 36),
            Text = "",
            Parent = sidebar,
        })
        local indicator = create("Frame", {
            Name = "Indicator",
            BackgroundColor3 = AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            Visible = false,
            Parent = item,
        })
        local icon = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 12, 0.5, -9),
            Image = resolveIcon(iconName),
            ImageColor3 = CurrentTheme.TextSecondary,
            Parent = item,
        })
        local label = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 40, 0, 0),
            Size = UDim2.new(1, -50, 1, 0),
            Font = Enum.Font.Gotham,
            Text = tabName,
            TextColor3 = CurrentTheme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = item,
        })

        local hoverFrame = create("Frame", {
            Name = "Hover",
            BackgroundColor3 = CurrentTheme.Hover,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0,
            Parent = item,
        })

        item.MouseEnter:Connect(function()
            if window.CurrentTab ~= tab then
                hoverFrame.BackgroundTransparency = CurrentTheme.HoverTransparency
            end
        end)
        item.MouseLeave:Connect(function()
            hoverFrame.BackgroundTransparency = 1
        end)

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

        local function selectTab()
            -- Deselect previous
            if window.CurrentTab and window.CurrentTab ~= tab then
                local prev = window.CurrentTab
                if prev.Container then
                    prev.Container.Visible = false
                end
                if prev.Indicator then
                    prev.Indicator.Visible = false
                end
                if prev.Icon then
                    prev.Icon.ImageColor3 = CurrentTheme.TextSecondary
                end
                if prev.Label then
                    prev.Label.TextColor3 = CurrentTheme.Text
                end
            end

            indicator.Visible = true
            icon.ImageColor3 = AccentColor
            label.TextColor3 = AccentColor
            container.Visible = true
            window.CurrentTab = tab
            hoverFrame.BackgroundTransparency = 1
        end

        item.MouseButton1Click:Connect(selectTab)

        if #window.Tabs == 0 then
            task.defer(selectTab)
        end

        table.insert(window.Tabs, tab)
        tab.Item = item
        tab.Indicator = indicator
        tab.Icon = icon
        tab.Label = label

        -- Components
        function tab:CreateSection(text)
            local section = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamSemibold,
                Text = text or "Section",
                TextColor3 = CurrentTheme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section,
            })
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
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = para })
            create("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
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
                local h = 32 + contentLbl.TextBounds.Y
                para.Size = UDim2.new(1, 0, 0, math.max(50, h))
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

            local height = desc and 52 or 36
            local btn = create("TextButton", {
                BackgroundColor3 = CurrentTheme.SecondaryBackground,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, height),
                Text = "",
                AutoButtonColor = false,
                Parent = container,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
            create("UIStroke", {
                Color = CurrentTheme.Border,
                Thickness = 1,
                Parent = btn,
            })

            local nameLbl = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, desc and 6 or 0),
                Size = UDim2.new(1, -24, 0, 20),
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
                    Position = UDim2.new(0, 12, 0, 26),
                    Size = UDim2.new(1, -24, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = desc,
                    TextColor3 = CurrentTheme.TextSecondary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = btn,
                })
            end

            btn.MouseEnter:Connect(function()
                tween(btn, { BackgroundColor3 = AccentColor }, 0.12)
                nameLbl.TextColor3 = Color3.new(1, 1, 1)
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, { BackgroundColor3 = CurrentTheme.SecondaryBackground }, 0.12)
                nameLbl.TextColor3 = CurrentTheme.Text
            end)
            btn.MouseButton1Down:Connect(function()
                tween(btn, { BackgroundColor3 = AccentColor:Lerp(Color3.new(0, 0, 0), 0.15) }, 0.06)
            end)
            btn.MouseButton1Up:Connect(function()
                tween(btn, { BackgroundColor3 = AccentColor }, 0.06)
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
                Size = UDim2.new(1, 0, 0, 36),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local track = create("Frame", {
                BackgroundColor3 = current and AccentColor or CurrentTheme.ToggleOff,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -44, 0.5, -10),
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
            local knob = create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(0, 16, 0, 16),
                Position = current and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                Parent = track,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local function set(val)
                current = val
                window.ConfigValues[flag] = val
                tween(track, { BackgroundColor3 = val and AccentColor or CurrentTheme.ToggleOff }, 0.15)
                tween(knob, { Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.15)
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
                Size = UDim2.new(1, 0, 0, 52),
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
                Position = UDim2.new(1, -50, 0, 0),
                Size = UDim2.new(0, 50, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(current),
                TextColor3 = CurrentTheme.TextSecondary,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = frame,
            })

            local track = create("Frame", {
                BackgroundColor3 = CurrentTheme.Border,
                Size = UDim2.new(1, 0, 0, 4),
                Position = UDim2.new(0, 0, 0, 32),
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
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new((current - range[1]) / math.max(range[2] - range[1], 1), -7, 0.5, -7),
                Parent = track,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
            create("UIStroke", { Color = AccentColor, Thickness = 1, Parent = knob })

            local sliding = false
            local function update(val)
                val = clamp(math.floor(val / increment + 0.5) * increment, range[1], range[2])
                current = val
                window.ConfigValues[flag] = val
                local pct = (val - range[1]) / math.max(range[2] - range[1], 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, -7, 0.5, -7)
                valueLbl.Text = tostring(val)
                safeCall(callback, val)
            end

            local function onInput(input)
                local rel = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
                update(range[1] + rel * (range[2] - range[1]))
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    onInput(input)
                end
            end)
            table.insert(window.Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end))
            table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    onInput(input)
                end
            end))

            if window.ConfigValues[flag] ~= nil then
                update(window.ConfigValues[flag])
            end
            return { Set = update, Get = function() return current end }
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
                Size = UDim2.new(1, 0, 0, 36),
                ClipsDescendants = false,
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.45, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = dName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local dropBtn = create("TextButton", {
                BackgroundColor3 = CurrentTheme.InputBackground,
                Size = UDim2.new(0.5, 0, 0, 28),
                Position = UDim2.new(0.5, 0, 0.5, -14),
                Text = tostring(current) .. "  ▼",
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dropBtn })
            create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = dropBtn })

            local open = false
            local listFrame
            dropBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    if listFrame then listFrame:Destroy() end
                    listFrame = create("Frame", {
                        BackgroundColor3 = CurrentTheme.SecondaryBackground,
                        Size = UDim2.new(0.5, 0, 0, math.min(#optionsList * 28, 140)),
                        Position = UDim2.new(0.5, 0, 1, 4),
                        ZIndex = 50,
                        Parent = frame,
                    })
                    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = listFrame })
                    create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = listFrame })
                    create("UIListLayout", { Parent = listFrame })
                    for _, opt in ipairs(optionsList) do
                        local optBtn = create("TextButton", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 28),
                            Text = "  " .. tostring(opt),
                            TextColor3 = CurrentTheme.Text,
                            TextSize = 12,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 51,
                            Parent = listFrame,
                        })
                        optBtn.MouseEnter:Connect(function()
                            optBtn.BackgroundTransparency = 0.85
                            optBtn.BackgroundColor3 = AccentColor
                        end)
                        optBtn.MouseLeave:Connect(function()
                            optBtn.BackgroundTransparency = 1
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            current = opt
                            window.ConfigValues[flag] = opt
                            dropBtn.Text = tostring(current) .. "  ▼"
                            safeCall(callback, opt)
                            if listFrame then listFrame:Destroy() end
                            open = false
                        end)
                    end
                else
                    if listFrame then listFrame:Destroy() end
                end
            end)

            if window.ConfigValues[flag] ~= nil then
                current = window.ConfigValues[flag]
                dropBtn.Text = tostring(current) .. "  ▼"
            end

            return {
                Set = function(v)
                    current = v
                    dropBtn.Text = tostring(v) .. "  ▼"
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
                Size = UDim2.new(1, 0, 0, 36),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = iName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })
            local box = create("TextBox", {
                BackgroundColor3 = CurrentTheme.InputBackground,
                Size = UDim2.new(0.55, 0, 0, 28),
                Position = UDim2.new(0.45, 0, 0.5, -14),
                Font = Enum.Font.Gotham,
                PlaceholderText = placeholder,
                PlaceholderColor3 = CurrentTheme.TextSecondary,
                Text = window.ConfigValues[flag] or "",
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                ClearTextOnFocus = false,
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
            create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = box })
            create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = box })

            box.FocusLost:Connect(function()
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
                Size = UDim2.new(1, 0, 0, 36),
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
                Size = UDim2.new(0, 100, 0, 26),
                Position = UDim2.new(1, -110, 0.5, -13),
                Text = current.Name,
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = keyBtn })
            create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = keyBtn })

            local listening = false
            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
            end)
            table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, gp)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    current = input.KeyCode
                    keyBtn.Text = current.Name
                    listening = false
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
                Size = UDim2.new(1, 0, 0, 36),
                Parent = container,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 1, 0),
                Font = Enum.Font.Gotham,
                Text = cName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })
            local preview = create("TextButton", {
                BackgroundColor3 = color,
                Size = UDim2.new(0, 28, 0, 28),
                Position = UDim2.new(1, -36, 0.5, -14),
                Text = "",
                Parent = frame,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = preview })
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
                preview.BackgroundColor3 = color
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
        local searchFrame = create("Frame", {
            BackgroundColor3 = CurrentTheme.InputBackground,
            Size = UDim2.new(1, -12, 0, 28),
            Parent = sidebar,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = searchFrame })
        create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = searchFrame })
        local box = create("TextBox", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            Font = Enum.Font.Gotham,
            PlaceholderText = "Search...",
            PlaceholderColor3 = CurrentTheme.TextSecondary,
            Text = "",
            TextColor3 = CurrentTheme.Text,
            TextSize = 12,
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

    -- Open animation
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    tween(main, { Size = mainSize, BackgroundTransparency = 0 }, 0.28, Enum.EasingStyle.Quart)

    Windows[windowId] = window

    if options.LoadingTitle then
        local loading = create("Frame", {
            BackgroundColor3 = CurrentTheme.Background,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 100,
            Parent = main,
        })
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0.4, 0),
            Font = Enum.Font.GothamSemibold,
            Text = loadingTitle,
            TextColor3 = CurrentTheme.Text,
            TextSize = 18,
            Parent = loading,
        })
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0, 0, 0.4, 32),
            Font = Enum.Font.Gotham,
            Text = loadingSubtitle,
            TextColor3 = CurrentTheme.TextSecondary,
            TextSize = 13,
            Parent = loading,
        })
        task.delay(1.2, function()
            tween(loading, { BackgroundTransparency = 1 }, 0.3)
            task.wait(0.3)
            if loading and loading.Parent then
                loading:Destroy()
            end
        end)
    end

    return window
end

return WinUI
