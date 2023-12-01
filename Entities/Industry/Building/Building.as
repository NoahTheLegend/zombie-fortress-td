﻿// Genreic building

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "Costs.as";
#include "CheckSpam.as";

//are builders the only ones that can finish construction?
const bool builder_only = false;

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(6,6));	
	this.set_string("shop description", "Construct");
	this.set_u8("shop icon", 12);
	
	this.Tag(SHOP_AUTOCLOSE);
	
	{
		ShopItem@ s = addShopItem(this, "Builder Shop", "$buildershop$", "buildershop", Descriptions::buildershop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50 );
	}
	{
		ShopItem@ s = addShopItem(this, "Knight Shop", "$knightshop$", "knightshop", Descriptions::knightshop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50 );
	}
	{
		ShopItem@ s = addShopItem(this, "Archer Shop", "$archershop$", "archershop", Descriptions::archershop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50 );
	}
	{
		ShopItem@ s = addShopItem( this, "Barracks", "$barracks$", "barracks", Descriptions::barracks );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 80 );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 80 );
	}
	{
		ShopItem@ s = addShopItem(this, "Quarters", "$quarters$", "quarters", Descriptions::quarters);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50 );
	}
	{
		ShopItem@ s = addShopItem( this, "Dorm", "$dorm$", "dorm", Descriptions::dorm );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 300 );
	}
	{
		ShopItem@ s = addShopItem(this, "Boat Shop", "$boatshop$", "boatshop", Descriptions::boatshop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200 );
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100 );
	}
	{
		ShopItem@ s = addShopItem(this, "Vehicle Shop", "$vehicleshop$", "vehicleshop", Descriptions::vehicleshop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200 );
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100 );
	}
	{
		ShopItem@ s = addShopItem( this, "Defense Shop", "$defenseshop$", "defenseshop", "Buy advanced weaponcraft." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 150 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 50 );
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100 );
	}
	{
		ShopItem@ s = addShopItem(this, "Storage Cache", "$storage$", "storage", Descriptions::storagecache);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50 );
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50 );
	}
	{
		ShopItem@ s = addShopItem(this, "Transport Tunnel", "$tunnel$", "tunnel", Descriptions::tunnel);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50 );
	}
	{
		ShopItem@ s = addShopItem( this, "Advanced Vehicles", "$advancedvehicles$", "advancedvehicles", "Buy advanced vehicles." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 300 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100 );
	}
	{
		ShopItem@ s = addShopItem( this, "Nursery", "$nursery$", "nursery", Descriptions::nursery );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 250 );
	}
	{
		ShopItem@ s = addShopItem( this, "Trader Shop", "$trader2$", "trader2", "Build a trader shop" );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 500 );
	}

	

	
	
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if(this.isOverlapping(caller))
		this.set_bool("shop available", !builder_only || caller.getName() == "builder" );
	else
		this.set_bool("shop available", false );
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	bool isServer = getNet().isServer();
	if (cmd == this.getCommandID("shop made item"))
	{
		this.Tag("shop disabled"); //no double-builds
		
		CBlob@ caller = getBlobByNetworkID( params.read_netid() );
		CBlob@ item = getBlobByNetworkID( params.read_netid() );
		if (item !is null && caller !is null)
		{
			this.getSprite().PlaySound("/Construct.ogg" ); 
			this.getSprite().getVars().gibbed = true;
			this.server_Die();

			// open factory upgrade menu immediately
			if (item.getName() == "factory")
			{
				CBitStream factoryParams;
				factoryParams.write_netid( caller.getNetworkID() );
				item.SendCommand( item.getCommandID("upgrade factory menu"), factoryParams );
			}
		}
	}
}
