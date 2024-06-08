// Enginering Workshop

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_castle_back);
	//this.getSprite().getConsts().accurateLighting = true;
	

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4,1));	
	this.set_string("shop description", "Buy Defensives");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Bomb", "$bomb$", "mat_bombs", "Explosive bomb.", true);
		AddRequirement(s.requirements, "coin", "", "Denars", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Water Bomb", "$waterbomb$", "mat_waterbombs", "A bottle with water.", true);
		AddRequirement(s.requirements, "coin", "", "Denars", 2);
	}
	{
		ShopItem@ s = addShopItem(this, "Mine", getTeamIcon("mine", "Mine.png", 0, Vec2f(16, 16), 1), "mine", "Instant mine.", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Keg", getTeamIcon("keg", "Keg.png", 0, Vec2f(16, 16), 0), "keg", "High-explosive barrel.", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 200);
	}
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
