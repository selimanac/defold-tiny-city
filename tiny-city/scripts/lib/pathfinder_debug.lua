local data             = require("scripts.data")
local const            = require("scripts.const")

-- =================================
-- MODULE
-- =================================

local pathfinder_debug = {}


local function get_edge_positions(from_node_id, to_node_id)
	local from_v2 = pathfinder.get_node_position(from_node_id)
	local to_v2 = pathfinder.get_node_position(to_node_id)
	return vmath.vector3(from_v2.x, 0, from_v2.y), vmath.vector3(to_v2.x, 0, to_v2.y)
end

function pathfinder_debug.draw_edges()
	if data.debug == false then
		return
	end
	for _, edge in ipairs(data.edges) do
		local from, to = get_edge_positions(edge.from_node_id, edge.to_node_id)
		msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = const.COLORS.GREEN })
	end
end

return pathfinder_debug
