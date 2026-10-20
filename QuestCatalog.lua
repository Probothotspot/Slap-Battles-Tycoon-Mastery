-- Community reference snapshot, not a claim of access to current server rules.
return {Name="QuestCatalog",Ready=true,Checked="2026-10-20",LiveVerified=false,
    Source="https://roblox-slap-battles.fandom.com/wiki/Tycoon",
    Order={"defense","points","god"},Quests={
        defense={Id="defense",Title="Защита тайкуна",Target=500,Unit="ударов",
            Description="Ударять игроков рядом со своим тайкуном.",
            Hint="Перепроверь условия близости и улучшений на игровой панели."},
        points={Id="points",Title="Очки на главном острове",Target=15000,Unit="очков",
            Description="Накопить очки, находясь на главном острове.",
            Hint="Это общий прогресс квеста, а не только текущий баланс тайкуна."},
        god={Id="god",Title="Убийства в GOD STATUS",Target=200,Unit="убийств",
            Description="Убивать игроков при действующем GOD STATUS.",
            Hint="Исчезновение или смерть цели рядом сами по себе не подтверждают убийство."},
    }}
