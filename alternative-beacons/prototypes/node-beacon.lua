-- node-beacon.lua

local blank_image = {
  filename = "__alternative-beacons__/graphics/blank.png",
  width = 1,
  height = 1,
  frame_count = 1,
  line_length = 1,
  shift = { 0, 0 },
  repeat_count = 32,
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
            filename = "__alternative-beacons__/graphics/node-beacon-base.png",
            width = 116,
            height = 93,
            shift = util.by_pixel(11, 1.5),
            hr_version = {
              filename = "__alternative-beacons__/graphics/hr-node-beacon-base.png",
              width = 232,
              height = 186,
              shift = util.by_pixel(11, 1.5),
              scale = 0.5
            }
          },
          {
            filename = "__alternative-beacons__/graphics/node-beacon-base-shadow.png",
            width = 116,
            height = 93,
            shift = util.by_pixel(11, 1.5),
            draw_as_shadow = true,
            hr_version = {
              filename = "__alternative-beacons__/graphics/hr-node-beacon-base-shadow.png",
              width = 232,
              height = 186,
              shift = util.by_pixel(11, 1.5),
              draw_as_shadow = true,
              scale = 0.5
            }
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
            filename = "__alternative-beacons__/graphics/node-beacon-antenna.png",
            width = 54,
            height = 50,
            line_length = 8,
            frame_count = 32,
            animation_speed = 0.5,
            shift = util.by_pixel(-1, -55),
            hr_version = {
              filename = "__alternative-beacons__/graphics/hr-node-beacon-antenna.png",
              width = 108,
              height = 100,
              line_length = 8,
              frame_count = 32,
              animation_speed = 0.5,
              shift = util.by_pixel(-1, -55),
              scale = 0.5
            }
          },
          {
            filename = "__alternative-beacons__/graphics/node-beacon-antenna-shadow.png",
            width = 63,
            height = 49,
            line_length = 8,
            frame_count = 32,
            animation_speed = 0.5,
            shift = util.by_pixel(100.5, 15.5),
            draw_as_shadow = true,
            hr_version = {
              filename = "__alternative-beacons__/graphics/hr-node-beacon-antenna-shadow.png",
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
}

data:extend({
{
  type = "beacon",
  name = "ab-node-beacon",
  icon = "__alternative-beacons__/graphics/node-beacon-icon.png",
  icon_mipmaps = 1,
  icon_size = 64,
  flags = { "placeable-player", "player-creation" },
  minable = {
    mining_time = 0.3,
    result = "ab-node-beacon"
  },
  allowed_effects = { "consumption", "speed", "pollution" },
  graphics_set = beacon_graphics,
  animation_shadow = blank_image,
  base_picture = blank_image,
  collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
  drawing_box = { { -1.5, -2.025 }, { 1.5, 1.5 } },
  selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
  corpse = "medium-remnants",
  damaged_trigger_effect = {
    entity_name = "spark-explosion",
    offset_deviation = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    offsets = { { 0, 1 } },
    type = "create-entity"
  },
  dying_explosion = "beacon-explosion",
  energy_source = {
    type = "electric",
    usage_priority = "secondary-input"
  },
  energy_usage = "3000kW",
  max_health = 400,
  module_specification = {
    module_info_icon_shift = { 0, 0.5 },
    module_info_max_icons_per_row = 3,
    module_info_max_icon_rows = 1,
    module_info_multi_row_initial_height_modifier = -0.3,
    module_slots = 3
  },
  distribution_effectivity = 0.5,
  supply_area_distance = 7.05, -- extends from edge of collision box (17x17)
  -- exclusion_area_distance = 7 (17x17; hardcoded in control.lua)
  radius_visualisation_picture = {
    layers = {
        {filename = "__alternative-beacons__/graphics/visualization/beacon-radius-visualization-node.png", size = {33, 33}, priority = "extra-high-no-scale"},
    }
  },
  vehicle_impact_sound = {
    {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.5},
    {filename = "__base__/sound/car-metal-impact-2.ogg", volume = 0.5},
    {filename = "__base__/sound/car-metal-impact-3.ogg", volume = 0.5},
    {filename = "__base__/sound/car-metal-impact-4.ogg", volume = 0.5},
    {filename = "__base__/sound/car-metal-impact-5.ogg", volume = 0.5},
    {filename = "__base__/sound/car-metal-impact-6.ogg", volume = 0.5}
  },
  water_reflection = {
    pictures = {
      filename = "__base__/graphics/entity/beacon/beacon-reflection.png",
      priority = "extra-high",
      width = 24,
      height = 28,
      shift = { 0, 1.71875 },
      variation_count = 1,
      scale = 5,
    },
    rotate = false,
    orientation_to_variation = false
  },
  open_sound = data.raw.beacon.beacon.open_sound,
  close_sound = data.raw.beacon.beacon.close_sound
}
})
