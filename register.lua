
-- default mcl_beacon colors
mcl_beacon.register_color("White", "#ffffffff", "mcl_dye:white")
mcl_beacon.register_color("Black", "#0f0f0fff", "mcl_dye:black")
mcl_beacon.register_color("Blue", "#0000ffff", "mcl_dye:blue")
mcl_beacon.register_color("Cyan", "#00ffffff", "mcl_dye:cyan")
mcl_beacon.register_color("Green", "#00ff00ff", "mcl_dye:green")
mcl_beacon.register_color("Magenta", "#ff00ffff", "mcl_dye:magenta")
mcl_beacon.register_color("Orange", "#ff8000ff", "mcl_dye:orange")
mcl_beacon.register_color("Red", "#ff0000ff", "mcl_dye:red")
mcl_beacon.register_color("Violet", "#8f00ffff", "mcl_dye:violet")
mcl_beacon.register_color("Yellow", "#ffff00ff", "mcl_dye:yellow")

-- base mcl_beacon recipe
minetest.register_craft({
	output = "mcl_beacon:white",
	recipe = {
		{"mcl_core:glass", "mcl_core:glass", "mcl_core:glass"},
		{"mcl_core:glass", "mcl_mobitems:nether_star", "mcl_core:glass"},
		{"mcl_core:obsidian", "mcl_core:obsidian", "mcl_core:obsidian"},
	}
})

-- floating beam cleanup
minetest.register_lbm({
	label = "Floating mcl_beacon beam cleanup",
	name = "mcl_beacon:beam_cleanup",
	nodenames = {"group:mcl_beacon_beam"},
	run_at_every_load = true,
	action = function(pos, node)
		local under_pos = vector.add(pos, mcl_beacon.param2_to_under[node.param2])
		if mcl_beacon.is_airlike_node(under_pos) then
			minetest.set_node(pos, { name = "air" })
		end
	end,
})

-- purple is named violet now
minetest.register_alias("mcl_beacon:purplebeam", "mcl_beacon:violetbeam")
minetest.register_alias("mcl_beacon:purplebase", "mcl_beacon:violetbase")
minetest.register_alias("mcl_beacon:purple", "mcl_beacon:violet")

-- no empty/unactivated mcl_beacon
minetest.register_alias("mcl_beacon:empty", "mcl_beacon:white")
