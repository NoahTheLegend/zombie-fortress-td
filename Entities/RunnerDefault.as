#include "RunnerCommon.as";
#include "Hitters.as";
#include "KnockedCommon.as"
#include "FireCommon.as"
#include "Help.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.Tag("medium weight");

	this.set_f32("damage_resistance", 1);
    this.set_f32("weakness", 1);

	//default player minimap dot - not for migrants
	//if (this.getName() != "migrant")
	//{
	//	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
	//}

	this.set_s16(burn_duration , 130);
	this.set_f32("heal amount", 0.0f);

	//fix for tiny chat font
	this.SetChatBubbleFont("hud");
	this.maxChatBubbleLines = 4;

	InitKnockable(this);
}

void onTick(CBlob@ this)
{
	this.Untag("prevent crouch");
	DoKnockedUpdate(this);

	// for scoreboard render
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	if ((getGameTime()+this.getNetworkID()) % 30 != 0) return;

	string[] inv_items;
	u16[]     sprite_frames;
	Vec2f[]  sprite_sizes;
	u16[] quantities;
	for (u8 i = 0; i < inv.getInventorySlots().x * inv.getInventorySlots().y; i++)
	{
		CBlob@ item = inv.getItem(i);
		if (item is null || item.getSprite() is null) continue;
		
		SpriteConsts@ consts = item.getSprite().getConsts();
		inv_items.push_back(consts.filename);
		sprite_frames.push_back(item.inventoryIconFrame);
		sprite_sizes.push_back(Vec2f(consts.frameWidth, consts.frameHeight));
		quantities.push_back(item.getQuantity());
	}

	this.set("scoreboard_items", inv_items);
	this.set("scoreboard_item_frames", sprite_frames);
	this.set("scoreboard_item_sizes", sprite_sizes);
	this.set("scoreboard_item_quantities", quantities);
}

// pick up efffects
// something was picked up

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/PutInInventory.ogg");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getSprite().PlaySound("/Pickup.ogg");

	this.ClearButtons();

	if (isClient())
	{
		RemoveHelps(this, "help throw");

		if (!attached.hasTag("activated"))
			SetHelp(this, "help throw", "", getTranslatedString("${ATTACHED}$Throw    $KEY_C$").replace("{ATTACHED}", getTranslatedString(attached.getName())), "", 2);
	}

	// check if we picked a player - don't just take him out of the box
	/*if (attached.hasTag("player"))
	this.server_DetachFrom( attached ); CRASHES*/
}

// set the Z back
// The baseZ is assumed to be 0
void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.getSprite().SetZ(0.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("migrant") || this.hasTag("dead");
}

// make Suicide ignore invincibility
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.exists("damage_resistance"))
	{
		damage *= this.get_f32("damage_resistance");
	}
	if (this.hasTag("invincible") && customData == 11)
		this.Untag("invincible");
	return damage;
}
