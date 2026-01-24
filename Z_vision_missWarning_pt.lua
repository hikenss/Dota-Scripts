local Z_vision_missWarning={}
local v1={}

-- Menu em Português
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
            table.insert(v17[idx],{unit=h,draw_icon=Render.LoadImage("panorama/images/heroes/icons/"..Entity.GetUnitName(h).."_png.vtex_c"),is_enemy=isEnemy,last_seen=GameRules.GetGameTime(),is_missing=true,is_dead=true,near_chated=false,miss_chated=false,moveDirection=Vector(),moveSpeed=0})
        end
    else
        table.insert(v17[idx],{unit=h,draw_icon=Render.LoadImage("panorama/images/heroes/icons/"..Entity.GetUnitName(h).."_png.vtex_c"),is_enemy=isEnemy,last_seen=GameRules.GetGameTime(),is_missing=true,is_dead=true,near_chated=false,miss_chated=false,moveDirection=Vector(),moveSpeed=0})
    end
end

local function v28()
    v21=Render.LoadFont("Arial",16,700)
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
                    arr[1].is_dead=true; arr[1].is_missing=false; arr[1].miss_chated=false; arr[1].near_chated=false
                else
                    arr[1].is_dead=false
                    if not anyVisible then
                        if not arr[1].is_missing then arr[1].is_missing=true; arr[1].last_seen=now end
                    else
                        arr[1].is_missing=false; arr[1].last_seen=now; arr[1].miss_chated=false; arr[1].near_chated=false
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
                    arr[1].is_dead=true; arr[1].is_missing=false; arr[1].miss_chated=false; arr[1].near_chated=false
                else
                    arr[1].is_dead=false
                    if not NPC.IsVisible(u) then
                        if not arr[1].is_missing then arr[1].is_missing=true; arr[1].last_seen=now end
                    else
                        arr[1].is_missing=false; arr[1].last_seen=now; arr[1].miss_chated=false; arr[1].near_chated=false
                        arr[1].moveDirection=Entity.GetAbsRotation(arr[1].unit):GetForward():Normalized()
                        arr[1].moveSpeed=NPC.GetMoveSpeed(arr[1].unit)
                    end
                end
            end
        end
    end
end

local function v30(now)
    local col=0
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
                if ( (v1.mapEnable:Get() or v1.minimapEnable:Get()) and (diff>=v1.missDrawTime:Get()) and (secs<v1.missDrawTimeLimit:Get()) and (GameRules.GetDOTATime()<(v1.autoDisableTime:Get()*60)) ) then
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
                        Render.Line(s1,s2,Color(255,0,0,128),3)
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

function Z_vision_missWarning.OnDraw()
    if v26 then v30(v20) end
end

return Z_vision_missWarning
