// Swing Door logic

#include "Hitters.as"

const f32 MIN_VELLEN_TO_BREAK = 3.0f; // movement velocity required to break the block

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);
	this.getSprite().getConsts().accurateLighting = true;

	getMap().server_SetTile(this.getPosition(), CMap::tile_castle_back);

	this.getCurrentScript().tickFrequency = 0;

	this.getShape().SetStatic(true);

	this.Tag("blocks water");
	this.Tag("explosion always teamkill");
	this.Tag("builder always hit");
	this.Tag("builder urgent hit");

	this.getSprite().SetFrameIndex(XORRandom(2));
}

string getRandomRubbleSound()
{
	return "Rubble"+(XORRandom(2)+1)+".ogg";
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound(getRandomRubbleSound());
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		f32 vellen = (blob.getOldPosition()-blob.getPosition()).Length();

		if (vellen > MIN_VELLEN_TO_BREAK)
		{
			if (isServer())
				this.server_Die();

			if (isClient() && this.getSprite() !is null)
				this.getSprite().Gib();
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound(getRandomRubbleSound());
}