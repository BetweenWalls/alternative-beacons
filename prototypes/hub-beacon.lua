-- hub-beacon.lua

local item = {
  type = "item",
  name = "ab-hub-beacon",
  place_result = "ab-hub-beacon",
  icon = "__alternative-beacons__/graphics/icon-hub.png",
  icon_size = 64,
  stack_size = 20,
  subgroup = "module",
  order = "a[beacon]e"
}

local recipe = {
  type = "recipe",
  name = "ab-hub-beacon",
  results = {{type="item", name="ab-hub-beacon", amount=1}},
  enabled = false,
  energy_required = 50,
  ingredients = {{type = "item", name = "advanced-circuit", amount = 300}, {type = "item", name = "electronic-circuit", amount = 300}, {type = "item", name = "copper-cable", amount = 150}, {type = "item", name = "steel-plate", amount = 150}}
}

-- Most common settings for the animations (deepcopied multiple times to keep the code short)
local animationTemplate = {
  animation = {
      width = 198,
      height = 340,
      scale = 0.625,
      line_length = 1,
      frame_count = 1,
      shift = {0, -1.4}
  }
}

-- Includes 3 still images, 3 animated images that cover the still images when the machine is active, and a shadow.
-- Because of a combination of 'always_draw' and 'render_layer', layers couldn't be used to fit them in the same animation list.
local beacon_graphics = {
  animation_list = {
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate),
      table.deepcopy(animationTemplate)
  }
}
-- Additional settings changes
beacon_graphics.animation_list[1].render_layer = "lower-object-above-shadow"
beacon_graphics.animation_list[1].animation.filename = "__alternative-beacons__/graphics/hr-hub-base.png"
beacon_graphics.animation_list[2].animation.filename = "__alternative-beacons__/graphics/hr-hub-antenna.png"
beacon_graphics.animation_list[3].animation.filename = "__alternative-beacons__/graphics/hr-hub-body.png"

beacon_graphics.animation_list[4].render_layer = "lower-object-above-shadow"
beacon_graphics.animation_list[4].always_draw = false
beacon_graphics.animation_list[4].animation.filename = "__alternative-beacons__/graphics/hr-hub-base-animated.png"
beacon_graphics.animation_list[4].animation.line_length = 8
beacon_graphics.animation_list[4].animation.frame_count = 32
beacon_graphics.animation_list[4].animation.animation_speed = 0.5
beacon_graphics.animation_list[4].animation.draw_as_glow = true

beacon_graphics.animation_list[5].always_draw = false
beacon_graphics.animation_list[5].animation.filename = "__alternative-beacons__/graphics/hr-hub-antenna-animated.png"
beacon_graphics.animation_list[5].animation.line_length = 8
beacon_graphics.animation_list[5].animation.frame_count = 32
beacon_graphics.animation_list[5].animation.animation_speed = 0.5
beacon_graphics.animation_list[5].animation.draw_as_glow = true

beacon_graphics.animation_list[6].always_draw = false
beacon_graphics.animation_list[6].animation.filename = "__alternative-beacons__/graphics/hr-hub-body-animated.png"
beacon_graphics.animation_list[6].animation.line_length = 8
beacon_graphics.animation_list[6].animation.frame_count = 32
beacon_graphics.animation_list[6].animation.animation_speed = 0.5
beacon_graphics.animation_list[6].animation.draw_as_glow = true

beacon_graphics.animation_list[7].animation.draw_as_shadow = true
beacon_graphics.animation_list[7].animation.filename = "__alternative-beacons__/graphics/hr-hub-shadow.png"
beacon_graphics.animation_list[7].animation.width = 366
beacon_graphics.animation_list[7].animation.height = 204
beacon_graphics.animation_list[7].animation.shift = {1.59, 0}

local beacon = {
  type = "beacon",
  name = "ab-hub-beacon",
  icon = "__alternative-beacons__/graphics/icon-hub.png",
  icon_size = 64,
  icon_mipmaps = 4,
  flags = {"placeable-player", "player-creation"},
  minable = {mining_time = 0.5, result = "ab-hub-beacon"},
  energy_source = {type = "electric", usage_priority = "secondary-input"},
  energy_usage = "15000kW",
  heating_energy = "12500kW",
  max_health = 500,
  collision_box = { { -1.75, -1.75 }, { 1.75, 1.75 } },
  drawing_box = { { -2, -2.7 }, { 2, 2 } },
  selection_box = { { -2, -2 }, { 2, 2 } },
  drawing_box_vertical_extension = 2.7,
  allowed_effects = {"consumption", "speed", "pollution"},
  distribution_effectivity = settings.startup["ab-hub-beacon-distribution-effectivity"].value,
  distribution_effectivity_bonus_per_quality_level = settings.startup["ab-hub-beacon-distribution-effectivity-bonus-per-quality-level"].value,
  profile = {1, 0.97, 0.95, 0.9334, 0.93, 0.9275, 0.925, 0.9225, 0.92, 0},
  beacon_counter = "total",
  supply_area_distance = settings.startup["ab-hub-beacon-supply-area-distance"].value, -- extends from edge of collision box (32x32)
  -- exclusion_area_distance = 34 (72x72; hardcoded in control.lua)
  module_slots = settings.startup["ab-hub-beacon-module-slots"].value,
  icons_positioning = {{
    inventory_index = defines.inventory.beacon_modules,
    shift = {0, 0.1},
    max_icons_per_row = 3,
    max_icon_rows = 3,
    multi_row_initial_height_modifier = -0.3,
  }},
  graphics_set = beacon_graphics,
  radius_visualisation_picture =
  {
    filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
    priority = "extra-high-no-scale",
    size = {10, 10}
  },
  water_reflection = {
    pictures = {
      filename = "__alternative-beacons__/graphics/reflection-hub.png",
      priority = "extra-high",
      width = 24,
      height = 37,
      scale = 6.66,
      shift = {0, 3.2},
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

local technology = {{
  icon = "__alternative-beacons__/graphics/tech-hub.png",
  icon_size = 256
}}

return {item = item, entity = beacon, recipe = recipe, technology = technology}