local C={}
function C.new(actions,protocol,players,player,clock)
    clock=clock or os.clock
    local s={Role="Main",Quest1=false,Running=false,State="idle",Message="Укажи ник второго аккаунта",
        Peer=nil,PeerName="",Quest=nil,Attempts=0}
    local function phase(name,message,delay)
        s.State=name; s.Message=message; s.Since=clock(); s.Deadline=clock()+(delay or 15)
    end
    function s:stop(message)
        self.Running=false; self.State="idle"; self.Message=message or "Остановлено"
        actions:release()
        -- Remove the height signal immediately on Main stop. Do not toggle rock off.
        if self.Role=="Main" and self.ReturnCF then
            pcall(function() actions:teleport(self.ReturnCF) end)
        end
        self.ReturnCF=nil
    end
    function s:connect(name)
        self:stop(); self.PeerName=name
        self.Peer=protocol.player(players,name,player)
        self.Message=self.Peer and ("Найден игрок: "..self.Peer.Name.."; связь скриптов не подтверждена") or "Players Not Found"
        return self.Peer~=nil
    end
    function s:start()
        if self.Destroyed then return false end
        if not self.Peer or self.Peer.Parent~=players then self.Message="Players Not Found"; return false end
        if self.Role=="Main" and not self.Quest1 then self.Message="Включи Quest 1"; return false end
        local c,r=actions:body(); if not r then self.Message="Персонаж недоступен"; return false end
        if self.Role=="Main" and actions:glove()~="Tycoon" then self.Message="Экипируй Tycoon на Main"; return false end
        self.Character=c; self.Running=true; self.Attempts=0; self.StableSince=nil
        self.ReturnCF=nil; self.Quest=nil; self.Target=nil
        self.EquipSent=nil; self.LastPortal=nil; self.SignalQuest=nil; self.SignalSince=nil
        if self.Role=="Main" then
            if actions:arena() then phase("spawn1","E: подготовка Tycoon")
            else phase("enterMain","Вход Main через красный портал") end
        else phase("equipAlt","Экипировка Diamond") end
        return true
    end
    function s:step()
        actions:serviceInput()
        if not self.Running then return end
        if not self.Peer or self.Peer.Parent~=players then self:stop("Players Not Found"); return end
        local c,r=actions:body()
        if not r or c~=self.Character then self:stop("Персонаж погиб или сменился"); return end
        if self.Role=="Main" and actions:glove()~="Tycoon" then self:stop("Main сменил перчатку"); return end
        if self.Role=="Alt" and self.State~="equipAlt" and actions:glove()~="Diamond" then
            self:stop("Alt сменил Diamond"); return
        end
        local now=clock()
        if self.State~="hold" and self.State~="waitSignal" and now>self.Deadline then
            self:stop("Таймаут: "..self.Message); return
        end
        if self.State=="equipAlt" then
            if actions:glove()=="Diamond" then
                if actions:arena() then phase("waitSignal","Ожидание Main на Y=10000")
                else phase("enterAlt","Вход Alt через красный портал") end
            elseif not self.EquipSent then actions:equipDiamond(); self.EquipSent=true end
        elseif self.State=="enterMain" or self.State=="enterAlt" then
            if actions:arena() then
                if self.Role=="Main" then phase("spawn1","E: подготовка Tycoon")
                else phase("waitSignal","Ожидание Main на Y=10000") end
            elseif not self.LastPortal or now-self.LastPortal>=2 then
                actions:teleport(actions:portal().CFrame); self.LastPortal=now
            end
        elseif self.State=="spawn1" then
            self.PreviousTycoon=protocol.tycoon(workspace,player.Name)
            actions:pressE(); phase("spawn2","Ожидание второй E",5)
        elseif self.State=="spawn2" and now-self.Since>=1 then
            actions:pressE(); phase("waitTycoon","Ожидание нового Tycoon",15)
        elseif self.State=="waitTycoon" then
            local tycoon=protocol.tycoon(workspace,player.Name)
            if tycoon and tycoon~=self.PreviousTycoon and actions:destruct(player) then
                self.Tycoon=tycoon; self.ReturnCF=r.CFrame
                actions:platform(1); phase("hold","Main на Y=10000. Защита кнопки не выполняет Quest 1")
            end
        elseif self.State=="waitSignal" then
            local _,peerRoot=actions:body(self.Peer)
            local q=peerRoot and protocol.questAt(peerRoot.Position.Y)
            if q~=self.SignalQuest then self.SignalQuest=q; self.SignalSince=now end
            if q and now-(self.SignalSince or now)>=1.5 then
                if q~=1 then self:stop("Quest "..q.." пока не реализован"); return end
                self.Quest=1; phase("positionAlt","Поиск Destruct у Main",20)
            end
        elseif self.State=="positionAlt" then
            local part=actions:destruct(self.Peer)
            if part then
                local rock=actions:rock()
                if rock==true then self:stop("Alt уже камень: сначала выйди из камня вручную"); return end
                self.Target=part; actions:teleport(CFrame.new(part.Position))
                phase("rockAlt","Проверка позиции перед E",8)
            end
        elseif self.State=="rockAlt" then
            if not self.Target or not self.Target:IsDescendantOf(workspace) then self:stop("Destruct исчез"); return end
            if (r.Position-self.Target.Position).Magnitude>4 then
                self:stop("Коллизия вытолкнула Alt из кнопки; E не отправлена"); return
            end
            if now-self.Since>=.5 then
                if actions:rock()==true then phase("hold","Камень подтверждён. Проверка позиции")
                else actions:pressE(); self.Attempts=self.Attempts+1
                    phase("verifyRock","Проверка превращения в камень",20) end
            end
        elseif self.State=="verifyRock" then
            local rock=actions:rock()
            if rock==true then phase("hold","Камень подтверждён. Защита кнопки активна")
            elseif now-self.Since>=16 then
                -- Retry only with explicit false. Unknown may mean a marker mismatch.
                if rock==false and self.Attempts<3 then phase("rockAlt","Повтор способности")
                else self:stop("Камень не подтверждён. Нужен точный маркер; повторы E остановлены") end
            end
        elseif self.State=="hold" then
            if self.Role=="Main" then
                if not self.Tycoon or not self.Tycoon:IsDescendantOf(workspace) then self:stop("Тайкун исчез"); return end
                if protocol.questAt(r.Position.Y)~=1 then self:stop("Main покинул сигнальную платформу"); return end
                self.Message="Main: ожидание. Quest 1 требует ударов; счётчик не подменяется"
            else
                local _,peerRoot=actions:body(self.Peer)
                if not peerRoot or protocol.questAt(peerRoot.Position.Y)~=self.Quest then
                    self:stop("Сигнал Main потерян. Камень не выключен"); return
                end
                local part=actions:destruct(self.Peer)
                if not part or part~=self.Target then self:stop("Кнопка исчезла или тайкун сменился"); return end
                local rock=actions:rock()
                if rock~=true or (r.Position-part.Position).Magnitude>4 then
                    self:stop("Защита не подтверждена: камень или позиция изменились"); return
                end
            end
        end
    end
    function s:Destroy() self:stop(); self.Destroyed=true; actions:Destroy() end
    return s
end
return C
