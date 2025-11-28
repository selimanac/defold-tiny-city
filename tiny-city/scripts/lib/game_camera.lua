local data        = require("tiny-city.scripts.lib.data")
local const       = require("tiny-city.scripts.lib.const")

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
		if data.current_camera == "MAIN_CAMERA" then
			data.current_camera = "POLICE_CAMERA"
		elseif data.current_camera == "POLICE_CAMERA" then
			data.current_camera = "PLANE_CAMERA"
		elseif data.current_camera == "PLANE_CAMERA" then
			data.current_camera = "MAIN_CAMERA"
		end
		print("CURRENT:" .. data.current_camera)
		msg.post(data.cameras[data.current_camera], "enable")
	end
end

return game_camera
