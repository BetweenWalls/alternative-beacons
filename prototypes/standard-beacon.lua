-- standard-beacon.lua
-- this prototype is practically the same as the vanilla prototype and is only necessary for compatibility reasons when using other mods that alter vanilla beacons

local item = {
  type = "item",
  name = "ab-standard-beacon",
  place_result = "ab-standard-beacon",
  icon = "__base__/graphics/icons/beacon.png",
  icon_size = 64,
  stack_size = 20,
  subgroup = "module",
  order = "a[beacon]a"
}

local recipe = {
  type = "recipe",
  name = "ab-standard-beacon",
  results = {{type="item", name="ab-standard-beacon", amount=1}},
  enabled = false,
  energy_required = 15,
  ingredients = {{type = "item", name = "advanced-circuit", amount = 20}, {type = "item", name = "electronic-circuit", amount = 20}, {type = "item", name = "copper-cable", amount = 10}, {type = "item", name = "steel-plate", amount = 10}}
}

-- copied from \base\prototypes\entity\entities.lua with minor changes
local beacon = {
  type = "beacon",
  name = "ab-standard-beacon",
  icon = "__base__/graphics/icons/beacon.png",
  icon_size = 64,
  icon_mipmaps = 4,
  flags = {"placeable-player", "player-creation"},
  minable = {mining_time = 0.2, result = "ab-standard-beacon"},
  energy_source = {type = "electric", usage_priority = "secondary-input"},
  energy_usage = "480kW",
  heating_energy = "400kW",
  max_health = 200,
  collision_box = {{-1.25, -1.25}, {1.25, 1.25}},
  drawing_box = {{-1.5, -2.2}, {1.5, 1.3}},
  selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
  drawing_box_vertical_extension = 0.2,
  allowed_effects = {"consumption", "speed", "pollution"},
  distribution_effectivity = settings.startup["ab-standard-beacon-distribution-effectivity"].value,
  distribution_effectivity_bonus_per_quality_level = settings.startup["ab-standard-beacon-distribution-effectivity-bonus-per-quality-level"].value,
  profile = {1, 0.7071, 0.5773, 0.5, 0.4472, 0.4082, 0.3779, 0.3535, 0.3333, 0.3162, 0.3015, 0.2887, 0.2773, 0.2672, 0.2582, 0.25, 0.2425, 0.2357, 0.2294, 0.2236, 0.2182, 0.2132, 0.2085, 0.2041, 0.2, 0.1961, 0.1924, 0.189, 0.1857, 0.1825, 0.1796, 0.1768, 0.1741, 0.1715, 0.169, 0.1666, 0.1644, 0.1622, 0.1601, 0.1581, 0.1561, 0.1543, 0.1525, 0.1507, 0.149, 0.1474, 0.1458, 0.1443, 0.1428, 0.1414, 0.14, 0.1387, 0.1373, 0.1361, 0.1348, 0.1336, 0.1324, 0.1313, 0.1302, 0.1291, 0.128, 0.127, 0.126, 0.125, 0.124, 0.1231, 0.1221, 0.1212, 0.1204, 0.1195, 0.1187, 0.1178, 0.117, 0.1162, 0.1154, 0.1147, 0.1139, 0.1132, 0.1125, 0.1118, 0.1111, 0.1104, 0.1097, 0.1091, 0.1084, 0.1078, 0.1072, 0.1066, 0.106, 0.1054, 0.1048, 0.1042, 0.1037, 0.1031, 0.1026, 0.102, 0.1015, 0.101, 0.1005, 0.1},
  beacon_counter = "total",
  supply_area_distance = settings.startup["ab-standard-beacon-supply-area-distance"].value, -- extends from edge of collision box
  module_slots = settings.startup["ab-standard-beacon-module-slots"].value,
  icons_positioning = {{
    inventory_index = defines.inventory.beacon_modules,
    shift = {0, 0.5},
    max_icons_per_row = 2,
    multi_row_initial_height_modifier = -0.3,
  }},
  graphics_set = require("__base__/prototypes/entity/beacon-animations.lua"),
  radius_visualisation_picture = {
    filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
    priority = "extra-high-no-scale",
    size = {10, 10}
  },
  water_reflection = {
    pictures = {
      filename = "__alternative-beacons__/graphics/reflection-standard.png",
      priority = "extra-high",
      width = 18,
      height = 29,
      scale = 5,
      shift = util.by_pixel(0, 55),
      variation_count = 1
    },
    orientation_to_variation = false,
    rotate = false
  },
  open_sound = {filename = "__base__/sound/open-close/beacon-open.ogg", volume = 0.4},
  close_sound = {filename = "__base__/sound/open-close/beacon-close.ogg", volume = 0.4},
  working_sound = {
    audible_distance_modifier = 0.33,
    max_sounds_per_type = 3,
    sound = {
      {filename = "__base__/sound/beacon-1.ogg", volume = 0.2},
      {filename = "__base__/sound/beacon-2.ogg", volume = 0.2}
    }
  },
  impact_category = "metal",
  damaged_trigger_effect = { -- changed from: damaged_trigger_effect = hit_effects.entity(),
    entity_name = "spark-explosion",
    offset_deviation = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    offsets = { { 0, 1 } },
    type = "create-entity"
  },
  dying_explosion = "beacon-explosion",
  corpse = "beacon-remnants"
}

if mods["space-age"] then
  local frozen_patch = {
    filename = "__space-age__/graphics/entity/frozen/beacon/beacon-frozen.png",
    height = 192,
    width = 212,
    scale = 0.5,
    shift = {0.015625, 0.03125}
  }
  beacon.graphics_set.frozen_patch = frozen_patch
end

if not feature_flags["freezing"] then beacon.heating_energy = nil end
if not feature_flags["quality"] then beacon.distribution_effectivity_bonus_per_quality_level = nil end

return {item = item, entity = beacon, recipe = recipe}