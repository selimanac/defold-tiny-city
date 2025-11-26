local const                = require("tiny-city.scripts.lib.const")
local data                 = require("tiny-city.scripts.lib.data")
local collision            = require("tiny-city.scripts.lib.collision")

-- =================================
-- MODULE
-- =================================
local vehicles             = {}

-- =================================
-- VARS
-- =================================
vehicles.count             = 0
local target_node_position = vmath.vector3()

local function add(start_node_id, goal_node_id, vehicle_type)
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

	-- Get return path to create a loop
	local second_path_size, second_path_status, second_path_status_text, second_path = pathfinder.find_node_to_node(goal_node_id, start_node_id, 32)

	local total_path_size = path_size + second_path_size

	-- Combine both paths for continuous looping
	for _, v in ipairs(second_path) do
		path[#path + 1] = v
	end

	-- Generate smoothed path
	local smoothed_size, smoothed_path = pathfinder.smooth_path(data.path_smoothing_id, path)

	-- Calculate initial position and rotation
	local vehicle_position             = vmath.vector3(path[1].x, 0, path[1].y)
	local target_position              = vmath.vector3(path[2].x, 0, path[2].y)
	local direction                    = target_position - vehicle_position
	local initial_rotation             = vmath.quat_rotation_y(math.atan2(direction.x, direction.z))
	local vehicle_instance             = factory.create(vehicle_type.FACTORY, vehicle_position, initial_rotation) --msg.url("police_camera") --factory.create(vehicle_type.FACTORY, vehicle_position, initial_rotation)
	local aabb_id                      = collision.insert_gameobject(vehicle_instance, 0.4, 1, 0.4, collision.COLLISION_BITS.VEHICLE)
	vehicles.count                     = vehicles.count + 1

	pprint(vehicle_type.MAX_SPEED)
	local vehicle_agent                  = {
		uuid                 = uuid4.generate(),
		position             = vehicle_position,
		max_speed            = vehicle_type.MAX_SPEED,
		rotation_speed       = vehicle_type.ROTATION_SPEED,
		speed                = vehicle_type.SPEED,
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
		state                = const.VEHICLE_STATE.ACTIVE,
		aabb_id              = aabb_id,
		type                 = vehicle_type,
		-- Brake and throttle system
		throttle             = 0.0, -- 0.0 to 1.0
		brake                = 0.0, -- 0.0 to 1.0
		acceleration_rate    = vehicle_type.ACCELERATION_RATE,
		brake_rate           = vehicle_type.BRAKE_RATE,
		target_speed         = vehicle_type.SPEED,
		previous_direction   = vmath.vector3(),
		-- Reservation system
		reserved_node_id     = nil -- ID of the node this vehicle has reserved
	}
	data.vehicles[vehicle_agent.uuid]    = vehicle_agent
	data.lookup.aabb_to_vehicle[aabb_id] = vehicle_agent.uuid
	table.insert(data.lookup.vehicle_list, vehicle_agent.uuid)
end

function vehicles.init()
	--add(83, 17, const.VEHICLE_TYPE.FIRE)

	add(83, 17, const.VEHICLE_TYPE.VAN)
	add(2, 29, const.VEHICLE_TYPE.AMBULANCE)
	add(3, 20, const.VEHICLE_TYPE.POLICE)
	add(86, 59, const.VEHICLE_TYPE.TAXI)
	add(12, 53, const.VEHICLE_TYPE.FIRE)
	add(65, 21, const.VEHICLE_TYPE.GARBAGE)
	add(18, 63, const.VEHICLE_TYPE.SEDAN)
	add(24, 21, const.VEHICLE_TYPE.SUV)
	add(22, 89, const.VEHICLE_TYPE.SUV_CLASSIC)
	add(57, 7, const.VEHICLE_TYPE.TRUCK)
	add(25, 51, const.VEHICLE_TYPE.VAN)
	add(81, 17, const.VEHICLE_TYPE.AMBULANCE)
	add(77, 8, const.VEHICLE_TYPE.POLICE)
	add(72, 80, const.VEHICLE_TYPE.TAXI)
	add(17, 16, const.VEHICLE_TYPE.VAN)
	add(51, 46, const.VEHICLE_TYPE.TAXI)
	add(33, 18, const.VEHICLE_TYPE.SEDAN)
end

function vehicles.remove(vehicle_id, vehicle)
	-- Release any node reservations before removing
	vehicles.release_node_reservation(vehicle, vehicle_id)
	vehicle.state = cons.VEHICLE_STATE.INACTIVE
	collision.remove(vehicle.aabb_id)
	data.lookup.aabb_to_vehicle[vehicle.aabb_id] = nil

	for i = 1, #data.lookup.vehicle_list do
		if data.lookup.vehicle_list[i] == vehicle_id then
			table.remove(data.lookup.vehicle_list, i)
			break
		end
	end

	go.delete(vehicle.instance)
	table.remove(data.vehicles, vehicle_id)
end

function vehicles.set_speed(vehicle, dt)
	local speed_change = 0

	if vehicle.brake > 0 then
		-- Braking takes priority over throttle
		speed_change = -vehicle.brake * vehicle.brake_rate * dt
	elseif vehicle.throttle > 0 then
		-- Apply throttle only if not braking
		speed_change = vehicle.throttle * vehicle.acceleration_rate * dt
	end

	-- Update speed
	vehicle.speed = vehicle.speed + speed_change

	-- Clamp speed to valid range [0, max_speed]
	vehicle.speed = math.max(0, math.min(vehicle.speed, vehicle.max_speed))
end

-- Determine appropriate throttle/brake based on target speed and distance to obstacle
function vehicles.calculate_throttle_brake(vehicle, distance_to_obstacle, target_vehicle_speed)
	-- Reset
	vehicle.throttle = 0
	vehicle.brake = 0

	local critical_distance = const.VEHICLE_CONTROL.CRITICAL_DISTANCE
	local near_distance = const.VEHICLE_CONTROL.NEAR_DISTANCE
	local medium_distance = const.VEHICLE_CONTROL.MEDIUM_DISTANCE
	local far_distance = const.VEHICLE_CONTROL.FAR_DISTANCE

	if distance_to_obstacle then
		local speed_ratio = vehicle.speed / vehicle.max_speed
		local speed_difference = vehicle.speed - target_vehicle_speed

		local speed_scale = 1.0 + (speed_ratio * 0.5) -- Faster vehicles need more distance
		if speed_difference > 0 then
			speed_scale = speed_scale + (speed_difference * 0.3)
		end

		local adjusted_critical = critical_distance * speed_scale
		local adjusted_near = near_distance * speed_scale
		local adjusted_medium = medium_distance * speed_scale
		local adjusted_far = far_distance * speed_scale

		-- There's an obstacle ahead
		if distance_to_obstacle < adjusted_critical then
			-- Emergency braking
			vehicle.brake = 1.0
			vehicle.target_speed = 0
		elseif distance_to_obstacle < adjusted_near then
			-- Heavy braking - match or slightly slower than vehicle ahead
			vehicle.brake = 0.8
			vehicle.target_speed = math.max(0, target_vehicle_speed * 0.8)
		elseif distance_to_obstacle < adjusted_medium then
			-- Moderate braking
			vehicle.brake = 0.5
			vehicle.target_speed = target_vehicle_speed
		elseif distance_to_obstacle < adjusted_far then
			-- Light braking
			if vehicle.speed > target_vehicle_speed then
				vehicle.brake = 0.3
			end
			vehicle.target_speed = target_vehicle_speed
		else
			-- Far enough - maintain speed or accelerate to max
			vehicle.target_speed = vehicle.max_speed
		end
	else
		-- No obstacle - accelerate to max speed
		vehicle.target_speed = vehicle.max_speed
	end

	-- Apply throttle if current speed is below target speed and not braking
	if vehicle.brake == 0 and vehicle.speed < vehicle.target_speed then
		local speed_difference = vehicle.target_speed - vehicle.speed
		vehicle.throttle = math.min(1.0, speed_difference / vehicle.max_speed)
	end
end

-- Release the reservation on a node
function vehicles.release_node_reservation(vehicle, vehicle_id)
	if vehicle.reserved_node_id then
		-- Only release if we are the one who reserved it
		if data.node_reservations[vehicle.reserved_node_id] == vehicle_id then
			data.node_reservations[vehicle.reserved_node_id] = nil
		end
		vehicle.reserved_node_id = nil
	end
end

-- Try to reserve the next node for this vehicle
-- Returns true if reservation successful, false if node already reserved
function vehicles.reserve_node(vehicle, vehicle_id, node_id)
	if not node_id then
		return false
	end

	-- Check if node is already reserved
	if data.node_reservations[node_id] then
		-- Node is reserved by another vehicle
		if data.node_reservations[node_id] ~= vehicle_id then
			return false
		end
		-- Already reserved by this vehicle
		return true
	end

	-- Reserve the node
	data.node_reservations[node_id] = vehicle_id
	vehicle.reserved_node_id = node_id
	return true
end

-- Get the node ID from the path at a given waypoint index
-- Returns the pathfinder node ID (not the position)
function vehicles.get_node_id_at_waypoint(vehicle, waypoint_offset)
	waypoint_offset = waypoint_offset or 0
	local target_id = vehicle.current_waypoint_id + waypoint_offset

	if target_id > vehicle.path_size or target_id < 1 then
		return nil
	end

	return vehicle.path[target_id].id
end

-- Check if the next node is reserved by another vehicle
-- Returns true if blocked, along with the distance to the reserved node
function vehicles.is_next_node_reserved(vehicle, vehicle_id)
	-- Get the next node we're heading to
	local next_node_id = vehicles.get_node_id_at_waypoint(vehicle, 0)

	if not next_node_id then
		return false, nil
	end

	-- Check if it's reserved by someone else
	local reserving_vehicle_id = data.node_reservations[next_node_id]
	if reserving_vehicle_id and reserving_vehicle_id ~= vehicle_id then
		-- Calculate distance to this node

		vehicles.get_raycast_target_position(vehicle, 0, target_node_position)

		if target_node_position then
			local distance = vmath.length(vehicle.position - target_node_position)
			return true, distance
		end
		return true, nil
	end

	return false, nil
end

function vehicles.get_vehicle_from_aabb(aabb_id)
	local vehicle_id = data.lookup.aabb_to_vehicle[aabb_id]
	return data.vehicles[vehicle_id]
end

-- Get waypoint position from original (unsmoothed) path for raycasting
function vehicles.get_raycast_target_position(vehicle, waypoint_offset, waypoint_position)
	waypoint_offset = waypoint_offset or 0
	local target_id = vehicle.current_waypoint_id + waypoint_offset

	if target_id > vehicle.path_size then
		return nil -- No waypoint available
	end

	local node = vehicle.path[target_id]

	waypoint_position.x = node.x
	waypoint_position.y = 0
	waypoint_position.z = node.y
	--return vmath.vector3(node.x, 0, node.y)
end

-- Get waypoint position from smoothed path for vehicle movement
function vehicles.get_current_waypoint_position(vehicle, waypoint_position)
	if vehicle.smoothed_waypoint_id > vehicle.smoothed_path_size then
		return vehicle.position -- No waypoint, stay in place
	end

	local node = vehicle.smoothed_path[vehicle.smoothed_waypoint_id]

	waypoint_position.x = node.x
	waypoint_position.y = 0
	waypoint_position.z = node.y
	--return vmath.vector3(node.x, 0, node.y)
end

function vehicles.check_waypoint(vehicle)
	if vehicle.smoothed_waypoint_id > vehicle.smoothed_path_size then
		return false -- No more waypoint
	end
	local waypoint_position = vmath.vector3()
	vehicles.get_current_waypoint_position(vehicle, waypoint_position)
	local waypoint_distance = vmath.length(vehicle.position - waypoint_position)

	-- Simple arrival threshold - very tight for point-to-point movement
	if waypoint_distance <= const.VEHICLE_CONTROL.ARRIVAL_THRESHOLD then
		-- Reached waypoint, advance to next
		vehicle.smoothed_waypoint_id = vehicle.smoothed_waypoint_id + 1

		if vehicle.smoothed_waypoint_id > vehicle.smoothed_path_size then
			vehicle.state = const.VEHICLE_STATE.ARRIVED
			return true
		end

		return true -- Advanced to next waypoint
	end

	return false -- Not yet arrived
end

return vehicles
