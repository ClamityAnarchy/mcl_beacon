local function get_useable_effects(name, pos)
	local useable_effects = {}
	-- check each of the nearby mcl_beacons
	for spos,mcl_beacon_pos in pairs(mcl_beacon.players[name].mcl_beacons) do
		local useable = false
		local meta = minetest.get_meta(mcl_beacon_pos)
		local active = meta:get_string("active")
		local range = meta:get_int("range")
		if active == "true" and range > 0 then
			local offset = vector.subtract(pos, mcl_beacon_pos)
			local distance = math.max(math.abs(offset.x), math.abs(offset.y), math.abs(offset.z))
			if distance <= range + 0.5 then
				local effect = meta:get_string("effect")
				if effect ~= "" and effect ~= "none" and mcl_beacon.effects[effect] then
					local owner = meta:get_string("owner")
					if owner == "" or mcl_beacon.can_effect(pos, owner) then
						useable_effects[effect] = true
						useable = true
					end
				end
			end
		end
		if not useable then
			mcl_beacon.players[name].mcl_beacons[spos] = nil
		end
	end
	-- check all the effects granted by in-range mcl_beacons
	for effect,_ in pairs(useable_effects) do
		if type(mcl_beacon.effects[effect].overrides) == "table" then
			-- remove the effects overridden by the effect
			for _,override in ipairs(mcl_beacon.effects[effect].overrides) do
				useable_effects[override] = nil
			end
		end
	end
	return useable_effects
end

local function get_all_effect_ids(effects1, effects2)
	local effect_ids = {}
	for id,_ in pairs(effects1) do
		effect_ids[id] = true
	end
	for id,_ in pairs(effects2) do
		effect_ids[id] = true
	end
	return effect_ids
end

local timer = 0

minetest.register_globalstep(function(dtime)
	-- update the timer
	timer = timer + dtime
	if (timer >= 1) then
		timer = 0
		-- loop through all the players
		local players = minetest.get_connected_players()
		for _,player in ipairs(players) do
			local name = player:get_player_name()
			if mcl_beacon.players[name] then
				local useable = get_useable_effects(name, player:get_pos())
				local active = mcl_beacon.players[name].effects
				-- check the player's effects
				for id,_ in pairs(get_all_effect_ids(active, useable)) do
					-- remove effect
					if active[id] and not useable[id] then
						active[id] = nil
						if mcl_beacon.effects[id].on_remove then
							mcl_beacon.effects[id].on_remove(player, name)
						end
					-- add effect
					elseif useable[id] and not active[id] then
						active[id] = true
						if mcl_beacon.effects[id].on_apply then
							mcl_beacon.effects[id].on_apply(player, name)
						end
					-- update effect
					else
						if mcl_beacon.effects[id].on_step then
							mcl_beacon.effects[id].on_step(player, name)
						end
					end
				end
				mcl_beacon.players[name].effects = active
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	mcl_beacon.players[player:get_player_name()] = {mcl_beacons = {}, effects = {}}
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if not mcl_beacon.players[name] then return end
	for id,_ in pairs(mcl_beacon.players[name].effects) do
		-- remove all effects before leaving
		if mcl_beacon.effects[id].on_remove then
			mcl_beacon.effects[id].on_remove(player, name)
		end
	end
	mcl_beacon.players[name] = nil
end)
