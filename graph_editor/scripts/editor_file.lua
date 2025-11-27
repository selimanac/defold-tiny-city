local data  = require("graph_editor.scripts.editor_data")
local const = require("graph_editor.scripts.editor_const")
local utils = require("graph_editor.scripts.editor_utils")
local graph = require("graph_editor.scripts.editor_graph")

-- =======================================
-- MODULE
-- =======================================
local file  = {}

-- =======================================
-- Save
-- =======================================
function file.add(filename)
	for i, v in ipairs(const.GRAPH_EDITOR.FILES) do
		if v == filename then
			return i
		end
	end
	table.insert(const.GRAPH_EDITOR.FILES, filename)
	return #const.GRAPH_EDITOR.FILES
end

function file.save()
	data.save_load_text = const.FILE_STATUS.SAVE_SUCCESS
	--local json_nodes = prepare_for_save()

	local save_status = true
	local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]
	local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. file_name

	local json_data = sys.serialize({ nodes = data.nodes, edges = data.edges, options = data.options })
	local file = io.open(file_path, "w")
	if file then
		file:write(json_data)
		file:close()
		utils.set_title(file_path)
	else
		save_status = false
	end

	data.save_load_text = save_status and const.FILE_STATUS.SAVE_SUCCESS or const.FILE_STATUS.SAVE_ERROR

	timer.delay(0.7, false, function()
		data.save_load_text = ""
	end)
end

function file.load()
	local load_status = true
	local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]
	if file_name == nil then
		return
	end
	local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. file_name
	local file = io.open(file_path, "r")
	if not file then
		load_status = false
	else
		local content = file:read("*a") -- read entire file
		file:close()

		local loaded_data = sys.deserialize(content)

		if loaded_data.options then
			data.options = loaded_data.options
		end

		graph.load(loaded_data)
		utils.set_title(file_path)
	end

	data.save_load_text = load_status and const.FILE_STATUS.LOAD_SUCCESS or const.FILE_STATUS.LOAD_ERROR

	timer.delay(0.7, false, function()
		data.save_load_text = ""
	end)
end

function file.save_exports(nodes, edges)
	if data.selected_file > -1 then
		data.save_load_text = const.FILE_STATUS.EXPORT_SUCCESS

		local save_status = true
		local file_name = const.GRAPH_EDITOR.FILES[data.selected_file]

		local nodes_file_name = file_name:gsub("%.json$", "")
		nodes_file_name = nodes_file_name .. "_nodes.json"

		local file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. nodes_file_name

		local json_data = nodes
		local file = io.open(file_path, "w")
		if file then
			file:write(json_data)
			file:close()
		else
			save_status = false
		end

		data.save_load_text = save_status and const.FILE_STATUS.EXPORT_SUCCESS or const.FILE_STATUS.EXPORT_ERROR

		timer.delay(0.7, false, function()
			data.save_load_text = ""
		end)

		local edges_file_name = file_name:gsub("%.json$", "")
		edges_file_name = edges_file_name .. "_edges.json"


		file_path = const.GRAPH_EDITOR.FOLDER .. "/" .. edges_file_name

		json_data = edges
		file = io.open(file_path, "w")
		if file then
			file:write(json_data)
			file:close()
		else
			save_status = false
		end

		data.save_load_text = save_status and const.FILE_STATUS.EXPORT_SUCCESS or const.FILE_STATUS.EXPORT_ERROR

		timer.delay(0.7, false, function()
			data.save_load_text = ""
		end)
	else
		data.modals.open_export = true
	end
end

function file.export_json()
	local temp_nodes = {}

	local nodes = data.nodes
	local order = {}

	for uuid, _ in pairs(nodes) do
		order[#order + 1] = uuid
	end

	-- Sort UUIDs by node.pathfinder_node_id
	table.sort(order, function(a, b)
		return nodes[a].pathfinder_node_id < nodes[b].pathfinder_node_id
	end)


	for _, uuid in ipairs(order) do
		local node = nodes[uuid]
		local temp_node = { id = node.pathfinder_node_id, x = utils.round3(node.position.x), y = utils.round3(node.position.z) }
		table.insert(temp_nodes, temp_node)
	end


	data.export.nodes = json.encode(temp_nodes)


	local temp_edges = {}
	for _, edge in pairs(data.edges) do
		local temp_edge = {
			from_node_id = edge.from_node_id,
			to_node_id = edge.to_node_id,
			bidirectional = edge.bidirectional
		}
		table.insert(temp_edges, temp_edge)
	end

	data.export.edges = json.encode(temp_edges)

	file.save_exports(data.export.nodes, data.export.edges)
end

function file.export_lua()
	-- body
end

return file
