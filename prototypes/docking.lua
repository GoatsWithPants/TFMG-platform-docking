local TFMG_util = require("__TFMG-lib__.data.util") --TFMG data stage functions, primarily the rocket capacity one

local item_sounds = require("__base__.prototypes.item_sounds")
local sounds = require("__base__.prototypes.entity.sounds")
local hit_effects = require("__base__.prototypes.entity.hit-effects")

--belt animation set

--local basic_belt_animation_set =
--{
--  animation_set =
--  {
--    filename = "__base__/graphics/entity/transport-belt/transport-belt.png",
--    priority = "extra-high",
--    size = 128,
--    scale = 0.5,
--    frame_count = 16,
--    direction_count = 20
--  },
--}

local connector_buildability_rules = {
	{
		area = { { -0.4, -0.4 }, { 0.4, 0.4 } },
		required_tiles = { layers = { ground_tile = true } },
		colliding_tiles = { layers = { empty_space = true } },
		remove_on_collision = true,
	},
	{
		area = { { -1.5, -50 }, { 1.5, -0.6 } },
		required_tiles = { layers = { empty_space = true } },
		remove_on_collision = true,
	},
}

local connector_buildability_rules_pipe = {
	{
		area = { { -0.4, -0.4 }, { 0.4, 0.4 } },
		required_tiles = { layers = { ground_tile = true } },
		colliding_tiles = { layers = { empty_space = true } },
		remove_on_collision = true,
	},
	{
		area = { { -1.5, 0.6 }, { 1.5, 50 } },
		required_tiles = { layers = { empty_space = true } },
		remove_on_collision = true,
	},
}

local place_visualisation = {
	filename = "__core__/graphics/cursor-boxes-32x32.png",
	priority = "extra-high-no-scale",
	width = 64,
	height = 64,
	scale = 0.5,
	x = 3 * 64,
}

--docking port
local docking_port = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
docking_port.sprites = make_4way_animation_from_spritesheet({
	layers = {
		{
			scale = 0.5,
			filename = "__TFMG-platform-docking__/graphics/docking-port-controller.png",
			width = 114,
			height = 102,
		},
		{
			scale = 0.5,
			filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
			width = 98,
			height = 66,
			shift = util.by_pixel(8.5, 1.5),
			draw_as_shadow = true,
		},
	},
})
docking_port.name = "TFMG-docking-port"
docking_port.minable = { mining_time = 0.1, result = "TFMG-docking-port" }
docking_port.tile_buildability_rules = connector_buildability_rules
docking_port.placeable_position_visualization = place_visualisation
docking_port.collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }
--docking_port.collision_mask = { layers = {is_lower_object=true, is_object=true, transport_belt=true}}

data:extend({
	docking_port, --docking port entity
	{ --hidden simple entity
		type = "simple-entity-with-owner",
		name = "TFMG-dock-collider",
		collision_box = { { -1.5, -50 }, { 1.5, 0.4 } },
		tile_buildability_rules = connector_buildability_rules,
		placeable_position_visualization = place_visualisation,
		collision_mask = { layers = {} },
		hidden = true,
		hidden_in_factoriopedia = true,
		flags = { "not-on-map" },
	},
	{ --docking port item
		type = "item",
		name = "TFMG-docking-port",
		icon = "__TFMG-platform-docking__/graphics/docking-port-controller-icon.png",
		subgroup = "space-related",
		order = "k-a",
		inventory_move_sound = item_sounds.wood_inventory_move,
		pick_sound = item_sounds.wood_inventory_pickup,
		drop_sound = item_sounds.wood_inventory_move,
		place_result = "TFMG-docking-port",
		stack_size = 50,
		weight = TFMG_util.rocket_capacity(50),
		hidden = false,
	},
	{ --docking belt item
		type = "item",
		name = "TFMG-docking-belt",
		icon = "__base__/graphics/icons/linked-belt.png",
		hidden = false,
		subgroup = "space-related",
		order = "k-b",
		inventory_move_sound = item_sounds.mechanical_inventory_move,
		pick_sound = item_sounds.mechanical_inventory_pickup,
		drop_sound = item_sounds.mechanical_inventory_move,
		place_result = "TFMG-docking-belt",
		stack_size = 50,
		weight = TFMG_util.rocket_capacity(50),
	},
	{--docking pipe item
		type = "item",
		name = "TFMG-docking-pipe",
		icon = "__TFMG-platform-docking__/graphics/docking-pipe.png",
		subgroup = "space-related",
		order = "k-c",
		inventory_move_sound = item_sounds.metal_small_inventory_move,
		pick_sound = item_sounds.metal_small_inventory_pickup,
		drop_sound = item_sounds.metal_small_inventory_move,
		place_result = "TFMG-docking-pipe",
		stack_size = 50,
		weight = TFMG_util.rocket_capacity(50),
		random_tint_color = item_tints.iron_rust,
	},
	{ --docking radar item
		type = "item",
		name = "TFMG-docking-radar",
		icon = "__TFMG-platform-docking__/graphics/docking-radar-icon.png",
		hidden = false,
		subgroup = "space-related",
		order = "k-d",
		inventory_move_sound = item_sounds.mechanical_inventory_move,
		pick_sound = item_sounds.mechanical_inventory_pickup,
		drop_sound = item_sounds.mechanical_inventory_move,
		place_result = "TFMG-docking-radar",
		stack_size = 50,
		weight = TFMG_util.rocket_capacity(50),
	},
	{ --docking belt
		type = "linked-belt",
		name = "TFMG-docking-belt",
		icon = "__base__/graphics/icons/linked-belt.png",
		flags = { "placeable-neutral", "player-creation" },
		hidden = true,
		minable = { mining_time = 0.1, result = "TFMG-docking-belt" },
		max_health = 160,
		corpse = "underground-belt-remnants",
		dying_explosion = "underground-belt-explosion",
		open_sound = sounds.machine_open,
		close_sound = sounds.machine_close,
		working_sound = data.raw["underground-belt"]["underground-belt"].working_sound,
		resistances = data.raw["underground-belt"]["underground-belt"].resistances,
		collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } },
		selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		--collision_mask = { layers = {is_lower_object=true, is_object=true, transport_belt=true}},
		--tile_buildability_rules = connector_buildability_rules, --somethings off with this.
		surface_conditions = { { property = "gravity", min = 0, max = 0 } },
		placeable_position_visualization = place_visualisation,
		damaged_trigger_effect = hit_effects.entity(),
		--animation_speed_coefficient = 32,
		--belt_animation_set = basic_belt_animation_set,
		fast_replaceable_group = "docking-belts",
		speed = 0.03125,
		structure_render_layer = "object",
		structure = {
			direction_in = {
				sheet = {
					filename = "__base__/graphics/entity/linked-belt/linked-belt-structure.png",
					priority = "extra-high",
					width = 192,
					height = 192,
					y = 192,
					scale = 0.5,
				},
			},
			direction_out = {
				sheet = {
					filename = "__base__/graphics/entity/linked-belt/linked-belt-structure.png",
					priority = "extra-high",
					width = 192,
					height = 192,
					scale = 0.5,
				},
			},
			direction_in_side_loading = {
				sheet = {
					filename = "__base__/graphics/entity/linked-belt/linked-belt-structure.png",
					priority = "extra-high",
					width = 192,
					height = 192,
					y = 192 * 3,
					scale = 0.5,
				},
			},
			direction_out_side_loading = {
				sheet = {
					filename = "__base__/graphics/entity/linked-belt/linked-belt-structure.png",
					priority = "extra-high",
					width = 192,
					height = 192,
					y = 192 * 2,
					scale = 0.5,
				},
			},
			back_patch = data.raw["underground-belt"]["underground-belt"].structure.back_patch,
			front_patch = data.raw["underground-belt"]["underground-belt"].structure.front_patch,
		},
		allow_side_loading = false,
	},
	{--docking pipe entity
		type = "pipe-to-ground",
		name = "TFMG-docking-pipe",
		icon = "__TFMG-platform-docking__/graphics/docking-pipe.png",
		flags = { "placeable-neutral", "player-creation" },
		minable = { mining_time = 0.1, result = "TFMG-docking-pipe" },
		max_health = 150,
		corpse = "pipe-to-ground-remnants",
		dying_explosion = "pipe-to-ground-explosion",
		--factoriopedia_simulation = simulations.factoriopedia_pipe_to_ground,
		icon_draw_specification = { scale = 0.5 },
		resistances = {
			{
				type = "fire",
				percent = 80,
			},
			{
				type = "impact",
				percent = 40,
			},
		},
		fast_replaceable_group = "docking-pipes",
		collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } },
		selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		--collision_mask = { layers = {is_lower_object=true, is_object=true, transport_belt=true}},
		tile_buildability_rules = connector_buildability_rules_pipe,
		surface_conditions = { { property = "gravity", min = 0, max = 0 } },
		damaged_trigger_effect = hit_effects.entity(),
		fluid_box = {
			volume = 100,
			pipe_covers = pipecoverspictures(),
			pipe_connections = {
				{
					connection_type = "normal",
					direction = defines.direction.north,
					position = { 0, 0 },
				},
				{
					connection_type = "linked",
					direction = defines.direction.south,
					position = { 0, 0 },
					linked_connection_id = 1,
				},
			},
			hide_connection_info = true,
		},
		impact_category = "metal",
		working_sound = sounds.pipe,
		open_sound = sounds.metal_small_open,
		close_sound = sounds.metal_small_close,
		pictures = {
			north = {
				filename = "__TFMG-platform-docking__/graphics/pipe-to-ground-up.png",
				priority = "extra-high",
				width = 128,
				height = 128,
				scale = 0.5,
			},
			south = {
				filename = "__TFMG-platform-docking__/graphics/pipe-to-ground-down.png",
				priority = "extra-high",
				width = 128,
				height = 128,
				scale = 0.5,
			},
			west = {
				filename = "__TFMG-platform-docking__/graphics/pipe-to-ground-left.png",
				priority = "extra-high",
				width = 128,
				height = 128,
				scale = 0.5,
			},
			east = {
				filename = "__TFMG-platform-docking__/graphics/pipe-to-ground-right.png",
				priority = "extra-high",
				width = 128,
				height = 128,
				scale = 0.5,
			},
		},
		visualization = {
			north = {
				filename = "__base__/graphics/entity/pipe-to-ground/visualization.png",
				priority = "extra-high",
				x = 64,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
			south = {
				filename = "__base__/graphics/entity/pipe-to-ground/visualization.png",
				priority = "extra-high",
				x = 192,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
			west = {
				filename = "__base__/graphics/entity/pipe-to-ground/visualization.png",
				priority = "extra-high",
				x = 256,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
			east = {
				filename = "__base__/graphics/entity/pipe-to-ground/visualization.png",
				priority = "extra-high",
				x = 128,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
		},
		disabled_visualization = {
			north = {
				filename = "__base__/graphics/entity/pipe-to-ground/disabled-visualization.png",
				priority = "extra-high",
				x = 64,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
			south = {
				filename = "__base__/graphics/entity/pipe-to-ground/disabled-visualization.png",
				priority = "extra-high",
				x = 192,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
			west = {
				filename = "__base__/graphics/entity/pipe-to-ground/disabled-visualization.png",
				priority = "extra-high",
				x = 256,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
			east = {
				filename = "__base__/graphics/entity/pipe-to-ground/disabled-visualization.png",
				priority = "extra-high",
				x = 128,
				size = 64,
				scale = 0.5,
				flags = { "icon" },
			},
		},
	},
	{ --docking radar entity
		type = "radar",
		name = "TFMG-docking-radar",
		icon = "__TFMG-platform-docking__/graphics/docking-radar-icon.png",
		flags = { "placeable-neutral", "player-creation"},
		hidden = false,
		minable = { mining_time = 0.1, result = "TFMG-docking-radar"},
		max_health = 160,
		corpse = "radar-remnants",   
		dying_explosion = "radar-explosion",
		energy_usage = "0kW",
		energy_per_sector = "0kW",
		energy_per_nearby_scan = "0kW",
		energy_source = {type = "void", usage_priority = "lamp"},
		max_distance_of_sector_revealed = 0,
		max_distance_of_nearby_sector_revealed = 0,
		connects_to_other_radars = false,
		open_sound = sounds.machine_open,
		close_sound = sounds.machine_close,
		collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } },
		selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		surface_conditions = { { property = "gravity", min = 0, max = 0 } },
		damaged_trigger_effect = hit_effects.entity(),
		fast_replaceable_group = "docking-parts",  
		circuit_connector = circuit_connector_definitions["lamp"],
    	circuit_wire_max_distance = default_circuit_wire_max_distance,
		integration_patch =
			{
				filename = "__base__/graphics/entity/radar/radar-integration.png",
				priority = "low",
				width = 238,
				height = 216,
				shift = util.by_pixel(1.5, 4.0),
				scale = 0.5
			},
		pictures =
		{
			layers =
			{
				{
					variation_count = 64,
					filename = "__TFMG-platform-docking__/graphics/docking-radar.png",
					priority = "low",
					width = 196,
					height = 254,
					apply_projection = false,
					direction_count = 64,
					line_length = 8,
					--shift = util.by_pixel(1.0, -16.0),
					scale = 0.15
				},
				{
					filename = "__base__/graphics/entity/radar/radar-shadow.png",
					priority = "low",
					width = 336,
					height = 170,
					apply_projection = false,
					direction_count = 64,
					line_length = 8,
					--shift = util.by_pixel(39.0, 6.0),
					draw_as_shadow = true,
					scale = 0.15
				}
			}
		},
		max_text_width = 400,
		text_shift = util.by_pixel(0, -24),
		icon_draw_specification = {shift = util.by_pixel(0.5, -8), scale = 0.5},
		text_color = {1.0, 1.0, 1.0, 1.0},
		background_color = {0.0, 0.0, 0.0, 0.25}
	},
	--recipe time
	{ --docking controller
		type = "recipe",
		name = "TFMG-docking-port",
		energy_required = 4,
		enabled = false,
		allow_productivity = false,
		ingredients = {
			{ type = "item", name = "constant-combinator", amount = 1 },
			{ type = "item", name = "processing-unit", amount = 8 },
			{ type = "item", name = "steel-plate", amount = 8 },
		},
		results = {
			{ type = "item", name = "TFMG-docking-port", amount = 1 },
		},
	},
	{ --docking radar
		type = "recipe",
		name = "TFMG-docking-radar",
		energy_required = 4,
		enabled = false,
		allow_productivity = false,
		ingredients = {
			{ type = "item", name = "radar", amount = 1 },
			{ type = "item", name = "processing-unit", amount = 8 },
			{ type = "item", name = "steel-plate", amount = 8 },
		},
		results = {
			{ type = "item", name = "TFMG-docking-radar", amount = 1 },
		},
	},
	{ --docking belt
		type = "recipe",
		name = "TFMG-docking-belt",
		energy_required = 4,
		enabled = false,
		allow_productivity = false,
		ingredients = {
			{ type = "item", name = "express-underground-belt", amount = 1 },
			{ type = "item", name = "electric-engine-unit", amount = 4 },
			{ type = "item", name = "low-density-structure", amount = 8 },
		},
		results = {
			{ type = "item", name = "TFMG-docking-belt", amount = 1 },
		},
	},
	{ --docking pipe
		type = "recipe",
		name = "TFMG-docking-pipe",
		energy_required = 4,
		enabled = false,
		allow_productivity = false,
		ingredients = {
			{ type = "item", name = "pipe-to-ground", amount = 1 },
			{ type = "item", name = "electric-engine-unit", amount = 4 },
			{ type = "item", name = "low-density-structure", amount = 8 },
		},
		results = {
			{ type = "item", name = "TFMG-docking-pipe", amount = 1 },
		},
	},
	--technology
	{ --platform-docking
		type = "technology",
		name = "TFMG-platform-docking",
		icons = {
			{ icon = "__space-age__/graphics/technology/space-platform.png", icon_size = 256 },
			{ icon = "__base__/graphics/technology/logistic-system.png", icon_size = 256 },
		},
		icon_size = 256,
		effects = {
			{
				type = "unlock-recipe",
				recipe = "TFMG-docking-port",
			},
			{
				type = "unlock-recipe",
				recipe = "TFMG-docking-pipe",
			},
			{
				type = "unlock-recipe",
				recipe = "TFMG-docking-belt",
			},
			{
				type = "unlock-recipe",
				recipe = "TFMG-docking-radar",
			},
		},
		prerequisites = { "space-science-pack", "logistics-3"},
		unit = {
			count = 500,
			ingredients = {
				{ "automation-science-pack", 1 },
				{ "logistic-science-pack", 1 },
				{ "chemical-science-pack", 1 },
				{ "production-science-pack", 1 },
				{ "space-science-pack", 1 },
			},
			time = 60,
		},
	},
})

