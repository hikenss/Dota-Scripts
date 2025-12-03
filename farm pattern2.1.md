local FarmPattern = {};
local localHero = nil;
local localTeam = nil;
local displayAlpha = 0;
local alphaStep = 10;
local easingFactor = 0.2;
local smoothCheckpoints = {};
local segmentCheckpoints = {};
local smoothRouteNodes = {};
local timelineCursorX = 0;
local panelFont = nil;
local baseFontSize = 16;
local lastPanelFontSize = 0;
local menuRoot = Menu.Create("Scripts", "User Scripts", "Farm Pattern");
local menuOptions = menuRoot:Create("Options");
local menuMain = menuOptions:Create("Main");
local menuAlgo = menuOptions:Create("Algorithm");
local menuVis = menuOptions:Create("Visualization");
local menuAdv = menuOptions:Create("Advanced");
local opt = {};
opt.enabled = menuMain:Switch("Show Farm Route", true);
opt.ctrlToDrag = menuMain:Switch("Ctrl-Drag Stats Text", true);
opt.optimized = menuAlgo:Switch("Show Optimal Path", true);
opt.algorithm = menuAlgo:Combo("Algorithm", {"Greedy","Optimal (Advanced)","Beam Search"}, 1);
opt.searchRadius = menuAlgo:Slider("Search Radius", 500, 6000, 1500);
opt.allyRadius = menuAlgo:Slider("Ally Exclusion Radius", 300, 1000, 600);
opt.pointsCount = menuAlgo:Slider("Points to Calculate", 2, 10, 4);
opt.minEfficiency = menuAlgo:Slider("Min Efficiency (g/s)", 0, 50, 10);
opt.goldWeight = menuAlgo:Slider("Gold Weight", 0.5, 2, 1);
opt.xpWeight = menuAlgo:Slider("XP Weight", 0, 2, 0.7);
opt.dynamicUpdate = menuAlgo:Switch("Dynamic Route Updates", true);
opt.checkpointCount = menuAlgo:Slider("Checkpoints per Path", 1, 10, 5);
opt.beamWidth = menuAlgo:Slider("Beam Width", 1, 10, 3);
opt.maxBeamNodes = menuAlgo:Slider("Max Beam Nodes", 10, 200, 60);
opt.stackBias = menuAlgo:Slider("Jungle Stacking Bias", 0, 2, 0.5);
opt.showVisualization = menuVis:Switch("Toggle Visualization", true);
opt.visualColor = menuVis:ColorPicker("Visual Color", Color(0, 255, 128));
opt.circleSize = menuVis:Slider("Point Size", 5, 30, 10);
opt.lineThickness = menuVis:Slider("Line Thickness", 1, 6, 2);
opt.futureOpacity = menuVis:Slider("Future Segment Opacity (%)", 0, 100, 50);
opt.showPointIndex = menuVis:Switch("Show Point Index", true);
opt.showGold = menuVis:Switch("Show Gold Values", true);
opt.panelScale = menuVis:Slider("HUD Scale (%)", 60, 160, 100);
opt.farmTimePerCreep = menuAdv:Slider("Farm Time/Creep (s)", 0.5, 3, 1);
opt.easingFactor = menuAdv:Slider("Smoothing Factor", 0.05, 0.5, 0.2);
opt.alphaStep = menuAdv:Slider("Fade Step", 1, 25, 10);
opt.advanceDistance = menuAdv:Slider("Advance Segment Distance", 50, 500, 220);
db.farmRouteIndicator = db.farmRouteIndicator or {};
local hud = db.farmRouteIndicator;
hud.x = hud.x or 10;
hud.y = hud.y or 320;
local dragging = false;
local dragDelta = Vec2(0, 0);
local spots = {};
local route = {};
local lastTick = 0;
local currentSegmentIndex = 1;
local lastHeroPos = nil;
local function timeSinceStart()
	local t = GameRules.GetGameTime() - GameRules.GetGameStartTime();
	if (t < 0) then
		t = 0;
	end
	return t;
end
local function getLocalHero()
	if not localHero then
		localHero = Heroes.GetLocal();
	end
	return localHero;
end
local function getLocalTeam()
	if not localTeam then
		local p = Players.GetLocal();
		local slot = Player.GetPlayerSlot(p);
		localTeam = ((slot < 5) and Enum.TeamNum.TEAM_RADIANT) or Enum.TeamNum.TEAM_DIRE;
	end
	return localTeam;
end
local function countKeys(tbl)
	local n = 0;
	if tbl then
		for _ in pairs(tbl) do
			n = n + 1;
		end
	end
	return n;
end
local function estimateClearSeconds(spot)
	local hero = getLocalHero();
	if not hero then
		return opt.farmTimePerCreep:Get();
	end
	local creepCount = spot.creepCount or 0;
	if (creepCount == 0) then
		if (spot.gold > 150) then
			creepCount = 5;
		elseif (spot.gold > 100) then
			creepCount = 4;
		else
			creepCount = 3;
		end
	end
	local trueDps = NPC.GetTrueDamage(hero) * NPC.GetAttackSpeed(hero);
	local baselineHp = 300;
	local dpsFactor = baselineHp / math.max(50, trueDps);
	local hasAoE = false;
	local abilityIds = {"juggernaut_blade_fury","axe_counter_helix","antimage_blink","phantom_assassin_stifling_dagger","luna_moon_glaive","sven_great_cleave"};
	for _, name in ipairs(abilityIds) do
		local a = NPC.GetAbility(hero, name);
		if (a and Ability.IsReady(a)) then
			hasAoE = true;
			break;
		end
	end
	local seconds = creepCount * dpsFactor;
	if hasAoE then
		seconds = seconds * 0.6;
	end
	return math.max(seconds, creepCount * opt.farmTimePerCreep:Get());
end
local function stackBiasWeight(isJungle)
	if not isJungle then
		return 1;
	end
	local sec = math.floor(timeSinceStart() % 60);
	if ((sec < 40) or (sec > 56)) then
		return 1;
	end
	local peak = 50;
	local dist = math.abs(sec - peak);
	local norm = math.max(0, 1 - (dist / 10));
	return 1 + (opt.stackBias:Get() * norm);
end
local function interpolatePoints(a, b, count)
	local pts = {};
	for i = 1, count do
		local t = i / (count + 1);
		local x = a.x + ((b.x - a.x) * t);
		local y = a.y + ((b.y - a.y) * t);
		local z = a.z + ((b.z - a.z) * t);
		table.insert(pts, Vector(x, y, z));
	end
	return pts;
end
local function smoothRouteNodesTowards()
	if (#route == 0) then
		smoothRouteNodes = {};
		return;
	end
	for i = 1, #route do
		local target = route[i].pos;
		local cur = smoothRouteNodes[i] or Vector(target.x, target.y, target.z);
		cur.x = cur.x + ((target.x - cur.x) * easingFactor);
		cur.y = cur.y + ((target.y - cur.y) * easingFactor);
		cur.z = cur.z + ((target.z - cur.z) * easingFactor);
		smoothRouteNodes[i] = cur;
	end
	for i = #route + 1, #smoothRouteNodes do
		smoothRouteNodes[i] = nil;
	end
end
local function ensurePanelFont()
	local scale = ((opt.panelScale and opt.panelScale:Get()) or 100) / 100;
	local desiredSize = math.max(10, math.floor(baseFontSize * scale));
	if (desiredSize ~= lastPanelFontSize) then
		panelFont = Renderer.LoadFont("MuseoSansEx", desiredSize, Enum.FontCreate.FONTFLAG_ANTIALIAS, 1);
		lastPanelFontSize = desiredSize;
	end
end
local function allyNear(pos, radius)
	local hero = getLocalHero();
	if not hero then
		return false;
	end
	local team = getLocalTeam();
	local allies = Heroes.InRadius(pos, radius, team, Enum.TeamType.TEAM_FRIEND);
	for _, ally in ipairs(allies) do
		if ((ally ~= hero) and Entity.IsAlive(ally)) then
			return true;
		end
	end
	return false;
end
local function buildSegmentCheckpoints(unit, points, perSegment)
	local segments = {};
	local origin = Entity.GetAbsOrigin(unit);
	if (#points > 0) then
		table.insert(segments, interpolatePoints(origin, points[1].pos, perSegment));
	end
	for i = 1, #points - 1 do
		table.insert(segments, interpolatePoints(points[i].pos, points[i + 1].pos, perSegment));
	end
	return segments;
end
local function smoothTowards()
	for si, seg in ipairs(segmentCheckpoints) do
		smoothCheckpoints[si] = smoothCheckpoints[si] or {};
		for pi, pos in ipairs(seg) do
			local cur = smoothCheckpoints[si][pi] or Vector(pos.x, pos.y, pos.z);
			cur.x = cur.x + ((pos.x - cur.x) * easingFactor);
			cur.y = cur.y + ((pos.y - cur.y) * easingFactor);
			cur.z = cur.z + ((pos.z - cur.z) * easingFactor);
			smoothCheckpoints[si][pi] = cur;
		end
	end
end
local function greedyRoute()
	local hero = getLocalHero();
	if not hero then
		return {};
	end
	local heroPos = Entity.GetAbsOrigin(hero);
	local ms = NPC.GetMoveSpeed(hero);
	local pool = {};
	for _, s in ipairs(spots) do
		local xp = s.gold * 0.8;
		table.insert(pool, {pos=s.pos,gold=s.gold,xp=xp,creepCount=s.creepCount,isJungle=s.isJungle});
	end
	local chosen = {};
	local current = heroPos;
	local minEff = opt.minEfficiency:Get();
	local maxPoints = opt.pointsCount:Get();
	local gw = opt.goldWeight:Get();
	local xw = opt.xpWeight:Get();
	while (#pool > 0) and (#chosen < maxPoints) do
		local bestIdx = nil;
		local bestScore = 0;
		for i, c in ipairs(pool) do
			local travel = GridNav.GetTravelTime(current, c.pos, false, nil, ms);
			local clear = estimateClearSeconds(c);
			local value = ((c.gold * gw) + (c.xp * xw)) * stackBiasWeight(c.isJungle);
			local eff = value / (travel + clear);
			if ((eff >= minEff) and (eff > bestScore)) then
				bestScore = eff;
				bestIdx = i;
			end
		end
		if not bestIdx then
			break;
		end
		table.insert(chosen, pool[bestIdx]);
		current = pool[bestIdx].pos;
		table.remove(pool, bestIdx);
	end
	return chosen;
end
local function rankCandidatesFrom(pos, cands, ms, gw, xw, minEff)
	local ranked = {};
	for _, c in ipairs(cands) do
		local travel = GridNav.GetTravelTime(pos, c.pos, false, nil, ms);
		local clear = estimateClearSeconds(c);
		local eff = ((c.gold * gw) + (c.gold * 0.8 * xw)) / (travel + clear);
		eff = eff * stackBiasWeight(c.isJungle);
		if (eff >= minEff) then
			table.insert(ranked, {pos=c.pos,gold=c.gold,xp=(c.gold * 0.8),creepCount=c.creepCount,isJungle=c.isJungle,eff=eff});
		end
	end
	table.sort(ranked, function(a, b)
		return a.eff > b.eff;
	end);
	return ranked;
end
local function optimalRoute()
	local hero = getLocalHero();
	if not hero then
		return {};
	end
	local heroPos = Entity.GetAbsOrigin(hero);
	local ms = NPC.GetMoveSpeed(hero);
	local gw = opt.goldWeight:Get();
	local xw = opt.xpWeight:Get();
	local minEff = opt.minEfficiency:Get();
	local candidates = rankCandidatesFrom(heroPos, spots, ms, gw, xw, minEff);
	local limit = math.min(8, #candidates);
	if (#candidates > limit) then
		local trimmed = {};
		for i = 1, limit do
			trimmed[i] = candidates[i];
		end
		candidates = trimmed;
	end
	local function pathScore(path, totalTime)
		if (totalTime <= 0) then
			return 0;
		end
		local g, xp = 0, 0;
		for _, p in ipairs(path) do
			g = g + p.gold;
			xp = xp + p.xp;
		end
		local base = ((g * gw) + (xp * xw)) / totalTime;
		local hasJ = false;
		for _, p in ipairs(path) do
			if p.isJungle then
				hasJ = true;
				break;
			end
		end
		if hasJ then
			base = base * stackBiasWeight(true);
		end
		return base;
	end
	local bestPath, bestScore = {}, 0;
	local function dfs(remaining, currentPos, pathSoFar, timeSoFar, depth)
		if ((depth >= opt.pointsCount:Get()) or (#remaining == 0)) then
			local s = pathScore(pathSoFar, timeSoFar);
			if (s > bestScore) then
				bestPath = pathSoFar;
				bestScore = s;
			end
			return;
		end
		for i, node in ipairs(remaining) do
			local nextRemaining = {};
			for j, c in ipairs(remaining) do
				if (j ~= i) then
					table.insert(nextRemaining, c);
				end
			end
			local travel = GridNav.GetTravelTime(currentPos, node.pos, false, nil, ms);
			local clear = estimateClearSeconds(node);
			local t = timeSoFar + travel + clear;
			local newPath = {table.unpack(pathSoFar)};
			table.insert(newPath, node);
			dfs(nextRemaining, node.pos, newPath, t, depth + 1);
		end
	end
	dfs(candidates, heroPos, {}, 0, 0);
	return bestPath;
end
local function beamSearchRoute()
	local hero = getLocalHero();
	if not hero then
		return {};
	end
	local heroPos = Entity.GetAbsOrigin(hero);
	local ms = NPC.GetMoveSpeed(hero);
	local gw = opt.goldWeight:Get();
	local xw = opt.xpWeight:Get();
	local minEff = opt.minEfficiency:Get();
	local beamW = opt.beamWidth:Get();
	local maxNodes = opt.maxBeamNodes:Get();
	local function scorePath(path, totalTime)
		if (totalTime <= 0) then
			return 0;
		end
		local g, xp = 0, 0;
		for _, p in ipairs(path) do
			g = g + p.gold;
			xp = xp + p.xp;
		end
		local base = ((g * gw) + (xp * xw)) / totalTime;
		local hasJ = false;
		for _, p in ipairs(path) do
			if p.isJungle then
				hasJ = true;
				break;
			end
		end
		if hasJ then
			base = base * stackBiasWeight(true);
		end
		return base;
	end
	local initialRank = rankCandidatesFrom(heroPos, spots, ms, gw, xw, minEff);
	local frontier = {};
	for i = 1, math.min(beamW, #initialRank) do
		local n = initialRank[i];
		table.insert(frontier, {path={n},pos=n.pos,time=estimateClearSeconds(n)});
	end
	local best = {path={},score=0};
	local expansions = 0;
	while (#frontier > 0) and (expansions < maxNodes) do
		local newFrontier = {};
		for _, state in ipairs(frontier) do
			if (#state.path >= opt.pointsCount:Get()) then
				local s = scorePath(state.path, state.time);
				if (s > best.score) then
					best.path = state.path;
					best.score = s;
				end
			else
				local remaining = {};
				for _, c in ipairs(spots) do
					local used = false;
					for _, u in ipairs(state.path) do
						if (u.pos == c.pos) then
							used = true;
							break;
						end
					end
					if not used then
						table.insert(remaining, c);
					end
				end
				local ranked = rankCandidatesFrom(state.pos, remaining, ms, gw, xw, minEff);
				for i = 1, math.min(beamW, #ranked) do
					local nxt = ranked[i];
					local travel = GridNav.GetTravelTime(state.pos, nxt.pos, false, nil, ms);
					local clear = estimateClearSeconds(nxt);
					local newTime = state.time + travel + clear;
					local newPath = {table.unpack(state.path)};
					table.insert(newPath, nxt);
					table.insert(newFrontier, {path=newPath,pos=nxt.pos,time=newTime});
					expansions = expansions + 1;
				end
			end
		end
		table.sort(newFrontier, function(a, b)
			return scorePath(a.path, a.time) > scorePath(b.path, b.time);
		end);
		if (#newFrontier > beamW) then
			local trimmed = {};
			for i = 1, beamW do
				trimmed[i] = newFrontier[i];
			end
			frontier = trimmed;
		else
			frontier = newFrontier;
		end
	end
	if ((#best.path == 0) and (#frontier > 0)) then
		best.path = frontier[1].path;
	end
	return best.path;
end
local function selectRoute()
	local algo = opt.algorithm:Get();
	if (algo == 1) then
		return greedyRoute();
	elseif (algo == 2) then
		return optimalRoute();
	else
		return beamSearchRoute();
	end
end
local KEY_CTRL = Enum.ButtonCode.KEY_LCONTROL;
local KEY_MOUSE1 = Enum.ButtonCode.KEY_MOUSE1;
FarmPattern.OnUpdate = function()
	if not opt.enabled:Get() then
		return;
	end
	local hero = getLocalHero();
	if (not hero or not Entity.IsAlive(hero)) then
		return;
	end
	local now = GameRules.GetGameTime();
	local heroPos = Entity.GetAbsOrigin(hero);
	easingFactor = opt.easingFactor:Get();
	alphaStep = opt.alphaStep:Get();
	if ((now - lastTick) >= 0.1) then
		lastTick = now;
		spots = {};
		local seen = {};
		local searchR = opt.searchRadius:Get();
		local allyR = opt.allyRadius:Get();
		if (LIB_HEROES_DATA and LIB_HEROES_DATA.lane_creeps_groups) then
			for _, grp in ipairs(LIB_HEROES_DATA.lane_creeps_groups) do
				local p = grp.position;
				if ((p - heroPos):Length2D() <= searchR) then
					local g = 0;
					for _, creep in pairs(grp.creeps) do
						g = g + NPC.GetGoldBounty(creep);
					end
					local key = tostring(p);
					if ((g > 0) and not seen[key] and not allyNear(p, allyR)) then
						seen[key] = true;
						table.insert(spots, {pos=p,gold=g,isJungle=false,creepCount=countKeys(grp.creeps)});
					end
				end
			end
		end
		if (LIB_HEROES_DATA and LIB_HEROES_DATA.jungle_spots) then
			for _, camp in ipairs(LIB_HEROES_DATA.jungle_spots) do
				local p = camp.pos or ((camp.box.min + camp.box.max) * 0.5);
				if ((p - heroPos):Length2D() <= searchR) then
					local g = Camp.GetGoldBounty(camp, true);
					local key = tostring(p);
					if ((g > 0) and not seen[key] and not allyNear(p, allyR)) then
						seen[key] = true;
						table.insert(spots, {pos=p,gold=g,isJungle=true});
					end
				end
			end
		end
		if opt.optimized:Get() then
			local newRoute = selectRoute();
			route = newRoute;
			segmentCheckpoints = buildSegmentCheckpoints(hero, route, opt.checkpointCount:Get());
			if (#smoothCheckpoints ~= #segmentCheckpoints) then
				smoothCheckpoints = {};
				for i, seg in ipairs(segmentCheckpoints) do
					smoothCheckpoints[i] = {};
					for j, pt in ipairs(seg) do
						smoothCheckpoints[i][j] = Vector(pt.x, pt.y, pt.z);
					end
				end
			end
			if (#segmentCheckpoints > 0) then
				currentSegmentIndex = math.max(1, math.min(currentSegmentIndex, #segmentCheckpoints));
				local seg = segmentCheckpoints[currentSegmentIndex];
				if (seg and (#seg > 0)) then
					local lastPt = seg[#seg];
					if ((lastPt - heroPos):Length2D() <= opt.advanceDistance:Get()) then
						currentSegmentIndex = math.min(currentSegmentIndex + 1, #segmentCheckpoints);
					end
				end
			end
			if (lastHeroPos and ((heroPos - lastHeroPos):Length2D() > 2000)) then
				currentSegmentIndex = 1;
			end
			lastHeroPos = heroPos;
			for i = 1, #route do
				if not smoothRouteNodes[i] then
					local p = route[i].pos;
					smoothRouteNodes[i] = Vector(p.x, p.y, p.z);
				end
			end
		else
			route = {};
			segmentCheckpoints = {};
			smoothCheckpoints = {};
			smoothRouteNodes = {};
			currentSegmentIndex = 1;
		end
	end
end;
FarmPattern.OnDraw = function()
	if not opt.enabled:Get() then
		return;
	end
	local hero = getLocalHero();
	if (not hero or not Entity.IsAlive(hero)) then
		return;
	end
	if (not opt.optimized:Get() or (#route == 0)) then
		return;
	end
	smoothTowards();
	smoothRouteNodesTowards();
	local seconds = timeSinceStart();
	local sec = math.floor(seconds % 60);
	local heroPos = Entity.GetAbsOrigin(hero);
	local hero2D, okHero = Render.WorldToScreen(heroPos);
	local targetAlpha = (opt.showVisualization:Get() and 255) or 0;
	if (displayAlpha < targetAlpha) then
		displayAlpha = math.min(displayAlpha + alphaStep, targetAlpha);
	elseif (displayAlpha > targetAlpha) then
		displayAlpha = math.max(displayAlpha - alphaStep, targetAlpha);
	end
	if (displayAlpha <= 0) then
		return;
	end
	local a = math.floor(displayAlpha);
	local maxPoints = math.min(opt.pointsCount:Get(), #route);
	local totalGold = 0;
	for i = 1, maxPoints do
		totalGold = totalGold + route[i].gold;
	end
	local header = string.format("Farm Path: %d point(s), ~%d gold", maxPoints, math.floor(totalGold));
	local algoIdx = opt.algorithm:Get();
	local algoName = ((algoIdx == 1) and "Greedy") or ((algoIdx == 2) and "Optimal") or "Beam";
	local scale = ((opt.panelScale and opt.panelScale:Get()) or 100) / 100;
	local fontScale = scale;
	local function TextSizeScaled(text)
		ensurePanelFont();
		local tw, th = Renderer.GetTextSize(panelFont or 1, text);
		return tw, th;
	end
	local function DrawTextScaled(x, y, text, r, g, b, alpha, withShadow)
		ensurePanelFont();
		if withShadow then
			Renderer.SetDrawColor(0, 0, 0, alpha);
			Renderer.DrawText(panelFont or 1, x + 1, y + 1, text);
		end
		Renderer.SetDrawColor(r or 255, g or 255, b or 255, alpha);
		Renderer.DrawText(panelFont or 1, x, y, text);
	end
	local line1 = header;
	local l1w, l1h = TextSizeScaled(line1);
	local pad = 8;
	local gap = 8;
	local stripeW = 5;
	local segBlockW = 10;
	local segBlockH = 6;
	local segGap = 2;
	local segW = ((maxPoints > 0) and ((maxPoints * (segBlockW + segGap)) - segGap)) or 0;
	local segH = segBlockH;
	local function badgeSize(text)
		local tw, th = TextSizeScaled(text);
		return tw + 14, math.max(16, th + 6);
	end
	local badge1 = string.format("Algo: %s", algoName);
	local badge2 = (opt.dynamicUpdate:Get() and "Live") or "Static";
	local badge3 = string.format("Pts: %d", maxPoints);
	local b1w, b1h = badgeSize(badge1);
	local b2w, b2h = badgeSize(badge2);
	local b3w, b3h = badgeSize(badge3);
	local badgesW = b1w + 6 + b2w + 6 + b3w;
	local badgesH = math.max(b1h, b2h, b3h);
	local effBarW = math.max(260, l1w);
	local effBarH = 6;
	local timeBarW = effBarW;
	local timeBarH = 6;
	local effTextH = 16;
	local contentW = math.max(l1w, segW, badgesW, effBarW);
	local contentH = l1h + gap + segH + gap + badgesH + gap + effBarH + 4 + effTextH + gap + timeBarH;
	local panelW = math.floor((contentW + (pad * 2) + stripeW + 6) * scale);
	local panelH = math.floor((contentH + (pad * 2)) * scale);
	local tl = Vec2(hud.x, hud.y);
	local br = Vec2(hud.x + panelW, hud.y + panelH);
	local cx, cy = Input.GetCursorPos();
	local cursor = Vec2(cx, cy);
	if (opt.ctrlToDrag:Get() and Input.IsKeyDown(KEY_CTRL) and Input.IsKeyDownOnce(KEY_MOUSE1) and (cursor.x >= tl.x) and (cursor.x <= br.x) and (cursor.y >= tl.y) and (cursor.y <= br.y)) then
		dragging = true;
		dragDelta = tl - cursor;
	end
	if (dragging and Input.IsKeyDown(KEY_MOUSE1)) then
		local mx, my = Input.GetCursorPos();
		hud.x = mx + dragDelta.x;
		hud.y = my + dragDelta.y;
	end
	if (dragging and not Input.IsKeyDown(KEY_MOUSE1)) then
		dragging = false;
	end
	local bgAlpha = math.floor(170 * (a / 255));
	Render.FilledRect(tl, br, Color(0, 0, 0, bgAlpha), 8);
	Render.Blur(tl, br, NaN, 1, 8);
	local vc = opt.visualColor:Get();
	local sr = Color(math.floor(vc.r), math.floor(vc.g), math.floor(vc.b), math.floor(220 * (a / 255)));
	Render.FilledRect(Vec2(tl.x, tl.y), Vec2(tl.x + stripeW, br.y), sr, 8);
	local tx = tl.x + math.floor((stripeW + pad + 2) * scale);
	local ty = tl.y + math.floor(pad * scale);
	ensurePanelFont();
	DrawTextScaled(tx, ty, line1, 255, 255, 255, a, true);
	local segY = ty + math.floor(l1h + (gap * scale));
	for i = 1, maxPoints do
		local node = route[i];
		local isJ = node and node.isJungle;
		local x1 = tx + math.floor((i - 1) * (segBlockW + segGap) * scale);
		local x2 = x1 + math.floor(segBlockW * scale);
		local y1 = segY;
		local y2 = segY + math.floor(segBlockH * scale);
		local rr, gg, bb = cr, cg, cb;
		if isJ then
			rr, gg, bb = 255, 165, 0;
		end
		Render.FilledRect(Vec2(x1, y1), Vec2(x2, y2), Color(0, 0, 0, math.floor(160 * (a / 255))), 2);
		Render.FilledRect(Vec2(x1 + 1, y1 + 1), Vec2(x2 - 1, y2 - 1), Color(rr, gg, bb, math.floor(220 * (a / 255))), 2);
	end
	local by = ty + math.floor(l1h + (gap * scale) + (segH * scale) + (gap * scale));
	local function drawBadge(text, x, y, col, alpha)
		local tw, th = TextSizeScaled(text);
		local bx1, by1 = x, y;
		local bx2, by2 = x + tw + 14, y + th + 6;
		Render.FilledRect(Vec2(bx1, by1), Vec2(bx2, by2), Color(col[1], col[2], col[3], math.floor(210 * (alpha / 255))), 6);
		DrawTextScaled(x + 8, y + 3, text, 255, 255, 255, alpha, true);
		return bx2;
	end
	local xBadge = tx;
	local colAlgo = {52,152,219};
	local colLive = (opt.dynamicUpdate:Get() and {46,204,113}) or {127,140,141};
	local colPts = {52,73,94};
	xBadge = drawBadge(badge1, xBadge, by, colAlgo, a) + 6;
	xBadge = drawBadge(badge2, xBadge, by, colLive, a) + 6;
	_ = drawBadge(badge3, xBadge, by, colPts, a);
	local effY = by + math.floor(badgesH + (gap * scale));
	local barX1, barY1 = tx, effY;
	local barX2, barY2 = tx + math.floor(effBarW * scale), effY + math.floor(effBarH * scale);
	Render.FilledRect(Vec2(barX1, barY1), Vec2(barX2, barY2), Color(20, 20, 20, math.floor(160 * (a / 255))), 4);
	local ms = NPC.GetMoveSpeed(hero);
	local totalTime = 0;
	local totalG = 0;
	local curPos = heroPos;
	for i = 1, maxPoints do
		local node = route[i];
		if node then
			totalG = totalG + (node.gold or 0);
			local travel = GridNav.GetTravelTime(curPos, node.pos, false, nil, ms);
			local clear = estimateClearSeconds(node);
			totalTime = totalTime + travel + clear;
			curPos = node.pos;
		end
	end
	local eff = ((totalTime > 0) and (totalG / totalTime)) or 0;
	local effMin = opt.minEfficiency:Get();
	local effMax = math.max(effMin + 10, effMin * 2);
	local tEff = 0;
	if (effMax > effMin) then
		tEff = (eff - effMin) / (effMax - effMin);
	end
	if (tEff < 0) then
		tEff = 0;
	end
	if (tEff > 1) then
		tEff = 1;
	end
	local function mix(a0, b0, t0)
		return a0 + ((b0 - a0) * t0);
	end
	local rEff = math.floor(mix(231, 46, tEff));
	local gEff = math.floor(mix(76, 204, tEff));
	local bEff = math.floor(mix(60, 113, tEff));
	local fillW = math.floor(effBarW * tEff);
	Render.FilledRect(Vec2(barX1, barY1), Vec2(barX1 + fillW, barY2), Color(rEff, gEff, bEff, math.floor(220 * (a / 255))), 4);
	local effText = string.format("%.1f g/s (min %.1f)", eff, effMin);
	local etw, eth = TextSizeScaled(effText);
	local etx = barX1 + math.floor((math.floor(effBarW * scale) - etw) * 0.5);
	local ety = barY2 + math.floor(2 * scale);
	DrawTextScaled(etx, ety, effText, 255, 255, 255, a, true);
	local tbarY = ety + math.max(eth, math.floor(effTextH * fontScale)) + math.floor(6 * scale);
	local tbX1, tbY1 = tx, tbarY;
	local tbX2, tbY2 = tx + math.floor(timeBarW * scale), tbarY + math.floor(timeBarH * scale);
	Render.FilledRect(Vec2(tbX1, tbY1), Vec2(tbX2, tbY2), Color(20, 20, 20, math.floor(160 * (a / 255))), 4);
	local scaledTBW = math.floor(timeBarW * scale);
	local stackStart = math.floor((45 / 60) * scaledTBW);
	local stackEnd = math.floor((56 / 60) * scaledTBW);
	Render.FilledRect(Vec2(tbX1 + stackStart, tbY1), Vec2(tbX1 + stackEnd, tbY2), Color(255, 165, 0, math.floor(160 * (a / 255))), 4);
	local targetCursorX = (sec / 60) * scaledTBW;
	timelineCursorX = timelineCursorX + ((targetCursorX - timelineCursorX) * 0.25);
	local cursorHalf = math.max(1, math.floor(1 * scale));
	Render.FilledRect(Vec2((tbX1 + math.floor(timelineCursorX)) - cursorHalf, tbY1 - 2), Vec2(tbX1 + math.floor(timelineCursorX) + cursorHalf, tbY2 + 2), Color(255, 255, 255, math.floor(200 * (a / 255))), 3);
	if opt.dynamicUpdate:Get() then
		local segs = smoothCheckpoints;
		if (currentSegmentIndex <= #segs) then
			for _, p in ipairs(segs[currentSegmentIndex]) do
				local s2d, ok = Render.WorldToScreen(p);
				if ok then
					Renderer.SetDrawColor(255, 165, 0, a);
					Renderer.DrawFilledCircle(s2d.x, s2d.y, 5);
				end
			end
		end
		for si = currentSegmentIndex + 1, #segs do
			for _, p in ipairs(segs[si]) do
				local s2d, ok = Render.WorldToScreen(p);
				local fo = math.floor(a * (opt.futureOpacity:Get() / 100));
				if ok then
					Renderer.SetDrawColor(255, 165, 0, fo);
					Renderer.DrawFilledCircle(s2d.x, s2d.y, 3);
				end
			end
		end
	end
	local col = opt.visualColor:Get();
	local cr, cg, cb = math.floor(col.r), math.floor(col.g), math.floor(col.b);
	local prev2D = nil;
	local prevOk = false;
	local thickness = opt.lineThickness:Get();
	local function drawThickLine(x1, y1, x2, y2, r, g, b, alpha, t)
		if (t <= 1) then
			Renderer.SetDrawColor(r, g, b, alpha);
			Renderer.DrawLine(x1, y1, x2, y2);
			return;
		end
		local dx, dy = x2 - x1, y2 - y1;
		local len = math.max(1, math.sqrt((dx * dx) + (dy * dy)));
		local nx, ny = -dy / len, dx / len;
		local half = math.floor(t / 2);
		for o = -half, half do
			local ox, oy = nx * o, ny * o;
			Renderer.SetDrawColor(r, g, b, alpha);
			Renderer.DrawLine(x1 + ox, y1 + oy, x2 + ox, y2 + oy);
		end
	end
	for i = 1, maxPoints do
		local node = route[i];
		local nodePos = smoothRouteNodes[i] or node.pos;
		local p2d, ok = Render.WorldToScreen(nodePos);
		local t = ((maxPoints > 1) and ((i - 1) / (maxPoints - 1))) or 0;
		local r = math.floor(cr + ((255 - cr) * 0.25 * t));
		local g = math.floor(cg + ((255 - cg) * 0.25 * t));
		local b = math.floor(cb + ((255 - cb) * 0.25 * t));
		local showStack = false;
		local stackCountdown = nil;
		if ((i == 1) and node.isJungle and (sec >= 45) and (sec <= 56)) then
			showStack = true;
			r = 255 - cr;
			g = 255 - cg;
			b = 255 - cb;
			if (sec <= 53) then
				stackCountdown = tostring(53 - sec);
			end
		end
		if (i == 1) then
			local okLine = okHero or ok;
			if okLine then
				drawThickLine(hero2D.x, hero2D.y, p2d.x, p2d.y, r, g, b, a, thickness);
			end
		else
			local okLine = prevOk or ok;
			if (okLine and prev2D) then
				drawThickLine(prev2D.x, prev2D.y, p2d.x, p2d.y, r, g, b, a, thickness);
			end
		end
		if ok then
			local radius = opt.circleSize:Get();
			Renderer.SetDrawColor(math.floor(r * 0.6), math.floor(g * 0.6), math.floor(b * 0.6), a);
			Renderer.DrawFilledCircle(p2d.x, p2d.y, radius + 2);
			Renderer.SetDrawColor(r, g, b, a);
			Renderer.DrawFilledCircle(p2d.x, p2d.y, radius);
			if opt.showPointIndex:Get() then
				local label = tostring(i);
				local lw, lh = Renderer.GetTextSize(panelFont or 1, label);
				Renderer.SetDrawColor(0, 0, 0, a);
				Renderer.DrawText(1, (p2d.x - (lw * 0.5)) + 1, (p2d.y - (lh * 0.5)) + 1, label);
				Renderer.SetDrawColor(255, 255, 255, a);
				Renderer.DrawText(1, p2d.x - (lw * 0.5), p2d.y - (lh * 0.5), label);
			end
			if showStack then
				local text = "STACK!";
				if stackCountdown then
					text = text .. " " .. stackCountdown;
				end
				local sw, sh = Renderer.GetTextSize(panelFont or 1, text);
				Renderer.SetDrawColor(r, g, b, a);
				Renderer.DrawText(1, p2d.x - (sw * 0.5), ((p2d.y - radius) - sh) - 2, text);
			end
			if opt.showGold:Get() then
				local value = tostring(math.floor(node.gold));
				local vw, vh = Renderer.GetTextSize(panelFont or 1, value);
				Renderer.SetDrawColor(0, 0, 0, a);
				Renderer.DrawText(1, (p2d.x - (vw * 0.5)) + 1, p2d.y + radius + 2 + 1, value);
				Renderer.SetDrawColor(255, 215, 0, a);
				Renderer.DrawText(1, p2d.x - (vw * 0.5), p2d.y + radius + 2, value);
			end
		end
		prev2D, prevOk = p2d, ok;
	end
end;
return {OnUpdate=FarmPattern.OnUpdate,OnDraw=FarmPattern.OnDraw};