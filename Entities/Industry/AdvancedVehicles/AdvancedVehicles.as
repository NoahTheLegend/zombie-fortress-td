// Advanced Vehicles

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
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	
	{
		ShopItem@ s = addShopItem( this, "Balloon", "$balloon$", "balloon", "Hold left click for up, right click for down. Don't get too high though!", false, true );
		AddRequirement( s.requirements, "coin", "", "Coins", 1000 );
	}

	{
		ShopItem@ s = addShopItem(this, "Zeppelin", "$zeppelin$", "zeppelin", "Like a bigger balloon.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 2000 );
	}	

//	{
//		ShopItem@ s = addShopItem(this, "Glider", "$glider$", "glider", "Another thing for flying around with.", true);
//		AddRequirement(s.requirements, "coin", "", "Coins", 1000 );
//	}	

//	{
//		ShopItem@ s = addShopItem(this, "Glider", "$glider$", "glider", "Another thing for flying around with.", true);
//		AddRequirement(s.requirements, "coin", "", "Coins", 1000 );
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
