-- Loader-only fixtures; real GUI/Main are exercised in tests.lua.
local fixtureSources={}
for _,path in ipairs({"loader.lua","manifest.lua","config.lua","Cleanup.lua","Logger.lua","Adapter.lua",
    "QuestCatalog.lua","Progress.lua","QuestCore.lua","QuestDefense.lua","QuestMainIsland.lua","QuestGodStatus.lua"}) do
    local file=assert(io.open(path,"rb")); fixtureSources[path]=file:read("*a"); file:close()
end
fixtureSources["Gui.lua"]=[=[return {mount=function()
    local gui=Instance.new("ScreenGui"); gui.Name="TycoonMasteryGUI"; gui.Enabled=true
    gui.Parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"); return gui
end}]=]
fixtureSources["main.lua"]=[=[return {start=function(loadModule,manifest,report)
    local env=getgenv()
    local old=env.SlapBattlesTycoonMastery; if old then old:Destroy() end
    for _,entry in ipairs(manifest.systems) do loadModule(entry.path) end
    local app={Version=manifest.version}
    env.SlapBattlesTycoonMastery=app
    function app:Destroy()
        if self.Destroyed then return end; self.Destroyed=true
        if self.Gui then self.Gui:Destroy(); report:Destroy() end
        if env.SlapBattlesTycoonMastery==self then env.SlapBattlesTycoonMastery=nil end
    end
    app.Gui=loadModule("Gui.lua").mount()
    return app
end}]=]
-- Local-only engine doubles: verify loading diagnostics without executing Roblox.
local realClock = os.clock
local sources = fixtureSources
local nativeLoad = load
local mainThread = coroutine.running()
local clock, workers, objects, downloads, settings, earlyZero
local signalNames = { InputBegan=true, InputEnded=true, InputChanged=true,
    WindowFocusReleased=true, Activated=true, Destroying=true, MessageOut=true }
local function signal()
    local s = { listeners={} }
    function s:Connect(fn)
        local c = { _kind="RBXScriptConnection", active=true, callback=fn }
        function c:Disconnect() self.active=false end
        table.insert(self.listeners,c)
        return c
    end
    function s:Fire(...)
        local list={table.unpack(self.listeners)}
        for _,c in ipairs(list) do if c.active then c.callback(...) end end
    end
    return s
end
local methods = {}
function methods:IsA(class) return self.ClassName==class or class=="Instance" end
function methods:Destroy()
    if self._destroyed then return end
    self._destroyed=true
    self.Destroying:Fire()
    for _,child in ipairs(objects) do if child.Parent==self then child:Destroy() end end
    self.Parent=nil
end
local meta = {
    __index=function(self,key)
        if methods[key] then return methods[key] end
        if signalNames[key] then
            self._signals[key]=self._signals[key] or signal()
            return self._signals[key]
        end
        return self._props[key]
    end,
    __newindex=function(self,key,value) self._props[key]=value end,
}
Instance={new=function(class)
    local obj=setmetatable({_kind="Instance",_props={ClassName=class},_signals={}},meta)
    table.insert(objects,obj)
    return obj
end}
typeof=function(value) return type(value)=="table" and value._kind or type(value) end
Vector2={new=function(x,y) return {X=x,Y=y} end}
UDim={new=function(s,o) return {Scale=s,Offset=o} end}
UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
Color3={fromRGB=function(r,g,b) return {r,g,b} end,new=function(r,g,b) return {r,g,b} end}
Enum=setmetatable({},{__index=function(self,k)
    local values=setmetatable({},{__index=function(_,name) return k.."."..name end})
    rawset(self,k,values)
    return values
end})
warn=function() end
getgenv=function() return _G end
os.clock=function() return clock end
task={}
function task.spawn(fn)
    local co=coroutine.create(fn)
    local ok,delay=coroutine.resume(co)
    assert(ok,delay)
    table.insert(workers,{thread=co,wake=clock+(delay or 0)})
    return co
end
function task.wait(duration)
    if coroutine.running()~=mainThread then return coroutine.yield(duration or 0.05) end
    if #downloads==0 then
        for _,o in ipairs(objects) do if o.Text=="loading modules 0/1" then earlyZero=true end end
        if settings.cancelEarly then
            settings.cancelEarly=false
            _G.SlapBattlesTycoonMasteryLoader:Destroy()
        end
    end
    clock=clock+(duration or 0.05)
    for _,w in ipairs(workers) do
        if coroutine.status(w.thread)=="suspended" and w.wake<=clock then
            local ok,delay=coroutine.resume(w.thread)
            assert(ok,delay)
            w.wake=clock+(delay or 0.05)
        end
    end
    return duration or 0.05
end
task.cancel=function(co) if coroutine.status(co)~="dead" then coroutine.close(co) end end
local log,playerGui
game={GetService=function(self,name)
    if name=="Players" then return {LocalPlayer={WaitForChild=function() return playerGui end}} end
    if name=="UserInputService" then return self.input end
    if name=="LogService" then return log end
    error("Unknown service "..name)
end}
function game:HttpGet(url)
    local path=url:match("/main/(.+)$")
    table.insert(downloads,path)
    if settings.network==path then error("HTTP 404 fixture") end
    if settings.timeout==path then while true do task.wait(100) end end
    local source=settings.overrides and settings.overrides[path] or sources[path]
    assert(source,"Missing fixture "..tostring(path))
    return source
end
local function reset(options)
    if _G.SlapBattlesTycoonMastery then _G.SlapBattlesTycoonMastery:Destroy() end
    if _G.SlapBattlesTycoonMasteryLoader then _G.SlapBattlesTycoonMasteryLoader:Destroy() end
    clock,workers,objects,downloads,settings,earlyZero=0,{},{},{},options or {},false
    log={MessageOut=signal()}
    game.input={InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal()}
    playerGui=Instance.new("PlayerGui")
    loadstring=nativeLoad
end
local function boot()
    return assert(nativeLoad(sources["loader.lua"],"@TycoonMastery/loader.lua"))()
end

local function stripGui()
    for _,o in ipairs(objects) do
        if o.Name=="TycoonMasteryLoadingGUI" and not o._destroyed then return o end
    end
end
local function stripLabel()
    local gui=stripGui()
    local count,label=0,nil
    for _,o in ipairs(objects) do
        if not o._destroyed and o.ClassName=="TextLabel" and o.Parent and o.Parent.Parent==gui then
            count,label=count+1,o
        end
    end
    assert(count==1,"Exactly one loading label must be visible to the player")
    return label
end
local function failed(options,detail)
    reset(options)
    local app,report=boot()
    assert(not app and report.State=="error" and report.Errors==1 and report.Completed==0)
    assert(report.Finished and not report.Destroyed and not report.Hidden)
    assert(stripLabel().Text=="error" and stripGui().Enabled~=false)
    if detail then assert(report.LastError:find(detail,1,true),report.LastError) end
    return report
end
reset()
local app,report=boot()
assert(app and app.Version=="0.2.0" and app.Gui.Parent and app.Gui.Enabled~=false)
assert(earlyZero and report.Completed==1 and report.Errors==0 and report.Warnings==0)
assert(report.State=="ready" and report.Finished and report.Hidden)
assert(stripLabel().Text=="loading modules 1/1" and stripGui().Enabled==false)
assert(#downloads==13)
log.MessageOut:Fire("unrelated error",Enum.MessageType.MessageError)
assert(report.State=="ready" and report.Hidden)
log.MessageOut:Fire("TycoonMastery/QuestDefense.lua: runtime fixture",Enum.MessageType.MessageError)
assert(report.State=="error" and report.Errors==1 and not report.Hidden)
assert(stripLabel().Text=="error" and stripGui().Enabled==true)
log.MessageOut:Fire("TycoonMastery/QuestDefense.lua: runtime fixture",Enum.MessageType.MessageError)
assert(report.Errors==1)
local nextApp,nextReport=boot()
assert(app.Destroyed and report.Destroyed and nextApp and nextReport.Hidden)
nextApp:Destroy();nextApp:Destroy()
assert(nextReport.Destroyed and _G.SlapBattlesTycoonMastery==nil)
print("PASS: one loading label, 0/1 before requests, 13 cached module downloads, visible main GUI before hiding, runtime error text and repeat-run cleanup")
failed({network="QuestDefense.lua"},"download")
failed({overrides={["QuestMainIsland.lua"]="return {"}},"compile")
failed({overrides={["Progress.lua"]="return true"}},"initialize")
failed({overrides={["Gui.lua"]="return {}"}},"mount")
failed({overrides={["manifest.lua"]="return {schemaVersion=99}"}},"invalid manifest")
failed({overrides={["Gui.lua"]="return {mount=function() error('mount fixture failure') end}"}},"mount fixture")
failed({overrides={["main.lua"]="return {start=function() return {Destroy=function() end} end}"}},"GUI is not visible")
failed({timeout="QuestDefense.lua"},"timeout")
assert(clock>=20 and clock<21)
print("PASS: network, syntax, wrong export, interface, manifest, GUI startup, missing GUI and timeout all show only error")
reset();loadstring=nil
local missing,compilerReport=boot()
assert(not missing and compilerReport.State=="error" and #downloads==0 and stripLabel().Text=="error")
reset({cancelEarly=true})
local cancelled=boot()
assert(not cancelled and #downloads==0 and _G.SlapBattlesTycoonMasteryLoader==nil)
print("PASS: unavailable compiler and cancellation")
reset()
os.clock=realClock
