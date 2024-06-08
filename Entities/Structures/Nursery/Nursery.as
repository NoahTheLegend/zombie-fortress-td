// Nursery

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

#include "MakeSeed.as"

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;
	
	
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4,2));	
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	this.Tag("builder always hit");
	this.Tag("builder urgent hit");

	{
		ShopItem@ s = addShopItem(this, "Wheat", "$wheatbunch$", "wheatbunch", "Bunch of Wheat", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Nut", "$nut$", "nut", "Nut", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 2);
	}
	{
		ShopItem@ s = addShopItem(this, "Grass", "$grass$", "grass", "Grass", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 2);
	}
	{
		ShopItem@ s = addShopItem(this, "Bone", "$bone$", "bone", "Chicken bone", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Oak tree seed", "$tree_bushy$", "tree_bushy", "Oak seed", false);
		AddRequirement( s.requirements, "coin", "Oak seed", "Denars", 750 );
		s.spawnNothing = true;
	}
	{	 
		ShopItem@ s = addShopItem(this, "Pine tree seed", "$tree_pine$", "tree_pine", "Pine seed", false);
		AddRequirement( s.requirements, "coin", "Pine seed", "Denars", 750 );
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bush seed", "$bush$", "bush", "Bush seed", false);
		AddRequirement( s.requirements, "coin", "Bush seed", "Denars", 5 );
	}
	{
		ShopItem@ s = addShopItem(this, "Flowers seeds", "$flowers$", "flowers", "Flowers seeds", false);
		AddRequirement( s.requirements, "coin", "Flowers seeds", "Denars", 10 );
	}
	
	this.set_string("required class", "builder");
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "builder"*/ );
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/ChaChing.ogg" );

		if (!isServer()) return;
		u16 callerid, itemid;
		string name;

		if (!params.saferead_netid(callerid) || !params.saferead_netid(itemid) || !params.saferead_string(name))
		{
			return;
		}

		CBlob@ caller = getBlobByNetworkID(callerid);
		CBlob@ item = getBlobByNetworkID(itemid);
		if (name.find("tree") != -1)
		{
			if (name == "tree_pine") @item = server_MakeSeed(this.getPosition(), "tree_bushy", 400, 2, 4);
			else if (name == "tree_bushy") @item = server_MakeSeed(this.getPosition(), "tree_bushy", 400, 3, 4);
			//else if (name == "-g") @item = server_MakeSeed(this.getPosition(), "grain_plant", 300, 1, 4);
		}
		if (caller is null || item is null) return;

		AttachmentPoint@ pc = caller.getAttachments().getAttachmentPointByName("PICKUP");
		if (pc is null) return;

		bool has_carried = false;
		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null) has_carried = true;

		CInventory@ callerInv = caller.getInventory();
		if (callerInv is null) return;
		caller.server_AttachTo(item, pc);
		if (!item.canBePutInInventory(caller) || !has_carried || callerInv.isFull())
		{
			if (has_carried) caller.server_PutInInventory(carried);
			caller.server_Pickup(item);
			caller.server_AttachTo(item, pc);
		}
		else if (!callerInv.isFull())
		{
			caller.server_PutInInventory(item);
		}
	}
}
