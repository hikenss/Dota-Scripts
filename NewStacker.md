local tab = Menu.Create("Creeps", "Main", "Distributed Stacker");
tab:Icon("\u{f0e8}");
local ui = tab:Create("Options"):Create("Main");
local toggleKey = ui:Bind("Activate Distributed Auto Stacker", Enum.ButtonCode.KEY_0, "panorama/images/spellicons/rattletrap_power_cogs_png.vtex_c");
local debugDraw = ui:Switch("Visual Debug", false, "");
local debugFontSize = ui:Slider("Debug Font Size", 12, 36, 16);
local firstHitSecMelee = ui:Slider("First Hit Melee (sec)", 51, 55, 53);
local firstHitSecRanged = ui:Slider("First Hit Ranged (sec)", 51, 55, 53);
local perStackShiftCenti = ui:Slider("Stack Shift (0.3–0.6 sec)", 30, 60, 40, function(v)
	return string.format("%.1f", v / 100);
end);
local fancyVisuals = ui:Switch("Visual Performance", true, "");
local availableFonts = {"Tahoma","Arial","Verdana","Segoe UI","Consolas","Courier New","Calibri"};
local debugFontFamily = ui:Combo("Debug Font", availableFonts, 0);
local autoNonHeroBind = ui:Bind("Auto Stack Non-Hero Units", Enum.ButtonCode.KEY_9, "");
local autoNonHeroActive = false;
local wasAutoNonHeroHeld = false;
local overlayFontCache = {};
local minimapPanel = nil;
local minimapImage = nil;
local minimapImageLoaded = false;
local lastCampStacks = {};
local function loadMinimapImage()
	if not minimapImageLoaded then
		-- Load from remote URL (most reliable)
		minimapImage = Render.LoadImage("https://s3.iimg.su/s/08/gyXXwkpxTyE5mHJhWyOPVJErQJzRzCG9XYZHtlzF.jpg");
		
		minimapImageLoaded = true;
		if minimapImage then
			print("[AutoStacker] Minimap image loaded successfully");
		else
			print("[AutoStacker] Failed to load minimap image - will use fallback rendering");
		end
	end
	return minimapImage;
end
local function getRenderFont(fontName)
	local key = fontName or "Tahoma";
	if not overlayFontCache[key] then
		overlayFontCache[key] = Render.LoadFont(key, Enum.FontCreate.FONTFLAG_ANTIALIAS);
	end
	return overlayFontCache[key];
end
local isActive = false;
local wasToggleHeld = false;
local state = state or {};
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
-- Helper function to determine camp side (Radiant vs Dire)
local function getCampSide(campId)
	-- Radiant camps: mostly in bottom-left (negative x, positive y)
	-- Dire camps: mostly in top-right (positive x, negative y)
	-- Mid camps: can be either based on exact location
	
	local radiantIds = {1,5,9,13,17,21,23,26};
	local direIds = {2,4,6,10,15,20,24,27};
	
	for _, id in ipairs(radiantIds) do
		if campId == id then return "radiant" end
	end
	for _, id in ipairs(direIds) do
		if campId == id then return "dire" end
	end
	return "neutral"; -- Mid camps
end

local CAMP_POINTS = {[1]={wait=Vector(-742, 4325, 134),pull=Vector(-682, 3881, 236),side="radiant"},[2]={wait=Vector(2943, -796, 256),pull=Vector(2817, -53, 256),side="dire"},[3]={wait=Vector(4082, -5526, 128),pull=Vector(4181, -6368, 128),side="dire"},[4]={wait=Vector(8255, -734, 256),pull=Vector(8204, -1369, 256),side="dire"},[5]={wait=Vector(-4806, 4534, 128),pull=Vector(-4884, 5071, 128),side="radiant"},[6]={wait=Vector(4284, -4110, 128),pull=Vector(3622, -4505, 128),side="dire"},[7]={wait=Vector(-2121, -3921, 128),pull=Vector(-1564, -4531, 128),side="radiant"},[8]={wait=Vector(262, -4751, 136),pull=Vector(333, -4101, 254),side="neutral"},[9]={wait=Vector(-4509, 361, 256),pull=Vector(-5031, 1121, 128),side="radiant"},[10]={wait=Vector(4072, -421, 256),pull=Vector(4276, -1359, 128),side="dire"},[11]={wait=Vector(-1274, -4908, 128),pull=Vector(-812, -5282, 128),side="radiant"},[12]={wait=Vector(1515, 8209, 128),pull=Vector(792, 8152, 128),side="radiant"},[13]={wait=Vector(455, 3965, 134),pull=Vector(-78, 3932, 136),side="radiant"},[14]={wait=Vector(-4144, 322, 256),pull=Vector(-5031, 1121, 128),side="radiant"},[15]={wait=Vector(316, -8138, 134),pull=Vector(954, -8538, 136),side="dire"},[16]={wait=Vector(-2529, -7737, 134),pull=Vector(-2690, -7154, 134),side="radiant"},[17]={wait=Vector(-479, 7639, 134),pull=Vector(-551, 6961, 128),side="radiant"},[18]={wait=Vector(-4743, 7534, 0),pull=Vector(-4832, 7136, 0),side="radiant"},[19]={wait=Vector(1348, 3263, 128),pull=Vector(1683, 3710, 128),side="neutral"},[20]={wait=Vector(7969, 1047, 256),pull=Vector(7681, 695, 256),side="dire"},[21]={wait=Vector(-7735, -183, 256),pull=Vector(-7436, 685, 256),side="radiant"},[22]={wait=Vector(-3962, 7564, 0),pull=Vector(-4521, 7474, 8),side="radiant"},[23]={wait=Vector(-2589, 4502, 256),pull=Vector(-2651, 5138, 256),side="radiant"},[24]={wait=Vector(3522, -8186, 8),pull=Vector(4028, -7376, 0),side="dire"},[25]={wait=Vector(1501, -4208, 256),pull=Vector(1094, -5103, 136),side="neutral"},[26]={wait=Vector(-4338, 4903, 128),pull=Vector(-5198, 4877, 128),side="radiant"},[27]={wait=Vector(-7757, -1219, 256),pull=Vector(-7693, -727, 256),side="radiant"},[28]={wait=Vector(4781, -7812, 8),pull=Vector(4510, -7260, 82),side="dire"}};
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
		out[campId] = {
			wait=Vector(pts.wait:GetX(), pts.wait:GetY(), pts.wait:GetZ()),
			pull=Vector(pts.pull:GetX(), pts.pull:GetY(), pts.pull:GetZ()),
			side=pts.side
		};
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
		local entry = {campId=campId,wait=vecToTable(pts.wait),pull=vecToTable(pts.pull),side=pts.side};
		table.insert(arr, entry);
	end
	return arr;
end
local function DisabledMapToArray(map)
	local arr = {};
	for campId, disabled in pairs(map or {}) do
		if disabled then
			table.insert(arr, campId);
		end
	end
	table.sort(arr, function(a, b) return (a or 0) < (b or 0) end);
	return arr;
end
local function ArrayToMap(arr)
	local map = {};
	for _, e in ipairs(arr or {}) do
		if (e and e.campId) then
			map[e.campId] = {wait=tableToVector(e.wait),pull=tableToVector(e.pull),side=e.side};
		end
	end
	return map;
end
local function DisabledArrayToMap(arr)
	local map = {};
	for _, campId in ipairs(arr or {}) do
		if campId then
			map[campId] = true;
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
				ACTIVE_POINTS[campId] = {wait=((pts.wait and Vector(pts.wait:GetX(), pts.wait:GetY(), pts.wait:GetZ())) or Vector(0, 0, 0)),pull=((pts.pull and Vector(pts.pull:GetX(), pts.pull:GetY(), pts.pull:GetZ())) or Vector(0, 0, 0)),side=pts.side};
			end
		end
	end
	-- Don't restore disabled state from preset - it's only kept in memory via minimapPanel.camp_enabled
	minimapPanel = minimapPanel or {};
	minimapPanel.camp_enabled = minimapPanel.camp_enabled or {};
end
local function SaveStackPresets()
	local JSON = require("assets.JSON");
	local file = io.open(GetStackPresetsPath(), "w");
	if file then
		local serializable = {};
		for name, preset in pairs(stack_presets) do
			-- Only save points, not disabled state
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
						-- Only load points, not disabled state (which is kept in memory only)
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
local function snapshotDisabledCamps()
	local disabled = {};
	for campId, _ in pairs(CAMP_POINTS or {}) do
		if minimapPanel and minimapPanel.camp_enabled and minimapPanel.camp_enabled[campId] == false then
			disabled[campId] = true;
		end
		if builder_state and builder_state.deleted and builder_state.deleted[campId] then
			disabled[campId] = true;
		end
	end
	return disabled;
end
local function isCampEnabledId(campId)
	-- Simple check: if camp is not marked as disabled, it's enabled
	return not (minimapPanel and minimapPanel.camp_enabled and minimapPanel.camp_enabled[campId] == false);
end
local function setCampEnabledId(campId, shouldEnable)
	minimapPanel = minimapPanel or {};
	minimapPanel.camp_enabled = minimapPanel.camp_enabled or {};
	if shouldEnable then
		minimapPanel.camp_enabled[campId] = nil;  -- nil = enabled
	else
		minimapPanel.camp_enabled[campId] = false;  -- false = disabled
	end
end
local function areAllCampsEnabledForSide(side)
	-- Check if all camps for a side are enabled
	local foundAnyCamp = false;
	for campId, camp in pairs(CAMP_POINTS or {}) do
		if camp and camp.side == side then
			foundAnyCamp = true;
			if not isCampEnabledId(campId) then
				return false;  -- At least one is disabled
			end
		end
	end
	return foundAnyCamp;  -- true only if found at least one and all were enabled
end
local function setCampsEnabledForSide(side, shouldEnable)
	minimapPanel = minimapPanel or {};
	minimapPanel.camp_enabled = minimapPanel.camp_enabled or {};
	for campId, camp in pairs(CAMP_POINTS or {}) do
		if camp and camp.side == side then
			if shouldEnable then
				minimapPanel.camp_enabled[campId] = nil;  -- nil = enabled
			else
				minimapPanel.camp_enabled[campId] = false;  -- false = disabled
			end
		end
	end
end
local function isCampEnabled(campId)
	if not campId then
		return false;
	end
	if builder_state and builder_state.deleted and builder_state.deleted[campId] then
		return false;
	end
	-- Use the same check as button state
	return isCampEnabledId(campId);
end
local function getCampPoints(campId)
	if not isCampEnabled(campId) then
		return nil;
	end
	return ACTIVE_POINTS[campId] or CAMP_POINTS[campId];
end
local campStrikeCenters = {};
local campBoxes = {};
local campStacks = {};
local campStacksMinute = {};
local campEffFirstHit = {};
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
		print(string.format("[AutoStacker] Camp #%d strike center calculated: (%.0f, %.0f, %.0f)", campId, center:GetX(), center:GetY(), center:GetZ()));
	else
		print("[AutoStacker] Cannot calculate strike center for camp #" .. tostring(campId));
	end
end
local function assignUnitsToNearestCamps(units)
	local assignment = {};
	local usedCamps = {};
	
	-- Track ALL already used camps from unitToCampId
	for existingUnit, campId in pairs(unitToCampId or {}) do
		if campId and isEntityValid(existingUnit) then
			-- Mark camp as used unless this unit is being reassigned
			local isBeingReassigned = false;
			for _, u in ipairs(units) do
				if existingUnit == u then
					isBeingReassigned = true;
					break;
				end
			end
			
			if not isBeingReassigned then
				if isCampEnabled(campId) then
					usedCamps[campId] = true;
				else
					-- Clear disabled camps
					unitToCampId[existingUnit] = nil;
				end
			end
		end
	end
	
	-- Assign each unit to nearest available camp
	for _, u in ipairs(units) do
		local unitPos = (isEntityValid(u) and safeCall(Entity.GetAbsOrigin, u)) or nil;
		if unitPos then
			local bestCamp, bestDist = nil, math.huge;
			
			-- Find nearest available camp
			for campId, _ in pairs(ACTIVE_POINTS) do
				if (not usedCamps[campId]) and isCampEnabled(campId) then
					local pts = getCampPoints(campId);
					if pts and pts.wait then
						local d = (pts.wait - unitPos):Length2D();
						if (d < bestDist) then
							bestDist = d;
							bestCamp = campId;
						end
					end
				end
			end
			
			if bestCamp then
				assignment[u] = bestCamp;
				usedCamps[bestCamp] = true;
			else
				local enabledCount = 0;
				for cid, _ in pairs(ACTIVE_POINTS) do
					if isCampEnabled(cid) then enabledCount = enabledCount + 1; end
				end
				local usedCount = 0;
				for _ in pairs(usedCamps) do usedCount = usedCount + 1; end
				print(string.format("[AutoStacker] WARN: No available camp for unit (enabled: %d, used: %d)", 
					enabledCount, usedCount));
			end
		end
	end
	
	return assignment;
end
local function beginSession()
	local player = Players.GetLocal();
	local sel = Player.GetSelectedUnits(player) or {};
	if (#sel == 0) then
		print("[AutoStacker] No units selected.");
		return false;
	end
	
	-- Initialize lists if not exists
	if not selectedUnits then selectedUnits = {} end
	if not selectedUnitsSet then selectedUnitsSet = {} end
	if not unitToCampId then unitToCampId = {} end
	
	-- Add new units individually (don't clear existing ones)
	local newUnits = {};
	for _, u in ipairs(sel) do
		if isEntityValid(u) and not selectedUnitsSet[u] then
			selectedUnitsSet[u] = true;
			table.insert(selectedUnits, u);
			table.insert(newUnits, u);
		end
	end
	
	if (#newUnits == 0) then
		print("[AutoStacker] No new units to add (already assigned or invalid).");
		return false;
	end
	
	-- Count enabled camps
	local enabledCamps = 0;
	for cid, _ in pairs(ACTIVE_POINTS) do
		if isCampEnabled(cid) then enabledCamps = enabledCamps + 1; end
	end
	
	print(string.format("[AutoStacker] Adding %d units (total: %d, enabled camps: %d)", #newUnits, #selectedUnits, enabledCamps));
	
	-- Assign only new units to camps
	local newAssignments = assignUnitsToNearestCamps(newUnits);
	for unit, campId in pairs(newAssignments) do
		unitToCampId[unit] = campId;
		ensureStrikeCenterForCamp(campId);
		print(string.format("[AutoStacker] Unit assigned to camp #%d", campId));
	end
	
	-- MOVER TODAS AS UNIDADES IMEDIATAMENTE (em batch para reduzir lag)
	for unit, campId in pairs(newAssignments) do
		local points = getCampPoints(campId);
		if points and points.wait then
			moveUnitTo(player, unit, points.wait);
		end
	end
	
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
local function autoAssignNonHeroUnits()
	if not autoNonHeroActive then
		return;
	end
	
	local player = Players.GetLocal();
	if not player then return end;
	local playerId = Player.GetPlayerID(player);
	
	-- Initialize tables
	if not selectedUnits then selectedUnits = {} end
	if not selectedUnitsSet then selectedUnitsSet = {} end
	if not unitToCampId then unitToCampId = {} end
	if not timeline then timeline = {} end
	
	-- Find ALL controllable units (not just illusions, like stacker2.lua)
	local unitsToAdd = {};
	for _, npc in pairs(NPCs.GetAll()) do
		if Entity.IsNPC(npc) and Entity.IsAlive(npc) 
			and NPC.IsControllableByPlayer(npc, playerId)
			and not NPC.IsHero(npc)
			and not NPC.IsCourier(npc) then
			
			-- Check if not already assigned
			if not unitToCampId[npc] and not selectedUnitsSet[npc] then
				table.insert(unitsToAdd, npc);
			end
		end
	end
	
	-- Assign units to camps
	if #unitsToAdd > 0 then
		local player = Players.GetLocal();
		local newAssignments = assignUnitsToNearestCamps(unitsToAdd);
		for unit, campId in pairs(newAssignments) do
			if not selectedUnitsSet[unit] then
				selectedUnitsSet[unit] = true;
				table.insert(selectedUnits, unit);
				unitToCampId[unit] = campId;
				ensureStrikeCenterForCamp(campId);
				
				-- MOVER UNIDADE IMEDIATAMENTE para o ponto de espera
				local points = getCampPoints(campId);
				if points and points.wait then
					moveUnitTo(player, unit, points.wait);
				end
				
				print(string.format("[AutoStacker AUTO] Illusion assigned to Camp #%d", campId));
			end
		end
	end
end

function OnUpdate()
	-- Handle auto non-hero bind toggle
	local autoPressed = autoNonHeroBind:IsPressed();
	if (autoPressed and not wasAutoNonHeroHeld) then
		autoNonHeroActive = not autoNonHeroActive;
		print("[AutoStacker] Auto non-hero mode:", autoNonHeroActive and "ON" or "OFF");
		if autoNonHeroActive then
			-- Initialize auto mode only if needed
			if not isActive then
				isActive = true;
				print("[AutoStacker] Auto mode activated");
			end
			-- Don't clear existing units/assignments - just start detecting new ones
		else
			-- Clear assignments when disabling
			for unit, _ in pairs(selectedUnitsSet) do
				if unitToCampId[unit] then
					unitToCampId[unit] = nil;
				end
			end
			selectedUnits = {};
			selectedUnitsSet = {};
			unitToCampId = {};
			timeline = {};
			print("[AutoStacker] Auto mode deactivated");
		end
	end
	wasAutoNonHeroHeld = autoPressed;
	
	-- Run auto assignment if active (throttled para reduzir lag)
	if autoNonHeroActive then
		local currentTime = GameRules.GetGameTime();
		state.__lastAutoCheck = state.__lastAutoCheck or 0;
		-- Checar apenas a cada 0.5 segundos ao invés de todo frame
		if (currentTime - state.__lastAutoCheck) >= 0.5 then
			state.__lastAutoCheck = currentTime;
			autoAssignNonHeroUnits();
		end
	end
	
	if not stack_presets_loaded then
		LoadStackPresets();
		if not presets_ui then
			local builderTab = tab:Create("Builder"):Create("Settings");
			presets_ui = {};
			presets_ui.builder_switch = builderTab:Switch("Builder Mode", false, "\u{f044}");
			presets_ui.show_all = builderTab:Switch("Show All Camps", true, "\u{f06e}");
			presets_ui.preset_select = builderTab:Combo("Preset", GetPresetNames(), 0);
			presets_ui.active_btn = builderTab:Button("Set Active", function()
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
				stack_presets[name] = {points={},disabled={}};
				selected_preset_name = name;
				SaveStackPresets();
				local names = GetPresetNames();
				presets_ui.preset_select:Update(names, math.max(0, #names - 1));
				print("[Stacker Presets] Created empty preset '" .. name .. "'");
			end);
			presets_ui.use_current = builderTab:Button("Save Current Preset", function()
				local names = GetPresetNames();
				local idx = (presets_ui.preset_select:Get() or 0) + 1;
				local name = names[idx];
				if not name then
					print("[Stacker Presets] No preset selected");
					return;
				end
				active_preset_name = name;
				-- Only save waypoint positions, NOT enable/disable state
				stack_presets[name] = {points=DeepCopyCampPoints(ACTIVE_POINTS)};
				SaveStackPresets();
				print("[Stacker Presets] Saved current preset '" .. name .. "'");
			end);
			presets_ui.delete_wp = builderTab:Button("Delete Waypoint (hover)", function()
				local cid = minimapPanel._hover_camp_id;
				if not cid then
					print("[Builder] Hover a camp on the minimap to delete.");
					return;
				end
				builder_state.deleted = builder_state.deleted or {};
				builder_state.deleted[cid] = true;
				ACTIVE_POINTS[cid] = nil;
				minimapPanel.camp_enabled[cid] = false;
				print(string.format("[Builder] Deleted waypoint for camp #%d (use 'Save Current Preset' to save)", cid));
			end);
			presets_ui.restore_wp = builderTab:Button("Add/Restore Waypoint (hover)", function()
				local cid = minimapPanel._hover_camp_id;
				if not cid then
					print("[Builder] Hover a camp on the minimap to restore.");
					return;
				end
				builder_state.deleted = builder_state.deleted or {};
				builder_state.deleted[cid] = nil;
				ACTIVE_POINTS[cid] = DeepCopyCampPoints({[cid]=CAMP_POINTS[cid]})[cid] or CAMP_POINTS[cid];
				minimapPanel.camp_enabled[cid] = nil;
				print(string.format("[Builder] Restored waypoint for camp #%d (use 'Save Current Preset' to save)", cid));
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
	local player = Players.GetLocal();
	local pressed = toggleKey:IsPressed();
	if (pressed and not wasToggleHeld) then
		isActive = not isActive;
		if isActive then
			-- Ativar modo manual
			beginSession();
			print("[AutoStacker] Manual mode: ON");
		else
			-- Desativar modo manual
			selectedUnits = {};
			selectedUnitsSet = {};
			unitToCampId = {};
			timeline = {};
			lastCampStacks = {};
			print("[AutoStacker] Manual mode: OFF");
		end
	end
	wasToggleHeld = pressed;
	
	-- Don't return if auto mode is active, even if manual mode isn't
	if not isActive and not autoNonHeroActive then
		return;
	end
	
	local alive = {};
	for _, u in ipairs(selectedUnits) do
		if isEntityAlive(u) then
			table.insert(alive, u);
		else
			-- Clean up dead unit
			if unitToCampId[u] then
				unitToCampId[u] = nil;
			end
			if selectedUnitsSet[u] then
				selectedUnitsSet[u] = nil;
			end
		end
	end
	
	if (#alive == 0) then
		if not autoNonHeroActive then
			print("[AutoStacker] All units died, deactivating bot.");
			isActive = false;
			lastCampStacks = {};
			return;
		else
			-- In auto mode, just clear and wait for new units
			selectedUnits = {};
			return;
		end
	end
	
	-- Update selectedUnits list to only alive units
	selectedUnits = alive;
	local t = gameTimeSeconds();
	local minute = math.floor(t / 60);
	local sec = t % 60;
	for _, u in ipairs(selectedUnits) do
		local campId = unitToCampId[u];
		if (not campId) or (not isCampEnabled(campId)) then
			unitToCampId[u] = nil;
			selectedUnitsSet[u] = nil;
			-- Silently skip unassigned units
			goto continue_unit;
		else
			local points = getCampPoints(campId);
			if not points then
				unitToCampId[u] = nil;
				selectedUnitsSet[u] = nil;
				goto continue_unit;
			end
			local strike = campStrikeCenters[campId];
			if not strike then
				ensureStrikeCenterForCamp(campId);
				strike = campStrikeCenters[campId];
				if not strike then
					goto continue_unit;
				end
			end
			local st = ensureTimelineFor(u, minute);
			local baseHit = (isUnitRanged(u) and firstHitSecRanged:Get()) or firstHitSecMelee:Get();
			
			-- Detectar stacks apenas uma vez por minuto
			if (sec >= 50) then
				if ((campStacksMinute[campId] or -1) ~= minute) then
					local stacksNow = evaluateCampStacks(campId);
					local prevStacks = lastCampStacks[campId] or 0;
					campStacks[campId] = stacksNow;
					campStacksMinute[campId] = minute;
					if (stacksNow > prevStacks and stacksNow > 0) then
						Notification({
							duration = 3,
							timer = 3,
							primary_text = "Stack successful!",
							primary_image = "panorama/images/spellicons/rattletrap_power_cogs_png.vtex_c",
							secondary_text = string.format("Camp #%d: %d stack(s)", campId, stacksNow),
							position = getCampPoints(campId) and getCampPoints(campId).wait or nil
						});
						print(string.format("[Stacker] ✓ Successful stack! Camp #%d: %d", campId, stacksNow));
					else
						print(string.format("[Stacker] Camp #%d stacks detected: %d", campId, stacksNow));
					end
					lastCampStacks[campId] = stacksNow;
				end
			end
			local stacks = campStacks[campId] or 0;
			local perStackShift = perStackShiftCenti:Get() / 100;
			local effFirstHit = math.max(52, math.min(54, baseHit - (stacks * perStackShift)));
			campEffFirstHit[campId] = effFirstHit;
			
			-- GARANTIR que a unidade está no ponto de espera no início de cada minuto
			if (sec < 5) and not st.movedToWait then
				st.movedToWait = true;
				moveUnitTo(player, u, points.wait);
			end
			
			-- MOVER UNIDADE PARA O PONTO DE ESPERA (reforçar antes do timing)
			if (sec < effFirstHit) then
				if not st.movedToWait then
					st.movedToWait = true;
					moveUnitTo(player, u, points.wait);
				end
			else
				-- FASE DE ATAQUE: dar o primeiro hit nos creeps
				if ((sec >= effFirstHit) and (sec < (effFirstHit + 2)) and not st.attackIssued) then
					st.attackIssued = true;
					print(string.format("[Stacker] Unit %s at %d:%.2f -> ATTACK (%.0f, %.0f, %.0f) [first=%.1f, stacks=%d, eff=%.1f]", tostring(u), minute, sec, strike:GetX(), strike:GetY(), strike:GetZ(), baseHit, stacks, effFirstHit));
					attackMoveUnitTo(player, u, strike);
				end
				
				-- FASE DE PULL: alinhado com Auto Stacker By GLTM
				if not st.pullIssued then
					if st.hitConfirmed then
						st.pullIssued = true;
						print(string.format("[Stacker] Unit %s -> PULL [on hit confirmed]", tostring(u)));
						moveUnitTo(player, u, points.pull);
					elseif (sec >= 57 and sec < 58) then
						st.pullIssued = true;
						print(string.format("[Stacker] Unit %s -> PULL [fallback at 57s]", tostring(u)));
						moveUnitTo(player, u, points.pull);
					end
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
		if (not campId) or (not isCampEnabled(campId)) then
			return;
		end
		local points = getCampPoints(campId);
		if not points then
			return;
		end
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
local mapBounds = {minX = -8288, minY = -8288, maxX = 8288, maxY = 8288};
local function worldToMinimap(worldPos, minimapX, minimapY, minimapW, minimapH)
	local normX = (worldPos.x - mapBounds.minX) / (mapBounds.maxX - mapBounds.minX);
	local normY = (worldPos.y - mapBounds.minY) / (mapBounds.maxY - mapBounds.minY);
	normY = 1.0 - normY;
	return minimapX + (normX * minimapW), minimapY + (normY * minimapH);
end

-- ============================================================================
-- COMPLETE MINIMAP PANEL SYSTEM (from auto_stack.min.lua reference)
-- ============================================================================

-- Panel state initialization
minimapPanel = minimapPanel or {};
minimapPanel.x = minimapPanel.x or 20;
minimapPanel.y = minimapPanel.y or 24;
minimapPanel.width = minimapPanel.width or 328;
minimapPanel.height = minimapPanel.height or 400;
minimapPanel.header_h = minimapPanel.header_h or 22;
minimapPanel.header_radius = minimapPanel.header_radius or 5;
minimapPanel.header_padding = minimapPanel.header_padding or 5;
minimapPanel.margin = minimapPanel.margin or 4;
minimapPanel.padding = minimapPanel.padding or 11;
minimapPanel.expanded = minimapPanel.expanded ~= false;
minimapPanel.hidden = minimapPanel.hidden or false;      -- Dock hidden state
minimapPanel.docked_side = minimapPanel.docked_side;   -- "left", "right", or nil
minimapPanel.dragging = false;
minimapPanel.drag_dx = 0.0;
minimapPanel.drag_dy = 0.0;
minimapPanel._anim_t = minimapPanel._anim_t or 1.0;
minimapPanel._anim_prev_time = minimapPanel._anim_prev_time or 0;
minimapPanel._dock_s_h = minimapPanel._dock_s_h or 0.0;     -- Dock slide horizontal
minimapPanel._dock_s_b = minimapPanel._dock_s_b or 0.0;     -- Dock slide base
minimapPanel._dock_prev_time = minimapPanel._dock_prev_time or 0;
minimapPanel._btn_prev_time = minimapPanel._btn_prev_time or 0;
minimapPanel._minimap_anim_prev_time = minimapPanel._minimap_anim_prev_time or 0;
minimapPanel._minimap_ring_scale = minimapPanel._minimap_ring_scale or {};
minimapPanel._minimap_enabled_t = minimapPanel._minimap_enabled_t or {};
minimapPanel._btn_hover_t = minimapPanel._btn_hover_t or { radiant = 0.0, dire = 0.0 };
minimapPanel._btn_state_t = minimapPanel._btn_state_t or { radiant = 0.0, dire = 0.0 };
minimapPanel.camp_enabled = minimapPanel.camp_enabled or {};
minimapPanel._dragging_waypoint = nil;  -- Dragging waypoint state for builder mode
minimapPanel._dragging_waypoint_type = nil;  -- "wait" or "pull"
minimapPanel._initialized = minimapPanel._initialized or false;

-- Load screen position from config if available
local function loadPanelPosition()
	-- Already initialized in state
end

-- Save panel position to config
local function savePanelPosition()
	-- Can be extended to save to config if needed
end

-- Delta time calculator with smoothing
local function deltaTime(stateTable, keyName)
	if not stateTable then stateTable = {} end
	local now = GameRules.GetGameTime and GameRules.GetGameTime() or 0.0;
	local prev = stateTable[keyName] or now;
	stateTable[keyName] = now;
	return now - prev;
end

-- Exponential smoothing helper
local function smoothValue(stateTable, keyName, targetValue, deltaT, tau)
	if not stateTable then stateTable = {} end
	if tau <= 1e-6 then
		stateTable[keyName] = targetValue;
		return targetValue;
	end
	local current = stateTable[keyName] or targetValue;
	local l = 1.0 - math.exp(-(deltaT / tau));
	if l > 1.0 then l = 1.0 end
	local result = current + (targetValue - current) * l;
	stateTable[keyName] = result;
	return result;
end

-- Load minimap background
local minimapBgImage = nil;
local function loadMinimapBackground()
	-- Return cached image if successfully loaded once
	if minimapBgImage then return minimapBgImage end

	-- Use the correct image URL
	local img = Render.LoadImage('https://i.imgur.com/3QVvpmK.png');
	if img then
		minimapBgImage = img;
		return minimapBgImage;
	end

	-- If loading fails, don't cache failure; fallback will render a colored rect
	return nil;
end

-- Lerp color
local function lerpColor(c1, c2, t)
	t = math.max(0, math.min(1, t));
	return Color(
		math.floor(c1.r + (c2.r - c1.r) * t + 0.5),
		math.floor(c1.g + (c2.g - c1.g) * t + 0.5),
		math.floor(c1.b + (c2.b - c1.b) * t + 0.5),
		math.floor(c1.a + (c2.a - c1.a) * t + 0.5)
	);
end

-- Draw shadow circle
local function drawShadow(pos, radius, maxAlpha, fadeWidth)
	if not pos or not radius then return end
	maxAlpha = maxAlpha or 160;
	fadeWidth = fadeWidth or 5;
	local fz = math.floor(radius * (maxAlpha / 255) + 0.5);
	if fz > 0 then
		Render.FilledCircle(pos, radius, Color(0, 0, 0, fz));
	end
	for i = 1, fadeWidth do
		local q = i / fadeWidth;
		local a = math.floor(radius * (1.0 - q) * (maxAlpha / 255) + 0.5);
		if a > 0 then
			Render.Circle(pos, radius + i, Color(0, 0, 0, a), 1);
		end
	end
end

-- Draw minimap panel - COMPLETE with DOCK SYSTEM
local function drawMinimapPanel()
	if not minimapPanel then return end
	
	local screenSize = Render.ScreenSize();
	local screenW = screenSize.x;
	local screenH = screenSize.y;
	
	local panelX = minimapPanel.x or 20;
	local panelY = minimapPanel.y or 24;
	local panelW = minimapPanel.width or 328;
	local headerH = minimapPanel.header_h or 22;
	local padding = minimapPanel.padding or 11;
	local margin = minimapPanel.margin or 4;

	-- Initialize default position: start on the right side
	if not minimapPanel._initialized then
		minimapPanel.x = math.max(0, screenW - panelW - 20);
		minimapPanel.y = panelY;
		panelX = minimapPanel.x;
		panelY = minimapPanel.y;
		minimapPanel.hidden = false;
		minimapPanel.docked_side = nil;
		minimapPanel._initialized = true;
	end
	
	-- ========== DOCK SYSTEM ==========
	local DOCK_TOLERANCE = 50;  -- Aumentado para detectar mais facilmente quando arrastar pro lado
	local DOCK_SPEED = 3000;  -- pixels per second
	local DOCK_STRIP_W = 48;  -- Width of dock strip
	
	-- Detect dock side based on position (when not dragging)
	if not minimapPanel.dragging and not minimapPanel.hidden then
		if panelX <= DOCK_TOLERANCE then
			minimapPanel.docked_side = "left";
		elseif panelX + panelW >= screenW - DOCK_TOLERANCE then
			minimapPanel.docked_side = "right";
		else
			minimapPanel.docked_side = nil;
		end
	else
		if minimapPanel.docked_side == nil and minimapPanel.hidden then
			if panelX <= screenW / 2 then
				minimapPanel.docked_side = "left";
			else
				minimapPanel.docked_side = "right";
			end
		end
	end
	
	-- Animate dock sliding
	local dockDt = deltaTime(minimapPanel, '_dock_prev_time');
	local dockTarget = (minimapPanel.hidden and minimapPanel.docked_side) and panelW or 0;
	minimapPanel._dock_s_h = smoothValue(minimapPanel, '_dock_s_h', dockTarget, dockDt, 0.08);
	minimapPanel._dock_s_b = minimapPanel._dock_s_h;
	
	-- Adjust panel X position based on dock state
	local displayX = panelX;
	if minimapPanel.docked_side == "left" then
		displayX = 0 - minimapPanel._dock_s_h;
	elseif minimapPanel.docked_side == "right" then
		displayX = screenW - panelW + minimapPanel._dock_s_h;
	end
	
	-- ========== DOCK STRIP (When docked and hidden) ==========
	if minimapPanel.docked_side and minimapPanel.hidden then
		local stripX, stripY, stripW, stripH = 0, 24, DOCK_STRIP_W, headerH;
		if minimapPanel.docked_side == "right" then
			stripX = screenW - DOCK_STRIP_W;
		end
		
		-- Check dock strip hover
		local mx, my = Input.GetCursorPos();
		local dockStripHover = mx and my and mx >= stripX and mx <= stripX + stripW and my >= stripY and my <= stripY + stripH;
		
		-- Draw dock strip
		local stripColor = dockStripHover and Color(40, 90, 130, 255) or Color(20, 60, 100, 240);
		Render.FilledRect(Vec2(stripX, stripY), Vec2(stripX + stripW, stripY + stripH), stripColor, 8);
		Render.Rect(Vec2(stripX, stripY), Vec2(stripX + stripW, stripY + stripH), Color(100, 150, 200, 200), 8);
		
		-- Draw arrow icon to expand
		local rfont = getRenderFont("Tahoma");
		local arrowIcon = minimapPanel.docked_side == "left" and ">" or "<";
		Render.Text(rfont, 16, arrowIcon, Vec2(stripX + (dockStripHover and 12 or 13), stripY + (dockStripHover and 1 or 2)), dockStripHover and Color(200, 255, 255, 255) or Color(150, 200, 255, 255));
		
		-- Click to expand dock
		if mx and my and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
			if dockStripHover then
				minimapPanel.hidden = false;
			end
		end
		return;
	end
	
	-- ========== HEADER ==========
	local headerY = displayX >= 0 and panelY or panelY;
	local headerRect1 = Vec2(displayX, headerY);
	local headerRect2 = Vec2(displayX + panelW, headerY + headerH);
	
	-- Header background
	Render.FilledRect(headerRect1, headerRect2, Color(20, 60, 100, 220), 5);
	Render.Rect(headerRect1, headerRect2, Color(100, 150, 200, 255), 5);
	
	-- Title
	local rfont = getRenderFont("Tahoma");
	Render.Text(rfont, 15, "AutoStack Minimap", Vec2(displayX + 15, headerY + 5), Color(150, 200, 255, 255));
	
	-- Collapse/Dock button (chevron or arrow)
	local chevronX = displayX + panelW - 35;
	local chevronY = headerY + 5;
	Render.FilledRect(Vec2(chevronX, chevronY), Vec2(chevronX + 20, chevronY + 12), Color(100, 100, 100, 180), 3);
	
	local chevronIcon;
	if minimapPanel.docked_side then
		chevronIcon = minimapPanel.docked_side == "left" and ">" or "<";
	else
		chevronIcon = minimapPanel.expanded and "−" or "+";
	end
	Render.Text(rfont, 12, chevronIcon, Vec2(chevronX + (minimapPanel.docked_side and 4 or 6), chevronY - 2), Color(255, 255, 255, 255));
	
	-- Store chevron bounds for click detection
	minimapPanel._chevron = { x0 = chevronX, y0 = chevronY, x1 = chevronX + 20, y1 = chevronY + 12 };
	
	-- Check for header click
	local mx, my = Input.GetCursorPos();
	if mx and my and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
		-- Collapse/Dock button click
		if mx >= minimapPanel._chevron.x0 and mx <= minimapPanel._chevron.x1 and
		   my >= minimapPanel._chevron.y0 and my <= minimapPanel._chevron.y1 then
			if minimapPanel.docked_side then
				minimapPanel.hidden = not minimapPanel.hidden;
			else
				minimapPanel.expanded = not minimapPanel.expanded;
			end
			minimapPanel._anim_t = minimapPanel.expanded and 1.0 or 0.0;
		end
		-- Drag detection
		if mx >= headerRect1.x and mx <= headerRect2.x and
		   my >= headerRect1.y and my <= headerRect2.y and
		   not (mx >= minimapPanel._chevron.x0 and mx <= minimapPanel._chevron.x1) then
			minimapPanel.dragging = true;
			minimapPanel.drag_dx = mx - displayX;
			minimapPanel.drag_dy = my - panelY;
			minimapPanel.docked_side = nil;  -- Undock when dragging
		end
	end
	
	-- Handle dragging
	if minimapPanel.dragging and Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
		if mx and my then
			minimapPanel.x = mx - minimapPanel.drag_dx;
			minimapPanel.y = my - minimapPanel.drag_dy;
			displayX = minimapPanel.x;
			panelX = minimapPanel.x;
			panelY = minimapPanel.y;
		end
	else
		minimapPanel.dragging = false;
		-- Auto-snap to edges when released
		if minimapPanel.x <= DOCK_TOLERANCE then
			minimapPanel.x = 0;
		elseif minimapPanel.x + panelW >= screenW - DOCK_TOLERANCE then
			minimapPanel.x = screenW - panelW;
		end
	end
	
	-- ========== COLLAPSE/EXPAND ANIMATION ==========
	local now = GameRules.GetGameTime and GameRules.GetGameTime() or 0.0;
	local dT = deltaTime(minimapPanel, '_anim_prev_time');
	local animDuration = 0.13;
	local targetExpanded = minimapPanel.expanded and 1.0 or 0.0;
	local animSpeed = animDuration > 1e-6 and dT / animDuration or 1.0;
	
	if targetExpanded > minimapPanel._anim_t then
		minimapPanel._anim_t = math.min(1.0, minimapPanel._anim_t + animSpeed);
	elseif targetExpanded < minimapPanel._anim_t then
		minimapPanel._anim_t = math.max(0.0, minimapPanel._anim_t - animSpeed);
	end
	
	local easing = minimapPanel._anim_t;
	easing = easing * easing * (3 - 2 * easing); -- Smoothstep
	
	-- If collapsed, only show header
	if easing <= 0.01 then
		return;
	end
	
	-- ========== BODY BACKGROUND ==========
	local BTN_W = 147;
	local BTN_H = 22;
	local BTN_GAP = 12;
	local IMG_W = 306;
	local IMG_H = 306;
	
	local bodyStartY = headerY + headerH + margin;
	local contentHeight = BTN_H + BTN_GAP + IMG_H + padding * 2;
	local animatedHeight = math.max(0, math.floor((contentHeight - padding * 2) * easing + 0.5));
	local bodyHeight = padding * 2 + animatedHeight;
	
	local bodyRect1 = Vec2(displayX, bodyStartY);
	local bodyRect2 = Vec2(displayX + panelW, bodyStartY + bodyHeight);
	
	if easing > 0.01 then
		-- Body background
		Render.FilledRect(bodyRect1, bodyRect2, Color(15, 15, 20, 240), 8);
		Render.Rect(bodyRect1, bodyRect2, Color(100, 150, 200, 255), 8);
		
		-- ========== RADIANT/DIRE TOGGLE BUTTONS ==========
		local btnStartY = bodyStartY + padding;
		local btnX1 = displayX + (panelW - (BTN_W * 2 + BTN_GAP)) / 2;
		local btnX2 = btnX1 + BTN_W + BTN_GAP;
		
		-- Check if all camps are enabled for each side
		local allRadiantOn = areAllCampsEnabledForSide("radiant");
		local allDireOn = areAllCampsEnabledForSide("dire");
		local hasRadiant = allRadiantOn or (not allRadiantOn and #(CAMP_POINTS or {}) > 0);  -- true if any radiant camp exists
		local hasDire = allDireOn or (not allDireOn and #(CAMP_POINTS or {}) > 0);  -- true if any dire camp exists
		
		-- Radiant button
		local radiantHover = mx and my and mx >= btnX1 and mx <= btnX1 + BTN_W and my >= btnStartY and my <= btnStartY + BTN_H;
		local radiantColor = (hasRadiant and allRadiantOn) and Color(90, 140, 255, 200) or Color(60, 60, 80, 150);
		Render.FilledRect(Vec2(btnX1, btnStartY), Vec2(btnX1 + BTN_W, btnStartY + BTN_H), radiantColor, 3);
		Render.Text(rfont, 14, "Radiant", Vec2(btnX1 + 35, btnStartY + 4), Color(200, 200, 255, 255));
		
		minimapPanel._btn_radiant = { x0 = btnX1, y0 = btnStartY, x1 = btnX1 + BTN_W, y1 = btnStartY + BTN_H };
		
		-- Dire button
		local direHover = mx and my and mx >= btnX2 and mx <= btnX2 + BTN_W and my >= btnStartY and my <= btnStartY + BTN_H;
		local direColor = (hasDire and allDireOn) and Color(90, 140, 255, 200) or Color(60, 60, 80, 150);
		Render.FilledRect(Vec2(btnX2, btnStartY), Vec2(btnX2 + BTN_W, btnStartY + BTN_H), direColor, 3);
		Render.Text(rfont, 14, "Dire", Vec2(btnX2 + 48, btnStartY + 4), Color(200, 200, 255, 255));
		
		minimapPanel._btn_dire = { x0 = btnX2, y0 = btnStartY, x1 = btnX2 + BTN_W, y1 = btnStartY + BTN_H };
		
		-- Handle button clicks (track previous state to detect single click)
		local mouseDown = mx and my and Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1);
		minimapPanel._prev_mouse_down = minimapPanel._prev_mouse_down or false;
		local mouseClicked = mouseDown and not minimapPanel._prev_mouse_down;
		minimapPanel._prev_mouse_down = mouseDown;
		
		if mouseClicked then
			if radiantHover and hasRadiant then
				-- Toggle all radiant camps
				local shouldEnable = not allRadiantOn;
				setCampsEnabledForSide("radiant", shouldEnable);
				print(string.format("[Minimap] %s Radiant camps", shouldEnable and "Enabled" or "Disabled"));
			end
			if direHover and hasDire then
				-- Toggle all dire camps
				local shouldEnable = not allDireOn;
				setCampsEnabledForSide("dire", shouldEnable);
				print(string.format("[Minimap] %s Dire camps", shouldEnable and "Enabled" or "Disabled"));
			end
		end
		
		-- ========== MINIMAP IMAGE AREA ==========
		local minimapImageY = btnStartY + BTN_H + BTN_GAP;
		local minimapImageX = displayX + (panelW - IMG_W) / 2;
		local OVERLAY_OFF = 0;  -- show full image without cropping
		
		-- Load and draw background image
		local bgImg = loadMinimapBackground();
		if bgImg then
			Render.Image(bgImg, Vec2(minimapImageX, minimapImageY), Vec2(IMG_W, IMG_H), Color(255, 255, 255, 255));
		else
			-- Fallback: brighter background so it never stays black
			Render.FilledRect(Vec2(minimapImageX, minimapImageY), Vec2(minimapImageX + IMG_W, minimapImageY + IMG_H), Color(90, 130, 180, 235), 8);
			Render.Rect(Vec2(minimapImageX, minimapImageY), Vec2(minimapImageX + IMG_W, minimapImageY + IMG_H), Color(140, 180, 215, 220), 8);
		end
		
		-- Clipping for minimap content
		local mapClip1 = Vec2(minimapImageX + OVERLAY_OFF, minimapImageY + OVERLAY_OFF);
		local mapClip2 = Vec2(minimapImageX + IMG_W - OVERLAY_OFF, minimapImageY + IMG_H - OVERLAY_OFF);
		Render.PushClip(mapClip1, mapClip2);
		
		-- ========== MAP CONSTANTS ==========
		local RING_R = 8.0;
		local RING_TH = 1.5;
		local DOT_R = 3.5;
		local RING_HIT_R = 10;
		local SHADOW_MAX_A = 160;
		local SHADOW_FADE_W = 5;
		local MINIMAP_BASE_RING_R = 8.5;
		local RING_HOVER_SCALE = 1.28;
		local MINIMAP_ENABLED_TAU = 0.05;
		local MINIMAP_SCALE_TAU = 0.08;
		
		-- Map bounds (adjusted to match image proportions)
		local minx, miny, maxx, maxy = -8192, -8192, 8192, 8192;
		
		-- World to minimap conversion
		local function worldToMinimap(pos)
			if not pos then return nil, nil end
			local bv = (pos.x - minx) / (maxx - minx);
			local px = (pos.y - miny) / (maxy - miny);
			bv = math.max(0, math.min(1, bv));
			px = math.max(0, math.min(1, px));
			local mapx = minimapImageX + OVERLAY_OFF + bv * (IMG_W - 2 * OVERLAY_OFF);
			local mapy = minimapImageY + OVERLAY_OFF + (1.0 - px) * (IMG_H - 2 * OVERLAY_OFF);
			return mapx, mapy;
		end
		
		-- Minimap to world conversion (inverse)
		local function minimapToWorld(screenX, screenY)
			if not screenX or not screenY then return nil end
			local bv = (screenX - (minimapImageX + OVERLAY_OFF)) / (IMG_W - 2 * OVERLAY_OFF);
			local px = (screenY - (minimapImageY + OVERLAY_OFF)) / (IMG_H - 2 * OVERLAY_OFF);
			bv = math.max(0, math.min(1, bv));
			px = math.max(0, math.min(1, px));
			local worldX = minx + bv * (maxx - minx);
			local worldY = miny + (1.0 - px) * (maxy - miny);
			return Vector(worldX, worldY, 0);
		end
		
		-- ========== DRAW CAMPS ON MINIMAP ==========
		local inactiveColor = Color(120, 120, 130);
		local activeColor = Color(90, 140, 255);
		local disabledColor = Color(80, 80, 100);
		local dTMinimap = deltaTime(minimapPanel, '_minimap_anim_prev_time');
		
		minimapPanel._minimap_points = {};
		minimapPanel._hover_camp_id = nil;
		minimapPanel._minimap_rect = { x0 = mapClip1.x, y0 = mapClip1.y, x1 = mapClip2.x, y1 = mapClip2.y };
		
		for campId, camp in pairs(CAMP_POINTS or {}) do
			if camp and camp.wait then
				local mx_map, my_map = worldToMinimap(camp.wait);
				if mx_map and my_map then
					local pos = Vec2(math.floor(mx_map + 0.5), math.floor(my_map + 0.5));
					
					-- Check if camp is enabled
					local isEnabled = isCampEnabled(campId);
					
					-- Check hover
					local isHover = false;
					local isHoverRaw = false;
					if mx and my then
						local dx = mx - pos.x;
						local dy = my - pos.y;
						isHoverRaw = (dx * dx + dy * dy) <= (RING_HIT_R * RING_HIT_R);
						if isHoverRaw then
							minimapPanel._hover_camp_id = campId;
						end
					end
					isHover = isHoverRaw and isEnabled;
					
					-- Draw shadow
					drawShadow(pos, math.floor(MINIMAP_BASE_RING_R + 0.5), SHADOW_MAX_A, SHADOW_FADE_W);
					
					-- Animate ring scale (hover effect)
					local hoverScale = isHover and RING_HOVER_SCALE or 1.0;
					local currentScale = minimapPanel._minimap_ring_scale[campId] or 1.0;
					local animatedScale = smoothValue(minimapPanel._minimap_ring_scale, campId, hoverScale, dTMinimap, MINIMAP_SCALE_TAU);
					local ringR = RING_R * animatedScale;
					
					-- Animate enabled/disabled fade
					local targetAlpha = isEnabled and 1.0 or 0.5;
					local animatedAlpha = smoothValue(minimapPanel._minimap_enabled_t, campId, targetAlpha, dTMinimap, MINIMAP_ENABLED_TAU);
					
					-- Draw ring
					local ringColor;
					if not isEnabled then
						ringColor = disabledColor;
					else
						ringColor = lerpColor(inactiveColor, activeColor, animatedAlpha);
					end
					Render.Circle(pos, ringR, ringColor, RING_TH);
					
					-- Draw dot
					if animatedAlpha > 0.01 then
						local dotColor = isEnabled and activeColor or disabledColor;
						Render.FilledCircle(pos, math.max(0.001, animatedAlpha) * DOT_R, dotColor);
					end
					
					-- Store for click detection
					table.insert(minimapPanel._minimap_points, {
						id = campId,
						cx = pos.x,
						cy = pos.y,
						r = ringR,
						r_hit = RING_HIT_R,
						type = "wait"
					});
				end
			end
		end
		
		-- ========== HANDLE MINIMAP CLICKS ==========
		-- Handle builder mode waypoint dragging
		if builder_state.enabled and mx and my then
			if mx >= minimapPanel._minimap_rect.x0 and mx <= minimapPanel._minimap_rect.x1 and
			   my >= minimapPanel._minimap_rect.y0 and my <= minimapPanel._minimap_rect.y1 then
				
				-- Check if starting a waypoint drag (track mouse state)
				local mouseDown = Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1);
				minimapPanel._drag_mouse_down = minimapPanel._drag_mouse_down or false;
				local dragMouseClicked = mouseDown and not minimapPanel._drag_mouse_down;
				minimapPanel._drag_mouse_down = mouseDown;
				
				if dragMouseClicked and not minimapPanel._dragging_waypoint then
					for _, K in ipairs(minimapPanel._minimap_points) do
						local dn = mx - (K.cx or 0);
						local dp = my - (K.cy or 0);
						local dq = K.r_hit or K.r or 10;
						if dn * dn + dp * dp <= dq * dq then
							-- Start dragging waypoint
							minimapPanel._dragging_waypoint = K.id;
							minimapPanel._dragging_waypoint_type = K.type or "wait";
							minimapPanel._drag_offset_x = mx - K.cx;
							minimapPanel._drag_offset_y = my - K.cy;
							break;
						end
					end
				end
				
				-- Update waypoint position during drag
				if minimapPanel._dragging_waypoint and Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
					local campId = minimapPanel._dragging_waypoint;
					local camp = CAMP_POINTS[campId];
					if camp then
						-- Convert screen coords to world coords
						local newWorldPos = minimapToWorld(mx - minimapPanel._drag_offset_x, my - minimapPanel._drag_offset_y);
						if newWorldPos then
							-- Update ACTIVE_POINTS for editor
							if not ACTIVE_POINTS[campId] then
								ACTIVE_POINTS[campId] = { wait = camp.wait, pull = camp.pull, side = camp.side };
							end
							ACTIVE_POINTS[campId][minimapPanel._dragging_waypoint_type] = newWorldPos;
						end
					end
				end
				
				-- Stop dragging
				if minimapPanel._dragging_waypoint and not Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
					-- Changes are already saved in ACTIVE_POINTS above
					minimapPanel._dragging_waypoint = nil;
					minimapPanel._dragging_waypoint_type = nil;
					minimapPanel._drag_offset_x = 0;
					minimapPanel._drag_offset_y = 0;
				end
			end
		else
			-- Normal mode: just toggle camps
			local mouseDown = Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1);
			minimapPanel._toggle_mouse_down = minimapPanel._toggle_mouse_down or false;
			local toggleMouseClicked = mouseDown and not minimapPanel._toggle_mouse_down;
			minimapPanel._toggle_mouse_down = mouseDown;
			
			if mx and my and toggleMouseClicked then
				if mx >= minimapPanel._minimap_rect.x0 and mx <= minimapPanel._minimap_rect.x1 and
				   my >= minimapPanel._minimap_rect.y0 and my <= minimapPanel._minimap_rect.y1 then
					for _, K in ipairs(minimapPanel._minimap_points) do
						local dn = mx - (K.cx or 0);
						local dp = my - (K.cy or 0);
						local dq = K.r_hit or K.r or 10;
						if dn * dn + dp * dp <= dq * dq then
							local currentlyEnabled = minimapPanel.camp_enabled[K.id] ~= false;
							if currentlyEnabled then
								minimapPanel.camp_enabled[K.id] = false;
							else
								minimapPanel.camp_enabled[K.id] = nil;
							end
							break;
						end
					end
				end
			end
		end
		
		Render.PopClip();
	end
end

function OnDraw()
	local allowFancy = (isActive and fancyVisuals and fancyVisuals:Get()) or false;
	local shouldDrawMinimap = (isActive or autoNonHeroActive);
	if (not debugDraw:Get() and not (presets_ui and builder_state.enabled) and not shouldDrawMinimap) then
		return;
	end
	local title = "Auto Stacker: " .. (isActive and "ON" or "OFF") .. (autoNonHeroActive and " [AUTO]" or "");
	local fontIdx = ((debugFontFamily and debugFontFamily:Get()) or 0) + 1;
	local fontName = availableFonts[fontIdx] or "Tahoma";
	local fontSize = math.max(12, debugFontSize:Get());
	local rfont = getRenderFont(fontName);
	local textSize = Render.TextSize(rfont, fontSize, title);
	
	-- Draw minimap panel
	if shouldDrawMinimap then
		drawMinimapPanel();
	end
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
	Render.Blur(Vec2(x1, y1), Vec2(x2, y2), NaN, 1, 8);
	-- Left indicator bar - changes based on mode
	local barColor = Color(68, 68, 68, 220);
	if autoNonHeroActive then
		barColor = Color(255, 165, 0, 255); -- Orange for auto mode
	elseif isActive then
		barColor = Color(46, 204, 113, 255); -- Green for manual mode
	end
	Render.FilledRect(Vec2(x1, y1), Vec2(x1 + 5, y2), barColor, 8);
	
	local dotR = math.floor(fontSize * 0.45);
	local statusColor = (isActive and Color(46, 204, 113, 255)) or Color(231, 76, 60, 255);
	if autoNonHeroActive then
		statusColor = Color(255, 165, 0, 255); -- Orange dot for auto mode
	end
	Render.FilledCircle(Vec2(x1 + paddingX, y1 + (height / 2)), dotR, statusColor);
	
	-- Add pulsing effect for auto mode
	if autoNonHeroActive then
		local pulse = (math.sin(gameTimeSeconds() * 3) * 0.3) + 0.7;
		local pulseColor = Color(255, 165, 0, math.floor(pulse * 255));
		Render.FilledCircle(Vec2(x1 + paddingX, y1 + (height / 2)), dotR + 2, pulseColor);
	end
	
	local tx = x1 + paddingX + (dotR * 2) + 8;
	local ty = (y1 + ((height - fontSize) / 2)) - 1;
	Render.Text(rfont, fontSize, title, Vec2(tx, ty), Color(255, 255, 255, 240));
	local font = Renderer.LoadFont(fontName, fontSize, Enum.FontCreate.FONTFLAG_ANTIALIAS, 1);
	if (isActive and selectedUnits and (#selectedUnits > 0)) then
		if not (fancyVisuals and fancyVisuals:Get()) then
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
					local baseHit = (isUnitRanged(u) and firstHitSecRanged:Get()) or firstHitSecMelee:Get();
					local stacks = campStacks[campId] or 0;
					local perStackShift = perStackShiftCenti:Get() / 100;
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
		local fontIdx = ((debugFontFamily and debugFontFamily:Get()) or 0) + 1;
		local fontName = availableFonts[fontIdx] or "Tahoma";
		local fontSize = math.max(12, debugFontSize:Get());
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
					stack_presets[tgtPreset] = stack_presets[tgtPreset] or {points={},disabled={}};
					stack_presets[tgtPreset].points[builder_state.dragCamp] = stack_presets[tgtPreset].points[builder_state.dragCamp] or {};
					stack_presets[tgtPreset].points[builder_state.dragCamp][builder_state.dragType] = v;
					SaveStackPresets();
					if (isActive and (builder_state.dragType == "wait")) then
						local campId = builder_state.dragCamp;
						local tnow = gameTimeSeconds();
						local minute = math.floor(tnow / 60);
						local sec = tnow % 60;
						local stacks = campStacks[campId] or 0;
						local perStackShift = perStackShiftCenti:Get() / 100;
						local player = Players.GetLocal();
						for _, u in ipairs(selectedUnits or {}) do
							if ((unitToCampId[u] == campId) and isEntityAlive(u)) then
								local st = ensureTimelineFor(u, minute);
								local baseHit = (isUnitRanged(u) and firstHitSecRanged:Get()) or firstHitSecMelee:Get();
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