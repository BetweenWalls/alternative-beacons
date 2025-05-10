--- globals.lua

local globals = {}

--- updates global data
--  creates and updates exclusion ranges for all beacons - beacons from other mods will use their distribution range as their exclusion range unless otherwise noted
function globals.setup(beacon_prototypes)
  local updated_distribution_ranges = {}
  local updated_exclusion_ranges = {}
  local updated_types = {
    ["ab-hub-beacon"] = {hub=true},
    ["ab-conflux-beacon"] = {conflux=true}
    -- entries are added below for all strict beacons
  }

  local custom_exclusion_ranges = { -- these beacons are given custom exclusion ranges: "strict" ranges disable beacons whose distribution areas overlap them, "solo" means the smallest range for "strict" beacons which is large enough to prevent synergy with other beacons
    ["ab-focused-beacon"] = {add=settings.startup["ab-focused-beacon-exclusion-range"].value},
    ["ab-node-beacon"] = {add=settings.startup["ab-node-beacon-exclusion-range"].value},
    ["ab-conflux-beacon"] = {add=settings.startup["ab-conflux-beacon-exclusion-range"].value},
    ["ab-hub-beacon"] = {add=settings.startup["ab-hub-beacon-exclusion-range"].value},
    ["ab-isolation-beacon"] = {add=settings.startup["ab-isolation-beacon-exclusion-range"].value, mode="strict"},
    ["se-basic-beacon"] = { value = "solo", mode = "strict" },
    ["se-compact-beacon"] = { value = "solo", mode = "strict" },
    ["se-compact-beacon-2"] = { value = "solo", mode = "strict" },
    ["se-wide-beacon"] = { value = "solo", mode = "strict" },
    ["se-wide-beacon-2"] = { value = "solo", mode = "strict" },
    ["ei_copper-beacon"] = { value = "solo", mode = "strict" },
    ["ei_iron-beacon"] = { value = "solo", mode = "strict" },
    ["el_ki_beacon_entity"] = { value = "solo", mode = "strict" },
    ["fi_ki_beacon_entity"] = { value = "solo", mode = "strict" },
    ["fu_ki_beacon_entity"] = { value = "solo", mode = "strict" }
    -- entries are added below for: Pyanodons AM-FM beacons, Bob's "beacon-3" (and mini/micro versions), productivity/speed beacons from Advanced Modules, beacons from Fast Furnaces, "beacon3", and "productivity-beacon"
  }
  local updated_repeating_beacons = { -- these beacons don't disable any of the beacons in the list associated with them
    ["beacon"] = {"beacon", "ab-standard-beacon", "kr-singularity-beacon", "beacon-mk1", "beacon-mk2", "beacon-mk3", "5d-beacon-02", "5d-beacon-03", "5d-beacon-04"}, -- additional entries added below
    ["ab-standard-beacon"] = {"beacon", "ab-standard-beacon", "kr-singularity-beacon", "beacon-mk1", "beacon-mk2", "beacon-mk3", "5d-beacon-02", "5d-beacon-03", "5d-beacon-04"}, -- additional entries added below
    ["kr-singularity-beacon"] = {"kr-singularity-beacon"},
    ["ei_copper-beacon"] = {"ei_copper-beacon","ei_iron-beacon"},
    ["ei_iron-beacon"] = {"ei_copper-beacon","ei_iron-beacon"},
    ["beacon-mk1"] = {"beacon", "ab-standard-beacon", "nullius-beacon-3"},
    ["beacon-mk2"] = {"beacon", "ab-standard-beacon", "nullius-beacon-3"},
    ["beacon-mk3"] = {"beacon", "ab-standard-beacon", "nullius-beacon-3"},
    ["el_ki_beacon_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fi_ki_beacon_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fu_ki_beacon_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["el_ki_core_slave_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fi_ki_core_slave_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["fu_ki_core_slave_entity"] = {"el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity", "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"},
    ["5d-beacon-02"] = {"beacon", "ab-standard-beacon", "nullius-beacon-3"},
    ["5d-beacon-03"] = {"beacon", "ab-standard-beacon", "nullius-beacon-3"},
    ["5d-beacon-04"] = {"beacon", "ab-standard-beacon", "nullius-beacon-3"},
    ["mini-beacon-1"] = {"mini-beacon-1"},
    ["micro-beacon-1"] = {"micro-beacon-1"}
    -- entries are added below for: pyanodons AM-FM beacons, nullius small/large beacons, mini/micro beacons, power crystals, alien beacons, warp beacons, editor beacons
  }

  local max_moduled_building_size = 9 -- by default, rocket silo (9x9) is the largest building which can use modules
  local standard = true
  --local beacon_prototypes = game.get_filtered_entity_prototypes({{filter = "type", type = "beacon"}})
  local mods = script.active_mods
  if (mods["pycoalprocessing"] or mods["space-exploration"] or mods["mini"] or mods["Custom-Mods"]) then standard = false end

  -- adjusts reference tables
  if not standard then
    for name, beacon_list in pairs(updated_repeating_beacons) do
      for i=1,#beacon_list,1 do
        if beacon_list[i] == "beacon" then table.remove(updated_repeating_beacons[name], i) end
      end
    end
    updated_repeating_beacons["beacon"] = {}
  end
  if mods["space-exploration"] then
    custom_exclusion_ranges["beacon"] = {value = "solo", mode = "strict"}
    if mods["248k"] then -- changes KI beacons to solo-style beacons
      updated_repeating_beacons["el_ki_beacon_entity"] = {"el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"}
      updated_repeating_beacons["fi_ki_beacon_entity"] = {"el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"}
      updated_repeating_beacons["fu_ki_beacon_entity"] = {"el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity"}
    end
  end
  -- TODO: prevent 248K beacon cores from being "disabled" even though it has no effect on them relaying module effects to beacons
  if mods["Beacon2"] then
    for _, beacon in pairs(beacon_prototypes) do                              -- TODO: can the beacon stats be checked directly instead of iterating through all beacons?
      if beacon.name == "beacon-2" and beacon.supply_area_distance < 3.5 then -- only allow repeating if it's a specific version (multiple mods use the same name)
        updated_repeating_beacons["beacon-2"] = {"ab-standard-beacon"}
        if standard then updated_repeating_beacons["beacon-2"] = {"beacon", "ab-standard-beacon"} end
        table.insert(updated_repeating_beacons["ab-standard-beacon"], "beacon-2")
        if standard then table.insert(updated_repeating_beacons["beacon"], "beacon-2") end
      end
    end
  end
  if mods["zombiesextended-modules"] then
    if not settings.startup["ab-balance-other-beacons"].value then
    -- TODO: beacon-mk1, beacon-mk2, and beacon-mk3 SHOULD disable standard beacons and vice versa (their names are shared with Factorio Extended and they were previously just added directly to the table without checking this)
    updated_repeating_beacons["beacon-mk1"] = nil
    updated_repeating_beacons["beacon-mk2"] = nil
    updated_repeating_beacons["beacon-mk3"] = nil
    end
  end

  -- populate reference tables with repetitive and conditional info
  local repeaters_all = {}
  for name, beacon in pairs(beacon_prototypes) do
    table.insert(repeaters_all, beacon.name)
    if updated_types[name] == nil then updated_types[name] = {} end
  end
  if mods["Advanced_Modules"] or mods["Advanced_Sky_Modules"] or mods["Advanced_beacons"] then ------------------------------------------------------------------------------------------------------------
    if settings.startup["ab-balance-other-beacons"].value then
      custom_exclusion_ranges["productivity-beacon-1"] = {add=3}
      custom_exclusion_ranges["productivity-beacon-2"] = {add=4}
      custom_exclusion_ranges["productivity-beacon-3"] = {add=5}
      custom_exclusion_ranges["speed-beacon-2"] = {add=2}
      custom_exclusion_ranges["speed-beacon-3"] = {add=5}
    end
  end
  if mods["bobmodules"] then ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- v1.1 changes:
    if mods["SeaBlockMetaPack"] then
      --table.insert(updated_repeating_beacons["beacon"], "bob-beacon-2")
      --table.insert(updated_repeating_beacons["beacon"], "bob-beacon-3")
      --table.insert(updated_repeating_beacons["ab-standard-beacon"], "bob-beacon-2")
      --table.insert(updated_repeating_beacons["ab-standard-beacon"], "bob-beacon-3")
      --updated_repeating_beacons["bob-beacon-2"] = {"beacon", "ab-standard-beacon"}
      --updated_repeating_beacons["bob-beacon-3"] = {"beacon", "ab-standard-beacon"}
      --custom_exclusion_ranges["bob-beacon-2"] = {add=-3}
      --custom_exclusion_ranges["bob-beacon-3"] = {add=-6}
    elseif settings.startup["ab-balance-other-beacons"].value and not (mods["CoppermineBobModuleRebalancing"] and settings.startup["coppermine-bob-module-nerfed-beacons"] and settings.startup["coppermine-bob-module-nerfed-beacons"].value) then
      --custom_exclusion_ranges["bob-beacon-3"] = {add=2}
    end
  end
  if mods["EndgameExtension"] then ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if settings.startup["ab-balance-other-beacons"].value then
      custom_exclusion_ranges["beacon-3"] = {add=2}
      custom_exclusion_ranges["productivity-beacon"] = {add=3}
    end
  end
  if mods["beacons"] then ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if settings.startup["ab-balance-other-beacons"].value then
      custom_exclusion_ranges["beacon3"] = {add=2}
    end
  end
  if mods["FastFurnaces"] then ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if settings.startup["ab-balance-other-beacons"].value then
      custom_exclusion_ranges["reika-fast-beacon"] = {add=2}
      custom_exclusion_ranges["reika-fast-beacon-2"] = {value="solo", mode="strict"}
    end
  end
  if mods["starry-sakura"] then ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if startup["ab-balance-other-beacons"].value then
      updated_repeating_beacons["tiny-beacon"] = {"tiny-beacon"}
      updated_repeating_beacons["small-beacon"] = {"small-beacon"}
    end
  end
  if mods["nullius"] then ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local repeaters_small = {"beacon", "ab-standard-beacon"}
    local repeaters_large = {}
    if not standard then repeaters_small = {"ab-standard-beacon"} end
    for tier=1,3,1 do
      if tier <= 2 then table.insert(repeaters_small, "nullius-large-beacon-" .. tier) end
      table.insert(repeaters_small, "nullius-beacon-" .. tier)
      table.insert(repeaters_large, "nullius-beacon-" .. tier)
      if standard then table.insert(updated_repeating_beacons["beacon"], "nullius-beacon-" .. tier) end
      table.insert(updated_repeating_beacons["ab-standard-beacon"], "nullius-beacon-" .. tier)
      for count=1,4,1 do
        table.insert(repeaters_small, "nullius-beacon-" .. tier .. "-" .. count)
        table.insert(repeaters_large, "nullius-beacon-" .. tier .. "-" .. count)
        if standard then table.insert(updated_repeating_beacons["beacon"], "nullius-beacon-" .. tier .. "-" .. count) end
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
    for _, beacon_to_compare in pairs(updated_repeating_beacons["ab-standard-beacon"]) do -- small beacon 3 acts as a standard beacon
      local added = false
      for _, beacon in pairs (updated_repeating_beacons["nullius-beacon-3"]) do
        if beacon == beacon_to_compare then added = true end
      end
      if not added then table.insert(updated_repeating_beacons["nullius-beacon-3"], beacon_to_compare) end
    end
  end
  if mods["pycoalprocessing"] then ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
    max_moduled_building_size = math.max(11, max_moduled_building_size)
    if mods["pypetroleumhandling"] then max_moduled_building_size = math.max(15, max_moduled_building_size) end
  end
  if mods["PowerCrystals"] then ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
  if mods["mini-machines"] then ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if settings.startup["ab-balance-other-beacons"].value == true then
      if mods["bobmodules"] and not mods["SeaBlockMetaPack"] then
        --custom_exclusion_ranges["mini-bob-beacon-3"] = {add=3} -- TODO test with/without seablock
      elseif mods["FactorioExtended-Plus-Module"] then
        updated_repeating_beacons["mini-beacon-1"] = {"mini-beacon-1", "mini-beacon-2", "mini-beacon-3", "mini-beacon-4"}
        updated_repeating_beacons["mini-beacon-2"] = {"mini-beacon-1"}
        updated_repeating_beacons["mini-beacon-3"] = {"mini-beacon-1"}
      elseif mods["5dim_module"] then
        updated_repeating_beacons["mini-beacon-1"] = {"mini-beacon-1", "mini-beacon-2", "mini-beacon-3", "mini-beacon-4"}
        updated_repeating_beacons["mini-beacon-2"] = {"mini-beacon-1"}
        updated_repeating_beacons["mini-beacon-3"] = {"mini-beacon-1"}
      end
      if mods["5dim_module"] then updated_repeating_beacons["mini-beacon-4"] = {"mini-beacon-1"} end
    end
  end
  if mods["micro-machines"] then --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if settings.startup["ab-balance-other-beacons"].value == true then
      if mods["bobmodules"] then
        --custom_exclusion_ranges["micro-bob-beacon-3"] = {add=2}
      elseif mods["FactorioExtended-Plus-Module"] then
        updated_repeating_beacons["micro-beacon-1"] = {"micro-beacon-1", "micro-beacon-2", "micro-beacon-3", "micro-beacon-4"}
        updated_repeating_beacons["micro-beacon-2"] = {"micro-beacon-1"}
        updated_repeating_beacons["micro-beacon-3"] = {"micro-beacon-1"}
      elseif mods["5dim_module"] then
        updated_repeating_beacons["micro-beacon-1"] = {"micro-beacon-1", "micro-beacon-2", "micro-beacon-3", "micro-beacon-4"}
        updated_repeating_beacons["micro-beacon-2"] = {"micro-beacon-1"}
        updated_repeating_beacons["micro-beacon-3"] = {"micro-beacon-1"}
      end
      if mods["5dim_module"] then updated_repeating_beacons["micro-beacon-4"] = {"micro-beacon-1"} end
    end
  end
  if mods["exotic-industries"] then -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    max_moduled_building_size = math.max(11, max_moduled_building_size)
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      table.insert(updated_repeating_beacons[beacon.name], "ei_alien-beacon")
    end
    custom_exclusion_ranges["ei_alien-beacon"] = {value=0}
    updated_repeating_beacons["ei_alien-beacon"] = repeaters_all
    -- TODO: Make copper/iron beacons repeatable for all other beacons since they can't be disabled anyway
  end
  if mods["warptorio2"] then ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      for i=1,10,1 do
        table.insert(updated_repeating_beacons[beacon.name], "warptorio-beacon-" .. tostring(i))
      end
    end
    for i=1,10,1 do
      custom_exclusion_ranges["warptorio-beacon-" .. tostring(i)] = {value=0}
      updated_repeating_beacons["warptorio-beacon-" .. tostring(i)] = repeaters_all
    end
  end
  if mods["LunarLandings"] then ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      table.insert(updated_repeating_beacons[beacon.name], "ll-oxygen-diffuser")
    end
    custom_exclusion_ranges["ll-oxygen-diffuser"] = {value=0}
    updated_repeating_beacons["ll-oxygen-diffuser"] = repeaters_all
  end
  if mods["EditorExtensions"] then ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      table.insert(updated_repeating_beacons[beacon.name], "ee-super-beacon")
    end
    custom_exclusion_ranges["ee-super-beacon"] = {value=0}
    updated_repeating_beacons["ee-super-beacon"] = repeaters_all
  end
  if mods["creative-mod"] then ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      table.insert(updated_repeating_beacons[beacon.name], "creative-mod_super-beacon")
    end
    custom_exclusion_ranges["creative-mod_super-beacon"] = {value=0}
    updated_repeating_beacons["creative-mod_super-beacon"] = repeaters_all
  end
  if mods["StableFoundations"] then -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      table.insert(updated_repeating_beacons[beacon.name], "sf-tile-bonus")
    end
    custom_exclusion_ranges["sf-tile-bonus"] = {value=0}
    updated_repeating_beacons["sf-tile-bonus"] = repeaters_all
  end
  if mods["janky-beacon-rebalance"] then ------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local repeaters_janky = {"beacon", "ab-standard-beacon"}
    for count=1,24,1 do
      for quality=1,5,1 do
        if quality == 1 then
          table.insert(repeaters_janky, "janky-beacon-" .. count)
        else
          table.insert(repeaters_janky, "janky-beacon-" .. count .. "-quality-" .. quality)
        end
      end
    end
    for count=1,24,1 do
      for quality=1,5,1 do
        updated_repeating_beacons["janky-beacon-" .. count] = repeaters_janky
        updated_repeating_beacons["janky-beacon-" .. count .. "-quality-" .. quality] = repeaters_janky
      end
    end
  end
  if mods["maraxsis"] then --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    updated_repeating_beacons["maraxsis-conduit"] = {"beacon", "ab-standard-beacon", "maraxsis-conduit"}
    table.insert(updated_repeating_beacons["beacon"], "maraxsis-conduit")
    table.insert(updated_repeating_beacons["ab-standard-beacon"], "maraxsis-conduit")
  end
  if mods["beacon-interface"] then ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for _, beacon in pairs(beacon_prototypes) do
      if updated_repeating_beacons[beacon.name] == nil then updated_repeating_beacons[beacon.name] = {} end
      table.insert(updated_repeating_beacons[beacon.name], "beacon-interface--beacon-tile")
      table.insert(updated_repeating_beacons[beacon.name], "beacon-interface--beacon")
    end
    custom_exclusion_ranges["beacon-interface--beacon-tile"] = {value=0}
    updated_repeating_beacons["beacon-interface--beacon-tile"] = repeaters_all
    custom_exclusion_ranges["beacon-interface--beacon"] = {value=0}
    updated_repeating_beacons["beacon-interface--beacon"] = repeaters_all
  end
  if mods["modular-beacon-power"] then --------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for urbname,urb in pairs(updated_repeating_beacons) do
      local urb_addons = {}
      for _,repname in pairs(urb) do
        local variants = {}
        for name,_ in pairs(beacon_prototypes) do
          if base_name(name) == repname and name ~= repname then table.insert(variants, name) end
        end
        for _,variant in pairs(variants) do
          table.insert(urb_addons, variant)
        end
      end
      for _,addon in pairs(urb_addons) do
        table.insert(urb, addon) -- adds variants of each beacon in the ordered lists to those lists
      end
      local variants = {}
      for name,_ in pairs(beacon_prototypes) do
        if base_name(name) == urbname and name ~= urbname then table.insert(variants, name) end
      end
      for _,variant in pairs(variants) do
        updated_repeating_beacons[variant] = urb -- variants have the same lists
      end
    end
    for cername,cer in pairs(custom_exclusion_ranges) do
      local variants = {}
      for name,_ in pairs(beacon_prototypes) do
        if base_name(name) == cername and name ~= cername then table.insert(variants, name) end
      end
      for _,variant in pairs(variants) do
        custom_exclusion_ranges[variant] = cer -- variants have the same exclusion ranges
      end
    end
    for typename,type in pairs(updated_types) do
      if type.conflux or type.hub then
        local variants = {}
        for name,_ in pairs(beacon_prototypes) do
          if base_name(name) == typename and name ~= typename then table.insert(variants, name) end
        end
        for _,variant in pairs(variants) do
          updated_types[variant] = type -- variant conflux/hub beacons behave the same
        end
      end
    end
  end

  -- set distribution/exclusion ranges
  for _, beacon in pairs(beacon_prototypes) do
    updated_distribution_ranges[beacon.name] = math.ceil(get_distribution_range(beacon))
    if updated_exclusion_ranges[beacon.name] == nil then
      local exclusion_range = updated_distribution_ranges[beacon.name]
      local range = custom_exclusion_ranges[beacon.name]
      if range then
        if range.value == nil then
          if range.add then exclusion_range = exclusion_range + range.add end
        elseif range.value == "solo" then
          if range.mode == nil or range.mode == "basic" then
            exclusion_range = 2*updated_distribution_ranges[beacon.name] + max_moduled_building_size-1
          elseif range.mode == "strict" then
            exclusion_range = updated_distribution_ranges[beacon.name] + max_moduled_building_size-1
          end
        else
          exclusion_range = range.value
        end
        if range.mode and range.mode == "strict" then updated_types[beacon.name].strict = true end
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
          if beacon_to_compare.name == updated_repeating_beacons[beacon.name][i] then is_valid = true end
        end
        if is_valid == true then affected_beacons[ updated_repeating_beacons[beacon.name][i] ] = true end
      end
      storage.repeating_beacons[beacon.name] = affected_beacons
    end
  end

  -- setup table of the maximum ranges at which each beacon could affect or be affected by others
  local updated_search_ranges = {}
  for name1, beacon1 in pairs(beacon_prototypes) do
    local highest_exclusion_range = 0
    local highest_distribution_range = 0
    local highest_strict_range = 0
    for name2, beacon2 in pairs(beacon_prototypes) do
      if not ((storage.repeating_beacons[name1] and storage.repeating_beacons[name1][name2]) or (storage.repeating_beacons[name2] and storage.repeating_beacons[name2][name1])) then
        if updated_exclusion_ranges[name2] > highest_exclusion_range then highest_exclusion_range = updated_exclusion_ranges[name2] end
        if updated_distribution_ranges[name2] > highest_distribution_range then highest_distribution_range = updated_distribution_ranges[name2] end
        if updated_types[name2].strict and updated_exclusion_ranges[name2] > highest_strict_range then highest_strict_range = updated_exclusion_ranges[name2] end
      end
    end
    local range = math.max(updated_exclusion_ranges[name1], highest_exclusion_range)
    if updated_types[name1].strict then range = math.max(range, updated_exclusion_ranges[name1] + highest_distribution_range) end
    range = math.max(range, updated_distribution_ranges[name1] + highest_strict_range)
    updated_search_ranges[name1] = range
  end

  storage.exclusion_ranges = updated_exclusion_ranges
  storage.distribution_ranges = updated_distribution_ranges
  storage.search_ranges = updated_search_ranges
  storage.strict_beacons = updated_types

  return storage
end

-- returns the distribution range for the given beacon (from the edge of selection rather than edge of collision)
function get_distribution_range(beacon)
  local collision_radius = (beacon.collision_box.right_bottom.x - beacon.collision_box.left_top.x) / 2 -- beacon's collision is assumed to be centered on its origin; standard format assumed (leftTop, rightBottom)
  local selection_radius = (beacon.selection_box.right_bottom.x - beacon.selection_box.left_top.x) / 2 -- selection box is assumed to be in full tiles
  local range = beacon.get_supply_area_distance() - (selection_radius - collision_radius)
  if selection_radius < collision_radius then range = beacon.get_supply_area_distance() end
  do return range end -- note: use ceil() on the returned range to get the total tiles affected
end

return globals
