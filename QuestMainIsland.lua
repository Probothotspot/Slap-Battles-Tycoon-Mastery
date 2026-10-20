local M={Name="QuestMainIsland",Ready=true}
function M.new(context)
    return context.Core.new(context.Catalog.Quests.points,function(s)
        if not s.Alive then return "waiting","Ожидание живого персонажа" end
        if s.Glove~="Tycoon" then return "equip","Экипируй Tycoon" end
        if s.OnMainIsland==nil then return "unbound","Область главного острова пока не привязана" end
        if not s.OnMainIsland then return "move","Перейди на главный остров" end
        return "guide","Зарабатывай очки и сверяй счётчик квеста"
    end)
end
return M
