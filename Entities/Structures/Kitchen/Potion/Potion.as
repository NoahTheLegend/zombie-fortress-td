#include "PotionEffectsCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("add_effect");

	this.Tag("potion");
	this.Tag("medium weight");
	this.Tag("material");

	this.set_u8("tier", 0);
	this.set_u8("effect", 0);

	this.getCurrentScript().tickFrequency = 3;

	Update(this);
}

void Update(CBlob@ this)
{
	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();
	u8 tier = this.get_u8("tier");
	sprite.animation.frame = tier;
	this.inventoryIconFrame = sprite.animation.frame;
	this.setInventoryName(tier == 0 ? "Lesser Potion" : tier == 1 ? "Potion" : "Greater Potion");
}

void onTick(CBlob@ this)
{
	Update(this);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (blob.hasTag("flesh") ? false : blob.isCollidable());
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null || !this.isAttachedTo(caller)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());
	CButton@ button = caller.CreateGenericButton(
			22,                                
			Vec2f_zero,                           
			this,                                                    
			this.getCommandID("add_effect"),                                              
			"Drink",
			params
		);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("add_effect"))
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		caller.Untag("potion_drunk");

		caller.set_u32("potion_duration", getGameTime() + (20 + 20*this.get_u8("tier"))*30);
		caller.set_u8("potion_effect", this.get_u8("effect"));
		caller.set_u8("potion_tier", this.get_u8("tier"));
		
		if (isClient())
		{
			this.getSprite().PlaySound("Gulp.ogg");
		}
		//printf(""+this.get_u8("effect"));
		caller.AddScript("PotionEffect.as");
		this.server_Die();
	}
}