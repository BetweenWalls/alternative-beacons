--- data-final-fixes.lua
--  should only make changes which cannot be made earlier due to other mod changes; changes should be for specific mods combinations or come with settings so they can be disabled

local ingredient_multipliers = {
    ["ab-standard-beacon"] = 1,
    ["ab-focused-beacon"] = 2,
    ["ab-node-beacon"] = 4,
    ["ab-conflux-beacon"] = 10,
    ["ab-hub-beacon"] = 15,
    ["ab-isolation-beacon"] = 20,
}

if startup["ab-enable-se-beacons"].value and not mods["space-exploration"] then
  ingredient_multipliers["se-basic-beacon"] = 4
  ingredient_multipliers["se-compact-beacon"] = 10
  ingredient_multipliers["se-wide-beacon"] = 20
  ingredient_multipliers["se-compact-beacon-2"] = 15
  ingredient_multipliers["se-wide-beacon-2"] = 30
end

-- remakes an ingredient list with multiplied amounts
-- TODO: account for other possible ingredient variables (fluids and catalysts)
function match_ingredients(ingredients, new_ingredients, multiplier)
  local mult = multiplier
  for index, ingredient in pairs(ingredients) do
    multiplier = mult
    if (ingredient.type ~= nil and ingredient.name ~= nil and ingredient.amount ~= nil) then
      if ingredient.amount * multiplier > 500 then multiplier = multiplier/((ingredient.amount * multiplier)/500) end
      table.insert(new_ingredients, {["type"] = ingredient.type, ["name"] = ingredient.name, ["amount"] = math.ceil(ingredient.amount * multiplier)})
    elseif (ingredient.name ~= nil and ingredient.amount ~= nil) then
      if ingredient.amount * multiplier > 500 then multiplier = multiplier/((ingredient.amount * multiplier)/500) end
      table.insert(new_ingredients, {["type"] = "item", ["name"] = ingredient.name, ["amount"] = math.ceil(ingredient.amount * multiplier)})
    elseif #ingredient == 2 and type(ingredient[2]) == "number" then
      if ingredient[2] * multiplier > 500 then multiplier = multiplier/((ingredient[2] * multiplier)/500) end
      table.insert(new_ingredients, {["type"] = "item", ["name"] = ingredient[1], ["amount"] = math.ceil(ingredient[2] * multiplier)})
    end
  end
  do return new_ingredients end
end

-- adjusts recipes to use the same ingredient types as standard beacons (or another beacon if one is deemed more suitable for specific mods)
-- TODO: move to data-updates.lua and only do this again here if necessary (i.e. if other mods update recipes in their own data-updates.lua files)
if data.raw.recipe.beacon ~= nil then
  if startup["ab-update-recipes"].value then
    local common = "beacon"
    if mods["nullius"] then common = "nullius-large-beacon-1" end
    if mods["5dim_module"] or mods["OD27_5dim_module"] then common = "5d-beacon-02" end
    if mods["exotic-industries"] then
      common = "ei_copper-beacon"
      ingredient_multipliers["beacon"] = 1
    end
    if mods["pycoalprocessing"] then
      common = "beacon-mk01"
    end
    if mods["Ultracube"] then
      common = "cube-beacon"
      ingredient_multipliers["beacon"] = 1
    end
    for beacon_name, multiplier in pairs(ingredient_multipliers) do
      if data.raw.recipe[beacon_name] ~= nil then
        local new_ingredients = {}
        if data.raw.recipe[common].ingredients ~= nil then new_ingredients = match_ingredients(data.raw.recipe[common].ingredients, new_ingredients, multiplier) end
        if #new_ingredients > 0 then data.raw.recipe[beacon_name].ingredients = new_ingredients else data.raw.recipe[beacon_name].ingredients = nil end
      end
    end
    --if mods["mini-machines"] or mods["micro-machines"] then
    --  for name, beacon_recipe in pairs(data.raw.recipe) do
    --    if beacon_recipe["base_machine"] and beacon_recipe["base_machine"].result and beacon_recipe["base_machine"].result.place_result and data.raw.beacon[beacon_recipe["base_machine"].result.place_result] then
    --      -- TODO: adjust mini/micro recipe costs based on startup settings? or just reduce by 25%/50% if they're balanced by this mod?
    --    end
    --  end
    --end
  end
end

-- override stats of vanilla beacons (again) for specific mods
if data.raw.item.beacon ~= nil and data.raw.beacon.beacon ~= nil and data.raw.recipe.beacon ~= nil then
  if mods["beacons"] and not (mods["pycoalprocessing"] or mods["space-exploration"] or mods["Krastorio2"]) then
    localise("beacon", {"item", "beacon", "recipe"}, "name", {"name.ab-standard-beacon"})
  end
  if ((mods["5dim_module"] or mods["OD27_5dim_module"]) and not mods["pycoalprocessing"]) then
    localise("beacon", {"item", "beacon", "recipe"}, "name", {"name.ab-standard-beacon"})
    localise("beacon", {"item", "beacon"}, "description", {'?', {'', {"description.ab_except"}, ' ', {"description.ab_standard_tiers_addon"}} })
    data.raw.item.beacon.order = "a[beacon]-1"
    data.raw.recipe.beacon.order = "a[beacon]-1"
  end
  if mods["SeaBlockMetaPack"] then
    localise("beacon", {"item", "beacon"}, "description", {'?', {'', {"description.ab_except"}, ' ', {"description.ab_standard_23_addon"}} })
  end
  if (mods["exotic-industries"]) then
    local do_technology = false
    if data.raw.technology["effect-transmission"] ~= nil then do_technology = true end
    if startup["ab-override-vanilla-beacons"].value == true then override_vanilla_beacon(true, do_technology) end
  end
  if (mods["exotic-industries"] or ((mods["5dim_module"] or mods["OD27_5dim_module"]) and not mods["pycoalprocessing"])) then
    if startup["ab-show-extended-stats"].value == true then
      local strict = false
      add_extended_description("beacon", {item=data.raw.item.beacon, beacon=data.raw.beacon.beacon}, exclusion_range_values["beacon"], strict)
    end
  end
end

if mods["bobmodules"] and mods["exotic-industries"] and startup["ab-balance-other-beacons"].value then
  data.raw.beacon["beacon"].next_upgrade = nil
  data.raw.beacon["bob-beacon-2"].next_upgrade = nil
  data.raw.item["bob-beacon-2"].hidden = false
  data.raw.item["bob-beacon-3"].hidden = false
end

if mods["minno-beacon-rebalance-mod"] then
  -- note: included in data-final-fixes.lua since these beacons aren't instantiated until after data-updates.lua finishes executing
  localise("beacon-highpower", {"item", "beacon"}, "description", {"description.ab_overload"})
  localise("beacon-2-highpower", {"item", "beacon"}, "description", {"description.ab_overload"})
  localise("beacon-3-highpower", {"item", "beacon"}, "description", {"description.ab_overload"})
  override_localisation = false
  data.raw.beacon["beacon-3-highpower"].radius_visualisation_picture = data.raw.beacon["beacon"].radius_visualisation_picture
  if startup["ab-show-extended-stats"].value then
    local new_beacons = {"beacon-highpower", "beacon-2-highpower", "beacon-3-highpower"}
    for _, name in pairs(new_beacons) do
      if data.raw.beacon[name].selection_box then
        if exclusion_range_values[name] == nil then exclusion_range_values[name] = math.ceil(get_distribution_range(data.raw.beacon[name])) end
        add_extended_description(name, {item=data.raw.item[name], beacon=data.raw.beacon[name]}, exclusion_range_values[name], false)
      end
    end
  end
end

-- ensures beacons which can be upgraded into each other share the same bounding box
for _,beacon in pairs(data.raw.beacon) do
  if beacon.next_upgrade then
    data.raw.beacon[beacon.next_upgrade].collision_box = beacon.collision_box
  end
end
