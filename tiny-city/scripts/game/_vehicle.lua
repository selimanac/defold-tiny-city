local const     = require("tiny-city.scripts.lib.const")
local data      = require("tiny-city.scripts.lib.data")
local collision = require("tiny-city.scripts.lib.collision")


-- =================================
-- MODULE
-- =================================
local vehicles = {}


local vehicle_id = 0


function vehicles.add(start_node_id, goal_node_id, type)
	local path_size = 0
	local path_status = 0
	local path_status_text = ""
	local path = {}

	-- Get unsmoothed path (node-to-node) for raycasting and collision detection
	path_size, path_status, path_status_text, path = pathfinder.find_node_to_node(start_node_id, goal_node_id, 32)

	if path_status ~= pathfinder.PathStatus.SUCCESS then
		print(path_status_text)
		return
	end

	-- Get return path to create a loop (vehicle will go back and forth)
	local second_path_size, second_path_status, second_path_status_text, second_path = pathfinder.find_node_to_node(goal_node_id, start_node_id, 32)

	local total_path_size = path_size + second_path_size

	-- Combine both paths for continuous looping
	for _, v in ipairs(second_path) do
		path[#path + 1] = v
	end

	-- Generate smoothed path for natural vehicle movement (uses Bezier curves)
	local smoothed_size, smoothed_path = pathfinder.smooth_path(data.path_smoothing_id, path)

	-- Calculate initial position and rotation
	--	local agent_position_v2            = pathfinder.get_node_position(start_node_id)
	local agent_position               = vmath.vector3(path[1].x, 0, path[1].y)

	--	local target_pos_v2                = pathfinder.get_node_position(0)
	local target_pos                   = vmath.vector3(path[2].x, 0, path[2].y)
	local to_target                    = target_pos - agent_position
	local target_rotation              = math.atan2(to_target.x, to_target.z)
	local initial_rotation             = vmath.quat_rotation_y(target_rotation)

	-- Spawn the vehicle game object
	local vehicle_instance             = factory.create(type.FACTORY, agent_position, initial_rotation)

	-- Create collision bounding box (AABB) for this vehicle
	vehicle_id                         = vehicle_id + 1
	local aabb_id                      = collision.insert_gameobject(vehicle_instance, 0.4, 1, 0.4, collision.COLLISION_BITS.VEHICLE)

	local vehicle_agent                = {
		uuid                 = uuid4.generate(),
		position             = agent_position,
		max_speed            = type.MAX_SPEED,
		rotation_speed       = type.ROTATION_SPEED,
		speed                = type.SPEED,
		rotation             = initial_rotation,
		rotation_angle       = 0,
		-- Original path (unsmoothed) for raycasting to nodes
		path                 = path,
		path_size            = total_path_size,
		path_start_node_id   = start_node_id,
		path_end_node_id     = goal_node_id,
		current_waypoint_id  = 1, -- For raycasting to next node
		-- Smoothed path for vehicle movement
		smoothed_path        = smoothed_path,
		smoothed_path_size   = smoothed_size,
		smoothed_waypoint_id = 1, -- For smooth movement
		instance             = vehicle_instance,
		state                = const.AGENT_STATES.ACTIVE,
		aabb_id              = aabb_id,
		type                 = type,
		-- Brake and throttle system
		throttle             = 0.0, -- 0.0 to 1.0
		brake                = 0.0, -- 0.0 to 1.0
		acceleration_rate    = type.ACCELERATION_RATE,
		brake_rate           = type.BRAKE_RATE,
		target_speed         = type.SPEED,
		previous_direction   = vmath.vector3(),
		-- Reservation system
		reserved_node_id     = nil -- ID of the node this vehicle has reserved
	}

	table.insert(data.vehicles, vehicle_id, vehicle_agent)
	table.insert(data.lookup.aabb_to_vehicle, aabb_id, vehicle_id)
end

return vehicles
