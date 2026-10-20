-- Read-only adapter. No assumed model names, remote events or local success counters.
local A={Name="Adapter",Ready=true}
local function text(item)
    if item:IsA("TextLabel") or item:IsA("TextButton") then return tostring(item.Text or ""):sub(1,2000) end
    return ""
end
local function visible(item)
    local p=item
    while p do
        if p.Name=="TycoonMasteryGUI" then return false end
        if p:IsA("GuiObject") and not p.Visible then return false end
        if p:IsA("ScreenGui") and not p.Enabled then return false end
        p=p.Parent
    end
    return true
end
local function scope(item)
    local parts,master,tycoon={},false,false
    local p=item
    for _=1,6 do
        if not p then break end
        local name=string.lower(p.Name)
        if name:find("master",1,true) then master=true end
        if name:find("tycoon",1,true) then tycoon=true end
        parts[#parts+1]=text(p)
        for i,child in ipairs(p:GetChildren()) do
            if i>32 then break end
            local value=text(child)
            if string.lower(value):find("tycoon",1,true) then tycoon=true end
            parts[#parts+1]=value
        end
        p=p.Parent
    end
    return master and tycoon,table.concat(parts," "):lower()
end
function A.new(context)
    local player,progress,parser,catalog=context.Player,context.Progress,context.Parser,context.Catalog
    local self={Message="Открой игровую панель Tycoon Mastery",ScanLimit=1000}
    function self:bind(provider)
        assert(provider==nil or type(provider)=="function","Provider must be a function or nil")
        self.Provider=provider; progress:clear()
    end
    function self:snapshot()
        local character=player.Character
        local h=character and character:FindFirstChildOfClass("Humanoid")
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local tool=character and character:FindFirstChildOfClass("Tool")
        local s={Alive=h~=nil and h.Health>0 and root~=nil,Glove=tool and tool.Name}
        local authoritative={}
        if self.Provider then
            local ok,data=pcall(self.Provider)
            if ok and type(data)=="table" then
                for _,key in ipairs({"OwnedTycoon","EnemyNearTycoon","OnMainIsland","GodStatus"}) do
                    if type(data[key])=="boolean" then s[key]=data[key] end
                end
                if type(data.Progress)=="table" and type(data.Source)=="string" then
                    for id,value in pairs(data.Progress) do
                        if progress:set(id,value,data.Source) then authoritative[id]=true end
                    end
                end
                self.Message="Привязанный игровой адаптер"
            else self.Message="Ошибка игрового адаптера; неподтверждённые условия неизвестны" end
        end
        local gui=player:FindFirstChildOfClass("PlayerGui")
        local found,conflicts={},{}
        if gui then
            for i,item in ipairs(gui:GetDescendants()) do
                if i>self.ScanLimit then break end
                local value=text(item)
                if value:find("/",1,true) and visible(item) then
                    local scoped,description=scope(item)
                    if scoped then
                        for id,def in pairs(catalog.Quests) do
                            local n=parser.parse(value,def.Target)
                            local matches=(id=="defense" and (description:find("defend",1,true) or description:find("slap",1,true)))
                                or (id=="points" and description:find("main island",1,true))
                                or (id=="god" and description:find("god status",1,true))
                            if n and matches then
                                if found[id]~=nil and found[id]~=n then conflicts[id]=true end
                                found[id]=n
                            end
                        end
                    end
                end
            end
        end
        local any=false
        for id,value in pairs(found) do
            if not conflicts[id] and not authoritative[id] then progress:set(id,value,"Панель Tycoon Mastery"); any=true end
        end
        if not self.Provider then self.Message=any and "Прочитан видимый интерфейс Tycoon Mastery" or "Открой игровую панель Tycoon Mastery; счётчики пока не прочитаны" end
        return s
    end
    function self:Destroy() self.Provider=nil end
    return self
end
return A
