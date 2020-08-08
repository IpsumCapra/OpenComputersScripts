local constants = {}

constants.mainOptions = { "Settings", "Navigation", "Crew", "Advanced" }

constants.settingOptions = { "Set dimensions", "Set name" }

constants.navOptions = { "Jump", "Set target", "Set movement" }

constants.advancedOptions = { "Maintenance mode", "Disable core" }

constants.rotationValues = {
    {"Front", "w"},
    {"Right +90deg", "d"},
    {"Back +180deg", "s"},
    {"Left -90deg", "a"}
}

return constants