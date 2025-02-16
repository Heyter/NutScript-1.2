PLUGIN.name = "Grid Inventory"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Inventory system where items have a size and fit in a grid."

local INVENTORY_TYPE_ID = "grid"
PLUGIN.INVENTORY_TYPE_ID = INVENTORY_TYPE_ID

nut.util.include("sh_grid_inv.lua")
nut.util.include("sv_transfer.lua")
nut.util.include("sv_access_rules.lua")

function PLUGIN:GetDefaultInventoryType(character)
	return INVENTORY_TYPE_ID
end

if (SERVER) then
	-- Called when item has been dragged on top of target (also an item).
	function PLUGIN:ItemCombine(client, item, target)
		if (target.onCombine) then
			if (target:call("onCombine", client, nil, item)) then -- when other items dragged into the item.
				return
			end
		end

		if (item.onCombineTo) then
			if (item and item:call("onCombineTo", client, nil, target)) then -- when you drag the item on something
				return
			end
		end
	end

	-- Called when an item has been dragged out of its inventory.
	function PLUGIN:ItemDraggedOutOfInventory(client, item)
		item:interact("drop", client)
	end
else
	net.Receive("nutMoveItem", function()
		local itemID = net.ReadUInt(32)
		local item = nut.item.instances[itemID]
		if not item then return end

		local x, y = net.ReadUInt(10), net.ReadUInt(10)
		item.data.x = x
		item.data.y = y

		local inventory = nut.inventory.instances[item.invID]
		if not inventory then return end

		hook.Run("InventoryItemMoved", inventory, item, x, y)
	end)

	net.Receive("nutItemTransfer", function()
		local itemID = net.ReadUInt(32)
		local item = nut.item.instances[itemID]

		local oldInventory = nut.inventory.instances[net.ReadUInt(32)]
		local newInvID = net.ReadUInt(32)
		local newInventory = nut.inventory.instances[newInvID]

		if oldInventory then
			oldInventory.items[itemID] = nil
			hook.Run("InventoryItemRemoved", oldInventory, item)
		end

		if newInventory and item then
			newInventory.items[itemID] = item
			hook.Run("InventoryItemAdded", newInventory, item)
		end

		if item then item.invID = newInvID end
	end)
end