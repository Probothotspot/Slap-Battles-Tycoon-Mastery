local G={}
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function make(class,props,parent)
    local o=Instance.new(class); for k,v in pairs(props) do o[k]=v end; o.Parent=parent; return o
end
local function round(o,r) make("UICorner",{CornerRadius=UDim.new(0,r or 10)},o) end
function G.mount(app,cleanup)
    local Tween=game:GetService("TweenService")
    local input=game:GetService("UserInputService")
    local gui=make("ScreenGui",{Name="TycoonMasteryGUI",ResetOnSpawn=false,DisplayOrder=105},nil)
    cleanup:add(gui)
    local root=make("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},gui)
    local frame=make("Frame",{Name="MainWindow",Size=UDim2.fromOffset(360,430),Position=UDim2.new(.5,-180,.5,-215),
        BackgroundColor3=rgb(38,23,65),BorderSizePixel=0,ClipsDescendants=true},root); round(frame,14)
    local gradient=make("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,rgb(106,61,166)),
        ColorSequenceKeypoint.new(1,rgb(34,23,65))}),Rotation=0},frame)
    local scale=make("UIScale",{Scale=1},frame)
    local function text(parent,value,x,y,w,h,size)
        return make("TextLabel",{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
            BackgroundTransparency=1,TextColor3=rgb(245,235,255),Font=Enum.Font.Gotham,TextSize=size or 13,
            TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},parent)
    end
    local function button(parent,value,x,y,w,h)
        local b=make("TextButton",{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
            BackgroundColor3=rgb(62,36,96),TextColor3=rgb(250,240,255),Font=Enum.Font.GothamBold,TextSize=13,
            BorderSizePixel=0},parent); round(b,8); return b
    end
    local title=text(frame,"TYCOON MASTERY",14,6,290,32,17); title.Font=Enum.Font.GothamBold; title.Active=true
    local close=button(frame,"×",321,9,28,28)
    local main=button(frame,"Main Account",12,49,164,36)
    local alt=button(frame,"Alt Account",184,49,164,36)
    local label=text(frame,"Alt Account • ник аккаунта на сервере",14,94,332,20,12)
    local field=make("TextBox",{Name="PeerName",Text="",PlaceholderText="Username, не DisplayName",ClearTextOnFocus=false,
        Position=UDim2.fromOffset(12,120),Size=UDim2.fromOffset(244,36),BackgroundColor3=rgb(31,23,47),
        TextColor3=rgb(255,255,255),PlaceholderColor3=rgb(160,140,185),Font=Enum.Font.Gotham,TextSize=12},frame); round(field,8)
    local connect=button(frame,"Connect",264,120,84,36)
    local switches={}
    local function toggle(name,y,callback)
        local row=button(frame,"",12,y,336,43)
        text(row,name,12,0,235,43,14)
        local track=make("Frame",{Position=UDim2.fromOffset(274,10),Size=UDim2.fromOffset(50,24),
            BackgroundColor3=rgb(70,61,85),BorderSizePixel=0},row); round(track,12)
        local knob=make("Frame",{Position=UDim2.fromOffset(3,3),Size=UDim2.fromOffset(18,18),
            BackgroundColor3=rgb(245,240,250),BorderSizePixel=0},track); round(knob,9)
        local s={Row=row,Track=track,Knob=knob}
        cleanup:add(row.Activated:Connect(callback)); table.insert(switches,s); return s
    end
    local quest=toggle("Quest 1",171,function()
        if app.Running or app.Role~="Main" then return end
        app.Quest1=not app.Quest1
    end)
    text(frame,"Quest 2 / Quest 3 — зарезервированы",14,219,332,20,11)
    local status=text(frame,"",14,246,332,62,12)
    local start=toggle("Start Farming",319,function()
        if app.Running then app:stop() else app:start() end
    end)
    text(frame,"Quest 1: сейчас подготовка и защита кнопки.\nДля прогресса нужны удары рядом с тайкуном.",14,367,332,32,10)
    local credit=text(frame,"By: Probothotspot",14,405,332,18,10)
    credit.TextXAlignment=Enum.TextXAlignment.Center
    local toast=make("TextLabel",{Name="ConnectionToast",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,90),
        Size=UDim2.fromOffset(270,64),BackgroundColor3=rgb(66,35,101),TextColor3=rgb(255,255,255),
        Font=Enum.Font.GothamBold,TextSize=14,TextWrapped=true,Text=""},gui); round(toast,10)
    local toastUntil=0
    local activeTweens={}
    local function animate(object,props)
        if activeTweens[object] then activeTweens[object]:Cancel() end
        local t=Tween:Create(object,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
        activeTweens[object]=t; t:Play()
    end
    local function notify(ok)
        toast.Text=ok and "Connected Player\nИгрок найден; обмен скриптов не подтверждён" or "Players Not Found"
        toastUntil=os.clock()+4; animate(toast,{Position=UDim2.new(1,-16,1,-16)})
    end
    cleanup:add(connect.Activated:Connect(function() notify(app:connect(field.Text)) end))
    cleanup:add(field.FocusLost:Connect(function(enter) if enter then notify(app:connect(field.Text)) end end))
    local function role(value)
        if app.Running then app:stop() end
        app.Role=value; app.Peer=nil; app.PeerName=""; field.Text=""
        label.Text=(value=="Main" and "Alt Account" or "Main Account").." • ник аккаунта на сервере"
        app.Message="Укажи ник второго аккаунта"
    end
    cleanup:add(main.Activated:Connect(function() role("Main") end))
    cleanup:add(alt.Activated:Connect(function() role("Alt") end))
    cleanup:add(close.Activated:Connect(function() app:Destroy() end))
    local function setToggle(s,on)
        if s.Value==on then return end; s.Value=on
        animate(s.Knob,{Position=UDim2.fromOffset(on and 29 or 3,3)})
        animate(s.Track,{BackgroundColor3=on and rgb(176,105,246) or rgb(70,61,85)})
    end
    local drag,origin,pointer
    cleanup:add(title.InputBegan:Connect(function(e)
        if e.UserInputType==Enum.UserInputType.MouseButton1 or e.UserInputType==Enum.UserInputType.Touch then
            drag,origin,pointer=e,frame.Position,e.Position
        end
    end))
    local function fit()
        local size=root.AbsoluteSize
        if size.X>0 and size.Y>0 then scale.Scale=math.min(1,(size.X-16)/360,(size.Y-16)/430) end
    end
    cleanup:add(root:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
    cleanup:add(input.InputChanged:Connect(function(e)
        if not drag then return end
        if e~=drag and not (drag.UserInputType==Enum.UserInputType.MouseButton1
            and e.UserInputType==Enum.UserInputType.MouseMovement) then return end
        local delta=e.Position-pointer
        frame.Position=UDim2.new(origin.X.Scale,origin.X.Offset+delta.X,origin.Y.Scale,origin.Y.Offset+delta.Y)
    end))
    cleanup:add(input.InputEnded:Connect(function(e) if e==drag then drag=nil end end))
    cleanup:add(input.WindowFocusReleased:Connect(function() drag=nil end))
    cleanup:add(game:GetService("RunService").Heartbeat:Connect(function()
        gradient.Rotation=(os.clock()*12)%360
        local gray=200+math.floor(math.sin(os.clock()*1.5)*40)
        credit.TextColor3=rgb(gray,gray,gray)
        main.BackgroundColor3=app.Role=="Main" and rgb(120,69,175) or rgb(62,36,96)
        alt.BackgroundColor3=app.Role=="Alt" and rgb(120,69,175) or rgb(62,36,96)
        setToggle(quest,app.Role=="Main" and app.Quest1 or app.Quest==1)
        setToggle(start,app.Running)
        local reading=app.Progress and app.Progress:read("defense")
        local counter=reading and reading.Known and not reading.Stale and tostring(reading.Value) or "—"
        status.Text=app.Message.."\nQuest 1: "..counter.." / 500"
        if toastUntil>0 and os.clock()>toastUntil then
            toastUntil=0; animate(toast,{Position=UDim2.new(1,-16,1,90)})
        end
    end))
    cleanup:add(function() for _,t in pairs(activeTweens) do t:Cancel() end end)
    cleanup:add(gui.Destroying:Connect(function() app:Destroy() end))
    gui.Parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    fit(); return gui
end
return G
