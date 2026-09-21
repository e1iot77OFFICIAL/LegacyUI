local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")

local Library = {}
Library.__index = Library

local Tab = {}
Tab.__index = Tab

local Scheme = {
    Background   = Color3.fromRGB(21, 19, 31),
    Element      = Color3.fromRGB(37, 33, 53),
    ElementHover = Color3.fromRGB(46, 40, 66),
    Accent       = Color3.fromRGB(156, 90, 255),
    Text         = Color3.fromRGB(241, 241, 251),
    TextDim      = Color3.fromRGB(161, 161, 181),
    Border       = Color3.fromRGB(61, 55, 89),
    Danger       = Color3.fromRGB(255, 81, 81),

    TitlebarBackground = Color3.fromRGB(11, 11, 11),
    TitlebarText       = Color3.fromRGB(156, 90, 255),

    NavBackground = Color3.fromRGB(27, 23, 41),
    NavIdleText   = Color3.fromRGB(161, 161, 181),
    NavActive     = Color3.fromRGB(37, 33, 53),
    NavActiveText = Color3.fromRGB(156, 90, 255),

    ContentBackground = Color3.fromRGB(27, 23, 41),

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

    DropdownBackground = Color3.fromRGB(27, 23, 41),
    DropdownBorder     = Color3.fromRGB(51, 45, 75),
    DropdownText       = Color3.fromRGB(241, 241, 251),
    DropdownItemIdle   = Color3.fromRGB(23, 21, 33),
    DropdownItemText   = Color3.fromRGB(241, 241, 251),

    ToggleBackground   = Color3.fromRGB(37, 33, 53),
    ToggleBorder       = Color3.fromRGB(61, 55, 89),
    ToggleText         = Color3.fromRGB(201, 201, 216),
    ToggleBoxOff       = Color3.fromRGB(29, 25, 43),
    ToggleBoxOffBorder = Color3.fromRGB(61, 55, 89),
    ToggleBoxOn        = Color3.fromRGB(156, 90, 255),
    ToggleBoxOnBorder  = Color3.fromRGB(156, 90, 255),

    NotifyBackground = Color3.fromRGB(27, 23, 41),
    NotifyBorder     = Color3.fromRGB(61, 55, 89),
}

local BODY_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local TITLE_FONT = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

local function create(class, props, parent)
    local inst = Instance.new(class)
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

local function stroke(parent, color, thickness)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 0),
    }, parent)
end

local function tween(obj, time, props)
    local t = tweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function draggable(frame, dragArea)
    local dragging, dragStart, startPos = false, nil, nil
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

local function clearOld()
    local containers = {
        players.LocalPlayer:FindFirstChild("PlayerGui"),
        coreGui,
    }
    if gethui then
        table.insert(containers, gethui())
    end
    for _, container in ipairs(containers) do
        if container then
            local old = container:FindFirstChild("Legacy")
            if old then
                old:Destroy()
            end
        end
    end
end

function Library:new(config)
    config = config or {}
    local self = setmetatable({}, Library)
    self.Scheme = setmetatable(config.scheme or {}, { __index = Scheme })
    self.Tabs = {}
    self.ActiveTab = nil
    self.Keybind = config.keybind or Enum.KeyCode.RightShift
    self.Visible = true
    self.OpenDropdowns = {}
    self.Connections = {}

    local S = self.Scheme

    clearOld()

    local gui = create("ScreenGui", {
        Name = "Legacy",
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
    }, gui)
    stroke(main, S.Border, 2)

    local topBar = create("Frame", {
        Name = "TopBar",
        BorderSizePixel = 0,
        BackgroundColor3 = S.TitlebarBackground,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
    }, main)
    stroke(topBar, S.Border, 2)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = config.title or "UI Library",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = TITLE_FONT,
        TextColor3 = S.TitlebarText,
        Size = UDim2.new(0.5, 0, 1, 0),
    }, topBar)
    create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, title)

    local closeBtn = create("TextButton", {
        Name = "ExitBtn",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = "✕",
        TextSize = 16,
        TextColor3 = S.TextDim,
        FontFace = BODY_FONT,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -30, 0, 0),
    }, topBar)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, 0.15, { TextColor3 = S.Danger })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, 0.15, { TextColor3 = S.TextDim })
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
    stroke(nav, S.Border, 1)

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

    local content = create("Frame", {
        Name = "ContentContainer",
        BorderSizePixel = 0,
        BackgroundColor3 = S.ContentBackground,
        Size = UDim2.new(1, -12, 1, -76),
        Position = UDim2.new(0, 6, 0, 64),
        ClipsDescendants = true,
    }, main)
    stroke(content, S.Border, 1)

    draggable(main, topBar)

    self.Gui = gui
    self.Main = main
    self.TopBar = topBar
    self.Nav = nav
    self.ButtonHolder = buttonHolder
    self.Content = content

    table.insert(self.Connections, userInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.Keybind then
            self.Visible = not self.Visible
            gui.Enabled = self.Visible
        end
    end))

    table.insert(self.Connections, userInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if #self.OpenDropdowns == 0 then return end

        local mousePos = userInput:GetMouseLocation()
        for i = #self.OpenDropdowns, 1, -1 do
            local entry = self.OpenDropdowns[i]
            if entry.Frame and entry.List and entry.Frame.Parent and entry.List.Parent then
                local framePos = entry.Frame.AbsolutePosition
                local frameSize = entry.Frame.AbsoluteSize
                local listPos = entry.List.AbsolutePosition
                local listSize = entry.List.AbsoluteSize

                local insideFrame = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X
                    and mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
                local insideList = mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X
                    and mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y

                if not insideFrame and not insideList then
                    entry.Close()
                end
            else
                table.remove(self.OpenDropdowns, i)
            end
        end
    end))

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
        FontFace = BODY_FONT,
        Size = UDim2.new(0, 100, 1, 0),
        AutoButtonColor = false,
    }, self.ButtonHolder)
    corner(btn, 4)

    local scroll = create("ScrollingFrame", {
        Name = name .. "Tab",
        BorderSizePixel = 0,
        BackgroundColor3 = S.ContentBackground,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = S.Border,
        ScrollBarImageTransparency = 0.3,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ScrollingEnabled = true,
        Active = true,
        Visible = false,
    }, self.Content)
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, scroll)

    local tab = setmetatable({
        Name = name,
        Button = btn,
        Frame = scroll,
        Library = self,
    }, Tab)

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

    if not self.NotifyHolder then
        self.NotifyHolder = create("Frame", {
            Name = "NotifyHolder",
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 260, 1, -20),
            Position = UDim2.new(1, -10, 0, 10),
            AnchorPoint = Vector2.new(1, 0),
        }, self.Gui)
        create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            FillDirection = Enum.FillDirection.Vertical,
        }, self.NotifyHolder)
    end

    local notify = create("Frame", {
        Name = "Notify",
        BorderSizePixel = 0,
        BackgroundColor3 = S.NotifyBackground,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = -tick(),
    }, self.NotifyHolder)
    stroke(notify, S.NotifyBorder, 1)

    local accent = create("Frame", {
        Name = "Accent",
        BorderSizePixel = 0,
        BackgroundColor3 = S.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
    }, notify)

    local titleLabel = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Title or "Notification",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.Text,
        FontFace = BODY_FONT,
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 10, 0, 6),
    }, notify)

    local bodyLabel = create("TextLabel", {
        Name = "Body",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Body or "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextColor3 = S.TextDim,
        FontFace = BODY_FONT,
        Size = UDim2.new(1, -16, 1, -26),
        Position = UDim2.new(0, 10, 0, 24),
    }, notify)

    tween(notify, 0.25, { BackgroundTransparency = 0 })
    tween(accent, 0.25, { BackgroundTransparency = 0 })

    task.delay(opts.Time or 3, function()
        if not notify or not notify.Parent then return end
        tween(notify, 0.25, { BackgroundTransparency = 1 })
        tween(accent, 0.25, { BackgroundTransparency = 1 })
        task.wait(0.3)
        if notify and notify.Parent then
            notify:Destroy()
        end
    end)
end

function Library:Toggle()
    self.Visible = not self.Visible
    self.Gui.Enabled = self.Visible
end

function Library:Destroy()
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}
    self.Gui:Destroy()
end

function Tab:AddButton(opts)
    local S = self.Library.Scheme

    local btn = create("TextButton", {
        Name = "Button",
        BorderSizePixel = 0,
        BackgroundColor3 = S.ButtonBackground,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 40),
    }, self.Frame)
    stroke(btn, S.ButtonBorder, 1)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Button",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.ButtonText,
        FontFace = BODY_FONT,
        Size = UDim2.new(1, -20, 1, 0),
    }, btn)
    create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, title)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = S.ElementHover })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = S.ButtonBackground })
    end)
    btn.MouseButton1Click:Connect(function()
        if opts.Func then opts.Func() end
    end)

    return btn
end

function Tab:AddLabel(opts)
    local S = self.Library.Scheme

    local frame = create("Frame", {
        Name = "Label",
        BorderSizePixel = 0,
        BackgroundColor3 = S.LabelBackground,
        Size = UDim2.new(1, 0, 0, 30),
    }, self.Frame)
    stroke(frame, S.LabelBorder, 1)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.LabelText,
        FontFace = BODY_FONT,
        Size = UDim2.new(1, -20, 1, 0),
    }, frame)
    create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, title)

    return frame
end

function Tab:AddInfo(opts)
    local S = self.Library.Scheme

    local frame = create("Frame", {
        Name = "Info",
        BorderSizePixel = 0,
        BackgroundColor3 = S.InfoBackground,
        Size = UDim2.new(1, 0, 0, 30),
    }, self.Frame)
    stroke(frame, S.InfoBorder, 1)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Info",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.InfoText,
        FontFace = BODY_FONT,
        Size = UDim2.new(1, -20, 1, 0),
    }, frame)
    create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, title)

    return frame
end

function Tab:AddWarning(opts)
    local S = self.Library.Scheme

    local frame = create("Frame", {
        Name = "Warning",
        BorderSizePixel = 0,
        BackgroundColor3 = S.WarningBackground,
        Size = UDim2.new(1, 0, 0, 30),
    }, self.Frame)
    stroke(frame, S.WarningBorder, 1)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Warning",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.WarningText,
        FontFace = BODY_FONT,
        Size = UDim2.new(1, -20, 1, 0),
    }, frame)
    create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, title)

    return frame
end

function Tab:AddSlider(opts)
    local S = self.Library.Scheme
    local min = opts.Min or 0
    local max = opts.Max or 100
    local value = opts.Default or min

    local frame = create("Frame", {
        Name = "Slider",
        BorderSizePixel = 0,
        BackgroundColor3 = S.Element,
        Size = UDim2.new(1, 0, 0, 40),
    }, self.Frame)
    stroke(frame, S.Border, 1)

    local valueLabel = create("TextLabel", {
        Name = "Value",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = tostring(value),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = S.Text,
        FontFace = BODY_FONT,
        Size = UDim2.new(0.2, -8, 0, 14),
        Position = UDim2.new(0.8, 0, 0, 2),
        ZIndex = 3,
    }, frame)

    local back = create("Frame", {
        Name = "SliderBack",
        BorderSizePixel = 0,
        BackgroundColor3 = S.SliderBackground,
        Size = UDim2.new(1, -16, 0, 13),
        Position = UDim2.new(0, 8, 0, 22),
        ZIndex = 1,
    }, frame)

    local fill = create("Frame", {
        Name = "Draggable",
        BorderSizePixel = 0,
        BackgroundColor3 = S.SliderFill,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 2,
    }, back)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Slider",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        FontFace = BODY_FONT,
        Size = UDim2.new(1, 0, 0, 13),
        Position = UDim2.new(0, 0, 0, 22),
        ZIndex = 3,
    }, frame)

    local dragging = false

    local function update(input)
        local pos = math.clamp((input.Position.X - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos + 0.5)
        value = val
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(val)
        if opts.Callback then opts.Callback(val) end
    end

    back.InputBegan:Connect(function(input)
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

    local initPos = (value - min) / (max - min)
    fill.Size = UDim2.new(initPos, 0, 1, 0)

    return frame
end

function Tab:AddDropdown(opts)
    local S = self.Library.Scheme
    local values = opts.Values or {}
    local selected = opts.Default or values[1]

    local frame = create("Frame", {
        Name = "Dropdown",
        BorderSizePixel = 0,
        BackgroundColor3 = S.DropdownBackground,
        Size = UDim2.new(1, 0, 0, 30),
    }, self.Frame)
    stroke(frame, S.DropdownBorder, 1)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Dropdown",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.DropdownText,
        FontFace = BODY_FONT,
        Size = UDim2.new(0.5, -8, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
    }, frame)

    local valueLabel = create("TextLabel", {
        Name = "Value",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = tostring(selected),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = S.DropdownText,
        FontFace = BODY_FONT,
        Size = UDim2.new(0.4, -8, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
    }, frame)

    local list = create("ScrollingFrame", {
        Name = "List",
        BorderSizePixel = 0,
        BackgroundColor3 = S.DropdownBackground,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = S.DropdownBorder,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 100,
    }, self.Library.Main)
    stroke(list, S.DropdownBorder, 1)
    create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)

    local open = false
    local connection = nil
    local entry = nil

    local function positionList()
        local main = self.Library.Main
        if not main or not main.Parent then return end
        local pos = frame.AbsolutePosition
        local mainPos = main.AbsolutePosition
        local height = math.min(#values * 22 + 8, 150)

        list.Position = UDim2.fromOffset(
            pos.X - mainPos.X,
            pos.Y - mainPos.Y + frame.AbsoluteSize.Y + 2
        )
        list.Size = UDim2.new(0, frame.AbsoluteSize.X, 0, height)
    end

    local function openList()
        open = true
        list.Visible = true
        positionList()

        if connection then connection:Disconnect() end
        connection = runService.Heartbeat:Connect(function()
            if not open then return end
            if not frame.Parent or not list.Parent or not self.Library.Main.Parent then
                open = false
                list.Visible = false
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                return
            end
            positionList()
        end)
    end

    local function closeList()
        open = false
        list.Visible = false
        if connection then
            connection:Disconnect()
            connection = nil
        end
        local idx = table.find(self.Library.OpenDropdowns, entry)
        if idx then
            table.remove(self.Library.OpenDropdowns, idx)
        end
    end

    entry = {
        Frame = frame,
        List = list,
        Close = closeList,
    }

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if open then
                closeList()
            else
                openList()
                if not table.find(self.Library.OpenDropdowns, entry) then
                    table.insert(self.Library.OpenDropdowns, entry)
                end
            end
        end
    end)

    for _, val in ipairs(values) do
        local item = create("TextButton", {
            Name = "Item",
            BorderSizePixel = 0,
            BackgroundColor3 = S.DropdownItemIdle,
            Text = tostring(val),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = S.DropdownItemText,
            FontFace = BODY_FONT,
            Size = UDim2.new(1, 0, 0, 20),
            AutoButtonColor = false,
        }, list)
        create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, item)

        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = S.ElementHover
        end)
        item.MouseLeave:Connect(function()
            item.BackgroundColor3 = S.DropdownItemIdle
        end)
        item.MouseButton1Click:Connect(function()
            selected = val
            valueLabel.Text = tostring(val)
            if opts.Callback then opts.Callback(val) end
            closeList()
        end)
    end

    frame.Destroying:Connect(function()
        if connection then connection:Disconnect() end
        local idx = table.find(self.Library.OpenDropdowns, entry)
        if idx then table.remove(self.Library.OpenDropdowns, idx) end
        if list then list:Destroy() end
    end)

    return frame
end

function Tab:AddToggle(opts)
    local S = self.Library.Scheme
    local state = opts.Default or false

    local frame = create("TextButton", {
        Name = "Toggle",
        BorderSizePixel = 0,
        BackgroundColor3 = S.ToggleBackground,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 40),
    }, self.Frame)
    stroke(frame, S.ToggleBorder, 1)

    local title = create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = opts.Text or "Toggle",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = S.ToggleText,
        FontFace = BODY_FONT,
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
    local boxStroke = stroke(box, state and S.ToggleBoxOnBorder or S.ToggleBoxOffBorder, 1)

    frame.MouseButton1Click:Connect(function()
        state = not state
        box.BackgroundColor3 = state and S.ToggleBoxOn or S.ToggleBoxOff
        boxStroke.Color = state and S.ToggleBoxOnBorder or S.ToggleBoxOffBorder
        if opts.Callback then opts.Callback(state) end
    end)

    return frame
end

Library.Tab = Tab

return Library
