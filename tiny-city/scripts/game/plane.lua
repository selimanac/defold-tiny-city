local data                = require("tiny-city.scripts.lib.data")
local const               = require("tiny-city.scripts.lib.const")
local audio               = require("tiny-city.scripts.lib.audio")
local game_camera         = require("tiny-city.scripts.lib.game_camera")

-- =================================
-- MODULE
-- =================================
local plane               = {}

-- =================================
-- VARS
-- =================================
local container           = msg.url()
local prop                = msg.url()

-- path
local smooth_path         = {}
local path_length         = 0
local path_progress       = 0

local position            = vmath.vector3()
local rotation            = vmath.quat()
local current_bank        = 0
local previous_yaw        = 0
local smoothed_turn_rate  = 0

-- Settings
local MAX_SPEED           = 0.3
local ROTATION_SPEED      = 10
local BANK_SPEED          = 13.8
local MAX_BANK_ANGLE      = math.rad(35)
local BANK_SENSITIVITY    = 13.8
local SAMPLES_PER_SEGMENT = 32
local TURN_RATE_SMOOTHING = 0.8

-- Lua version based on https://github.com/SeanTyson/luaSplineGeometry/blob/2e3b495158635d3cf26b98ded310d74f1d5bd85e/spline_geometry.lua#L123
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

	idx1 = (idx1 % path_length) + 1
	idx2 = (idx2 % path_length) + 1

	local t = progress - math.floor(progress)
	return vmath.lerp(t, smooth_path[idx1], smooth_path[idx2])
end

local function normalize_angle(angle)
	while angle > math.pi do angle = angle - 2 * math.pi end
	while angle < -math.pi do angle = angle + 2 * math.pi end
	return angle
end

-- TODO: Cleanup this shit
function plane.init()
	-- Load control points
	local control_points = {}
	for i = 1, 6 do
		table.insert(control_points, go.get_position("/path_node_" .. i))
	end

	smooth_path = build_smooth_path(control_points, SAMPLES_PER_SEGMENT)
	path_length = #smooth_path

	position = vmath.vector3(smooth_path[1])
	local forward = vmath.normalize(smooth_path[2] - smooth_path[1])

	local yaw = math.atan2(forward.x, forward.z)
	rotation = vmath.quat_rotation_y(yaw)
	previous_yaw = yaw

	local plane_urls = collectionfactory.create("/vehicles/factories#plane", position, rotation)

	container = msg.url(plane_urls[hash("/container")])
	prop = msg.url(plane_urls[hash("/plane_prop")])

	go.animate(prop, "euler.z", go.PLAYBACK_LOOP_FORWARD, 360, go.EASING_LINEAR, 0.2)

	local plane_camera = msg.url(plane_urls[hash("/plane_camera")])
	plane_camera.fragment = "plane_camera"

	local plane_script = msg.url(plane_urls[hash("/plane_camera")])
	plane_script.fragment = "game_camera"

	game_camera.add(const.CAMERA.PLANE, plane_camera, plane_script, "disable")

	local plane_fx = container
	plane_fx.fragment = "plane_fx"
	audio.fx["PLANE"] = plane_fx

	--[[
    -- rotated particles are not working
    local plane_particle = container
    plane_particle.fragment = "plane"
    particlefx.play(plane_particle)]]

	path_progress = 0
end

function plane.update(dt)
	-- Move along path
	local speed_factor = (MAX_SPEED / 10.0) * path_length
	path_progress = path_progress + speed_factor * dt

	if path_progress >= path_length then
		path_progress = path_progress - path_length
	end

	local current_pos = get_path_point(path_progress)

	-- Look ahead for direction
	local lookahead_distance = 3.0
	local next_progress = path_progress + lookahead_distance
	if next_progress >= path_length then
		next_progress = next_progress - path_length
	end
	local next_pos = get_path_point(next_progress)

	-- direction
	local direction = next_pos - current_pos
	local dir_len = vmath.length(direction)

	if dir_len > const.EPSILON then
		direction = direction / dir_len

		-- target yaw
		local target_yaw = math.atan2(direction.x, direction.z)
		local yaw_delta = normalize_angle(target_yaw - previous_yaw)
		local turn_rate_t = math.min(1.0, TURN_RATE_SMOOTHING * dt)
		smoothed_turn_rate = smoothed_turn_rate + (yaw_delta - smoothed_turn_rate) * turn_rate_t

		-- banking
		local target_bank = -smoothed_turn_rate * BANK_SENSITIVITY
		target_bank = math.max(-MAX_BANK_ANGLE, math.min(MAX_BANK_ANGLE, target_bank))

		local bank_t = math.min(1.0, BANK_SPEED * dt)
		current_bank = current_bank + (target_bank - current_bank) * bank_t

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
