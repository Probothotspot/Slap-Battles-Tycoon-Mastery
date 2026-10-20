-- Height is a lossy one-way signal, not an acknowledgement from the other script.
local P={Name="PairProtocol",Ready=true}
function P.questAt(y)
    if type(y)~="number" or y~=y then return nil end
    for i=1,3 do if math.abs(y-i*10000)<=12 then return i end end
end
function P.player(players,name,localPlayer)
    name=tostring(name or ""):match("^%s*(.-)%s*$"):gsub("^@",""):lower()
    if name=="" then return nil end
    for _,p in ipairs(players:GetPlayers()) do
        if p~=localPlayer and p.Name:lower()==name then return p end
    end
end
function P.tycoon(world,name)
    local expected=string.char(195,133).."Tycoon"..name
    local found
    for _,o in ipairs(world:GetChildren()) do
        if o.Name==expected and (o:IsA("Model") or o:IsA("Folder")) then
            if found then return nil,"Несколько тайкунов владельца" end
            found=o
        end
    end
    return found,"Тайкун не найден"
end
return P
