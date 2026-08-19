--[[
    MacUI v1.0.0
    A modern macOS-inspired Roblox UI library
    Liquid Glass + macOS design language + clean developer API
]]

local MacUI = {
    Version = "1.0.0",
    Themes = {},
    CurrentTheme = "Dark",
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
        Transparency = 0.18,
        Border = true,
        Shadow = true,
        Tint = Color3.fromRGB(30, 30, 35)
    }
}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
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

-- Animation utility
function MacUI.Tween(object, info, properties)
    if MacUI.Accessibility.ReducedMotion then
        for prop, value in pairs(properties) do
            object[prop] = value
        end
        return nil
    end
    local tweenInfo = TweenInfo.new(
        info.Time or 0.25,
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

-- Icon map (safe public rbxassetids + text fallbacks)
local Icons = {
    house = "rbxassetid://7733960981",
    settings = "rbxassetid://7734053495",
    person = "rbxassetid://7733774602",
    eye = "rbxassetid://7733774602",
    info = "rbxassetid://7733960981",
    search = "rbxassetid://7734053495",
    check = "rbxassetid://7733715400",
    close = "rbxassetid://7733715400",
    player = "rbxassetid://7733774602",
    visuals = "rbxassetid://7733960981",
    misc = "rbxassetid://7734053495",
    home = "rbxassetid://7733960981",
    default = "rbxassetid://7733960981"
}

function MacUI.GetIcon(name)
    return Icons[string.lower(name or "")] or Icons.default
end

-- Theme system
MacUI.Themes.Dark = {
    Background = Color3.fromRGB(28, 28, 30),
    SecondaryBackground = Color3.fromRGB(38, 38, 42),
    TertiaryBackground = Color3.fromRGB(48, 48, 52),
    Text = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(180, 180, 185),
    Accent = Color3.fromRGB(10, 132, 255),
    Border = Color3.fromRGB(70, 70, 75),
    Glass = Color3.fromRGB(40, 40, 45),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0)
}

MacUI.Themes.Light = {
    Background = Color3.fromRGB(246, 246, 248),
    SecondaryBackground = Color3.fromRGB(255, 255, 255),
    TertiaryBackground = Color3.fromRGB(235, 235, 240),
    Text = Color3.fromRGB(28, 28, 30),
    SecondaryText = Color3.fromRGB(90, 90, 95),
    Accent = Color3.fromRGB(0, 122, 255),
    Border = Color3.fromRGB(200, 200, 205),
    Glass = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(52, 199, 89),
    Warning = Color3.fromRGB(255, 149, 0),
    Danger = Color3.fromRGB(255, 59, 48),
    Shadow = Color3.fromRGB(0, 0, 0)
}

MacUI.Themes.Graphite = {
    Background = Color3.fromRGB(40, 40, 42),
    SecondaryBackground = Color3.fromRGB(50, 50, 53),
    TertiaryBackground = Color3.fromRGB(60, 60, 64),
    Text = Color3.fromRGB(245, 245, 247),
    SecondaryText = Color3.fromRGB(160, 160, 165),
    Accent = Color3.fromRGB(120, 120, 130),
    Border = Color3.fromRGB(80, 80, 85),
    Glass = Color3.fromRGB(55, 55, 58),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0)
}

MacUI.Themes.Midnight = {
    Background = Color3.fromRGB(15, 15, 20),
    SecondaryBackground = Color3.fromRGB(22, 22, 28),
    TertiaryBackground = Color3.fromRGB(30, 30, 38),
    Text = Color3.fromRGB(240, 240, 245),
    SecondaryText = Color3.fromRGB(150, 150, 160),
    Accent = Color3.fromRGB(94, 92, 230),
    Border = Color3.fromRGB(50, 50, 60),
    Glass = Color3.fromRGB(25, 25, 32),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0)
}

MacUI.Themes.Blue = {
    Background = Color3.fromRGB(20, 30, 50),
    SecondaryBackground = Color3.fromRGB(28, 40, 65),
    TertiaryBackground = Color3.fromRGB(35, 50, 80),
    Text = Color3.fromRGB(240, 245, 255),
    SecondaryText = Color3.fromRGB(160, 180, 210),
    Accent = Color3.fromRGB(10, 132, 255),
    Border = Color3.fromRGB(50, 70, 100),
    Glass = Color3.fromRGB(30, 45, 70),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0)
}

MacUI.Themes.Purple = {
    Background = Color3.fromRGB(30, 20, 45),
    SecondaryBackground = Color3.fromRGB(40, 28, 58),
    TertiaryBackground = Color3.fromRGB(50, 35, 70),
    Text = Color3.fromRGB(245, 240, 255),
    SecondaryText = Color3.fromRGB(180, 160, 200),
    Accent = Color3.fromRGB(175, 82, 222),
    Border = Color3.fromRGB(70, 50, 90),
    Glass = Color3.fromRGB(45, 30, 65),
    Success = Color3.fromRGB(48, 209, 88),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
    Shadow = Color3.fromRGB(0, 0, 0)
}

function MacUI:RegisterTheme(name, themeTable)
    self.Themes[name] = themeTable
end

function MacUI:SetTheme(name)
    if not self.Themes[name] then
        warn("[MacUI] Warning: Theme '" .. tostring(name) .. "' does not exist")
        return
    end
    self.CurrentTheme = name
    local theme = self.Themes[name]
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
    -- Apply scale globally if needed
end

-- Helper: Create glass frame
local function CreateGlassFrame(parent, props)
    local theme = MacUI.Themes[MacUI.CurrentTheme]
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.Color or theme.Glass
    frame.BackgroundTransparency = props.Transparency or MacUI.GlassStyle.Transparency
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, props.Radius or 12)
    corner.Parent = frame

    if MacUI.GlassStyle.Border then
        local stroke = Instance.new("UIStroke")
        stroke.Color = theme.Border
        stroke.Transparency = 0.55
        stroke.Thickness = 1
        stroke.Parent = frame
    end

    return frame
end

-- Notification system
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
        screenGui.Parent = GetUIParent()
    end

    local notif = CreateGlassFrame(screenGui, {Radius = 14, Transparency = 0.12})
    notif.Size = UDim2.new(0, 320, 0, 70)
    notif.Position = UDim2.new(1, 20, 0, 20 + (#self.Notifications * 80))
    notif.AnchorPoint = Vector2.new(1, 0)
    notif.ZIndex = 100

    local iconImg = Instance.new("ImageLabel")
    iconImg.Size = UDim2.new(0, 28, 0, 28)
    iconImg.Position = UDim2.new(0, 14, 0.5, -14)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = self.GetIcon(icon)
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

    table.insert(self.Notifications, notif)

    -- Slide in
    notif.Position = UDim2.new(1, 20, 0, 20 + ((#self.Notifications - 1) * 80))
    MacUI.Tween(notif, {Time = 0.35, EasingStyle = Enum.EasingStyle.Quint}, {
        Position = UDim2.new(1, -20, 0, 20 + ((#self.Notifications - 1) * 80))
    })

    task.delay(duration, function()
        if notif and notif.Parent then
            MacUI.Tween(notif, {Time = 0.3}, {
                Position = UDim2.new(1, 40, 0, notif.Position.Y.Offset),
                BackgroundTransparency = 1
            })
            task.wait(0.35)
            notif:Destroy()
            for i, n in ipairs(self.Notifications) do
                if n == notif then
                    table.remove(self.Notifications, i)
                    break
                end
            end
            -- Restack remaining
            for i, n in ipairs(self.Notifications) do
                MacUI.Tween(n, {Time = 0.25}, {
                    Position = UDim2.new(1, -20, 0, 20 + ((i - 1) * 80))
                })
            end
        end
    end)
end

-- Configuration (pcall-safe for different environments)
function MacUI:CreateConfig(opts)
    self.Config.Folder = opts.Folder or "MacUI"
    self.Config.File = opts.File or "Config"
end

function MacUI:SaveConfig()
    local success, err = pcall(function()
        if writefile then
            local data = HttpService:JSONEncode(self.Config.Data)
            writefile(self.Config.Folder .. "/" .. self.Config.File .. ".json", data)
        end
    end)
    if not success then
        warn("[MacUI] Config save unavailable in this environment:", err)
    end
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

-- Main Window
function MacUI:CreateWindow(options)
    options = options or {}
    local name = options.Name or "MacUI"
    local subtitle = options.Subtitle or ""
    local themeName = options.Theme or "Dark"
    local acrylic = options.Acrylic ~= false
    local size = options.Size or UDim2.new(0, 720, 0, 480)
    local minSize = options.MinSize or Vector2.new(480, 320)

    self:SetTheme(themeName)
    local theme = self.Themes[themeName]

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MacUI_" .. name
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = GetUIParent()

    -- Main window frame
    local window = CreateGlassFrame(screenGui, {
        Radius = 16,
        Transparency = acrylic and MacUI.GlassStyle.Transparency or 0.05,
        Color = theme.Background
    })
    window.Name = "Window"
    window.Size = size
    window.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    window.ClipsDescendants = true
    window.Active = true

    -- Shadow approximation
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 60, 1, 60)
    shadow.Position = UDim2.new(0, -30, 0, -30)
    shadow.ZIndex = -1
    shadow.Parent = window

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = window

    -- Traffic lights
    local function CreateTrafficLight(color, posX)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 14, 0, 14)
        btn.Position = UDim2.new(0, posX, 0.5, -7)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = titleBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(0, 0, 0)
        stroke.Transparency = 0.7
        stroke.Thickness = 0.5
        stroke.Parent = btn

        return btn
    end

    local closeBtn = CreateTrafficLight(Color3.fromRGB(255, 95, 87), 14)
    local minBtn = CreateTrafficLight(Color3.fromRGB(255, 189, 46), 36)
    local maxBtn = CreateTrafficLight(Color3.fromRGB(40, 200, 64), 58)

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -160, 1, 0)
    titleLabel.Position = UDim2.new(0, 90, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = name
    titleLabel.TextColor3 = theme.Text
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    if subtitle ~= "" then
        titleLabel.Text = name .. "  —  " .. subtitle
    end

    -- Search button (top right)
    local searchBtn = Instance.new("ImageButton")
    searchBtn.Size = UDim2.new(0, 22, 0, 22)
    searchBtn.Position = UDim2.new(1, -36, 0.5, -11)
    searchBtn.BackgroundTransparency = 1
    searchBtn.Image = MacUI.GetIcon("search")
    searchBtn.ImageColor3 = theme.SecondaryText
    searchBtn.Parent = titleBar

    -- Sidebar
    local sidebar = CreateGlassFrame(window, {
        Radius = 0,
        Transparency = 0.08,
        Color = theme.SecondaryBackground
    })
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 180, 1, -42)
    sidebar.Position = UDim2.new(0, 0, 0, 42)
    sidebar.BorderSizePixel = 0

    local sidebarStroke = Instance.new("UIStroke")
    sidebarStroke.Color = theme.Border
    sidebarStroke.Transparency = 0.7
    sidebarStroke.Thickness = 1
    sidebarStroke.Parent = sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 12)
    sidebarPadding.PaddingLeft = UDim.new(0, 10)
    sidebarPadding.PaddingRight = UDim.new(0, 10)
    sidebarPadding.Parent = sidebar

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -180, 1, -42)
    content.Position = UDim2.new(0, 180, 0, 42)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = window

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "Scroll"
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 4
    contentScroll.ScrollBarImageColor3 = theme.Border
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.Parent = content

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 16)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentScroll

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 20)
    contentPadding.PaddingLeft = UDim.new(0, 24)
    contentPadding.PaddingRight = UDim.new(0, 24)
    contentPadding.PaddingBottom = UDim.new(0, 24)
    contentPadding.Parent = contentScroll

    -- Window object
    local Window = {
        ScreenGui = screenGui,
        Frame = window,
        TitleBar = titleBar,
        Sidebar = sidebar,
        Content = contentScroll,
        Tabs = {},
        CurrentTab = nil,
        OriginalSize = size,
        OriginalPos = window.Position,
        IsMaximized = false,
        IsMinimized = false,
        Connections = {},
        Elements = {} -- for search
    }

    -- Dragging
    local dragging, dragStart, startPos
    TrackConnection(titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    -- Traffic light actions
    TrackConnection(closeBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
    end))
    TrackConnection(minBtn.MouseButton1Click:Connect(function()
        Window:Minimize()
    end))
    TrackConnection(maxBtn.MouseButton1Click:Connect(function()
        Window:Maximize()
    end))

    -- Hover effects for traffic lights
    local function SetupHover(btn, baseColor)
        TrackConnection(btn.MouseEnter:Connect(function()
            MacUI.Tween(btn, {Time = 0.15}, {BackgroundColor3 = baseColor:Lerp(Color3.new(1,1,1), 0.15)})
        end))
        TrackConnection(btn.MouseLeave:Connect(function()
            MacUI.Tween(btn, {Time = 0.15}, {BackgroundColor3 = baseColor})
        end))
    end
    SetupHover(closeBtn, Color3.fromRGB(255, 95, 87))
    SetupHover(minBtn, Color3.fromRGB(255, 189, 46))
    SetupHover(maxBtn, Color3.fromRGB(40, 200, 64))

    function Window:ApplyTheme(t)
        theme = t
        window.BackgroundColor3 = t.Background
        sidebar.BackgroundColor3 = t.SecondaryBackground
        titleLabel.TextColor3 = t.Text
        searchBtn.ImageColor3 = t.SecondaryText
        -- Additional theme application can be extended per element
    end

    function Window:Minimize()
        if self.IsMinimized then
            MacUI.Tween(window, {Time = 0.3}, {Size = self.OriginalSize, Position = self.OriginalPos})
            self.IsMinimized = false
        else
            self.OriginalSize = window.Size
            self.OriginalPos = window.Position
            MacUI.Tween(window, {Time = 0.3}, {
                Size = UDim2.new(0, 200, 0, 42),
                Position = UDim2.new(0, 20, 1, -60)
            })
            self.IsMinimized = true
        end
    end

    function Window:Maximize()
        if self.IsMaximized then
            MacUI.Tween(window, {Time = 0.35, EasingStyle = Enum.EasingStyle.Quint}, {
                Size = self.OriginalSize,
                Position = self.OriginalPos
            })
            self.IsMaximized = false
        else
            self.OriginalSize = window.Size
            self.OriginalPos = window.Position
            MacUI.Tween(window, {Time = 0.35, EasingStyle = Enum.EasingStyle.Quint}, {
                Size = UDim2.new(1, -40, 1, -40),
                Position = UDim2.new(0, 20, 0, 20)
            })
            self.IsMaximized = true
        end
    end

    function Window:Toggle()
        window.Visible = not window.Visible
    end

    function Window:Destroy()
        DisconnectAll(self.Connections)
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
        for i, w in ipairs(MacUI.Windows) do
            if w == self then
                table.remove(MacUI.Windows, i)
                break
            end
        end
    end

    function Window:CreateTab(opts)
        opts = opts or {}
        local tabName = opts.Name or "Tab"
        local iconName = opts.Icon or "default"

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundColor3 = theme.TertiaryBackground
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = sidebar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 8)
        tabCorner.Parent = tabBtn

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 18, 0, 18)
        icon.Position = UDim2.new(0, 10, 0.5, -9)
        icon.BackgroundTransparency = 1
        icon.Image = MacUI.GetIcon(iconName)
        icon.ImageColor3 = theme.SecondaryText
        icon.Parent = tabBtn

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.new(0, 36, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = tabName
        label.TextColor3 = theme.SecondaryText
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = tabBtn

        local tabContent = Instance.new("Frame")
        tabContent.Name = tabName
        tabContent.Size = UDim2.new(1, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.AutomaticSize = Enum.AutomaticSize.Y
        tabContent.Parent = contentScroll

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Padding = UDim.new(0, 12)
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Parent = tabContent

        local Tab = {
            Button = tabBtn,
            Content = tabContent,
            Name = tabName,
            Sections = {},
            Window = Window
        }

        local function SelectTab()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                t.Button.BackgroundTransparency = 1
                t.Button:FindFirstChildOfClass("TextLabel").TextColor3 = theme.SecondaryText
                t.Button:FindFirstChildOfClass("ImageLabel").ImageColor3 = theme.SecondaryText
            end
            tabContent.Visible = true
            tabBtn.BackgroundTransparency = 0.4
            label.TextColor3 = theme.Text
            icon.ImageColor3 = theme.Accent
            Window.CurrentTab = Tab
        end

        TrackConnection(tabBtn.MouseButton1Click:Connect(SelectTab))
        TrackConnection(tabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                MacUI.Tween(tabBtn, {Time = 0.15}, {BackgroundTransparency = 0.7})
            end
        end))
        TrackConnection(tabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                MacUI.Tween(tabBtn, {Time = 0.15}, {BackgroundTransparency = 1})
            end
        end))

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
            secLayout.Padding = UDim.new(0, 8)
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
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 36)
                btn.BackgroundColor3 = theme.TertiaryBackground
                btn.BackgroundTransparency = 0.3
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.Parent = sectionContent

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = btn

                local stroke = Instance.new("UIStroke")
                stroke.Color = theme.Border
                stroke.Transparency = 0.6
                stroke.Thickness = 1
                stroke.Parent = btn

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -16, 1, 0)
                lbl.Position = UDim2.new(0, 12, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Button"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = btn

                if opts.Description then
                    btn.Size = UDim2.new(1, 0, 0, 52)
                    local desc = Instance.new("TextLabel")
                    desc.Size = UDim2.new(1, -16, 0, 18)
                    desc.Position = UDim2.new(0, 12, 0, 28)
                    desc.BackgroundTransparency = 1
                    desc.Text = opts.Description
                    desc.TextColor3 = theme.SecondaryText
                    desc.Font = Enum.Font.Gotham
                    desc.TextSize = 12
                    desc.TextXAlignment = Enum.TextXAlignment.Left
                    desc.Parent = btn
                end

                TrackConnection(btn.MouseEnter:Connect(function()
                    MacUI.Tween(btn, {Time = 0.15}, {BackgroundTransparency = 0.1})
                end))
                TrackConnection(btn.MouseLeave:Connect(function()
                    MacUI.Tween(btn, {Time = 0.15}, {BackgroundTransparency = 0.3})
                end))
                TrackConnection(btn.MouseButton1Click:Connect(function()
                    MacUI.Tween(btn, {Time = 0.08}, {BackgroundTransparency = 0})
                    task.wait(0.08)
                    MacUI.Tween(btn, {Time = 0.15}, {BackgroundTransparency = 0.3})
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "Button", Name = opts.Name, Object = btn})
                return btn
            end

            -- Toggle (macOS style switch)
            function Section:CreateToggle(opts)
                opts = opts or {}
                local current = opts.CurrentValue or false
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -70, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Toggle"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(0, 42, 0, 24)
                track.Position = UDim2.new(1, -42, 0.5, -12)
                track.BackgroundColor3 = current and theme.Accent or theme.TertiaryBackground
                track.Parent = row

                local trackCorner = Instance.new("UICorner")
                trackCorner.CornerRadius = UDim.new(1, 0)
                trackCorner.Parent = track

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 20, 0, 20)
                knob.Position = current and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.Parent = track

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local function SetState(val)
                    current = val
                    MacUI.Tween(track, {Time = 0.2}, {BackgroundColor3 = val and theme.Accent or theme.TertiaryBackground})
                    MacUI.Tween(knob, {Time = 0.2, EasingStyle = Enum.EasingStyle.Quint}, {
                        Position = val and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                    })
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, val)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                    MacUI.Config.Data[opts.Name] = val
                end

                TrackConnection(track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        SetState(not current)
                    end
                end))

                table.insert(Window.Elements, {Type = "Toggle", Name = opts.Name, Object = row})
                return {Set = SetState, Get = function() return current end}
            end

            -- Slider
            function Section:CreateSlider(opts)
                opts = opts or {}
                local min, max = opts.Range[1] or 0, opts.Range[2] or 100
                local increment = opts.Increment or 1
                local current = opts.CurrentValue or min

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 50)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.7, 0, 0, 20)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Slider"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local valueLbl = Instance.new("TextLabel")
                valueLbl.Size = UDim2.new(0.3, 0, 0, 20)
                valueLbl.Position = UDim2.new(0.7, 0, 0, 0)
                valueLbl.BackgroundTransparency = 1
                valueLbl.Text = tostring(current)
                valueLbl.TextColor3 = theme.SecondaryText
                valueLbl.Font = Enum.Font.Gotham
                valueLbl.TextSize = 13
                valueLbl.TextXAlignment = Enum.TextXAlignment.Right
                valueLbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 32)
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
                local function Update(val)
                    val = math.clamp(math.floor(val / increment + 0.5) * increment, min, max)
                    current = val
                    local alpha = (val - min) / (max - min)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, -8, 0.5, -8)
                    valueLbl.Text = tostring(val)
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, val)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                    MacUI.Config.Data[opts.Name] = val
                end

                TrackConnection(track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
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
                    end
                end))

                table.insert(Window.Elements, {Type = "Slider", Name = opts.Name, Object = row})
                return {Set = Update, Get = function() return current end}
            end

            -- Dropdown
            function Section:CreateDropdown(opts)
                opts = opts or {}
                local options = opts.Options or {}
                local current = opts.CurrentOption or options[1]

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.4, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Dropdown"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local dropBtn = Instance.new("TextButton")
                dropBtn.Size = UDim2.new(0.55, 0, 0, 30)
                dropBtn.Position = UDim2.new(0.45, 0, 0.5, -15)
                dropBtn.BackgroundColor3 = theme.TertiaryBackground
                dropBtn.BackgroundTransparency = 0.3
                dropBtn.Text = current
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
                TrackConnection(dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        listFrame = Instance.new("Frame")
                        listFrame.Size = UDim2.new(0.55, 0, 0, #options * 28)
                        listFrame.Position = UDim2.new(0.45, 0, 1, 4)
                        listFrame.BackgroundColor3 = theme.SecondaryBackground
                        listFrame.Parent = row
                        local lc = Instance.new("UICorner")
                        lc.CornerRadius = UDim.new(0, 8)
                        lc.Parent = listFrame
                        local ls = Instance.new("UIStroke")
                        ls.Color = theme.Border
                        ls.Transparency = 0.5
                        ls.Parent = listFrame

                        for i, opt in ipairs(options) do
                            local item = Instance.new("TextButton")
                            item.Size = UDim2.new(1, 0, 0, 28)
                            item.Position = UDim2.new(0, 0, 0, (i-1)*28)
                            item.BackgroundTransparency = 1
                            item.Text = opt
                            item.TextColor3 = theme.Text
                            item.Font = Enum.Font.Gotham
                            item.TextSize = 13
                            item.Parent = listFrame
                            TrackConnection(item.MouseButton1Click:Connect(function()
                                current = opt
                                dropBtn.Text = opt
                                listFrame:Destroy()
                                open = false
                                if opts.Callback then
                                    local ok, err = pcall(opts.Callback, opt)
                                    if not ok then warn("[MacUI] Callback error:", err) end
                                end
                                MacUI.Config.Data[opts.Name] = opt
                            end))
                        end
                    else
                        if listFrame then listFrame:Destroy() end
                    end
                end))

                table.insert(Window.Elements, {Type = "Dropdown", Name = opts.Name, Object = row})
                return {Set = function(v) current = v; dropBtn.Text = v end}
            end

            -- Input
            function Section:CreateInput(opts)
                opts = opts or {}
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.35, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Input"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.6, 0, 0, 30)
                box.Position = UDim2.new(0.38, 0, 0.5, -15)
                box.BackgroundColor3 = theme.TertiaryBackground
                box.BackgroundTransparency = 0.3
                box.Text = ""
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

                TrackConnection(box.FocusLost:Connect(function(enter)
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, box.Text)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "Input", Name = opts.Name, Object = row})
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
                return lbl
            end

            -- Paragraph
            function Section:CreateParagraph(opts)
                opts = opts or {}
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 0)
                frame.BackgroundTransparency = 1
                frame.AutomaticSize = Enum.AutomaticSize.Y
                frame.Parent = sectionContent

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 20)
                title.BackgroundTransparency = 1
                title.Text = opts.Title or ""
                title.TextColor3 = theme.Text
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 14
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = frame

                local content = Instance.new("TextLabel")
                content.Size = UDim2.new(1, 0, 0, 0)
                content.Position = UDim2.new(0, 0, 0, 24)
                content.BackgroundTransparency = 1
                content.Text = opts.Content or ""
                content.TextColor3 = theme.SecondaryText
                content.Font = Enum.Font.Gotham
                content.TextSize = 13
                content.TextXAlignment = Enum.TextXAlignment.Left
                content.TextWrapped = true
                content.AutomaticSize = Enum.AutomaticSize.Y
                content.Parent = frame
                return frame
            end

            -- Keybind
            function Section:CreateKeybind(opts)
                opts = opts or {}
                local current = opts.CurrentKeybind or Enum.KeyCode.RightShift
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Keybind"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local keyBtn = Instance.new("TextButton")
                keyBtn.Size = UDim2.new(0, 90, 0, 28)
                keyBtn.Position = UDim2.new(1, -90, 0.5, -14)
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
                        MacUI.Config.Data[opts.Name] = current.Name
                    end
                    if not gp and input.KeyCode == current and opts.Callback then
                        local ok, err = pcall(opts.Callback)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "Keybind", Name = opts.Name, Object = row})
                return {Get = function() return current end}
            end

            -- Color Picker (simplified)
            function Section:CreateColorPicker(opts)
                opts = opts or {}
                local current = opts.Color or Color3.fromRGB(0, 122, 255)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundTransparency = 1
                row.Parent = sectionContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = opts.Name or "Color"
                lbl.TextColor3 = theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local swatch = Instance.new("TextButton")
                swatch.Size = UDim2.new(0, 36, 0, 24)
                swatch.Position = UDim2.new(1, -36, 0.5, -12)
                swatch.BackgroundColor3 = current
                swatch.Text = ""
                swatch.AutoButtonColor = false
                swatch.Parent = row

                local sc = Instance.new("UICorner")
                sc.CornerRadius = UDim.new(0, 6)
                sc.Parent = swatch

                -- Simple cycle for demo (full HSV picker would be larger)
                local colors = {
                    Color3.fromRGB(0, 122, 255),
                    Color3.fromRGB(52, 199, 89),
                    Color3.fromRGB(255, 59, 48),
                    Color3.fromRGB(175, 82, 222),
                    Color3.fromRGB(255, 149, 0)
                }
                local idx = 1
                TrackConnection(swatch.MouseButton1Click:Connect(function()
                    idx = idx % #colors + 1
                    current = colors[idx]
                    swatch.BackgroundColor3 = current
                    if opts.Callback then
                        local ok, err = pcall(opts.Callback, current)
                        if not ok then warn("[MacUI] Callback error:", err) end
                    end
                end))

                table.insert(Window.Elements, {Type = "ColorPicker", Name = opts.Name, Object = row})
                return {Set = function(c) current = c; swatch.BackgroundColor3 = c end}
            end

            -- Segmented Control
            function Section:CreateSegmentedControl(opts)
                opts = opts or {}
                local options = opts.Options or {"One", "Two"}
                local current = opts.Default or options[1]

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 32)
                frame.BackgroundColor3 = theme.TertiaryBackground
                frame.BackgroundTransparency = 0.4
                frame.Parent = sectionContent

                local fc = Instance.new("UICorner")
                fc.CornerRadius = UDim.new(0, 8)
                fc.Parent = frame

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
                        current = opt
                        for name, btn in pairs(buttons) do
                            btn.BackgroundTransparency = (name == opt) and 0.2 or 1
                            btn.BackgroundColor3 = (name == opt) and theme.Accent or Color3.new(0,0,0)
                        end
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

        Window.Tabs[tabName] = Tab
        if not Window.CurrentTab then
            SelectTab()
        end
        return Tab
    end

    function Window:CreateSearch()
        -- Simple search overlay (expandable)
        local searchFrame = CreateGlassFrame(window, {Radius = 10, Transparency = 0.1})
        searchFrame.Size = UDim2.new(0, 280, 0, 36)
        searchFrame.Position = UDim2.new(1, -300, 0, 4)
        searchFrame.Visible = false
        searchFrame.ZIndex = 50

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
        searchBox.Parent = searchFrame

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
    window.Size = UDim2.new(0, 0, 0, 0)
    window.BackgroundTransparency = 1
    MacUI.Tween(window, {Time = 0.4, EasingStyle = Enum.EasingStyle.Quint}, {
        Size = size,
        BackgroundTransparency = acrylic and MacUI.GlassStyle.Transparency or 0.05
    })

    table.insert(self.Windows, Window)
    return Window
end


return MacUI
