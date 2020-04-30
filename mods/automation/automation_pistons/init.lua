minetest.register_node("automation_pistons:piston", {
	description = "Piston",
	tiles = {"default_wood.png", "automation_strong_metal.png","default_wood.png^automation_piston_side.png"},
	groups = {choppy = 3, machine=1},
	sounds =  default.node_sound_stone_defaults(),
	paramtype2 = "facedir",
	on_place = minetest.rotate_node,

	on_automation_rotate = function(pos, from, force)
		if force > 40 then
			local node = minetest.get_node(pos)
			local a = {vector.new(0, 1, 0), vector.new(0, 0, 1), vector.new(0, 0, -1), vector.new(1,0,0), vector.new(-1,0,0), vector.new(-1,0, 0)}
			local d = a[math.floor(node.param2/4)+1]
			if minetest.get_node(vector.add(pos, vector.multiply(d,2))).name == "air" or minetest.get_node(vector.add(pos, d)).name == "air" then
				node.name = "automation_pistons:piston_on"
				minetest.swap_node(pos, node)

				local meta = minetest.get_meta(vector.add(pos, d)):to_table()

				if not(minetest.get_node(vector.add(pos, d)).name == "air") then
					minetest.set_node(vector.add(pos, vector.multiply(d,2)), minetest.get_node(vector.add(pos, d)))
					minetest.get_meta(vector.add(pos, vector.multiply(d,2))):from_table(meta)
				end

				minetest.set_node(vector.add(pos, d), {name = "automation_pistons:piston_pusher", param2 = node.param2})
				minetest.check_for_falling(vector.add(pos, vector.multiply(d, 2)))
			end
		end
	end,
})

minetest.register_node("automation_pistons:piston_on", {
	description = "Piston (ON)",
	tiles = {"automation_strong_metal.png", "automation_strong_metal.png","default_wood.png^automation_piston_side.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {{-2/16, 5/16, -2/16, 2/16, 0.5, 2/16}, {-0.5, -0.5, -0.5, 0.5, 5/16, 0.5}},
	},

	groups = {choppy = 3, not_in_creative_inventory = 1 , machine=1},
	sounds =  default.node_sound_stone_defaults(),
	paramtype2 = "facedir",
	on_place = minetest.rotate_node,

	drop = "automation_pistons:piston",

	on_automation_rotate = function(pos, from, force)
		if force > 40 then
			local node = minetest.get_node(pos)
			local a = {vector.new(0, 1, 0), vector.new(0, 0, 1), vector.new(0, 0, -1), vector.new(1,0,0), vector.new(-1,0,0), vector.new(-1,0, 0)}
			local d = a[math.floor(node.param2/4)+1]

			node.name = "automation_pistons:piston"
			minetest.swap_node(pos, node)

			minetest.set_node(vector.add(pos, d), {name = "air"})
			minetest.check_for_falling(vector.add(pos, vector.multiply(d, 2)))
		end
	end,
})

minetest.register_node("automation_pistons:piston_pusher", {
	description = "Piston (Pusher)",
	tiles = {"default_wood.png"},
	groups = {choppy = 3, not_in_creative_inventory = 1},
	sounds =  default.node_sound_stone_defaults(),
	paramtype2 = "facedir",
	paramtype = "light",

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {{-2/16, -0.5, -2/16, 2/16, 0.5, 2/16}, {-0.5, 6/16, -0.5, 0.5, 0.5, 0.5}},
	},

	drop = "",
})


minetest.register_craft({
	output = 'automation_pistons:piston',
	recipe = {
		{'group:wood', 'group:wood', 'group:wood'},
		{'automation_materials:strong_metal', 'default:stick', 'automation_materials:strong_metal'},
		{'automation_materials:strong_metal', 'automation_machines:boiler_empty', 'automation_materials:strong_metal'},
	}
})
