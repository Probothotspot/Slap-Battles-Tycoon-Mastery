local M={Name="QuestGodStatus",Ready=true}
function M.new(context)
    return context.Core.new(context.Catalog.Quests.god,function(s)
        if not s.Alive then return "waiting","Ожидание живого персонажа" end
        if s.Glove~="Tycoon" then return "equip","Экипируй Tycoon" end
        if s.GodStatus==nil then return "unbound","Источник действующего GOD STATUS пока не привязан" end
        if not s.GodStatus then return "upgrade","Развивай тайкун до GOD STATUS" end
        return "guide","GOD STATUS активен: играй и проверяй прогресс убийств"
    end)
end
return M
