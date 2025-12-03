local script = {}

-- UI
local tab = Menu.Create("Scripts", "Auto Dispel", "Auto Dispel on Cast", "Utility")
local main = tab:Create("Main")
local items_group = tab:Create("Items")
local ui = {}
ui.enabled = main:Switch("Enabled", true, "\u{f0e7}")
ui.debug   = main:Switch("Debug", false, "\u{f188}")
ui.delay   = main:Slider("Recast Delay (ms)", 50, 300, 100, function(v) return tostring(v) .. "ms" end)
ui.items   = items_group:MultiSelect(
  "Dispel Items",
  {
    {"item_black_king_bar", "panorama/images/items/black_king_bar_png.vtex_c", true},
    {"item_manta",          "panorama/images/items/manta_png.vtex_c",          true},
    {"item_lotus_orb",      "panorama/images/items/lotus_orb_png.vtex_c",      true},
    {"item_guardian_greaves","panorama/images/items/guardian_greaves_png.vtex_c", false},
    {"item_disperser",      "panorama/images/items/disperser_png.vtex_c",      false},
    {"item_satanic",        "panorama/images/items/satanic_png.vtex_c",        false}
  },
  false
)

local function dbg(msg)
  if ui.debug:Get() then
    print("[AutoDispel] " .. msg)
  end
end

-- Internal state for delayed re-issue
local pending_orders = {}

local function schedule_reissue(order_snapshot, delay_ms)
  table.insert(pending_orders, {
    at = os.clock() * 1000 + (delay_ms or 0),
    data = order_snapshot
  })
end

local function copy_order_data(data)
  -- Only copy the fields we actually use for reissuing
  return {
    order       = data.order,
    target      = data.target,
    position    = data.position or Vector(0, 0, 0),
    ability     = data.ability,
    orderIssuer = data.orderIssuer,
    npc         = data.npc,
    queue       = data.queue,
    showEffects = data.showEffects
  }
end

local function reissue_order(o)
  local player = Players.GetLocal()
  local hero = o.npc or Heroes.GetLocal()
  if not hero or not Entity.IsAlive(hero) then
    return
  end

  -- Fallbacks for optional flags
  local queue = (o.queue == true)
  local show = (o.showEffects ~= false)
  local issuer = o.orderIssuer or Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY
  local pos = o.position or Vector(0, 0, 0)

  -- Some orders require ability handle, keep as is from snapshot
  Player.PrepareUnitOrders(
    player,
    o.order,
    o.target,
    pos,
    o.ability,
    issuer,
    hero,
    queue,
    show
  )

  dbg("Reissued order " .. tostring(o.order))
end

local function is_under_dispellable_cc(hero)
  if NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_STUNNED) then return false end -- requested: all except stun
  if NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_MUTED)   then return false end -- items cannot be used under mute

  return (
    NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_SILENCED) or
    NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_ROOTED)   or
    NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_HEXED)
  )
end

local function get_selected_items()
  local list = {}
  for _, name in ipairs(ui.items:ListEnabled() or {}) do
    table.insert(list, name)
  end
  return list
end

local function is_bkb_active(hero)
  return NPC.HasModifier(hero, "modifier_black_king_bar_immune")
end

local function try_cast_item(hero, item_name)
  local item = NPC.GetItem(hero, item_name, true)
  if not item then return false end
  if not Ability.IsCastable(item, NPC.GetMana(hero)) then return false end

  if item_name == "item_black_king_bar" then
    if is_bkb_active(hero) then return false end
    Ability.CastNoTarget(item, false)
    return true
  elseif item_name == "item_manta" then
    Ability.CastNoTarget(item, false)
    return true
  elseif item_name == "item_lotus_orb" then
    Ability.CastTarget(item, hero, false)
    return true
  elseif item_name == "item_guardian_greaves" then
    Ability.CastNoTarget(item, false)
    return true
  elseif item_name == "item_disperser" then
    Ability.CastTarget(item, hero, false)
    return true
  elseif item_name == "item_satanic" then
    Ability.CastNoTarget(item, false)
    return true
  else
    return false
  end
end

local function cast_first_available_dispel(hero)
  -- Priority is defined by the current order in MultiSelect (drag to reorder)
  local ordered = ui.items:ListEnabled() or {}

  -- Fallback to a sensible default if nothing selected
  if #ordered == 0 then
    ordered = { "item_black_king_bar", "item_manta", "item_guardian_greaves", "item_disperser", "item_lotus_orb", "item_satanic" }
  end

  for _, name in ipairs(ordered) do
    if try_cast_item(hero, name) then
      dbg("Used dispel item: " .. name)
      return true
    end
  end

  return false
end

-- Hook: intercept orders
script.OnPrepareUnitOrders = function(data)
  if not ui.enabled:Get() then return true end

  local hero = data.npc or Heroes.GetLocal()
  if not hero or not Entity.IsNPC(hero) then return true end
  if hero ~= Heroes.GetLocal() then return true end

  -- Only react to cast orders
  local cast_orders = {
    [Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET] = true,
    [Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION]  = true,
    [Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET]    = true,
    [Enum.UnitOrder.DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION] = true
  }
  if not cast_orders[data.order] then return true end

  -- Avoid recursion if the ability being cast is already one of dispel items
  if data.ability and Entity.IsAbility(data.ability) then
    local aname = Ability.GetName(data.ability)
    if aname == "item_black_king_bar" or aname == "item_manta" or aname == "item_lotus_orb" or aname == "item_guardian_greaves" or aname == "item_disperser" or aname == "item_satanic" then
      return true
    end
  end

  if not is_under_dispellable_cc(hero) then
    return true
  end

  -- Try to use a dispel item. If successful, block the current order and re-issue after delay
  if cast_first_available_dispel(hero) then
    local snapshot = copy_order_data(data)
    schedule_reissue(snapshot, ui.delay:Get())
    dbg("Blocked and scheduled re-issue for order " .. tostring(data.order))
    return false
  end

  return true
end

-- Process delayed re-issues
script.OnUpdate = function()
  if #pending_orders == 0 then return end

  local now = os.clock() * 1000
  local i = 1
  while i <= #pending_orders do
    if now >= pending_orders[i].at then
      local payload = pending_orders[i].data
      table.remove(pending_orders, i)
      pcall(reissue_order, payload)
    else
      i = i + 1
    end
  end
end

return script; 