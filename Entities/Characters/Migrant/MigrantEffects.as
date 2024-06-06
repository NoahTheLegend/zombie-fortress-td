// Migrant effects/sounds for client

#include "MigrantCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 29;
	this.set_u32("scream_delay", getGameTime());
}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead"))
	{
		CPlayer@ p = getLocalPlayer();
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

	if (!this.hasTag("migrant"))
	{
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		return;
	}

	u8 strategy = this.get_u8("strategy");

	if (this.get_bool("changed_strategy") && strategy == Strategy::follow && XORRandom(2) == 0)
	{
		this.getSprite().PlaySound("/MigrantSayHello", 1.0f, 0.95f + XORRandom(16)*0.01f);
		this.set_bool("changed_strategy", false);
	}

	if (this.get_bool("panic") || this.get_bool("zombie_nearby"))
	{
		if (XORRandom(5) == 0)
		{
			this.getSprite().PlaySound("/MigrantScream", 1.0f, 0.95f + XORRandom(11)*0.01f);  // temp: fix for migrants screaming all the time
		}
	}
	else
	{
		const int t = this.getCurrentScript().tickFrequency;
		const int t2 = this.getTickSinceCreated();
		if (t2 > t && t2 <= t * 2 && this.isOverlapping("hall"))
		{
			this.getSprite().PlaySound("/" + getTranslatedString("MigrantSayHello"), 1.0f, 0.95f + XORRandom(16)*0.01f);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage < this.getHealth() && this.get_u32("scream_delay") + 30 < getGameTime())
	{
		this.set_u32("scream_delay", getGameTime());
		this.getSprite().PlaySound("/MigrantScream", 1.0f, 0.95f + XORRandom(11)*0.01f);
	}
	return damage;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		if (XORRandom(2) == 0 && blob.hasTag("player"))
		{
			if (blob.getTeamNum() == this.getTeamNum())
			{
				if (XORRandom(5) == 0 && !blob.hasTag("migrant"))
				{
					this.getSprite().PlaySound("/" + getTranslatedString("MigrantSayFriend"), 1.0f, 0.95f + XORRandom(16)*0.01f);
				}
			}
			else if (this.getTeamNum() < 10)
			{
				this.getSprite().PlaySound("/" + getTranslatedString("MigrantSayNo"), 1.0f, 0.95f + XORRandom(16)*0.01f);
			}
		}
	}
	//	else if (blob.getName() == "warboat" || blob.getName() == "longboat") // auto-get inside boat
	//	{
	//		blob.server_PutInInventory( this );
	//		this.getSprite().PlaySound("/PopIn.ogg");
	//	}
	//}
}

// sound when player spawns into migrant

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		if (player.isMyPlayer())
		{
			Sound::Play("Respawn.ogg");
		}
		else
		{
			this.getSprite().PlaySound("Respawn.ogg");
		}
	}
}


void onChangeTeam(CBlob@ this, const int oldTeam)
{
	// calm down

	this.set_u8("strategy", 0);
}
