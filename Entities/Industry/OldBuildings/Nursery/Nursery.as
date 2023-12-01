// Nursery

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;
	
	
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(5,1));	
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{	 
		ShopItem@ s = addShopItem( this, "Pine tree seed", "$tree_pine$", "tree_pine", "", true, true );
		AddRequirement( s.requirements, "coin", "", "Coins", 100 );
	}

	{
		ShopItem@ s = addShopItem( this, "Oak tree seed", "$tree_bushy$", "tree_bushy", "", true, true );
		AddRequirement( s.requirements, "coin", "", "Coins", 100 );
	}
	
	{
		ShopItem@ s = addShopItem( this, "Grain plant seed", "$grain_plant$", "grain_plant", "", true );
		AddRequirement( s.requirements, "coin", "", "Coins", 50 );
	}
	
	{
		ShopItem@ s = addShopItem( this, "Bush seed", "$bush$", "bush", "", true );
		AddRequirement( s.requirements, "coin", "", "Coins", 50 );
	}
	
	{
		ShopItem@ s = addShopItem( this, "Flowers seed", "$flowers$", "flowers", "", true );
		AddRequirement( s.requirements, "coin", "", "Coins", 50 );
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
	}
}
