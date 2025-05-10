-- node-beacon.lua

local item = {
  type = "item",
  name = "ab-node-beacon",
  place_result = "ab-node-beacon",
  icon = "__alternative-beacons__/graphics/icon-node.png",
  icon_size = 64,
  stack_size = 20,
  subgroup = "module",
  order = "a[beacon]c"
}

local recipe = {
  type = "recipe",
  name = "ab-node-beacon",
  results = {{type="item", name="ab-node-beacon", amount=1}},
  enabled = false,
  energy_required = 30,
  ingredients = {{type = "item", name = "advanced-circuit", amount = 80}, {type = "item", name = "electronic-circuit", amount = 80}, {type = "item", name = "copper-cable", amount = 40}, {type = "item", name = "steel-plate", amount = 40}}
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
            filename = "__alternative-beacons__/graphics/hr-node-base.png",
            width = 232,
            height = 186,
            shift = util.by_pixel(11, 1.5),
            scale = 0.5
          },
          {
            filename = "__alternative-beacons__/graphics/hr-classic-base-shadow.png",
            width = 232,
            height = 186,
            shift = util.by_pixel(11, 1.5),
            draw_as_shadow = true,
            scale = 0.5
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
            shift = util.by_pixel(-1, -55),
            scale = 0.5
          },
          {
            filename = "__alternative-beacons__/graphics/hr-classic-antenna-shadow.png",
            width = 126,
            height = 98,
            line_length = 8,
            frame_count = 32,
            animation_speed = 0.5,
            shift = util.by_pixel(100.5, 15.5),
            draw_as_shadow = true,
            scale = 0.5
          }
        }
      }
    }
  }
}

local beacon = {
  type = "beacon",
  name = "ab-node-beacon",
  icon = "__alternative-beacons__/graphics/icon-node.png",
  icon_size = 64,
  icon_mipmaps = 4,
  flags = {"placeable-player", "player-creation"},
  minable = {mining_time = 0.3, result = "ab-node-beacon"},
  energy_source = {type = "electric", usage_priority = "secondary-input"},
  energy_usage = "3600kW",
  heating_energy = "3000kW",
  max_health = 300,
  collision_box = { { -1.25, -1.25 }, { 1.25, 1.25 } },
  drawing_box = { { -1.5, -2.025 }, { 1.5, 1.5 } },
  selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
  drawing_box_vertical_extension = 1,
  allowed_effects = {"consumption", "speed", "pollution"},
  distribution_effectivity = settings.startup["ab-node-beacon-distribution-effectivity"].value,
  distribution_effectivity_bonus_per_quality_level = settings.startup["ab-node-beacon-distribution-effectivity-bonus-per-quality-level"].value,
  profile = {2, 1.5, 1.22, 1.07, 0.9597, 0.8875, 0.833, 0.7805, 0.735, 0.6893, 0.6507, 0.6151, 0.5876, 0.5597, 0.5359, 0.516, 0.4976, 0.4795, 0.4626, 0.4468},
  beacon_counter = "total",
  supply_area_distance = settings.startup["ab-node-beacon-supply-area-distance"].value, -- extends from edge of collision box
  -- exclusion_area_distance = 8 (19x19; coded in control.lua)
  module_slots = settings.startup["ab-node-beacon-module-slots"].value,
  icons_positioning = {{
    inventory_index = defines.inventory.beacon_modules,
    shift = {0, 0.5},
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
      scale = 5,
      shift = {0, 2.5},
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
  icon = "__alternative-beacons__/graphics/tech-node.png",
  icon_size = 256
}}

return {item = item, entity = beacon, recipe = recipe, technology = technology}