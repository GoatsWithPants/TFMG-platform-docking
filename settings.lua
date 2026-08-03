data:extend({
  {
    type = "bool-setting",
    name = "TFMG-dock-preview-dynamic-zoom",
    order = "A-A",
    setting_type = "runtime-per-user",
    default_value = true,
  },
  {
    type = "double-setting",
    name = "TFMG-dock-preview-zoom",
    order = "A-B",
    setting_type = "runtime-per-user",
    minimum_value = 0.01,
    maximum_value = 10,
    default_value = 1,
  },
  {
    type = "int-setting",
    name = "TFMG-dock-preview-size-x",
    order = "B-A",
    setting_type = "runtime-per-user",
    minimum_value = 1,--Rip bozo if they set it to 1.
    maximum_vale = 5000,
    default_value = 512,
  },
  {
    type = "int-setting",
    name = "TFMG-dock-preview-size-y",
    order = "B-B",
    setting_type = "runtime-per-user",
    minimum_value = 1,--Rip bozo if they set it to 1.
    maximum_vale = 5000,
    default_value = 512,
  },

})