local v0=Menu.Create("Scripts","User Scripts","UnitPush");v0:Icon("\u{f0e7}");local v1=v0:Create("Options"):Create("Main");local v2=v1:Bind("Activate Bot",Enum.ButtonCode.KEY_0,"panorama/images/spellicons/rattletrap_power_cogs_png.vtex_c");local v3=nil;local v4=nil;local v5=1;local v6=0;local v7=150;local v8=false;local v9=false;local v10=false;local v11={Vector( -6633, -3412,256),Vector( -6688, -3085,256),Vector( -6688, -2812,128),Vector( -6633, -2484,137),Vector( -6633, -2156,128),Vector( -6633, -1993,128),Vector( -6688, -1665,128),Vector( -6579, -1338,128),Vector( -6524, -901,128),Vector( -6469, -573,128),Vector( -6469, -300,128),Vector( -6469,27,128),Vector( -6469,300,128),Vector( -6360,628,128),Vector( -6415,955,128),Vector( -6415,1392,128),Vector( -6360,1829,128),Vector( -6360,2320,128),Vector( -6360,2702,128),Vector( -6306,3030,128),Vector( -6251,3685,128),Vector( -6251,4231,128),Vector( -6251,4613,128),Vector( -6087,5105,128),Vector( -5814,5487,128),Vector( -5487,5650,128),Vector( -5050,5978,128),Vector( -4449,6033,128),Vector( -3958,6033,128),Vector( -3521,6033,128),Vector( -3030,6196,128),Vector( -2539,6087,128),Vector( -1938,6142,0),Vector( -1447,6142,45),Vector( -1119,6142,128),Vector( -573,6142,128),Vector( -136,5978,128),Vector(246,5978,128),Vector(573,5978,128),Vector(901,5978,128),Vector(1283,5923,128),Vector(1665,5923,128),Vector(2102,5869,128),Vector(2320,5814,136),Vector(2539,5760,128),Vector(2812,5814,128),Vector(3194,5814,256),Vector(3467,5814,256)};local v12={Vector( -4613, -4067,256),Vector( -4449, -3903,256),Vector( -4176, -3740,128),Vector( -3958, -3576,134),Vector( -3740, -3467,128),Vector( -3576, -3303,128),Vector( -3358, -3139,128),Vector( -3139, -2975,128),Vector( -2975, -2812,128),Vector( -2866, -2593,128),Vector( -2757, -2429,128),Vector( -2648, -2320,128),Vector( -2429, -2047,128),Vector( -2211, -1883,128),Vector( -1993, -1665,128),Vector( -1774, -1447,128),Vector( -1556, -1228,128),Vector( -1338, -1065,128),Vector( -1174, -901,128),Vector( -1065, -737,128),Vector( -628, -300,0),Vector( -136,191,128),Vector(191,409,128),Vector(519,573,128),Vector(901,955,128),Vector(1228,1283,128),Vector(1556,1501,128),Vector(1829,1665,128),Vector(2156,1883,128),Vector(2375,2102,128),Vector(2648,2320,128),Vector(2921,2593,128),Vector(3139,2812,128),Vector(3358,2975,135),Vector(3576,3139,128),Vector(3849,3358,148),Vector(4122,3685,256)};local v13={Vector( -3958, -6142,256),Vector( -3576, -6087,252),Vector( -3194, -6087,128),Vector( -2921, -6142,137),Vector( -2593, -6142,128),Vector( -2266, -6196,128),Vector( -2047, -6142,128),Vector( -1720, -6196,128),Vector( -1501, -6251,128),Vector( -1283, -6251,128),Vector( -1065, -6251,128),Vector( -792, -6251,128),Vector( -573, -6251,128),Vector( -409, -6251,128),Vector( -136, -6196,128),Vector(82, -6196,128),Vector(246, -6196,128),Vector(409, -6251,128),Vector(1174, -6306,0),Vector(2211, -6196,128),Vector(2702, -6196,128),Vector(3139, -6142,128),Vector(3521, -6142,128),Vector(3958, -6142,128),Vector(4449, -6142,128),Vector(4832, -6087,128),Vector(5105, -5923,128),Vector(5487, -5869,128),Vector(5541, -5596,128),Vector(5760, -5377,128),Vector(5814, -5050,128),Vector(5869, -4777,128),Vector(6033, -4449,128),Vector(6033, -4231,128),Vector(6033, -4067,128),Vector(5978, -3849,128),Vector(6033, -3576,128),Vector(6033, -3248,128),Vector(6033, -3030,128),Vector(5978, -2812,128),Vector(5978, -2484,128),Vector(6033, -2266,128),Vector(6033, -1883,128),Vector(6087, -1556,128),Vector(6087, -1338,128),Vector(6087, -1119,128),Vector(6087, -901,128),Vector(6087, -682,128),Vector(6087, -519,128),Vector(6087, -409,128),Vector(6087, -191,128),Vector(6087, -27,128),Vector(6142,246,128),Vector(6087,464,128),Vector(6087,737,128),Vector(6087,1010,128),Vector(6087,1338,128),Vector(6142,1556,128),Vector(6142,1829,128),Vector(6196,2102,128),Vector(6196,2375,164),Vector(6251,3085,256)};

-- Fast one-tick params (UI preserved; tune constants here if needed)
local FAST_MinStep     = 600     -- minimal spacing between kept points
local FAST_MinAngleDeg = 15      -- min angle to keep a "turn" (degrees)
local FAST_MaxOrders   = 18      -- hard cap on number of queued orders

-- Helpers: squared distance, path simplify, clamp
local function __dist2(a,b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx*dx + dy*dy
end

local function __simplifyPath(points, minStep, minAngleDeg)
    if not points then return nil end
    local n = #points
    if n <= 2 then return points end

    local out = {}
    out[#out+1] = points[1]
    local minStep2 = (minStep or FAST_MinStep) * (minStep or FAST_MinStep)
    local cosThr = math.cos(((minAngleDeg or FAST_MinAngleDeg) * math.pi) / 180)

    local lastKeep = points[1]
    for i = 2, n - 1 do
        local p = points[i]
        if __dist2(p, lastKeep) >= minStep2 then
            local a = lastKeep
            local c = points[i+1]
            local v1x, v1y = p.x - a.x, p.y - a.y
            local v2x, v2y = c.x - p.x, c.y - p.y
            local l1 = math.sqrt(v1x*v1x + v1y*v1y)
            local l2 = math.sqrt(v2x*v2x + v2y*v2y)

            local keep = true
            if l1 > 0 and l2 > 0 then
                local cosAng = (v1x*v2x + v1y*v2y) / (l1 * l2)
                if cosAng > cosThr then
                    keep = false
                end
            end

            if keep then
                out[#out+1] = p
                lastKeep = p
            end
        end
    end

    out[#out+1] = points[n]
    return out
end

local function __clampPath(points, maxCount)
    if not points then return nil end
    local n = #points
    if n <= maxCount then return points end
    local out = {}
    for i = 1, maxCount do
        local idx = math.floor((i - 1) * (n - 1) / (maxCount - 1)) + 1
        out[i] = points[idx]
    end
    return out
end

local function v14(v17) local v18={};for v48= #v17,1, -1 do table.insert(v18,v17[v48]);end return v18;end local function v15(v19) local v20=Entity.GetAbsOrigin(v19);local function v21(v49) local v50=math.huge;for v59,v60 in ipairs(v49) do local v61=(v60-v20):Length2D();if (v61<v50) then v50=v61;end end return v50;end local v22=v21(v11);local v23=v21(v12);local v24=v21(v13);local v25=math.min(v22,v23,v24);local v26={};if (v25==v22) then print("[DEBUG] Hero is closer to top line.");v26=v11;elseif (v25==v23) then print("[DEBUG] Hero is closer to mid line.");v26=v12;else print("[DEBUG] Hero is closer to bot line.");v26=v13;end local v27=Entity.GetTeamNum(v19);if (v27==2) then return v26;else return v14(v26);end end local function v16(v28) local v29=Entity.GetAbsOrigin(v28);local v30=Entity.GetTeamNum(v28);local v31=nil;if (v30==2) then v31=Vector(5595,5104,256);elseif (v30==3) then v31=Vector( -6087, -5268,256);else return nil;end local v32=v15(v28);local function v33(v51,v52) local v53,v54=1,math.huge;for v62,v63 in ipairs(v52) do local v64=(v63-v51):Length2D();if (v64<v54) then v54=v64;v53=v62;end end return v53,v54;end local v34,v35=v33(v29,v32);local v36=v32[v34];local v37,v35=v33(v31,v32);local v38=v32[v37];local v39=GridNav.BuildPath(v29,v36,false,nil);if ( not v39 or ( #v39<1)) then print("[DEBUG] Failed subPathA (hero->line).");return nil;end local v40={};if (v34<=v37) then for v66=v34,v37 do table.insert(v40,v32[v66]);end else for v67=v34,v37, -1 do table.insert(v40,v32[v67]);end end local v41=GridNav.BuildPath(v38,v31,false,nil);if ( not v41 or ( #v41<1)) then print("[DEBUG] Failed subPathC (line->throne).");return nil;end local v42={};for v55,v56 in ipairs(v39) do table.insert(v42,v56);end for v57=2, #v40 do table.insert(v42,v40[v57]);end for v58=2, #v41 do table.insert(v42,v41[v58]);end print(string.format("[DEBUG] Built route with %d points. Entry index: %d, Exit index: %d", #v42,v34,v37));return v42;end function OnUpdate() local v43=Players.GetLocal();local v44=v2:IsPressed();if (v44 and  not v9) then v8= not v8;print("[DEBUG] Bot active toggled to "   .. tostring(v8) );if v8 then v3=Player.GetSelectedUnits(v43) or {} ;print("[DEBUG] Controlled units updated, count: "   ..  #v3 );else v3=nil;end v4=nil;v5=1;end v9=v44;if  not v8 then return;end if ( not v3 or ( #v3==0)) then print("[DEBUG] No controlled units available.");return;end local v45=v3[1];if  not v45 then return;end if  not v4 then v4=v16(v45);if (v4 and ( #v4>0)) then 
    -- FAST: simplify & clamp before queuing (UI preserved)
    v4 = __simplifyPath(v4, FAST_MinStep, FAST_MinAngleDeg);
    v4 = __clampPath(v4, FAST_MaxOrders);
    v5=1;v6=os.clock();print("[DEBUG] Group route computed with "   ..  #v4   .. " points for "   .. NPC.GetUnitName(v45) );
else print("[DEBUG] Failed to compute group route for "   .. NPC.GetUnitName(v45) );return;end else print("[DEBUG] Using existing group route");end local v46=Entity.GetAbsOrigin(v45);local v47=v4[v5];if v47 then local v65=(v46-v47):Length2D();print("[DEBUG] Leader distance to waypoint "   .. v5   .. ": "   .. v65 );if (v65<v7) then v5=v5 + 1 ;if (v5> #v4) then print("[DEBUG] Leader reached final waypoint; route completed.");v4=nil;return;else v47=v4[v5];print("[DEBUG] Switching leader to waypoint "   .. v5 );end end 
-- FAST: send first order with queue=false to clear old queue, then queue the rest
if (v5<=#v4) then
    Player.PrepareUnitOrders(v43,Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,nil,v4[v5],nil,Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS,v3,false);
    for v68=v5+1, #v4 do
        local v69=v4[v68];
        Player.PrepareUnitOrders(v43,Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,nil,v69,nil,Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS,v3,true);
    end
end
print("[DEBUG] Queued "   .. (( #v4-v5) + 1)   .. " orders for group. Shutting down bot." );v8=false;v3=nil;v4=nil;v5=1;return;else print("[DEBUG] Current target waypoint is nil.");end end return {OnUpdate=OnUpdate};