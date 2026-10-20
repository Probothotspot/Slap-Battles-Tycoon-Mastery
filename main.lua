local Main={}
function Main.start(loadModule,manifest,diagnostics)
    local config=loadModule("config.lua")
    if config.PairMode==false then return loadModule("LegacyMain.lua").start(loadModule,manifest,diagnostics) end
    local Cleanup=loadModule("Cleanup.lua")
    local Protocol=loadModule("PairProtocol.lua")
    local Actions=loadModule("PairActions.lua")
    local Controller=loadModule("PairController.lua")
    local Gui=loadModule("PairGui.lua")
    local players=game:GetService("Players")
    local env=_G
    if type(getgenv)=="function" then local ok,v=pcall(getgenv); if ok and type(v)=="table" then env=v end end
    local key="SlapBattlesTycoonMastery"
    if type(env[key])=="table" and type(env[key].Destroy)=="function" then env[key]:Destroy() end
    local cleanup=Cleanup.new()
    local actions=Actions.new(players.LocalPlayer,Protocol)
    local app=Controller.new(actions,Protocol,players,players.LocalPlayer)
    local catalog=loadModule("QuestCatalog.lua")
    local Parser=loadModule("Progress.lua")
    local progress=Parser.new(catalog)
    local adapter=loadModule("Adapter.lua").new({Player=players.LocalPlayer,Progress=progress,Parser=Parser,Catalog=catalog})
    app.Progress=progress
    cleanup:add(function() adapter:Destroy() end)
    app.Version=manifest.version
    local stopController=app.Destroy
    function app:Destroy()
        if self.Destroyed then return end
        stopController(self); cleanup:Destroy()
        if env[key]==self then env[key]=nil end
    end
    env[key]=app
    local ok,err=pcall(function()
        app.Gui=Gui.mount(app,cleanup)
        local nextRead,nextStep=0,0
        cleanup:add(game:GetService("RunService").Heartbeat:Connect(function()
            local good,problem=pcall(function()
                actions:serviceInput()
                if os.clock()<nextStep then return end
                nextStep=os.clock()+.2
                app:step()
                if app.Running and app.Role=="Main" and os.clock()>=nextRead then
                    nextRead=os.clock()+1; adapter:snapshot()
                    local reading=progress:read("defense")
                    if reading.Known and not reading.Stale and reading.Value>=catalog.Quests.defense.Target then
                        app:stop("Quest 1 выполнен: подтверждено игровым счётчиком")
                    end
                end
            end)
            if not good then app:stop("Ошибка: "..tostring(problem)) end
        end))
        if diagnostics then cleanup:add(function() if app.Initialized then diagnostics:Destroy() end end) end
    end)
    if not ok then app:Destroy(); error("[TycoonMastery] "..tostring(err)) end
    app.Initialized=true; return app
end
return Main
