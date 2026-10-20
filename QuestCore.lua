local C={Name="QuestCore",Ready=true}
function C.new(definition,evaluate)
    local self={Id=definition.Id,Definition=definition}
    function self:update(snapshot,progress)
        local status,message=evaluate(snapshot)
        local reading=progress:read(self.Id)
        if reading.Known and reading.Value>=definition.Target and not reading.Stale then
            status,message="shown_complete","На игровой панели показано выполнение"
        end
        self.View={Id=self.Id,Title=definition.Title,Target=definition.Target,Unit=definition.Unit,
            Status=status,Message=message,Hint=definition.Hint,Known=reading.Known,Value=reading.Value,
            Source=reading.Source,Stale=reading.Stale,Age=reading.Age,
            Fraction=reading.Known and math.min(1,reading.Value/definition.Target) or 0}
        return self.View
    end
    return self
end
return C
