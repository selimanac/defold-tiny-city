--local dof = require("dof.dof")
--local light_and_shadows = require "light_and_shadows.light_and_shadows"


--light_and_shadows.upscale = true
--[[local far_z = camera.get_far_z(msg.url("/game_camera#camera"))
local near_z = camera.get_near_z(msg.url("/game_camera#camera"))
dof.set_camera_params(near_z, far_z)
dof.set_distance(1.0, 4.0)
dof.set_focus(0.5, 0.5)
dof.set_dof_mode(0)
dof.set_gaussian_blur(3, 5)]]

local const     = require("tiny-city.scripts.lib.const")
local graph     = require("tiny-city.scripts.lib.graph")
local collision = require("tiny-city.scripts.lib.collision")
local traffic   = require("tiny-city.scripts.game.traffic")
local data      = require("tiny-city.scripts.lib.data")

-- =================================
-- MODULE
-- =================================
local manager   = {}
-- =================================
-- VARS
-- =================================

function manager.init()
	const.CAMERA = msg.url("/game_camera#camera")
	data.cameras["MAIN_CAMERA"] = const.CAMERA
	msg.post(data.cameras["MAIN_CAMERA"], "enable")
	collision.init()
	graph.init()
	traffic.init()
end

function manager.update(dt)
	traffic.update(dt)
end

function manager.input(action_id, action)
	if action.pressed and action_id == const.TRIGGERS.KEY_1 then
		msg.post(data.cameras[data.current_camera], "disable")
		if data.current_camera == "MAIN_CAMERA" then
			data.current_camera = "POLICE_CAMERA"
		else
			data.current_camera = "MAIN_CAMERA"
		end

		msg.post(data.cameras[data.current_camera], "enable")
	end
	traffic.input(action_id, action)
end

return manager
