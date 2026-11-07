--[[
    WinUI v3.0.0 - Windows 11 / PowerToys inspired Luau UI Library for Roblox
    Visual language: Win11 Fluent (Mica surfaces, NavigationView, SettingsCard rows,
    toggle pills, InfoBars) styled after Microsoft PowerToys' settings app.
    Pure Luau - Modular - Production-oriented

    API shape: Window -> CreateTab(icon+label in a left NavigationView)
                       -> Tab:CreateSection(a "SettingsCard" group)
                           -> Section:CreateToggle / CreateSlider / CreateDropdown / ...
]]

local WinUI = {}
WinUI.__index = WinUI

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LIBRARY_NAME = "WinUI"
local VERSION = "3.0.0"

-- ============================================================
-- Utility
-- ============================================================
local function safeCall(fn, ...)
    if not fn then return true end
    local ok, result = pcall(fn, ...)
    if not ok then warn("[WinUI] Error:", result) end
    return ok, result
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deepCopy(v) end
    return copy
end

local function clamp(n, min, max) return math.clamp(n, min, max) end

local function create(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
        if props.Parent then inst.Parent = props.Parent end
    end
    if children then
        for _, child in ipairs(children) do child.Parent = inst end
    end
    return inst
end

local function tween(obj, props, duration, style, dir)
    duration = duration or 0.18
    style = style or Enum.EasingStyle.Quint
    dir = dir or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(duration, style, dir), props)
    t:Play()
    return t
end

local function getGuiParent()
    local ok = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
    end)
    return ok and CoreGui or PlayerGui
end

local FONT_HEADER = Enum.Font.GothamBold
local FONT_TITLE = Enum.Font.GothamSemibold
local FONT_BODY = Enum.Font.Gotham

-- ============================================================
-- Fluent / Win11 icon set (Lucide-style asset ids)
-- ============================================================
local Icons = {
    home = "rbxassetid://10723407389", settings = "rbxassetid://10734950309",
    user = "rbxassetid://10747373176", eye = "rbxassetid://10723346959",
    sword = "rbxassetid://10734975486", box = "rbxassetid://10709782497",
    info = "rbxassetid://10723415903", search = "rbxassetid://10734943674",
    grid = "rbxassetid://10723439906", keyboard = "rbxassetid://10734943017",
    mouse = "rbxassetid://10709790644", image = "rbxassetid://10723407867",
    text = "rbxassetid://10734893084", color = "rbxassetid://10734884940",
    puzzle = "rbxassetid://10734881866", star = "rbxassetid://10734950309",
    shield = "rbxassetid://10734975486",
}
local function resolveIcon(name)
    if not name or name == "" then return Icons.home end
    if typeof(name) == "string" and string.find(name, "rbxasset") then return name end
    return Icons[string.lower(tostring(name))] or Icons.home
end

-- ============================================================
-- Theme Engine - Windows 11 Mica + PowerToys accent palette
-- ============================================================
local Themes = {
    ["Windows 11 Dark"] = {
        Accent = Color3.fromRGB(0, 120, 212),
        Background = Color3.fromRGB(32, 32, 32),
        Card = Color3.fromRGB(44, 44, 44),
        CardHover = Color3.fromRGB(50, 50, 50),
        Nav = Color3.fromRGB(28, 28, 28),
        TitleBar = Color3.fromRGB(32, 32, 32),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(190, 190, 190),
        Border = Color3.fromRGB(62, 62, 62),
        Divider = Color3.fromRGB(55, 55, 55),
        ControlOff = Color3.fromRGB(100, 100, 100),
        InputBackground = Color3.fromRGB(54, 54, 54),
    },
    ["Windows 11 Light"] = {
        Accent = Color3.fromRGB(0, 103, 192),
        Background = Color3.fromRGB(243, 243, 243),
        Card = Color3.fromRGB(251, 251, 251),
        CardHover = Color3.fromRGB(246, 246, 246),
        Nav = Color3.fromRGB(235, 235, 235),
        TitleBar = Color3.fromRGB(243, 243, 243),
        Text = Color3.fromRGB(26, 26, 26),
        TextSecondary = Color3.fromRGB(96, 96, 96),
        Border = Color3.fromRGB(215, 215, 215),
        Divider = Color3.fromRGB(226, 226, 226),
        ControlOff = Color3.fromRGB(170, 170, 170),
        InputBackground = Color3.fromRGB(255, 255, 255),
    },
    ["PowerToys Dark"] = {
        Accent = Color3.fromRGB(0, 153, 136),
        Background = Color3.fromRGB(30, 30, 30),
        Card = Color3.fromRGB(40, 40, 40),
        CardHover = Color3.fromRGB(46, 46, 46),
        Nav = Color3.fromRGB(24, 24, 24),
        TitleBar = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(245, 245, 245),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Border = Color3.fromRGB(58, 58, 58),
        Divider = Color3.fromRGB(52, 52, 52),
        ControlOff = Color3.fromRGB(95, 95, 95),
        InputBackground = Color3.fromRGB(50, 50, 50),
    },
    ["Mica Blue"] = {
        Accent = Color3.fromRGB(76, 194, 255),
        Background = Color3.fromRGB(20, 26, 36),
        Card = Color3.fromRGB(28, 36, 50),
        CardHover = Color3.fromRGB(33, 42, 58),
        Nav = Color3.fromRGB(16, 21, 30),
        TitleBar = Color3.fromRGB(20, 26, 36),
        Text = Color3.fromRGB(240, 246, 255),
        TextSecondary = Color3.fromRGB(160, 175, 195),
        Border = Color3.fromRGB(48, 60, 80),
        Divider = Color3.fromRGB(40, 52, 70),
        ControlOff = Color3.fromRGB(80, 92, 112),
        InputBackground = Color3.fromRGB(32, 42, 58),
    },
}

local CurrentTheme = deepCopy(Themes["Windows 11 Dark"])
local AccentColor = CurrentTheme.Accent
local Windows = {}

-- ============================================================
-- Toast notifications (Win11 style)
-- ============================================================
local NotifGui
local function ensureNotifGui()
    if NotifGui and NotifGui.Parent then return NotifGui end
    NotifGui = create("ScreenGui", {
        Name = "WinUI_Notifications", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
        Parent = getGuiParent(),
    })
    local holder = create("Frame", {
        Name = "Holder", BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, 0), Position = UDim2.new(1, -332, 0, 0),
        Parent = NotifGui,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder,
    })
    create("UIPadding", { PaddingBottom = UDim.new(0, 16), PaddingRight = UDim.new(0, 12), Parent = holder })
    return NotifGui
end

local StyleColors = {
    Info = Color3.fromRGB(0, 120, 212), Success = Color3.fromRGB(16, 124, 16),
    Warning = Color3.fromRGB(157, 93, 0), Danger = Color3.fromRGB(196, 43, 28),
    Error = Color3.fromRGB(196, 43, 28),
}

function WinUI:Notify(opts)
    opts = opts or {}
    ensureNotifGui()
    local holder = NotifGui.Holder
    local style = StyleColors[opts.Style] or AccentColor
    local notif = create("Frame", {
        BackgroundColor3 = CurrentTheme.Card, Size = UDim2.new(0, 304, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true, Parent = holder,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
    create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = notif })
    create("Frame", { BackgroundColor3 = style, Size = UDim2.new(0, 3, 1, 0), Parent = notif })
    local pad = create("UIPadding", {
        PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), Parent = notif,
    })
    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
        Font = FONT_TITLE, Text = opts.Title or LIBRARY_NAME, TextColor3 = CurrentTheme.Text,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = notif,
    })
    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 0, 0, 20), Font = FONT_BODY, Text = opts.Content or "",
        TextColor3 = CurrentTheme.TextSecondary, TextSize = 13, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = notif,
    })
    notif.BackgroundTransparency = 1
    tween(notif, { BackgroundTransparency = 0 }, 0.2)
    task.delay(opts.Duration or 4, function()
        if notif and notif.Parent then
            tween(notif, { BackgroundTransparency = 1 }, 0.2)
            task.delay(0.22, function() if notif then notif:Destroy() end end)
        end
    end)
    return notif
end

function WinUI:SetTheme(name)
    local t = Themes[name]
    if not t then return end
    CurrentTheme = deepCopy(t)
    AccentColor = CurrentTheme.Accent
    for _, w in pairs(Windows) do if w._applyTheme then w._applyTheme() end end
end

function WinUI:RegisterTheme(name, theme) Themes[name] = theme end

-- ============================================================
-- Main window builder
-- ============================================================
function WinUI:CreateWindow(opts)
    opts = opts or {}
    local name = opts.Name or "WinUI"
    local subtitle = opts.Subtitle or ""
    if opts.Theme and Themes[opts.Theme] then
        CurrentTheme = deepCopy(Themes[opts.Theme])
        AccentColor = opts.Accent or CurrentTheme.Accent
    end
    local size = opts.Size or UDim2.new(0, 840, 0, 540)
    local minSize = opts.MinSize or Vector2.new(620, 400)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightControl
    local navCollapsedDefault = opts.NavCollapsed or false

    local screenGui = create("ScreenGui", {
        Name = "WinUI_" .. name, ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
        Parent = getGuiParent(),
    })

    -- Window shell (Mica card)
    local main = create("Frame", {
        Name = "Main", BackgroundColor3 = CurrentTheme.Background,
        Size = size, Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        ClipsDescendants = true, Parent = screenGui,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = main })
    local mainStroke = create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = main })
    local sizeConstraint = create("UISizeConstraint", { MinSize = minSize, Parent = main })

    -- ---------------- Title bar ----------------
    local titleBar = create("Frame", {
        Name = "TitleBar", BackgroundColor3 = CurrentTheme.TitleBar,
        Size = UDim2.new(1, 0, 0, 40), Parent = main,
    })
    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -220, 1, 0),
        Font = FONT_TITLE, Text = subtitle ~= "" and (name .. "  -  " .. subtitle) or name,
        TextColor3 = CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = titleBar,
    })

    local captionHolder = create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 138, 1, 0), Parent = titleBar,
    })
    create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = captionHolder })

    local function captionBtn(glyph, hoverColor, isClose)
        local btn = create("TextButton", {
            BackgroundColor3 = CurrentTheme.TitleBar, BackgroundTransparency = 1,
            Size = UDim2.new(0, 46, 1, 0), Text = glyph, Font = FONT_BODY,
            TextSize = 11, TextColor3 = CurrentTheme.Text, Parent = captionHolder,
        })
        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0 }, 0.1)
            if isClose then tween(btn, { TextColor3 = Color3.new(1, 1, 1) }, 0.1) end
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundTransparency = 1 }, 0.1)
            if isClose then tween(btn, { TextColor3 = CurrentTheme.Text }, 0.1) end
        end)
        return btn
    end
    local minBtn = captionBtn("\226\128\148", CurrentTheme.CardHover, false)
    local maxBtn = captionBtn("\226\150\161", CurrentTheme.CardHover, false)
    local closeBtn = captionBtn("\226\156\149", Color3.fromRGB(196, 43, 28), true)

    -- Drag window
    do
        local dragging, dragStart, startPos = false, nil, nil
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = input.Position; startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- ---------------- Left NavigationView ----------------
    local NAV_W, NAV_COLLAPSED_W = 208, 52
    local navCollapsed = navCollapsedDefault
    local nav = create("Frame", {
        Name = "Nav", BackgroundColor3 = CurrentTheme.Nav,
        Size = UDim2.new(0, navCollapsed and NAV_COLLAPSED_W or NAV_W, 1, -40),
        Position = UDim2.new(0, 0, 0, 40), Parent = main,
    })
    local hamburger = create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Text = "\226\152\176",
        Font = FONT_BODY, TextSize = 16, TextColor3 = CurrentTheme.Text, Parent = nav,
    })
    local navList = create("ScrollingFrame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44), ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y, Parent = nav,
    })
    create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = navList })
    create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), Parent = navList })

    local navDivider = create("Frame", { BackgroundColor3 = CurrentTheme.Border, Size = UDim2.new(0, 1, 1, -40), Position = UDim2.new(1, 0, 0, 40), Parent = main })

    -- ---------------- Content area ----------------
    local content = create("Frame", {
        Name = "Content", BackgroundTransparency = 1,
        Position = UDim2.new(0, (navCollapsed and NAV_COLLAPSED_W or NAV_W) + 1, 0, 40),
        Size = UDim2.new(1, -((navCollapsed and NAV_COLLAPSED_W or NAV_W) + 1), 1, -40), Parent = main,
    })
    local pageHeader = create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 16), Size = UDim2.new(1, -48, 0, 32),
        Font = FONT_HEADER, Text = "", TextColor3 = CurrentTheme.Text, TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = content,
    })
    local pageScroll = create("ScrollingFrame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 56), Size = UDim2.new(1, -40, 1, -72),
        ScrollBarThickness = 4, ScrollBarImageColor3 = CurrentTheme.TextSecondary,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y, Parent = content,
    })
    create("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pageScroll })

    hamburger.MouseButton1Click:Connect(function()
        navCollapsed = not navCollapsed
        local w = navCollapsed and NAV_COLLAPSED_W or NAV_W
        tween(nav, { Size = UDim2.new(0, w, 1, -40) }, 0.18)
        tween(navDivider, { Position = UDim2.new(0, w, 0, 40) }, 0.18)
        tween(content, { Position = UDim2.new(0, w + 1, 0, 40), Size = UDim2.new(1, -(w + 1), 1, -40) }, 0.18)
        for _, child in ipairs(navList:GetChildren()) do
            if child:IsA("TextButton") then
                local lbl = child:FindFirstChild("Label")
                if lbl then tween(lbl, { TextTransparency = navCollapsed and 1 or 0 }, 0.15) end
            end
        end
    end)

    -- ---------------- Window object ----------------
    local window = {}
    window.Tabs = {}
    window.ConfigValues = {}
    window._navSelector = nil
    local tabOrder = 0

    window._applyTheme = function()
        main.BackgroundColor3 = CurrentTheme.Background
        mainStroke.Color = CurrentTheme.Border
        titleBar.BackgroundColor3 = CurrentTheme.TitleBar
        nav.BackgroundColor3 = CurrentTheme.Nav
        navDivider.BackgroundColor3 = CurrentTheme.Border
        pageHeader.TextColor3 = CurrentTheme.Text
    end

    function window:SetTitle(newName, newSub)
        name, subtitle = newName or name, newSub or subtitle
    end

    function window:Minimize()
        tween(main, { Size = UDim2.new(0, main.Size.X.Offset, 0, 40) }, 0.2)
        nav.Visible, content.Visible = false, false
    end
    function window:Maximize()
        nav.Visible, content.Visible = true, true
        tween(main, { Size = size }, 0.2)
    end
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then window:Minimize() else window:Maximize() end
    end)
    maxBtn.MouseButton1Click:Connect(function()
        local screen = workspace.CurrentCamera.ViewportSize
        if main.Size == size then
            tween(main, { Size = UDim2.new(0, screen.X - 40, 0, screen.Y - 60), Position = UDim2.new(0, 20, 0, 20) }, 0.2)
        else
            tween(main, { Size = size, Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2) }, 0.2)
        end
    end)
    closeBtn.MouseButton1Click:Connect(function() window:Toggle() end)

    local visible = true
    function window:Toggle()
        visible = not visible
        main.Visible = visible
    end
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == toggleKey then window:Toggle() end
    end)

    -- ============================================================
    -- Tabs (NavigationView items)
    -- ============================================================
    function window:CreateTab(topts)
        topts = topts or {}
        tabOrder += 1
        local tabName = topts.Name or ("Tab " .. tabOrder)
        local icon = resolveIcon(topts.Icon)

        local navBtn = create("TextButton", {
            Name = tabName, BackgroundTransparency = 1, Text = "",
            Size = UDim2.new(1, 0, 0, 36), LayoutOrder = tabOrder, Parent = navList,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = navBtn })
        local indicator = create("Frame", {
            BackgroundColor3 = AccentColor, Size = UDim2.new(0, 3, 0, 0),
            Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = navBtn,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })
        create("ImageLabel", {
            BackgroundTransparency = 1, Image = icon, ImageColor3 = CurrentTheme.Text,
            Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 14, 0.5, -9), Parent = navBtn,
        })
        create("TextLabel", {
            Name = "Label", BackgroundTransparency = 1, Font = FONT_BODY, Text = tabName,
            TextColor3 = CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -50, 1, 0), Parent = navBtn,
        })

        local page = create("Frame", {
            Name = tabName .. "_Page", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = pageScroll,
        })
        create("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

        navBtn.MouseEnter:Connect(function()
            if window._navSelector ~= navBtn then tween(navBtn, { BackgroundColor3 = CurrentTheme.CardHover, BackgroundTransparency = 0 }, 0.1) end
        end)
        navBtn.MouseLeave:Connect(function()
            if window._navSelector ~= navBtn then tween(navBtn, { BackgroundTransparency = 1 }, 0.1) end
        end)

        local tab = { Page = page, Name = tabName, _sectionOrder = 0 }

        local function selectTab()
            for _, p in ipairs(pageScroll:GetChildren()) do
                if p:IsA("Frame") then p.Visible = false end
            end
            for _, b in ipairs(navList:GetChildren()) do
                if b:IsA("TextButton") then
                    tween(b, { BackgroundTransparency = 1 }, 0.1)
                    local ind = b:FindFirstChildWhichIsA("Frame")
                    if ind then tween(ind, { Size = UDim2.new(0, 3, 0, 0) }, 0.12) end
                end
            end
            page.Visible = true
            window._navSelector = navBtn
            tween(navBtn, { BackgroundColor3 = CurrentTheme.CardHover, BackgroundTransparency = 0 }, 0.12)
            tween(indicator, { Size = UDim2.new(0, 3, 0, 18) }, 0.14)
            pageHeader.Text = tabName
        end
        navBtn.MouseButton1Click:Connect(selectTab)
        if tabOrder == 1 then selectTab() end
        window.Tabs[tabName] = tab

        -- ========================================================
        -- Sections (SettingsCard groups)
        -- ========================================================
        function tab:CreateSection(sopts)
            sopts = sopts or {}
            tab._sectionOrder += 1
            local sName = sopts.Name or "Section"
            local collapsible = sopts.Collapsible

            local card = create("Frame", {
                BackgroundColor3 = CurrentTheme.Card, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = tab._sectionOrder, Parent = page,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
            create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = card })

            local header = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = card })
            create("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -40, 1, 0),
                Font = FONT_TITLE, Text = sName, TextColor3 = CurrentTheme.Text, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
            })
            local chevron
            local rowHolder = create("Frame", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 0, 0, 40),
                ClipsDescendants = true, Parent = card,
            })
            create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = rowHolder })

            local collapsed = sopts.Collapsed or false
            if collapsible then
                chevron = create("TextLabel", {
                    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16), Font = FONT_BODY, Text = collapsed and "\226\140\165" or "\226\140\167",
                    TextColor3 = CurrentTheme.TextSecondary, TextSize = 12, Parent = header,
                })
                local clickZone = create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = header })
                clickZone.MouseButton1Click:Connect(function()
                    collapsed = not collapsed
                    rowHolder.Visible = not collapsed
                    chevron.Text = collapsed and "\226\140\165" or "\226\140\167"
                end)
                rowHolder.Visible = not collapsed
            end

            local section = { Card = card, _rowOrder = 0 }

            local function newRow(h)
                section._rowOrder += 1
                if section._rowOrder > 1 then
                    create("Frame", { BackgroundColor3 = CurrentTheme.Divider, Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 0), Parent = rowHolder })
                end
                local row = create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h or 54),
                    LayoutOrder = section._rowOrder, Parent = rowHolder,
                })
                create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = row })
                return row
            end

            local function labelBlock(row, title, desc, rightInset)
                create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, -(rightInset or 140), 0, desc and 17 or 54),
                    Position = UDim2.new(0, 0, desc and 6 or 0, 0), Font = FONT_BODY, Text = title,
                    TextColor3 = CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center, Parent = row,
                })
                if desc then
                    create("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(1, -(rightInset or 140), 0, 16),
                        Position = UDim2.new(0, 0, 0, 26), Font = FONT_BODY, Text = desc,
                        TextColor3 = CurrentTheme.TextSecondary, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = row,
                    })
                end
            end

            -- ---------------- Toggle (Win11 pill switch) ----------------
            function section:CreateToggle(o)
                o = o or {}
                local row = newRow(54)
                labelBlock(row, o.Name or "Toggle", o.Description)
                local state = o.CurrentValue or false
                local pill = create("Frame", {
                    BackgroundColor3 = state and AccentColor or CurrentTheme.ControlOff,
                    Size = UDim2.new(0, 40, 0, 22), AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })
                local thumb = create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 16, 0, 16),
                    AnchorPoint = Vector2.new(0, 0.5), Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                    Parent = pill,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })
                local btn = create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = pill })
                local function set(v, fire)
                    state = v
                    tween(pill, { BackgroundColor3 = state and AccentColor or CurrentTheme.ControlOff }, 0.12)
                    tween(thumb, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.14, Enum.EasingStyle.Back)
                    if o.Flag then window.ConfigValues[o.Flag] = state end
                    if fire ~= false then safeCall(o.Callback, state) end
                end
                btn.MouseButton1Click:Connect(function() set(not state) end)
                return { Set = function(v) set(v, false) end, Get = function() return state end }
            end

            -- ---------------- Checkbox ----------------
            function section:CreateCheckbox(o)
                o = o or {}
                local row = newRow(54)
                labelBlock(row, o.Name or "Checkbox", o.Description)
                local state = o.CurrentValue or false
                local box = create("TextButton", {
                    BackgroundColor3 = state and AccentColor or CurrentTheme.InputBackground,
                    Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Text = state and "\226\156\147" or "",
                    TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = FONT_BODY, Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = box })
                create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = box })
                box.MouseButton1Click:Connect(function()
                    state = not state
                    tween(box, { BackgroundColor3 = state and AccentColor or CurrentTheme.InputBackground }, 0.1)
                    box.Text = state and "\226\156\147" or ""
                    if o.Flag then window.ConfigValues[o.Flag] = state end
                    safeCall(o.Callback, state)
                end)
                return { Set = function(v) state = v; box.Text = v and "\226\156\147" or ""; box.BackgroundColor3 = v and AccentColor or CurrentTheme.InputBackground end, Get = function() return state end }
            end

            -- ---------------- Button ----------------
            function section:CreateButton(o)
                o = o or {}
                local row = newRow(54)
                labelBlock(row, o.Name or "Button", o.Description, 130)
                local btn = create("TextButton", {
                    BackgroundColor3 = AccentColor, Size = UDim2.new(0, 112, 0, 30),
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Font = FONT_TITLE, Text = o.ButtonText or "Run", TextSize = 13,
                    TextColor3 = Color3.new(1, 1, 1), Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
                btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = AccentColor:Lerp(Color3.new(1, 1, 1), 0.12) }, 0.1) end)
                btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = AccentColor }, 0.1) end)
                btn.MouseButton1Click:Connect(function()
                    tween(btn, { Size = UDim2.new(0, 108, 0, 28) }, 0.06)
                    task.delay(0.07, function() tween(btn, { Size = UDim2.new(0, 112, 0, 30) }, 0.1) end)
                    safeCall(o.Callback)
                end)
                return btn
            end

            -- ---------------- Slider ----------------
            function section:CreateSlider(o)
                o = o or {}
                local row = newRow(54)
                local min, max = o.Min or 0, o.Max or 100
                local step = o.Increment or 1
                local value = clamp(o.CurrentValue or min, min, max)
                labelBlock(row, o.Name or "Slider", o.Description, 180)

                local valLabel = create("TextLabel", {
                    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 40, 0, 16), Font = FONT_BODY, Text = tostring(value),
                    TextColor3 = CurrentTheme.TextSecondary, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
                })
                local track = create("Frame", {
                    BackgroundColor3 = CurrentTheme.ControlOff, Size = UDim2.new(0, 120, 0, 4),
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -48, 0.5, 0), Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
                local fill = create("Frame", { BackgroundColor3 = AccentColor, Size = UDim2.new(0, 0, 1, 0), Parent = track })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
                local thumb = create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 14, 0, 14),
                    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), ZIndex = 2, Parent = track,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })
                create("UIStroke", { Color = AccentColor, Thickness = 2, Parent = thumb })

                local function paint()
                    local pct = (value - min) / math.max(0.0001, (max - min))
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                    valLabel.Text = tostring(value)
                end
                paint()

                local dragging = false
                local function setFromX(x)
                    local pct = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local raw = min + pct * (max - min)
                    value = clamp(math.floor(raw / step + 0.5) * step, min, max)
                    paint()
                    if o.Flag then window.ConfigValues[o.Flag] = value end
                    safeCall(o.Callback, value)
                end
                thumb.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
                track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFromX(i.Position.X) end end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end
                end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

                return { Set = function(v) value = clamp(v, min, max); paint() end, Get = function() return value end }
            end

            -- ---------------- Dropdown / ComboBox ----------------
            function section:CreateDropdown(o)
                o = o or {}
                local row = newRow(54)
                local options = o.Options or {}
                local current = o.CurrentOption or options[1] or ""
                labelBlock(row, o.Name or "Dropdown", o.Description, 170)

                local combo = create("TextButton", {
                    BackgroundColor3 = CurrentTheme.InputBackground, AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 150, 0, 32),
                    Font = FONT_BODY, Text = "   " .. tostring(current), TextSize = 13,
                    TextColor3 = CurrentTheme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = combo })
                create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = combo })
                create("TextLabel", {
                    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14), Text = "\226\140\163", Font = FONT_BODY, TextSize = 10,
                    TextColor3 = CurrentTheme.TextSecondary, Parent = combo,
                })

                local flyout
                local function close()
                    if flyout then flyout:Destroy(); flyout = nil end
                end
                combo.MouseButton1Click:Connect(function()
                    if flyout then close(); return end
                    flyout = create("Frame", {
                        BackgroundColor3 = CurrentTheme.Card, ZIndex = 50,
                        Size = UDim2.new(0, 150, 0, math.min(#options, 6) * 30 + 8),
                        Position = UDim2.new(0, combo.AbsolutePosition.X - content.AbsolutePosition.X, 0, combo.AbsolutePosition.Y - content.AbsolutePosition.Y + 36),
                        Parent = content,
                    })
                    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = flyout })
                    create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = flyout })
                    local list = create("ScrollingFrame", {
                        BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
                        ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y, ZIndex = 50, Parent = flyout,
                    })
                    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
                    for _, opt in ipairs(options) do
                        local item = create("TextButton", {
                            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ZIndex = 51,
                            Font = FONT_BODY, Text = "  " .. tostring(opt), TextSize = 13,
                            TextColor3 = CurrentTheme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = list,
                        })
                        create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = item })
                        item.MouseEnter:Connect(function() item.BackgroundTransparency = 0; item.BackgroundColor3 = CurrentTheme.CardHover end)
                        item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
                        item.MouseButton1Click:Connect(function()
                            current = opt
                            combo.Text = "   " .. tostring(opt)
                            if o.Flag then window.ConfigValues[o.Flag] = opt end
                            safeCall(o.Callback, opt)
                            close()
                        end)
                    end
                end)
                return {
                    Set = function(v) current = v; combo.Text = "   " .. tostring(v) end,
                    Get = function() return current end,
                    Refresh = function(newOpts) options = newOpts end,
                }
            end

            -- ---------------- NumberBox (PowerToys spinner) ----------------
            function section:CreateNumberBox(o)
                o = o or {}
                local row = newRow(54)
                local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
                local value = clamp(o.CurrentValue or min, min, max)
                labelBlock(row, o.Name or "Number", o.Description, 150)

                local box = create("Frame", {
                    BackgroundColor3 = CurrentTheme.InputBackground, AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 110, 0, 30), Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
                create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = box })
                local txt = create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                    Font = FONT_BODY, Text = tostring(value), TextColor3 = CurrentTheme.Text, TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = box,
                })
                local function spin(delta)
                    local btn = create("TextButton", {
                        BackgroundTransparency = 1, Size = UDim2.new(0, 26, 1, 0),
                        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, delta > 0 and -26 or 0, 0, 0),
                        Text = delta > 0 and "\226\150\178" or "\226\150\188", Font = FONT_BODY, TextSize = 9,
                        TextColor3 = CurrentTheme.TextSecondary, Parent = box,
                    })
                    btn.MouseButton1Click:Connect(function()
                        value = clamp(value + delta, min, max)
                        txt.Text = tostring(value)
                        if o.Flag then window.ConfigValues[o.Flag] = value end
                        safeCall(o.Callback, value)
                    end)
                end
                spin(step); spin(-step)
                return { Set = function(v) value = clamp(v, min, max); txt.Text = tostring(value) end, Get = function() return value end }
            end

            -- ---------------- Text input ----------------
            function section:CreateInput(o)
                o = o or {}
                local row = newRow(54)
                labelBlock(row, o.Name or "Input", o.Description, 180)
                local box = create("TextBox", {
                    BackgroundColor3 = CurrentTheme.InputBackground, AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 160, 0, 30),
                    Font = FONT_BODY, PlaceholderText = o.PlaceholderText or "", Text = o.CurrentValue or "",
                    TextColor3 = CurrentTheme.Text, TextSize = 13, ClearTextOnFocus = false, Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
                local stroke = create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = box })
                create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = box })
                box.Focused:Connect(function() tween(stroke, { Color = AccentColor, Thickness = 1.5 }, 0.1) end)
                box.FocusLost:Connect(function()
                    tween(stroke, { Color = CurrentTheme.Border, Thickness = 1 }, 0.1)
                    if o.Flag then window.ConfigValues[o.Flag] = box.Text end
                    safeCall(o.Callback, box.Text)
                end)
                return { Set = function(v) box.Text = v end, Get = function() return box.Text end }
            end

            -- ---------------- Keybind ----------------
            function section:CreateKeybind(o)
                o = o or {}
                local row = newRow(54)
                labelBlock(row, o.Name or "Keybind", o.Description, 150)
                local current = o.CurrentKeybind or Enum.KeyCode.RightControl
                local keyBtn = create("TextButton", {
                    BackgroundColor3 = CurrentTheme.InputBackground, AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 110, 0, 30),
                    Font = FONT_BODY, Text = current.Name, TextColor3 = CurrentTheme.Text, TextSize = 12, Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = keyBtn })
                create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = keyBtn })
                local listening = false
                keyBtn.MouseButton1Click:Connect(function()
                    listening = true; keyBtn.Text = "..."
                    tween(keyBtn, { BackgroundColor3 = AccentColor }, 0.1)
                end)
                UserInputService.InputBegan:Connect(function(input)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        keyBtn.Text = current.Name
                        listening = false
                        tween(keyBtn, { BackgroundColor3 = CurrentTheme.InputBackground }, 0.12)
                        safeCall(o.Callback, current)
                    end
                end)
                return { Set = function(k) current = k; keyBtn.Text = k.Name end, Get = function() return current end }
            end

            -- ---------------- Color picker ----------------
            function section:CreateColorPicker(o)
                o = o or {}
                local row = newRow(54)
                labelBlock(row, o.Name or "Color", o.Description, 60)
                local color = o.Color or AccentColor
                local swatch = create("TextButton", {
                    BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 28, 0, 28), Text = "", Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = swatch })
                create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1, Parent = swatch })
                local palette = {
                    Color3.fromRGB(0, 120, 212), Color3.fromRGB(0, 153, 136), Color3.fromRGB(16, 124, 16),
                    Color3.fromRGB(196, 43, 28), Color3.fromRGB(136, 23, 152), Color3.fromRGB(157, 93, 0),
                    Color3.fromRGB(0, 153, 188), Color3.fromRGB(120, 120, 120),
                }
                local idx = 1
                for i, c in ipairs(palette) do if c == color then idx = i end end
                swatch.MouseButton1Click:Connect(function()
                    idx = idx % #palette + 1
                    color = palette[idx]
                    tween(swatch, { BackgroundColor3 = color }, 0.12)
                    safeCall(o.Callback, color)
                end)
                return { Set = function(c) color = c; swatch.BackgroundColor3 = c end, Get = function() return color end }
            end

            -- ---------------- Segmented control ----------------
            function section:CreateSegmentedControl(o)
                o = o or {}
                local row = newRow(54)
                local options = o.Options or {}
                local current = o.CurrentOption or options[1]
                labelBlock(row, o.Name or "Segmented", o.Description, 10 + #options * 70)
                local holder = create("Frame", {
                    BackgroundColor3 = CurrentTheme.InputBackground, AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, #options * 68, 0, 30), Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = holder })
                create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
                local buttons = {}
                for _, opt in ipairs(options) do
                    local b = create("TextButton", {
                        BackgroundColor3 = opt == current and AccentColor or CurrentTheme.InputBackground,
                        Size = UDim2.new(0, 68, 1, 0), Font = FONT_BODY, Text = tostring(opt), TextSize = 12,
                        TextColor3 = opt == current and Color3.new(1, 1, 1) or CurrentTheme.Text, Parent = holder,
                    })
                    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
                    buttons[opt] = b
                    b.MouseButton1Click:Connect(function()
                        current = opt
                        for k, bb in pairs(buttons) do
                            tween(bb, { BackgroundColor3 = k == current and AccentColor or CurrentTheme.InputBackground }, 0.1)
                            bb.TextColor3 = k == current and Color3.new(1, 1, 1) or CurrentTheme.Text
                        end
                        safeCall(o.Callback, current)
                    end)
                end
                return { Set = function(v) current = v end, Get = function() return current end }
            end

            -- ---------------- Progress bar ----------------
            function section:CreateProgressBar(o)
                o = o or {}
                local row = newRow(44)
                labelBlock(row, o.Name or "Progress", nil, 150)
                local track = create("Frame", {
                    BackgroundColor3 = CurrentTheme.ControlOff, AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 140, 0, 6), Parent = row,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
                local fill = create("Frame", { BackgroundColor3 = AccentColor, Size = UDim2.new(0, 0, 1, 0), Parent = track })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
                local value = clamp(o.CurrentValue or 0, 0, 100)
                fill.Size = UDim2.new(value / 100, 0, 1, 0)
                return {
                    Set = function(v)
                        value = clamp(v, 0, 100)
                        tween(fill, { Size = UDim2.new(value / 100, 0, 1, 0) }, 0.2)
                    end,
                    Get = function() return value end,
                }
            end

            -- ---------------- Label / Paragraph ----------------
            function section:CreateLabel(o)
                o = o or {}
                local row = newRow(32)
                create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = FONT_BODY,
                    Text = o.Text or o.Name or "", TextColor3 = CurrentTheme.Text, TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })
                return row
            end
            function section:CreateParagraph(o)
                o = o or {}
                local row = newRow(0)
                row.AutomaticSize = Enum.AutomaticSize.Y
                create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = row })
                create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = FONT_TITLE,
                    Text = o.Title or "", TextColor3 = CurrentTheme.Text, TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })
                create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    Position = UDim2.new(0, 0, 0, 20), Font = FONT_BODY, Text = o.Content or "",
                    TextColor3 = CurrentTheme.TextSecondary, TextSize = 13, TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })
                return row
            end

            -- ---------------- InfoBar / Callout ----------------
            function section:CreateCallout(o)
                o = o or {}
                local accent = StyleColors[o.Style] or AccentColor
                local row = create("Frame", {
                    BackgroundColor3 = accent, BackgroundTransparency = 0.88, Size = UDim2.new(1, -28, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 14, 0, 0), LayoutOrder = section._rowOrder + 1, Parent = rowHolder,
                })
                section._rowOrder += 1
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })
                create("UIStroke", { Color = accent, Thickness = 1, Transparency = 0.4, Parent = row })
                create("Frame", { BackgroundColor3 = accent, Size = UDim2.new(0, 3, 1, 0), Parent = row })
                local pad = create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = row })
                create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = FONT_TITLE,
                    Text = o.Title or "", TextColor3 = CurrentTheme.Text, TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })
                create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    Position = UDim2.new(0, 0, 0, 18), Font = FONT_BODY, Text = o.Content or "",
                    TextColor3 = CurrentTheme.TextSecondary, TextSize = 12, TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })
                return row
            end

            return section
        end

        return tab
    end

    -- Built-in Settings tab (theme switcher)
    function window:CreateSettingsTab()
        local tab = window:CreateTab({ Name = "Settings", Icon = "settings" })
        local sec = tab:CreateSection({ Name = "Appearance" })
        local themeNames = {}
        for n in pairs(Themes) do table.insert(themeNames, n) end
        sec:CreateDropdown({
            Name = "Theme", Description = "Switch between Windows 11 and PowerToys styles",
            Options = themeNames, CurrentOption = "Windows 11 Dark",
            Callback = function(v) WinUI:SetTheme(v) end,
        })
        sec:CreateColorPicker({ Name = "Accent color", Color = AccentColor, Callback = function(c) AccentColor = c end })
        return tab
    end

    function window:SaveConfig()
        local folder, file = (opts.ConfigurationSaving or {}).Folder or "WinUI", (opts.ConfigurationSaving or {}).File or "settings"
        pcall(function()
            if writefile and makefolder and isfolder then
                if not isfolder(folder) then makefolder(folder) end
                writefile(folder .. "/" .. file .. ".json", game:GetService("HttpService"):JSONEncode(window.ConfigValues))
            end
        end)
    end
    function window:LoadConfig()
        local folder, file = (opts.ConfigurationSaving or {}).Folder or "WinUI", (opts.ConfigurationSaving or {}).File or "settings"
        pcall(function()
            if readfile and isfile and isfile(folder .. "/" .. file .. ".json") then
                window.ConfigValues = game:GetService("HttpService"):JSONDecode(readfile(folder .. "/" .. file .. ".json"))
            end
        end)
    end
    function window:Destroy()
        if screenGui then screenGui:Destroy() end
    end

    if (opts.ConfigurationSaving or {}).Enabled then window:LoadConfig() end

    Windows[screenGui] = window
    return window
end

return WinUI
