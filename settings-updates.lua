--- settings-updates.lua

if mods["space-exploration"] then
    if mods["Krastorio2"] then
        data.raw["bool-setting"]["ab-enable-k2-beacons"].hidden = false
    end
else
    data.raw["bool-setting"]["ab-enable-se-beacons"].hidden = false
end
if mods["pycoalprocessing"] then
    if data.raw["bool-setting"]["future-beacons"] ~= nil then
        data.raw["bool-setting"]["future-beacons"].hidden = true
        data.raw["bool-setting"]["future-beacons"].forced_value = true
    end
end
if mods["mini-machines"] then
    if data.raw["bool-setting"]["mini-tech"] ~= nil then
        data.raw["bool-setting"]["mini-tech"].default_value = false
    end
end
if mods["micro-machines"] then
    if data.raw["bool-setting"]["micro-tech"] ~= nil then
        data.raw["bool-setting"]["micro-tech"].default_value = false
    end
end
if mods["TarawindBeaconsRE3x3"] then
    if data.raw["bool-setting"]["tarawind-reloaded-3x3mode"] ~= nil then
        data.raw["bool-setting"]["tarawind-reloaded-3x3mode"].default_value = true
    end
    if data.raw["bool-setting"]["tarawind-reloaded-productivityreduce"] ~= nil then
        data.raw["bool-setting"]["tarawind-reloaded-productivityreduce"].default_value = true
    end
end
if mods["TarawindBeaconsRE"] then
    if data.raw["bool-setting"]["TBRE-Productivity"] ~= nil then
        data.raw["bool-setting"]["TBRE-Productivity"].hidden = true
        data.raw["bool-setting"]["TBRE-Productivity"].forced_value = true -- prevents a crash
    end
end
if mods["more-module-slots"] then
    if data.raw["bool-setting"]["more-module-slots_beacon"] ~= nil then
        data.raw["bool-setting"]["more-module-slots_beacon"].default_value = false
    end
end
if mods["CoppermineBobModuleRebalancing"] then
    if data.raw["bool-setting"]["bobmods-modules-enable-modules-lab"] ~= nil then
        data.raw["bool-setting"]["bobmods-modules-enable-modules-lab"].hidden = true
        data.raw["bool-setting"]["bobmods-modules-enable-modules-lab"].forced_value = true -- prevents a crash
    end
end
if mods["Li-Module-Fix"] then
    if data.raw["double-setting"]["beacon_sad"] ~= nil then
        data.raw["double-setting"]["beacon_sad"].hidden = true
        data.raw["double-setting"]["beacon_sad"].forced_value = 1 -- custom beacon range currently unsupported (it would require transferring info between data/control stages)
        data.raw["double-setting"]["beacon_sad"].default_value = 1
        data.raw["double-setting"]["beacon_sad"].maximum_value = 1.00001
        data.raw["double-setting"]["beacon_sad"].minimum_value = 1
    end
    if data.raw["double-setting"]["beacon_de"] ~= nil then
        data.raw["double-setting"]["beacon_de"].default_value = 1
    end
    if data.raw["int-setting"]["more_slots_unm"] ~= nil then
        data.raw["int-setting"]["more_slots_unm"].default_value = 0
        data.raw["int-setting"]["more_slots_unm"].minimum_value = 0
    end
end
--[[
if mods["wret-beacon-rebalance-mod"] then
    if data.raw["bool-setting"]["wret-overload-disable-overloaded"] ~= nil then
        data.raw["bool-setting"]["wret-overload-disable-overloaded"].hidden = true
        data.raw["bool-setting"]["wret-overload-disable-overloaded"].forced_value = false
        -- TODO: integrate these beacons?
    end
end
]]
