local collision          = {}

collision.COLLISION_BITS = {
	VEHICLE        = 1,
	SIGN           = 2,
	TRAFFIC_LIGHTS = 4,
	ALL            = bit.bnot(0) -- -1 for all results
}


local aabb_group_id = 0

function collision.init()
	aabb_group_id = daabbcc3d.new_group(daabbcc3d.UPDATE_PARTIALREBUILD)
end

function collision.insert_aabb(position, width, height, depth, collision_bit)
	collision_bit = collision_bit and collision_bit or nil
	return daabbcc3d.insert_aabb(aabb_group_id, position, width, height, depth, collision_bit)
end

function collision.insert_gameobject(go_url, width, height, depth, collision_bit)
	collision_bit = collision_bit and collision_bit or nil
	return daabbcc3d.insert_gameobject(aabb_group_id, go_url, width, height, depth, collision_bit)
end

function collision.query_aabb(position, width, height, depth, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc3d.query_aabb(aabb_group_id, position, width, height, depth, mask_bits, get_manifold)
end

function collision.query_id(aabb_id, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc3d.query_id(aabb_group_id, aabb_id, mask_bits, get_manifold)
end

function collision.query_id_sort(aabb_id, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc3d.query_id_sort(aabb_group_id, aabb_id, mask_bits, get_manifold)
end

function collision.query_aabb_sort(position, width, height, depth, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc3d.query_aabb_sort(aabb_group_id, position, width, height, depth, mask_bits, get_manifold)
end

function collision.raycast(ray_start, ray_end, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc3d.raycast(aabb_group_id, ray_start, ray_end, mask_bits, get_manifold)
end

function collision.raycast_sort(ray_start, ray_end, collision_bit, get_manifold)
	local mask_bits = collision_bit and collision_bit or nil
	get_manifold    = get_manifold and get_manifold or nil
	return daabbcc3d.raycast_sort(aabb_group_id, ray_start, ray_end, mask_bits, get_manifold)
end

function collision.update_aabb(aabb)
	daabbcc3d.update_aabb(aabb_group_id, aabb.aabb_id, aabb.position, aabb.size.width, aabb.size.height, aabb.size.depth)
end

function collision.remove(aabb_id)
	daabbcc3d.remove(aabb_group_id, aabb_id)
end

function collision.reset()
	daabbcc3d.reset()
end

return collision
