// Enginering Workshop

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_castle_back);
	//this.getSprite().getConsts().accurateLighting = true;
	

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(5,1));	
	this.set_string("shop description", "Buy Fire Things");
	this.set_u8("shop icon", 25);

	
	{
		ShopItem@ s = addShopItem( this, "Mounted Crossbow", "$mounted_bow$", "mounted_bow", "Ideal for roofs and boats.", false, true );
		AddRequirement( s.requirements, "coin", "", "Coins", 200 );
		s.crate_icon = 6;
	}

	{
		ShopItem@ s = addShopItem(this, "Crossbow Arrows", "$mat_rarrows$", "mat_rarrows", "Arrows for the Mounted Crossbow.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 100 );
	}	
	
	{
		ShopItem@ s = addShopItem( this, "Mounted Bazooka", "$mounted_bazooka$", "mounted_bazooka", "For those explosive needs.", false, true );
		AddRequirement( s.requirements, "coin", "", "Coins", 300 );
		s.crate_icon = 23;
	}	

	{
		ShopItem@ s = addShopItem(this, "Bazooka Rockets", "$mat_rockets$", "mat_rockets", "Rockets for the Mounted Bazooka.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 100 );
	}

	{
		ShopItem@ s = addShopItem(this, "Satchel", "$bomb_satchel$", "bomb_satchel", "A special kind of sticky bomb. Any class can use it.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 35 );
	}

//	{
//		ShopItem@ s = addShopItem(this, "Mounted Cannon", "$mounted_cannon$", "mounted_cannon", "For more explosive needs.", true);
//		AddRequirement(s.requirements, "coin", "", "Coins", 50 );
//	}

}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	u8 kek = caller.getTeamNum();	
	if (kek == 0)
	{
		this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "builder"*/ );
	}
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/ChaChing.ogg" );
	}
}
