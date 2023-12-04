#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"
#include "MakeScroll.as"
#include "ScrollCommon.as";

void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
    shape.SetGravityScale(0);

    shape.SetStatic(true);

    this.getSprite().SetZ(-5);
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(3,2));	
	this.set_string("shop description", "Materialize");
	this.set_u8("shop icon", 12);
	{
		ShopItem@ s = addShopItem(this, "Wood", "$mat_wood$", "mat_wood", "Transform coins into wood planks.", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Stone", "$mat_stone$", "mat_stone", "Transform coins rocks.", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 75);
	}
	{
		ShopItem@ s = addShopItem(this, "Gold", "$mat_gold$", "mat_gold", "Transform coins into gold ingots.", false);
		AddRequirement(s.requirements, "coin", "", "Denars", 150);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of Drought", "$scroll_drought$", "scroll_drought", "Evaporate nearby water.", false);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of Resurrection", "$scroll_revive$", "scroll_revive", "Resurrect two of dead dwarves to help you.", false);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");

		u16 caller, item;
		string name;

		if (!params.saferead_netid(caller) || !params.saferead_netid(item) || !params.saferead_string(name))
		{
			return;
		}

		CBlob@ callerBlob = getBlobByNetworkID(caller);
		if (callerBlob is null)
		{
			return;
		}

		if (isServer())
		{
			
		}
	}
}
