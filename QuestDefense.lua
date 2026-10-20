local M={Name="QuestDefense",Ready=true}
function M.new(context)
    return context.Core.new(context.Catalog.Quests.defense,function(s)
        if not s.Alive then return "waiting","Ожидание живого персонажа" end
        if s.Glove~="Tycoon" then return "equip","Экипируй Tycoon" end
        if s.OwnedTycoon==nil then return "unbound","Объект своего тайкуна пока не привязан" end
        if not s.OwnedTycoon then return "build","Размести свой тайкун" end
        if s.EnemyNearTycoon==nil then return "unbound","Нужна проверенная область защиты тайкуна" end
        return "guide",s.EnemyNearTycoon and "Противник рядом: защищай тайкун" or "Ожидание противника рядом с тайкуном"
    end)
end
return M
