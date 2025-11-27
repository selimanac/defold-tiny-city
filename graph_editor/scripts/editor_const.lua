local const = {}

local function split_csv(str)
	local t = {}
	for token in str:gmatch("[^,%s]+") do
		t[#t + 1] = token
	end
	return t
end

const.EDITOR_STATES   = {
	ADD_NODE             = 1,
	REMOVE_NODE          = 2,
	MOVE_NODE            = 3,
	ADD_EDGE             = 4,
	REMOVE_EDGE          = 5,
	ADD_AGENT            = 6,
	ADD_DIRECTIONAL_EDGE = 7,
	--SELECT_NODE          = 8
}

const.PROJECT_NAME    = sys.get_config_string("project.title", "defold-graph-pathfinder-editor")

const.MOUSE           = "/graph_editor/mouse"
const.TRIGGERS        = {
	MOUSE_BUTTON_LEFT  = hash("mouse_button_left"),
	MOUSE_BUTTON_RIGHT = hash("mouse_button_right"),
	MOUSE_WHEEL_UP     = hash("mouse_wheel_up"),
	MOUSE_WHEEL_DOWN   = hash("mouse_wheel_down"),
}

const.VIEWPORT_CAMERA = "/editor_camera#camera"
const.VIEWPORT        = "/editor_camera"

const.FACTORIES       = {
	NODE      = "/graph_editor/factories#node",
	AGENT     = "/graph_editor/factories#agent",
	DIRECTION = "/graph_editor/factories#direction",
}
const.GRAPH_EDITOR    = {
	MAX_NODES             = sys.get_config_int("graph_editor.max_nodes", 128),
	MAX_GAMEOBJECT_NODES  = sys.get_config_int("graph_editor.max_gameobject_nodes", 128),
	MAX_EDGES_PER_NODE    = sys.get_config_int("graph_editor.max_edges_per_node", 6),
	HEAP_POOL_BLOCK_SIZE  = sys.get_config_int("graph_editor.heap_pool_block_size", 128),
	MAX_CACHE_PATH_LENGTH = sys.get_config_int("graph_editor.max_cache_path_length", 128),
	FOLDER                = project_path.get() .. "/" .. sys.get_config_string("graph_editor.folder"),
	FILES                 = split_csv(sys.get_config_string("graph_editor.files", "default.json"))
}

const.COLORS          = {
	RED   = vmath.vector3(1, 0, 0),
	BLUE  = vmath.vector3(0, 0, 1),
	GREEN = vmath.vector3(0, 1, 0)
}
const.FILE_STATUS     = {
	SAVE_SUCCESS   = "...Saved!...",
	EXPORT_SUCCESS = "...Exported!...",
	SAVE_ERROR     = "...Can't save the file!...",
	EXPORT_ERROR   = "...Can't export the file!...",
	LOAD_SUCCESS   = "...Loaded!...",
	LOAD_ERROR     = "...Can't load the file!...",
	PREPARE        = "...Preparing Data..."
}

const.EDITOR_STATUS   = {
	ADD_NODE                             = "Click anywhere to add a node",
	REMOVE_NODE                          = "Select a node to remove",
	MOVE_NODE                            = "Select a node to move",
	ADD_EDGE_1                           = "Select the first node",
	ADD_EDGE_2                           = "Select the second node to connect",
	ADD_EDGE_ERROR                       = "Start node and end node cannot be the same",
	ADD_AGENT                            = "Click anywhere to add an agent",
	READY                                = "READY",
	SELECT_NODE                          = "Click to select a node",
	LOADING                              = "LOADING",
	RESET                                = "RESET",
	AGEND_MODE_FIND_PATH_LABEL           = "FIND PATH",
	AGEND_MODE_FIND_PROJECTED_PATH_LABEL = "FIND PROJECTED PATH",
	NO_PATH_FOR_AGENT                    = "No valid path for agent",
	REMOVE_EDGE                          = "Select a edge to remove"
}

const.AGEND_MODE      = {
	NODE_TO_NODE           = 1,
	PROJECTED_TO_NODE      = 2,
	NODE_TO_PROJECTED      = 3,
	PROJECTED_TO_PROJECTED = 4
}

const.AGENT_TO_PATH   = {
	"node_to_node",
	"projected_to_node",
	"node_to_projected",
	"projected_to_projected"
}



return const
