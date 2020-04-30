local S = minetest.get_translator("mcl_potions")

local brewhelp = S("Put this item in an item frame for decoration. It's useless otherwise.")

minetest.register_craftitem("mcl_potions:fermented_spider_eye", {
	description = S("Fermented Spider Eye"),
	_doc_items_longdesc = brewhelp,
	wield_image = "mcl_potions_spider_eye_fermented.png",
	inventory_image = "mcl_potions_spider_eye_fermented.png",
	-- TODO: Reveal item when it's actually useful
	groups = { brewitem = 1, not_in_creative_inventory = 1, not_in_craft_guide = 1 },
	stack_max = 64,
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_potions:fermented_spider_eye",
	recipe = { "mcl_mushrooms:mushroom_brown", "mcl_core:sugar", "mcl_mobitems:spider_eye" },
})

minetest.register_craftitem("mcl_potions:glass_bottle", {
	description = S("Glass Bottle"),
	_tt_help = S("Liquid container"),
	_doc_items_longdesc = S("A glass bottle is used as a container for liquids and can be used to collect water directly."),
	_doc_items_usagehelp = S("To collect water, it on a cauldron with water (which removes a level of water) or any water source (which removes no water)."),
	inventory_image = "mcl_potions_potion_bottle_empty.png",
	wield_image = "mcl_potions_potion_bottle_empty.png",
	groups = {brewitem=1},
	liquids_pointable = true,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			local def = minetest.registered_nodes[node.name]

			-- Call on_rightclick if the pointed node defines it
			if placer and not placer :get_player_control().sneak then
				if def and def.on_rightclick then
					return def.on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
				end
			end

			-- Try to fill glass bottle with water
			local get_water = false
			local from_liquid_source = false
			local river_water = false
			if not def then
				-- Unknown node: no-op
			elseif def.groups and def.groups.water and def.liquidtype == "source" then
				-- Water source
				get_water = true
				from_liquid_source = true
				river_water = node.name == "mclx_core:river_water_source"
			-- Or reduce water level of cauldron by 1
			elseif string.sub(node.name, 1, 14) == "mcl_cauldrons:" then
				local pname = placer:get_player_name()
				if minetest.is_protected(pointed_thing.under, pname) then
					minetest.record_protection_violation(pointed_thing.under, pname)
					return itemstack
				end
				if node.name == "mcl_cauldrons:cauldron_3" then
					get_water = true
					minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_2"})
				elseif node.name == "mcl_cauldrons:cauldron_2" then
					get_water = true
					minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_1"})
				elseif node.name == "mcl_cauldrons:cauldron_1" then
					get_water = true
					minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron"})
				elseif node.name == "mcl_cauldrons:cauldron_3r" then
					get_water = true
					river_water = true
					minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_2r"})
				elseif node.name == "mcl_cauldrons:cauldron_2r" then
					get_water = true
					river_water = true
					minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_1r"})
				elseif node.name == "mcl_cauldrons:cauldron_1r" then
					get_water = true
					river_water = true
					minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron"})
				end
			end
			if get_water then
				local creative = minetest.settings:get_bool("creative_mode") == true
				if from_liquid_source or creative then
					-- Replace with water bottle, if possible, otherwise
					-- place the water potion at a place where's space
					local water_bottle
					if river_water then
						water_bottle = ItemStack("mcl_potions:potion_river_water")
					else
						water_bottle = ItemStack("mcl_potions:potion_water")
					end
					local inv = placer:get_inventory()
					if creative then
						-- Don't replace empty bottle in creative for convenience reasons
						if not inv:contains_item("main", water_bottle) then
							inv:add_item("main", water_bottle)
						end
					elseif itemstack:get_count() == 1 then
						return water_bottle
					else
						if inv:room_for_item("main", water_bottle) then
							inv:add_item("main", water_bottle)
						else
							minetest.add_item(placer:get_pos(), water_bottle)
						end
						itemstack:take_item()
					end
				end
				minetest.sound_play("mcl_potions_bottle_fill", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)
			end
		end
		return itemstack
	end,
})

minetest.register_craft( {
	output = "mcl_potions:glass_bottle 3",
	recipe = {
		{ "mcl_core:glass", "", "mcl_core:glass" },
		{ "", "mcl_core:glass", "" }
	}
})

-- Template function for creating images of filled potions
-- - colorstring must be a ColorString of form “#RRGGBB”, e.g. “#0000FF” for blue.
-- - opacity is optional opacity from 0-255 (default: 127)
local potion_image = function(colorstring, opacity)
	if not opacity then
		opacity = 127
	end
	return "mcl_potions_potion_bottle_drinkable.png^(mcl_potions_potion_overlay.png^[colorize:"..colorstring..":"..tostring(opacity)..")"
end

-- Cauldron fill up rules:
-- Adding any water increases the water level by 1, preserving the current water type
local cauldron_levels = {
	-- start = { add water, add river water }
	{ "",    "_1",  "_1r" },
	{ "_1",  "_2",  "_2" },
	{ "_2",  "_3",  "_3" },
	{ "_1r", "_2r",  "_2r" },
	{ "_2r", "_3r", "_3r" },
}
local fill_cauldron = function(cauldron, water_type)
	local base = "mcl_cauldrons:cauldron"
	for i=1, #cauldron_levels do
		if cauldron == base .. cauldron_levels[i][1] then
			if water_type == "mclx_core:river_water_source" then
				return base .. cauldron_levels[i][3]
			else
				return base .. cauldron_levels[i][2]
			end
		end
	end
end

-- Itemstring of potions is “mcl_potions:potion_<NBT Potion Tag>”

minetest.register_craftitem("mcl_potions:potion_water", {
	description = S("Water Bottle"),
	_tt_help = S("No effect"),
	_doc_items_longdesc = S("Water bottles can be used to fill cauldrons. Drinking water has no effect."),
	_doc_items_usagehelp = S("Use the “Place” key to drink. Place this item on a cauldron to pour the water into the cauldron."),
	stack_max = 1,
	inventory_image = potion_image("#0000FF"),
	wield_image = potion_image("#0000FF"),
	groups = {brewitem=1, food=3, can_eat_when_full=1, water_bottle=1},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			local def = minetest.registered_nodes[node.name]

			-- Call on_rightclick if the pointed node defines it
			if placer and not placer:get_player_control().sneak then
				if def and def.on_rightclick then
					return def.on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
				end
			end

			local cauldron = fill_cauldron(node.name, "mcl_core:water_source")
			if cauldron then
				local pname = placer:get_player_name()
				if minetest.is_protected(pointed_thing.under, pname) then
					minetest.record_protection_violation(pointed_thing.under, pname)
					return itemstack
				end
				-- Increase water level of cauldron by 1
				minetest.set_node(pointed_thing.under, {name=cauldron})
				minetest.sound_play("mcl_potions_bottle_pour", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)
				if minetest.settings:get_bool("creative_mode") == true then
					return itemstack
				else
					return "mcl_potions:glass_bottle"
				end
			end
		end

		-- Drink the water by default
		return minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, placer, pointed_thing)
	end,
	on_secondary_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
})

minetest.register_craftitem("mcl_potions:potion_river_water", {
	description = S("River Water Bottle"),
	_tt_help = S("No effect"),
	_doc_items_longdesc = S("River water bottles can be used to fill cauldrons. Drinking it has no effect."),
	_doc_items_usagehelp = S("Use the “Place” key to drink. Place this item on a cauldron to pour the river water into the cauldron."),

	stack_max = 1,
	inventory_image = potion_image("#0044FF"),
	wield_image = potion_image("#0044FF"),
	groups = {brewitem=1, food=3, can_eat_when_full=1, water_bottle=1},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			local def = minetest.registered_nodes[node.name]

			-- Call on_rightclick if the pointed node defines it
			if placer and not placer:get_player_control().sneak then
				if def and def.on_rightclick then
					return def.on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
				end
			end

			local cauldron = fill_cauldron(node.name, "mclx_core:river_water_source")
			if cauldron then
				local pname = placer:get_player_name()
				if minetest.is_protected(pointed_thing.under, pname) then
					minetest.record_protection_violation(pointed_thing.under, pname)
					return itemstack
				end
				-- Increase water level of cauldron by 1
				minetest.set_node(pointed_thing.under, {name=cauldron})
				minetest.sound_play("mcl_potions_bottle_pour", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)
				if minetest.settings:get_bool("creative_mode") == true then
					return itemstack
				else
					return "mcl_potions:glass_bottle"
				end
			end
		end

		-- Drink the water by default
		return minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, placer, pointed_thing)
	end,
	on_secondary_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
})



local how_to_drink = S("Use the “Place” key to drink it.")

minetest.register_craftitem("mcl_potions:potion_awkward", {
	description = S("Awkward Potion"),
	_tt_help = S("No effect"),
	_doc_items_longdesc = S("This potion has an awkward taste and is used for brewing more potions. Drinking it has no effect."),
	_doc_items_usagehelp = how_to_drink,
	stack_max = 1,
	inventory_image = potion_image("#0000FF"),
	wield_image = potion_image("#0000FF"),
	-- TODO: Reveal item when it's actually useful
	groups = {brewitem=1, food=3, can_eat_when_full=1, not_in_creative_inventory=1},
	on_place = minetest.item_eat(0, "mcl_potions:glass_bottle"),
	on_secondary_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
})
minetest.register_craftitem("mcl_potions:potion_mundane", {
	description = S("Mundane Potion"),
	_tt_help = S("No effect"),
	_doc_items_longdesc = S("This potion has a clean taste and is used for brewing more potions. Drinking it has no effect."),
	_doc_items_usagehelp = how_to_drink,
	stack_max = 1,
	inventory_image = potion_image("#0000FF"),
	wield_image = potion_image("#0000FF"),
	-- TODO: Reveal item when it's actually useful
	groups = {brewitem=1, food=3, can_eat_when_full=1, not_in_creative_inventory=1 },
	on_place = minetest.item_eat(0, "mcl_potions:glass_bottle"),
	on_secondary_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
})
minetest.register_craftitem("mcl_potions:potion_thick", {
	description = S("Thick Potion"),
	_tt_help = S("No effect"),
	_doc_items_longdesc = S("This potion has a bitter taste and is used for brewing more potions. Drinking it has no effect."),
	_doc_items_usagehelp = how_to_drink,
	stack_max = 1,
	inventory_image = potion_image("#0000FF"),
	wield_image = potion_image("#0000FF"),
	-- TODO: Reveal item when it's actually useful
	groups = {brewitem=1, food=3, can_eat_when_full=1, not_in_creative_inventory=1 },
	on_place = minetest.item_eat(0, "mcl_potions:glass_bottle"),
	on_secondary_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
})

minetest.register_craftitem("mcl_potions:speckled_melon", {
	description = S("Glistering Melon"),
	_doc_items_longdesc = S("This shiny melon is full of tiny gold nuggets and would be nice in an item frame. It isn't edible and not useful for anything else."),
	stack_max = 64,
	-- TODO: Reveal item when it's actually useful
	groups = { brewitem = 1, not_in_creative_inventory = 1, not_in_craft_guide = 1 },
	inventory_image = "mcl_potions_melon_speckled.png",
})

minetest.register_craft({
	output = "mcl_potions:speckled_melon",
	recipe = {
		{'mcl_core:gold_nugget', 'mcl_core:gold_nugget', 'mcl_core:gold_nugget'},
		{'mcl_core:gold_nugget', 'mcl_farming:melon_item', 'mcl_core:gold_nugget'},
		{'mcl_core:gold_nugget', 'mcl_core:gold_nugget', 'mcl_core:gold_nugget'},
	}
})

minetest.register_craftitem("mcl_potions:dragon_breath", {
	description = S("Dragon's Breath"),
	_doc_items_longdesc = brewhelp,
	wield_image = "mcl_potions_dragon_breath.png",
	inventory_image = "mcl_potions_dragon_breath.png",
	-- TODO: Reveal item when it's actually useful
	groups = { brewitem = 1, not_in_creative_inventory = 1 },
	stack_max = 64,
})
