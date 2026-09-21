local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")

local Library = {}
Library.__index = Library

local DefaultScheme = {
    Background   = Color3.fromRGB(21, 19, 31),
    Element      = Color3.fromRGB(37, 33, 53),
    ElementHover = Color3.fromRGB(46, 40, 66),
    Accent       = Color3.fromRGB(156, 90, 255),
    AccentDim    = Color3.fromRGB(110, 62, 180),
    Text         = Color3.fromRGB(241, 241, 251),
    TextDim      = Color3.fromRGB(161, 161, 181),
    Border       = Color3.fromRGB(61, 55, 89),
    Success      = Color3.fromRGB(80, 220, 120),
    Warning      = Color3.fromRGB(255, 81, 81),
    Danger       = Color3.fromRGB(255, 81, 81),
    Info         = Color3.fromRGB(91, 171, 255),

    TitlebarBackground = Color3.fromRGB(11, 11, 11),
    TitlebarText       = Color3.fromRGB(156, 90, 255),
    CloseIdle          = Color3.fromRGB(161, 161, 181),
    CloseHover         = Color3.fromRGB(255, 81, 81),

    NavBackground = Color3.fromRGB(27, 23, 41),
    NavIdleText   = Color3.fromRGB(161, 161, 181),
    NavActive     = Color3.fromRGB(37, 33, 53),
    NavActiveText = Color3.fromRGB(156, 90, 255),

    TabBackground = Color3.fromRGB(27, 23, 41),
    TabBorder     = Color3.fromRGB(61, 55, 89),

    ButtonBackground = Color3.fromRGB(37, 33, 53),
    ButtonBorder     = Color3.fromRGB(61, 55, 89),
    ButtonText       = Color3.fromRGB(241, 241, 251),

    LabelBackground = Color3.fromRGB(27, 23, 41),
    LabelBorder     = Color3.fromRGB(51, 45, 75),
    LabelText       = Color3.fromRGB(241, 241, 251),

    InfoBackground = Color3.fromRGB(21, 27, 41),
    InfoBorder     = Color3.fromRGB(51, 91, 141),
    InfoText       = Color3.fromRGB(91, 171, 255),

    WarningBackground = Color3.fromRGB(37, 21, 27),
    WarningBorder     = Color3.fromRGB(121, 41, 51),
    WarningText       = Color3.fromRGB(255, 81, 81),

    SliderBackground = Color3.fromRGB(29, 25, 43),
    SliderFill       = Color3.fromRGB(156, 90, 255),
    SliderThumb      = Color3.fromRGB(241, 241, 251),

    DropdownBackground = Color3.fromRGB(27, 23, 41),
    DropdownBorder     = Color3.fromRGB(51, 45, 75),
    DropdownText       = Color3.fromRGB(241, 241, 251),
    DropdownItemIdle   = Color3.fromRGB(23, 21, 33),
    DropdownItemActive = Color3.fromRGB(156, 90, 255),
    DropdownItemText   = Color3.fromRGB(241, 241, 251),

    ToggleBackground = Color3.fromRGB(37, 33, 53),
    ToggleBorder     = Color3.fromRGB(61, 55, 89),
    ToggleText       = Color3.fromRGB(201, 201, 216),
    ToggleBoxOff     = Color3.fromRGB(29, 25, 43),
    ToggleBoxOffBorder = Color3.fromRGB(61, 55, 89),
    ToggleBoxOn      = Color3.fromRGB(156, 90, 255),
    ToggleBoxOnBorder = Color3.fromRGB(156, 90, 255),

    NotifyBackground = Color3.fromRGB(27, 23, 41),
    NotifyBorder     = Color3.fromRGB(61, 55, 89),
    NotifyTitle      = Color3.fromRGB(241, 241, 251),
    NotifyBody       = Color3.fromRGB(161, 161, 181),
}

local function create(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function applyStroke(frame, color, thickness)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, frame)
end

local function applyCorner(frame, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 4),
    }, frame)
end

local function tween(obj, time, props)
    local t = tweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function makeDraggable(frame, dragArea)
    local dragging = false
    local dragStart, startPos

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    userInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function getParent()
    if runService:IsStudio() then
        return players.LocalPlayer:WaitForChild("PlayerGui")
    end
    if gethui then
        return gethui()
    end
    return coreGui
end

function Library:new(config)
    config = config or {}
    local self = setmetatable({}, Library)
    self.Scheme = setmetatable(config.scheme or {}, { __index = DefaultScheme })
    self.Tabs = {}
    self.ActiveTab = nil
    self.Keybind = config.keybind or Enum.KeyCode.RightShift
    self.Visible = true

    local S = self.Scheme

    local gui = create("ScreenGui", {
        Name = config.name or "Legacy",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    }, getParent())

    local main = create("Frame", {
        Name = "Main",
        BorderSizePixel = 0,
        BackgroundColor3 = S.Background,
        Size = config.size or UDim2.new(0, 536, 0, 582),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = true,
    }, gui)

    applyStroke(main, S.Border, 2)
    applyCorner(main, 4)

    local topBar = create("Frame", {
        Name = "TopBar",
        BorderSizePixel = 0,
        BackgroundColor3 = S.TitlebarBackground,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
    }, main)
    applyStroke(topBar, S.Border, 2)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = config.title or "Legacy UI",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.TitlebarText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, topBar)

    local closeBtn = create("TextButton", {
        Name = "CloseBtn",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = "✕",
        TextSize = 16,
        TextColor3 = S.CloseIdle,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -30, 0, 0),
    }, topBar)

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, 0.15, { TextColor3 = S.CloseHover })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, 0.15, { TextColor3 = S.CloseIdle })
    end)
    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    local nav = create("Frame", {
        Name = "Navigation",
        BorderSizePixel = 0,
        BackgroundColor3 = S.NavBackground,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 0, 30),
    }, main)
    applyStroke(nav, S.Border, 1)

    local buttonHolder = create("Frame", {
        Name = "ButtonHolder",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    }, nav)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
    }, buttonHolder)
    create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
    }, buttonHolder)

    local content = create("ScrollingFrame", {
        Name = "ContentContainer",
        BorderSizePixel = 0,
        BackgroundColor3 = S.TabBackground,
        Size = UDim2.new(1, -12, 1, -70),
        Position = UDim2.new(0, 6, 0, 64),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = S.Border,
        ScrollBarImageTransparency = 0.3,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ScrollingEnabled = true,
        Active = true,
    }, main)
    applyStroke(content, S.Border, 1)
    applyCorner(content, 4)

    makeDraggable(main, topBar)

    self.Gui = gui
    self.Main = main
    self.TopBar = topBar
    self.Nav = nav
    self.ButtonHolder = buttonHolder
    self.Content = content

    userInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.Keybind then
            self.Visible = not self.Visible
            gui.Enabled = self.Visible
        end
    end)

    return self
end

function Library:CreateTab(name)
    local S = self.Scheme

    local btn = create("TextButton", {
        Name = name .. "TabBtn",
        BorderSizePixel = 0,
        BackgroundColor3 = S.NavBackground,
        Text = name,
        TextSize = 14,
        TextColor3 = S.NavIdleText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0, 100, 1, 0),
        AutoButtonColor = false,
    }, self.ButtonHolder)
    applyCorner(btn, 4)

    local frame = create("Frame", {
        Name = name .. "Tab",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    }, self.Content)
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, frame)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, frame)

    local tab = {
        Name = name,
        Button = btn,
        Frame = frame,
        Library = self,
    }

    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(btn, 0.15, { BackgroundColor3 = S.ElementHover })
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(btn, 0.15, { BackgroundColor3 = S.NavBackground })
        end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function Library:SelectTab(tab)
    local S = self.Scheme
    for _, t in ipairs(self.Tabs) do
        if t == tab then
            t.Button.BackgroundColor3 = S.NavActive
            t.Button.TextColor3 = S.NavActiveText
            t.Frame.Visible = true
        else
            t.Button.BackgroundColor3 = S.NavBackground
            t.Button.TextColor3 = S.NavIdleText
            t.Frame.Visible = false
        end
    end
    self.ActiveTab = tab
end

function Library:Notify(opts)
    opts = opts or {}
    local S = self.Scheme

    local notify = create("Frame", {
        Name = "Notify",
        BorderSizePixel = 0,
        BackgroundColor3 = S.NotifyBackground,
        Size = UDim2.new(0, 260, 0, 60),
        Position = UDim2.new(1, 10, 1, -70),
        AnchorPoint = Vector2.new(1, 1),
    }, self.Gui)
    applyStroke(notify, S.NotifyBorder, 1)
    applyCorner(notify, 4)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Title or "Notification",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.NotifyTitle,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 8, 0, 6),
    }, notify)

    local body = create("TextLabel", {
        Name = "Body",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Body or "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextColor3 = S.NotifyBody,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, -16, 1, -30),
        Position = UDim2.new(0, 8, 0, 26),
    }, notify)

    tween(notify, 0.3, { Position = UDim2.new(1, -10, 1, -70) })

    task.delay(opts.Time or 3, function()
        tween(notify, 0.3, { Position = UDim2.new(1, 10, 1, -70) })
        task.wait(0.3)
        notify:Destroy()
    end)
end

function Library:Toggle()
    self.Visible = not self.Visible
    self.Gui.Enabled = self.Visible
end

function Library:Destroy()
    self.Gui:Destroy()
end

local Tab = {}
Tab.__index = Tab

function Tab:AddButton(opts)
    local S = self.Library.Scheme
    local parent = self.Frame

    local btn = create("TextButton", {
        Name = "Button_" .. (opts.Text or "Unnamed"),
        BorderSizePixel = 0,
        BackgroundColor3 = S.ButtonBackground,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 36),
    }, parent)
    applyStroke(btn, S.ButtonBorder, 1)
    applyCorner(btn, 4)

    create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Button",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.ButtonText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, btn)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = S.ElementHover })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = S.ButtonBackground })
    end)
    btn.MouseButton1Click:Connect(function()
        if opts.Func then
            opts.Func()
        end
    end)

    return btn
end

function Tab:AddLabel(opts)
    local S = self.Library.Scheme
    local parent = self.Frame

    local frame = create("Frame", {
        Name = "Label_" .. (opts.Text or "Unnamed"),
        BorderSizePixel = 0,
        BackgroundColor3 = S.LabelBackground,
        Size = UDim2.new(1, 0, 0, 28),
    }, parent)
    applyStroke(frame, S.LabelBorder, 1)
    applyCorner(frame, 4)

    create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Label",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.LabelText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, frame)

    return frame
end

function Tab:AddInfo(opts)
    local S = self.Library.Scheme
    local parent = self.Frame

    local frame = create("Frame", {
        Name = "Info_" .. (opts.Text or "Unnamed"),
        BorderSizePixel = 0,
        BackgroundColor3 = S.InfoBackground,
        Size = UDim2.new(1, 0, 0, 28),
    }, parent)
    applyStroke(frame, S.InfoBorder, 1)
    applyCorner(frame, 4)

    create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Info",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.InfoText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, frame)

    return frame
end

function Tab:AddWarning(opts)
    local S = self.Library.Scheme
    local parent = self.Frame

    local frame = create("Frame", {
        Name = "Warning_" .. (opts.Text or "Unnamed"),
        BorderSizePixel = 0,
        BackgroundColor3 = S.WarningBackground,
        Size = UDim2.new(1, 0, 0, 28),
    }, parent)
    applyStroke(frame, S.WarningBorder, 1)
    applyCorner(frame, 4)

    create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Warning",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.WarningText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, frame)

    return frame
end

function Tab:AddSlider(opts)
    local S = self.Library.Scheme
    local parent = self.Frame

    local min = opts.Min or 0
    local max = opts.Max or 100
    local value = opts.Default or min

    local frame = create("Frame", {
        Name = "Slider_" .. (opts.Text or "Unnamed"),
        BorderSizePixel = 0,
        BackgroundColor3 = S.Element,
        Size = UDim2.new(1, 0, 0, 48),
    }, parent)
    applyStroke(frame, S.Border, 1)
    applyCorner(frame, 4)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Slider",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.Text,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 8, 0, 4),
    }, frame)

    local valueLabel = create("TextLabel", {
        Name = "Value",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = tostring(value),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = S.Text,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0.3, -8, 0, 20),
        Position = UDim2.new(0.7, 0, 0, 4),
    }, frame)

    local sliderBack = create("Frame", {
        Name = "SliderBack",
        BorderSizePixel = 0,
        BackgroundColor3 = S.SliderBackground,
        Size = UDim2.new(1, -16, 0, 8),
        Position = UDim2.new(0, 8, 0, 32),
    }, frame)
    applyCorner(sliderBack, 4)

    local fill = create("Frame", {
        Name = "Fill",
        BorderSizePixel = 0,
        BackgroundColor3 = S.SliderFill,
        Size = UDim2.new(0, 0, 1, 0),
    }, sliderBack)
    applyCorner(fill, 4)

    local thumb = create("Frame", {
        Name = "Thumb",
        BorderSizePixel = 0,
        BackgroundColor3 = S.SliderThumb,
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
    }, sliderBack)
    applyCorner(thumb, 6)

    local dragging = false

    local function update(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        value = val
        fill.Size = UDim2.new(pos, 0, 1, 0)
        thumb.Position = UDim2.new(pos, 0, 0.5, 0)
        valueLabel.Text = tostring(val)
        if opts.Callback then
            opts.Callback(val)
        end
    end

    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    userInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    userInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    thumb.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)

    return frame
end

function Tab:AddDropdown(opts)
    local S = self.Library.Scheme
    local parent = self.Frame
    local values = opts.Values or {}
    local selected = opts.Default or values[1]

    local frame = create("Frame", {
        Name = "Dropdown_" .. (opts.Text or "Unnamed"),
        BorderSizePixel = 0,
        BackgroundColor3 = S.DropdownBackground,
        Size = UDim2.new(1, 0, 0, 32),
    }, parent)
    applyStroke(frame, S.DropdownBorder, 1)
    applyCorner(frame, 4)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Dropdown",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.DropdownText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0.5, -8, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, frame)

    local valueLabel = create("TextLabel", {
        Name = "Value",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = tostring(selected),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = S.DropdownText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
    }, frame)

    local arrow = create("TextLabel", {
        Name = "Arrow",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = "▼",
        TextSize = 12,
        TextColor3 = S.DropdownText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
    }, frame)

    local list = create("ScrollingFrame", {
        Name = "List",
        BorderSizePixel = 0,
        BackgroundColor3 = S.DropdownBackground,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 2),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = S.DropdownBorder,
        Visible = false,
        ClipsDescendants = true,
    }, frame)
    applyStroke(list, S.DropdownBorder, 1)
    applyCorner(list, 4)
    create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)

    local open = false

    local function toggleList()
        open = not open
        list.Visible = open
        arrow.Text = open and "▲" or "▼"
        if open then
            local count = #values
            local height = math.min(count * 22 + 8, 150)
            tween(list, 0.15, { Size = UDim2.new(1, 0, 0, height) })
        else
            tween(list, 0.15, { Size = UDim2.new(1, 0, 0, 0) })
        end
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggleList()
        end
    end)

    for _, val in ipairs(values) do
        local item = create("TextButton", {
            Name = "Item_" .. val,
            BorderSizePixel = 0,
            BackgroundColor3 = S.DropdownItemIdle,
            Text = tostring(val),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = S.DropdownItemText,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, 0, 0, 20),
            AutoButtonColor = false,
        }, list)
        create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, item)

        item.MouseEnter:Connect(function()
            tween(item, 0.1, { BackgroundColor3 = S.ElementHover })
        end)
        item.MouseLeave:Connect(function()
            tween(item, 0.1, { BackgroundColor3 = S.DropdownItemIdle })
        end)
        item.MouseButton1Click:Connect(function()
            selected = val
            valueLabel.Text = tostring(val)
            if opts.Callback then
                opts.Callback(val)
            end
            toggleList()
        end)
    end

    return frame
end

function Tab:AddToggle(opts)
    local S = self.Library.Scheme
    local parent = self.Frame
    local state = opts.Default or false

    local frame = create("TextButton", {
        Name = "Toggle_" .. (opts.Text or "Unnamed"),
        BorderSizePixel = 0,
        BackgroundColor3 = S.ToggleBackground,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 36),
    }, parent)
    applyStroke(frame, S.ToggleBorder, 1)
    applyCorner(frame, 4)

    create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Toggle",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.ToggleText,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, frame)

    local box = create("Frame", {
        Name = "CheckmarkHolder",
        BorderSizePixel = 0,
        BackgroundColor3 = state and S.ToggleBoxOn or S.ToggleBoxOff,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0.5, -10),
    }, frame)
    applyStroke(box, state and S.ToggleBoxOnBorder or S.ToggleBoxOffBorder, 1)
    applyCorner(box, 3)

    local function update()
        box.BackgroundColor3 = state and S.ToggleBoxOn or S.ToggleBoxOff
        for _, c in ipairs(box:GetChildren()) do
            if c:IsA("UIStroke") then
                c.Color = state and S.ToggleBoxOnBorder or S.ToggleBoxOffBorder
            end
        end
        if opts.Callback then
            opts.Callback(state)
        end
    end

    frame.MouseButton1Click:Connect(function()
        state = not state
        update()
    end)

    return frame
end

Tab.Library = Library
Library.Tab = Tab
Library.Tree = {}

return Library
