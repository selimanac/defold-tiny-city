local data                = require("tiny-city.scripts.lib.data")
local const               = require("tiny-city.scripts.lib.const")

local plane               = {}

local container           = msg.url()
local prop                = msg.url()

local smooth_path         = {} -- Pre-calculated smooth path
local path_length         = 0
local path_progress       = 0

local position            = vmath.vector3()
local rotation            = vmath.quat()
local current_bank        = 0
local previous_yaw        = 0
local smoothed_turn_rate  = 0

-- Configuration
local MAX_SPEED           = 0.3
local ROTATION_SPEED      = 10
local BANK_SPEED          = 13.8
local MAX_BANK_ANGLE      = math.rad(35)
local BANK_SENSITIVITY    = 13.8
local SAMPLES_PER_SEGMENT = 16  -- Adjust for smoothness vs memory
local TURN_RATE_SMOOTHING = 0.8 -- Lower = smoother, higher = more responsive


-- TODO: Cleanup this shit
local function catmull_rom_point(p0, p1, p2, p3, t)
	local t2 = t * t
	local t3 = t2 * t

	return vmath.vector3(
		0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t +
			(2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
			(-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
		0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t +
			(2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
			(-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
		0.5 * ((2 * p1.z) + (-p0.z + p2.z) * t +
			(2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2 +
			(-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3)
	)
end

local function build_smooth_path(control_points, samples_per_segment)
	local path = {}
	local num_segments = #control_points

	for segment = 0, num_segments - 1 do
		local p0 = control_points[((segment - 1) % num_segments) + 1]
		local p1 = control_points[(segment % num_segments) + 1]
		local p2 = control_points[((segment + 1) % num_segments) + 1]
		local p3 = control_points[((segment + 2) % num_segments) + 1]

		for i = 0, samples_per_segment - 1 do
			local t = i / samples_per_segment
			table.insert(path, catmull_rom_point(p0, p1, p2, p3, t))
		end
	end

	return path
end

local function get_path_point(progress)
	-- Get two surrounding points
	local idx1 = math.floor(progress)
	local idx2 = idx1 + 1

	-- Wrap indices
	idx1 = (idx1 % path_length) + 1
	idx2 = (idx2 % path_length) + 1

	-- Interpolate between points
	local t = progress - math.floor(progress)
	return vmath.lerp(t, smooth_path[idx1], smooth_path[idx2])
end

local function normalize_angle(angle)
	while angle > math.pi do angle = angle - 2 * math.pi end
	while angle < -math.pi do angle = angle + 2 * math.pi end
	return angle
end

function plane.init()
	-- Load control points
	local control_points = {}
	for i = 1, 6 do
		table.insert(control_points, go.get_position("/path_node_" .. i))
	end

	-- Pre-calculate smooth path ONCE
	smooth_path = build_smooth_path(control_points, SAMPLES_PER_SEGMENT)
	path_length = #smooth_path

	print("Plane: Pre-calculated " .. path_length .. " smooth path points")

	-- Initial position and rotation
	position = vmath.vector3(smooth_path[1])
	local forward = vmath.normalize(smooth_path[2] - smooth_path[1])

	local yaw = math.atan2(forward.x, forward.z)
	rotation = vmath.quat_rotation_y(yaw)
	previous_yaw = yaw

	-- Spawn plane
	local plane_urls = collectionfactory.create("/vehicles/factories#plane", position, rotation)

	container = msg.url(plane_urls[hash("/container")])
	prop = msg.url(plane_urls[hash("/plane_prop")])

	go.animate(prop, "euler.z", go.PLAYBACK_LOOP_FORWARD, 360, go.EASING_LINEAR, 0.2)

	local plane_camera = msg.url(plane_urls[hash("/plane_camera")])
	plane_camera.fragment = "plane_camera"
	data.cameras["PLANE_CAMERA"] = plane_camera
	msg.post(data.cameras["PLANE_CAMERA"], "disable")

	path_progress = 0
end

function plane.update(dt)
	-- Move along path (progress is in indices now, not segments)
	local speed_factor = (MAX_SPEED / 10.0) * path_length
	path_progress = path_progress + speed_factor * dt

	-- Loop smoothly
	if path_progress >= path_length then
		path_progress = path_progress - path_length
	end

	-- Get current position with interpolation
	local current_pos = get_path_point(path_progress)

	-- Look ahead for direction
	local lookahead_distance = 3.0 -- In indices
	local next_progress = path_progress + lookahead_distance
	if next_progress >= path_length then
		next_progress = next_progress - path_length
	end
	local next_pos = get_path_point(next_progress)

	-- Calculate direction
	local direction = next_pos - current_pos
	local dir_len = vmath.length(direction)

	if dir_len > const.EPSILON then
		direction = direction / dir_len

		-- Calculate target yaw
		local target_yaw = math.atan2(direction.x, direction.z)

		-- Calculate angular velocity (turn rate) with normalization
		local yaw_delta = normalize_angle(target_yaw - previous_yaw)
		local instantaneous_turn_rate = yaw_delta / dt

		-- Smooth the turn rate to eliminate jitter
		local turn_rate_t = math.min(1.0, TURN_RATE_SMOOTHING * dt)
		smoothed_turn_rate = smoothed_turn_rate + (instantaneous_turn_rate - smoothed_turn_rate) * turn_rate_t

		-- Calculate target bank from smoothed turn rate
		local target_bank = -smoothed_turn_rate * BANK_SENSITIVITY * dt * 1.0
		target_bank = math.max(-MAX_BANK_ANGLE, math.min(MAX_BANK_ANGLE, target_bank))

		-- Smooth banking
		local bank_t = math.min(1.0, BANK_SPEED * dt)
		current_bank = current_bank + (target_bank - current_bank) * bank_t

		-- Apply rotation (yaw first, then bank)
		local target_quat = vmath.quat_rotation_y(target_yaw)
		local t = math.min(1.0, ROTATION_SPEED * dt)
		local base_rotation = vmath.slerp(t, rotation, target_quat)

		local bank_quat = vmath.quat_rotation_z(current_bank)
		rotation = base_rotation * bank_quat

		previous_yaw = target_yaw
	end

	-- Update transform
	position = current_pos
	go.set_position(position, container)
	go.set_rotation(rotation, container)
end

return plane
