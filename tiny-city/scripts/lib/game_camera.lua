local data        = require("tiny-city.scripts.lib.data")
local const       = require("tiny-city.scripts.lib.const")
local audio       = require("tiny-city.scripts.lib.audio")
local dof         = require("dof.dof")

-- =================================
-- MODULE
-- =================================
local game_camera = {}

local far_z       = 0
local near_z      = 0

local function set_dof()
	far_z = camera.get_far_z(data.cameras[data.current_camera].camera)
	near_z = camera.get_near_z(data.cameras[data.current_camera].camera)
	dof.set_camera_params(near_z, far_z)

	if data.current_camera == const.CAMERA.MAIN then
		dof.set_dof_mode(1, 10)
		dof.set_distance(0.5, 15.0)
		dof.set_focus(0.5, 0.45)
	elseif data.current_camera == const.CAMERA.POLICE then
		audio.play_fx("POLICE", 0.5)

		dof.set_dof_mode(1, 20)
		dof.set_distance(1.0, 30.0)
		dof.set_focus(0.5, 0.45)
	elseif data.current_camera == const.CAMERA.PLANE then
		audio.play_fx("PLANE", 1)

		dof.set_dof_mode(1, 10)
		dof.set_distance(1.0, 15.0)
		dof.set_focus(0.5, 0.35)
	end
end

function game_camera.add(name, camera, script, status)
	status = status and status or "disable"
	data.cameras[name] = {
		camera = camera,
		script = script
	}

	msg.post(data.cameras[name].camera, status)
	msg.post(data.cameras[name].script, hash(status .. "_input"))
end

function game_camera.init()
	game_camera.add(const.CAMERA.MAIN, msg.url("/game_camera#camera"), msg.url("/game_camera#game_camera"), "enable")

	set_dof()
	dof.set_dof_mode(1, 1)
	dof.set_gaussian_blur(2, 3)
end

function game_camera.input(action_id, action)
	if action.pressed and action_id == const.TRIGGERS.KEY_1 then
		msg.post(data.cameras[data.current_camera].camera, "disable")
		msg.post(data.cameras[data.current_camera].script, hash("disable_input"))
		audio.stop_all_fx()
		if data.current_camera == const.CAMERA.MAIN then
			data.current_camera = const.CAMERA.POLICE
		elseif data.current_camera == const.CAMERA.POLICE then
			data.current_camera = const.CAMERA.PLANE
		elseif data.current_camera == const.CAMERA.PLANE then
			data.current_camera = const.CAMERA.MAIN
		end
		set_dof()
		msg.post(data.cameras[data.current_camera].camera, "enable")
		msg.post(data.cameras[data.current_camera].script, "enable_input")
	end
end

return game_camera
