local Z_vision_missWarning={}
local v1={}

-- ============================================================================
-- Z Vision Miss Warning  (por: Mayfail)
-- Upgrade: ping no minimapa, alertas HUD, detecção de ameaça
-- ============================================================================

-- ── Helpers ─────────────────────────────────────────────────────────────────
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function getScreenSize()
    local ok, s = pcall(Render.GetScreenSize or Render.ScreenSize)
    if ok and s then return s end
    return Vec2(1920, 1080)
end

local function renderTextShadow(font, size, text, pos, color, shadowColor)
    shadowColor = shadowColor or Color(0,0,0,180)
    pcall(Render.Text, font, size, text, Vec2(pos.x+1, pos.y+1), shadowColor)
    pcall(Render.Text, font, size, text, pos, color)
end

local function filledRect(x, y, w, h, col, rounding)
    rounding = rounding or 0
    pcall(Render.FilledRect, Vec2(x,y), Vec2(x+w, y+h), col, rounding)
end

local function outlineRect(x, y, w, h, col, rounding, thickness)
    rounding = rounding or 0; thickness = thickness or 1
    if Render.OutlineRect then
        pcall(Render.OutlineRect, Vec2(x,y), Vec2(x+w, y+h), col, rounding, thickness)
    elseif Render.Rect then
        pcall(Render.Rect, Vec2(x,y), Vec2(x+w, y+h), col, rounding, nil, thickness)
    end
end

local function getTextSizeEst(font, size, text)
    if Render.GetTextSize then
        local ok, v = pcall(Render.GetTextSize, font, text)
        if ok and v then return v end
    end
    return Vec2(math.floor(#tostring(text) * (size * 0.55)), size)
end

-- ── Ping no minimapa ────────────────────────────────────────────────────────
local function pingDangerAt(pos)
    if not pos or type(MiniMap) ~= "table" or type(MiniMap.Ping) ~= "function" then return false end
    local pingType = Enum and Enum.PingType and (Enum.PingType.DANGER or Enum.PingType.DEFAULT) or nil
    local ok = pcall(MiniMap.Ping, pos, pingType)
    if ok then return true end
    ok = pcall(MiniMap.Ping, pos)
    return ok
end

-- ── Cores por severidade ────────────────────────────────────────────────────
local SEV_HIGH, SEV_MED, SEV_LOW = 3, 2, 1

local function severityColors(sev, alphaMul)
    alphaMul = alphaMul or 1.0
    if sev >= SEV_HIGH then
        return Color(245,90,90, math.floor(240*alphaMul)), Color(90,15,15, math.floor(180*alphaMul))
    elseif sev >= SEV_MED then
        return Color(255,170,60, math.floor(235*alphaMul)), Color(90,50,10, math.floor(170*alphaMul))
    end
    return Color(255,225,90, math.floor(230*alphaMul)), Color(90,80,20, math.floor(160*alphaMul))
end

-- ── HUD Alert state ─────────────────────────────────────────────────────────
local hudAlerts = {}
local nextAlertId = 0
local MAX_HUD_ALERTS = 4
local ALERT_DURATION = 5.0  -- segundos
local lastPingTime = -999
local PING_COOLDOWN = 8.0   -- segundos entre pings
local perHeroPingTime = {}   -- [heroName] = lastPingAt

local function pruneAlerts(now)
    local keep = {}
    for i = 1, #hudAlerts do
        if hudAlerts[i] and hudAlerts[i].expiresAt > now then
            keep[#keep+1] = hudAlerts[i]
        end
    end
    hudAlerts = keep
end

local function addHudAlert(heroName, heroIcon, severity, text, now)
    nextAlertId = nextAlertId + 1
    table.insert(hudAlerts, 1, {
        id       = nextAlertId,
        heroName = heroName,
        heroIcon = heroIcon,
        severity = severity,
        text     = text,
        expiresAt = now + ALERT_DURATION,
        createdAt = now,
    })
    while #hudAlerts > MAX_HUD_ALERTS do
        table.remove(hudAlerts)
    end
end

-- ── Cache de torres aliadas ──────────────────────────────────────────────────
local towerCache = { t = -999, towers = {} }
local function getAlliedTowers(allyTeamNum, now)
    if now - towerCache.t < 2.0 then return towerCache.towers end
    towerCache.t = now
    towerCache.towers = {}
    local allNPCs = NPCs and NPCs.GetAll and NPCs.GetAll() or {}
    for _, npc in ipairs(allNPCs) do
        if npc and Entity.IsAlive(npc) and Entity.GetTeamNum(npc) == allyTeamNum then
            local name = NPC.GetUnitName(npc) or ""
            if name:find("tower") then
                towerCache.towers[#towerCache.towers+1] = Entity.GetAbsOrigin(npc)
            end
        end
    end
    return towerCache.towers
end

-- ── Classificar ameaça simplificada ─────────────────────────────────────────
-- Retorna severity (1-3) ou nil se não há ameaça relevante perto de um aliado
local function classifyMissNearAlly(enemyEntry, predictPos, ally, now)
    if not ally or not Entity.IsAlive(ally) then return nil end
    if Entity.IsSameTeam(Heroes.GetLocal(), ally) == false then return nil end -- só aliados
    -- Se o aliado sou eu mesmo, pular
    if ally == Heroes.GetLocal() then return nil end

    local allyPos = Entity.GetAbsOrigin(ally)
    if not allyPos or not predictPos then return nil end

    local dist = (predictPos - allyPos):Length2D()
    local maxDist = v1.threatRadius and v1.threatRadius:Get() or 2500
    if dist > maxDist then return nil end  -- longe demais

    -- Verificar se tem tower aliada perto do ally
    local underTower = false
    local allyTeam = Entity.GetTeamNum(ally)
    local towers = getAlliedTowers(allyTeam, now)
    for _, tPos in ipairs(towers) do
        if (tPos - allyPos):Length2D() < 900 then underTower = true; break end
    end

    -- Contar inimigos perto do aliado
    local enemyCount = 0
    local allHeroes = Heroes.GetAll()
    for _, h in ipairs(allHeroes) do
        if h and Entity.IsAlive(h) and not Entity.IsSameTeam(ally, h) and NPC.IsVisible(h) then
            local d = (Entity.GetAbsOrigin(h) - allyPos):Length2D()
            if d < 1600 then enemyCount = enemyCount + 1 end
        end
    end

    -- Verificar HP baixo
    local allyHp = Entity.GetHealth(ally) / math.max(1, Entity.GetMaxHealth(ally))

    -- Classificação
    if underTower and enemyCount >= 1 then
        -- Dive
        if enemyCount >= 2 or allyHp < 0.4 then return SEV_HIGH, "DIVE" end
        return SEV_MED, "DIVE"
    end

    if enemyCount >= 2 then
        -- Gank
        if enemyCount >= 3 or allyHp < 0.35 then return SEV_HIGH, "GANK" end
        return SEV_MED, "GANK"
    end

    -- Inimigo sumido se aproximando de aliado com hp baixo
    if dist < 1800 and allyHp < 0.5 then
        return SEV_LOW, "PERIGO"
    end

    -- Inimigo muito perto
    if dist < 1200 then
        return SEV_LOW, "PERTO"
    end

    return nil
end

-- ── Desenhar alertas HUD ────────────────────────────────────────────────────
local function drawHudAlerts(now, font, fontSmall)
    if #hudAlerts == 0 then return end
    fontSmall = fontSmall or font
    if not font then return end

    local screen = getScreenSize()
    local baseX = (screen.x or 1920) - 24
    local baseY = 80
    local rowH = 44
    local gap = 8
    local padX = 10
    local padY = 6

    for i = 1, #hudAlerts do
        local a = hudAlerts[i]
        if a then
            local badge = a.text or "ALERTA"
            local title = a.heroName or "Inimigo"
            local timeLeft = math.max(0, a.expiresAt - now)
            local timeText = string.format("%.1fs", timeLeft)
            local relLife = clamp(timeLeft / ALERT_DURATION, 0, 1)
            local lifeFade = clamp(timeLeft / 0.35, 0, 1)

            -- Calcular tamanhos
            local badgeSize = getTextSizeEst(fontSmall, 12, badge)
            local titleSize = getTextSizeEst(font, 14, title)
            local timeSize = getTextSizeEst(fontSmall, 12, timeText)
            local badgeW = math.max(50, badgeSize.x + 12)
            local badgeH = 18
            local width = math.max(220, badgeW + 8 + titleSize.x + 8 + timeSize.x + padX*2)
            width = math.min(width, math.floor(screen.x * 0.38))

            local x = baseX - width
            local y = baseY + (i-1) * (rowH + gap)

            local accentColor, borderGlow = severityColors(a.severity or SEV_LOW, clamp(lifeFade+0.25, 0.25, 1))
            local badgeBg = severityColors(a.severity or SEV_LOW, clamp(0.22 + relLife*0.45, 0.22, 0.7))
            local bgColor = Color(12,14,18, math.floor(185 * (0.35 + relLife*0.65)))
            local shadowCol = Color(0,0,0, math.floor(170 * clamp(lifeFade+0.2, 0.2, 1)))
            local titleCol = Color(242,247,252, math.floor(245 * clamp(lifeFade+0.35, 0.35, 1)))
            local badgeTextCol = Color(255,255,255, math.floor(230 * clamp(lifeFade+0.3, 0.3, 1)))
            local timeCol = Color(220,230,240, math.floor(200 * clamp(lifeFade+0.3, 0.3, 1)))

            -- Fundo + bordas
            filledRect(x+2, y+2, width, rowH, Color(0,0,0, math.floor(95*clamp(lifeFade+0.3,0.3,1))), 7)
            filledRect(x, y, width, rowH, bgColor, 7)
            filledRect(x, y, width, 3, accentColor, 6)
            filledRect(x, y, 3, rowH, accentColor, 6)
            outlineRect(x, y, width, rowH, borderGlow, 7, 1)

            -- Badge
            local badgeX = x + padX
            local badgeY2 = y + padY
            filledRect(badgeX, badgeY2, badgeW, badgeH, badgeBg, 5)
            outlineRect(badgeX, badgeY2, badgeW, badgeH, Color(255,255,255, math.floor(18+relLife*30)), 5, 1)
            renderTextShadow(fontSmall, 12, badge, Vec2(badgeX+6, badgeY2+2), badgeTextCol, shadowCol)

            -- Título + tempo
            renderTextShadow(font, 14, title, Vec2(badgeX + badgeW + 8, y + padY - 1), titleCol, shadowCol)
            renderTextShadow(fontSmall, 12, timeText, Vec2(x + width - padX - timeSize.x, y + padY + 1), timeCol, shadowCol)

            -- Barra de progresso
            local progressW = math.floor((width-2) * relLife)
            if progressW > 0 then
                filledRect(x+1, y+rowH-3, progressW, 2, accentColor, 1)
            end
        end
    end
end

local v2=Menu.Create("Scripts","Outros","Aviso de Sumiço")
v2:Icon("\u{E02E}")
local v3=v2:Create("Principal"):Create("Aviso de Sumiço")
v1.enable=v3:Switch("Ativar",true,"\u{E0B7}")
v1.multiMonitorEnable=v3:Switch("Tratar ilusões fortes como heróis (Beta)",false,"\u{E21A}")

local v6=v2:Create("Principal"):Create("Configurações de Exibição")
v1.missDrawTime=v6:Slider("Exibir após sumir (segundos)",0.1,15,0.5,"%.1f s")
v1.missDrawTime:Icon("\u{F843} ")
v1.missDrawTimeLimit=v6:Slider("Parar de exibir após (segundos)",60,300,120,"%d s")
v1.autoDisableTime=v6:Slider("Desativar automaticamente após tempo de jogo (minutos)",0,120,20,"%d min")
v1.autoDisableTime:Icon("\u{F845} ")
v1.topPanelEnable=v6:Switch("Informações no painel superior (sem auto-desativar)",true,"\u{E26E}")
v1.mapEnable=v6:Switch("Prever caminho no mapa principal",true,"\u{E09E}")
v1.minimapEnable=v6:Switch("Prever posição no minimapa",true,"\u{E47F}")
v1.missDrawTimeLimit:Icon("\u{F845} ")

local v13=v2:Create("Principal"):Create("Mensagens de Chat")
v1.missChatEnable=v13:Switch("Alertas de sumiço e proximidade (visível apenas para você)",true,"\u{F4AF}")
v1.missChatTime=v13:Slider("Enviar alerta após sumir (segundos)",10,90,15,"%d s")
v1.missChatTime:Icon("\u{F843}")


local v14=v2:Create("Principal"):Create("Alertas de Ameaça")
v1.pingEnable=v14:Switch("Ping no minimapa quando inimigo some perto de aliado",true,"\u{E47F}")
v1.pingCooldown=v14:Slider("Cooldown do ping (segundos)",3,30,8,"%d s")
v1.pingCooldown:Icon("\u{F843}")
v1.hudAlertEnable=v14:Switch("Alertas HUD no canto da tela",true,"\u{E26E}")
v1.hudAlertEnable:ToolTip("Mostra caixas de alerta no canto direito quando inimigos somem perto de aliados")
v1.threatRadius=v14:Slider("Raio de detecção de ameaça",1000,3500,2500,"%d unidades")
v1.threatRadius:Icon("\u{E09E}")

local v16=v2:Create("Principal"):Create("Notas Importantes")
v16:Label("1.O script pode falhar sem heróis inimigos","\u{26A0}")
v16:Label("2.Recarregue o script após mudanças no número de heróis","\u{26A0}")
v16:Label("3.Este é um script gratuito por: Mayfail","\u{26A0}")

-- Estado e buffers
local v17={}
local v18={}
local v19=0
local v20=-100
local v21=-1
local v22=Vec2(0,0)
local v23=false
local v24=0
local v25=Vec2(0,0)
local v26=true

-- Registro de heróis e ícones
local function v27(h)
    local isEnemy=not Entity.IsSameTeam(Heroes.GetLocal(),h)
    local idx=Hero.GetPlayerID(h)+1
    if not v17[idx] then v17[idx]={} end
    if v17[idx][1] then
        if Entity.GetUnitName(h)=="npc_dota_hero_monkey_king" then return end
        if ((Entity.GetUnitName(h)=="npc_dota_hero_vengefulspirit") or (Entity.GetUnitName(h)=="npc_dota_lone_druid_bear") or (Entity.GetUnitName(h)=="npc_dota_hero_arc_warden")) and v17[idx][2] then
            v17[idx][2].unit=h
        else
            table.insert(v17[idx],{unit=h,draw_icon=Render.LoadImage("panorama/images/heroes/icons/"..Entity.GetUnitName(h).."_png.vtex_c"),is_enemy=isEnemy,last_seen=GameRules.GetGameTime(),is_missing=true,is_dead=true,near_chated=false,miss_chated=false,ally_chated=false,moveDirection=Vector(),moveSpeed=0})
        end
    else
        table.insert(v17[idx],{unit=h,draw_icon=Render.LoadImage("panorama/images/heroes/icons/"..Entity.GetUnitName(h).."_png.vtex_c"),is_enemy=isEnemy,last_seen=GameRules.GetGameTime(),is_missing=true,is_dead=true,near_chated=false,miss_chated=false,ally_chated=false,moveDirection=Vector(),moveSpeed=0})
    end
end

local function v28()
    v21=Render.LoadFont("Arial",16,700)
    v1._fontSmall=Render.LoadFont("Arial",14,400)
    v22=Render.ScreenSize()
    for i=1,Players.Count() do table.insert(v17,{}) end
    v23=Entity.GetTeamNum(Heroes.GetLocal())==3
    v25=Vec2(63,40)
    v24=16
    local all=Heroes.GetAll()
    for _,h in ipairs(all) do v27(h); v18[h]=9 end
    v19=#all
end

local function v29(now)
    if v19<Heroes.Count() then
        local all=Heroes.GetAll()
        for _,h in ipairs(all) do
            if not v18[h] then v27(h); v18[h]=9 end
        end
        v19=Heroes.Count()
    end
    if v1.multiMonitorEnable:Get() then
        for _,arr in ipairs(v17) do
            if (#arr>0) and arr[1].is_enemy then
                local anyVisible=false
                local anyAlive=false
                for _,entry in ipairs(arr) do
                    anyVisible = anyVisible or (NPC.IsVisible(entry.unit) and Entity.IsAlive(entry.unit))
                    anyAlive   = anyAlive   or Entity.IsAlive(entry.unit)
                end
                if not anyAlive then
                    arr[1].is_dead=true; arr[1].is_missing=false; arr[1].miss_chated=false; arr[1].near_chated=false; arr[1].ally_chated=false
                else
                    arr[1].is_dead=false
                    if not anyVisible then
                        if not arr[1].is_missing then arr[1].is_missing=true; arr[1].last_seen=now end
                    else
                        arr[1].is_missing=false; arr[1].last_seen=now; arr[1].miss_chated=false; arr[1].near_chated=false; arr[1].ally_chated=false
                        arr[1].moveDirection=Entity.GetAbsRotation(arr[1].unit):GetForward():Normalized()
                        arr[1].moveSpeed=NPC.GetMoveSpeed(arr[1].unit)
                    end
                end
            end
        end
    else
        for _,arr in ipairs(v17) do
            if (#arr>0) and arr[1].is_enemy then
                local u=arr[1].unit
                if not Entity.IsAlive(u) then
                    arr[1].is_dead=true; arr[1].is_missing=false; arr[1].miss_chated=false; arr[1].near_chated=false; arr[1].ally_chated=false
                else
                    arr[1].is_dead=false
                    if not NPC.IsVisible(u) then
                        if not arr[1].is_missing then arr[1].is_missing=true; arr[1].last_seen=now end
                    else
                        arr[1].is_missing=false; arr[1].last_seen=now; arr[1].miss_chated=false; arr[1].near_chated=false; arr[1].ally_chated=false
                        arr[1].moveDirection=Entity.GetAbsRotation(arr[1].unit):GetForward():Normalized()
                        arr[1].moveSpeed=NPC.GetMoveSpeed(arr[1].unit)
                    end
                end
            end
        end
    end
    -- ── Verificar ameaças perto de aliados (ping + HUD alerta) ──
    if v1.pingEnable:Get() or v1.hudAlertEnable:Get() then
        local allies = {}
        for _, h in ipairs(Heroes.GetAll()) do
            if h and Entity.IsAlive(h) and Entity.IsSameTeam(Heroes.GetLocal(), h) and h ~= Heroes.GetLocal() then
                allies[#allies+1] = h
            end
        end
        for _, arr in ipairs(v17) do
            if #arr > 0 and arr[1].is_enemy and arr[1].is_missing and not arr[1].is_dead then
                local e = arr[1]
                local diff = now - e.last_seen
                if diff >= (v1.missDrawTime and v1.missDrawTime:Get() or 0.5) and diff < 60 then
                    local predict = Entity.GetAbsOrigin(e.unit) + (e.moveDirection * e.moveSpeed * diff)
                    local heroName = NPC.GetUnitName(e.unit) or "?"
                    heroName = heroName:gsub("npc_dota_hero_", "")
                    for _, ally in ipairs(allies) do
                        local sev, label = classifyMissNearAlly(e, predict, ally, now)
                        if sev then
                            -- Ping
                            if v1.pingEnable:Get() then
                                local canGlobal = (now - lastPingTime) >= (v1.pingCooldown and v1.pingCooldown:Get() or 8)
                                local canHero = (now - (perHeroPingTime[heroName] or -999)) >= (v1.pingCooldown and v1.pingCooldown:Get() or 8)
                                if canGlobal and canHero then
                                    if pingDangerAt(predict) then
                                        lastPingTime = now
                                        perHeroPingTime[heroName] = now
                                    end
                                end
                            end
                            -- HUD Alerta
                            if v1.hudAlertEnable:Get() then
                                -- Evitar spam: só 1 alerta por herói a cada 6s
                                local dominated = false
                                for _, a in ipairs(hudAlerts) do
                                    if a.heroName == heroName and (a.expiresAt - now) > 1 then
                                        dominated = true; break
                                    end
                                end
                                if not dominated then
                                    addHudAlert(heroName, e.draw_icon, sev, label, now)
                                end
                            end
                            -- Chat: Notificar quando aliado precisa de ajuda
                            if v1.missChatEnable:Get() and not e.ally_chated then
                                local allyName = NPC.GetUnitName(ally) or "?"
                                allyName = allyName:gsub("npc_dota_hero_", "")
                                Chat.Print("ConsoleChat", "[ZMiss] " .. label .. "! " .. heroName .. " pode estar indo para " .. allyName)
                                e.ally_chated = true
                            end
                        end
                    end
                end
            end
        end
    end

end

local function v30(now)
    local col=0
    local gameTime = GameRules.GetDOTATime()
    local autoDisableMinutes = v1.autoDisableTime:Get()
    
    -- Se auto-disable está ativo (> 0) e o tempo passou, não desenha nada
    if autoDisableMinutes > 0 and gameTime >= (autoDisableMinutes * 60) then
        return
    end
    
    for _,arr in ipairs(v17) do
        if (#arr>0) and arr[1].is_enemy then
            local e=arr[1]
            local diff=now-e.last_seen
            local secs=math.floor(diff)
            if e.is_missing and not e.is_dead then
                if v1.topPanelEnable:Get() then
                    local x=(v23 and ((((v22.x/2)-100)-(63*5))+(col*63))) or ((v22.x/2)+100+(col*63))
                    local y=0
                    local s=tostring(secs)
                    local w=#s*(v24/2)
                    local tx=x+((v25.x-w)/2)
                    local ty=y+((v25.y-v24)/2)
                    local pad=v24/4
                    Render.FilledRect(Vec2(tx-pad,ty-pad),Vec2(tx+w+pad+2,ty+v24+pad+2),Color(255,0,0,180),3)
                    Render.Text(v21,v24,s,Vec2(tx,ty),Color(255,255,255,255))
                end
                if ( (v1.mapEnable:Get() or v1.minimapEnable:Get()) and (diff>=v1.missDrawTime:Get()) and (secs<v1.missDrawTimeLimit:Get()) ) then
                    local predict=Entity.GetAbsOrigin(e.unit)+(e.moveDirection*e.moveSpeed*(now-e.last_seen))
                    if (v1.missChatEnable:Get() and Entity.IsAlive(Heroes.GetLocal()) and (predict:Distance(Entity.GetAbsOrigin(Heroes.GetLocal()))<2000) and not e.near_chated and (secs>10)) then
                        Chat.Print("ConsoleChat","<font color='#ffa500ff'>!!Aviso de Sumiço!! </font> "..'<img class="HeroIcon" src="file://{images}/heroes/icons/'..Entity.GetUnitName(e.unit)..'.png"/>'.."<font color='#ff4500ff'> pode se aproximar a 2000 unidades</font>")
                        e.near_chated=true
                    end
                    if v1.minimapEnable:Get() then
                        MiniMap.DrawHeroIcon(Entity.GetUnitName(e.unit),predict,255,80,80,200)
                    end
                    if v1.mapEnable:Get() then
                        local s1,v1ok=Render.WorldToScreen(Entity.GetAbsOrigin(e.unit))
                        local s2,v2ok=Render.WorldToScreen(predict)
                        if v1ok and v2ok then Render.Line(s1,s2,Color(255,0,0,128),3) end
                        if v1ok then Render.ImageCentered(e.draw_icon,s1,Vec2(35,35),Color(255,80,80,200)); Render.Text(v21,18,tostring(secs),s1,Color(255,255,255,255)) end
                        if v2ok then Render.ImageCentered(e.draw_icon,s2,Vec2(35,35),Color(255,80,80,200)); Render.Text(v21,18,tostring(secs),s2,Color(255,255,255,255)) end
                    end
                end
                if v1.missChatEnable:Get() and (diff>v1.missChatTime:Get()) and not e.miss_chated then
                    Chat.Print("ConsoleChat","<font color='#ff00ffff'>Aviso </font>"..'<img class="HeroIcon" src="file://{images}/heroes/icons/'..Entity.GetUnitName(e.unit)..'.png"/>'.."<font color='#00ffffff'> Sumido por "..v1.missChatTime:Get().." segundos</font>")
                    e.miss_chated=true
                end
            end
            col=col+1
        end
    end
    -- ── Desenhar alertas HUD ──
    if v1.hudAlertEnable and v1.hudAlertEnable:Get() then
        pruneAlerts(now)
        drawHudAlerts(now, v21, v1._fontSmall)
    end

end

function Z_vision_missWarning.OnScriptsLoaded()
    v28()

end

function Z_vision_missWarning.OnUpdate()
    v26=v1.enable:Get()
    if not Engine.IsInGame() then return end
    if not v1.enable:Get() then return end
    if (Heroes.GetLocal()==nil) then return end
    v20=GameRules.GetGameTime()
    v29(v20)

end

function Z_vision_missWarning.OnGameEnd()
    hudAlerts = {}
    nextAlertId = 0
    lastPingTime = -999
    perHeroPingTime = {}
    towerCache = { t = -999, towers = {} }
end

function Z_vision_missWarning.OnDraw()
    if v26 then v30(v20) end
end

return Z_vision_missWarning
