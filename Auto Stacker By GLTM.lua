---@diagnostic disable: undefined-global


local Stacker = {}


local menuRoot = Menu.Create("Scripts", "User Scripts", "Auto Stacker")
menuRoot:Icon("\u{f0c9}")
local menuOptions = menuRoot:Create("Settings")
local mainMenu = menuOptions:Create("Main")
local ui = {}


ui.enable = mainMenu:Switch("Enable", false)
ui.enable:Icon("\u{f00c}")

ui.toggleKey = mainMenu:Bind("Activation Key", Enum.ButtonCode.KEY_NONE, "panorama/images/items/shivas_guard_png.vtex_c")

local mainMenu = menuOptions:Create("Information")
mainMenu:Label("More scripts - discord.gg/glitch-realm")


local firstHitSecMelee = 53
local firstHitSecRanged = 53
local perStackShiftCenti = 40


local availableFonts = {"Tahoma","Arial","Verdana","Segoe UI","Consolas","Courier New","Calibri"};
local debugDraw = false;
local debugFontSize = 16;
local fancyVisuals = true;
local debugFontFamily = 0;
local overlayFontCache = {};
local function getRenderFont(fontName)
	local key = fontName or "Tahoma";
	if not overlayFontCache[key] then
		overlayFontCache[key] = Render.LoadFont(key, Enum.FontCreate.FONTFLAG_ANTIALIAS);
	end
	return overlayFontCache[key];
end
local isActive = false;
local wasToggleHeld = false;
local overlayX, overlayY = 10, 10;
local isDragging = false;
local dragDx, dragDy = 0, 0;
db = db or {};
db.autoStackerPanel = db.autoStackerPanel or {};
local panel_info = db.autoStackerPanel;
if (type(panel_info.x) == "number") then
	overlayX = panel_info.x;
end
if (type(panel_info.y) == "number") then
	overlayY = panel_info.y;
end
local selectedUnits = {};
local selectedUnitsSet = {};
local unitToCampId = {};
local CAMP_POINTS = {[1]={wait=Vector(-742, 4325, 134),pull=Vector(-682, 3881, 236)},[2]={wait=Vector(2943, -796, 256),pull=Vector(2817, -53, 256)},[3]={wait=Vector(4082, -5526, 128),pull=Vector(4181, -6368, 128)},[4]={wait=Vector(8255, -734, 256),pull=Vector(8204, -1369, 256)},[5]={wait=Vector(-4806, 4534, 128),pull=Vector(-4884, 5071, 128)},[6]={wait=Vector(4284, -4110, 128),pull=Vector(3622, -4505, 128)},[7]={wait=Vector(-2121, -3921, 128),pull=Vector(-1564, -4531, 128)},[8]={wait=Vector(262, -4751, 136),pull=Vector(333, -4101, 254)},[9]={wait=Vector(-4509, 361, 256),pull=Vector(-5031, 1121, 128)},[10]={wait=Vector(4072, -421, 256),pull=Vector(4276, -1359, 128)},[11]={wait=Vector(-1274, -4908, 128),pull=Vector(-812, -5282, 128)},[12]={wait=Vector(1515, 8209, 128),pull=Vector(792, 8152, 128)},[13]={wait=Vector(455, 3965, 134),pull=Vector(-78, 3932, 136)},[14]={wait=Vector(-4144, 322, 256),pull=Vector(-5031, 1121, 128)},[15]={wait=Vector(316, -8138, 134),pull=Vector(954, -8538, 136)},[16]={wait=Vector(-2529, -7737, 134),pull=Vector(-2690, -7154, 134)},[17]={wait=Vector(-479, 7639, 134),pull=Vector(-551, 6961, 128)},[18]={wait=Vector(-4743, 7534, 0),pull=Vector(-4832, 7136, 0)},[19]={wait=Vector(1348, 3263, 128),pull=Vector(1683, 3710, 128)},[20]={wait=Vector(7969, 1047, 256),pull=Vector(7681, 695, 256)},[21]={wait=Vector(-7735, -183, 256),pull=Vector(-7436, 685, 256)},[22]={wait=Vector(-3962, 7564, 0),pull=Vector(-4521, 7474, 8)},[23]={wait=Vector(-2589, 4502, 256),pull=Vector(-2651, 5138, 256)},[24]={wait=Vector(3522, -8186, 8),pull=Vector(4028, -7376, 0)},[25]={wait=Vector(1501, -4208, 256),pull=Vector(1094, -5103, 136)},[26]={wait=Vector(-4338, 4903, 128),pull=Vector(-5198, 4877, 128)},[27]={wait=Vector(-7757, -1219, 256),pull=Vector(-7693, -727, 256)},[28]={wait=Vector(4781, -7812, 8),pull=Vector(4510, -7260, 82)}};
local ACTIVE_POINTS = {};
local stack_presets = {};
local stack_presets_loaded = false;
local stack_presets_file_exists = false;
local active_preset_name = nil;
local selected_preset_name = nil;
local builder_state = {enabled=false,show_all=true,dragging=false,dragCamp=nil,dragType=nil};
local presets_ui = nil;
local function DeepCopyCampPoints(src)
	local out = {};
	for campId, pts in pairs(src or {}) do
		out[campId] = {wait=Vector(pts.wait:GetX(), pts.wait:GetY(), pts.wait:GetZ()),pull=Vector(pts.pull:GetX(), pts.pull:GetY(), pts.pull:GetZ())};
	end
	return out;
end
local function GetStackPresetsPath()
	return "stack_presets.json";
end
local function vecToTable(v)
	if not v then
		return nil;
	end
	return {x=v:GetX(),y=v:GetY(),z=v:GetZ()};
end
local function tableToVector(t)
	if not t then
		return nil;
	end
	return Vector(t.x or 0, t.y or 0, t.z or 0);
end
local function MapToArray(map)
	local arr = {};
	for campId, pts in pairs(map or {}) do
		local entry = {campId=campId,wait=vecToTable(pts.wait),pull=vecToTable(pts.pull)};
		table.insert(arr, entry);
	end
	return arr;
end
local function ArrayToMap(arr)
	local map = {};
	for _, e in ipairs(arr or {}) do
		if (e and e.campId) then
			map[e.campId] = {wait=tableToVector(e.wait),pull=tableToVector(e.pull)};
		end
	end
	return map;
end
local function RebuildActivePoints()
	ACTIVE_POINTS = DeepCopyCampPoints(CAMP_POINTS);
	if (active_preset_name and stack_presets[active_preset_name] and stack_presets[active_preset_name].points) then
		for campId, pts in pairs(stack_presets[active_preset_name].points) do
			if ACTIVE_POINTS[campId] then
				if pts.wait then
					ACTIVE_POINTS[campId].wait = Vector(pts.wait:GetX(), pts.wait:GetY(), pts.wait:GetZ());
				end
				if pts.pull then
					ACTIVE_POINTS[campId].pull = Vector(pts.pull:GetX(), pts.pull:GetY(), pts.pull:GetZ());
				end
			else
				ACTIVE_POINTS[campId] = {wait=((pts.wait and Vector(pts.wait:GetX(), pts.wait:GetY(), pts.wait:GetZ())) or Vector(0, 0, 0)),pull=((pts.pull and Vector(pts.pull:GetX(), pts.pull:GetY(), pts.pull:GetZ())) or Vector(0, 0, 0))};
			end
		end
	end
end
local function SaveStackPresets()
	local JSON = require("assets.JSON");
	local file = io.open(GetStackPresetsPath(), "w");
	if file then
		local serializable = {};
		for name, preset in pairs(stack_presets) do
			local points_arr = MapToArray(preset.points or {});
			local entry = {name=name,points=points_arr};
			table.insert(serializable, entry);
		end
		local data = {presets=serializable,active=active_preset_name};
		local json_string = JSON.encode(JSON, data);
		file:write(json_string);
		file:close();
		print(string.format("[Stacker Presets] saved %d preset(s) to %s (active=%s)", #serializable, GetStackPresetsPath(), tostring(active_preset_name)));
	else
		print("[Stacker Presets] ERROR: could not save presets file!");
	end
end
local function LoadStackPresets()
	if stack_presets_loaded then
		return;
	end
	local JSON = require("assets.JSON");
	local file = io.open(GetStackPresetsPath(), "r");
	if file then
		stack_presets_file_exists = true;
		local content = file:read("*all");
		file:close();
		if (content and not string.match(content, "^%s*$")) then
			local ok, data = pcall(JSON.decode, JSON, content);
			if (ok and (type(data) == "table")) then
				stack_presets = {};
				for _, p in ipairs(data.presets or {}) do
					if (p and p.name) then
						stack_presets[p.name] = {points=ArrayToMap(p.points or {})};
					end
				end
				active_preset_name = data.active or "Default";
			else
				stack_presets = {};
			end
		else
			stack_presets = {};
		end
	else
		stack_presets_file_exists = false;
		stack_presets = {};
	end
	if not stack_presets['Default'] then
		stack_presets['Default'] = {points=DeepCopyCampPoints(CAMP_POINTS)};
		active_preset_name = active_preset_name or "Default";
		SaveStackPresets();
	end
	stack_presets_loaded = true;
	RebuildActivePoints();
end
local function GetPresetNames()
	local names = {};
	if stack_presets['Default'] then
		table.insert(names, "Default");
	end
	local others = {};
	for name, _ in pairs(stack_presets) do
		if (name ~= "Default") then
			table.insert(others, name);
		end
	end
	table.sort(others);
	for _, n in ipairs(others) do
		table.insert(names, n);
	end
	return names;
end
local function getCampPoints(campId)
	return ACTIVE_POINTS[campId] or CAMP_POINTS[campId];
end
local campStrikeCenters = {};
local campBoxes = {};
local campStacks = {};
local campStacksMinute = {};
local campEffFirstHit = {};
local lastCampStacks = {};
local STACK_MODIFIERS = {"modifier_stacked_neutral"};
local timeline = {};
local function safeCall(fn, ...)
	local ok, res = pcall(fn, ...);
	if not ok then
		return nil;
	end
	return res;
end
local function isEntityValid(e)
	if not e then
		return false;
	end
	return safeCall(Entity.GetAbsOrigin, e) ~= nil;
end
local function isEntityAlive(e)
	if not isEntityValid(e) then
		return false;
	end
	local res = safeCall(Entity.IsAlive, e);
	return res == true;
end
local function isUnitRanged(unit)
	local ok = safeCall(NPC.IsRanged, unit);
	if (ok ~= nil) then
		return ok == true;
	end
	local baseRange = safeCall(NPC.GetAttackRange, unit) or 150;
	return baseRange > 250;
end
local function gameTimeSeconds()
	local t = GameRules.GetGameTime() - GameRules.GetGameStartTime();
	if (t < 0) then
		t = 0;
	end
	return t;
end
local function getCampBoxCenter(camp)
	if not camp then
		return nil;
	end
	local box = Camp.GetCampBox(camp);
	if (not box or not box.min or not box.max) then
		return nil;
	end
	local cx = (box.min:GetX() + box.max:GetX()) / 2;
	local cy = (box.min:GetY() + box.max:GetY()) / 2;
	local cz = (box.min:GetZ() + box.max:GetZ()) / 2;
	return Vector(cx, cy, cz);
end
local function findClosestRealCamp(pos)
	local all = Camps.GetAll();
	if (not all or (#all == 0)) then
		return nil;
	end
	local bestCamp, bestDist = nil, math.huge;
	for _, c in ipairs(all) do
		local center = getCampBoxCenter(c);
		if center then
			local d = (center - pos):Length2D();
			if (d < bestDist) then
				bestDist = d;
				bestCamp = c;
			end
		end
	end
	return bestCamp;
end
local function ensureStrikeCenterForCamp(campId)
	if campStrikeCenters[campId] then
		return;
	end
	local points = getCampPoints(campId);
	if not points then
		return;
	end
	local realCamp = findClosestRealCamp(points.wait);
	if not realCamp then
				print("[AutoStacker] Real camp not found for camp #" .. tostring(campId));
		return;
	end
	local center = getCampBoxCenter(realCamp);
	if center then
		campStrikeCenters[campId] = center;
		local box = Camp.GetCampBox(realCamp);
		if (box and box.min and box.max) then
			campBoxes[campId] = {min=box.min,max=box.max};
		end
			print(string.format("[AutoStacker] Strike center calculated for camp #%d: (%.0f, %.0f, %.0f)", campId, center:GetX(), center:GetY(), center:GetZ()));
	else
		print("[AutoStacker] Cannot calculate strike center for camp #" .. tostring(campId));
	end
end
local function assignUnitsToNearestCamps(units)
	local assignment = {};
	local availableCampIds = {};
	for campId, _ in pairs(CAMP_POINTS) do
		table.insert(availableCampIds, campId);
	end
	if (#units <= #availableCampIds) then
		for _, u in ipairs(units) do
			local unitPos = (isEntityValid(u) and safeCall(Entity.GetAbsOrigin, u)) or nil;
			if unitPos then
				local bestCamp, bestDist, bestIdx = nil, math.huge, nil;
				for idx, campId in ipairs(availableCampIds) do
					local pts = getCampPoints(campId);
					local d = (pts.wait - unitPos):Length2D();
					if (d < bestDist) then
						bestDist = d;
						bestCamp = campId;
						bestIdx = idx;
					end
				end
				if bestCamp then
					assignment[u] = bestCamp;
					table.remove(availableCampIds, bestIdx);
				end
			end
		end
	else
		for _, u in ipairs(units) do
			local unitPos = (isEntityValid(u) and safeCall(Entity.GetAbsOrigin, u)) or nil;
			if unitPos then
				local bestCamp, bestDist = nil, math.huge;
				for campId, _ in pairs(CAMP_POINTS) do
					local pts = getCampPoints(campId);
					local d = (pts.wait - unitPos):Length2D();
					if (d < bestDist) then
						bestDist = d;
						bestCamp = campId;
					end
				end
				assignment[u] = bestCamp;
			end
		end
	end
	return assignment;
end
local function beginSession()
	local player = Players.GetLocal();
	local sel = Player.GetSelectedUnits(player) or {};
	if (#sel == 0) then
		print("[AutoStacker] No selected units.");
		return false;
	end
	selectedUnits, selectedUnitsSet = {}, {};
	for _, u in ipairs(sel) do
		if isEntityValid(u) then
			selectedUnitsSet[u] = true;
			table.insert(selectedUnits, u);
		end
	end
	if (#selectedUnits == 0) then
		print("[AutoStacker] No valid units in selection.");
		return false;
	end
	unitToCampId = assignUnitsToNearestCamps(selectedUnits);
	lastCampStacks = {};
	for _, campId in ipairs((function()
		local ids = {};
		for _, id in pairs(unitToCampId) do
			table.insert(ids, id);
		end
		return ids;
	end)()) do
		ensureStrikeCenterForCamp(campId);
	end
	timeline = {};
	return true;
end
local function ensureTimelineFor(unit, minute)
	if not timeline[unit] then
		timeline[unit] = {};
	end
	if not timeline[unit][minute] then
		timeline[unit][minute] = {movedToWait=false,attackIssued=false,hitConfirmed=false,pullIssued=false};
	end
	return timeline[unit][minute];
end
local function pointInsideBox(pos, box, margin)
	if (not box or not box.min or not box.max) then
		return false;
	end
	margin = margin or 0;
	local x, y = pos:GetX(), pos:GetY();
	return (x >= (box.min:GetX() - margin)) and (x <= (box.max:GetX() + margin)) and (y >= (box.min:GetY() - margin)) and (y <= (box.max:GetY() + margin));
end
local function evaluateCampStacks(campId)
	local box = campBoxes[campId];
	if not box then
		return 0;
	end
	local all = Entities.GetAll();
	local maxStacks = 0;
	for _, e in pairs(all) do
		if (Entity.IsAlive(e) and Entity.IsNPC(e) and NPC.IsCreep(e) and not NPC.IsLaneCreep(e) and not NPC.IsHero(e)) then
			local pos = Entity.GetAbsOrigin(e);
			if pointInsideBox(pos, box, 200) then
				local mod = NPC.GetModifier(e, "modifier_stacked_neutral");
				if mod then
					local c = Modifier.GetStackCount(mod) or 0;
					if (c > maxStacks) then
						maxStacks = c;
					end
				end
			end
		end
	end
	return maxStacks;
end
local function moveUnitTo(player, unit, pos)
	if not isEntityValid(unit) then
		return;
	end
	Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, pos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS, {unit}, false);
end
local function attackMoveUnitTo(player, unit, pos)
	if not isEntityValid(unit) then
		return;
	end
	Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE, nil, pos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS, {unit}, false);
end
function OnUpdate()
	if not stack_presets_loaded then
		LoadStackPresets();
		if not presets_ui then
			local builderMenu = menuRoot:Create("Builder");
			local builderTab = builderMenu:Create("Settings");
			presets_ui = {};
				presets_ui.builder_switch = builderTab:Switch("Builder Mode", false, "\u{f044}");
			presets_ui.show_all = builderTab:Switch("Show All Camps", true, "\u{f06e}");
			presets_ui.preset_select = builderTab:Combo("Preset", GetPresetNames(), 0);
			presets_ui.active_btn = builderTab:Button("Make Active", function()
				local names = GetPresetNames();
				local idx = (presets_ui.preset_select:Get() or 0) + 1;
				local name = names[idx];
				if name then
					active_preset_name = name;
					RebuildActivePoints();
					SaveStackPresets();
					print("[Stacker Presets] Active preset: " .. name);
				end
			end);
			presets_ui.new_name = builderTab:Input("New Preset Name", "My Preset", "\u{f040}");
			presets_ui.create_empty = builderTab:Button("Create Empty Preset", function()
				local name = presets_ui.new_name:Get();
				if (not name or (name == "")) then
					name = "Preset " .. tostring(math.random(1000, 9999));
				end
				if stack_presets[name] then
					print("[Stacker Presets] Error: preset already exists: " .. name);
					return;
				end
				stack_presets[name] = {points={}};
				selected_preset_name = name;
				SaveStackPresets();
				local names = GetPresetNames();
				presets_ui.preset_select:Update(names, math.max(0, #names - 1));
					print("[Stacker Presets] Created empty preset '" .. name .. "'");
			end);
			presets_ui.use_current = builderTab:Button("Save Current Points to Selected", function()
				local names = GetPresetNames();
				local idx = (presets_ui.preset_select:Get() or 0) + 1;
				local name = names[idx];
				if not name then
					print("[Stacker Presets] No preset selected");
					return;
				end
				stack_presets[name] = {points=DeepCopyCampPoints(ACTIVE_POINTS)};
				SaveStackPresets();
					print("[Stacker Presets] Saved current points to preset '" .. name .. "'");
			end);
			presets_ui.delete_btn = builderTab:Button("Delete Selected Preset", function()
				local names = GetPresetNames();
				local idx = (presets_ui.preset_select:Get() or 0) + 1;
				local name = names[idx];
				if (name and (name ~= "Default")) then
					stack_presets[name] = nil;
					SaveStackPresets();
					local upd = GetPresetNames();
					presets_ui.preset_select:Update(upd, 0);
					if (active_preset_name == name) then
						active_preset_name = "Default";
						RebuildActivePoints();
					end
						print("[Stacker Presets] Deleted preset '" .. name .. "'");
				else
					print("[Stacker Presets] Cannot delete or no preset selected: '" .. tostring(name) .. "'");
				end
			end);
			presets_ui.preset_select:SetCallback(function()
				local names = GetPresetNames();
				local idx = (presets_ui.preset_select:Get() or 0) + 1;
				selected_preset_name = names[idx];
			end);
			presets_ui.builder_switch:SetCallback(function()
				builder_state.enabled = presets_ui.builder_switch:Get();
			end, true);
			presets_ui.show_all:SetCallback(function()
				builder_state.show_all = presets_ui.show_all:Get();
			end, true);
		end
	end
	if not ui.enable:Get() then
		if isActive then
			isActive = false;
			selectedUnits, selectedUnitsSet = {}, {};
			unitToCampId, timeline = {}, {};
		end
		return;
	end
	
	local player = Players.GetLocal();
	local pressed = ui.toggleKey:IsPressed();
	if (pressed and not wasToggleHeld) then
		isActive = not isActive;
		print("[AutoStacker] Bot toggled:", isActive);
		if isActive then
			if not beginSession() then
				isActive = false;
			end
		else
			selectedUnits, selectedUnitsSet = {}, {};
			unitToCampId, timeline = {}, {};
		end
	end
	wasToggleHeld = pressed;
	if not isActive then
		return;
	end
	local alive = {};
	for _, u in ipairs(selectedUnits) do
		if isEntityAlive(u) then
			table.insert(alive, u);
		end
	end
	if (#alive == 0) then
			print("[AutoStacker] All units died, disabling bot.");
		isActive = false;
		return;
	end
	local t = gameTimeSeconds();
	local minute = math.floor(t / 60);
	local sec = t % 60;
	for _, u in ipairs(alive) do
		local campId = unitToCampId[u];
		if not campId then
				print("[AutoStacker] Unit assignment missing.");
		else
			local points = getCampPoints(campId);
			local strike = campStrikeCenters[campId];
			if not strike then
				ensureStrikeCenterForCamp(campId);
				strike = campStrikeCenters[campId];
				if not strike then
					goto continue_unit;
				end
			end
			local st = ensureTimelineFor(u, minute);
			local baseHit = (isUnitRanged(u) and firstHitSecRanged) or firstHitSecMelee;
			if (sec >= 50) then
				if ((campStacksMinute[campId] or -1) ~= minute) then
					local stacksNow = evaluateCampStacks(campId);
					local lastStacks = lastCampStacks[campId] or 0;
					campStacks[campId] = stacksNow;
					campStacksMinute[campId] = minute;
					
					if (stacksNow > lastStacks and stacksNow > 0) then
						Notification({
							duration = 3,
							timer = 3,
							primary_text = "Stack successful!",
							primary_image = "panorama/images/spellicons/rattletrap_power_cogs_png.vtex_c",
							secondary_text = string.format("Camp #%d: %d stacks", campId, stacksNow),
							position = getCampPoints(campId) and getCampPoints(campId).wait or nil
						});
						
							print(string.format("[Stacker] ✓ Successful stack! Camp #%d: %d stacks", campId, stacksNow));
					else
						print(string.format("[Stacker] Camp #%d stacks detected: %d", campId, stacksNow));
					end
					
					lastCampStacks[campId] = stacksNow;
				end
			end
			local stacks = campStacks[campId] or 0;
			local perStackShift = perStackShiftCenti / 100;
			local effFirstHit = math.max(52, math.min(54, baseHit - (stacks * perStackShift)));
			campEffFirstHit[campId] = effFirstHit;
			if (sec < effFirstHit) then
				if not st.movedToWait then
					st.movedToWait = true;
					print(string.format("[Stacker] Unit %s at %d:%.2f -> WAIT (%.0f, %.0f, %.0f)", tostring(u), minute, sec, points.wait:GetX(), points.wait:GetY(), points.wait:GetZ()));
					moveUnitTo(player, u, points.wait);
				end
			else
				if ((sec >= effFirstHit) and (sec < (effFirstHit + 2)) and not st.attackIssued) then
					st.attackIssued = true;
					print(string.format("[Stacker] Unit %s at %d:%.2f -> ATTACK (%.0f, %.0f, %.0f) [first=%.1f, stacks=%d, eff=%.1f]", tostring(u), minute, sec, strike:GetX(), strike:GetY(), strike:GetZ(), baseHit, stacks, effFirstHit));
					attackMoveUnitTo(player, u, strike);
				end
				if (st.hitConfirmed and not st.pullIssued) then
					st.pullIssued = true;
					print(string.format("[Stacker] Unit %s at %d:%.2f -> PULL (%.0f, %.0f, %.0f) [on hit]", tostring(u), minute, sec, points.pull:GetX(), points.pull:GetY(), points.pull:GetZ()));
					moveUnitTo(player, u, points.pull);
				elseif ((sec >= 57) and (sec < 58) and not st.pullIssued) then
					st.pullIssued = true;
					print(string.format("[Stacker] Unit %s at %d:%.2f -> PULL (%.0f, %.0f, %.0f) [fallback]", tostring(u), minute, sec, points.pull:GetX(), points.pull:GetY(), points.pull:GetZ()));
					moveUnitTo(player, u, points.pull);
				end
			end
		end
		::continue_unit::;
	end
end
function OnEntityHurt(data)
	if not isActive then
		return;
	end
	if (not data or not data.source) then
		return;
	end
	local src = data.source;
	if not isEntityValid(src) then
		return;
	end
	if not selectedUnitsSet[src] then
		return;
	end
	local target = data.target;
	local t = gameTimeSeconds();
	local minute = math.floor(t / 60);
	local st = ensureTimelineFor(src, minute);
	if (st.attackIssued and not st.hitConfirmed) then
		st.hitConfirmed = true;
		local campId = unitToCampId[src];
		local points = getCampPoints(campId);
		if (target and isEntityValid(target)) then
			local observed = 0;
			for _, name in ipairs(STACK_MODIFIERS) do
				local mod = safeCall(NPC.GetModifier, target, name);
				if mod then
					local c = safeCall(Modifier.GetStackCount, mod) or 0;
					if (c > 0) then
						observed = c;
						break;
					end
				end
			end
			if (observed > 0) then
				campStacks[campId] = observed;
			end
		end
		if (points and not st.pullIssued) then
			st.pullIssued = true;
			print(string.format("[Stacker] Unit %s at %d:%02d -> PULL (%.0f, %.0f, %.0f) [OnEntityHurt]", tostring(src), minute, math.floor(t % 60), points.pull:GetX(), points.pull:GetY(), points.pull:GetZ()));
			moveUnitTo(Players.GetLocal(), src, points.pull);
		end
	end
end
function OnDraw()
	local allowFancy = (isActive and fancyVisuals) or false;
	if (not debugDraw and not (presets_ui and builder_state.enabled) and not allowFancy) then
		return;
	end
	local title = (isActive and "Auto Stacker: ON") or "Auto Stacker: OFF";
	local fontIdx = (debugFontFamily or 0) + 1;
	local fontName = availableFonts[fontIdx] or "Tahoma";
	local fontSize = math.max(12, debugFontSize);
	local rfont = getRenderFont(fontName);
	local textSize = Render.TextSize(rfont, fontSize, title);
	local paddingX, paddingY = 12, 8;
	local width = textSize.x + (paddingX * 2) + fontSize;
	local height = math.max(textSize.y + (paddingY * 2), fontSize + (paddingY * 2));
	local x1, y1 = overlayX, overlayY;
	local x2, y2 = overlayX + width, overlayY + height;
	local mx, my = Input.GetCursorPos();
	local inside = (mx >= x1) and (mx <= x2) and (my >= y1) and (my <= y2);
	if (Input.IsKeyDown(Enum.ButtonCode.KEY_LCONTROL) and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) and inside) then
		isDragging = true;
		dragDx = mx - overlayX;
		dragDy = my - overlayY;
	end
	if (isDragging and Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1)) then
		overlayX = mx - dragDx;
		overlayY = my - dragDy;
		panel_info.x = overlayX;
		panel_info.y = overlayY;
	elseif (isDragging and not Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1)) then
		isDragging = false;
	end
	Render.FilledRect(Vec2(x1, y1), Vec2(x2, y2), Color(0, 0, 0, 200), 8);
	Render.Blur(Vec2(x1, y1), Vec2(x2, y2), 0/0, 1, 8);
	Render.FilledRect(Vec2(x1, y1), Vec2(x1 + 5, y2), Color(68, 68, 68, 220), 8);
	local dotR = math.floor(fontSize * 0.45);
	local statusColor = (isActive and Color(46, 204, 113, 255)) or Color(231, 76, 60, 255);
	Render.FilledCircle(Vec2(x1 + paddingX, y1 + (height / 2)), dotR, statusColor);
	local tx = x1 + paddingX + (dotR * 2) + 8;
	local ty = (y1 + ((height - fontSize) / 2)) - 1;
	Render.Text(rfont, fontSize, title, Vec2(tx, ty), Color(255, 255, 255, 240));
	local font = Renderer.LoadFont(fontName, fontSize, Enum.FontCreate.FONTFLAG_ANTIALIAS, 1);
	if (isActive and selectedUnits and (#selectedUnits > 0)) then
		if not fancyVisuals then
			for _, u in ipairs(selectedUnits) do
				local campId = unitToCampId[u];
				if campId then
					local points = getCampPoints(campId);
					if points then
						local sx, sy, onScreen = Renderer.WorldToScreen(points.wait);
						if onScreen then
							Renderer.SetDrawColor(0, 0, 255, 255);
							Renderer.DrawText(font, sx - 20, sy - 20, ">>");
						end
					end
				end
			end
			local seen = {};
			for _, u in ipairs(selectedUnits) do
				local campId = unitToCampId[u];
				if (campId and not seen[campId]) then
					seen[campId] = true;
					local anchor = campStrikeCenters[campId];
					if not anchor then
						local pts = getCampPoints(campId);
						anchor = (pts and pts.wait) or nil;
					end
					if anchor then
						local sx, sy, onScreen = Renderer.WorldToScreen(anchor);
						if onScreen then
							local stacks = campStacks[campId] or 0;
							local eff = campEffFirstHit[campId];
							local effText = (eff and string.format("%.1f", eff)) or "-";
							local label = string.format("stacks:%d  first:%ss", stacks, effText);
							Renderer.SetDrawColor(255, 255, 0, 255);
							Renderer.DrawText(font, sx - 40, sy - 36, label);
						end
					end
				end
			end
		else
			local function drawCircleScreen(cx, cy, radius, r, g, b, a, segments)
				segments = segments or 36;
				local prevx, prevy = nil, nil;
				for i = 0, segments do
					local ang = (i / segments) * math.pi * 2;
					local x = cx + (math.cos(ang) * radius);
					local y = cy + (math.sin(ang) * radius);
					if (prevx and prevy) then
						Renderer.SetDrawColor(r, g, b, a);
						Renderer.DrawLine(prevx, prevy, x, y);
					end
					prevx, prevy = x, y;
				end
			end
			local function drawRingScreen(cx, cy, radius, thickness, r, g, b, a)
				local steps = math.max(1, math.floor(thickness));
				for i = 0, steps - 1 do
					drawCircleScreen(cx, cy, radius - (i - (steps / 2)), r, g, b, a, 40);
				end
			end
			local function drawProgressArc(cx, cy, radius, thickness, progress, r, g, b, a)
				progress = math.max(0, math.min(1, progress or 0));
				local segments = 120;
				local maxIndex = math.max(1, math.floor(segments * progress));
				for ring = -math.floor(thickness / 2), math.floor((thickness - 1) / 2) do
					local rr = radius + ring;
					local prevx, prevy = nil, nil;
					for i = 0, maxIndex do
						local ang = (i / segments) * math.pi * 2;
						local x = cx + (math.cos(ang) * rr);
						local y = cy + (math.sin(ang) * rr);
						if (prevx and prevy) then
							Renderer.SetDrawColor(r, g, b, a);
							Renderer.DrawLine(prevx, prevy, x, y);
						end
						prevx, prevy = x, y;
					end
				end
			end
			local function drawArrow(sx1, sy1, sx2, sy2, r, g, b)
				Renderer.SetDrawColor(r, g, b, 255);
				Renderer.DrawLine(sx1, sy1, sx2, sy2);
				local dx, dy = sx2 - sx1, sy2 - sy1;
				local len = math.max(1, math.sqrt((dx * dx) + (dy * dy)));
				dx, dy = dx / len, dy / len;
				local size = 8;
				local ax1 = (sx2 - (dx * size)) + (-dy * size * 0.6);
				local ay1 = (sy2 - (dy * size)) + (dx * size * 0.6);
				local ax2 = (sx2 - (dx * size)) - (-dy * size * 0.6);
				local ay2 = (sy2 - (dy * size)) - (dx * size * 0.6);
				Renderer.DrawLine(sx2, sy2, ax1, ay1);
				Renderer.DrawLine(sx2, sy2, ax2, ay2);
			end
			local t = gameTimeSeconds();
			local minute = math.floor(t / 60);
			local sec = t % 60;
			for _, u in ipairs(selectedUnits) do
				local campId = unitToCampId[u];
				if campId then
					local points = getCampPoints(campId);
					local strike = campStrikeCenters[campId] or (points and points.wait);
					local st = ensureTimelineFor(u, minute);
					local baseHit = (isUnitRanged(u) and firstHitSecRanged) or firstHitSecMelee;
					local stacks = campStacks[campId] or 0;
					local perStackShift = perStackShiftCenti / 100;
					local effFirstHit = math.max(52, math.min(54, baseHit - (stacks * perStackShift)));
					local nextPos = nil;
					local cr, cg, cb = 52, 152, 219;
					if ((sec < effFirstHit) and not st.attackIssued) then
						nextPos = (points and points.wait) or nil;
						cr, cg, cb = 52, 152, 219;
					elseif not st.pullIssued then
						nextPos = strike;
						cr, cg, cb = 241, 196, 15;
					else
						nextPos = (points and points.pull) or nil;
						cr, cg, cb = 231, 76, 60;
					end
					local upos = (isEntityValid(u) and safeCall(Entity.GetAbsOrigin, u)) or nil;
					local ux, uy, us = nil, nil, nil;
					if upos then
						ux, uy, us = Renderer.WorldToScreen(upos);
					end
					if (nextPos and us) then
						local tx, ty, ts = Renderer.WorldToScreen(nextPos);
						if ts then
							drawArrow(ux, uy, tx, ty, cr, cg, cb);
						end
					end
					local pulse = (math.sin(t * 4) * 0.5) + 0.5;
					local baseR = 10 + (pulse * 4);
					if points then
						local wx, wy, wv = Renderer.WorldToScreen(points.wait);
						if wv then
							drawRingScreen(wx, wy, baseR, 3, 52, 152, 219, 220);
						end
						local px, py, pv = Renderer.WorldToScreen(points.pull);
						if pv then
							drawRingScreen(px, py, baseR, 3, 231, 76, 60, 220);
						end
					end
					if strike then
						local sx, sy, sv = Renderer.WorldToScreen(strike);
						if sv then
							drawRingScreen(sx, sy, baseR + 2, 3, 241, 196, 15, 220);
						end
					end
				end
			end
			local seen = {};
			for _, u in ipairs(selectedUnits) do
				local campId = unitToCampId[u];
				if (campId and not seen[campId]) then
					seen[campId] = true;
					local center = campStrikeCenters[campId];
					local pts = getCampPoints(campId);
					center = center or (pts and pts.wait);
					if center then
						local sx, sy, ok = Renderer.WorldToScreen(center);
						if ok then
							local progress = (t % 60) / 60;
							drawProgressArc(sx, sy, 22, 4, progress, 0, 200, 255, 220);
							local stacks = campStacks[campId] or 0;
							local eff = campEffFirstHit[campId];
							local effText = (eff and string.format("%.1f", eff)) or "-";
							Renderer.SetDrawColor(255, 255, 255, 230);
							Renderer.DrawText(font, sx - 44, sy - 36, string.format("%s  %ss", tostring(stacks), effText));
						end
					end
				end
			end
		end
	end
	if (presets_ui and builder_state.enabled) then
		local fontIdx = (debugFontFamily or 0) + 1;
		local fontName = availableFonts[fontIdx] or "Tahoma";
		local fontSize = math.max(12, debugFontSize);
		local builderFont = Renderer.LoadFont(fontName, fontSize, Enum.FontCreate.FONTFLAG_ANTIALIAS, 1);
		local function drawHandle(pos, color)
			local sx, sy, onScreen = Renderer.WorldToScreen(pos);
			if onScreen then
				Renderer.SetDrawColor(color[1], color[2], color[3], 255);
				Render.FilledRect(Vec2(sx - 6, sy - 6), Vec2(sx + 6, sy + 6), Color(color[1], color[2], color[3], 220), 3);
			end
			return sx, sy, onScreen;
		end
		local campsToDraw = {};
		if builder_state.show_all then
			for campId, _ in pairs(CAMP_POINTS) do
				table.insert(campsToDraw, campId);
			end
		else
			for _, u in ipairs(selectedUnits or {}) do
				local campId = unitToCampId[u];
				if campId then
					table.insert(campsToDraw, campId);
				end
			end
		end
		local mx, my = Input.GetCursorPos();
		local isDown = Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1);
		local startedDrag = false;
		local ignoreTrees = false;
		local localHero = Heroes.GetLocal();
		local npc_map = GridNav.CreateNpcMap({localHero}, not ignoreTrees);
		if builder_state.dragging then
			if isDown then
				local wp = Input.GetWorldCursorPos();
				local gz = World.GetGroundZ(wp.x, wp.y);
				local v = Vector(wp.x, wp.y, gz);
				local pts = ACTIVE_POINTS[builder_state.dragCamp];
				if pts then
					pts[builder_state.dragType] = v;
					local tgtPreset = active_preset_name or "Default";
					stack_presets[tgtPreset] = stack_presets[tgtPreset] or {points={}};
					stack_presets[tgtPreset].points[builder_state.dragCamp] = stack_presets[tgtPreset].points[builder_state.dragCamp] or {};
					stack_presets[tgtPreset].points[builder_state.dragCamp][builder_state.dragType] = v;
					SaveStackPresets();
					if (isActive and (builder_state.dragType == "wait")) then
						local campId = builder_state.dragCamp;
						local tnow = gameTimeSeconds();
						local minute = math.floor(tnow / 60);
						local sec = tnow % 60;
						local stacks = campStacks[campId] or 0;
						local perStackShift = perStackShiftCenti / 100;
						local player = Players.GetLocal();
						for _, u in ipairs(selectedUnits or {}) do
							if ((unitToCampId[u] == campId) and isEntityAlive(u)) then
								local st = ensureTimelineFor(u, minute);
								local baseHit = (isUnitRanged(u) and firstHitSecRanged) or firstHitSecMelee;
								local effFirstHit = math.max(52, math.min(54, baseHit - (stacks * perStackShift)));
								if ((sec < effFirstHit) and not st.attackIssued) then
									moveUnitTo(player, u, v);
									st.movedToWait = true;
								end
							end
						end
					end
				end
			else
				builder_state.dragging = false;
			end
		end
		for _, campId in ipairs(campsToDraw) do
			local pts = getCampPoints(campId);
			if pts then
				local wx, wy, on1 = drawHandle(pts.wait, {52,152,219});
				if (on1 and not builder_state.dragging and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1)) then
					if ((mx >= (wx - 8)) and (mx <= (wx + 8)) and (my >= (wy - 8)) and (my <= (wy + 8))) then
						builder_state.dragging = true;
						builder_state.dragCamp = campId;
						builder_state.dragType = "wait";
						startedDrag = true;
					end
				end
				local px, py, on2 = drawHandle(pts.pull, {231,76,60});
				if (on2 and not builder_state.dragging and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) and not startedDrag) then
					if ((mx >= (px - 8)) and (mx <= (px + 8)) and (my >= (py - 8)) and (my <= (py + 8))) then
						builder_state.dragging = true;
						builder_state.dragCamp = campId;
						builder_state.dragType = "pull";
					end
				end
				local path = GridNav.BuildPath(pts.wait, pts.pull, ignoreTrees, npc_map) or {};
				local prev_x, prev_y, prev_visible = nil, nil, nil;
				for _, pos in ipairs(path) do
					local x, y, visible = Renderer.WorldToScreen(pos);
					if (prev_x and prev_y and visible and prev_visible) then
						Renderer.SetDrawColor(255, 255, 255, 220);
						Renderer.DrawLine(prev_x, prev_y, x, y);
					end
					prev_x, prev_y, prev_visible = x, y, visible;
				end
				local sxw, syw, ok1 = Renderer.WorldToScreen(pts.wait);
				local sxp, syp, ok2 = Renderer.WorldToScreen(pts.pull);
				if ok1 then
					Renderer.SetDrawColor(255, 255, 255, 220);
					Renderer.DrawText(builderFont, sxw + 8, syw - 8, tostring(campId) .. " W");
				end
				if ok2 then
					Renderer.SetDrawColor(255, 255, 255, 220);
					Renderer.DrawText(builderFont, sxp + 8, syp - 8, tostring(campId) .. " P");
				end
			end
		end
		if npc_map then
			GridNav.ReleaseNpcMap(npc_map);
		end
	end
end
return {OnUpdate=OnUpdate,OnDraw=OnDraw,OnEntityHurt=OnEntityHurt};