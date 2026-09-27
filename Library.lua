local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local tw = game:GetService("TweenService")
local lp = plrs.LocalPlayer

local lib = {}
lib.__index = lib

lib.Scheme = {
    Background = Color3.fromRGB(21,19,31),
    TopBar = Color3.fromRGB(11,11,11),
    TopBarExt = Color3.fromRGB(26,26,26),
    Content = Color3.fromRGB(27,23,41),
    Element = Color3.fromRGB(37,33,53),
    ElementHover = Color3.fromRGB(45,40,65),
    Accent = Color3.fromRGB(156,90,255),
    Outline = Color3.fromRGB(61,55,89),
    OutlineDim = Color3.fromRGB(51,45,75),
    Text = Color3.fromRGB(241,241,251),
    TextDim = Color3.fromRGB(161,161,181),
    SliderBack = Color3.fromRGB(29,25,43),
    DropdownItem = Color3.fromRGB(23,21,33),
    InfoBg = Color3.fromRGB(21,27,41),
    InfoBorder = Color3.fromRGB(51,91,141),
    InfoText = Color3.fromRGB(91,171,255),
    WarningBg = Color3.fromRGB(37,21,27),
    WarningBorder = Color3.fromRGB(121,41,51),
    WarningText = Color3.fromRGB(255,81,81),
}

local font = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
local titleFont = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Regular)

lib.IsOpen = true
lib.Options = {}
lib.Toggles = {}
lib.Tabs = {}

local gui = Instance.new("ScreenGui")
gui.Name = "Legacy"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

if gethui then gui.Parent = gethui()
else
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = game:GetService("CoreGui")
end

-- overlay for dropdowns/colorpickers so they dont clip
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundTransparency = 1
overlay.Size = UDim2.new(1,0,1,0)
overlay.ZIndex = 500
overlay.Active = false
overlay.Parent = gui

local function mk(cls, props)
    local i = Instance.new(cls)
    for k,v in pairs(props) do
        if k ~= "Parent" then i[k] = v end
    end
    if props.Parent then i.Parent = props.Parent end
    return i
end

local function corner(x, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = x
    return c
end

local function stroke(x, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or lib.Scheme.Outline
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = x
    return s
end

local function pad(x, list)
    local p = Instance.new("UIPadding")
    for _,e in ipairs(list) do p[e[1]] = e[2] end
    p.Parent = x
    return p
end

local nh, nl
local function ensureNotify()
    if nh then return end
    nh = mk("Frame", {
        Name = "Notifications", BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20), Position = UDim2.new(1,-330,0,10),
        ZIndex = 1000, Parent = gui,
    })
    nl = mk("UIListLayout", {
        Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = nh,
    })
end

function lib:Notify(d)
    if type(d) == "string" then d = {Title="Notification", Body=d} end
    d = d or {}
    local title = d.Title or "Notification"
    local body = d.Body or d.Description or ""
    local tm = d.Time or 4
    ensureNotify()

    local f = mk("Frame", {
        BackgroundColor3 = lib.Scheme.Background, BackgroundTransparency = 0.15,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,52), ZIndex = 1001, Parent = nh,
    })
    corner(f, 6)
    stroke(f, lib.Scheme.Outline, 1)

    local acc = mk("Frame", {
        Size = UDim2.new(0,3,1,0), BackgroundColor3 = lib.Scheme.Accent,
        BorderSizePixel = 0, ZIndex = 1002, Parent = f,
    })
    corner(acc, 2)

    mk("TextLabel", {
        Size = UDim2.new(1,-24,0,20), Position = UDim2.new(0,12,0,6),
        BackgroundTransparency = 1, Text = title, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1002, Parent = f,
    })
    mk("TextLabel", {
        Size = UDim2.new(1,-24,0,18), Position = UDim2.new(0,12,0,26),
        BackgroundTransparency = 1, Text = body, TextColor3 = lib.Scheme.TextDim,
        FontFace = font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1002, Parent = f,
    })

    f.Position = UDim2.new(1,30,0,0)
    tw:Create(f, TweenInfo.new(0.28), {Position = UDim2.new(0,0,0,0)}):Play()
    task.delay(tm, function()
        if f.Parent then
            local t = tw:Create(f, TweenInfo.new(0.28), {Position = UDim2.new(1,30,0,0)})
            t:Play(); t.Completed:Wait(); f:Destroy()
        end
    end)
end

local wid = 0
local function nextId()
    wid = wid + 1
    return wid
end

local function reg(id, e)
    lib.Options[id] = e
    if e.Type == "Toggle" or e.Type == "KeyPicker" or e.Type == "Dropdown" or e.Type == "ColorPicker" then
        lib.Toggles[id] = e
    end
end

-- forward decl (из-за порядка)
local makeToggle, makeSlider, makeDropdown, makeButton
local makeLabel, makeInfo, makeWarn, makeColor
local makeKey, makeInput

local function mkGB(tab, name, side)
    if tab.__GB[side] then
        if name then tab.__GB[side].Header.Text = name end
        return tab.__GB[side]
    end

    local left = (side == "left")
    local fr = mk("Frame", {
        Name = left and "GbLeft" or "GbRight",
        BackgroundColor3 = lib.Scheme.Content, BorderSizePixel = 0,
        Size = UDim2.new(0.5,-8,1,-8),
        Position = left and UDim2.new(0,4,0,4) or UDim2.new(0.5,4,0,4),
        ZIndex = 2, Parent = tab.Frame,
    })

    local h = mk("TextLabel", {
        Name = "Header", Size = UDim2.new(1,0,0,24),
        BackgroundColor3 = lib.Scheme.TopBar, BorderSizePixel = 0,
        Text = name or "", TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = fr,
    })
    pad(h, {{"PaddingLeft", UDim.new(0,10)}})

    local sc = mk("ScrollingFrame", {
        Name = "Scroll", Size = UDim2.new(1,0,1,-24),
        Position = UDim2.new(0,0,0,24),
        BackgroundColor3 = lib.Scheme.Content, BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4, ScrollBarImageColor3 = lib.Scheme.Outline,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true, ZIndex = 3, Parent = fr,
    })
    mk("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sc})
    pad(sc, {
        {"PaddingLeft", UDim.new(0,6)}, {"PaddingRight", UDim.new(0,6)},
        {"PaddingTop", UDim.new(0,6)},  {"PaddingBottom", UDim.new(0,6)},
    })

    local g = {Frame=fr, Header=h, Scroll=sc, Tab=tab, Section=tab.Name.."/"..side, Widgets={}}
    tab.__GB[side] = g

    g.AddToggle = function(s,o) return makeToggle(s,o) end
    g.AddSlider = function(s,o) return makeSlider(s,o) end
    g.AddDropdown = function(s,o) return makeDropdown(s,o) end
    g.AddButton = function(s,o) return makeButton(s,o) end
    g.AddLabel = function(s,o) return makeLabel(s,o) end
    g.AddInfo = function(s,o) return makeInfo(s,o) end
    g.AddWarning = function(s,o) return makeWarn(s,o) end
    g.AddColorPicker = function(s,o) return makeColor(s,o) end
    g.AddKeyPicker = function(s,o) return makeKey(s,o) end
    g.AddInput = function(s,o) return makeInput(s,o) end

    return g
end

function lib:new(cfg)
    cfg = cfg or {}
    if cfg.scheme then
        for k,v in pairs(cfg.scheme) do lib.Scheme[k] = v end
    end

    local self = setmetatable({}, lib)
    self.Tabs = {}
    self.ActiveTab = nil
    self.__GB = {}

    local title = cfg.title or cfg.name or "UI"
    local size = cfg.size or UDim2.new(0,536,0,582)
    local key = cfg.keybind or Enum.KeyCode.RightShift

    local main = mk("Frame", {
        Name = "Main", BorderSizePixel = 0,
        BackgroundColor3 = lib.Scheme.Background, Size = size,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        ZIndex = 1, Parent = gui,
    })
    stroke(main, lib.Scheme.Outline, 2)

    local top = mk("Frame", {
        Name = "TopBar", BorderSizePixel = 0,
        BackgroundColor3 = lib.Scheme.TopBar, Size = UDim2.new(1,0,0,30),
        ZIndex = 2, Parent = main,
    })
    stroke(top, lib.Scheme.Outline, 2)

    mk("Frame", {
        Name = "Extension", BorderSizePixel = 0,
        BackgroundColor3 = lib.Scheme.TopBarExt,
        Size = UDim2.new(1,0,0.5,0), Position = UDim2.new(0,0,1,0),
        ZIndex = 3, Parent = top,
    })

    local tl = mk("TextLabel", {
        Name = "Title", BorderSizePixel = 0, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        FontFace = titleFont, TextColor3 = lib.Scheme.Accent,
        Size = UDim2.new(0.7,0,1,0), Text = title, ZIndex = 4, Parent = top,
    })
    pad(tl, {{"PaddingLeft", UDim.new(0,10)}})

    local exitBtn = mk("ImageButton", {
        Name = "ExitBtn", BorderSizePixel = 0, BackgroundTransparency = 1,
        AutoButtonColor = false, Image = "rbxassetid://132261474823036",
        Size = UDim2.new(0,30,0,30), Position = UDim2.new(1,-30,0,0),
        ZIndex = 4, Parent = top,
    })

    local nav = mk("Frame", {
        Name = "Navigation", BorderSizePixel = 0,
        BackgroundColor3 = lib.Scheme.Content, ClipsDescendants = true,
        Size = UDim2.new(1,0,0,32), Position = UDim2.new(0,0,0,30),
        ZIndex = 2, Parent = main,
    })
    stroke(nav, lib.Scheme.Outline, 1)

    local bh = mk("ScrollingFrame", {
        Name = "ButtonHolder", BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1,0,1,0),
        CanvasSize = UDim2.new(0,0,1,0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 2, ScrollBarImageColor3 = lib.Scheme.Accent,
        ScrollBarImageTransparency = 0.3,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ZIndex = 3, Parent = nav,
    })
    local nlay = mk("UIListLayout", {
        Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = bh,
    })
    pad(bh, {
        {"PaddingLeft", UDim.new(0,4)}, {"PaddingRight", UDim.new(0,4)},
        {"PaddingTop", UDim.new(0,4)}, {"PaddingBottom", UDim.new(0,4)},
    })

    local cc = mk("Frame", {
        Name = "ContentContainer", BorderSizePixel = 0,
        BackgroundColor3 = lib.Scheme.Content,
        Size = UDim2.new(1,-12,1,-78), Position = UDim2.new(0,6,0,66),
        ZIndex = 2, Parent = main,
    })
    stroke(cc, lib.Scheme.Outline, 1)

    local drag = false
    local ds, sp

    top.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = inp.Position; sp = main.Position
        end
    end)
    uis.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    uis.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)

    uis.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == key then
            main.Visible = not main.Visible
            lib.IsOpen = main.Visible
        end
    end)

    exitBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
        lib.IsOpen = main.Visible
    end)

    self.Main = main
    self.ContentContainer = cc
    self.Navigation = nav
    self.ButtonHolder = bh
    self.NavLayout = nlay
    self.Keybind = key

    function self:SelectTab(t)
        if self.ActiveTab == t then return end
        self.ActiveTab = t
        for _,x in ipairs(self.Tabs) do
            x.Frame.Visible = (x == t)
            local on = (x == t)
            tw:Create(x.Button, TweenInfo.new(0.18), {
                BackgroundColor3 = on and lib.Scheme.Element or lib.Scheme.Content,
                TextColor3 = on and lib.Scheme.Accent or lib.Scheme.TextDim,
            }):Play()
        end
    end

    function self:Toggle()
        main.Visible = not main.Visible
        lib.IsOpen = main.Visible
    end

    function self:Destroy()
        main:Destroy(); gui:Destroy()
    end

    function self:CreateTab(name)
        local btn = mk("TextButton", {
            Name = "Tab_"..name, BorderSizePixel = 0, TextSize = 14,
            BackgroundColor3 = lib.Scheme.Content, FontFace = font,
            TextColor3 = lib.Scheme.TextDim, Size = UDim2.new(0,100,1,0),
            AutomaticSize = Enum.AutomaticSize.X, AutoButtonColor = false,
            Text = name, ZIndex = 4, Parent = bh,
        })
        corner(btn, 4)
        stroke(btn, lib.Scheme.Outline, 1)
        pad(btn, {{"PaddingLeft", UDim.new(0,12)}, {"PaddingRight", UDim.new(0,12)}})

        local fr = mk("ScrollingFrame", {
            Name = name.."Tab", BorderSizePixel = 0,
            BackgroundColor3 = lib.Scheme.Content, Size = UDim2.new(1,0,1,0),
            CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 5,
            ScrollBarImageColor3 = lib.Scheme.Outline,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ClipsDescendants = true, Visible = false, ZIndex = 2, Parent = cc,
        })

        local tab = {Name=name, Button=btn, Frame=fr, Library=self, __GB={}, Widgets={}}

        btn.MouseEnter:Connect(function()
            if self.ActiveTab ~= tab then
                tw:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = lib.Scheme.Element}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if self.ActiveTab ~= tab then
                tw:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = lib.Scheme.Content}):Play()
            end
        end)
        btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

        tab.AddLeftGB = function(_, n) return mkGB(tab, n, "left") end
        tab.AddRightGB = function(_, n) return mkGB(tab, n, "right") end

        table.insert(self.Tabs, tab)
        if not self.ActiveTab then self:SelectTab(tab) end
        return tab
    end

    self.Library = lib
    return self
end

-- ============== widgets ==============

makeToggle = function(g, o)
    o = o or {}
    local txt = o.Text or "Toggle"
    local def = o.Default or false
    local cb = o.Callback
    local id = o.Id or ("Toggle_"..nextId())

    local fr = mk("Frame", {
        Name = "Toggle", BackgroundColor3 = lib.Scheme.Element,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,40), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.Outline, 1)
    corner(fr, 4)

    mk("TextLabel", {
        Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = fr,
    })

    local ch = mk("Frame", {
        Size = UDim2.new(0,20,0,20), Position = UDim2.new(1,-28,0.5,-10),
        BackgroundColor3 = def and lib.Scheme.Accent or lib.Scheme.SliderBack,
        BorderSizePixel = 0, ZIndex = 5, Parent = fr,
    })
    stroke(ch, def and lib.Scheme.Accent or lib.Scheme.Outline, 1)
    corner(ch, 3)

    local st = def
    local e
    e = {
        Id = id, Type = "Toggle", Value = st, Frame = fr,
        SetValue = function(_, v)
            st = v and true or false
            ch.BackgroundColor3 = st and lib.Scheme.Accent or lib.Scheme.SliderBack
            ch.UIStroke.Color = st and lib.Scheme.Accent or lib.Scheme.Outline
            e.Value = st
            if cb then task.spawn(cb, st) end
        end,
    }

    fr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            e.SetValue(e, not st)
        end
    end)
    fr.MouseEnter:Connect(function() tw:Create(fr, TweenInfo.new(0.15), {BackgroundColor3 = lib.Scheme.ElementHover}):Play() end)
    fr.MouseLeave:Connect(function() tw:Create(fr, TweenInfo.new(0.15), {BackgroundColor3 = lib.Scheme.Element}):Play() end)

    reg(id, e)
    table.insert(g.Widgets, e)
    table.insert(g.Tab.Widgets, e)
    return { Set=function(_,v) e.SetValue(e,v) end, Get=function() return st end }
end

makeSlider = function(g, o)
    o = o or {}
    local txt = o.Text or "Slider"
    local mn = o.Min or 0
    local mx = o.Max or 100
    local def = o.Default or mn
    local rnd = o.Rounding or 0
    local sfx = o.Suffix or ""
    local cb = o.Callback
    local id = o.Id or ("Slider_"..nextId())

    local fr = mk("Frame", {
        Name = "Slider", BackgroundColor3 = lib.Scheme.Element,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,44), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.Outline, 1)
    corner(fr, 4)

    mk("TextLabel", {
        Size = UDim2.new(0.7,0,0,20), Position = UDim2.new(0,12,0,4),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = fr,
    })

    local vl = mk("TextLabel", {
        Size = UDim2.new(0.3,-12,0,20), Position = UDim2.new(0.7,0,0,4),
        BackgroundTransparency = 1, Text = tostring(def)..sfx,
        TextColor3 = lib.Scheme.Text, FontFace = font, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5, Parent = fr,
    })

    local tr = mk("Frame", {
        Size = UDim2.new(1,-24,0,10), Position = UDim2.new(0,12,0,28),
        BackgroundColor3 = lib.Scheme.SliderBack, BorderSizePixel = 0,
        ZIndex = 5, Parent = fr,
    })
    corner(tr, 3)

    local fl = mk("Frame", {
        Size = UDim2.new(0,0,1,0), BackgroundColor3 = lib.Scheme.Accent,
        BorderSizePixel = 0, ZIndex = 6, Parent = tr,
    })
    corner(fl, 3)

    local val = def
    local e
    local function apply()
        local a = (mx > mn) and ((val - mn) / (mx - mn)) or 0
        a = math.clamp(a, 0, 1)
        fl.Size = UDim2.new(a, 0, 1, 0)
        vl.Text = tostring(val)..sfx
    end
    apply()

    e = {
        Id = id, Type = "Slider", Value = val, Min = mn, Max = mx, Rounding = rnd, Frame = fr,
        SetValue = function(_, v)
            v = tonumber(v) or val
            v = math.clamp(v, mn, mx)
            if rnd > 0 then v = math.floor(v * 10^rnd + 0.5) / 10^rnd
            else v = math.floor(v + 0.5) end
            val = v
            e.Value = v
            apply()
            if cb then task.spawn(cb, v) end
        end,
    }

    local drg = false
    local function upd(inp)
        local a = math.clamp((inp.Position.X - tr.AbsolutePosition.X) / math.max(tr.AbsoluteSize.X,1), 0, 1)
        e.SetValue(e, mn + (mx - mn) * a)
    end
    tr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drg = true; upd(inp)
        end
    end)
    fl.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drg = true; upd(inp)
        end
    end)
    uis.InputChanged:Connect(function(inp)
        if drg and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            upd(inp)
        end
    end)
    uis.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drg = false
        end
    end)

    reg(id, e)
    table.insert(g.Widgets, e)
    table.insert(g.Tab.Widgets, e)
    return { Set=function(_,v) e.SetValue(e,v) end, Get=function() return val end }
end

local function newOverlayList()
    local lf = mk("ScrollingFrame", {
        Name = "OverlayList", BackgroundColor3 = lib.Scheme.TopBar,
        BorderSizePixel = 0, CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4,
        ScrollBarImageColor3 = lib.Scheme.Outline, ZIndex = 501, Parent = overlay,
    })
    stroke(lf, lib.Scheme.Outline, 1)
    corner(lf, 4)
    mk("UIListLayout", {Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = lf})
    pad(lf, {
        {"PaddingTop", UDim.new(0,4)}, {"PaddingBottom", UDim.new(0,4)},
        {"PaddingLeft", UDim.new(0,4)}, {"PaddingRight", UDim.new(0,4)},
    })
    return lf
end

makeDropdown = function(g, o)
    o = o or {}
    local txt = o.Text or "Dropdown"
    local vals = o.Values or {}
    local rawDef = o.Default
    local cb = o.Callback
    local multi = o.Multi
    local id = o.Id or ("Dropdown_"..nextId())

    local sel
    if multi then
        sel = {}
        if type(rawDef) == "table" then
            for k,v in pairs(rawDef) do
                if type(k) == "number" then sel[v] = true
                elseif v == true then sel[k] = true end
            end
        elseif rawDef then
            sel[rawDef] = true
        end
    else
        sel = rawDef or vals[1] or ""
    end

    local fr = mk("Frame", {
        Name = "Dropdown", BackgroundColor3 = lib.Scheme.Element,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,34),
        ClipsDescendants = false, ZIndex = 10, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.Outline, 1)
    corner(fr, 4)

    local tl = mk("TextLabel", {
        Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11, Parent = fr,
    })

    local ar = mk("TextLabel", {
        Size = UDim2.new(0,20,1,0), Position = UDim2.new(1,-28,0,0),
        BackgroundTransparency = 1, Text = "v", TextColor3 = lib.Scheme.TextDim,
        FontFace = font, TextSize = 14, ZIndex = 11, Parent = fr,
    })

    local function updLbl()
        if multi then
            local ks = {}
            for k,v in pairs(sel) do if v then table.insert(ks, tostring(k)) end end
            table.sort(ks)
            tl.Text = #ks == 0 and (txt..": none") or (txt..": "..table.concat(ks,", "))
        else
            tl.Text = txt..": "..tostring(sel)
        end
    end
    updLbl()

    local e
    e = {
        Id=id, Type="Dropdown", Value=sel, Values=vals, Multi=multi, Frame=fr,
        SetValue = function(_, v)
            if multi then
                if type(v) == "table" then
                    sel = {}
                    for k,val in pairs(v) do
                        if type(k) == "number" then sel[val] = true
                        elseif val == true then sel[k] = true end
                    end
                elseif v == nil then sel = {}
                else sel = {[v]=true} end
            else
                sel = v
            end
            e.Value = sel
            updLbl()
            if cb then task.spawn(cb, sel) end
        end,
    }

    local open = false
    local lf
    local ancConn

    local function updAnc()
        if not lf or not lf.Parent then return end
        if not fr.Parent then
            if lf then lf:Destroy(); lf = nil end
            open = false
            return
        end
        local ap = fr.AbsolutePosition
        local asz = fr.AbsoluteSize
        lf.Position = UDim2.fromOffset(ap.X, ap.Y + asz.Y + 4)
        lf.Size = UDim2.new(0, asz.X, 0, math.min(#vals*20+8, 150))
    end

    local function close()
        if lf then lf:Destroy(); lf = nil end
        if ancConn then ancConn:Disconnect(); ancConn = nil end
        open = false
        tw:Create(ar, TweenInfo.new(0.15), {Rotation = 0}):Play()
    end

    local function openList()
        if lf then return end
        lf = newOverlayList()
        lf.Size = UDim2.new(0, fr.AbsoluteSize.X, 0, math.min(#vals*20+8, 150))

        for _, v in ipairs(vals) do
            local isOn = multi and (type(sel) == "table" and sel[v]) or (not multi and v == sel)
            local it = mk("TextLabel", {
                Size = UDim2.new(1,0,0,18),
                BackgroundColor3 = isOn and lib.Scheme.Accent or lib.Scheme.DropdownItem,
                BorderSizePixel = 0, Text = "  "..tostring(v),
                TextColor3 = lib.Scheme.Text, FontFace = font, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502, Parent = lf,
            })
            corner(it, 3)
            it.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                if multi then
                    if type(sel) ~= "table" then sel = {} end
                    sel[v] = not sel[v] or nil
                    e.Value = sel
                    updLbl()
                    it.BackgroundColor3 = sel[v] and lib.Scheme.Accent or lib.Scheme.DropdownItem
                    if cb then task.spawn(cb, sel) end
                else
                    sel = v; e.Value = v; updLbl()
                    if cb then task.spawn(cb, v) end
                    close()
                end
            end)
            it.MouseEnter:Connect(function()
                local on = multi and (type(sel) == "table" and sel[v]) or (not multi and v == sel)
                if not on then it.BackgroundColor3 = lib.Scheme.ElementHover end
            end)
            it.MouseLeave:Connect(function()
                local on = multi and (type(sel) == "table" and sel[v]) or (not multi and v == sel)
                it.BackgroundColor3 = on and lib.Scheme.Accent or lib.Scheme.DropdownItem
            end)
        end

        updAnc()
        ancConn = rs.RenderStepped:Connect(updAnc)
        open = true
        tw:Create(ar, TweenInfo.new(0.15), {Rotation = 180}):Play()
    end

    fr.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if open then close() else openList() end
    end)

    uis.InputBegan:Connect(function(inp, gp)
        if gp or not open then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = inp.Position
        local ap, asz = fr.AbsolutePosition, fr.AbsoluteSize
        if p.X >= ap.X and p.X <= ap.X+asz.X and p.Y >= ap.Y and p.Y <= ap.Y+asz.Y then return end
        if lf then
            local la, ls = lf.AbsolutePosition, lf.AbsoluteSize
            if p.X >= la.X and p.X <= la.X+ls.X and p.Y >= la.Y and p.Y <= la.Y+ls.Y then return end
        end
        close()
    end)

    reg(id, e)
    table.insert(g.Widgets, e)
    table.insert(g.Tab.Widgets, e)
    return {
        SetValue = function(_,v) e.SetValue(e,v) end,
        Set = function(_,v) e.SetValue(e,v) end,
        Get = function() return sel end,
        SetValues = function(_,l) vals = l; e.Values = l end,
    }
end

makeButton = function(g, o)
    o = o or {}
    local txt = o.Text or "Button"
    local fn = o.Func or o.Callback
    local id = o.Id or ("Button_"..nextId())

    local fr = mk("Frame", {
        Name = "Button", BackgroundColor3 = lib.Scheme.Element,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,32), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.Outline, 1)
    corner(fr, 4)

    mk("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = txt, TextColor3 = lib.Scheme.Text, FontFace = font, TextSize = 14,
        ZIndex = 5, Parent = fr,
    })

    fr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            fr.BackgroundColor3 = lib.Scheme.Accent
            if fn then task.spawn(fn) end
            task.delay(0.15, function()
                if fr.Parent then tw:Create(fr, TweenInfo.new(0.2), {BackgroundColor3 = lib.Scheme.Element}):Play() end
            end)
        end
    end)
    fr.MouseEnter:Connect(function() tw:Create(fr, TweenInfo.new(0.15), {BackgroundColor3 = lib.Scheme.ElementHover}):Play() end)
    fr.MouseLeave:Connect(function() tw:Create(fr, TweenInfo.new(0.15), {BackgroundColor3 = lib.Scheme.Element}):Play() end)

    reg(id, {Id=id, Type="Button", Frame=fr})
    table.insert(g.Widgets, {Id=id, Type="Button", Frame=fr})
    return {}
end

makeLabel = function(g, o)
    o = o or {}
    local txt = o.Text or ""
    local fr = mk("Frame", {
        Name = "Label", BackgroundColor3 = lib.Scheme.Content,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,26), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.OutlineDim, 1)
    corner(fr, 4)
    mk("TextLabel", {
        Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = fr,
    })
    return {}
end

makeInfo = function(g, o)
    o = o or {}
    local txt = o.Text or ""
    local fr = mk("Frame", {
        Name = "Info", BackgroundColor3 = lib.Scheme.InfoBg,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,26), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.InfoBorder, 1)
    corner(fr, 4)
    mk("TextLabel", {
        Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.InfoText,
        FontFace = font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = fr,
    })
    return {}
end

makeWarn = function(g, o)
    o = o or {}
    local txt = o.Text or ""
    local fr = mk("Frame", {
        Name = "Warning", BackgroundColor3 = lib.Scheme.WarningBg,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,26), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.WarningBorder, 1)
    corner(fr, 4)
    mk("TextLabel", {
        Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.WarningText,
        FontFace = font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = fr,
    })
    return {}
end

makeColor = function(g, o)
    o = o or {}
    local txt = o.Text or o.Title or "Color"
    local def = o.Default or Color3.new(1,1,1)
    local cb = o.Callback
    local id = o.Id or ("Color_"..nextId())

    local fr = mk("Frame", {
        Name = "ColorPicker", BackgroundColor3 = lib.Scheme.Element,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,34),
        ClipsDescendants = false, ZIndex = 10, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.Outline, 1)
    corner(fr, 4)

    mk("TextLabel", {
        Size = UDim2.new(1,-50,1,0), Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11, Parent = fr,
    })

    local sw = mk("Frame", {
        Size = UDim2.new(0,20,0,20), Position = UDim2.new(1,-32,0.5,-10),
        BackgroundColor3 = def, BorderSizePixel = 0, ZIndex = 11, Parent = fr,
    })
    stroke(sw, lib.Scheme.Outline, 1)
    corner(sw, 3)

    local presets = {
        Color3.fromRGB(255,81,81), Color3.fromRGB(255,170,0), Color3.fromRGB(255,255,0),
        Color3.fromRGB(80,255,80), Color3.fromRGB(0,200,255), Color3.fromRGB(156,90,255),
        Color3.fromRGB(255,100,200), Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0),
    }

    local e = {
        Id=id, Type="ColorPicker", Value=def, Frame=fr,
        SetValue = function(_, c)
            e.Value = c
            sw.BackgroundColor3 = c
            if cb then task.spawn(cb, c) end
        end,
    }

    local open, lf, ancConn
    local function close() if lf then lf:Destroy(); lf = nil end; if ancConn then ancConn:Disconnect(); ancConn = nil end; open = false end
    local function updAnc()
        if not lf or not lf.Parent then return end
        if not fr.Parent then if lf then lf:Destroy(); lf = nil end; open = false; return end
        local ap, asz = fr.AbsolutePosition, fr.AbsoluteSize
        lf.Position = UDim2.fromOffset(ap.X + asz.X - 160, ap.Y + asz.Y + 4)
    end
    local function openList()
        if lf then return end
        lf = mk("Frame", {
            Name = "OverlayColor", BackgroundColor3 = lib.Scheme.TopBar,
            BorderSizePixel = 0, Size = UDim2.new(0,160,0,60),
            ZIndex = 501, Parent = overlay,
        })
        stroke(lf, lib.Scheme.Outline, 1)
        corner(lf, 4)
        mk("UIGridLayout", {
            CellSize = UDim2.new(0,24,0,24), CellPadding = UDim2.new(0,4,0,4), Parent = lf,
        })
        pad(lf, {
            {"PaddingTop", UDim.new(0,4)}, {"PaddingLeft", UDim.new(0,4)},
            {"PaddingRight", UDim.new(0,4)}, {"PaddingBottom", UDim.new(0,4)},
        })
        for _, c in ipairs(presets) do
            local b = mk("Frame", {BackgroundColor3 = c, BorderSizePixel = 0, ZIndex = 502, Parent = lf})
            stroke(b, lib.Scheme.Outline, 1)
            corner(b, 3)
            b.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                e.SetValue(e, c); close()
            end)
        end
        updAnc()
        ancConn = rs.RenderStepped:Connect(updAnc)
        open = true
    end

    fr.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if open then close() else openList() end
    end)
    uis.InputBegan:Connect(function(inp, gp)
        if gp or not open then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = inp.Position
        local ap, asz = fr.AbsolutePosition, fr.AbsoluteSize
        if p.X >= ap.X and p.X <= ap.X+asz.X and p.Y >= ap.Y and p.Y <= ap.Y+asz.Y then return end
        if lf then
            local la, ls = lf.AbsolutePosition, lf.AbsoluteSize
            if p.X >= la.X and p.X <= la.X+ls.X and p.Y >= la.Y and p.Y <= la.Y+ls.Y then return end
        end
        close()
    end)

    reg(id, e)
    table.insert(g.Widgets, e)
    table.insert(g.Tab.Widgets, e)
    return { SetValue=function(_,c) e.SetValue(e,c) end, Get=function() return e.Value end }
end

makeKey = function(g, o)
    o = o or {}
    local txt = o.Text or "Key"
    local def = o.Default or "None"
    local cb = o.Callback
    local id = o.Id or ("Key_"..nextId())

    local fr = mk("Frame", {
        Name = "KeyPicker", BackgroundColor3 = lib.Scheme.Element,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,34), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.Outline, 1)
    corner(fr, 4)

    mk("TextLabel", {
        Size = UDim2.new(1,-80,1,0), Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = fr,
    })

    local val = def
    local kl = mk("TextLabel", {
        Size = UDim2.new(0,60,0,22), Position = UDim2.new(1,-68,0.5,-11),
        BackgroundColor3 = lib.Scheme.SliderBack, BorderSizePixel = 0,
        Text = tostring(def), TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 13, ZIndex = 5, Parent = fr,
    })
    stroke(kl, lib.Scheme.Outline, 1)
    corner(kl, 3)

    local listen = false
    local e
    e = {
        Id=id, Type="KeyPicker", Value=val, Mode="Toggle", Frame=fr,
        SetValue = function(_, v)
            val = v; e.Value = v; kl.Text = tostring(v)
            if cb then task.spawn(cb, v) end
        end,
        GetState = function()
            if val == "None" then return false end
            return uis:IsKeyDown(Enum.KeyCode[val])
        end,
    }

    kl.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        listen = true
        kl.Text = "..."
        kl.BackgroundColor3 = lib.Scheme.Accent
    end)
    uis.InputBegan:Connect(function(inp, gp)
        if not listen then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            val = inp.KeyCode == Enum.KeyCode.Escape and "None" or inp.KeyCode.Name
            e.Value = val
            kl.Text = tostring(val)
            kl.BackgroundColor3 = lib.Scheme.SliderBack
            listen = false
            if cb then task.spawn(cb, val) end
        end
    end)

    reg(id, e)
    table.insert(g.Widgets, e)
    table.insert(g.Tab.Widgets, e)
    return { SetValue=function(_,v) e.SetValue(e,v) end, GetState=e.GetState }
end

makeInput = function(g, o)
    o = o or {}
    local txt = o.Text or "Input"
    local def = o.Default or ""
    local ph = o.Placeholder or "type..."
    local cb = o.Callback
    local id = o.Id or ("Input_"..nextId())

    local fr = mk("Frame", {
        Name = "Input", BackgroundColor3 = lib.Scheme.Element,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,34), ZIndex = 4, Parent = g.Scroll,
    })
    stroke(fr, lib.Scheme.Outline, 1)
    corner(fr, 4)

    mk("TextLabel", {
        Size = UDim2.new(0.4,0,1,0), Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1, Text = txt, TextColor3 = lib.Scheme.Text,
        FontFace = font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = fr,
    })

    local bx = mk("TextBox", {
        Size = UDim2.new(0.55,-14,0,22), Position = UDim2.new(0.45,0,0.5,-11),
        BackgroundColor3 = lib.Scheme.SliderBack, BorderSizePixel = 0,
        Text = def, PlaceholderText = ph, TextColor3 = lib.Scheme.Text,
        PlaceholderColor3 = lib.Scheme.TextDim, FontFace = font, TextSize = 13,
        ClearTextOnFocus = false, ZIndex = 5, Parent = fr,
    })
    stroke(bx, lib.Scheme.Outline, 1)
    corner(bx, 3)

    local e = {
        Id=id, Type="Input", Value=def, Frame=fr,
        SetValue = function(_, v)
            e.Value = v; bx.Text = tostring(v)
            if cb then task.spawn(cb, v) end
        end,
    }
    bx.FocusLost:Connect(function()
        e.Value = bx.Text
        if cb then task.spawn(cb, bx.Text) end
    end)

    reg(id, e)
    table.insert(g.Widgets, e)
    table.insert(g.Tab.Widgets, e)
    return { SetValue=function(_,v) e.SetValue(e,v) end, Get=function() return e.Value end }
end

-- TODO: add tabs-inside-tabs someday
-- color: maybe add rgb input later

return lib
