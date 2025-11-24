local data            = require("graph_editor.scripts.editor_data")
local const           = require("graph_editor.scripts.editor_const")

-- =======================================
-- MODULE
-- =======================================
local agents          = {}

-- =======================================
-- VARIABLES
-- =======================================
local agent_container = {}
local EPSILON         = 0.0001
local agent_states    = {
	INACTIVE   = 0, -- Not in navigation system
	ACTIVE     = 1, -- Following path
	PAUSED     = 2, -- Paused by application
	REPLANNING = 3, -- Detected invalidation, finding new path
	ARRIVED    = 4 -- Reached goal
}

function agents.add()
	local path = data.path[const.AGENT_TO_PATH[data.agent_mode]].path
	local path_status = data.path[const.AGENT_TO_PATH[data.agent_mode]].status

	if path_status ~= pathfinder.PathStatus.SUCCESS then
		data.action_status = const.EDITOR_STATUS.NO_PATH_FOR_AGENT

		timer.delay(1.5, false, function()
			data.action_status = const.EDITOR_STATUS.ADD_AGENT
		end)

		return
	end
	local path_size = data.path[const.AGENT_TO_PATH[data.agent_mode]].size

	local initial_posiiton = vmath.vector3(0.0)

	if data.agent_mode == const.AGEND_MODE.NODE_TO_NODE or data.agent_mode == const.AGEND_MODE.NODE_TO_PROJECTED then
		initial_posiiton.x = path[1].x
		initial_posiiton.z = path[1].y
	end

	if data.agent_mode == const.AGEND_MODE.PROJECTED_TO_NODE then
		initial_posiiton.x = data.mouse_position.x
		initial_posiiton.z = data.mouse_position.z
	end

	if data.agent_mode == const.AGEND_MODE.PROJECTED_TO_PROJECTED then
		initial_posiiton.x = data.options.projected_to_projected.start_position.x
		initial_posiiton.z = data.options.projected_to_projected.start_position.y
	end

	local target_pos_v2 = pathfinder.get_node_position(1)
	local target_pos = vmath.vector3(target_pos_v2.x, 0, target_pos_v2.y)
	local to_target = target_pos - initial_posiiton
	local target_rotation = math.atan2(to_target.x, to_target.z)
	local target_quat = vmath.quat_rotation_y(target_rotation)

	local agent = {
		position            = initial_posiiton,
		velocity            = vmath.vector3(),
		max_speed           = 3.5,
		rotation_speed      = 20.0,
		speed               = 0,
		rotation            = target_quat,
		rotation_angle      = 0,
		path                = path,
		path_size           = path_size,
		current_waypoint_id = 1,
		instance            = factory.create(const.FACTORIES.AGENT, initial_posiiton),
		state               = agent_states.ACTIVE,
		id                  = 0
	}

	table.insert(agent_container, agent)
	agent_container[#agent_container].id = #agent_container

	print("AGEND ADEED: ", agent_container[#agent_container].id)
end

local function get_current_waypoint_position(agent)
	if agent.current_waypoint_id > agent.path_size then
		return agent.position -- No waypoint, stay in place
	end

	local node = agent.path[agent.current_waypoint_id] -- Only for static nodes

	return vmath.vector3(node.x, 0, node.y)
end

local function check_waypoint_arrival(agent)
	if agent.current_waypoint_id > agent.path_size then
		return false -- No more waypoint
	end

	local waypoint_position = get_current_waypoint_position(agent)
	local waypoint_distance = vmath.length(agent.position - waypoint_position)

	-- Simple arrival threshold - very tight for point-to-point movement
	local arrival_threshold = 0.5

	if waypoint_distance <= arrival_threshold then
		--  Reached waypoint, advance to next
		agent.current_waypoint_id = agent.current_waypoint_id + 1

		if agent.current_waypoint_id > agent.path_size then
			agent.state      = agent_states.ARRIVED
			agent.velocity.x = 0
			agent.velocity.y = 0
			agent.speed      = 0
			return true
		end

		return true -- Advanced to next waypoint
	end

	return false --  Not yet arrived
end

local function remove_agent(agent_id, agent)
	agent.state = agent_states.INACTIVE
	go.delete(agent.instance)
	table.remove(agent_container, agent_id)
end

function agents.update(dt)
	for agent_id, agent in ipairs(agent_container) do
		-- Only process active agents
		if agent.state == agent_states.ACTIVE then
			-- Check if agent reached current waypoint
			if not check_waypoint_arrival(agent) or agent.state ~= agent_states.ARRIVED then
				-- Get target waypoint position
				local target_pos = get_current_waypoint_position(agent)

				-- Calculate direction to target
				local to_target = target_pos - agent.position
				local distance = vmath.length(to_target)

				if distance >= EPSILON then
					-- Calculate direction unit vector
					local direction = to_target * (1.0 / distance)

					-- Calculate target rotation angle
					local target_rotation = math.atan2(direction.x, direction.z)
					local target_quat = vmath.quat_rotation_y(target_rotation)

					-- Get current rotation quaternion
					local current_quat = agent.rotation

					local t = math.min(1.0, agent.rotation_speed * dt)
					agent.rotation = vmath.slerp(t, current_quat, target_quat)

					agent.rotation_angle = target_rotation --  for reference (optional)

					-- Calculate movement for this frame and clamp
					local movement_distance = math.min(agent.max_speed * dt, distance)

					agent.position = agent.position + (direction * movement_distance)
					agent.position.y = 0.0
					go.set_position(agent.position, agent.instance)
					go.set_rotation(agent.rotation, agent.instance)

					agent.speed = agent.max_speed
				end
			else
				remove_agent(agent_id, agent)
			end
		else
			remove_agent(agent_id, agent)
		end
	end
end

function agents.get_count()
	return #agent_container
end

return agents
