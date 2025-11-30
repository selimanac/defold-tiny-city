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
	far_z = camera.get_far_z(data.cameras[data.current_camera])
	near_z = camera.get_near_z(data.cameras[data.current_camera])
	dof.set_camera_params(near_z, far_z)

	if data.current_camera == "MAIN_CAMERA" then
		dof.set_dof_mode(1, 10)
		dof.set_distance(0.5, 15.0)
		dof.set_focus(0.5, 0.45)
	elseif data.current_camera == "POLICE_CAMERA" then
		--dof.set_dof_mode(1, 50)
		dof.set_dof_mode(1, 50)
		dof.set_distance(0.3, 30.0)
		dof.set_focus(0.5, 0.45)
	elseif data.current_camera == "PLANE_CAMERA" then
		dof.set_dof_mode(1, 10)
		dof.set_distance(1.0, 15.0)
		dof.set_focus(0.5, 0.35)
	end
end

function game_camera.init()
	data.cameras["MAIN_CAMERA"] = msg.url("/game_camera#camera")
	msg.post(data.cameras["MAIN_CAMERA"], "enable")

	set_dof()
	dof.set_dof_mode(1, 1)
	--dof.set_dof_mode(0)
	dof.set_gaussian_blur(2, 3)
end

function game_camera.input(action_id, action)
	if action.pressed and action_id == const.TRIGGERS.KEY_1 then
		msg.post(data.cameras[data.current_camera], "disable")
		audio.stop_fx("PLANE")
		audio.stop_fx("POLICE")

		if data.current_camera == "MAIN_CAMERA" then
			data.current_camera = "POLICE_CAMERA"
			audio.play_fx("POLICE", 0.5)
		elseif data.current_camera == "POLICE_CAMERA" then
			data.current_camera = "PLANE_CAMERA"
			dof.set_focus(0.5, 0.35)
			audio.play_fx("PLANE", 1)
		elseif data.current_camera == "PLANE_CAMERA" then
			dof.set_focus(0.5, 0.45)
			data.current_camera = "MAIN_CAMERA"
		end
		set_dof()
		msg.post(data.cameras[data.current_camera], "enable")
	end
end

return game_camera
