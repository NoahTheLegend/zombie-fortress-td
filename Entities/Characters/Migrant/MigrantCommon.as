// function for setting a builder blob to migrant

namespace Strategy
{
	enum strats
	{
		idle = 0,
		follow,
		find_crystal,
		sum
	}
};

namespace FStrategy
{
	enum strats
	{
		idle = 0,
		follow,
		find_crystal,
		defend,
		sum
	}
};


const f32 SEEK_RANGE = 400.0f;
const f32 ENEMY_RANGE = 100.0f;

void SetStrategy(CBlob@ blob, const u8 strategy)
{
	blob.set_u8("strategy_delay", 30);
	blob.set_bool("changed_strategy", true);
	blob.Sync("changed_strategy", true);
	blob.set_u8("strategy", strategy);
	blob.Sync("strategy", true);
}

shared void SetMigrant(CBlob@ blob, bool isMigrant)
{
	if (blob is null)
		return;

	if (isMigrant) // on
	{
		blob.Tag("migrant");
		blob.getBrain().server_SetActive(true);
	}
	else // off
	{
		blob.Untag("migrant");
		blob.getBrain().server_SetActive(false);
	}
}

shared CBlob@ CreateMigrant(Vec2f pos, int team, string blobname = "migrant")
{
	CBlob@ blob = server_CreateBlobNoInit(blobname);
	if (blob !is null)
	{
		//setup ready for init
		blob.setSexNum(XORRandom(2));
		blob.server_setTeamNum(team);
		blob.setPosition(pos);

		blob.Init();

		blob.SetFacingLeft(XORRandom(2) == 0);

		SetMigrant(blob, true);   //requires brain -> after init
	}
	return blob;
}

bool isRoomFullOfMigrants(CBlob@ this)
{
	return this.get_u8("migrants count") >= this.get_u8("migrants max");
}

bool needsReplenishMigrant(CBlob@ this)
{
	return this.get_u8("migrants count") < this.get_u8("migrants max");
}

void AddMigrantCount(CBlob@ this, int add = 1)
{
	this.set_u8("migrants count", this.get_u8("migrants count") + add);
}

void DecMigrantCount(CBlob@ this, int dec = 1)
{
	this.set_u8("migrants count", this.get_u8("migrants count") - dec);
}
