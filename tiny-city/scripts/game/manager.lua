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

local graph     = require("tiny-city.scripts.lib.graph")
local collision = require("tiny-city.scripts.lib.collision")
local traffic   = require("tiny-city.scripts.game.traffic")

-- =================================
-- MODULE
-- =================================
local manager   = {}

-- =================================
-- VARS
-- =================================

function manager.init()
	collision.init()
	graph.init()
	traffic.init()
end

function manager.update(dt)
	traffic.update(dt)
end

function manager.input(action_id, action)
end

return manager
