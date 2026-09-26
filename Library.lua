local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer

local Library = {}
Library.__index = Library

Library.Scheme = {
    Background = Color3.fromRGB(21, 19, 31),
    TopBar = Color3.fromRGB(11, 11, 11),
    TopBarExt = Color3.fromRGB(26, 26, 26),
    Content = Color3.fromRGB(27, 23, 41),
    Element = Color3.fromRGB(37, 33, 53),
    ElementHover = Color3.fromRGB(45, 40, 65),
    Accent = Color3.fromRGB(156, 90, 255),
    Outline = Color3.fromRGB(61, 55, 89),
    OutlineDim = Color3.fromRGB(51, 45, 75),
    Text = Color3.fromRGB(241, 241, 251),
    TextDim = Color3.fromRGB(161, 161, 181),
    SliderBack = Color3.fromRGB(29, 25, 43),
    DropdownItem = Color3.fromRGB(23, 21, 33),
    InfoBg = Color3.fromRGB(21, 27, 41),
    InfoBorder = Color3.fromRGB(51, 91, 141),
    InfoText = Color3.fromRGB(91, 171, 255),
    WarningBg = Color3.fromRGB(37, 21, 27),
    WarningBorder = Color3.fromRGB(121, 41, 51),
    WarningText = Color3.fromRGB(255, 81, 81),
}

local FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
local TitleFont = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Regular)

Library.IsOpen = true
Library.Options = {}
Library.Toggles = {}
Library.Tabs = {}
Library.NotifySide = "Right"

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Legacy"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

do
    local parent
    if gethui then
        parent = gethui()
    else
        if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
        parent = game:GetService("CoreGui")
    end
    ScreenGui.Parent = parent
end

local function Create(Class, Props)
    local Inst = Instance.new(Class)
    for K, V in pairs(Props) do
        if K ~= "Parent" then Inst[K] = V end
    end
    if Props.Parent then Inst.Parent = Props.Parent end
    return Inst
end

local function Corner(Inst, Radius)
    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, Radius or 6)
    C.Parent = Inst
    return C
end

local function Stroke(Inst, Color, Thickness)
    local S = Instance.new("UIStroke")
    S.Color = Color or Library.Scheme.Outline
    S.Thickness = Thickness or 1
    S.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    S.Parent = Inst
    return S
end

local function Pad(Inst, List)
    local P = Instance.new("UIPadding")
    for _, Entry in ipairs(List) do
        P[Entry[1]] = Entry[2]
    end
    P.Parent = Inst
    return P
end

local NotifyHolder
local NotifyLayout
local function EnsureNotifyHolder()
    if NotifyHolder then return end
    NotifyHolder = Create("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -330, 0, 10),
        Parent = ScreenGui,
    })
    NotifyLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = NotifyHolder,
    })
end

function Library:Notify(Data)
    if type(Data) == "string" then Data = { Title = "Notification", Body = Data } end
    Data = Data or {}
    local Title = Data.Title or "Notification"
    local Body = Data.Body or Data.Description or ""
    local Time = Data.Time or 4
    EnsureNotifyHolder()

    local Frame = Create("Frame", {
        BackgroundColor3 = Library.Scheme.Background,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        Parent = NotifyHolder,
    })
    Corner(Frame, 6)
    Stroke(Frame, Library.Scheme.Outline, 1)

    local Accent = Create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Library.Scheme.Accent,
        BorderSizePixel = 0,
        Parent = Frame,
    })
    Corner(Accent, 2)

    Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundTransparency = 1,
        Text = Body,
        TextColor3 = Library.Scheme.TextDim,
        FontFace = FontFace,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    Frame.Position = UDim2.new(1, 30, 0, 0)
    TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = UDim2.new(0, 0, 0, 0) }):Play()

    task.delay(Time, function()
        if not Frame.Parent then return end
        local Out = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = UDim2.new(1, 30, 0, 0) })
        Out:Play()
        Out.Completed:Wait()
        Frame:Destroy()
    end)
end

local WidgetIdCounter = 0
local function NextId()
    WidgetIdCounter = WidgetIdCounter + 1
    return WidgetIdCounter
end

local function RegisterOption(Id, Entry)
    Library.Options[Id] = Entry
    if Entry.Type == "Toggle" or Entry.Type == "KeyPicker" or Entry.Type == "Dropdown" or Entry.Type == "ColorPicker" then
        Library.Toggles[Id] = Entry
    end
end

local CreateToggle, CreateSlider, CreateDropdown, CreateButton
local CreateLabel, CreateInfo, CreateWarning, CreateColorPicker
local CreateKeyPicker, CreateInput

local function CreateGroupBox(Tab, Name, Side)
    if Tab.__GB[Side] then
        if Name then Tab.__GB[Side].Header.Text = Name end
        return Tab.__GB[Side]
    end

    local IsLeft = (Side == "left")
    local GBFrame = Create("Frame", {
        Name = IsLeft and "GbLeft" or "GbRight",
        BackgroundColor3 = Library.Scheme.Content,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, -8, 1, -8),
        Position = IsLeft and UDim2.new(0, 4, 0, 4) or UDim2.new(0.5, 4, 0, 4),
        Parent = Tab.Frame,
    })

    local Header = Create("TextLabel", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Library.Scheme.TopBar,
        BorderSizePixel = 0,
        Text = Name or "",
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = GBFrame,
    })
    Pad(Header, { { "PaddingLeft", UDim.new(0, 10) } })

    local Scroll = Create("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, 0, 1, -24),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = Library.Scheme.Content,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Library.Scheme.Outline,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = GBFrame,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Scroll,
    })
    Pad(Scroll, {
        { "PaddingLeft", UDim.new(0, 6) },
        { "PaddingRight", UDim.new(0, 6) },
        { "PaddingTop", UDim.new(0, 6) },
        { "PaddingBottom", UDim.new(0, 6) },
    })

    local GB = {
        Frame = GBFrame,
        Header = Header,
        Scroll = Scroll,
        Tab = Tab,
        Section = Tab.Name .. "/" .. Side,
        Widgets = {},
    }

    Tab.__GB[Side] = GB

    GB.AddToggle = function(self, Options) return CreateToggle(self, Options) end
    GB.AddSlider = function(self, Options) return CreateSlider(self, Options) end
    GB.AddDropdown = function(self, Options) return CreateDropdown(self, Options) end
    GB.AddButton = function(self, Options) return CreateButton(self, Options) end
    GB.AddLabel = function(self, Options) return CreateLabel(self, Options) end
    GB.AddInfo = function(self, Options) return CreateInfo(self, Options) end
    GB.AddWarning = function(self, Options) return CreateWarning(self, Options) end
    GB.AddColorPicker = function(self, Options) return CreateColorPicker(self, Options) end
    GB.AddKeyPicker = function(self, Options) return CreateKeyPicker(self, Options) end
    GB.AddInput = function(self, Options) return CreateInput(self, Options) end

    return GB
end

function Library:new(Config)
    Config = Config or {}
    if Config.scheme then
        for K, V in pairs(Config.scheme) do
            Library.Scheme[K] = V
        end
    end

    local Self = setmetatable({}, Library)
    Self.Tabs = {}
    Self.ActiveTab = nil
    Self.__GB = {}

    local Title = Config.title or Config.name or "UI Library"
    local Size = Config.size or UDim2.new(0, 536, 0, 582)
    local Keybind = Config.keybind or Enum.KeyCode.RightShift

    local Main = Create("Frame", {
        Name = "Main",
        BorderSizePixel = 0,
        BackgroundColor3 = Library.Scheme.Background,
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        Parent = ScreenGui,
    })
    Stroke(Main, Library.Scheme.Outline, 2)

    local TopBar = Create("Frame", {
        Name = "TopBar",
        BorderSizePixel = 0,
        BackgroundColor3 = Library.Scheme.TopBar,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = Main,
    })
    Stroke(TopBar, Library.Scheme.Outline, 2)

    Create("Frame", {
        Name = "Extension",
        BorderSizePixel = 0,
        BackgroundColor3 = Library.Scheme.TopBarExt,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 1, 0),
        Parent = TopBar,
    })

    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        BorderSizePixel = 0,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        FontFace = TitleFont,
        TextColor3 = Library.Scheme.Accent,
        Size = UDim2.new(0.7, 0, 1, 0),
        Text = Title,
        Parent = TopBar,
    })
    Pad(TitleLabel, { { "PaddingLeft", UDim.new(0, 10) } })

    local ExitBtn = Create("ImageButton", {
        Name = "ExitBtn",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Image = "rbxassetid://132261474823036",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -30, 0, 0),
        Parent = TopBar,
    })

    local Navigation = Create("Frame", {
        Name = "Navigation",
        BorderSizePixel = 0,
        BackgroundColor3 = Library.Scheme.Content,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 30),
        Parent = Main,
    })
    Stroke(Navigation, Library.Scheme.Outline, 1)

    local ButtonHolder = Create("ScrollingFrame", {
        Name = "ButtonHolder",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 1, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Scheme.Accent,
        ScrollBarImageTransparency = 0.3,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        Parent = Navigation,
    })
    local NavLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = ButtonHolder,
    })
    Pad(ButtonHolder, {
        { "PaddingLeft", UDim.new(0, 4) },
        { "PaddingRight", UDim.new(0, 4) },
        { "PaddingTop", UDim.new(0, 4) },
        { "PaddingBottom", UDim.new(0, 4) },
    })

    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        BorderSizePixel = 0,
        BackgroundColor3 = Library.Scheme.Content,
        Size = UDim2.new(1, -12, 1, -78),
        Position = UDim2.new(0, 6, 0, 66),
        Parent = Main,
    })
    Stroke(ContentContainer, Library.Scheme.Outline, 1)

    local Dragging = false
    local DragStart, StartPos

    TopBar.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(Input)
        if not Dragging then return end
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            local Delta = Input.Position - DragStart
            Main.Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)

    UserInputService.InputBegan:Connect(function(Input, GPE)
        if GPE then return end
        if Input.KeyCode == Keybind then
            Main.Visible = not Main.Visible
            Library.IsOpen = Main.Visible
        end
    end)

    ExitBtn.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible
        Library.IsOpen = Main.Visible
    end)

    Self.Main = Main
    Self.ContentContainer = ContentContainer
    Self.Navigation = Navigation
    Self.ButtonHolder = ButtonHolder
    Self.NavLayout = NavLayout
    Self.Keybind = Keybind

    function Self:SelectTab(Tab)
        if Self.ActiveTab == Tab then return end
        Self.ActiveTab = Tab
        for _, T in ipairs(Self.Tabs) do
            T.Frame.Visible = (T == Tab)
            local IsActive = (T == Tab)
            TweenService:Create(T.Button, TweenInfo.new(0.18), {
                BackgroundColor3 = IsActive and Library.Scheme.Element or Library.Scheme.Content,
                TextColor3 = IsActive and Library.Scheme.Accent or Library.Scheme.TextDim,
            }):Play()
        end
    end

    function Self:Toggle()
        Main.Visible = not Main.Visible
        Library.IsOpen = Main.Visible
    end

    function Self:Destroy()
        Main:Destroy()
        ScreenGui:Destroy()
    end

    function Self:CreateTab(Name)
        local TabBtn = Create("TextButton", {
            Name = "Tab_" .. Name,
            BorderSizePixel = 0,
            TextSize = 14,
            BackgroundColor3 = Library.Scheme.Content,
            FontFace = FontFace,
            TextColor3 = Library.Scheme.TextDim,
            Size = UDim2.new(0, 100, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            AutoButtonColor = false,
            Text = Name,
            Parent = ButtonHolder,
        })
        Corner(TabBtn, 4)
        Stroke(TabBtn, Library.Scheme.Outline, 1)
        Pad(TabBtn, {
            { "PaddingLeft", UDim.new(0, 12) },
            { "PaddingRight", UDim.new(0, 12) },
        })

        local TabFrame = Create("ScrollingFrame", {
            Name = Name .. "Tab",
            BorderSizePixel = 0,
            BackgroundColor3 = Library.Scheme.Content,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 5,
            ScrollBarImageColor3 = Library.Scheme.Outline,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            Parent = ContentContainer,
        })

        local Tab = {
            Name = Name,
            Button = TabBtn,
            Frame = TabFrame,
            Library = Self,
            __GB = {},
            Widgets = {},
        }

        TabBtn.MouseEnter:Connect(function()
            if Self.ActiveTab ~= Tab then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), { BackgroundColor3 = Library.Scheme.Element }):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Self.ActiveTab ~= Tab then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), { BackgroundColor3 = Library.Scheme.Content }):Play()
            end
        end)
        TabBtn.MouseButton1Click:Connect(function()
            Self:SelectTab(Tab)
        end)

        Tab.AddLeftGB = function(_, GBName) return CreateGroupBox(Tab, GBName, "left") end
        Tab.AddRightGB = function(_, GBName) return CreateGroupBox(Tab, GBName, "right") end

        table.insert(Self.Tabs, Tab)
        if not Self.ActiveTab then Self:SelectTab(Tab) end

        return Tab
    end

    Self.Library = Library

    return Self
end

CreateToggle = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or "Toggle"
    local Default = Options.Default or false
    local Callback = Options.Callback
    local Id = Options.Id or ("Toggle_" .. NextId())

    local Frame = Create("Frame", {
        Name = "Toggle",
        BackgroundColor3 = Library.Scheme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.Outline, 1)
    Corner(Frame, 4)

    Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local CheckHolder = Create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0.5, -10),
        BackgroundColor3 = Default and Library.Scheme.Accent or Library.Scheme.SliderBack,
        BorderSizePixel = 0,
        Parent = Frame,
    })
    Stroke(CheckHolder, Default and Library.Scheme.Accent or Library.Scheme.Outline, 1)
    Corner(CheckHolder, 3)

    local State = Default
    local Entry
    Entry = {
        Id = Id,
        Type = "Toggle",
        Value = State,
        Frame = Frame,
        SetValue = function(_, V)
            State = V and true or false
            CheckHolder.BackgroundColor3 = State and Library.Scheme.Accent or Library.Scheme.SliderBack
            CheckHolder.UIStroke.Color = State and Library.Scheme.Accent or Library.Scheme.Outline
            Entry.Value = State
            if Callback then task.spawn(Callback, State) end
        end,
    }

    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Entry.SetValue(Entry, not State)
        end
    end)

    Frame.MouseEnter:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundColor3 = Library.Scheme.ElementHover }):Play()
    end)
    Frame.MouseLeave:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundColor3 = Library.Scheme.Element }):Play()
    end)

    RegisterOption(Id, Entry)
    table.insert(GB.Widgets, Entry)
    table.insert(GB.Tab.Widgets, Entry)

    return {
        Set = function(_, V) Entry.SetValue(Entry, V) end,
        Get = function() return State end,
    }
end

CreateSlider = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or "Slider"
    local Min = Options.Min or 0
    local Max = Options.Max or 100
    local Default = Options.Default or Min
    local Rounding = Options.Rounding or 0
    local Callback = Options.Callback
    local Id = Options.Id or ("Slider_" .. NextId())

    local Frame = Create("Frame", {
        Name = "Slider",
        BackgroundColor3 = Library.Scheme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.Outline, 1)
    Corner(Frame, 4)

    Create("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local ValueLbl = Create("TextLabel", {
        Size = UDim2.new(0.3, -12, 0, 20),
        Position = UDim2.new(0.7, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(Default),
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Frame,
    })

    local Track = Create("Frame", {
        Size = UDim2.new(1, -24, 0, 10),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundColor3 = Library.Scheme.SliderBack,
        BorderSizePixel = 0,
        Parent = Frame,
    })
    Corner(Track, 3)

    local Fill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Scheme.Accent,
        BorderSizePixel = 0,
        Parent = Track,
    })
    Corner(Fill, 3)

    local Value = Default
    local Entry
    local function Apply()
        local Alpha = (Max > Min) and ((Value - Min) / (Max - Min)) or 0
        Alpha = math.clamp(Alpha, 0, 1)
        Fill.Size = UDim2.new(Alpha, 0, 1, 0)
        ValueLbl.Text = tostring(Value)
    end
    Apply()

    Entry = {
        Id = Id,
        Type = "Slider",
        Value = Value,
        Min = Min,
        Max = Max,
        Rounding = Rounding,
        Frame = Frame,
        SetValue = function(_, V)
            V = tonumber(V) or Value
            V = math.clamp(V, Min, Max)
            if Rounding > 0 then
                local Mult = 10 ^ Rounding
                V = math.floor(V * Mult + 0.5) / Mult
            else
                V = math.floor(V + 0.5)
            end
            Value = V
            Entry.Value = V
            Apply()
            if Callback then task.spawn(Callback, V) end
        end,
    }

    local Dragging = false
    local function UpdateFromInput(Input)
        local TrackAbs = Track.AbsolutePosition
        local TrackSize = Track.AbsoluteSize
        local Alpha = math.clamp((Input.Position.X - TrackAbs.X) / math.max(TrackSize.X, 1), 0, 1)
        local NewVal = Min + (Max - Min) * Alpha
        Entry.SetValue(Entry, NewVal)
    end

    Track.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            UpdateFromInput(Input)
        end
    end)
    Fill.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            UpdateFromInput(Input)
        end
    end)
    UserInputService.InputChanged:Connect(function(Input)
        if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromInput(Input)
        end
    end)
    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)

    RegisterOption(Id, Entry)
    table.insert(GB.Widgets, Entry)
    table.insert(GB.Tab.Widgets, Entry)

    return {
        Set = function(_, V) Entry.SetValue(Entry, V) end,
        Get = function() return Value end,
    }
end

CreateDropdown = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or "Dropdown"
    local Values = Options.Values or {}
    local Default = Options.Default or Values[1] or ""
    local Callback = Options.Callback
    local Multi = Options.Multi
    local Id = Options.Id or ("Dropdown_" .. NextId())

    local Frame = Create("Frame", {
        Name = "Dropdown",
        BackgroundColor3 = Library.Scheme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        ClipsDescendants = false,
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.Outline, 1)
    Corner(Frame, 4)

    local TitleLbl = Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = Text .. ": " .. tostring(Default),
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local Arrow = Create("TextLabel", {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -28, 0, 0),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = Library.Scheme.TextDim,
        FontFace = FontFace,
        TextSize = 14,
        Parent = Frame,
    })

    local Selected = Default
    local Entry
    local function UpdateLabel()
        if Multi and type(Selected) == "table" then
            local Keys = {}
            for K, V in pairs(Selected) do
                if V then table.insert(Keys, K) end
            end
            if #Keys == 0 then
                TitleLbl.Text = Text .. ": none"
            else
                TitleLbl.Text = Text .. ": " .. table.concat(Keys, ", ")
            end
        else
            TitleLbl.Text = Text .. ": " .. tostring(Selected)
        end
    end

    Entry = {
        Id = Id,
        Type = "Dropdown",
        Value = Selected,
        Values = Values,
        Multi = Multi,
        Frame = Frame,
        SetValue = function(_, V)
            Selected = V
            Entry.Value = V
            UpdateLabel()
            if Callback then task.spawn(Callback, V) end
        end,
    }

    local ListOpen = false
    local ListFrame

    local function CloseList()
        if ListFrame then
            ListFrame:Destroy()
            ListFrame = nil
        end
        ListOpen = false
        TweenService:Create(Arrow, TweenInfo.new(0.15), { Rotation = 0 }):Play()
    end

    local function OpenList()
        ListFrame = Create("ScrollingFrame", {
            Name = "OptionHolder",
            BackgroundColor3 = Library.Scheme.TopBar,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, math.min(#Values * 20 + 8, 150)),
            Position = UDim2.new(0, 0, 1, 4),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Library.Scheme.Outline,
            ZIndex = 10,
            Parent = Frame,
        })
        Stroke(ListFrame, Library.Scheme.Outline, 1)
        Corner(ListFrame, 4)
        Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ListFrame,
        })
        Pad(ListFrame, {
            { "PaddingTop", UDim.new(0, 4) },
            { "PaddingBottom", UDim.new(0, 4) },
            { "PaddingLeft", UDim.new(0, 4) },
            { "PaddingRight", UDim.new(0, 4) },
        })

        for _, Value in ipairs(Values) do
            local IsActive = (not Multi and Value == Selected) or (Multi and type(Selected) == "table" and Selected[Value])
            local Item = Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = IsActive and Library.Scheme.Accent or Library.Scheme.DropdownItem,
                BorderSizePixel = 0,
                Text = "  " .. tostring(Value),
                TextColor3 = Library.Scheme.Text,
                FontFace = FontFace,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = ListFrame,
            })
            Corner(Item, 3)
            Item.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                if Multi then
                    if type(Selected) ~= "table" then Selected = {} end
                    Selected[Value] = not Selected[Value]
                    if not Selected[Value] then Selected[Value] = nil end
                    Entry.Value = Selected
                    UpdateLabel()
                    Item.BackgroundColor3 = Selected[Value] and Library.Scheme.Accent or Library.Scheme.DropdownItem
                    if Callback then task.spawn(Callback, Selected) end
                else
                    Selected = Value
                    Entry.Value = Value
                    UpdateLabel()
                    if Callback then task.spawn(Callback, Value) end
                    CloseList()
                end
            end)
            Item.MouseEnter:Connect(function()
                local active = (not Multi and Value == Selected) or (Multi and type(Selected) == "table" and Selected[Value])
                if not active then
                    Item.BackgroundColor3 = Library.Scheme.ElementHover
                end
            end)
            Item.MouseLeave:Connect(function()
                local active = (not Multi and Value == Selected) or (Multi and type(Selected) == "table" and Selected[Value])
                Item.BackgroundColor3 = active and Library.Scheme.Accent or Library.Scheme.DropdownItem
            end)
        end
        ListOpen = true
        TweenService:Create(Arrow, TweenInfo.new(0.15), { Rotation = 180 }):Play()
    end

    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        if ListOpen then CloseList() else OpenList() end
    end)

    RegisterOption(Id, Entry)
    table.insert(GB.Widgets, Entry)
    table.insert(GB.Tab.Widgets, Entry)

    return {
        SetValue = function(_, V) Entry.SetValue(Entry, V) end,
        Get = function() return Selected end,
        SetValues = function(_, List)
            Values = List
            Entry.Values = List
        end,
    }
end

CreateButton = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or "Button"
    local Func = Options.Func or Options.Callback
    local Id = Options.Id or ("Button_" .. NextId())

    local Frame = Create("Frame", {
        Name = "Button",
        BackgroundColor3 = Library.Scheme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.Outline, 1)
    Corner(Frame, 4)

    Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        Parent = Frame,
    })

    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Frame.BackgroundColor3 = Library.Scheme.Accent
            if Func then task.spawn(Func) end
            task.delay(0.15, function()
                if Frame.Parent then
                    TweenService:Create(Frame, TweenInfo.new(0.2), { BackgroundColor3 = Library.Scheme.Element }):Play()
                end
            end)
        end
    end)
    Frame.MouseEnter:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundColor3 = Library.Scheme.ElementHover }):Play()
    end)
    Frame.MouseLeave:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundColor3 = Library.Scheme.Element }):Play()
    end)

    local Entry = { Id = Id, Type = "Button", Frame = Frame }
    RegisterOption(Id, Entry)
    table.insert(GB.Widgets, Entry)
    table.insert(GB.Tab.Widgets, Entry)

    return {}
end

CreateLabel = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or ""
    local Frame = Create("Frame", {
        Name = "Label",
        BackgroundColor3 = Library.Scheme.Content,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.OutlineDim, 1)
    Corner(Frame, 4)
    Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })
    return {}
end

CreateInfo = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or ""
    local Frame = Create("Frame", {
        Name = "Info",
        BackgroundColor3 = Library.Scheme.InfoBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.InfoBorder, 1)
    Corner(Frame, 4)
    Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.InfoText,
        FontFace = FontFace,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })
    return {}
end

CreateWarning = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or ""
    local Frame = Create("Frame", {
        Name = "Warning",
        BackgroundColor3 = Library.Scheme.WarningBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.WarningBorder, 1)
    Corner(Frame, 4)
    Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.WarningText,
        FontFace = FontFace,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })
    return {}
end

CreateColorPicker = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or Options.Title or "Color"
    local Default = Options.Default or Color3.new(1, 1, 1)
    local Callback = Options.Callback
    local Id = Options.Id or ("Color_" .. NextId())

    local Frame = Create("Frame", {
        Name = "ColorPicker",
        BackgroundColor3 = Library.Scheme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.Outline, 1)
    Corner(Frame, 4)

    Create("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local Swatch = Create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -32, 0.5, -10),
        BackgroundColor3 = Default,
        BorderSizePixel = 0,
        Parent = Frame,
    })
    Stroke(Swatch, Library.Scheme.Outline, 1)
    Corner(Swatch, 3)

    local Presets = {
        Color3.fromRGB(255, 81, 81),
        Color3.fromRGB(255, 170, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(80, 255, 80),
        Color3.fromRGB(0, 200, 255),
        Color3.fromRGB(156, 90, 255),
        Color3.fromRGB(255, 100, 200),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(0, 0, 0),
    }

    local Entry
    Entry = {
        Id = Id,
        Type = "ColorPicker",
        Value = Default,
        Frame = Frame,
        SetValue = function(_, C)
            Entry.Value = C
            Swatch.BackgroundColor3 = C
            if Callback then task.spawn(Callback, C) end
        end,
    }

    local ListOpen = false
    local ListFrame
    local function CloseList()
        if ListFrame then ListFrame:Destroy() ListFrame = nil end
        ListOpen = false
    end
    local function OpenList()
        ListFrame = Create("Frame", {
            BackgroundColor3 = Library.Scheme.TopBar,
            Size = UDim2.new(0, 160, 0, 60),
            Position = UDim2.new(1, -160, 1, 4),
            ZIndex = 10,
            Parent = Frame,
        })
        Stroke(ListFrame, Library.Scheme.Outline, 1)
        Corner(ListFrame, 4)
        Create("UIGridLayout", {
            CellSize = UDim2.new(0, 24, 0, 24),
            CellPadding = UDim2.new(0, 4, 0, 4),
            Parent = ListFrame,
        })
        Pad(ListFrame, {
            { "PaddingTop", UDim.new(0, 4) },
            { "PaddingLeft", UDim.new(0, 4) },
            { "PaddingRight", UDim.new(0, 4) },
            { "PaddingBottom", UDim.new(0, 4) },
        })
        for _, C in ipairs(Presets) do
            local Btn = Create("Frame", {
                BackgroundColor3 = C,
                BorderSizePixel = 0,
                ZIndex = 11,
                Parent = ListFrame,
            })
            Stroke(Btn, Library.Scheme.Outline, 1)
            Corner(Btn, 3)
            Btn.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                Entry.SetValue(Entry, C)
                CloseList()
            end)
        end
        ListOpen = true
    end

    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        if ListOpen then CloseList() else OpenList() end
    end)

    RegisterOption(Id, Entry)
    table.insert(GB.Widgets, Entry)
    table.insert(GB.Tab.Widgets, Entry)

    return {
        SetValue = function(_, C) Entry.SetValue(Entry, C) end,
        Get = function() return Entry.Value end,
    }
end

CreateKeyPicker = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or "Key"
    local Default = Options.Default or "None"
    local Callback = Options.Callback
    local Id = Options.Id or ("Key_" .. NextId())

    local Frame = Create("Frame", {
        Name = "KeyPicker",
        BackgroundColor3 = Library.Scheme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.Outline, 1)
    Corner(Frame, 4)

    Create("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local Value = Default
    local KeyLbl = Create("TextLabel", {
        Size = UDim2.new(0, 60, 0, 22),
        Position = UDim2.new(1, -68, 0.5, -11),
        BackgroundColor3 = Library.Scheme.SliderBack,
        BorderSizePixel = 0,
        Text = tostring(Default),
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 13,
        Parent = Frame,
    })
    Stroke(KeyLbl, Library.Scheme.Outline, 1)
    Corner(KeyLbl, 3)

    local Listening = false
    local Entry
    Entry = {
        Id = Id,
        Type = "KeyPicker",
        Value = Value,
        Mode = "Toggle",
        Frame = Frame,
        SetValue = function(_, V)
            Value = V
            Entry.Value = V
            KeyLbl.Text = tostring(V)
            if Callback then task.spawn(Callback, V) end
        end,
        GetState = function()
            if Value == "None" then return false end
            return UserInputService:IsKeyDown(Enum.KeyCode[Value])
        end,
    }

    KeyLbl.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        Listening = true
        KeyLbl.Text = "..."
        KeyLbl.BackgroundColor3 = Library.Scheme.Accent
    end)

    UserInputService.InputBegan:Connect(function(Input, GPE)
        if not Listening then return end
        if Input.UserInputType == Enum.UserInputType.Keyboard then
            if Input.KeyCode == Enum.KeyCode.Escape then
                Value = "None"
            else
                Value = Input.KeyCode.Name
            end
            Entry.Value = Value
            KeyLbl.Text = tostring(Value)
            KeyLbl.BackgroundColor3 = Library.Scheme.SliderBack
            Listening = false
            if Callback then task.spawn(Callback, Value) end
        end
    end)

    RegisterOption(Id, Entry)
    table.insert(GB.Widgets, Entry)
    table.insert(GB.Tab.Widgets, Entry)

    return {
        SetValue = function(_, V) Entry.SetValue(Entry, V) end,
        GetState = Entry.GetState,
    }
end

CreateInput = function(GB, Options)
    Options = Options or {}
    local Text = Options.Text or "Input"
    local Default = Options.Default or ""
    local Placeholder = Options.Placeholder or "type..."
    local Callback = Options.Callback
    local Id = Options.Id or ("Input_" .. NextId())

    local Frame = Create("Frame", {
        Name = "Input",
        BackgroundColor3 = Library.Scheme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = GB.Scroll,
    })
    Stroke(Frame, Library.Scheme.Outline, 1)
    Corner(Frame, 4)

    Create("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Scheme.Text,
        FontFace = FontFace,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local Box = Create("TextBox", {
        Size = UDim2.new(0.55, -14, 0, 22),
        Position = UDim2.new(0.45, 0, 0.5, -11),
        BackgroundColor3 = Library.Scheme.SliderBack,
        BorderSizePixel = 0,
        Text = Default,
        PlaceholderText = Placeholder,
        TextColor3 = Library.Scheme.Text,
        PlaceholderColor3 = Library.Scheme.TextDim,
        FontFace = FontFace,
        TextSize = 13,
        ClearTextOnFocus = false,
        Parent = Frame,
    })
    Stroke(Box, Library.Scheme.Outline, 1)
    Corner(Box, 3)

    local Entry
    Entry = {
        Id = Id,
        Type = "Input",
        Value = Default,
        Frame = Frame,
        SetValue = function(_, V)
            Entry.Value = V
            Box.Text = tostring(V)
            if Callback then task.spawn(Callback, V) end
        end,
    }

    Box.FocusLost:Connect(function()
        Entry.Value = Box.Text
        if Callback then task.spawn(Callback, Box.Text) end
    end)

    RegisterOption(Id, Entry)
    table.insert(GB.Widgets, Entry)
    table.insert(GB.Tab.Widgets, Entry)

    return {
        SetValue = function(_, V) Entry.SetValue(Entry, V) end,
        Get = function() return Entry.Value end,
    }
end

return Library
