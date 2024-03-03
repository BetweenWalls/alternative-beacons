--- control.lua
--  this file is loaded prior to any scripts/functions and reloaded each time a game is saved/loaded so changes here can be tested without relaunching the game; available objects: script, remote, commands

local exclusion_ranges = {}     -- beacon prototype name -> range for affected beacons
local distribution_ranges = {}  -- beacon prototype name -> range for affected crafting machines
local search_ranges = {}        -- beacon prototype name -> maximum range that other beacons could be interacted with
local strict_beacons = {}       -- beacon prototype names for those with "strict" exclusion ranges
local repeating_beacons = {}    -- beacon prototype name -> list of beacons which won't be disabled
local offline_beacons = {}      -- beacon unit number -> its attached warning sprite
local update_rate = 0           -- if above zero, how many seconds elapse between updating all beacons (beacons are only updated via triggered events by default)

--- Mod Initialization - called on first startup after the mod is installed; available objects: global, game, rendering, settings
script.on_init(
  function()
    populate_beacon_data()
  end
)

--- Migrations are handled between on_init() and on_load()

--- Mod Load - called on subsequent startups
script.on_load(
  function()
    -- global is a global table that preserves data between saves which can store: nil, strings, numbers, booleans, tables, references to Factorio's LuaObjects; can read from global in on_load(), but not write to it
    exclusion_ranges = global.exclusion_ranges
    distribution_ranges = global.distribution_ranges
    search_ranges = global.search_ranges
    strict_beacons = global.strict_beacons
    repeating_beacons = global.repeating_beacons
    offline_beacons = global.offline_beacons
    update_rate = settings.global["ab-update-rate"].value
  end
)

-- Mod Configuration - called next if the game version or any mod version has changed, any mod was added or removed, a startup setting was changed, any prototypes were added or removed, or if a migration was applied
script.on_configuration_changed(
  function()
    populate_beacon_data()
  end
)


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- scripts and startup functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Enables all scripting to make exclusion areas function - can be disabled by other mods via a hidden startup setting if necessary
function enable_scripts()
  script.on_event( defines.events.on_built_entity,          function(event) check_nearby(event.created_entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_robot_built_entity,    function(event) check_nearby(event.created_entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.script_raised_built,      function(event) check_nearby(event.entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.script_raised_revive,     function(event) check_nearby(event.entity, "added") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_player_mined_entity,   function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_robot_mined_entity,    function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.on_entity_died,           function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  script.on_event( defines.events.script_raised_destroy,    function(event) check_nearby(event.entity, "removed") end, {{filter = "type", type = "beacon"}} )
  --script.on_event( defines.events.on_entity_cloned,         function(event) check_nearby(event.destination, "added") end, {{filter = "type", type = "beacon"}} ) -- TODO: Test this. What clones entities?
  script.on_event( defines.events.script_raised_teleported, function(event) check_global_list() end, {{filter = "type", type = "beacon"}} ) --TODO: Find a reliable way to trigger this event so a check_moved() function can be tested instead of just checking all beacons
  script.on_event(
    defines.events.on_runtime_mod_setting_changed,
    function(event)
      if event.setting == "ab-update-rate" then
        local previous_update_rate = update_rate
        update_rate = settings.global["ab-update-rate"].value
        if previous_update_rate ~= update_rate then
          unregister_periodic_updates()
          if update_rate > 0 then register_periodic_updates(update_rate * 60) end
        end
      end
    end
  )
  if update_rate > 0 then register(update_rate * 60) end
end

function register_periodic_updates(tick_rate)
  script.on_nth_tick(tick_rate, function(event) check_global_list() end)
end

function unregister_periodic_updates()
  script.on_nth_tick(nil)
end

--- updates global data
--  creates and updates exclusion ranges for all beacons - beacons from other mods will use their distribution range as their exclusion range
function populate_beacon_data()
  global = { exclusion_ranges = {}, distribution_ranges = {}, strict_beacons = {}, offline_beacons = {},  repeating_beacons = {} }
  local updated_distribution_ranges = {}
  local updated_strict_beacons = {}
  local updated_offline_beacons = {}
  local updated_exclusion_ranges = {}

  local custom_exclusion_ranges = { -- these beacons are given custom exclusion ranges: "strict" ranges disable beacons whose distribution areas overlap them, "solo" means the smallest range which is large enough to prevent synergy with other beacons
    ["ab-focused-beacon"] = {value = 3},
    ["ab-conflux-beacon"] = {value = 12},
    ["ab-hub-beacon"] = {value = 34},
    ["ab-isolation-beacon"] = {value = 68},
    ["se-compact-beacon"] = {value = "solo", mode = "strict"},
    ["se-compact-beacon-2"] = {value = "solo", mode = "strict"},
    ["se-wide-beacon"] = {value = "solo", mode = "strict"},
    ["se-wide-beacon-2"] = {value = "solo", mode = "strict"},
    ["ei_copper-beacon"] = {value = "solo", mode = "strict"},
    ["ei_iron-beacon"] = {value = "solo", mode = "strict"},
    ["el_ki_beacon_entity"] = {value = "solo", mode = "strict"},
    ["fi_ki_beacon_entity"] = {value = "solo", mode = "strict"},
    ["fu_ki_beacon_entity"] = {value = "solo", mode = "strict"},
    ["productivity-beacon"] = {value = 6},
    ["productivity-beacon-1"] = {value = 5},
    ["productivity-beacon-2"] = {value = 6},
    ["productivity-beacon-3"] = {value = 7},
    ["speed-beacon-2"] = {value = 8},
    ["speed-beacon-3"] = {value = 11},
    ["beacon-3"] = {value = 11},
    -- pyanodons AM-FM entries are added below
  }
  local updated_repeating_beacons = { -- these beacons don't disable any of the beacons in the list associated with them
    ["beacon"] = {"beacon", "ab-standard-beacon", "kr-singularity-beacon", "beacon-mk1", "beacon-mk2", "beacon-mk3", "5d-beacon-02", "5d-beacon-03", "5d-beacon-04"}, -- additional entries added below
    ["ab-standard-beacon"] = {"beacon", "ab-standard-beacon", "kr-singularity-beacon", "beacon-mk1", "beacon-mk2", "beacon-mk3", "5d-beacon-02", "5d-beacon-03", "5d-beacon-04"}, -- additional entries added below
    ["kr-singularity-beacon"] = {"kr-singularity-beacon"},
    ["ei_copper-beacon"] = {"ei_copper-beacon","ei_iron-beacon"}, -- TODO: only if beacon overloading is enabled
    ["ei_iron-beacon"] = {"ei_copper-beacon","ei_iron-beacon"},
    ["beacon-mk1"] = {"beacon"},
    ["beacon-mk2"] = {"beacon"},
    ["beacon-mk3"] = {"beacon"},
    ["el_ki_beacon_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fi_ki_beacon_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fu_ki_beacon_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["el_ki_core_slave_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fi_ki_core_slave_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fu_ki_core_slave_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["5d-beacon-02"] = {"beacon"},
    ["5d-beacon-03"] = {"beacon"},
    ["5d-beacon-04"] = {"beacon"},
    -- nullius small/large entries are added below
    -- pyanodons AM-FM entries are added below
    -- power crystal entries are added below
  }

  local max_moduled_building_size = 9 -- by default, rocket silo (9x9) is the largest building which can use modules
  local beacon_prototypes = game.get_filtered_entity_prototypes({{filter = "type", type = "beacon"}})
  local mods = script.active_mods
  if mods["Beacon2"] then
    for _, beacon in pairs(beacon_prototypes) do                              -- TODO: can the beacon stats be checked directly instead of iterating through all beacons?
      if beacon.name == "beacon-2" and beacon.supply_area_distance < 3.5 then -- only allow repeating if it's a specific version (multiple mods use the same name)
        updated_repeating_beacons["beacon-2"] = {"beacon"}
        table.insert(updated_repeating_beacons["beacon"], "beacon-2")
      end
    end
  end
  if mods["space-exploration"] and settings.startup["ab-override-vanilla-beacons"].value == false then custom_exclusion_ranges["beacon"] = {value = "solo", mode = "strict"} end -- changes standard beacons to solo-style beacons
  if mods["space-exploration"] and mods["248k"] then -- changes KI beacons to solo-style beacons
    updated_repeating_beacons["el_ki_beacon_entity"] = {"el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"}
    updated_repeating_beacons["fi_ki_beacon_entity"] = {"el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"}
    updated_repeating_beacons["fu_ki_beacon_entity"] = {"el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"}
  end

  -- populate reference tables with repetitive info
  if mods["nullius"] then
    local repeaters_small = {"beacon"}
    local repeaters_large = {}
    for tier=1,3,1 do
      if tier <= 2 then table.insert(repeaters_small, "nullius-large-beacon-" .. tier) end
      table.insert(repeaters_small, "nullius-beacon-" .. tier)
      table.insert(repeaters_large, "nullius-beacon-" .. tier)
      table.insert(updated_repeating_beacons["beacon"], "nullius-beacon-" .. tier)
      table.insert(updated_repeating_beacons["ab-standard-beacon"], "nullius-beacon-" .. tier)
      for count=1,4,1 do
        table.insert(repeaters_small, "nullius-beacon-" .. tier .. "-" .. count)
        table.insert(repeaters_large, "nullius-beacon-" .. tier .. "-" .. count)
        table.insert(updated_repeating_beacons["beacon"], "nullius-beacon-" .. tier .. "-" .. count)
        table.insert(updated_repeating_beacons["ab-standard-beacon"], "nullius-beacon-" .. tier .. "-" .. count)
      end
    end
    for tier=1,3,1 do
      if tier <= 2 then updated_repeating_beacons["nullius-large-beacon-" .. tier] = repeaters_large end
      updated_repeating_beacons["nullius-beacon-" .. tier] = repeaters_small
      for count=1,4,1 do
        updated_repeating_beacons["nullius-beacon-" .. tier .. "-" .. count] = repeaters_small
      end
    end
  end
  if mods["pycoalprocessing"] then
    local repeaters_AM_FM = {}
    for am=1,5,1 do
      for fm=1,5,1 do
        table.insert(repeaters_AM_FM, "beacon-AM" .. am .. "-FM" .. fm)
        table.insert(repeaters_AM_FM, "diet-beacon-AM" .. am .. "-FM" .. fm)
      end
    end
    for am=1,5,1 do
      for fm=1,5,1 do
        custom_exclusion_ranges["beacon-AM" .. am .. "-FM" .. fm] = {value = "solo", mode = "strict"}
        custom_exclusion_ranges["diet-beacon-AM" .. am .. "-FM" .. fm] = {value = "solo", mode = "strict"}
        updated_repeating_beacons["beacon-AM" .. am .. "-FM" .. fm] = repeaters_AM_FM
        updated_repeating_beacons["diet-beacon-AM" .. am .. "-FM" .. fm] = repeaters_AM_FM
      end
    end
  end
  if mods["PowerCrystals"] then
    local repeaters_crystal = {}
    for tier=1,3,1 do
      table.insert(repeaters_crystal, "model-power-crystal-productivity-" .. tier)
      table.insert(repeaters_crystal, "model-power-crystal-effectivity-" .. tier)
      table.insert(repeaters_crystal, "model-power-crystal-speed-" .. tier)
      table.insert(repeaters_crystal, "base-power-crystal-" .. tier)
      if tier <= 2 then
        table.insert(repeaters_crystal, "model-power-crystal-instability-" .. tier)
        table.insert(repeaters_crystal, "base-power-crystal-negative-" .. tier)
      end
    end
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      for i=1,#repeaters_crystal,1 do
        table.insert(updated_repeating_beacons[beacon.name], repeaters_crystal[i])
      end
    end
    local repeaters_all = {}
    for _, beacon in pairs(beacon_prototypes) do
      table.insert(repeaters_all, beacon.name)
    end
    for tier=1,3,1 do
      custom_exclusion_ranges["model-power-crystal-productivity-" .. tier] = {value = 0}
      custom_exclusion_ranges["model-power-crystal-effectivity-" .. tier] = {value = 0}
      custom_exclusion_ranges["model-power-crystal-speed-" .. tier] = {value = 0}
      custom_exclusion_ranges["base-power-crystal-" .. tier] = {value = 0}
      updated_repeating_beacons["model-power-crystal-productivity-" .. tier] = repeaters_all
      updated_repeating_beacons["model-power-crystal-effectivity-" .. tier] = repeaters_all
      updated_repeating_beacons["model-power-crystal-speed-" .. tier] = repeaters_all
      updated_repeating_beacons["base-power-crystal-" .. tier] = repeaters_all
      if tier <= 2 then
        custom_exclusion_ranges["model-power-crystal-instability-" .. tier] = {value = 0}
        custom_exclusion_ranges["base-power-crystal-negative-" .. tier] = {value = 0}
        updated_repeating_beacons["model-power-crystal-instability-" .. tier] = repeaters_all
        updated_repeating_beacons["base-power-crystal-negative-" .. tier] = repeaters_all
      end
    end
  end
  if mods["exotic-industries"] then
    max_moduled_building_size = 11
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      table.insert(updated_repeating_beacons[beacon.name], "ei_alien-beacon")
    end
  end

  -- set distribution/exclusion ranges
  -- TODO: Change exclusion range to be based on how much is added from distribution range? if other mods change the distribution range, everything would be messed up but it might be less broken if the exclusion ranges are based on the changed values instead of hardcoded
  for _, beacon in pairs(beacon_prototypes) do
    updated_distribution_ranges[beacon.name] = math.ceil(get_distribution_range(beacon))
    if updated_exclusion_ranges[beacon.name] == nil then
      local exclusion_range = updated_distribution_ranges[beacon.name]
      local range = custom_exclusion_ranges[beacon.name]
      if range ~= nil then
        exclusion_range = range.value
        if range.value == "solo" then
          if range.mode == nil or range.mode == "basic" then
            exclusion_range = 2*updated_distribution_ranges[beacon.name] + max_moduled_building_size-1
          elseif range.mode == "strict" then
            exclusion_range = updated_distribution_ranges[beacon.name] + max_moduled_building_size-1
          end
        end
        if range.mode ~= nil and range.mode == "strict" then updated_strict_beacons[beacon.name] = true end
      end
      updated_exclusion_ranges[beacon.name] = exclusion_range
    end
  end

  -- setup relationship table of beacons which should be able to repeat without extra interference (they won't disable each other)
  for _, beacon in pairs(beacon_prototypes) do
    if updated_repeating_beacons[beacon.name] ~= nil then
      local affected_beacons = {}
      for i=1,#updated_repeating_beacons[beacon.name],1 do
        local is_valid = false
        for _, beacon_to_compare in pairs(beacon_prototypes) do
          if beacon_to_compare.name == updated_repeating_beacons[beacon.name][i] then
            is_valid = true
            if (beacon.name == "beacon" and beacon_to_compare.name == "beacon" and mods["space-exploration"] and settings.startup["ab-override-vanilla-beacons"].value == false) then is_valid = false end
          end
        end
        if is_valid == true then
          affected_beacons[updated_repeating_beacons[beacon.name][i]] = true
        end
      end
      global.repeating_beacons[beacon.name] = affected_beacons
    end
  end

  -- setup table of the maximum ranges at which each beacon could affect or be affected by others
  local updated_search_ranges = {}
  for name1, beacon1 in pairs(beacon_prototypes) do
    local highest_exclusion_range = 0
    local highest_distribution_range = 0
    local highest_strict_range = 0
    for name2, beacon2 in pairs(beacon_prototypes) do
      if ((global.repeating_beacons[name1] and global.repeating_beacons[name1][name2]) or (global.repeating_beacons[name2] and global.repeating_beacons[name2][name1])) then
        -- nothing
      else
        if updated_exclusion_ranges[name2] > highest_exclusion_range then highest_exclusion_range = updated_exclusion_ranges[name2] end
        if updated_distribution_ranges[name2] > highest_distribution_range then highest_distribution_range = updated_distribution_ranges[name2] end
        if updated_strict_beacons[name2] and updated_exclusion_ranges[name2] > highest_strict_range then highest_strict_range = updated_exclusion_ranges[name2] end
      end
    end
    local range = math.max(updated_exclusion_ranges[name1], highest_exclusion_range)
    if updated_strict_beacons[name1] then range = math.max(range, updated_exclusion_ranges[name1] + highest_distribution_range) end
    range = math.max(range, updated_distribution_ranges[name1] + highest_strict_range)
    updated_search_ranges[name1] = range
  end

  global.exclusion_ranges = updated_exclusion_ranges
  global.distribution_ranges = updated_distribution_ranges
  global.search_ranges = updated_search_ranges
  global.strict_beacons = updated_strict_beacons
  global.offline_beacons = updated_offline_beacons
  exclusion_ranges = updated_exclusion_ranges
  distribution_ranges = updated_distribution_ranges
  search_ranges = updated_search_ranges
  strict_beacons = updated_strict_beacons
  offline_beacons = updated_offline_beacons
  repeating_beacons = global.repeating_beacons
  update_rate = settings.global["ab-update-rate"].value

  if settings.startup["ab-enable-exclusion-areas"].value then
    enable_scripts()
    check_global_list()
    if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["add_blacklist_name"] then
      remote.call("PickerDollies", "add_blacklist_name", "beacon")
      remote.call("PickerDollies", "add_blacklist_name", "ab-focused-beacon")
      remote.call("PickerDollies", "add_blacklist_name", "ab-node-beacon")
      remote.call("PickerDollies", "add_blacklist_name", "ab-conflux-beacon")
      remote.call("PickerDollies", "add_blacklist_name", "ab-hub-beacon")
      remote.call("PickerDollies", "add_blacklist_name", "ab-isolation-beacon")
    end
    -- beacon manipulation within Pyanodons
    if mods["pycoalprocessing"] then
      remote.add_interface("cryogenic-distillation",
      {am_fm_beacon_settings_changed = function(new_beacon) check_remote(new_beacon, "added") end, -- recheck nearby beacons
      am_fm_beacon_destroyed = function(receivers, surface) end}) -- do nothing
    end
  end
end

-- returns the distribution range for the given beacon (from the edge of selection rather than edge of collision)
function get_distribution_range(beacon)
  local collision_radius = (beacon.collision_box.right_bottom.x - beacon.collision_box.left_top.x) / 2 -- beacon's collision is assumed to be centered on its origin; standard format assumed (leftTop, rightBottom)
  local selection_radius = (beacon.selection_box.right_bottom.x - beacon.selection_box.left_top.x) / 2 -- selection box is assumed to be in full tiles
  local range = beacon.supply_area_distance - (selection_radius - collision_radius)
  if selection_radius < collision_radius then range = beacon.supply_area_distance end
  do return range end -- note: use ceil() on the returned range to get the total tiles affected
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- runtime functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- checks all beacons
function check_global_list()
  for _, surface in pairs(game.surfaces) do
    if surface ~= nil then
      local beacons = surface.find_entities_filtered({type = "beacon"})
      for _, beacon in pairs(beacons) do
        check_self(beacon, -1, nil)
      end
    end
  end
end

-- returns the distance between two bounding boxes
function get_distance(box_a, box_b)
  do return math.max(math.min(math.abs(box_a.right_bottom.x - box_b.left_top.x), math.abs(box_b.right_bottom.x - box_a.left_top.x)), math.min(math.abs(box_a.right_bottom.y - box_b.left_top.y), math.abs(box_b.right_bottom.y - box_a.left_top.y))) end
end

-- enables or disables beacons within the exclusion field (or other effective range) of an added/removed beacon entity
--   @behavior: either "added" or "removed"
function check_nearby(entity, behavior)
  local exclusion_mode = "normal"
  local exclusion_range = exclusion_ranges[entity.name]
  local search_range = search_ranges[entity.name]
  if strict_beacons[entity.name] ~= nil then exclusion_mode = "strict" end
  local search_area = {
    {entity.selection_box.left_top.x - search_range, entity.selection_box.left_top.y - search_range},
    {entity.selection_box.right_bottom.x + search_range, entity.selection_box.right_bottom.y + search_range}
  }
  -- find surrounding beacons and setup general info needed to determine correct behaviors
  local hubCount = 0
  local hubIDs = {}
  local nearby_entities = entity.surface.find_entities_filtered({area = search_area, type = "beacon"})
  if entity.name ~= "ab-hub-beacon" then
    for _, nearby_entity in pairs(nearby_entities) do
      if nearby_entity.name == "ab-hub-beacon" then
        if get_distance(entity.selection_box, nearby_entity.selection_box) < exclusion_ranges["ab-hub-beacon"] then
          hubCount = hubCount + 1
          table.insert(hubIDs, nearby_entity.unit_number)
        end
      end
    end
  end
  -- adjust nearby beacons as needed
  for _, nearby_entity in pairs(nearby_entities) do
    if nearby_entity.unit_number ~= entity.unit_number then
      local nearby_distance = get_distance(entity.selection_box, nearby_entity.selection_box)
      local disabling_range = exclusion_range
      if hubCount > 0 then
        if check_influence(nearby_entity, hubIDs) then exclusion_mode = "super" end -- beacons within a single hub's area affect each other differently
      end
      if exclusion_mode == "strict" then disabling_range = math.max(disabling_range, exclusion_range + distribution_ranges[nearby_entity.name]) end
      if exclusion_mode == "super" then disabling_range = math.max(disabling_range, exclusion_range + exclusion_ranges[nearby_entity.name]) end
      if nearby_entity.name == "ab-conflux-beacon" and distribution_ranges[entity.name] >= distribution_ranges[nearby_entity.name] then disabling_range = math.max(disabling_range, distribution_ranges[entity.name] + distribution_ranges[nearby_entity.name]) end -- TODO: range is checked rather than total area/size - either change the tooltip or take the beacon's dimensions into account too
      if nearby_distance < disabling_range then
        local wasEnabled = nearby_entity.active
        local removed_id = -1
        if behavior ~= "added" then removed_id = entity.unit_number end
        if use_repeating_behavior(entity, nearby_entity) == false then -- some beacons don't affect each other
          if behavior == "added" then
            nearby_entity.active = false
          else
            nearby_entity.active = true
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
  local search_range = search_ranges[entity.name]
  local search_area = {
    {entity.selection_box.left_top.x - search_range, entity.selection_box.left_top.y - search_range},
    {entity.selection_box.right_bottom.x + search_range, entity.selection_box.right_bottom.y + search_range}
  }
  -- find surrounding beacons and setup general info needed to determine correct behaviors
  local hubCount = 0
  local hubID = -1
  local hubIDs = {}
  local nearby_entities = entity.surface.find_entities_filtered({area = search_area, type = "beacon"})
  if entity.name ~= "ab-hub-beacon" then
    for _, nearby_entity in pairs(nearby_entities) do
      if nearby_entity.name == "ab-hub-beacon" and nearby_entity.unit_number ~= removed_id then
        if get_distance(entity.selection_box, nearby_entity.selection_box) < exclusion_ranges["ab-hub-beacon"] then
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
    if (nearby_entity.unit_number ~= entity.unit_number and nearby_entity.unit_number ~= removed_id) then
      local exclusion_mode = "normal"
      local nearby_distance = get_distance(entity.selection_box, nearby_entity.selection_box)
      local disabling_range = exclusion_ranges[nearby_entity.name]
      if strict_beacons[nearby_entity.name] ~= nil then exclusion_mode = "strict" end
      if hubCount > 0 and nearby_entity.name ~= "ab-hub-beacon" then
        if check_influence(nearby_entity, hubIDs) then exclusion_mode = "super" end -- beacons within a single hub's area affect each other differently
      end
      if exclusion_mode == "strict" then disabling_range = math.max(disabling_range, exclusion_ranges[nearby_entity.name] + distribution_ranges[entity.name]) end
      if exclusion_mode == "super" then disabling_range = math.max(disabling_range, exclusion_ranges[nearby_entity.name] + exclusion_ranges[entity.name]) end
      if entity.name == "ab-conflux-beacon" and distribution_ranges[nearby_entity.name] >= distribution_ranges[entity.name] then disabling_range = math.max(disabling_range, distribution_ranges[entity.name] + distribution_ranges[nearby_entity.name]) end
      if nearby_entity.name ~= "ab-hub-beacon" then
        if nearby_distance < disabling_range then
          if exclusion_mode == "super" or use_repeating_behavior(nearby_entity, entity) == false then isEnabled = false end -- some beacons don't affect each other
        end
      elseif (nearby_entity.name == "ab-hub-beacon" and entity.name == "ab-conflux-beacon") then
        disabling_range = distribution_ranges[entity.name] + distribution_ranges[nearby_entity.name]
        if nearby_distance < disabling_range then isEnabled = false end
      elseif (nearby_entity.name == "ab-hub-beacon" and entity.name == "ab-hub-beacon") then
        disabling_range = exclusion_ranges[nearby_entity.name]
        if nearby_distance < disabling_range then isEnabled = false end
      end
    end
  end
  if (isEnabled == false and (entity.name == "ei_copper-beacon" or entity.name == "ei_iron-beacon")) then isEnabled = true end
  if (entity.name == "base-power-crystal-1" or entity.name == "base-power-crystal-2" or entity.name == "base-power-crystal-3" or entity.name == "base-power-crystal-negative-1" or entity.name == "base-power-crystal-negative-2") then isEnabled = true end
  entity.active = isEnabled
  handle_change(entity, wasEnabled, isEnabled)
end

-- handles warning sprites, flying text, and alerts
function handle_change(entity, wasEnabled, isEnabled)
  if (wasEnabled == true and isEnabled == false) then -- beacon deactivated
    entity.surface.create_entity{
      name = "flying-text",
      position = entity.position,
      text = {"ab-beacon-deactivated"}
    }
    if offline_beacons[entity.unit_number] == nil then
      offline_beacons[entity.unit_number] = {
        rendering.draw_sprite{
          sprite = "ab-beacon-offline",
          target = entity,
          surface = entity.surface
        }
      }
      for _, player in pairs(entity.force.players) do
        player.add_custom_alert(entity,
          {type="virtual", name="ab-beacon-offline"},
          {"description.ab-beacon-offline-alert", "[img=virtual-signal/ab-beacon-offline]", "[img=entity/" .. entity.name .. "]"},
          true)
      end
    end

  elseif (wasEnabled == false and isEnabled == true) then -- beacon activated
    --entity.surface.create_entity{
    --  name = "flying-text",
    --  position = entity.position,
    --  text = {"ab-beacon-activated"}
    --}
    if offline_beacons[entity.unit_number] ~= nil then
      rendering.destroy(offline_beacons[entity.unit_number][1])
      offline_beacons[entity.unit_number] = nil
      --remove_beacon_alert(entity)
    end
  elseif (isEnabled == false and offline_beacons[entity.unit_number] == nil) then -- adds icons to old deactivated beacons (may not be necessary)
    offline_beacons[entity.unit_number] = {
      rendering.draw_sprite{
        sprite = "ab-beacon-offline",
        target = entity,
        surface = entity.surface
      }
    }
  elseif (isEnabled == true and offline_beacons[entity.unit_number] ~= nil) then -- removes icons in other cases (may not be necessary)
    rendering.destroy(offline_beacons[entity.unit_number][1])
    offline_beacons[entity.unit_number] = nil
  end
end

function remove_beacon_alert(beacon_entity)
  for _, player in pairs(beacon_entity.force.players) do
    player.remove_alert({entity=beacon_entity, type=defines.alert_type.custom, position=beacon_entity.selection_box.left_top, surface=beacon_entity.surface, message={"description.ab-beacon-offline-alert"}, icon={type="virtual", name="ab-beacon-offline"}}) -- TODO: this should only apply to the alert for the specific beacon_entity
  end
end

-- returns true if the given beacon (entity) is within the exclusion field of a specific hub (hubID)
--   used to determine if the beacon's overlapping area should apply to another beacon near the specific hub (it only applies for beacons within the same hub's exclusion area)
function check_influence(entity, hubIDs)
  local isInfluenced = false
  if exclusion_ranges["ab-hub-beacon"] ~= nil then
    local exclusion_range = exclusion_ranges["ab-hub-beacon"]
    local exclusion_area = {
      {entity.selection_box.left_top.x - exclusion_range, entity.selection_box.left_top.y - exclusion_range},
      {entity.selection_box.right_bottom.x + exclusion_range, entity.selection_box.right_bottom.y + exclusion_range}
    }
    local nearby_beacons = entity.surface.find_entities_filtered({area = exclusion_area, type = "beacon", name = "ab-hub-beacon"})
    for _, beacon in pairs(nearby_beacons) do
      for _, hub_number in pairs(hubIDs) do
        if beacon.unit_number == hub_number then isInfluenced = true end
      end
    end
  end
  do return isInfluenced end
end

-- returns true if the the beacons shouldn't disable each other
function use_repeating_behavior(entity1, entity2)
  local result = false
  if entity1.unit_number ~= entity2.unit_number then
    if repeating_beacons[entity1.name] and repeating_beacons[entity1.name][entity2.name] then result = true end
  end
  do return result end
end

-- checks all beacons within range of the given beacon
function check_remote(entity, behavior)
  local search_range = search_ranges[entity.name]
  local exclusion_area = {
    {entity.selection_box.left_top.x - search_range, entity.selection_box.left_top.y - search_range},
    {entity.selection_box.right_bottom.x + search_range, entity.selection_box.right_bottom.y + search_range}
  }
  local nearby_beacons = entity.surface.find_entities_filtered({area = exclusion_area, type = "beacon"})
  for _, beacon in pairs(nearby_beacons) do
    local wasEnabled = beacon.active
    if behavior == "added" then
      check_self(beacon, -1, wasEnabled)
    elseif (beacon.unit_number ~= entity.unit_number) then
      check_self(beacon, entity.unit_number, wasEnabled)
    end
  end
end
