local P={Name="Progress",Ready=true}
local function numeric(text)
    local s=text:lower():gsub("%s","")
    local k=s:sub(-1)=="k"
    if k then s=s:sub(1,-2) end
    if not k and s:find(",",1,true) then
        if s:find(",,",1,true) or s:sub(1,1)=="," or s:sub(-1)=="," then return nil end
        local i=0
        for group in s:gmatch("[^,]+") do
            i=i+1
            if not group:match("^%d+$") or (i==1 and (#group<1 or #group>3)) or (i>1 and #group~=3) then return nil end
        end
        s=s:gsub(",","")
    elseif k then s=s:gsub(",",".") end
    local n=tonumber(s)
    if n and k then n=n*1000 end
    if n and n==n and n>=0 and n<=1e9 and math.abs(n-math.floor(n+.5))<.001 then return math.floor(n+.5) end
end
function P.parse(text,target)
    if type(text)~="string" or #text>2000 then return nil end
    text=text:gsub("<[^>]*>","")
    for first,current,total,last in text:gmatch("()([%d][%d,%.]*[kK]?)%s*/%s*([%d][%d,%.]*[kK]?)()") do
        local a,b=numeric(current),numeric(total)
        local prefix=text:sub(1,first-1)
        local before,after=text:sub(first-1,first-1),text:sub(last,last)
        local boundary=not before:match("[%w%+%-%.,]") and not after:match("[%w%.,]") and not prefix:match("%d%s+$")
        if boundary and a and b==target then return a end
    end
end
function P.new(catalog,clock)
    clock=clock or os.clock
    local self={Values={}}
    function self:set(id,value,source)
        if not catalog.Quests[id] or type(value)~="number" or value~=value or value<0 or value>1e9
            or value~=math.floor(value) or type(source)~="string" or #source==0 or #source>120 then return false end
        -- Absolute current readings, not increments or a high-water mark: the
        -- game may legitimately correct a counter or change the active profile.
        self.Values[id]={Value=value,Source=source,Time=clock()}; return true
    end
    function self:read(id)
        local r=self.Values[id]
        if not r then return {Known=false} end
        return {Known=true,Value=r.Value,Source=r.Source,Age=math.max(0,clock()-r.Time),Stale=clock()-r.Time>10}
    end
    function self:clear() self.Values={} end
    return self
end
return P
