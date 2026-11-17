--- control.lua
--  this file is loaded prior to any scripts/functions and reloaded each time a game is saved/loaded so changes here can be tested without relaunching the game; available objects: script, remote, commands

local globals = require("scripts/globals")
--local exclusion_ranges = {}     -- beacon prototype name -> range for affected beacons
--local distribution_ranges = {}  -- beacon prototype name -> range for affected crafting machines
--local search_ranges = {}        -- beacon prototype name -> maximum range that other beacons could be interacted with
--local types = {}                -- beacon prototype name -> "strict", "hub", or "conflux" for beacons with distinct behaviors
--local repeating_beacons = {}    -- beacon prototype name -> list of beacons which won't be disabled
--local offline_beacons = {}      -- beacon unit number -> attached warning sprite, entity reference (for disabled beacons)
local update_rate               -- integer; if above zero, how many seconds elapse between updating all beacons (beacons are only updated via triggered events by default)
local persistent_alerts         -- boolean; whether or not alerts are refreshed for disabled beacons
local active_scripts            -- boolean; whether the mod's scripts are enabled

--- Mod Initialization - called on first startup after the mod is installed; available objects: global, game, rendering, settings
--- Migrations are handled between on_init() and on_load() and each migration file is executed once if it hasn't yet been executed for that game's save file
--- Mod Load - called on subsequent startups
--- Mod Configuration - called next if the game version or any mod version has changed, any mod was added or removed, a startup setting was changed, any prototypes were added or removed, or if a migration was applied

script.on_init( function()
  storage = { exclusion_ranges = {}, distribution_ranges = {}, search_ranges = {}, strict_beacons = {}, repeating_beacons = {}, offline_beacons = {} } -- TODO: refactor/migrate "strict_beacons" as "types" instead
  initialize()
  startup()
  check_global_list()
end )
script.on_load( function()
  startup()
end )
script.on_configuration_changed( function()
  initialize()
  startup()
  check_global_list() -- TODO: May not always be necessary?
end )

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- scripts and startup functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- Saves module/beacon prototype & entity data
function initialize()
  local beacon_prototypes = prototypes.get_entity_filtered({{filter = "type", type = "beacon"}})
  storage = globals.setup(beacon_prototypes)
  verify_technology_unlocks()
end

--- Loads stored data and starts scripts
function startup()
  --exclusion_ranges = storage.exclusion_ranges
  --distribution_ranges = storage.distribution_ranges
  --search_ranges = storage.search_ranges
  --types = storage.strict_beacons
  --repeating_beacons = storage.repeating_beacons
  --offline_beacons = storage.offline_beacons
  update_rate = settings.global["ab-update-rate"].value
  persistent_alerts = settings.global["ab-persistent-alerts"].value
  active_scripts = not settings.startup["ab-disable-exclusion-areas"].value -- TODO: invert setting so that true = active and false = inactive?
  if active_scripts then enable_scripts(script.active_mods) end
end

--- Enables beacon recipes which should be enabled but aren't due to technology changes
function verify_technology_unlocks()
  local techs = {"effect-transmission", "ab-novel-effect-transmission", "ab-medium-effect-transmission", "ab-long-effect-transmission", "ab-focused-beacon", "ab-node-beacon", "ab-conflux-beacon", "ab-hub-beacon", "ab-isolation-beacon", "se-compact-beacon", "se-wide-beacon", "se-compact-beacon-2", "se-wide-beacon-2", "nullius-broadcasting-2"}
  for _,force in pairs(game.forces) do
    for _,tech in pairs(techs) do
      if force.technologies[tech] and force.technologies[tech].researched then
        for _,effect in pairs(force.technologies[tech].prototype.effects) do
          if effect.type == "unlock-recipe" and force.recipes[effect.recipe] and not force.recipes[effect.recipe].enabled then
            force.recipes[effect.recipe].enabled = true
          end
        end
      end
    end
  end
end
-- TODO: The game remembers settings even after uninstalling a mod; can this be used to make it remember which technologies have been researched already, if users switch between different options?

-- Enables all scripting to make exclusion areas function - can be disabled by other mods via a hidden startup setting if necessary
function enable_scripts(mods)
  script.on_event( defines.events.on_built_entity,                function(event) check_nearby(event.entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_robot_built_entity,          function(event) check_nearby(event.entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.script_raised_built,            function(event) check_nearby(event.entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.script_raised_revive,           function(event) check_nearby(event.entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_space_platform_built_entity, function(event) check_nearby(event.entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_player_mined_entity,         function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_robot_mined_entity,          function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_entity_died,                 function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.script_raised_destroy,          function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_space_platform_mined_entity, function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  --script.on_event( defines.events.on_entity_cloned,             function(event) check_nearby(event.destination, "added") end, {{filter = "type", type = "beacon"}} ) -- TODO: Test this. What clones entities?
  --script.on_event( defines.events.script_raised_teleported,     function(event) check_global_list() end, {{filter = "type", type = "beacon"}} ) --TODO: Find a reliable way to trigger this event so a check_moved() function can be tested instead of just checking all beacons
  script.on_event( defines.events.on_runtime_mod_setting_changed, function(event) on_settings_changed(event) end )
  if update_rate > 0 then register_periodic_updates(update_rate * 60) end
  if persistent_alerts == true then register_alert_refreshing() end
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), function(event) check_remote(event["moved_entity"], "added", 1) end) -- rechecks nearby beacons when a beacon is moved; a maximum moved distance of 1 is assumed
  end
  if mods["pycoalprocessing"] then
    remote.remove_interface("cryogenic-distillation")
    remote.add_interface("cryogenic-distillation", {
      am_fm_beacon_settings_changed = function(new_beacon) check_remote(new_beacon, "added", 0) end, -- rechecks nearby beacons when an AM:FM beacon is updated
      am_fm_beacon_destroyed = function(receivers, surface) end -- unused
    })
  end
  if mods["informatron"] then
    remote.remove_interface("alternative-beacons")
    remote.add_interface("alternative-beacons", {
      informatron_menu = function(data) return informatron_beacon_menu(data.player_index) end,
      informatron_page_content = function(data) return informatron_beacon_page_content(data.page_name, data.player_index, data.element) end
    })
  end
end

--- Handles changes made to runtime settings
function on_settings_changed(event)
  if event.setting == "ab-update-rate" then
    local previous_update_rate = update_rate
    update_rate = settings.global["ab-update-rate"].value
    if previous_update_rate ~= update_rate then
      if previous_update_rate > 0 then unregister_periodic_updates(previous_update_rate * 60) end
      if update_rate > 0 then register_periodic_updates(update_rate * 60) end
    end
  end
  if event.setting == "ab-persistent-alerts" then -- TODO: Allow this to be adjusted per player in multiplayer while still allowing the admin to make it available or not?
    local previous_setting = persistent_alerts
    persistent_alerts = settings.global["ab-persistent-alerts"].value
    if previous_setting == false and persistent_alerts == true then
      register_alert_refreshing()
    elseif previous_setting == true and persistent_alerts == false then
      unregister_alert_refreshing()
    end
  end
end

function register_periodic_updates(tick_rate)
  script.on_nth_tick(tick_rate, function(event) check_global_list() end)
end

function unregister_periodic_updates(tick_rate)
  script.on_nth_tick(tick_rate, nil)
end

function register_alert_refreshing()
  script.on_nth_tick(601, function(event) refresh_beacon_alerts() end)
end

function unregister_alert_refreshing()
  script.on_nth_tick(601, nil)
end

function informatron_beacon_menu(player_index) return {} end

function informatron_beacon_page_content(page_name, player_index, element)
  if page_name == "alternative-beacons" then
    element.add{type="label", name="text_1", caption={"alternative-beacons.page_alternative-beacons_text_1"}}
    local image_container = element.add{type = "flow"}
    image_container.style.horizontal_align = "center"
    image_container.style.horizontally_stretchable = true
    image_container.add{type = "sprite", sprite = "ab_informatron_1"}
    element.add{type="label", name="text_2", caption={"alternative-beacons.page_alternative-beacons_text_2"}}
  end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- runtime functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- checks all beacons
function check_global_list()
  -- TODO: Spread actions over many ticks instead of just letting it go as quickly as possible (or just remove the setting which triggers this since everything should be handled in events now?)
  if active_scripts then
    for _, surface in pairs(game.surfaces) do
      if surface ~= nil then
        local beacons = surface.find_entities_filtered({type = "beacon"})
        for _, beacon in pairs(beacons) do
          check_self(beacon, -1, nil)
        end
      end
    end
  end
end

-- returns the distance between two bounding boxes
function get_distance(box_a, box_b)
  local x1 = box_a.right_bottom.x - box_b.left_top.x
  local x2 = box_b.right_bottom.x - box_a.left_top.x
  local y1 = box_a.right_bottom.y - box_b.left_top.y
  local y2 = box_b.right_bottom.y - box_a.left_top.y
  local dx = math.min(math.abs(x1), math.abs(x2))
  local dy = math.min(math.abs(y1), math.abs(y2))
  if x1 > 0 and x2 > 0 then dx = 0 end
  if y1 > 0 and y2 > 0 then dy = 0 end
  do return math.max(dx, dy) end
end

-- enables or disables beacons within the exclusion field (or other effective range) of an added/removed beacon entity
--   @behavior: either "added" or "removed"
function check_nearby(entity, behavior)
  if behavior == "removed" then remove_beacon_alert(entity) end
  local exclusion_mode = "normal"
  local exclusion_range = storage.exclusion_ranges[entity.name]
  local search_range = storage.search_ranges[entity.name]
  if storage.strict_beacons[entity.name].strict ~= nil then exclusion_mode = "strict" end
  local search_area = {
    {entity.selection_box.left_top.x - search_range, entity.selection_box.left_top.y - search_range},
    {entity.selection_box.right_bottom.x + search_range, entity.selection_box.right_bottom.y + search_range}
  }
  -- find surrounding beacons and setup general info needed to determine correct behaviors
  local hubCount = 0
  local hubIDs = {}
  local nearby_entities = entity.surface.find_entities_filtered({area = search_area, type = "beacon"})
  if storage.strict_beacons[entity.name].hub == nil and entity.name ~= "ll-oxygen-diffuser" then
    for _, nearby_entity in pairs(nearby_entities) do
      if storage.strict_beacons[nearby_entity.name].hub then
        if get_distance(entity.selection_box, nearby_entity.selection_box) < storage.exclusion_ranges[nearby_entity.name] then
          hubCount = hubCount + 1
          table.insert(hubIDs, nearby_entity.unit_number)
        end
      end
    end
  end
  -- adjust nearby beacons as needed
  for _, nearby_entity in pairs(nearby_entities) do
    if nearby_entity.unit_number ~= entity.unit_number and nearby_entity.name ~= "ll-oxygen-diffuser" then
      local nearby_distance = get_distance(entity.selection_box, nearby_entity.selection_box)
      local disabling_range = exclusion_range
      if hubCount > 0 then
        if check_influence(nearby_entity, hubIDs) then exclusion_mode = "super" end -- beacons within a single hub's area affect each other differently
      end
      if exclusion_mode == "strict" then disabling_range = math.max(disabling_range, exclusion_range + storage.distribution_ranges[nearby_entity.name]) end
      if exclusion_mode == "super" then disabling_range = math.max(disabling_range, math.max(exclusion_range, storage.distribution_ranges[entity.name]) + math.max(storage.exclusion_ranges[nearby_entity.name], storage.distribution_ranges[nearby_entity.name])) end
      if storage.strict_beacons[nearby_entity.name].conflux then
        local nearby_distribution_width = 2*storage.distribution_ranges[nearby_entity.name] + nearby_entity.selection_box.right_bottom.x - nearby_entity.selection_box.left_top.x
        local distribution_width = 2*storage.distribution_ranges[entity.name] + entity.selection_box.right_bottom.x - entity.selection_box.left_top.x
        if distribution_width >= nearby_distribution_width then disabling_range = math.max(disabling_range, storage.distribution_ranges[entity.name] + storage.distribution_ranges[nearby_entity.name]) end -- semi-strict
      end
      if nearby_distance < disabling_range then
        local wasEnabled = nearby_entity.active
        local removed_id = -1
        if behavior ~= "added" then removed_id = entity.unit_number end
        if use_repeating_behavior(entity, nearby_entity) == false then -- some beacons don't affect each other
          if behavior == "added" then
            nearby_entity.disabled_by_script = true
          else
            nearby_entity.disabled_by_script = false
          end
        end
        check_self(nearby_entity, removed_id, wasEnabled)
      end
    end
  end
  if behavior == "added" then
    local wasEnabled = entity.active
    check_self(entity, -1, wasEnabled)
  end
end

-- enables or disables a beacon entity based on exclusion fields and behaviors of surrounding beacons
--   @removed_id: the unit_number of a removed beacon or -1 if no beacon was removed
--   @wasEnabled: whether the beacon was active or not prior to the current checking process
function check_self(entity, removed_id, wasEnabled)
  local isEnabled = true
  local search_range = storage.search_ranges[entity.name]
  local search_area = {
    {entity.selection_box.left_top.x - search_range, entity.selection_box.left_top.y - search_range},
    {entity.selection_box.right_bottom.x + search_range, entity.selection_box.right_bottom.y + search_range}
  }
  -- find surrounding beacons and setup general info needed to determine correct behaviors
  local hubCount = 0
  local hubID = -1
  local hubIDs = {}
  local nearby_entities = entity.surface.find_entities_filtered({area = search_area, type = "beacon"})
  if storage.strict_beacons[entity.name].hub == nil and entity.name ~= "ll-oxygen-diffuser" then
    for _, nearby_entity in pairs(nearby_entities) do
      if storage.strict_beacons[nearby_entity.name].hub and nearby_entity.unit_number ~= removed_id then
        if get_distance(entity.selection_box, nearby_entity.selection_box) < storage.exclusion_ranges[nearby_entity.name] then
          hubCount = hubCount + 1
          if hubCount == 1 then hubID = nearby_entity.unit_number end
          table.insert(hubIDs, nearby_entity.unit_number)
          isEnabled = false
        end
      end
    end
    if hubCount > 1 then hubID = -1 end
    if hubCount == 1 then isEnabled = true end
  end
  -- adjust beacon based on surrounding beacons
  for _, nearby_entity in pairs(nearby_entities) do
    if (nearby_entity.unit_number ~= entity.unit_number and nearby_entity.unit_number ~= removed_id and nearby_entity.name ~= "ll-oxygen-diffuser") then
      local exclusion_mode = "normal"
      local nearby_distance = get_distance(entity.selection_box, nearby_entity.selection_box)
      local disabling_range = storage.exclusion_ranges[nearby_entity.name]
      if storage.strict_beacons[nearby_entity.name].strict ~= nil then exclusion_mode = "strict" end
      if hubCount > 0 and storage.strict_beacons[nearby_entity.name].hub == nil then
        if check_influence(nearby_entity, hubIDs) then exclusion_mode = "super" end -- beacons within a single hub's area affect each other differently
      end
      if exclusion_mode == "strict" then disabling_range = math.max(disabling_range, storage.exclusion_ranges[nearby_entity.name] + storage.distribution_ranges[entity.name]) end
      if exclusion_mode == "super" then disabling_range = math.max(disabling_range, math.max(storage.exclusion_ranges[nearby_entity.name], storage.distribution_ranges[nearby_entity.name]) + math.max(storage.exclusion_ranges[entity.name], storage.distribution_ranges[entity.name])) end
      if storage.strict_beacons[entity.name].conflux then
        local nearby_distribution_width = 2*storage.distribution_ranges[nearby_entity.name] + nearby_entity.selection_box.right_bottom.x - nearby_entity.selection_box.left_top.x
        local distribution_width = 2*storage.distribution_ranges[entity.name] + entity.selection_box.right_bottom.x - entity.selection_box.left_top.x
        if nearby_distribution_width >= distribution_width then disabling_range = math.max(disabling_range, storage.distribution_ranges[entity.name] + storage.distribution_ranges[nearby_entity.name]) end -- semi-strict
      end
      if storage.strict_beacons[nearby_entity.name].hub == nil then
        if nearby_distance < disabling_range then
          if exclusion_mode == "super" or use_repeating_behavior(nearby_entity, entity) == false then isEnabled = false end -- some beacons don't affect each other
        end
      elseif (storage.strict_beacons[nearby_entity.name].hub and storage.strict_beacons[entity.name].conflux) then
        disabling_range = storage.distribution_ranges[entity.name] + storage.distribution_ranges[nearby_entity.name]
        if nearby_distance < disabling_range then isEnabled = false end
      elseif (storage.strict_beacons[nearby_entity.name].hub and storage.strict_beacons[entity.name].hub) then
        disabling_range = storage.exclusion_ranges[nearby_entity.name]
        if nearby_distance < disabling_range then isEnabled = false end
      end
    end
  end
  if (isEnabled == false and (entity.name == "ei_copper-beacon" or entity.name == "ei_iron-beacon")) then isEnabled = true end
  if (entity.name == "base-power-crystal-1" or entity.name == "base-power-crystal-2" or entity.name == "base-power-crystal-3" or entity.name == "base-power-crystal-negative-1" or entity.name == "base-power-crystal-negative-2") then isEnabled = true end
  entity.disabled_by_script = not isEnabled
  handle_change(entity, wasEnabled, isEnabled)
end

-- handles warning sprites, flying text, and alerts
function handle_change(entity, wasEnabled, isEnabled)
  if (wasEnabled == true and isEnabled == false) then -- beacon deactivated
    -- TODO: Add a way for other mods to choose whether the activation/deactivation text gets displayed (such as modular beacon power)
    if storage.offline_beacons[entity.unit_number] == nil then
      add_beacon_warning(entity)
      for _, player in pairs(entity.force.players) do
        player.create_local_flying_text{text={"description.ab_beacon_deactivated"}, surface=entity.surface, position=entity.position, color={1,1,1,1}, time_to_live=200, speed=3}
        add_beacon_alert(entity, player)
      end
    end
  elseif (wasEnabled == false and isEnabled == true) then -- beacon activated
    for _, player in pairs(entity.force.players) do
      player.create_local_flying_text{text={"description.ab_beacon_activated"}, surface=entity.surface, position=entity.position, color={1,1,1,1}, time_to_live=200, speed=3}
    end
    remove_beacon_warning(entity)
  elseif (isEnabled == false and storage.offline_beacons[entity.unit_number] == nil) then -- adds icons to old deactivated beacons (may not be necessary)
    add_beacon_warning(entity)
  elseif (isEnabled == true and storage.offline_beacons[entity.unit_number] ~= nil) then -- removes icons in other cases (may not be necessary)
    remove_beacon_warning(entity)
  end
end

-- adds a warning sprite to a disabled beacon
function add_beacon_warning(entity)
  storage.offline_beacons[entity.unit_number] = {
    rendering.draw_sprite{
      sprite = "ab_beacon_offline",
      target = entity,
      surface = entity.surface,
      x_scale = 0.5,
      y_scale = 0.5
    },
    entity
  }
end

-- removes a warning sprite from a beacon
function remove_beacon_warning(entity)
  if storage.offline_beacons[entity.unit_number] ~= nil then
    remove_beacon_alert(storage.offline_beacons[entity.unit_number][2])
    rendering.get_object_by_id(storage.offline_beacons[entity.unit_number][1].id).destroy()
    storage.offline_beacons[entity.unit_number] = nil
  end
end

-- adds a flashing alert to the bottom right of the GUI for a disabled beacon and player 
function add_beacon_alert(entity, player)
  if entity.valid then
    player.add_custom_alert(entity,
    {type="virtual", name="ab_beacon_offline"},
    {"description.ab_beacon_offline_alert", "[img=entity/" .. entity.name .. "]"},
    true)
    entity.custom_status = {diode=defines.entity_status_diode.red, label={"description.ab_disabled_status"}}
  end
  --if persistent_alerts == true and #offline_beacons > 0 then register_alert_refreshing() end -- TODO: Can persistent alerts be modified to have zero performance impact whenever there are no offline beacons?
end

-- removes flashing alerts for the given beacon (all players)
function remove_beacon_alert(beacon_entity)
  if beacon_entity.valid then
    for _, player in pairs(beacon_entity.force.players) do
      player.remove_alert({entity=beacon_entity, type=defines.alert_type.custom, position=beacon_entity.position, surface=beacon_entity.surface, message={"description.ab_beacon_offline_alert"}, icon={type="virtual", name="ab_beacon_offline"}})
    end
    beacon_entity.custom_status = nil
  end
  --if persistent_alerts == true and #offline_beacons == 0 then unregister_alert_refreshing() end
end
-- TODO: Hovering over the alert makes warning icons appear on beacons at a smaller scale than usual

-- returns true if the given beacon (entity) is within the exclusion field of a specific hub (hubID)
--   used to determine if the beacon's overlapping area should apply to another beacon near the specific hub (it only applies for beacons within the same hub's exclusion area)
function check_influence(entity, hubIDs)
  local isInfluenced = false
  if storage.exclusion_ranges["ab-hub-beacon"] ~= nil then
    local exclusion_range = storage.exclusion_ranges["ab-hub-beacon"]
    local exclusion_area = {
      {entity.selection_box.left_top.x - exclusion_range, entity.selection_box.left_top.y - exclusion_range},
      {entity.selection_box.right_bottom.x + exclusion_range, entity.selection_box.right_bottom.y + exclusion_range}
    }
    local nearby_beacons = entity.surface.find_entities_filtered({area = exclusion_area, type = "beacon"})
    for _, beacon in pairs(nearby_beacons) do
      if storage.strict_beacons[beacon.name].hub then
        for _, hub_number in pairs(hubIDs) do
          if beacon.unit_number == hub_number then isInfluenced = true end
        end
      end
    end
  end
  do return isInfluenced end
end

-- returns true if the the beacons shouldn't disable each other
function use_repeating_behavior(entity1, entity2)
  local result = false
  if entity1.unit_number ~= entity2.unit_number then
    if storage.repeating_beacons[entity1.name] and storage.repeating_beacons[entity1.name][entity2.name] then result = true end
  end
  do return result end
end

-- checks all beacons within range of the given beacon
function check_remote(entity, behavior, extra_search_range)
  if entity.type == "beacon" then
    local search_range = storage.search_ranges[entity.name] + extra_search_range
    local search_area = {
      {entity.selection_box.left_top.x - search_range, entity.selection_box.left_top.y - search_range},
      {entity.selection_box.right_bottom.x + search_range, entity.selection_box.right_bottom.y + search_range}
    }
    local nearby_beacons = entity.surface.find_entities_filtered({area = search_area, type = "beacon"})
    for _, beacon in pairs(nearby_beacons) do
      local wasEnabled = beacon.active
      if behavior == "added" then
        check_self(beacon, -1, wasEnabled)
      elseif (beacon.unit_number ~= entity.unit_number) then
        check_self(beacon, entity.unit_number, wasEnabled)
      end
    end
  end
end

-- re-issues alerts for beacons which were disabled by this mod (they naturally end after 10 seconds)
function refresh_beacon_alerts()
  for i, offline_beacon in pairs(storage.offline_beacons) do
    if offline_beacon ~= nil then
      local beacon = offline_beacon[2]
      if beacon and beacon.valid then
        for _, player in pairs(beacon.force.players) do
          add_beacon_alert(beacon, player)
        end
      end
    end
  end
end

--- Returns the "base" part of a beacon name to the left of the separator for the modular-beacon-power mod
--- @param name string
--- @return string
function base_name(name)
  local t = {}
  for s in string.gmatch(name, "([^__MBP]+)") do
    table.insert(t,s)
  end
  return t[1]
end
