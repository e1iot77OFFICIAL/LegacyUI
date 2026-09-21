local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local lp = players.LocalPlayer

local Library = {}
Library.Tree = {}
Library.Tabs = {}
Library.Components = {}
Library.Scheme = {}
Library.Window = nil
Library.CurrentTab = nil
Library.Visible = true

local DefaultScheme = {
    Background = Color3.fromRGB(21, 19, 31),
    Main = Color3.fromRGB(21, 19, 31),
    Element = Color3.fromRGB(37, 33, 53),
    ElementHover = Color3.fromRGB(46, 40, 66),
    Accent = Color3.fromRGB(156, 90, 255),
    AccentDim = Color3.fromRGB(110, 62, 180),
    Text = Color3.fromRGB(241, 241, 251),
    TextDim = Color3.fromRGB(161, 161, 181),
    Border = Color3.fromRGB(61, 55, 89),
    BorderDim = Color3.fromRGB(51, 45, 75),

    TopBar = Color3.fromRGB(11, 11, 11),
    TopBarExtension = Color3.fromRGB(26, 26, 26),
    TopBarTitle = Color3.fromRGB(156, 90, 255),

    Nav = Color3.fromRGB(27, 23, 41),
    NavActive = Color3.fromRGB(37, 33, 53),
    NavActiveText = Color3.fromRGB(156, 90, 255),
    NavIdle = Color3.fromRGB(27, 23, 41),
    NavIdleText = Color3.fromRGB(161, 161, 181),

    Content = Color3.fromRGB(27, 23, 41),

    Button = Color3.fromRGB(37, 33, 53),
    ButtonText = Color3.fromRGB(241, 241, 251),
    ButtonHover = Color3.fromRGB(46, 40, 66),

    Label = Color3.fromRGB(27, 23, 41),
    LabelText = Color3.fromRGB(241, 241, 251),

    Info = Color3.fromRGB(21, 27, 41),
    InfoText = Color3.fromRGB(91, 171, 255),
    InfoBorder = Color3.fromRGB(51, 91, 141),

    Warning = Color3.fromRGB(37, 21, 27),
    WarningText = Color3.fromRGB(255, 81, 81),
    WarningBorder = Color3.fromRGB(121, 41, 51),

    Success = Color3.fromRGB(21, 37, 26),
    SuccessText = Color3.fromRGB(80, 220, 120),
    SuccessBorder = Color3.fromRGB(41, 121, 61),

    SliderBack = Color3.fromRGB(29, 25, 43),
    SliderFill = Color3.fromRGB(156, 90, 255),
    SliderThumb = Color3.fromRGB(241, 241, 251),

    ToggleOn = Color3.fromRGB(156, 90, 255),
    ToggleOff = Color3.fromRGB(29, 25, 43),
    ToggleBorder = Color3.fromRGB(61, 55, 89),

    Dropdown = Color3.fromRGB(27, 23, 41),
    DropdownOption = Color3.fromRGB(23, 21, 33),
    DropdownOptionActive = Color3.fromRGB(156, 90, 255),
    DropdownText = Color3.fromRGB(241, 241, 251),
    DropdownBorder = Color3.fromRGB(51, 45, 75),

    ScrollBar = Color3.fromRGB(61, 55, 89),
}

local function getParent()
    if runService:IsStudio() then
        return lp:WaitForChild("PlayerGui")
    end
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return coreGui
end

local function applyCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 0)
    c.Parent = inst
    return c
end

local function applyStroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Parent = inst
    return s
end

local function applyPadding(inst, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = inst
    return p
end

local function makeDraggable(frame, dragArea)
    local dragging = false
    local startPos, startFramePos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startFramePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    userInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startPos
            frame.Position = UDim2.new(
                startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
                startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
            )
        end
    end)
end

local function tween(inst, props, time)
    tweenService:Create(inst, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

function Library:new(config)
    config = config or {}
    self.Scheme = setmetatable(config.scheme or {}, { __index = DefaultScheme })
    self.Tabs = {}
    self.CurrentTab = nil

    local S = self.Scheme
    local viewport = workspace.CurrentCamera.ViewportSize
    local gui = Instance.new("ScreenGui")
    gui.Name = "Legacy"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = getParent()
    self.Gui = gui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.BorderSizePixel = 0
    main.BackgroundColor3 = S.Main
    main.Size = config.size or UDim2.new(0, 536, 0, 582)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Parent = gui
    self.Main = main

    applyCorner(main, 6)
    applyStroke(main, S.Border, 2)

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.BorderSizePixel = 0
    topBar.BackgroundColor3 = S.TopBar
    topBar.Size = UDim2.new(1, 0, 0, 30)
    topBar.Parent = main
    applyCorner(topBar, 6)

    local topBarCover = Instance.new("Frame")
    topBarCover.Name = "Cover"
    topBarCover.BorderSizePixel = 0
    topBarCover.BackgroundColor3 = S.TopBar
    topBarCover.Size = UDim2.new(1, 0, 0.5, 0)
    topBarCover.Position = UDim2.new(0, 0, 0.5, 0)
    topBarCover.Parent = topBar

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Text = config.name or "UI Library"
    title.TextColor3 = S.TopBarTitle
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Parent = topBar
    applyPadding(title, 0, 0, 8, 0)
    self.Title = title

    local exitBtn = Instance.new("TextButton")
    exitBtn.Name = "ExitBtn"
    exitBtn.BackgroundTransparency = 1
    exitBtn.BorderSizePixel = 0
    exitBtn.Text = "X"
    exitBtn.TextColor3 = S.TextDim
    exitBtn.TextSize = 16
    exitBtn.Font = Enum.Font.GothamBold
    exitBtn.Size = UDim2.new(0, 30, 0, 30)
    exitBtn.Position = UDim2.new(1, -30, 0, 0)
    exitBtn.Parent = topBar
    exitBtn.MouseEnter:Connect(function()
        tween(exitBtn, { TextColor3 = S.WarningText }, 0.15)
    end)
    exitBtn.MouseLeave:Connect(function()
        tween(exitBtn, { TextColor3 = S.TextDim }, 0.15)
    end)
    exitBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    makeDraggable(main, topBar)

    local nav = Instance.new("Frame")
    nav.Name = "Navigation"
    nav.BorderSizePixel = 0
    nav.BackgroundColor3 = S.Nav
    nav.Size = UDim2.new(1, -12, 0, 30)
    nav.Position = UDim2.new(0, 6, 0, 36)
    nav.Parent = main
    applyCorner(nav, 4)
    applyStroke(nav, S.Border, 1)

    local buttonHolder = Instance.new("Frame")
    buttonHolder.Name = "ButtonHolder"
    buttonHolder.BackgroundTransparency = 1
    buttonHolder.BorderSizePixel = 0
    buttonHolder.Size = UDim2.new(1, 0, 1, 0)
    buttonHolder.Parent = nav

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 2)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.FillDirection = Enum.FillDirection.Horizontal
    navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    navLayout.Parent = buttonHolder
    applyPadding(buttonHolder, 4, 4, 4, 4)

    local content = Instance.new("ScrollingFrame")
    content.Name = "ContentContainer"
    content.BorderSizePixel = 0
    content.BackgroundColor3 = S.Content
    content.Size = UDim2.new(1, -12, 1, -74)
    content.Position = UDim2.new(0, 6, 0, 72)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = S.ScrollBar
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.ElasticBehavior = Enum.ElasticBehavior.Never
    content.Active = true
    content.Parent = main
    applyCorner(content, 4)
    applyStroke(content, S.BorderDim, 1)
    self.Content = content

    self.NavLayout = navLayout
    self.ButtonHolder = buttonHolder

    if config.keybind then
        userInput.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == config.keybind then
                self:Toggle()
            end
        end)
    end

    self:CreateTab("Home")

    return self
end

function Library:CreateTab(name)
    local S = self.Scheme

    local tabButton = Instance.new("TextButton")
    tabButton.Name = name
    tabButton.BackgroundColor3 = S.NavIdle
    tabButton.BorderSizePixel = 0
    tabButton.Text = name
    tabButton.TextColor3 = S.NavIdleText
    tabButton.TextSize = 13
    tabButton.Font = Enum.Font.Gotham
    tabButton.Size = UDim2.new(0, 90, 1, 0)
    tabButton.Parent = self.ButtonHolder
    applyCorner(tabButton, 4)
    applyPadding(tabButton, 0, 0, 8, 8)

    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Name = name .. "Tab"
    tabContent.BorderSizePixel = 0
    tabContent.BackgroundTransparency = 1
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.Position = UDim2.new(0, 0, 0, 0)
    tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabContent.ScrollBarThickness = 4
    tabContent.ScrollBarImageColor3 = S.ScrollBar
    tabContent.ScrollingDirection = Enum.ScrollingDirection.Y
    tabContent.ElasticBehavior = Enum.ElasticBehavior.Never
    tabContent.Active = true
    tabContent.Visible = false
    tabContent.Parent = self.Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = tabContent

    applyPadding(tabContent, 8, 8, 8, 8)

    local tab = {
        Name = name,
        Button = tabButton,
        Content = tabContent,
        Components = {},
    }

    tabButton.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            tween(tabButton, { BackgroundColor3 = S.Element }, 0.15)
        end
    end)
    tabButton.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            tween(tabButton, { BackgroundColor3 = S.NavIdle }, 0.15)
        end
    end)
    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.CurrentTab then
        self:SelectTab(tab)
    end

    return tab
end

function Library:SelectTab(tab)
    local S = self.Scheme
    for _, t in ipairs(self.Tabs) do
        t.Content.Visible = false
        tween(t.Button, { BackgroundColor3 = S.NavIdle, TextColor3 = S.NavIdleText }, 0.15)
    end
    tab.Content.Visible = true
    tween(tab.Button, { BackgroundColor3 = S.NavActive, TextColor3 = S.NavActiveText }, 0.15)
    self.CurrentTab = tab
end

function Library:Toggle()
    self.Visible = not self.Visible
    self.Main.Visible = self.Visible
end

function Library:SetTitle(text)
    self.Title.Text = text
end

local function createRow(tab, name, height)
    local S = Library.Scheme
    local row = Instance.new("Frame")
    row.Name = name
    row.BorderSizePixel = 0
    row.BackgroundColor3 = S.Element
    row.Size = UDim2.new(1, -8, 0, height or 30)
    row.Parent = tab.Content
    applyCorner(row, 4)
    applyStroke(row, S.Border, 1)
    table.insert(tab.Components, row)
    return row
end

function Library:AddButton(tab, opts)
    opts = opts or {}
    local S = self.Scheme
    local row = createRow(tab, opts.Name or "Button", 30)

    local btn = Instance.new("TextButton")
    btn.Name = "Btn"
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Parent = row

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.Text or "Button"
    label.TextColor3 = S.ButtonText
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Parent = row
    applyPadding(label, 0, 0, 8, 0)

    btn.MouseEnter:Connect(function()
        tween(row, { BackgroundColor3 = S.ButtonHover }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(row, { BackgroundColor3 = S.Element }, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        if opts.Func then
            pcall(opts.Func)
        end
    end)

    local api = { Row = row, Label = label, Button = btn }
    tab.Components[#tab.Components] = api
    return api
end

function Library:AddLabel(tab, opts)
    opts = opts or {}
    local S = self.Scheme
    local row = createRow(tab, "Label", 28)
    row.BackgroundColor3 = S.Label
    applyStroke(row, S.BorderDim, 1)

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.Text or "Label"
    label.TextColor3 = S.LabelText
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Parent = row
    applyPadding(label, 0, 0, 8, 0)

    return { Row = row, Label = label }
end

function Library:AddInfo(tab, opts)
    opts = opts or {}
    local S = self.Scheme
    local row = createRow(tab, "Info", 28)
    row.BackgroundColor3 = S.Info
    applyStroke(row, S.InfoBorder, 1)

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.Text or "Info"
    label.TextColor3 = S.InfoText
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Parent = row
    applyPadding(label, 0, 0, 8, 0)

    return { Row = row, Label = label }
end

function Library:AddWarning(tab, opts)
    opts = opts or {}
    local S = self.Scheme
    local row = createRow(tab, "Warning", 28)
    row.BackgroundColor3 = S.Warning
    applyStroke(row, S.WarningBorder, 1)

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.Text or "Warning"
    label.TextColor3 = S.WarningText
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Parent = row
    applyPadding(label, 0, 0, 8, 0)

    return { Row = row, Label = label }
end

function Library:AddToggle(tab, opts)
    opts = opts or {}
    local S = self.Scheme
    local row = createRow(tab, "Toggle", 34)

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.Text or "Toggle"
    label.TextColor3 = S.TextDim
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Parent = row
    applyPadding(label, 0, 0, 8, 0)

    local checkHolder = Instance.new("Frame")
    checkHolder.Name = "CheckmarkHolder"
    checkHolder.BorderSizePixel = 0
    checkHolder.BackgroundColor3 = S.ToggleOff
    checkHolder.AnchorPoint = Vector2.new(1, 0.5)
    checkHolder.Size = UDim2.new(0, 20, 0, 20)
    checkHolder.Position = UDim2.new(1, -8, 0.5, 0)
    checkHolder.Parent = row
    applyCorner(checkHolder, 4)
    local stroke = applyStroke(checkHolder, S.ToggleBorder, 1)

    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Parent = row

    local state = opts.Default or false

    local function render()
        if state then
            tween(checkHolder, { BackgroundColor3 = S.ToggleOn }, 0.15)
            tween(stroke, { Color = S.ToggleOn }, 0.15)
            tween(label, { TextColor3 = S.Text }, 0.15)
        else
            tween(checkHolder, { BackgroundColor3 = S.ToggleOff }, 0.15)
            tween(stroke, { Color = S.ToggleBorder }, 0.15)
            tween(label, { TextColor3 = S.TextDim }, 0.15)
        end
    end
    render()

    btn.MouseButton1Click:Connect(function()
        state = not state
        render()
        if opts.Callback then
            pcall(opts.Callback, state)
        end
    end)

    local api = {
        Row = row,
        Label = label,
        State = state,
        Set = function(v)
            state = v
            render()
            if opts.Callback then pcall(opts.Callback, state) end
        end,
        Get = function() return state end,
    }
    return api
end

function Library:AddSlider(tab, opts)
    opts = opts or {}
    local S = self.Scheme
    local row = createRow(tab, "Slider", 40)

    local min = opts.Min or 0
    local max = opts.Max or 100
    local value = opts.Default or min

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.Text or "Slider"
    label.TextColor3 = S.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -70, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 2)
    label.Parent = row
    applyPadding(label, 0, 0, 8, 0)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.BackgroundTransparency = 1
    valueLabel.BorderSizePixel = 0
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = S.Text
    valueLabel.TextSize = 14
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Size = UDim2.new(0, 60, 0, 18)
    valueLabel.Position = UDim2.new(1, -68, 0, 2)
    valueLabel.Parent = row
    applyPadding(valueLabel, 0, 0, 0, 8)

    local sliderBack = Instance.new("Frame")
    sliderBack.Name = "SliderBack"
    sliderBack.BorderSizePixel = 0
    sliderBack.BackgroundColor3 = S.SliderBack
    sliderBack.Size = UDim2.new(1, -16, 0, 12)
    sliderBack.Position = UDim2.new(0, 8, 0, 22)
    sliderBack.Parent = row
    applyCorner(sliderBack, 6)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BorderSizePixel = 0
    fill.BackgroundColor3 = S.SliderFill
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = sliderBack
    applyCorner(fill, 6)

    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.BorderSizePixel = 0
    thumb.BackgroundColor3 = S.SliderThumb
    thumb.Size = UDim2.new(0, 8, 1, 4)
    thumb.Position = UDim2.new(0, 0, 0.5, 0)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Parent = sliderBack
    applyCorner(thumb, 4)

    local dragging = false

    local function render()
        local pct = (value - min) / (max - min)
        tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.05)
        tween(thumb, { Position = UDim2.new(pct, 0, 0.5, 0) }, 0.05)
        valueLabel.Text = tostring(math.floor(value * 100) / 100)
    end
    render()

    local function updateFromInput(input)
        local rel = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local newValue = min + (max - min) * rel
        newValue = math.floor(newValue)
        if newValue ~= value then
            value = newValue
            render()
            if opts.Callback then
                pcall(opts.Callback, value)
            end
        end
    end

    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    userInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    local api = {
        Row = row,
        Label = label,
        Set = function(v)
            value = math.clamp(v, min, max)
            render()
            if opts.Callback then pcall(opts.Callback, value) end
        end,
        Get = function() return value end,
    }
    return api
end

function Library:AddDropdown(tab, opts)
    opts = opts or {}
    local S = self.Scheme
    local row = createRow(tab, "Dropdown", 30)

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = opts.Text or "Dropdown"
    label.TextColor3 = S.DropdownText
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Parent = row
    applyPadding(label, 0, 0, 8, 0)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.BackgroundTransparency = 1
    valueLabel.BorderSizePixel = 0
    valueLabel.Text = tostring(opts.Default or "...") .. "  ▼"
    valueLabel.TextColor3 = S.TextDim
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Size = UDim2.new(0, 100, 1, 0)
    valueLabel.Position = UDim2.new(1, -108, 0, 0)
    valueLabel.Parent = row
    applyPadding(valueLabel, 0, 0, 0, 8)

    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Parent = row

    local list = Instance.new("ScrollingFrame")
    list.Name = "OptionHolder"
    list.BorderSizePixel = 0
    list.BackgroundColor3 = S.Dropdown
    list.Size = UDim2.new(1, -8, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = S.ScrollBar
    list.Visible = false
    list.Parent = tab.Content
    applyCorner(list, 4)
    applyStroke(list, S.DropdownBorder, 1)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list
    applyPadding(list, 4, 4, 4, 4)

    local values = opts.Values or {}
    local selected = opts.Default or values[1]
    local open = false

    local options = {}
    for i, v in ipairs(values) do
        local opt = Instance.new("TextButton")
        opt.Name = v
        opt.BackgroundColor3 = S.DropdownOption
        opt.BorderSizePixel = 0
        opt.Text = v
        opt.TextColor3 = S.DropdownText
        opt.TextSize = 13
        opt.Font = Enum.Font.Gotham
        opt.TextXAlignment = Enum.TextXAlignment.Left
        opt.Size = UDim2.new(1, 0, 0, 22)
        opt.Parent = list
        applyCorner(opt, 3)
        applyPadding(opt, 0, 0, 6, 6)
        table.insert(options, opt)

        opt.MouseEnter:Connect(function()
            if selected ~= v then
                tween(opt, { BackgroundColor3 = S.Element }, 0.1)
            end
        end)
        opt.MouseLeave:Connect(function()
            if selected ~= v then
                tween(opt, { BackgroundColor3 = S.DropdownOption }, 0.1)
            end
        end)
        opt.MouseButton1Click:Connect(function()
            selected = v
            for _, o in ipairs(options) do
                if o.Name == selected then
                    o.BackgroundColor3 = S.DropdownOptionActive
                else
                    o.BackgroundColor3 = S.DropdownOption
                end
            end
            valueLabel.Text = selected .. "  ▼"
            if opts.Callback then
                pcall(opts.Callback, selected)
            end
            open = false
            list.Visible = false
        end)
    end

    if selected then
        for _, o in ipairs(options) do
            if o.Name == selected then
                o.BackgroundColor3 = S.DropdownOptionActive
            end
        end
        valueLabel.Text = selected .. "  ▼"
    end

    local function toggleList()
        open = not open
        list.Visible = open
        if open then
            list.Size = UDim2.new(row.AbsoluteSize.X - 8, 0, 0, math.min(#values * 24 + 8, 200))
            list.Position = UDim2.new(row.Position.X.Scale, row.Position.X.Offset + 4, row.Position.Y.Scale, row.Position.Y.Offset + row.AbsoluteSize.Y + 4)
            valueLabel.Text = tostring(selected or "...") .. "  ▲"
        else
            valueLabel.Text = tostring(selected or "...") .. "  ▼"
        end
    end

    btn.MouseButton1Click:Connect(toggleList)
    btn.MouseEnter:Connect(function()
        tween(row, { BackgroundColor3 = S.ElementHover }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(row, { BackgroundColor3 = S.Element }, 0.15)
    end)

    local api = {
        Row = row,
        Label = label,
        Set = function(v)
            if v then
                selected = v
                valueLabel.Text = v .. "  ▼"
                if opts.Callback then pcall(opts.Callback, v) end
            end
        end,
        Get = function() return selected end,
        Refresh = function(newValues)
            values = newValues
        end,
    }
    return api
end

return Library
