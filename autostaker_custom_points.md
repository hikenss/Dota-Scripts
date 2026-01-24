local v0 = Menu.Create("Scripts", "User Scripts", "AutoStacker"); local v1 = v0:Create("Options"):Create("Main");
local function TR(key) return key end
local v3 = { Get = function() return true end }
local v161 = v1:Slider("Overlay font size", 10, 24, 12, "%d");
local v164 = v1:Slider("Overlay opacity", 0, 255, 210, "%d");
local v122 = v1:Switch("Show camp box", true, "\u{f65d}");
local v142 = v1:Slider("Camp box Z offset", -500, 500, -275, "%d");
local v123 = v1:Bind("Record point", Enum.ButtonCode.KEY_F7, "\u{f304}");
local v141 = v1:Bind("Reset points", Enum.ButtonCode.KEY_F8, "\u{f12d}");
v1:Label("Camp settings", "\u{f1bb}");
local v124 = v1:Slider("Attack second", 0, 59, 53, "%d");
local v127 = v1:Slider("Wait until sec", 0, 59, 15, "%d");
local v144 = v1:Slider("Attack time", 0, 2, 0.6, "%.1f");
local v5 = true; local v6 = false; local v7 = 10; local v8 = 10; local v9 = false; local v10 = 0; local v11 = 0; local v12 = {}; local v13 = {}; local v14 = {}; local v15 = {}; local v16 = {}; local v118 = {}; local v119 = 0.1; local v120 = {}; local v121 = {}; local v132 = nil; local v133 = nil; local v134 = nil; local v135 = 0; local v136 = nil; local v137 = false; local v138 = false; local v143 = {}; local v147 = "autostacker_presets"; local v148 = {}; local v159_lastNoPointsLog = 0;
local v166_dragging = false; local v167_dragTarget = nil; local v168_lastSave = 0; local v170_lastDesired = {}; local v171_unitCamp = {}; local v172_keyToCamp = {}; local v175_campStrike = {};
local v152
local v150
local function v157_getCampOpts(camp)
    local aS, wT, aT = v124:Get(), v127:Get(), v144:Get()
    local key = camp and v152(camp) or nil
    if key and v148[key] and v148[key].opts then
        if v148[key].opts.attackSec ~= nil then aS = v148[key].opts.attackSec end
        if v148[key].opts.waitTo ~= nil then wT = v148[key].opts.waitTo end
        if v148[key].opts.attackTime ~= nil then aT = v148[key].opts.attackTime end
    end
    return aS, wT, aT
end
local function v158_SaveCampOpts(camp, aS, wT, aT)
    if not camp then return end
    local key = v152(camp); if not key then return end
    if not v148[key] then v148[key] = {} end
    if not v148[key].opts then v148[key].opts = {} end
    v148[key].opts.attackSec = aS
    v148[key].opts.waitTo = wT
    v148[key].opts.attackTime = aT
    v150()
end
local function v149(tbl)
    local function serialize(value)
        if type(value) == "table" then
            local parts = {"{"}
            local first = true
            for k, v in pairs(value) do
                if not first then table.insert(parts, ",") end
                first = false
                local key
                if type(k) == "number" then
                    key = "[" .. k .. "]="
                else
                    key = string.format("[%q]=", tostring(k))
                end
                table.insert(parts, key .. serialize(v))
            end
            table.insert(parts, "}")
            return table.concat(parts)
        elseif type(value) == "string" then
            return string.format("%q", value)
        else
            return tostring(value)
        end
    end
    return "return " .. serialize(tbl)
end
v150 = function()
    local keysList = {}
    for key, preset in pairs(v148) do
        table.insert(keysList, key)
        if preset.center then Config.WriteString(v147, key .. ".center", string.format("%f,%f,%f", preset.center.x, preset.center.y, preset.center.z)) end
        if preset.wait then Config.WriteString(v147, key .. ".wait", string.format("%f,%f,%f", preset.wait.x, preset.wait.y, preset.wait.z)) end
        if preset.pull then Config.WriteString(v147, key .. ".pull", string.format("%f,%f,%f", preset.pull.x, preset.pull.y, preset.pull.z)) end
        if preset.opts then
            Config.WriteInt(v147, key .. ".attackSec", preset.opts.attackSec or 0)
            Config.WriteInt(v147, key .. ".waitTo", preset.opts.waitTo or 0)
            Config.WriteFloat(v147, key .. ".attackTime", preset.opts.attackTime or 0)
        end
    end
    if #keysList > 0 then Config.WriteString(v147, "_keys", table.concat(keysList, ",")) end
end
local function v151()
    local loaded = {}
    local keysStr = Config.ReadString(v147, "_keys", "")
    if keysStr ~= "" then
        for k in string.gmatch(keysStr, "[^,]+") do loaded[k] = true end
    else
        local camps = Camps.GetAll() or {}
        for i = 1, #camps do
            local camp = camps[i]; local key = v152(camp); if key then loaded[key] = true end
        end
    end
    for key, _ in pairs(loaded) do
        local function readVec3(s)
            local str = Config.ReadString(v147, s, "")
            if str == "" then return nil end
            local x,y,z = str:match("([^,]+),([^,]+),([^,]+)")
            if not x then return nil end
            return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
        end
        local center = readVec3(key .. ".center")
        local wait = readVec3(key .. ".wait")
        local pull = readVec3(key .. ".pull")
        local attackSec = Config.ReadInt(v147, key .. ".attackSec", -1)
        local waitTo = Config.ReadInt(v147, key .. ".waitTo", -1)
        local attackTime = Config.ReadFloat(v147, key .. ".attackTime", -1)
        if center or wait or pull or attackSec >= 0 or waitTo >= 0 or attackTime >= 0 then
            v148[key] = {
                center = center,
                wait = wait,
                pull = pull,
                opts = { attackSec = attackSec >= 0 and attackSec or nil, waitTo = waitTo >= 0 and waitTo or nil, attackTime = attackTime >= 0 and attackTime or nil }
            }
        end
    end
end
pcall(v151)
v152 = function(camp)
    if not camp then return nil end
    local box = Camp.GetCampBox(camp)
    if not box or not box.min or not box.max then return nil end
    local minX = math.floor(box.min:GetX())
    local minY = math.floor(box.min:GetY())
    local maxX = math.floor(box.max:GetX())
    local maxY = math.floor(box.max:GetY())
    return string.format("%d_%d_%d_%d", minX, minY, maxX, maxY)
end
local function v153(preset)
    if not preset then return end
    if preset.center then v132 = Vector(preset.center.x, preset.center.y, preset.center.z) end
    if preset.wait then v133 = Vector(preset.wait.x, preset.wait.y, preset.wait.z) end
    if preset.pull then v134 = Vector(preset.pull.x, preset.pull.y, preset.pull.z) end
    if preset.opts then if preset.opts.attackSec then v124:Set(preset.opts.attackSec) end; if preset.opts.waitTo then v127:Set(preset.opts.waitTo) end; if preset.opts.attackTime then v144:Set(preset.opts.attackTime) end end
end
local function v154()
    if not v136 then return end
    local key = v152(v136); if not key then return end
    local preset = v148[key];
    if preset then
        v153(preset); print("[AutoStacker] Пресет применён для кемпа " .. key)
    else
        v133 = nil; v134 = nil; print("[AutoStacker] Нет пресета для кемпа " .. key .. ", точки очищены")
    end
end

local function v155_SaveIfComplete()
    if not v136 or not v132 or not v133 or not v134 then return end
    local key = v152(v136); if not key then return end
    local existing = v148[key]
    local aS, wT, aT = v157_getCampOpts(v136)
    local cur = {
        center = { x = v132:GetX(), y = v132:GetY(), z = v132:GetZ() },
        wait = { x = v133:GetX(), y = v133:GetY(), z = v133:GetZ() },
        pull = { x = v134:GetX(), y = v134:GetY(), z = v134:GetZ() },
        opts = { attackSec = aS, waitTo = wT, attackTime = aT }
    }
    local function samePoint(a,b) return a and b and a.x==b.x and a.y==b.y and a.z==b.z end
    local same = existing and samePoint(existing.center, cur.center) and samePoint(existing.wait, cur.wait) and samePoint(existing.pull, cur.pull)
        and existing.opts and existing.opts.attackSec==cur.opts.attackSec and existing.opts.waitTo==cur.opts.waitTo and existing.opts.attackTime==cur.opts.attackTime or false
    if not same then
        v148[key] = cur
        v150()
        print("[AutoStacker] Автосохранение пресета для кемпа " .. key)
    end
end

local function v160_CaptureSelectedUnit(centerPos)
    local pl = Players.GetLocal(); if not pl then return end
    local sel = Player.GetSelectedUnits(pl) or {}
    local best, bestD = nil, math.huge
    for i = 1, #sel do
        local u = sel[i]
        if Entity.IsAlive(u) and (not Entity.IsHero(u)) then
            local up = Entity.GetAbsOrigin(u)
            local d = (up - centerPos):Length2D()
            if d < bestD then bestD = d; best = u end
        end
    end
    if best then
        local exists = false; for i = 1, #v12 do if v12[i] == best then exists = true; break end end
        if not exists then table.insert(v12, best) end
        v15[best] = {}
        if v136 then v171_unitCamp[best] = v136 end
    end
end

local function v156_ClearPresetForCamp(camp)
    if not camp then return end
    local key = v152(camp); if not key then return end
    v148[key] = nil
    Config.WriteString(v147, key .. ".center", "")
    Config.WriteString(v147, key .. ".wait", "")
    Config.WriteString(v147, key .. ".pull", "")
    Config.WriteInt(v147, key .. ".attackSec", -1)
    Config.WriteInt(v147, key .. ".waitTo", -1)
    Config.WriteFloat(v147, key .. ".attackTime", -1)
end
local function v17()
    local v22 = GameRules.GetGameTime() - GameRules.GetGameStartTime(); if (v22 < 0) then v22 = 0; end
    return v22;
end
local function v18(v23)
    if not v23 then return nil; end
    local v24 = Camp.GetCampBox(v23); if (not v24 or not v24.min or not v24.max) then return nil; end
    local v25 = (v24.min:GetX() + v24.max:GetX()) / 2; local v26 = (v24.min:GetY() + v24.max:GetY()) / 2; local v27 = (v24.min:GetZ() + v24.max:GetZ()) /
    2; return Vector(v25, v26, v27);
end
local function v19(v28)
    local v29 = Camps.GetAll(); if (not v29 or (#v29 == 0)) then return nil; end
    local v30 = nil; local v31 = math.huge; for v54, v55 in ipairs(v29) do
        local v56 = v18(v55); if v56 then
            local v71 = (v56 - v28):Length2D(); if (v71 < v31) then
                v31 = v71; v30 = v55;
            end
        end
    end
    return v30;
end
local function v20(v32)
    local v33 = {}; local v34 = {}; for v57, v58 in pairs(v13) do table.insert(v34, v57); end
    if (#v32 <= #v34) then for v72, v73 in ipairs(v32) do
            local v74, v75 = nil, math.huge; local v76 = Entity.GetAbsOrigin(v73); for v90, v91 in ipairs(v34) do
                local v92 = v13[v91]; local v93 = (v92.wait - v76):Length2D(); if (v93 < v75) then
                    v75 = v93; v74 = v91;
                end
            end
            if v74 then
                v33[v73] = v74; for v103, v104 in ipairs(v34) do if (v104 == v74) then
                        table.remove(v34, v103); break;
                    end end
            end
        end else for v77, v78 in ipairs(v32) do
            local v79, v80 = nil, math.huge; local v81 = Entity.GetAbsOrigin(v78); for v94, v95 in pairs(v13) do
                local v96 = (v95.wait - v81):Length2D(); if (v96 < v80) then
                    v80 = v96; v79 = v94;
                end
            end
            v33[v78] = v79;
        end end
    return v33;
end
local function v21()
    local v35 = Players.GetLocal(); local v36 = Player.GetSelectedUnits(v35) or {}; if (#v36 == 0) then
        print("[AutoStacker] Нет выбранных юнитов."); return false;
    end
    v12 = {}; for v59, v60 in ipairs(v36) do if Entity.IsAlive(v60) and (not Entity.IsHero(v60)) then table.insert(v12, v60); end end
    if (#v12 == 0) then print("[AutoStacker] Выберите не-героя для стака."); return false; end
    v15 = {}; return true;
end
function OnUpdate()
    local v37 = Players.GetLocal(); if (not v6) then v6 = true; v21(); end; if not v5 then return; end
    if (v141:IsPressed()) then local prevCamp = v136; if prevCamp then v156_ClearPresetForCamp(prevCamp) end; v132 = nil; v133 = nil; v134 = nil; v135 = 0; v136 = nil; v16[1] = nil; v121[1] = nil; v171_unitCamp = {}; print("[AutoStacker] Точки сброшены"); end
    
    local bp = v123:IsPressed(); if (bp and not v137) then
        v137 = true;
        local wp = Input.GetWorldCursorPos();
        v132 = wp; print("[AutoStacker] Center selected");
        local camp = nil; local near = Camps.InRadius(wp, 800);
        if near and (#near > 0) then
            local best, bestD = nil, math.huge; for i = 1, #near do local c = near[i]; local cc = v18(c); if cc then local d = (cc - wp):Length2D(); if d < bestD then bestD = d; best = c; end end end camp = best;
        end
        if (not camp) then camp = v19(wp); end
        if camp then
            v136 = camp; v121[1] = camp; local sc = v18(camp); if sc then v16[1] = sc; v175_campStrike[camp] = sc; end; v154();
            local pl = Players.GetLocal(); local sel = Player.GetSelectedUnits(pl) or {}; local bestU = nil; local bestD = math.huge
            for i = 1, #sel do local u = sel[i]; if Entity.IsAlive(u) and (not Entity.IsHero(u)) then local up = Entity.GetAbsOrigin(u); local d = (up - sc):Length2D(); if d < bestD then bestD = d; bestU = u end end end
            if bestU then
                v171_unitCamp[bestU] = camp; v15[bestU] = {}
                local exists = false; for i = 1, #v12 do if v12[i] == bestU then exists = true; break end end
                if not exists then table.insert(v12, bestU) end
                print(string.format("[AutoStacker] Привязал юнита %s к кемпу", tostring(bestU)))
            end
            if not v133 then v133 = (v16[1] + Vector(250, 0, 0)) end
            if not v134 then v134 = (v16[1] + Vector(-250, 0, 0)) end
            v155_SaveIfComplete();
        end
    end
    if (not bp) then v137 = false; end
    
    local v39 = v12 or {}; if (#v39 == 0) then
        local now = GameRules.GetGameTime(); if (now - v159_lastNoPointsLog) > 1.0 then print("[AutoStacker] Нет юнитов для управления."); v159_lastNoPointsLog = now end; return;
    end
    local v40 = {}; for v64, v65 in ipairs(v39) do if Entity.IsAlive(v65) and (v171_unitCamp[v65] ~= nil) then table.insert(v40, v65); end end
    if (#v40 == 0) then
        local now = GameRules.GetGameTime(); if (now - v159_lastNoPointsLog) > 1.0 then print("[AutoStacker] Нет привязанных юнитов."); v159_lastNoPointsLog = now end; return;
    end
    local v41 = v17(); local v42 = math.floor(v41 / 60); local v43 = math.floor(v41 % 60); for v66, v67 in ipairs(v40) do
        if not v15[v67] then v15[v67] = {}; end
        if not v15[v67][v42] then v15[v67][v42] = { waitDone = false, attackDone = false, pullDone = false }; end
    end
    for v68, v69 in ipairs(v40) do
        local campC = v171_unitCamp[v69]
        local v86 = { wait = nil, pull = nil };
        local v100 = nil; if campC then
                v100 = v175_campStrike[campC] or v18(campC)
                local key = v152(campC); local preset = key and v148[key] or nil
                if preset and preset.wait then v86.wait = Vector(preset.wait.x, preset.wait.y, preset.wait.z) end
                if preset and preset.pull then v86.pull = Vector(preset.pull.x, preset.pull.y, preset.pull.z) end
                if (not v86.wait or not v86.pull) and v100 then
                    if not v86.wait then v86.wait = (v100 + Vector(250, 0, 0)) end
                    if not v86.pull then v86.pull = (v100 + Vector(-250, 0, 0)) end
                end
            end
        if (v100 and v86.wait and v86.pull) then
                local v99 = v15[v69][v42]; if not v100 then goto continue_unit; end
                local aS, wT, aT = v157_getCampOpts(campC)
                local v101 = { v69 }; if (v43 < aS) then if not v99.waitDone then
                        v99.waitDone = true; print(string.format(
                        "[Stacker] Юнит %s в %d:%02d -> WAIT (%.0f, %.0f, %.0f)", v69, v42, v43, v86.wait:GetX(),
                            v86.wait:GetY(), v86.wait:GetZ())); Player.PrepareUnitOrders(v37,
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, v86.wait, nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, v69, false, false, false, false);
                    end else
                    if ((v43 == aS) and not v99.attackDone) then
                        v99.attackDone = true; 
                        local v114 = Entity.GetUnitsInRadius(v69, 1200, Enum.TeamType.TEAM_ENEMY, true, true);
                        local v115 = nil; local v116 = math.huge; if v114 and (#v114 > 0) then
                            local v117 = Entity.GetAbsOrigin(v69); for v120, v121 in ipairs(v114) do
                                if (NPC.IsNeutral(v121) and Entity.IsAlive(v121)) then
                                    local v122 = (Entity.GetAbsOrigin(v121) - v117):Length2D(); if (v122 < v116) then v116 = v122; v115 = v121; end
                                end
                            end
                        end
                        if v115 then
                            print(string.format("[Stacker] Юнит %s в %d:%02d -> ATTACK TARGET %s", v69, v42, v43, NPC.GetUnitName(v115)));
                            Player.AttackTarget(v37, v69, v115, false, false, true);
                            v143[v69] = GameRules.GetGameTime() + aT;
                            v120[v69] = v42;
                        else
                            print(string.format(
                            "[Stacker] Юнит %s в %d:%02d -> ATTACK (%.0f, %.0f, %.0f)", v69, v42, v43, v100:GetX(),
                                v100:GetY(), v100:GetZ())); Player.PrepareUnitOrders(v37,
                                Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE, nil, v100, nil,
                                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, v69, false, false, false, false);
                            v143[v69] = GameRules.GetGameTime() + aT;
                            v120[v69] = v42;
                        end
                    end
                    local nowTime = GameRules.GetGameTime(); if (v99.attackDone and (not v99.pullDone) and v143[v69] and (nowTime >= v143[v69])) then
                        v99.pullDone = true; print(string.format(
                        "[Stacker] Юнит %s в %d:%02d -> PULL (%.0f, %.0f, %.0f)", v69, v42, v43, v86.pull:GetX(),
                            v86.pull:GetY(), v86.pull:GetZ())); Player.PrepareUnitOrders(v37,
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, v86.pull, nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, v69, false, false, false, false);
                    end
                end
            else end
        ::continue_unit::
        ;
        local desired = nil; local nowT = GameRules.GetGameTime(); local aS, wT, aT = v157_getCampOpts(campC); local lastAttackMinute = v120[v69]; local curMinute = math.floor(v17() / 60); local inNextMinute = (lastAttackMinute ~= nil) and (curMinute > lastAttackMinute) or false; if (not v100 or not v86.wait or not v86.pull) then desired = nil; else
            local prevMinute = (lastAttackMinute ~= nil) and (curMinute - 1) or nil
            local state = v15[v69][v42]; local prevState = prevMinute and v15[v69][prevMinute] or nil
            if inNextMinute and prevState and (not prevState.pullDone) then desired = v86.pull
            elseif (inNextMinute and (v43 < wT)) then desired = v86.pull
            elseif ((v43 < aS) or (not state.attackDone)) then desired = v86.wait
            else
                if (not state.pullDone) then
                    if (v143[v69] and (nowT < v143[v69])) then desired = nil; else desired = v86.pull; end
                else
                    if (inNextMinute and (v43 >= wT)) then desired = v86.wait; else desired = v86.pull; end
                end
            end
        end
        if desired then
            local uPos = Entity.GetAbsOrigin(v69)
            local dist = (desired - uPos):Length2D()
            local lastPos = v170_lastDesired[v69]
            local targetChanged = (not lastPos) or (((desired - lastPos):Length2D()) > 10)
            local lastSpam = v118[v69] or 0
            local shouldOrder = false
            if targetChanged then
                shouldOrder = true
            elseif (dist > 60) and ((nowT - lastSpam) >= 0.6) then
                shouldOrder = true
            end
            if shouldOrder then
                v170_lastDesired[v69] = desired
                v118[v69] = nowT
                Player.PrepareUnitOrders(v37, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, desired, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, v69, false, false, false, false)
            end
        end
    end
end

function OnDraw()
    if (v5 and v122:Get()) then
        for unit, camp in pairs(v171_unitCamp) do
            if camp then
                local box = Camp.GetCampBox(camp); if (box and box.min and box.max) then
                    local z = (box.min:GetZ() + box.max:GetZ()) / 2 + v142:Get();
                    local p1 = Vector(box.min:GetX(), box.min:GetY(), z);
                    local p2 = Vector(box.max:GetX(), box.min:GetY(), z); local p3 = Vector(box.max:GetX(), box.max:GetY(), z);
                    local p4 = Vector(box.min:GetX(), box.max:GetY(), z); local x1, y1, s1 = Renderer.WorldToScreen(p1);
                    local x2, y2, s2 = Renderer.WorldToScreen(p2); local x3, y3, s3 = Renderer.WorldToScreen(p3); local x4, y4, s4 = Renderer.WorldToScreen(p4);
                    if (s1 and s2 and s3 and s4) then
                        Renderer.SetDrawColor(0, 255, 0, 220); Renderer.DrawLine(x1, y1, x2, y2); Renderer.DrawLine(x2, y2, x3, y3); Renderer.DrawLine(x3, y3, x4, y4); Renderer.DrawLine(x4, y4, x1, y1);
                        local cx = (x1 + x3) / 2; local cy = (y1 + y3) / 2; Renderer.SetDrawColor(0, 255, 0, 50); Renderer.DrawFilledRect(cx - 4, cy - 4, 8, 8);
                    end
                end
            end
        end
    end
    local pulse = math.floor((math.sin(GameRules.GetGameTime() * 4) * 0.5 + 0.5) * 4) + 6
    local clickOnce = Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1)
    local function hit(pt)
        if not pt then return false end
        local x, y, vis = Renderer.WorldToScreen(pt); if not vis then return false end
        return Input.IsCursorInRect(x - 10, y - 10, 20, 20)
    end
    if not v166_dragging then
        if Input.IsKeyDown(Enum.ButtonCode.KEY_LCONTROL) and clickOnce then
            if v133 and hit(v133) then v166_dragging = true; v167_dragTarget = "wait" end
            if v134 and hit(v134) then v166_dragging = true; v167_dragTarget = "pull" end
        end
    else
        local wp = Input.GetWorldCursorPos()
        if v167_dragTarget == "wait" and v133 then v133 = Vector(wp:GetX(), wp:GetY(), v133:GetZ()) end
        if v167_dragTarget == "pull" and v134 then v134 = Vector(wp:GetX(), wp:GetY(), v134:GetZ()) end
        if clickOnce then v166_dragging = false; v167_dragTarget = nil; v155_SaveIfComplete() end
    end
    if v133 then local x, y, vis = Renderer.WorldToScreen(v133); if vis then Renderer.SetDrawColor(0, 200, 255, 220); Renderer.DrawFilledCircle(x, y, pulse); Renderer.SetDrawColor(0, 120, 255, 255); Renderer.DrawOutlineCircle(x, y, pulse + 2, 32); Renderer.DrawText(Renderer.LoadFont("Tahoma", 12, Enum.FontWeight.BOLD), x + 10, y - 6, "ATTACK FROM"); end end
    if v134 then local x, y, vis = Renderer.WorldToScreen(v134); if vis then Renderer.SetDrawColor(255, 200, 0, 220); Renderer.DrawFilledCircle(x, y, pulse); Renderer.SetDrawColor(255, 140, 0, 255); Renderer.DrawOutlineCircle(x, y, pulse + 2, 32); Renderer.DrawText(Renderer.LoadFont("Tahoma", 12, Enum.FontWeight.BOLD), x + 10, y - 6, "RUN TO"); end end
    for unit, camp in pairs(v171_unitCamp) do
        local key = camp and v152(camp) or nil; local preset = key and v148[key] or nil
        local strike = camp and (v175_campStrike[camp] or v18(camp)) or nil
        local w = nil; local p = nil
        if preset and preset.wait then w = Vector(preset.wait.x, preset.wait.y, preset.wait.z) end
        if preset and preset.pull then p = Vector(preset.pull.x, preset.pull.y, preset.pull.z) end
        if (not w or not p) and strike then
            if not w then w = (strike + Vector(250, 0, 0)) end
            if not p then p = (strike + Vector(-250, 0, 0)) end
        end
        if w and p then
            local x1, y1, s1 = Renderer.WorldToScreen(w); local x2, y2, s2 = Renderer.WorldToScreen(p)
            if s1 and s2 then
                Renderer.SetDrawColor(255, 255, 255, 140); Renderer.DrawLine(x1, y1, x2, y2)
                local dx = x2 - x1; local dy = y2 - y1; local len = math.sqrt(dx * dx + dy * dy)
                if (len > 0) then
                    local ux = dx / len; local uy = dy / len; local px = -uy; local py = ux; local hx = x2; local hy = y2
                    local a1x = hx - ux * 12 + px * 6; local a1y = hy - uy * 12 + py * 6; local a2x = hx - ux * 12 - px * 6; local a2y = hy - uy * 12 - py * 6
                    Renderer.DrawLine(hx, hy, a1x, a1y); Renderer.DrawLine(hx, hy, a2x, a2y)
                end
            end
            local pulse = math.floor((math.sin(GameRules.GetGameTime() * 4) * 0.5 + 0.5) * 4) + 6
            do local xw, yw, visw = Renderer.WorldToScreen(w); if visw then Renderer.SetDrawColor(0, 200, 255, 220); Renderer.DrawFilledCircle(xw, yw, pulse); Renderer.SetDrawColor(0, 120, 255, 255); Renderer.DrawOutlineCircle(xw, yw, pulse + 2, 32); Renderer.DrawText(Renderer.LoadFont("Tahoma", 12, Enum.FontWeight.BOLD), xw + 10, yw - 6, "ATTACK FROM"); end end
            do local xp, yp, visp = Renderer.WorldToScreen(p); if visp then Renderer.SetDrawColor(255, 200, 0, 220); Renderer.DrawFilledCircle(xp, yp, pulse); Renderer.SetDrawColor(255, 140, 0, 255); Renderer.DrawOutlineCircle(xp, yp, pulse + 2, 32); Renderer.DrawText(Renderer.LoadFont("Tahoma", 12, Enum.FontWeight.BOLD), xp + 10, yp - 6, "RUN TO"); end end
            local up = Entity.GetAbsOrigin(unit); local ux, uy, us = Renderer.WorldToScreen(up)
            local target = nil
            local t = v17(); local minute = math.floor(t / 60); local sec = math.floor(t % 60)
            local st = v15[unit] and v15[unit][minute]
            if st then
                local attackSec = v124:Get(); local waitTo = v127:Get()
                local lastAttackMinute = v120[unit]; local curMinute = minute; local inNextMinute = (lastAttackMinute ~= nil) and (curMinute > lastAttackMinute) or false
                if (inNextMinute and (sec < waitTo)) then
                    target = p
                elseif ((sec < attackSec) or (not st.attackDone)) then
                    target = w
                else
                    if (not st.pullDone) then
                        if (not v143[unit]) or (GameRules.GetGameTime() >= v143[unit]) then target = p end
                    else
                        if (inNextMinute and (sec >= waitTo)) then target = w else target = p end
                    end
                end
            end
            if target and us then
                local tx, ty, ts = Renderer.WorldToScreen(target)
                if ts then
                    Renderer.SetDrawColor(0, 220, 255, 200); Renderer.DrawLine(ux, uy, tx, ty)
                    local dx = tx - ux; local dy = ty - uy; local len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then
                        local uxv = dx / len; local uyv = dy / len; local pxv = -uyv; local pyv = uxv; local hx, hy = tx, ty
                        local a1x = hx - uxv * 10 + pxv * 5; local a1y = hy - uyv * 10 + pyv * 5; local a2x = hx - uxv * 10 - pxv * 5; local a2y = hy - uyv * 10 - pyv * 5
                        Renderer.DrawLine(hx, hy, a1x, a1y); Renderer.DrawLine(hx, hy, a2x, a2y)
                    end
                end
            end
        end
    end
    local overlayFont = Renderer.LoadFont("Tahoma", v161:Get(), Enum.FontWeight.BOLD)
    for unit, camp in pairs(v171_unitCamp) do
        local sc = camp and (v175_campStrike[camp] or v18(camp)) or nil
        if sc then
            local cx, cy, vis = Renderer.WorldToScreen(sc); if vis then
                local w = 260; local baseH = 96
                local info = {}
                local key = v152(camp); local preset = key and v148[key] or nil
                local wPt = preset and preset.wait and Vector(preset.wait.x, preset.wait.y, preset.wait.z) or nil
                local pPt = preset and preset.pull and Vector(preset.pull.x, preset.pull.y, preset.pull.z) or nil
                if not wPt then table.insert(info, "1) Set point 1 (ATTACK FROM)") end
                if not pPt then table.insert(info, "2) Set point 2 (RUN TO)") end
                if wPt and pPt then table.insert(info, "Stacking activated") end
                local lineStep = v161:Get() + 4; local infoH = (#info) * lineStep + 4; local h = baseH + infoH
                local ox = math.floor(cx - w / 2); local oy = math.floor(cy - 120)
                Renderer.SetDrawColor(25, 25, 28, v164:Get()); Renderer.DrawFilledRect(ox, oy, w, h)
                Renderer.SetDrawColor(255, 255, 255, 255)
                for i = 1, #info do Renderer.DrawText(overlayFont, ox + 10, oy + 8 + (i - 1) * lineStep, info[i]) end
                local aS, wT, aT = v157_getCampOpts(camp)
                local function row(y, label, value, fmt)
                    Renderer.DrawText(overlayFont, ox + 10, y, label .. ": " .. string.format(fmt, value))
                    local bxm, bym, bw, bh = ox + w - 70, y, 24, 18
                    local bxp, byp = ox + w - 36, y
                    Renderer.SetDrawColor(60, 60, 65, 230); Renderer.DrawFilledRect(bxm, bym, bw, bh); Renderer.DrawFilledRect(bxp, byp, bw, bh)
                    Renderer.SetDrawColor(220, 220, 220, 255)
                    Renderer.DrawText(overlayFont, bxm + 7, bym, "-")
                    Renderer.DrawText(overlayFont, bxp + 6, byp, "+")
                    return bxm, bym, bw, bh, bxp, byp
                end
                local yBase = oy + infoH + 10
                local y1 = yBase; local m1x, m1y, mw, mh, p1x, p1y = row(y1, "Attack second", aS, "%d")
                local y2 = yBase + 26; local m2x, m2y, _, _, p2x, p2y = row(y2, "Wait until sec", wT, "%d")
                local y3 = yBase + 52; local m3x, m3y, _, _, p3x, p3y = row(y3, "Attack time", aT, "%.1f")
                local click = Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1)
                local function inRect(x, y, rw, rh) return Input.IsCursorInRect(x, y, rw, rh) end
                if click then
                    local changed = false
                    if inRect(m1x, m1y, mw, mh) then aS = math.max(0, math.min(59, aS - 1)); changed = true end
                    if inRect(p1x, p1y, mw, mh) then aS = math.max(0, math.min(59, aS + 1)); changed = true end
                    if inRect(m2x, m2y, mw, mh) then wT = math.max(0, math.min(59, wT - 1)); changed = true end
                    if inRect(p2x, p2y, mw, mh) then wT = math.max(0, math.min(59, wT + 1)); changed = true end
                    if inRect(m3x, m3y, mw, mh) then aT = math.max(0, math.min(2, math.floor((aT - 0.1) * 10 + 0.5) / 10)); changed = true end
                    if inRect(p3x, p3y, mw, mh) then aT = math.max(0, math.min(2, math.floor((aT + 0.1) * 10 + 0.5) / 10)); changed = true end
                    if changed then v158_SaveCampOpts(camp, aS, wT, aT); v155_SaveIfComplete() end
                end
            end
        end
    end
end

local function OnPrepareUnitOrders(params)
    if not v5 then return end
    local p = params or {}
    local orderType = p.order or p.orderType or p.type
    if not orderType then return end
    if (orderType ~= Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE) and (orderType ~= Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET) then return end
    local units = p.units or p.entities or p.selectedEntities
    local unit = p.unit or p.npc or p.entity
    local list = {}
    if units and type(units) == "table" then for i = 1, #units do list[#list + 1] = units[i] end end
    if unit then list[#list + 1] = unit end
    if #list == 0 then return end
    local involvesTracked = false; local trackedUnit = nil
    for i = 1, #list do
        local u = list[i]
        for j = 1, #v12 do if v12[j] == u then involvesTracked = true; trackedUnit = u; break end end
        if involvesTracked then break end
    end
    if not involvesTracked then return end
    local now = GameRules.GetGameTime(); local t = v17(); local minute = math.floor(t / 60); local second = math.floor(t % 60)
    local allow = false
    if trackedUnit and v143[trackedUnit] and (now < v143[trackedUnit]) then allow = true end
    local st = trackedUnit and v15[trackedUnit] and v15[trackedUnit][minute] or nil
    if st and (not st.attackDone) and (second == v124:Get()) then allow = true end
    if not allow then return true end
end

return { OnUpdate = OnUpdate, OnDraw = OnDraw, OnPrepareUnitOrders = OnPrepareUnitOrders };
