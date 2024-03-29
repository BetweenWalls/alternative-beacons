--- data-final-fixes.lua
--  should only make changes which cannot be made earlier due to other mod changes; changes should be for specific mods combinations or come with settings so they can be disabled

local ingredient_multipliers = {
    ["ab-focused-beacon"] = 2,
    ["ab-node-beacon"] = 5,
    ["ab-conflux-beacon"] = 10,
    ["ab-hub-beacon"] = 20,
    ["ab-isolation-beacon"] = 20,
}

if startup["ab-enable-se-beacons"].value then
  ingredient_multipliers["se-basic-beacon"] = 3
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
      if ingredient.amount * multiplier > 600 then multiplier = multiplier / 2 end
      if ingredient.amount * multiplier > 800 then multiplier = multiplier / 2 end
      table.insert(new_ingredients, {["type"] = ingredient.type, ["name"] = ingredient.name, ["amount"] = ingredient.amount * multiplier})
    elseif (ingredient.name ~= nil and ingredient.amount ~= nil) then
      if ingredient.amount * multiplier > 600 then multiplier = multiplier / 2 end
      if ingredient.amount * multiplier > 800 then multiplier = multiplier / 2 end
      table.insert(new_ingredients, {["type"] = "item", ["name"] = ingredient.name, ["amount"] = ingredient.amount * multiplier})
    elseif #ingredient == 2 and type(ingredient[2]) == "number" then
      if ingredient[2] * multiplier > 600 then multiplier = multiplier / 2 end
      if ingredient[2] * multiplier > 800 then multiplier = multiplier / 2 end
      table.insert(new_ingredients, {["type"] = "item", ["name"] = ingredient[1], ["amount"] = ingredient[2] * multiplier})
    end
  end
  do return new_ingredients end
end

-- adjusts recipes to use the same ingredient types as standard beacons (or another beacon if one is deemed more suitable for specific mods)
-- TODO: move to data-updates.lua and only do this again here if necessary (i.e. if other mods update recipes in their own data-updates.lua files)
if data.raw.recipe.beacon ~= nil then
  if startup["ab-update-recipes"].value then
    local common = "beacon"
    if mods["nullius"] then common = "nullius-beacon-3" end
    if mods["5dim_module"] or mods["OD27_5dim_module"] then common = "5d-beacon-02" end
    if mods["exotic-industries"] then
      common = "ei_copper-beacon"
      ingredient_multipliers["beacon"] = 1
    end
    if mods["pycoalprocessing"] then
      common = "beacon-mk01"
      ingredient_multipliers["ab-standard-beacon"] = 1
    end
    if mods["Ultracube"] then
      common = "cube-beacon"
      ingredient_multipliers["beacon"] = 1
    end
    for beacon_name, multiplier in pairs(ingredient_multipliers) do
      if data.raw.recipe[beacon_name] ~= nil then
        local new_ingredients = {}
        local new_ingredients_normal = {}
        local new_ingredients_expensive = {}
        if data.raw.recipe[common].ingredients ~= nil then new_ingredients = match_ingredients(data.raw.recipe[common].ingredients, new_ingredients, multiplier) end
        if data.raw.recipe[common].normal ~= nil and data.raw.recipe[common].normal.ingredients ~= nil then new_ingredients_normal = match_ingredients(data.raw.recipe[common].normal.ingredients, new_ingredients_normal, multiplier) end
        if data.raw.recipe[common].expensive ~= nil and data.raw.recipe[common].expensive.ingredients ~= nil then new_ingredients_expensive = match_ingredients(data.raw.recipe[common].expensive.ingredients, new_ingredients_expensive, multiplier) end
        if #new_ingredients > 0 then data.raw.recipe[beacon_name].ingredients = new_ingredients else data.raw.recipe[beacon_name].ingredients = nil end
        if #new_ingredients_normal > 0 then data.raw.recipe[beacon_name].normal.ingredients = new_ingredients_normal else data.raw.recipe[beacon_name].normal = nil end
        if #new_ingredients_expensive > 0 then data.raw.recipe[beacon_name].expensive.ingredients = new_ingredients_expensive else data.raw.recipe[beacon_name].expensive = nil end
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
if data.raw.item.beacon ~= nil and data.raw.beacon.beacon ~= nil then
  if mods["Krastorio2"] then data.raw.beacon["beacon"].localised_description = data.raw.item["beacon"].localised_description end -- TODO: This may not be necessary - find out what causes the two descriptions to be different
  if mods["beacons"] and not (mods["pycoalprocessing"] or mods["space-exploration"] or mods["Krastorio2"]) then
    localise("beacon", {"item", "beacon", "recipe"}, "name", {"name.ab-standard-beacon"})
  end
  if ((mods["5dim_module"] or mods["OD27_5dim_module"]) and not mods["pycoalprocessing"]) then
    localise("beacon", {"item", "beacon", "recipe"}, "name", {"name.ab-standard-beacon"})
    localise("beacon", {"item", "beacon"}, "description", {'?', {'', {"description.ab_except"}, ' ', {"description.ab_standard_tiers_addon"}} })
    data.raw.item.beacon.order = "a[beacon]-1"
    data.raw.recipe.beacon.order = "a[beacon]-1"
  end
  if (mods["space-exploration"] or mods["exotic-industries"]) then
    local do_technology = false
    if data.raw.technology["effect-transmission"] ~= nil then do_technology = true end
    if startup["ab-override-vanilla-beacons"].value == true then override_vanilla_beacon(true, do_technology) end
    if mods["space-exploration"] and startup["ab-override-vanilla-beacons"].value == false then
      localise("beacon", {"item", "beacon"}, "description", {"description.ab_strict"})
    end
  end
  if (mods["space-exploration"] or mods["exotic-industries"] or ((mods["5dim_module"] or mods["OD27_5dim_module"]) and not mods["pycoalprocessing"])) then
    if startup["ab-show-extended-stats"].value == true then
      local strict = false
      if mods["space-exploration"] and startup["ab-override-vanilla-beacons"].value == false then strict = true end
      add_extended_description("beacon", {item=data.raw.item.beacon, beacon=data.raw.beacon.beacon}, exclusion_range_values["beacon"], strict)
    end
  end
end

if mods["bobmodules"] and mods["exotic-industries"] and startup["ab-balance-other-beacons"].value then
  data.raw.beacon["beacon"].next_upgrade = nil
  data.raw.beacon["beacon-2"].next_upgrade = nil
  data.raw.item["beacon-2"].flags = nil -- removes "hidden" flag
  data.raw.item["beacon-3"].flags = nil
end
