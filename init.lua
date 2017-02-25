local style =  "size[8,9]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[5,8.85;" .. minetest.colorize("#777777", "Signed letters cannot be edited!") .. "]"

local paper_formspec = style ..
		"label[0.25,0.25;Write a letter:]" ..
		"textarea[0.5,1;7.5,7.5;text;;${text}]" ..
		"button[0.25,8;2,1;save;Save]" ..
		"button[4.75,8;3,1;sign;Sign the letter]"

local letter_formspec = style ..
		"label[0.25,0.25;Edit the letter:]" ..
		"textarea[0.5,1;7.5,7.5;text;;${text}]" ..
		"button[0.25,8;2,1;save;Save]" ..
		"button[4.75,8;3,1;sign;Sign the letter]"

local signed_letter_formspec = style ..
		"textarea[0.5,0.25;7.5,8.5;text;;${text}]"

local function save(pos, fields, sender)
	local node = minetest.get_node(pos)
	if fields.text == "" then
		if node.name ~= "default:paper" then
			node.name = "default:paper"
			minetest.swap_node(pos, node)
		end
		return
	end
	if node.name ~= "default:letter" then
		node.name = "default:letter"
		minetest.swap_node(pos, node)
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("text", fields.text)
	meta:set_string("formspec", letter_formspec)
end

local function sign(pos, sender)
	local node = minetest.get_node(pos)
	if node.name ~= "default:signed_letter" then
		node.name = "default:signed_letter"
		minetest.swap_node(pos, node)
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("signed_by", sender:get_player_name())
	local signed_by = minetest.formspec_escape(meta:get_string("signed_by"))
	meta:set_string("formspec", signed_letter_formspec .. "label[0.25,8;Signed by " .. signed_by .. "]")
end

minetest.register_node(":default:paper", {
	description = "Paper",
	tiles = {
		"default_paper.png",
		"default_paper.png^[transformFY",
	},
	inventory_image = "default_paper.png",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	paramtype = "light",
	walkable = false,
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.4375, -0.5, -0.4375, 0.4375, -0.49, 0.4375 },
		}
	},
	groups = { flammable = 3, snappy = 3 },
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", paper_formspec)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.save then
			save(pos, fields, sender)
		elseif fields.sign then
			save(pos, fields, sender)
			sign(pos, sender)
		end
	end,
})

minetest.register_node(":default:letter", {
	description = "Letter",
	tiles = {
		"default_paper.png^ts_paper_text.png",
		"default_paper.png^ts_paper_text.png^[transformFY",
	},
	inventory_image = "default_paper.png^ts_paper_text.png",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	paramtype = "light",
	walkable = false,
	stack_max = 1,
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.4375, -0.5, -0.4375, 0.4375, -0.49, 0.4375 },
		}
	},
	groups = { flammable = 3, snappy = 3 },
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", letter_formspec)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.save then
			save(pos, fields, sender)
		elseif fields.sign then
			save(pos, fields, sender)
			sign(pos, sender)
		end
	end,
	on_dig = function(pos, node, digger)
		local meta = minetest.get_meta(pos)
		if digger:is_player() and digger:get_inventory() then
			digger:get_inventory():add_item("main", {
				name = "default:letter",
				count = 1,
				wear = 0,
				metadata = minetest.serialize(meta:to_table())
			})
		end
		minetest.remove_node(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:from_table(minetest.deserialize(itemstack:get_metadata()))
		meta:set_string("formspec", letter_formspec)
	end
})

minetest.register_node(":default:signed_letter", {
	description = "Letter",
	tiles = {
		"default_paper.png^ts_paper_text.png^ts_paper_seal.png",
		"default_paper.png^ts_paper_text.png^ts_paper_seal.png^[transformFY",
	},
	inventory_image = "default_paper.png^ts_paper_text.png^ts_paper_seal.png",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	paramtype = "light",
	walkable = false,
	stack_max = 1,
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.4375, -0.5, -0.5, 0.4375, -0.49, 0.4375 },
		}
	},
	groups = { flammable = 3, snappy = 3 },
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local text = meta:get_string("text")
		local signed_by = meta:get_string("signed_by")
		meta:set_string("formspec", style .. "label[0.5,1;" .. text .. "]label[0.25,8;Signed by " .. signed_by .. "]")
	end,
	on_dig = function(pos, node, digger)
		local meta = minetest.get_meta(pos)
		if digger:is_player() and digger:get_inventory() then
			digger:get_inventory():add_item("main", {
				name = "default:signed_letter",
				count = 1,
				wear = 0,
				metadata = minetest.serialize(meta:to_table())
			})
		end
		minetest.remove_node(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:from_table(minetest.deserialize(itemstack:get_metadata()))
		local signed_by = minetest.formspec_escape(meta:get_string("signed_by"))
		meta:set_string("formspec", signed_letter_formspec .. "label[0.25,8;Signed by " .. signed_by .. "]")
	end
})

minetest.register_craft({
	type = "shapeless",
	output = "default:letter",
	recipe = {"default:paper", "default:letter"}
})

minetest.register_craft({
	type = "shapeless",
	output = "default:signed_letter",
	recipe = {"default:paper", "default:signed_letter"}
})

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() ~= "default:letter" and itemstack:get_name() ~= "default:signed_letter" then
		return
	end

	local original
	local index
	for i = 1, player:get_inventory():get_size("craft") do
		if old_craft_grid[i]:get_name() == "default:letter" or old_craft_grid[i]:get_name() == "signed_letter" then
			original = old_craft_grid[i]
			index = i
		end
	end
	if not original then
		return
	end
	local copymeta = original:get_metadata()
	itemstack:set_metadata(copymeta)
	craft_inv:set_stack("craft", index, original)
end)

minetest.register_craft({
	type = "fuel",
	recipe = "default:letter",
	burntime = 1,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:signed_letter",
	burntime = 1,
})