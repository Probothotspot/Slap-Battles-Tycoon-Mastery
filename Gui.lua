local Gui = {}
local views = setmetatable({}, { __mode = "k" })
local function create(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function round(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, object)
end
local function text(parent, name, value, x, y, width, height, size, color, bold)
    return create("TextLabel", { Name = name, Text = value, Position = UDim2.fromOffset(x,y),
        Size = UDim2.new(width, width == 1 and -2*x or 0, 0, height),
        BackgroundTransparency = 1, Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = size, TextColor3 = color or rgb(239,230,255),
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true }, parent)
end
local function button(parent, name, value, position, size)
    local object = create("TextButton", { Name = name, Text = value, Position = position, Size = size,
        BackgroundColor3 = rgb(65,41,103), BorderSizePixel = 0, AutoButtonColor = true,
        TextColor3 = rgb(250,245,255), Font = Enum.Font.GothamBold, TextSize = 15 }, parent)
    round(object,10)
    return object
end
local function gradient(object, colors, rotation)
    local keys = {}
    for i,color in ipairs(colors) do keys[i] = ColorSequenceKeypoint.new((i-1)/(#colors-1),color) end
    return create("UIGradient", { Color = ColorSequence.new(keys), Rotation = rotation or 0 }, object)
end
local function clockText(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    return string.format("%02d:%02d:%02d", math.floor(seconds/3600), math.floor(seconds/60)%60, seconds%60)
end
local function number(value)
    if value == nil then return "—" end
    local s = string.format("%.0f", value)
    return s:reverse():gsub("(%d%d%d)","%1 "):reverse():gsub("^ ","")
end

function Gui.mount(context)
    local app,cleanup=context.App,context.Cleanup
    local input=game:GetService("UserInputService")
    local width,height=context.Config.UI.Width,context.Config.UI.Height
    local gui=create("ScreenGui",{Name="TycoonMasteryGUI",ResetOnSpawn=false,DisplayOrder=105,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},nil)
    cleanup:add(gui)
    local root=create("Frame",{Name="SafeArea",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},gui)
    local frame=create("Frame",{Name="MasteryWindow",Size=UDim2.fromOffset(width,height),Position=UDim2.new(.5,-width/2,.5,-height/2),
        BackgroundColor3=rgb(25,16,45),BorderSizePixel=0,Active=true,ClipsDescendants=true},root)
    round(frame,16)
    local scale=create("UIScale",{Scale=1},frame)
    local title=text(frame,"Title","TYCOON MASTERY",56,9,1,24,18,nil,true); title.Size=UDim2.new(1,-110,0,24); title.Active=true
    local subtitle=text(frame,"Subtitle","",56,33,1,17,10,rgb(190,162,221)); subtitle.Size=UDim2.new(1,-110,0,17)
    local collapse=button(frame,"Collapse","−",UDim2.fromOffset(14,14),UDim2.fromOffset(32,32))
    local close=button(frame,"Close","×",UDim2.new(1,-46,0,14),UDim2.fromOffset(32,32))
    local body=create("ScrollingFrame",{Name="Body",Position=UDim2.fromOffset(18,64),Size=UDim2.new(1,-36,1,-108),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,Active=true,AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y},frame)
    local cards={}
    for i,id in ipairs(app.Catalog.Order) do
        local def=app.Catalog.Quests[id]
        local card=button(body,"Quest_"..id,"",UDim2.fromOffset(0,(i-1)*112),UDim2.new(1,-6,0,104))
        text(card,"QuestTitle",i..". "..def.Title,12,5,1,22,14,nil,true)
        local count=text(card,"Progress","— / "..def.Target,12,29,1,20,13,rgb(238,215,255),true)
        local message=text(card,"QuestState","",12,52,1,22,11,rgb(210,192,230))
        local source=text(card,"ProgressSource","",12,76,1,16,9,rgb(170,150,191))
        local track=create("Frame",{Position=UDim2.new(0,12,1,-6),Size=UDim2.new(1,-24,0,3),BackgroundColor3=rgb(39,27,55),BorderSizePixel=0},card)
        local bar=create("Frame",{Name="ProgressBar",Size=UDim2.fromScale(0,1),BackgroundColor3=rgb(178,117,250),BorderSizePixel=0},track)
        cards[id]={Card=card,Count=count,Message=message,Source=source,Bar=bar}
        local selected=id; cleanup:add(card.Activated:Connect(function() app:Select(selected) end))
    end
    local run=button(body,"RunToggle","Начать наблюдение",UDim2.fromOffset(0,342),UDim2.new(1,-6,0,40))
    local note=text(body,"ModeNote","Модули квестов загружены. Автофарм пока не подключён.",4,392,1,38,11,rgb(207,184,233))
    local reader=text(body,"ReaderStatus","",4,438,1,48,11,rgb(207,184,233))
    local hint=text(body,"QuestHint","",4,492,1,48,10,rgb(173,150,198))
    local credit=text(frame,"AuthorCredit","By: Probothotspot",18,0,1,18,10,rgb(230,230,230)); credit.Position=UDim2.new(0,18,1,-29); credit.TextXAlignment=Enum.TextXAlignment.Center
    local v={Frame=frame,Body=body,Scale=scale,Cards=cards,Run=run,Subtitle=subtitle,Reader=reader,Hint=hint,Collapsed=false}
    views[gui]=v
    local function fit()
        local size=root.AbsoluteSize
        if size.X<=0 or size.Y<=0 then return end
        scale.Scale=math.max(.1,math.min(1,(size.X-24)/width,(size.Y-24)/height))
        local w,h=width*scale.Scale,(v.Collapsed and 60 or height)*scale.Scale
        local x,y=frame.Position.X.Offset,frame.Position.Y.Offset
        if not v.Placed then x,y=(size.X-w)/2,(size.Y-h)/2; v.Placed=true end
        frame.Position=UDim2.fromOffset(math.max(0,math.min(x,size.X-w)),math.max(0,math.min(y,size.Y-h)))
    end
    cleanup:add(root:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
    cleanup:add(collapse.Activated:Connect(function()
        v.Collapsed=not v.Collapsed; body.Visible=not v.Collapsed; credit.Visible=not v.Collapsed
        collapse.Text=v.Collapsed and "+" or "−"; frame.Size=UDim2.fromOffset(width,v.Collapsed and 60 or height); fit()
    end))
    cleanup:add(run.Activated:Connect(function() if app.Running then app:Stop() else app:Start() end end))
    cleanup:add(close.Activated:Connect(function() app:Destroy() end))
    local active,start,origin
    cleanup:add(title.InputBegan:Connect(function(e)
        if not active and (e.UserInputType==Enum.UserInputType.MouseButton1 or e.UserInputType==Enum.UserInputType.Touch) then active,start,origin=e,e.Position,frame.Position end
    end))
    cleanup:add(input.InputChanged:Connect(function(e)
        if not active then return end
        if active.UserInputType==Enum.UserInputType.Touch then if e~=active then return end
        elseif e.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local delta=e.Position-start; frame.Position=UDim2.fromOffset(origin.X.Offset+delta.X,origin.Y.Offset+delta.Y); fit()
    end))
    cleanup:add(input.InputEnded:Connect(function(e) if e==active then active=nil end end))
    cleanup:add(input.WindowFocusReleased:Connect(function() active=nil end))
    cleanup:add(gui.Destroying:Connect(function() app:Destroy() end))
    cleanup:add(function() views[gui]=nil end)
    gui.Parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    fit(); Gui.update(gui,app); return gui
end
function Gui.update(gui,app)
    local v=views[gui]; if not v then return end
    v.Subtitle.Text=(app.Status=="error" and "ERROR" or (app.Running and "RUNNING" or "PAUSED")).." / v"..app.Version.." / 3 модуля"
    v.Run.Text=app.Running and "Пауза наблюдения" or "Начать наблюдение"
    v.Reader.Text=app.LastError or app.Adapter.Message
    v.Hint.Text=app.Catalog.Quests[app.Selected].Hint
    for _,id in ipairs(app.Catalog.Order) do
        local c,s=v.Cards[id],app.Views[id]
        c.Card.BackgroundColor3=id==app.Selected and rgb(95,52,144) or rgb(48,30,71)
        if s then
            c.Count.Text=(s.Known and tostring(s.Value) or "—").." / "..s.Target.." "..s.Unit
            c.Message.Text=s.Message
            c.Source.Text=s.Known and ((s.Stale and "Последнее наблюдение · " or "Источник: ")..s.Source) or "Нет прочитанного игрового счётчика"
            c.Bar.Size=UDim2.fromScale(s.Fraction,1)
        end
    end
end
return Gui
