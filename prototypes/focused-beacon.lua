-- focused-beacon.lua

local item = {
  type = "item",
  name = "ab-focused-beacon",
  place_result = "ab-focused-beacon",
  icon = "__alternative-beacons__/graphics/icon-focused.png",
  icon_size = 64,
  stack_size = 20,
  subgroup = "module",
  order = "a[beacon]b"
}

local recipe = {
  type = "recipe",
  name = "ab-focused-beacon",
  results = {{type="item", name="ab-focused-beacon", amount=1}},
  enabled = false,
  energy_required = 20,
  ingredients = {{type = "item", name = "advanced-circuit", amount = 40}, {type = "item", name = "electronic-circuit", amount = 40}, {type = "item", name = "copper-cable", amount = 20}, {type = "item", name = "steel-plate", amount = 20}}
}

local beacon_graphics = {
  module_icons_suppressed = false,
  animation_list = {
    {
      render_layer = "lower-object-above-shadow",
      always_draw = true,
      animation = {
        layers = {
          {
            filename = "__alternative-beacons__/graphics/hr-focused-base.png",
            width = 232,
            height = 186,
            shift = util.by_pixel(8, 1),
            scale = 0.335
          },
          {
            filename = "__alternative-beacons__/graphics/hr-classic-base-shadow.png",
            width = 232,
            height = 186,
            shift = util.by_pixel(8, 1),
            draw_as_shadow = true,
            scale = 0.335
          }
        }
      }
    },
    {
      render_layer = "object",
      always_draw = true,
      animation = {
        layers = {
          {
            filename = "__alternative-beacons__/graphics/hr-classic-antenna.png",
            width = 108,
            height = 100,
            line_length = 8,
            frame_count = 32,
            animation_speed = 0.5,
            shift = util.by_pixel(-0.7, -36),
            scale = 0.335
          },
          {
            filename = "__alternative-beacons__/graphics/hr-classic-antenna-shadow.png",
            width = 126,
            height = 98,
            line_length = 8,
            frame_count = 32,
            animation_speed = 0.5,
            shift = util.by_pixel(67, 10.5),
            draw_as_shadow = true,
            scale = 0.335
          }
        }
      }
    }
  }
}

local beacon = {
  type = "beacon",
  name = "ab-focused-beacon",
  icon = "__alternative-beacons__/graphics/icon-focused.png",
  icon_size = 64,
  icon_mipmaps = 4,
  flags = {"placeable-player", "player-creation"},
  minable = {mining_time = 0.2, result = "ab-focused-beacon"},
  energy_source = {type = "electric", usage_priority = "secondary-input"},
  energy_usage = "1200kW",
  heating_energy = "1000kW",
  max_health = 150,
  collision_box = { { -0.75, -0.75 }, { 0.75, 0.75 } },
  drawing_box = { { -1, -1.7 }, { 1, 1 } },
  selection_box = { { -1, -1 }, { 1, 1 } },
  drawing_box_vertical_extension = 0.6,
  allowed_effects = {"consumption", "speed", "pollution"},
  distribution_effectivity = settings.startup["ab-focused-beacon-distribution-effectivity"].value,
  distribution_effectivity_bonus_per_quality_level = settings.startup["ab-focused-beacon-distribution-effectivity-bonus-per-quality-level"].value,
  profile = {1.556, 1.334, 1.15, 1, 0.86, 0.75, 0.66, 0.59, 0.5333, 0.4868, 0.45, 0.414, 0.3872, 0.3635, 0.3423, 0.3233, 0.3059, 0.2901, 0.2755, 0.2621},
  beacon_counter = "total",
  supply_area_distance = settings.startup["ab-focused-beacon-supply-area-distance"].value, -- extends from edge of collision box (6x6)
  -- exclusion_area_distance = 3 (8x8; hardcoded in control.lua)
  module_slots = settings.startup["ab-focused-beacon-module-slots"].value,
  icons_positioning = {{
    inventory_index = defines.inventory.beacon_modules,
    shift = {0, 0.25},
    max_icons_per_row = 3,
    max_icon_rows = 1,
  }},
  graphics_set = beacon_graphics,
  radius_visualisation_picture = {
    filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
    priority = "extra-high-no-scale",
    size = {10, 10}
  },
  water_reflection = {
    pictures = {
      filename = "__alternative-beacons__/graphics/reflection-classic.png",
      priority = "extra-high",
      width = 24,
      height = 28,
      scale = 3.33,
      shift = {0, 1.8},
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
  corpse = "medium-remnants"
}

if not feature_flags["freezing"] then beacon.heating_energy = nil end
if not feature_flags["quality"] then beacon.distribution_effectivity_bonus_per_quality_level = nil end

local technology = {{
  icon = "__alternative-beacons__/graphics/tech-focused.png",
  icon_size = 256
}}

return {item = item, entity = beacon, recipe = recipe, technology = technology}