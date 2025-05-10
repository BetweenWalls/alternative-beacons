--- settings.lua

require("settings-beacons")

data:extend ({
    {
        type = "bool-setting",
        name = "ab-disable-exclusion-areas", -- other mods can force this to be true in order to disable scripting from this mod and implement their own
        setting_type = "startup",
        default_value = false,
        hidden = true,
        order = "1"
    },
    {
        type = "bool-setting",
        name = "ab-override-vanilla-beacons",
        setting_type = "startup",
        default_value = true,
        order = "a"
    },
    {
        type = "bool-setting",
        name = "ab-enable-focused-beacons",
        setting_type = "startup",
        default_value = true,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "ab-enable-node-beacons",
        setting_type = "startup",
        default_value = true,
        order = "c"
    },
    {
        type = "bool-setting",
        name = "ab-enable-conflux-beacons",
        setting_type = "startup",
        default_value = true,
        order = "d"
    },
    {
        type = "bool-setting",
        name = "ab-enable-hub-beacons",
        setting_type = "startup",
        default_value = true,
        order = "e"
    },
    {
        type = "bool-setting",
        name = "ab-enable-isolation-beacons",
        setting_type = "startup",
        default_value = true,
        order = "f"
    },
    {
        type = "string-setting",
        name = "ab-technology-layout",
        setting_type = "startup",
        allowed_values = {"tech-1", "tech-2", "tech-3", "tech-4"},
        default_value = "tech-1",
        order = "g"
    },
    {
        type = "bool-setting",
        name = "ab-enable-se-beacons",
        setting_type = "startup",
        hidden = true, -- only shown if Space Exploration is not active
        default_value = false,
        order = "hb"
    },
    {
        type = "bool-setting",
        name = "ab-enable-k2-beacons",
        setting_type = "startup",
        hidden = true, -- only shown if both Space Exploration and Krastorio 2 are active
        default_value = false,
        order = "hc"
    },
    {
        type = "bool-setting",
        name = "ab-update-recipes",
        setting_type = "startup",
        default_value = true,
        order = "xb"
    },
    {
        type = "bool-setting",
        name = "ab-show-extended-stats",
        setting_type = "startup",
        default_value = true,
        order = "xc"
    },
    {
        type = "bool-setting",
        name = "ab-balance-other-beacons",
        setting_type = "startup",
        default_value = true,
        order = "xd"
    },
    {
        type = "int-setting",
        name = "ab-update-rate",
        setting_type = "runtime-global",
        default_value = 0,
        minimum_value = 0,
        maximum_value = 86400,
        order = "y"
    },
    {
        type = "bool-setting",
        name = "ab-persistent-alerts",
        setting_type = "runtime-global",
        default_value = false,
        order = "z"
    },
})