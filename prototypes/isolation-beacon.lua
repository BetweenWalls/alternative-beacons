-- isolation-beacon.lua

local item = {
  type = "item",
  name = "ab-isolation-beacon",
  place_result = "ab-isolation-beacon",
  icon = "__alternative-beacons__/graphics/icon-isolation.png",
  icon_size = 64,
  stack_size = 20,
  subgroup = "module",
  order = "a[beacon]f"
}

local recipe = {
  type = "recipe",
  name = "ab-isolation-beacon",
  results = {{type="item", name="ab-isolation-beacon", amount=1}},
  enabled = false,
  energy_required = 60,
  ingredients = {{type = "item", name = "advanced-circuit", amount = 400}, {type = "item", name = "electronic-circuit", amount = 400}, {type = "item", name = "copper-cable", amount = 200}, {type = "item", name = "steel-plate", amount = 200}}
}

local animationTemplate = {
  animation = {
      width = 191,
      height = 335,
      scale = 0.78125,
      line_length = 1,
      frame_count = 1,
      shift = {0, -1.75}
  }
}

local beacon_graphics = {
  animation_list = {
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate)
  }
}
-- Additional settings changes
beacon_graphics.animation_list[1].animation.filename = "__alternative-beacons__/graphics/hr-isolation-off.png"

beacon_graphics.animation_list[2].always_draw = false
beacon_graphics.animation_list[2].animation.filename = "__alternative-beacons__/graphics/hr-isolation-animated.png"
beacon_graphics.animation_list[2].animation.line_length = 8
beacon_graphics.animation_list[2].animation.frame_count = 32
beacon_graphics.animation_list[2].animation.animation_speed = 0.5
beacon_graphics.animation_list[2].animation.draw_as_glow = true

beacon_graphics.animation_list[3].animation.draw_as_shadow = true
beacon_graphics.animation_list[3].animation.filename = "__alternative-beacons__/graphics/hr-isolation-shadow.png"
beacon_graphics.animation_list[3].animation.width = 366
beacon_graphics.animation_list[3].animation.height = 204
beacon_graphics.animation_list[3].animation.shift = {2, 0}

local beacon = {
  type = "beacon",
  name = "ab-isolation-beacon",
  icon = "__alternative-beacons__/graphics/icon-isolation.png",
  icon_size = 64,
  icon_mipmaps = 1,
  flags = {"placeable-player", "player-creation"},
  minable = {mining_time = 0.5, result = "ab-isolation-beacon"},
  energy_source = {type = "electric", usage_priority = "secondary-input"},
  energy_usage = "40000kW",
  heating_energy = "33000kW",
  max_health = 600,
  collision_box = { { -2.25, -2.25 }, { 2.25, 2.25 } },
  drawing_box = { { -2.5, -2.5 }, { 2.5, 2.5 } },
  selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } },
  drawing_box_vertical_extension = 3.3,
  allowed_effects = {"consumption", "speed", "pollution"},
  distribution_effectivity = settings.startup["ab-isolation-beacon-distribution-effectivity"].value,
  distribution_effectivity_bonus_per_quality_level = settings.startup
      ["ab-isolation-beacon-distribution-effectivity-bonus-per-quality-level"].value,
  profile = { 1, 0 },
  beacon_counter = "same_type",
  supply_area_distance = settings.startup["ab-isolation-beacon-supply-area-distance"].value, -- extends from edge of collision box (65x65)
  -- exclusion_area_distance = 38 (81x81 strict; hardcoded in control.lua)
  module_slots = settings.startup["ab-isolation-beacon-module-slots"].value,
  icons_positioning = { {
    inventory_index = defines.inventory.beacon_modules,
    shift = {0, 0.5},
    max_icons_per_row = 5,
    max_icon_rows = 2,
    multi_row_initial_height_modifier = -0.3,
  }},
  graphics_set = beacon_graphics,
  radius_visualisation_picture = {
    filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
    priority = "extra-high-no-scale",
    size = {10, 10}
  },
  water_reflection = {
    pictures = {
      filename = "__alternative-beacons__/graphics/reflection-isolation.png",
      priority = "extra-high",
      width = 24,
      height = 37,
      scale = 8.33,
      shift = {0, 4.3},
      variation_count = 1
    },
    rotate = false,
    orientation_to_variation = false
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
  damaged_trigger_effect = {
    entity_name = "spark-explosion",
    offset_deviation = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    offsets = { { 0, 1 } },
    type = "create-entity"
  },
  dying_explosion = "beacon-explosion",
  corpse = "big-remnants"
}

if not feature_flags["freezing"] then beacon.heating_energy = nil end
if not feature_flags["quality"] then beacon.distribution_effectivity_bonus_per_quality_level = nil end

if settings.startup["ab-isolation-beacon-size-six"] then
  beacon.collision_box = { { -2.75, -2.75 }, { 2.75, 2.75 } }
end

local technology = {{
  icon = "__alternative-beacons__/graphics/tech-isolation.png",
  icon_size = 256
}}

return {item = item, entity = beacon, recipe = recipe, technology = technology}