local A={}
function A.new(player,protocol)
    local self={Player=player,Protocol=protocol,Platforms={}}
    function self:body(p)
        local c=(p or player).Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if h and h.Health>0 and r and r:IsA("BasePart") then return c,r,h end
    end
    function self:glove()
        local stats=player:FindFirstChild("leaderstats")
        local value=stats and stats:FindFirstChild("Glove")
        if value and value:IsA("StringValue") then return value.Value end
        local c=player.Character
        local tool=c and c:FindFirstChildOfClass("Tool")
        if tool then return tool.Name end
    end
    function self:teleport(cf)
        local c,r=self:body(); assert(r,"Персонаж недоступен")
        c:PivotTo(cf*r.CFrame:ToObjectSpace(c:GetPivot()))
        r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
    end
    function self:portal()
        local lobby=workspace:FindFirstChild("Lobby")
        local p=lobby and lobby:FindFirstChild("Teleport1")
        assert(p and p:IsA("BasePart"),"Не найден Workspace.Lobby.Teleport1")
        return p
    end
    function self:arena()
        local c,r=self:body(); if not r then return false end
        -- Same height bounds as the existing Arena Bot. Height signal platforms
        -- are deliberately excluded from arena entry confirmation.
        return r.Position.Y<300
    end
    function self:equipDiamond()
        if self:glove()=="Diamond" then return end
        local lobby=workspace:FindFirstChild("Lobby")
        local stand=lobby and lobby:FindFirstChild("Diamond")
        local detector=stand and stand:FindFirstChildWhichIsA("ClickDetector",true)
        assert(detector,"Не найдена стойка Diamond. Экипируй Diamond вручную")
        assert(type(fireclickdetector)=="function","Нет fireclickdetector. Экипируй Diamond вручную")
        fireclickdetector(detector)
    end
    function self:pressE()
        local input=game:GetService("VirtualInputManager")
        self.Held=input
        local ok,err=pcall(function() input:SendKeyEvent(true,Enum.KeyCode.E,false,game) end)
        if not ok then self:release(); error("Ввод E недоступен: "..tostring(err)) end
        self.ReleaseAt=os.clock()+.08
    end
    function self:release()
        local input=self.Held; self.Held=nil
        if input then pcall(function() input:SendKeyEvent(false,Enum.KeyCode.E,false,game) end) end
    end
    function self:serviceInput()
        if self.Held and os.clock()>=(self.ReleaseAt or 0) then self:release() end
    end
    function self:platform(quest)
        local p=self.Platforms[quest]
        if not p or not p.Parent then
            p=Instance.new("Part"); p.Name="TycoonMasteryLocalPlatform"..quest
            p.Size=Vector3.new(48,2,48); p.Anchored=true; p.CanCollide=true
            p.Color=Color3.fromRGB(108,61,178); p.Material=Enum.Material.Neon
            p.Position=Vector3.new(0,quest*10000-4,0); p.Parent=workspace
            self.Platforms[quest]=p
        end
        self:teleport(CFrame.new(0,quest*10000,0))
    end
    function self:destruct(owner)
        local tycoon,err=protocol.tycoon(workspace,owner.Name)
        if not tycoon then return nil,err end
        local d=tycoon:FindFirstChild("Destruct")
        if not d or not d:IsA("BasePart") then return nil,"Destruct отсутствует" end
        return d
    end
    function self:rock()
        local c=self:body(); if not c then return nil end
        -- Only positive replicated markers are accepted. Anchored alone is not proof.
        for _,key in ipairs({"IsRock","Rocked","RockMode","DiamondActive"}) do
            local v=c:GetAttribute(key)
            if type(v)=="boolean" then return v,key end
            local value=c:FindFirstChild(key)
            if value and value:IsA("BoolValue") then return value.Value,key end
        end
        for _,o in ipairs(c:GetDescendants()) do
            local name=o.Name:lower()
            if o:IsA("BasePart") and (name=="rock" or name=="diamondrock")
                and o.Transparency<1 and o.CanCollide then return true,o.Name end
        end
        return nil,"Маркер камня неизвестен"
    end
    function self:Destroy()
        self:release()
        for _,p in pairs(self.Platforms) do p:Destroy() end
        self.Platforms={}
    end
    return self
end
return A
