
function mcl_beacon.on_place(itemstack, placer, pointed_thing)
	-- check for correct pointed_thing
	if not pointed_thing or not pointed_thing.above or not pointed_thing.under or pointed_thing.type ~= "node" then
		return itemstack, false
	end
	-- calculate param2 direction from pointed_thing
	local param2 = 0
	local pointed_dir = vector.subtract(pointed_thing.above, pointed_thing.under)
	if pointed_dir.x ~= 0 then
		param2 = pointed_dir.x > 0 and 12 or 16
	elseif pointed_dir.y ~= 0 then
		param2 = pointed_dir.y > 0 and 0 or 20
	elseif pointed_dir.z ~= 0 then
		param2 = pointed_dir.z > 0 and 4 or 8
	end
	-- place mcl_beacon
	return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

function mcl_beacon.place_beam(pos, player_name, dir)
	local node_name = minetest.get_node(pos).name
	local offset = mcl_beacon.dir_to_vector[dir]
	local param2 = mcl_beacon.dir_to_param2[dir]
	local can_break_nodes = mcl_beacon.config.beam_break_nodes
	-- place base
	pos = vector.add(pos, offset)
	minetest.add_node(pos, { name = node_name.."base", param2 = param2 })
	-- place beam
	for _=1, mcl_beacon.config.beam_length - 1 do
		pos = vector.add(pos, offset)
		if minetest.is_protected(pos, player_name) then return end
		if not can_break_nodes then
			if not mcl_beacon.is_airlike_node(pos) then return end
		end
		minetest.add_node(pos, { name = node_name.."beam", param2 = param2 })
	end
end

function mcl_beacon.remove_beam(pos)
	local dir = minetest.get_meta(pos):get_string("beam_dir")
	if not dir or not mcl_beacon.dir_to_vector[dir] then
		return -- invalid meta
	end
	local offset = mcl_beacon.dir_to_vector[dir]
	-- remove beam (no need to remove beam base seperately)
	for _=1, mcl_beacon.config.beam_length do
		pos = vector.add(pos, offset)
		local node = mcl_beacon.get_node(pos)
		if minetest.get_item_group(node.name, "mcl_beacon_beam") ~= 1 or mcl_beacon.param2_to_dir[node.param2] ~= dir then
			return -- end of beam
		end
		minetest.set_node(pos, {name = "air"})
	end
end

function mcl_beacon.activate(pos, player_name)
	local dir = mcl_beacon.param2_to_dir[minetest.get_node(pos).param2]
	local pos1 = vector.add(pos, mcl_beacon.dir_to_vector[dir])
	if minetest.is_protected(pos1, player_name) or not mcl_beacon.is_airlike_node(pos1) then
		minetest.chat_send_player(player_name, "Not enough room to activate mcl_beacon pointing in "..dir.." direction!")
		return
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("beam_dir", dir)
	meta:set_string("active", "true")
	minetest.get_node_timer(pos):start(3)
	minetest.sound_play("mcl_beacon_power_up", {
		gain = 2.0,
		pos = pos,
		max_hear_distance = 32,
	})
	mcl_beacon.place_beam(pos, player_name, dir)
	mcl_beacon.update(pos)
end

function mcl_beacon.deactivate(pos)
	local meta = minetest.get_meta(pos)
	local timer = minetest.get_node_timer(pos)
	meta:set_string("active", "false")
	timer:stop()
	minetest.sound_play("mcl_beacon_power_down", {
		gain = 2.0,
		pos = pos,
		max_hear_distance = 32,
	})
	mcl_beacon.remove_beam(pos)
end

function mcl_beacon.update(pos)
	local meta = minetest.get_meta(pos)
	local effect = meta:get_string("effect")
	if effect == "" or effect == "none" or not mcl_beacon.effects[effect] then
		return true -- effect not set in metadata / no mcl_beacon effects / invalid effect
	end
	local range = meta:get_int("range")
	if not range or range == 0 then return true end -- range not set in metadata
	-- check players
	for _,player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local spos = pos.x..","..pos.y..",".. pos.z
		if mcl_beacon.players[name] and not mcl_beacon.players[name].mcl_beacons[spos] then
			local offset = vector.subtract(player:get_pos(), pos)
			local distance = math.max(math.abs(offset.x), math.abs(offset.y), math.abs(offset.z))
			if distance <= range + 0.5 then
				mcl_beacon.players[name].mcl_beacons[spos] = pos
			end
		end
	end
	-- spawn active mcl_beacon particles
	local dir = meta:get_string("beam_dir")
	local colordef = mcl_beacon.colors[string.gsub(mcl_beacon.get_node(pos).name, "mcl_beacon:", "")]
	if dir and mcl_beacon.dir_to_vector[dir] and colordef and colordef.color then
		pos = vector.add(pos, mcl_beacon.dir_to_vector[dir])
		minetest.add_particlespawner({
			amount = 32,
			time = 3,
			minpos = {x=pos.x-0.25, y=pos.y-0.25, z=pos.z-0.25},
			maxpos = {x=pos.x+0.25, y=pos.y+0.25, z=pos.z+0.25},
			minvel = {x=-0.8, y=-0.8, z=-0.8},
			maxvel = {x=0.8, y=0.8, z=0.8},
			minacc = {x=0,y=0,z=0},
			maxacc = {x=0,y=0,z=0},
			minexptime = 0.5,
			maxexptime = 1,
			minsize = 1,
			maxsize = 2,
			texture = "mcl_beacon_particle.png^[multiply:"..colordef.color,
			glow = 14,
		})
	end
	return true
end
