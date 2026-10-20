local Main={}
function Main.start(loadModule,manifest,diagnostics)
    local config=loadModule("config.lua")
    local Cleanup,Gui,Adapter=loadModule("Cleanup.lua"),loadModule("Gui.lua"),loadModule("Adapter.lua")
    local modules={}
    for _,entry in ipairs(manifest.systems) do modules[entry.name]=loadModule(entry.path) end
    local env=_G
    if type(getgenv)=="function" then local ok,v=pcall(getgenv); if ok and type(v)=="table" then env=v end end
    local key="SlapBattlesTycoonMastery"
    if type(env[key])=="table" and type(env[key].Destroy)=="function" then env[key]:Destroy() end
    local cleanup=Cleanup.new()
    local catalog=modules.QuestCatalog
    local progress=modules.Progress.new(catalog)
    local adapter=Adapter.new({Player=game:GetService("Players").LocalPlayer,Progress=progress,Parser=modules.Progress,Catalog=catalog})
    local app={Version=manifest.version,Config=config,Catalog=catalog,Progress=progress,Adapter=adapter,
        Running=false,Destroyed=false,Selected="defense",Views={},Quests={},Status="paused"}
    local context={Catalog=catalog,Core=modules.QuestCore}
    for _,name in ipairs({"QuestDefense","QuestMainIsland","QuestGodStatus"}) do
        local quest=modules[name].new(context); app.Quests[quest.Id]=quest
    end
    local function refresh()
        app.Snapshot=adapter:snapshot()
        for _,id in ipairs(catalog.Order) do app.Views[id]=app.Quests[id]:update(app.Snapshot,progress) end
        if app.Gui then Gui.update(app.Gui,app) end
    end
    local function failure(err)
        app.Running=false; app.Status="error"; app.LastError=tostring(err)
        if diagnostics and diagnostics.Fail then diagnostics:Fail(err) end
        if app.Gui then pcall(Gui.update,app.Gui,app) end
    end
    function app:Start()
        if self.Destroyed or self.Status=="error" then return false end
        self.Running,self.Status=true,"running"
        local ok,err=pcall(refresh)
        if not ok then failure(err) end
        return ok
    end
    function app:Stop()
        if self.Destroyed then return end
        self.Running=false
        if self.Status~="error" then self.Status="paused" end
        if self.Gui then Gui.update(self.Gui,self) end
    end
    function app:Select(id)
        if self.Destroyed or not self.Quests[id] then return false end
        self.Selected=id
        if self.Gui then Gui.update(self.Gui,self) end
        return true
    end
    -- The provider must be written against inspected live objects. It can return
    -- OwnedTycoon/EnemyNearTycoon/OnMainIsland/GodStatus booleans and absolute
    -- Progress={defense=...,points=...,god=...}, plus a non-empty Source string.
    function app:BindGame(provider)
        if self.Destroyed then return false end
        adapter:bind(provider)
        local ok,err=pcall(refresh); if not ok then failure(err) end
        return ok
    end
    function app:Destroy()
        if self.Destroyed then return end
        self.Running,self.Destroyed=false,true
        cleanup:Destroy(); adapter:Destroy()
        if env[key]==self then env[key]=nil end
    end
    env[key]=app
    local ok,err=pcall(function()
        refresh()
        app.Gui=Gui.mount({App=app,Config=config,Cleanup=cleanup,Manifest=manifest})
        if diagnostics then cleanup:add(function() if app.Initialized then diagnostics:Destroy() end end) end
        local elapsed=0
        cleanup:add(game:GetService("RunService").Heartbeat:Connect(function(dt)
            if app.Destroyed or not app.Running then return end
            elapsed=elapsed+dt; if elapsed<config.PollInterval then return end; elapsed=0
            local good,problem=pcall(refresh); if not good then failure(problem) end
        end))
        if config.AutoStart then app:Start() end
    end)
    if not ok then app:Destroy(); error("[TycoonMastery] Initialization failed: "..tostring(err)) end
    app.Initialized=true
    return app
end
return Main
