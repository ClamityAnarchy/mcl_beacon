
local function is_def_valid(def)
	if type(def) ~= "table" then
		return false
	end
	if (def.desc_name and type(def.desc_name) ~= "string")
			or (def.info and type(def.info) ~= "string")
			or (def.min_level and type(def.min_level) ~= "number")
			or (def.overrides and type(def.overrides) ~= "table")
			or (def.on_apply and type(def.on_apply) ~= "function")
			or (def.on_step and type(def.on_step) ~= "function")
			or (def.on_remove and type(def.on_remove) ~= "function") then
		return false
	end
	return true
end

function mcl_beacon.register_effect(name, def)
	if name == nil then
		minetest.log("warning", "[mcl_beacon] Not registering effect, name is nil")
		return
	end
	if mcl_beacon.effects[name] then
		minetest.log("warning", "[mcl_beacon] Not registering effect \""..name.."\", effect already exists")
		return
	end
	if not is_def_valid(def) then
		minetest.log("warning", "[mcl_beacon] Not registering effect \""..name.."\", definition is invalid")
		return
	end

	mcl_beacon.effects[name] = {
		desc_name = def.desc_name or "Unnamed Effect",
		info = def.info or "?",
		min_level = def.min_level or 0,
		overrides = def.overrides,
		on_apply = def.on_apply,
		on_step = def.on_step,
		on_remove = def.on_remove,
	}
end

function mcl_beacon.override_effect(name, redef)
	if name == nil then
		minetest.log("warning", "[mcl_beacon] Not overriding effect, name is nil")
		return
	end
	if not mcl_beacon.effects[name] then
		minetest.log("warning", "[mcl_beacon] Not overriding effect \""..name.."\", effect does not exsist")
		return
	end
	if not is_def_valid(redef) then
		minetest.log("warning", "[mcl_beacon] Not overriding effect \""..name.."\", redefinition is invalid")
		return
	end
	local def = mcl_beacon.effects[name]
	for k, v in pairs(redef) do
		rawset(def, k, v)
	end
	mcl_beacon.effects[name] = nil
	mcl_beacon.register_effect(name, def)
end

function mcl_beacon.unregister_effect(name)
	if name == nil then
		minetest.log("warning", "[mcl_beacon] Not unregistering effect, name is nil")
		return
	end
	if not mcl_beacon.effects[name] then
		minetest.log("warning", "[mcl_beacon] Not unregistering effect \""..name.."\", effect does not exsist")
		return
	end
	mcl_beacon.effects[name] = nil
end

function mcl_beacon.register_color(name, colorstring, coloring_item)
	if type(name) ~= "string" or name == "" then
		minetest.log("warning", "[mcl_beacon] Not registering color, name is invalid")
		return
	end
	if type(colorstring) ~= "string" or colorstring:sub(1, 1) ~= "#" then
		minetest.log("warning", "[mcl_beacon] Not registering color, colorstring is invalid")
		return
	end

	local id = name:gsub("[%c%p%s]", ""):lower()
	if id == "" then
		minetest.log("warning", "[mcl_beacon] Not registering color, name must contain alphanumeric characters")
		return
	end

	mcl_beacon.colors[id] = { desc = name, color = colorstring }

	-- beam
	minetest.register_node("mcl_beacon:"..id.."beam", {
		description = name.." mcl_beacon Beam",
		tiles = {"mcl_beacon_beam.png^[multiply:"..colorstring},
		use_texture_alpha = "blend",
		inventory_image = "mcl_beacon_beam.png^[multiply:"..colorstring,
		groups = {mcl_beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beam.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		climbable = false,
		selection_box = { type = "fixed", fixed = {0.125, 0.5, 0.125, -0.125, -0.5, -0.125} },
		on_place = mcl_beacon.on_place,
		on_rotate = false,  -- no rotation with screwdriver
	})

	-- beam base
	minetest.register_node("mcl_beacon:"..id.."base", {
		description = name.." mcl_beacon Beam Base",
		tiles = {"mcl_beacon_beambase.png^[multiply:"..colorstring},
		use_texture_alpha = "blend",
		inventory_image = "mcl_beacon_beambase.png^[multiply:"..colorstring,
		groups = {mcl_beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beambase.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		climbable = mcl_beacon.config.beam_climbable,
		selection_box = { type = "fixed", fixed = {0.125, 0.5, 0.125, -0.125, -0.5, -0.125} },
		on_place = mcl_beacon.on_place,
		on_rotate = false,  -- no rotation with screwdriver
	})

	-- mcl_beacon node
	minetest.register_node("mcl_beacon:"..id, {
		description = name.." Beacon",
		tiles = {"mcl_beacon.png"},
		groups = { handy=1, pickaxey=1,cracky = 3, oddly_breakable_by_hand = 3, mcl_beacon = 1},
		drawtype = "glasslike",
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 13,
		on_place = mcl_beacon.on_place,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local player_name = placer and placer:get_player_name() or ""
			mcl_beacon.set_default_meta(pos, player_name)
			if not vector.equals(pointed_thing.above, pointed_thing.under) then
				mcl_beacon.activate(pos, player_name)
			end
			mcl_beacon.update_formspec(pos)
		end,
		on_timer = function(pos, elapsed)
			return mcl_beacon.update(pos)
		end,
		on_rotate = function(pos, node, user, mode, new_param2)
			if minetest.get_meta(pos):get_string("active") == "true" then
				return false
			end
			node.param2 = new_param2
			minetest.swap_node(pos, node)
			return true
		end,
		on_rightclick = mcl_beacon.update_formspec,
		on_receive_fields = mcl_beacon.receive_fields,
		allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			if minetest.is_protected(pos, player:get_player_name())
					or not minetest.get_meta(pos):get_inventory():get_stack(to_list, to_index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) or stack:get_name() ~= mcl_beacon.config.upgrade_item
					or not minetest.get_meta(pos):get_inventory():get_stack(listname, index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return 0
			end
			return 1
		end,
		on_metadata_inventory_put = mcl_beacon.update_formspec,
		on_metadata_inventory_take = mcl_beacon.update_formspec,
		on_destruct = mcl_beacon.remove_beam,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			if oldmetadata.inventory and oldmetadata.inventory.mcl_beacon_upgrades then
				for _,item in ipairs(oldmetadata.inventory.mcl_beacon_upgrades) do
					local stack = ItemStack(item)
					if not stack:is_empty() then
						minetest.add_item(pos, stack)
					end
				end
			end
		end,
		digiline = {
			receptor = {},
			effector = {
				action = mcl_beacon.digiline_effector
			},
		},
	})

	-- coloring recipe
	if type(coloring_item) == "string" and coloring_item ~= "" and minetest.registered_items[coloring_item] then
		minetest.register_craft({
			type = "shapeless",
			output = "mcl_beacon:"..id,
			recipe = { "group:mcl_beacon", coloring_item },
		})
	end
end
