local const          = require("tiny-city.scripts.lib.const")

-- =================================
-- MODULE
-- =================================
local traffic_lights = {}

-- =================================
-- VARS
-- =================================
local light_groups   = {} -- Array of light group configurations
local node_to_group  = {} -- Maps node_id -> group_id for quick lookup
local light_states   = {} -- Current state for each group
local lights         = {
	intersection1 = {
		group1 = {
			[113] = "/intersection_1_group_1_light_1",
			[111] = "/intersection_1_group_1_light_2"
		},
		group2 = {
			[118] = "/intersection_1_group_2_light_1",
			[108] = "/intersection_1_group_2_light_2"
		}
	},
	intersection2 = {
		group1 = {
			[7] = "/intersection_2_group_1_light_1",
			[165] = "/intersection_2_group_1_light_2"
		},
		group2 = {
			[65] = "/intersection_2_group_2_light_1",
			[64] = "/intersection_2_group_2_light_2"
		}
	},
	intersection3 = {
		group1 = {
			[175] = "/intersection_3_group_1_light_1",
			[68] = "/intersection_3_group_1_light_2"
		},
		group2 = {
			[22] = "/intersection_3_group_2_light_1",
			[20] = "/intersection_3_group_2_light_2"
		}
	},
}

local function set_light_tint(light, state)
	if state == const.TRAFFIC_LIGHT_STATE.GREEN then
		go.set(light.green, "tint", const.COLORS.GREEN)
		go.set(light.yellow, "tint", const.COLORS.DARK_GRAY)
		go.set(light.red, "tint", const.COLORS.DARK_GRAY)
	elseif state == const.TRAFFIC_LIGHT_STATE.YELLOW then
		go.set(light.green, "tint", const.COLORS.DARK_GRAY)
		go.set(light.yellow, "tint", const.COLORS.YELLOW)
		go.set(light.red, "tint", const.COLORS.DARK_GRAY)
	elseif state == const.TRAFFIC_LIGHT_STATE.RED then
		go.set(light.green, "tint", const.COLORS.DARK_GRAY)
		go.set(light.yellow, "tint", const.COLORS.DARK_GRAY)
		go.set(light.red, "tint", const.COLORS.RED)
	else
		go.set(light.green, "tint", const.COLORS.DARK_GRAY)
		go.set(light.yellow, "tint", const.COLORS.DARK_GRAY)
		go.set(light.red, "tint", const.COLORS.DARK_GRAY)
	end
end

function traffic_lights.init()
	light_groups = {}
	node_to_group = {}
	light_states = {}

	for intersection, groups in pairs(lights) do
		traffic_lights.add_intersection(intersection, groups.group1, groups.group2, 5.0)
	end
end

function traffic_lights.add_group(group_id, nodes, initial_state)
	local node_keys = {}
	local lights = {}
	for i, v in pairs(nodes) do
		table.insert(node_keys, i)

		local green = msg.url(v)
		green.fragment = 'green'

		local yellow = msg.url(v)
		yellow.fragment = 'yellow'

		local red = msg.url(v)
		red.fragment = 'red'

		local light = {
			green = green,
			yellow = yellow,
			red = red
		}

		-- Initialize all lights to dark (off)
		set_light_tint(light, nil)

		table.insert(lights, i, light)
	end

	light_groups[group_id] = {
		nodes = node_keys,
		lights = lights,
		state = initial_state or const.TRAFFIC_LIGHT_STATE.RED
	}

	light_states[group_id] = initial_state or const.TRAFFIC_LIGHT_STATE.RED

	for _, node_id in ipairs(node_keys) do
		node_to_group[node_id] = group_id
	end
end

function traffic_lights.add_intersection(intersection_id, group1_nodes, group2_nodes, cycle_time)
	local group1_id = intersection_id .. "_group1"
	local group2_id = intersection_id .. "_group2"

	-- Create the two groups with opposite initial states
	traffic_lights.add_group(group1_id, group1_nodes, const.TRAFFIC_LIGHT_STATE.GREEN)
	traffic_lights.add_group(group2_id, group2_nodes, const.TRAFFIC_LIGHT_STATE.RED)

	-- initial light colors
	for _, light in pairs(light_groups[group1_id].lights) do
		set_light_tint(light, const.TRAFFIC_LIGHT_STATE.GREEN)
	end

	for _, light in pairs(light_groups[group2_id].lights) do
		set_light_tint(light, const.TRAFFIC_LIGHT_STATE.RED)
	end

	-- Flag to prevent overlapping transitions
	local transitioning = false

	-- Set up timer to alternate the lights
	timer.delay(cycle_time, true, function()
		-- Skip if already transitioning
		if transitioning then
			print("Skipping cycle - transition in progress")
			return
		end

		-- Swap the states
		local group1_state = light_states[group1_id]
		local group2_state = light_states[group2_id]

		if group1_state == const.TRAFFIC_LIGHT_STATE.GREEN then
			-- Group 1: GREEN -> YELLOW (transition)
			transitioning = true
			light_states[group1_id] = const.TRAFFIC_LIGHT_STATE.YELLOW
			light_groups[group1_id].state = const.TRAFFIC_LIGHT_STATE.YELLOW

			for _, light in pairs(light_groups[group1_id].lights) do
				set_light_tint(light, const.TRAFFIC_LIGHT_STATE.YELLOW)
			end

			timer.delay(1.0, false, function()
				light_states[group1_id] = const.TRAFFIC_LIGHT_STATE.RED
				light_groups[group1_id].state = const.TRAFFIC_LIGHT_STATE.RED

				for _, light in pairs(light_groups[group1_id].lights) do
					set_light_tint(light, const.TRAFFIC_LIGHT_STATE.RED)
				end

				-- Set group 2 to YELLOW first (RED -> YELLOW transition)
				light_states[group2_id] = const.TRAFFIC_LIGHT_STATE.YELLOW
				light_groups[group2_id].state = const.TRAFFIC_LIGHT_STATE.YELLOW

				for _, light in pairs(light_groups[group2_id].lights) do
					set_light_tint(light, const.TRAFFIC_LIGHT_STATE.YELLOW)
				end

				timer.delay(1.0, false, function()
					light_states[group2_id] = const.TRAFFIC_LIGHT_STATE.GREEN
					light_groups[group2_id].state = const.TRAFFIC_LIGHT_STATE.GREEN

					for i, light in pairs(light_groups[group2_id].lights) do
						set_light_tint(light, const.TRAFFIC_LIGHT_STATE.GREEN)
					end

					transitioning = false
				end)
			end)
		elseif group2_state == const.TRAFFIC_LIGHT_STATE.GREEN then
			-- Group 2: GREEN -> YELLOW (transition)
			transitioning = true
			light_states[group2_id] = const.TRAFFIC_LIGHT_STATE.YELLOW
			light_groups[group2_id].state = const.TRAFFIC_LIGHT_STATE.YELLOW

			for _, light in pairs(light_groups[group2_id].lights) do
				set_light_tint(light, const.TRAFFIC_LIGHT_STATE.YELLOW)
			end

			timer.delay(1.0, false, function()
				light_states[group2_id] = const.TRAFFIC_LIGHT_STATE.RED
				light_groups[group2_id].state = const.TRAFFIC_LIGHT_STATE.RED

				for _, light in pairs(light_groups[group2_id].lights) do
					set_light_tint(light, const.TRAFFIC_LIGHT_STATE.RED)
				end

				-- Set group 1 to YELLOW first (RED -> YELLOW transition)
				light_states[group1_id] = const.TRAFFIC_LIGHT_STATE.YELLOW
				light_groups[group1_id].state = const.TRAFFIC_LIGHT_STATE.YELLOW

				for _, light in pairs(light_groups[group1_id].lights) do
					set_light_tint(light, const.TRAFFIC_LIGHT_STATE.YELLOW)
				end

				timer.delay(1.0, false, function()
					light_states[group1_id] = const.TRAFFIC_LIGHT_STATE.GREEN
					light_groups[group1_id].state = const.TRAFFIC_LIGHT_STATE.GREEN

					for i, light in pairs(light_groups[group1_id].lights) do
						set_light_tint(light, const.TRAFFIC_LIGHT_STATE.GREEN)
					end

					transitioning = false
				end)
			end)
		end
	end)
end

function traffic_lights.add_t_intersection(intersection_id, single_node_ids, pair_node_ids, cycle_time)
	traffic_lights.add_intersection(intersection_id, single_node_ids, pair_node_ids, cycle_time)
end

function traffic_lights.check_state(node_id)
	local group_id = node_to_group[node_id]
	if not group_id then
		return nil -- No traffic light at this node
	end

	return light_states[group_id]
end

-- Get all light groups
function traffic_lights.get_groups()
	return light_groups
end

-- Get current states
function traffic_lights.get_states()
	return light_states
end

return traffic_lights
