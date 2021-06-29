
minetest.register_chatcommand("mcl_beacon_effects", {
	params = "[<player name>]",
	description = "Lists active effects on yourself or another player",
	func = function(caller, param)
		param = param:trim()
		local name = (param ~= "" and param or caller)
		if not minetest.get_player_by_name(name) or not mcl_beacon.players[name] then
			return false, "Player " .. name .. " does not exist or is not online."
		end
		local output = name == caller and {"Your active effects:"} or {name.."'s active effects:"}
		for _,id in ipairs(mcl_beacon.sorted_effect_ids) do
			if mcl_beacon.players[name].effects[id] then
				table.insert(output, "- "..mcl_beacon.effects[id].desc_name)
			end
		end
		return true, table.concat(output, "\n")
	end,
})

minetest.register_chatcommand("mcl_beacon_nearby", {
	params = "[<player name>]",
	description = "Lists all mcl_beacons granting effects to yourself or another player",
	func = function(caller, param)
		param = param:trim()
		local name = (param ~= "" and param or caller)
		if not minetest.get_player_by_name(name) or not mcl_beacon.players[name] then
			return false, "Player " .. name .. " does not exist or is not online."
		end
		local output = name == caller and {"mcl_beacons near you:"} or {"mcl_beacons near "..name..":"}
		for spos,pos in pairs(mcl_beacon.players[name].mcl_beacons) do
			local effect = minetest.get_meta(pos):get_string("effect")
			if effect ~= "" and effect ~= "none" and mcl_beacon.effects[effect] then
				local def = minetest.registered_nodes[mcl_beacon.get_node(pos).name]
				if def and def.description then
					table.insert(output, "- "..def.description.." @ "..spos.." - "..mcl_beacon.effects[effect].desc_name)
				end
			end
		end
		return true, table.concat(output, "\n")
	end,
})

minetest.register_chatcommand("mcl_beacon_info", {
	description = "Lists all avalible mcl_beacon effects with their descriptions",
	func = function(caller)
		local output = {"All avalible mcl_beacon effects:"}
		for _,id in ipairs(mcl_beacon.sorted_effect_ids) do
			table.insert(output, "- "..mcl_beacon.effects[id].desc_name.." - "..mcl_beacon.effects[id].info)
		end
		return true, table.concat(output, "\n")
	end,
})
