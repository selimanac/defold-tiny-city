local data        = require("tiny-city.scripts.lib.data")
local const       = require("tiny-city.scripts.lib.const")
local audio       = require("tiny-city.scripts.lib.audio")

-- =================================
-- MODULE
-- =================================

local game_camera = {}

function game_camera.init()
	data.cameras["MAIN_CAMERA"] = msg.url("/game_camera#camera")
	msg.post(data.cameras["MAIN_CAMERA"], "enable")
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
			audio.play_fx("PLANE", 1)
		elseif data.current_camera == "PLANE_CAMERA" then
			data.current_camera = "MAIN_CAMERA"
		end

		msg.post(data.cameras[data.current_camera], "enable")
	end
end

return game_camera
