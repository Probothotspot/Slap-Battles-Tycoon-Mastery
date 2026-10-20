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
        or k=="FocusLost" or k=="CharacterAdded" or k=="Died" then
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
local function eq(a,b,why) count=count+1; assert(a==b,(why or ("Mismatch #"..count))..": "..tostring(a).." ~= "..tostring(b)) end
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


function methods:GetAttribute(k) return self._attributes and self._attributes[k] end
function methods:IsDescendantOf(parent)
 local p=self.Parent;while p do if p==parent then return true end;p=p.Parent end;return false
end
function methods:FindFirstChildWhichIsA(class,recursive)
 for _,o in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do if o:IsA(class) then return o end end
end
workspace=Instance.new("Folder")
local P=dofile("PairProtocol.lua")
local a=dofile("PairActions.lua").new(player,P)
player.Name="MainUser"
eq(a:rock(),nil)
character._attributes={IsRock=false};eq(a:rock(),false)
character._attributes.IsRock=true;eq(a:rock(),true)
character._attributes={}
local rock=Instance.new("Part");rock.Name="Rock";rock.Transparency=0;rock.CanCollide=true;rock.Parent=character
eq(a:rock(),true);rock.Transparency=1;eq(a:rock(),nil);rock:Destroy()
root.Anchored=true;eq(a:rock(),nil)
local glove=Instance.new("StringValue");glove.Name="Glove";glove.Value="Diamond";glove.Parent=board
eq(a:glove(),"Diamond")
local tycoon=Instance.new("Model");tycoon.Name="ÅTycoonMainUser";tycoon.Parent=workspace
local other=Instance.new("Model");other.Name="ÅTycoonOther";other.Parent=workspace
local destruct=Instance.new("Part");destruct.Name="Destruct";destruct.Parent=tycoon
eq(a:destruct(player),destruct)
destruct:Destroy();eq(a:destruct(player),nil)
local calls={}
services.VirtualInputManager={SendKeyEvent=function(_,down) table.insert(calls,down) end}
Enum.KeyCode={E="E"}
a:pressE();eq(calls[1],true);a:release();eq(calls[2],false);a:release();eq(#calls,2)
humanoid.Health=0;eq(a:body(),nil);humanoid.Health=100
local lobby=Instance.new("Folder");lobby.Name="Lobby";lobby.Parent=workspace
local portal=Instance.new("Part");portal.Name="Teleport1";portal.Parent=lobby
eq(a:portal(),portal)
root.Position.Y=350;eq(a:arena(),false);root.Position.Y=0;eq(a:arena(),true)
a:Destroy();eq(a.Held,nil)
print("PASS: "..count.." actual action ownership, rock evidence, input release and arena assertions")
