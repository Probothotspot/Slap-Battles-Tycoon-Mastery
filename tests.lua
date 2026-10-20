-- Execute the real GUI and Main against a small event-driven Roblox model.
local saved={Instance=Instance,Enum=Enum,UDim2=UDim2,UDim=UDim,Color3=Color3,
    ColorSequence=ColorSequence,ColorSequenceKeypoint=ColorSequenceKeypoint,
    TweenInfo=TweenInfo,game=game,typeof=typeof,warn=warn,session=_G.SlapBattlesTycoonMastery,
    readfile=readfile,writefile=writefile,isfile=isfile,identifyexecutor=identifyexecutor}
local signals,tweens={},{}
local viewport={X=1000,Y=850}
local function signal()
    local s={listeners={}}
    function s:Connect(callback)
        local c={kind="RBXScriptConnection",Connected=true,callback=callback}
        function c:Disconnect() self.Connected=false end
        table.insert(self.listeners,c); return c
    end
    function s:Fire(...)
        local copy={}; for _,c in ipairs(self.listeners) do table.insert(copy,c) end
        for _,c in ipairs(copy) do if c.Connected then c.callback(...) end end
    end
    table.insert(signals,s); return s
end
local function aliveConnections()
    local n=0
    for _,s in ipairs(signals) do for _,c in ipairs(s.listeners) do if c.Connected then n=n+1 end end end
    return n
end
UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
UDim={new=function(s,o) return {Scale=s,Offset=o} end}
Color3={fromRGB=function(r,g,b) return {r,g,b} end}
ColorSequence={new=function(v) return v end}
ColorSequenceKeypoint={new=function(t,c) return {t,c} end}
TweenInfo={new=function(...) return {...} end}
Enum={Font={Gotham="Gotham",GothamBold="GothamBold"},TextXAlignment={Left="Left",Center="Center"},
    TextYAlignment={Center="Center",Top="Top"},ZIndexBehavior={Sibling="Sibling"},
    AutomaticSize={Y="Y"},ScrollingDirection={Y="Y"},SortOrder={LayoutOrder="LayoutOrder"},
    EasingStyle={Linear="Linear",Quad="Quad"},EasingDirection={InOut="InOut",Out="Out"},
    UserInputType={MouseButton1="MouseButton1",Touch="Touch",MouseMovement="MouseMovement"}}
local methods,mt={},{}
Instance={new=function(class)
    return setmetatable({_class=class,_children={},_signals={},_properties={Name=class,Visible=true,ZIndex=1}},mt)
end}
mt.__index=function(self,k)
    if methods[k] then return methods[k] end
    if k=="AbsoluteSize" then
        if self._class=="ScreenGui" or self._class=="PlayerGui" then return viewport end
        local parent=self._properties.Parent
        local area=parent and parent.AbsoluteSize or {X=1000,Y=850}
        local size=self._properties.Size
        return size and {X=area.X*size.X.Scale+size.X.Offset,Y=area.Y*size.Y.Scale+size.Y.Offset} or area
    end
    if k=="Activated" or k=="InputBegan" or k=="InputChanged" or k=="InputEnded"
        or k=="WindowFocusReleased" or k=="Destroying" or k=="ChildAdded"
        or k=="CharacterAdded" or k=="Died" then
        if not self._signals[k] then self._signals[k]=signal() end
        return self._signals[k]
    end
    return self._properties[k]
end
mt.__newindex=function(self,k,v)
    if k=="Parent" then
        local old=self._properties.Parent
        if old then for i,c in ipairs(old._children) do if c==self then table.remove(old._children,i); break end end end
        if v then table.insert(v._children,self) end
    end
    self._properties[k]=v
    if self._signals[k] then self._signals[k]:Fire() end
end
function methods:GetChildren() local r={}; for _,c in ipairs(self._children) do table.insert(r,c) end; return r end
function methods:IsA(class)
    return self._class==class or (class=="BasePart" and self._class=="Part")
end
function methods:FindFirstChild(name,recursive)
    for _,c in ipairs(self._children) do
        if c.Name==name then return c end
        if recursive then local found=c:FindFirstChild(name,true); if found then return found end end
    end
end
function methods:FindFirstChildOfClass(class)
    for _,c in ipairs(self._children) do if c:IsA(class) then return c end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),name) end
function methods:GetPropertyChangedSignal(name)
    self._signals[name]=self._signals[name] or signal(); return self._signals[name]
end
function methods:Destroy()
    if self._properties.Destroyed then return end
    self._properties.Destroyed=true
    self.Destroying:Fire()
    for _,child in ipairs(self:GetChildren()) do child:Destroy() end
    self.Parent=nil
end
typeof=function(object) return type(object)=="table" and (object.kind or (object._class and "Instance")) or type(object) end
warn=function() end
local player=Instance.new("Player")
local playerGui=Instance.new("PlayerGui"); playerGui.Parent=player
local character=Instance.new("Model"); player.Character=character
local humanoid=Instance.new("Humanoid"); humanoid.Health=100; humanoid.Parent=character
local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Position={Y=350}; root.Parent=character
local backpack=Instance.new("Backpack"); backpack.Parent=player
local board=Instance.new("Folder"); board.Name="leaderstats"; board.Parent=player
local slaps=Instance.new("IntValue"); slaps.Name="Slaps"; slaps.Value=100; slaps.Parent=board
local input=Instance.new("UserInputService")
function input:GetFocusedTextBox() return self.FocusedBox end
local heartbeat=signal()
local services={Players={LocalPlayer=player},UserInputService=input,RunService={Heartbeat=heartbeat},TweenService={}}
function services.TweenService:Create(object,_,goals)
    local tween={Cancelled=false}
    function tween:Play() for k,v in pairs(goals) do object[k]=v end end
    function tween:Cancel() self.Cancelled=true end
    table.insert(tweens,tween); return tween
end
game={GetService=function(_,name) return assert(services[name],name) end}
local count=0
local function eq(a,b,why) count=count+1; assert(a==b,(why or "Mismatch")..": "..tostring(a).." ~= "..tostring(b)) end
function methods:GetDescendants()
    local out={}
    local function walk(p) for _,child in ipairs(p:GetChildren()) do out[#out+1]=child; walk(child) end end
    walk(self); return out
end
local oldIsA=methods.IsA
function methods:IsA(class)
    return oldIsA(self,class) or (class=="GuiObject" and (self._class=="Frame" or self._class=="ScrollingFrame"
        or self._class=="TextLabel" or self._class=="TextButton" or self._class=="TextBox"))
end
local manifest=dofile("manifest.lua")
for _,entry in ipairs(manifest.systems) do
    local m=dofile(entry.path); eq(m.Name,entry.name); eq(m.Ready,true)
end
for _,file in ipairs({"loader.lua","main.lua","Gui.lua","Adapter.lua","Cleanup.lua","Logger.lua","config.lua"}) do
    eq(type(assert(loadfile(file))),"function","Compile "..file)
end
local P,Catalog=dofile("Progress.lua"),dofile("QuestCatalog.lua")
eq(Catalog.Quests.god.Target,150,"Use the current in-game screenshot requirement")
eq(P.parse("0/150(0%)",Catalog.Quests.god.Target),0,"Read the exact screenshot counter format")
eq(P.parse("0/200(0%)",Catalog.Quests.god.Target),nil,"Outdated denominator is not accepted")
for _,case in ipairs({{"0 / 500",500,0},{"42/500",500,42},{"1,500 / 15,000",15000,1500},
    {"1.5K / 15K",15000,1500},{"<b>200 / 200</b>",200,200},{"999 / 500",500,999}}) do
    eq(P.parse(case[1],case[2]),case[3],"Valid counter")
end
for _,bad in ipairs({"-1/500","1e5/500","1 000/500","foo1/500","20/5000","nan/500","5/200","2.2/500","1,5/500","1,2345/500","1,,200/500"}) do
    eq(P.parse(bad,500),nil,"Reject ambiguous or invalid counter: "..bad)
end
local now=0; local p=P.new(Catalog,function() return now end)
eq(p:read("defense").Known,false)
eq(p:set("defense",0,"fixture"),true); eq(p:read("defense").Value,0)
eq(p:set("defense",0/0,"fixture"),false); eq(p:set("bogus",2,"fixture"),false)
eq(p:set("god",1.5,"fixture"),false); eq(p:set("points",3,""),false)
p:set("defense",100,"fixture"); p:set("defense",2,"fixture"); eq(p:read("defense").Value,2,"Absolute correction is not hidden")
now=11; eq(p:read("defense").Stale,true); p:clear(); eq(p:read("defense").Known,false)
local Core=dofile("QuestCore.lua")
local defense=dofile("QuestDefense.lua").new({Core=Core,Catalog=Catalog})
local points=dofile("QuestMainIsland.lua").new({Core=Core,Catalog=Catalog})
local god=dofile("QuestGodStatus.lua").new({Core=Core,Catalog=Catalog})
eq(defense:update({Alive=false},p).Status,"waiting")
eq(defense:update({Alive=true,Glove="Default"},p).Status,"equip")
eq(defense:update({Alive=true,Glove="Tycoon"},p).Status,"unbound")
eq(defense:update({Alive=true,Glove="Tycoon",OwnedTycoon=false},p).Status,"build")
eq(defense:update({Alive=true,Glove="Tycoon",OwnedTycoon=true,EnemyNearTycoon=true},p).Status,"guide")
eq(points:update({Alive=true,Glove="Tycoon",OnMainIsland=false},p).Status,"move")
eq(points:update({Alive=true,Glove="Tycoon",OnMainIsland=true},p).Status,"guide")
eq(god:update({Alive=true,Glove="Tycoon"},p).Status,"unbound")
eq(god:update({Alive=true,Glove="Tycoon",GodStatus=false},p).Status,"upgrade")
eq(god:update({Alive=true,Glove="Tycoon",GodStatus=true},p).Known,false,"God state is not itself a kill")
p:set("god",150,"fixture"); eq(god:update({Alive=true},p).Status,"shown_complete")
now=22; eq(god:update({Alive=true},p).Status~="shown_complete",true,"Stale observations cannot declare current completion")
local function make(class,name,parent,textValue)
    local object=Instance.new(class); object.Name=name; object.Parent=parent
    if textValue then object.Text=textValue end
    if class=="ScreenGui" then object.Enabled=true end
    return object
end
local liveGui=make("ScreenGui","LiveGameUI",playerGui)
local panel=make("Frame","TycoonMastery",liveGui)
make("TextLabel","Header",panel,"Tycoon Mastery")
local row=make("Frame","Defense",panel)
make("TextLabel","Description",row,"Defend your Tycoon from enemy attack")
local shown=make("TextLabel","Count",row,"12 / 500")
local pointRow=make("Frame","Points",panel)
make("TextLabel","Description",pointRow,"Accumulate points on the main island")
make("TextLabel","Count",pointRow,"1.5K / 15K")
local godRow=make("Frame","God",panel)
make("TextLabel","Description",godRow,"End lives while at GOD STATUS")
make("TextLabel","Count",godRow,"3 / 150")
local tool=make("Tool","Tycoon",character)
local progress=P.new(Catalog)
local adapter=dofile("Adapter.lua").new({Player=player,Progress=progress,Parser=P,Catalog=Catalog})
local s=adapter:snapshot()
eq(s.Glove,"Tycoon"); eq(s.Alive,true); eq(s.GodStatus,nil,"Missing state is not false")
eq(progress:read("defense").Value,12); eq(progress:read("points").Value,1500); eq(progress:read("god").Value,3)
local conflict=make("TextLabel","ConflictingCount",row,"13 / 500")
progress:clear(); adapter:snapshot(); eq(progress:read("defense").Known,false,"Conflicting UI values are ignored")
conflict:Destroy(); panel.Visible=false; progress:clear(); adapter:snapshot()
eq(progress:read("defense").Known,false,"Hidden panel not treated as live progress")
panel.Visible=true
adapter:bind(function() return {Alive=false,GodStatus="unknown",Progress={defense=42},Source="bound fixture"} end)
s=adapter:snapshot(); eq(s.Alive,true,"Provider cannot spoof observed life state"); eq(s.GodStatus,nil)
eq(progress:read("defense").Value,42,"Bound source outranks automatic UI parsing")
adapter:bind(function() error("fixture failure") end)
eq(pcall(function() adapter:snapshot() end),true,"Provider failure does not crash GUI")
eq(adapter.Message:find("Ошибка",1,true)~=nil,true)
local modules={}
local function loadModule(path) modules[path]=modules[path] or dofile(path); return modules[path] end
local app=loadModule("main.lua").start(loadModule,manifest,{Destroy=function() end})
local function find(name) return assert(app.Gui:FindFirstChild(name,true),"Missing "..name) end
local function click(name) find(name).Activated:Fire() end
eq(app.Running,false); eq(app.Selected,"defense")
eq(app.Quests.defense~=nil and app.Quests.points~=nil and app.Quests.god~=nil,true,"All three quests instantiated")
eq(find("Title").Text,"TYCOON MASTERY")
eq(find("RunToggle").Text,"Начать наблюдение")
click("Quest_god"); eq(app.Selected,"god"); eq(app:Select("missing"),false)
click("RunToggle"); eq(app.Running,true)
eq(app.Views.defense.Value,12)
shown.Text="16 / 500"; heartbeat:Fire(1); eq(app.Views.defense.Value,16)
click("RunToggle"); shown.Text="17 / 500"; heartbeat:Fire(1)
eq(app.Views.defense.Value,16,"Paused observer does not poll")
click("RunToggle"); eq(app.Views.defense.Value,17)
click("Collapse"); eq(find("Body").Visible,false); eq(app.Running,true)
click("Collapse"); eq(find("Body").Visible,true)
viewport={X=320,Y=480}; find("SafeArea"):GetPropertyChangedSignal("AbsoluteSize"):Fire()
eq(find("UIScale").Scale<1,true,"Phone window scales to viewport")
eq(find("MasteryWindow").Position.X.Offset>=0,true)
app:BindGame(function() return {GodStatus=true,Progress={god=7},Source="verified fixture"} end)
eq(app.Views.god.Value,7); eq(app.Views.god.Status,"guide")
humanoid.Health=0; heartbeat:Fire(1); eq(app.Views.god.Status,"waiting")
local old=app
app=loadModule("main.lua").start(loadModule,manifest,{Destroy=function() end})
eq(old.Destroyed,true,"Repeated startup releases previous session")
eq(app.Running,false)
app:Destroy(); eq(aliveConnections(),0,"All app connections are released")
local previousHeartbeat=services.RunService.Heartbeat
services.RunService.Heartbeat={Connect=function() error("heartbeat fixture failure") end}
local reportDestroyed=false
local initialized=pcall(function()
    loadModule("main.lua").start(loadModule,manifest,{Destroy=function() reportDestroyed=true end})
end)
eq(initialized,false,"Failure after mounting GUI is reported")
eq(reportDestroyed,false,"Initialization cleanup keeps the loading error strip available")
eq(_G.SlapBattlesTycoonMastery,nil,"Failed session is removed")
eq(aliveConnections(),0,"Failed initialization cleans up GUI listeners")
services.RunService.Heartbeat=previousHeartbeat
adapter:Destroy()
Instance,Enum,UDim2,UDim,Color3=saved.Instance,saved.Enum,saved.UDim2,saved.UDim,saved.Color3
ColorSequence,ColorSequenceKeypoint,TweenInfo=saved.ColorSequence,saved.ColorSequenceKeypoint,saved.TweenInfo
game,typeof,warn=saved.game,saved.typeof,saved.warn
_G.SlapBattlesTycoonMastery=saved.session
print("PASS: "..count.." quest, counter, adapter, GUI and lifecycle checks")
return count
