local traffic_lights              = require "tiny-city.scripts.game.traffic_lights"
local vehicles                    = require("tiny-city.scripts.game.vehicles")
local const                       = require("tiny-city.scripts.lib.const")
local data                        = require("tiny-city.scripts.lib.data")
local collision                   = require("tiny-city.scripts.lib.collision")

-- =================================
-- MODULE
-- =================================
local traffic                     = {}

-- =================================
-- VARS
-- =================================
local target_waypoint_position    = vmath.vector3()
local traffic_light_node_position = vmath.vector3()
local next_node_position          = vmath.vector3()

local raycasts_to_perform         = {}
local raycast                     = {
	current = vmath.vector3(),
	next = vmath.vector3(),
	ahead = vmath.vector3()
}

function traffic.init()
	const.CAMERA = msg.url("/game_camera#camera")
	traffic_lights.init()
	vehicles.init()
end

function traffic.update(dt)
	for i = 1, vehicles.count do
		local vehicle_id = data.lookup.vehicle_list[i]
		local vehicle = data.vehicles[vehicle_id]

		if vehicle.state == const.VEHICLE_STATE.ACTIVE then
			-- Check if agent reached current waypoint on smoothed path
			if not vehicles.check_waypoint(vehicle) or vehicle.state ~= const.VEHICLE_STATE.ARRIVED then
				vehicles.get_current_waypoint_position(vehicle, target_waypoint_position)

				-- =================================
				-- OBSTACLE TRACKING
				local distance_to_obstacle = nil
				local target_vehicle_speed = vehicle.max_speed
				local closest_vehicle      = nil
				local closest_distance     = const.HUGE

				-- =================================
				-- RAYCAST
				-- Calculate direction and distance to target
				local target_direction     = target_waypoint_position - vehicle.position
				local distance             = vmath.length(target_direction)
				local raycast_start        = vehicle.position

				-- Calculate raycast start position from front of vehicle
				if distance > const.EPSILON then
					local direction_normalized = target_direction * (1.0 / distance)
					raycast_start = vehicle.position + (direction_normalized * const.VEHICLE_CONTROL.RAYCAST_FORWARD_OFFSET)
				end

				-- Current waypoint node
				vehicles.get_raycast_target_position(vehicle, 0, raycast.current)
				-- Next waypoint node
				vehicles.get_raycast_target_position(vehicle, 1, raycast.next)
				-- Second next node (for very fast vehicles)
				vehicles.get_raycast_target_position(vehicle, 2, raycast.ahead)

				raycasts_to_perform = {}

				if raycast.current then
					table.insert(raycasts_to_perform, {
						from = raycast_start,
						target = raycast.current
					})
				end

				if vehicle.speed > const.SPEED_LIMITS.MID then
					if raycast.next then
						table.insert(raycasts_to_perform, {
							from = raycast.current,
							target = raycast.next
						})
					end
				end

				-- Add extended look-ahead for very fast vehicles
				if vehicle.speed > const.SPEED_LIMITS.HIGH then
					if raycast.ahead then
						table.insert(raycasts_to_perform, {
							from = raycast.next,
							target = raycast.ahead
						})
					end
				end

				-- RAYCAST TO TARGETS
				for ray_id = 1, #raycasts_to_perform do
					local raycast_info = raycasts_to_perform[ray_id]
					local ray_result, ray_result_count = collision.raycast(raycast_info.from, raycast_info.target, collision.COLLISION_BITS.VEHICLE, true)

					if ray_result then
						for ray_result_id = 1, ray_result_count do
							local ray_target_vehicle = ray_result[ray_result_id]

							if ray_target_vehicle.id ~= vehicle.aabb_id and ray_target_vehicle.distance < closest_distance then
								local target_vehicle = vehicles.get_vehicle_from_aabb(ray_target_vehicle.id)

								if target_vehicle then
									local should_brake = true

									if vehicle.previous_direction and vmath.length(vehicle.previous_direction) > 0.1
										and target_vehicle.previous_direction and vmath.length(target_vehicle.previous_direction) > 0.1 then
										-- dot = 1: same direction, dot = -1: opposite, dot = 0: perpendicular
										local dot_product = vmath.dot(vmath.normalize(vehicle.previous_direction), vmath.normalize(target_vehicle.previous_direction))

										-- Check for opposite direction traffic
										if dot_product < const.VEHICLE_CONTROL.OPPOSITE_DIRECTION_THRESHOLD then
											-- Vehicles moving in opposite directions
											-- Only brake if very close (potential head-on collision)
											if ray_target_vehicle.distance > const.VEHICLE_CONTROL.OPPOSITE_DIRECTION_BREAK_THRESHOLD then
												should_brake = false
											end
											-- Check for crossing/perpendicular traffic
										elseif dot_product < const.VEHICLE_CONTROL.CROSSING_DOT_THRESHOLD
											and ray_target_vehicle.distance < const.VEHICLE_CONTROL.CROSSING_DISTANCE then
											-- Vehicle is crossing our path - brake more aggressively
											-- Reduce effective distance to trigger earlier braking
											closest_distance = ray_target_vehicle.distance * const.VEHICLE_CONTROL.CROSSING_BRAKE_MULTIPLIER
											closest_vehicle = target_vehicle
										end
									end

									if should_brake then
										closest_distance = ray_target_vehicle.distance
										closest_vehicle = target_vehicle
									end
								end
							end
						end
					end
				end

				-- Set obstacle info if we found a vehicle
				if closest_vehicle then
					distance_to_obstacle = closest_distance
					target_vehicle_speed = closest_vehicle.speed
				end

				-- =================================
				-- RESERVATION

				local is_node_reserved, reserved_node_distance = vehicles.is_next_node_reserved(vehicle, vehicle_id)

				if is_node_reserved and reserved_node_distance then
					-- Next node is reserved by another vehicle - brake for it
					-- Treat reserved node as an obstacle
					if not distance_to_obstacle or reserved_node_distance < distance_to_obstacle then
						distance_to_obstacle = reserved_node_distance
						target_vehicle_speed = 0 -- Stop for reserved node
					end
				else
					-- Try to reserve the next node if not already reserved
					local next_node_id = vehicles.get_node_id_at_waypoint(vehicle, 0)
					if next_node_id and not vehicle.reserved_node_id then
						-- Reserve the node immediately - no distance check needed

						local traffic_light_state = traffic_lights.check_state(next_node_id)
						if traffic_light_state == nil then
							vehicles.reserve_node(vehicle, vehicle_id, next_node_id)
						end
					end
				end

				-- =================================
				-- TRAFFIC LIGHTS
				local check_node_id = vehicles.get_node_id_at_waypoint(vehicle, 0)

				if check_node_id then
					local traffic_light_state = traffic_lights.check_state(check_node_id)

					if traffic_light_state == const.TRAFFIC_LIGHT_STATE.RED then
						-- There's a red light ahead - calculate distance and treat as obstacle

						vehicles.get_raycast_target_position(vehicle, 0, traffic_light_node_position)

						if traffic_light_node_position then
							local distance_to_light = vmath.length(vehicle.position - traffic_light_node_position)
							-- Only stop for the light if we haven't already passed it
							if distance_to_light > 0.1 then
								-- Treat red light as an obstacle requiring a full stop
								if not distance_to_obstacle or distance_to_light < distance_to_obstacle then
									distance_to_obstacle = distance_to_light
									target_vehicle_speed = 0 -- Must stop at red light
								end
							end
						end
					end
				end

				-- Calculate appropriate throttle/brake based on obstacle distance
				vehicles.calculate_throttle_brake(vehicle, distance_to_obstacle, target_vehicle_speed)

				-- Apply speed
				vehicles.set_speed(vehicle, dt)

				if distance >= const.EPSILON then
					local direction = target_direction * (1.0 / distance)

					if vehicle.speed > const.VEHICLE_CONTROL.ROTATION_SPEED_THRESHOLD then
						local target_angle     = math.atan2(direction.x, direction.z)
						local target_rotation  = vmath.quat_rotation_y(target_angle)
						local current_rotation = vehicle.rotation
						local t                = math.min(1.0, vehicle.rotation_speed * dt)

						vehicle.rotation       = vmath.slerp(t, current_rotation, target_rotation)
						vehicle.rotation_angle = target_angle -- For reference
						go.set_rotation(vehicle.rotation, vehicle.instance)
					end

					-- Calculate movement for this frame and clamp
					local movement_distance    = math.min(vehicle.speed * dt, distance)

					vehicle.position           = vehicle.position + (direction * movement_distance)
					vehicle.position.y         = 0.0

					-- Store direction for crossing detection
					vehicle.previous_direction = direction * vehicle.speed

					go.set_position(vehicle.position, vehicle.instance)


					-- Check if we need to advance to next node

					if vehicle.current_waypoint_id <= vehicle.path_size then
						vehicles.get_raycast_target_position(vehicle, 0, next_node_position)

						local node_distance = vmath.length(vehicle.position - next_node_position)
						--	print(vehicle.current_waypoint_id, node_distance, next_node_position)
						if node_distance <= const.VEHICLE_CONTROL.ARRIVAL_THRESHOLD then -- Close enough to node
							-- Release reservation for the node we just reached
							vehicles.release_node_reservation(vehicle, vehicle_id)
							vehicle.current_waypoint_id = vehicle.current_waypoint_id + 1
							--print(vehicle.current_waypoint_id)
						end
					end
				end
			else
				-- Vehicle reached destination, reset to loop the path
				vehicles.release_node_reservation(vehicle, vehicle_id)
				vehicle.state = const.VEHICLE_STATE.ACTIVE
				vehicle.current_waypoint_id = 1
				vehicle.smoothed_waypoint_id = 1
			end
		end
	end
end

return traffic
