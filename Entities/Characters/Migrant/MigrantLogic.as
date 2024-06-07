#include "DecayCommon.as";
#include "MigrantCommon.as";
#include "KnockedCommon.as";

const string pickable_tag = "pickable";

void onInit(CBlob@ this)
{
	this.set_f32("gib health", -1.5f);
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("ignore_arrow");

	this.addCommandID("switch_strategy");
	this.addCommandID("switch_class");
	this.addCommandID("sync_strategy");
	this.set_u32("switch_button_delay", 0);

	AddIconToken("$migrant_follow$", "Orders.png", Vec2f(32,32), 4);
	AddIconToken("$migrant_find_crystal$", "Orders.png", Vec2f(32,32), 0);
	AddIconToken("$migrant_idle$", "Orders.png", Vec2f(32,32), 3);

	//AddIconToken("$migrant_claim$", "Orders.png", Vec2f(32,32), 1);
	//AddIconToken("$migrant_dismiss$", "Orders.png", Vec2f(32,32), 2);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null || this.hasTag("dead")) return;
	if (this.getDistanceTo(caller) > 32.0f) return;
	if (this.get_u32("switch_button_delay") > getGameTime()) return;

	u8 strategy = this.get_u8("strategy");
	string icon = "";
	Vec2f offset = Vec2f(0, -12);
	string description = "";

	switch(strategy) // switch to next strat
	{
		case Strategy::idle:
		{
			icon = "$migrant_follow$";
			description = "\nFollow me";
			break;
		}
		case Strategy::follow:
		{
			icon = "$migrant_find_crystal$";
			description = "\nGo to crystal";
			break;
		}
		case Strategy::find_crystal:
		{
			icon = "$migrant_idle$";
			description = "\nStay here";
			break;
		}
	}

	CBitStream params;
	params.write_u8(strategy);
	params.write_u16(caller.getNetworkID());
	CButton@ button = caller.CreateGenericButton(
			icon,                                
			offset,                           
			this,                                                    
			this.getCommandID("switch_strategy"),                                              
			description,
			params
		);

	CMap@ map = getMap();
	if (map is null) return;

	bool near_crystal = false;
	CBlob@[] bs;
	getBlobsByTag("crystal", @bs);
	for (u8 i = 0; i < bs.size(); i++)
	{
		CBlob@ b = bs[i];
		if (b is null) continue;
		
		if (b.getDistanceTo(this) < 48.0f
			&& !map.rayCastSolidNoBlobs(this.getPosition(), b.getPosition()))
		{
			near_crystal = true;
			break;
		}
	}

	if (!near_crystal) return;

	CBitStream params1;
	params1.write_u16(caller.getNetworkID());
	CButton@ button1 = caller.CreateGenericButton(
			28,                             
			Vec2f(0,8),                           
			this,                                                    
			this.getCommandID("switch_class"),                                              
			"\nArm this migrant",
			params1
		);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("switch_strategy"))
	{
		u8 strategy = (params.read_u8()+1) % Strategy::sum;
		u16 id = params.read_u16();

		this.set_u32("switch_button_delay", getGameTime()+5);

		switch(strategy)
		{
			case Strategy::idle:
			{
				this.set_u16("follow_id", 0);
				break;
			}
			case Strategy::follow:
			{
				CBlob@ caller = getBlobByNetworkID(id);
				if (caller is null || caller.hasTag("dead") || !caller.hasTag("player"))
					id = 0;

				this.set_u16("follow_id", id);
				break;
			}
			case Strategy::find_crystal:
			{
				break;
			}
		}

		SetStrategy(this, strategy);
	}
	else if (cmd == this.getCommandID("switch_class"))
	{
		if (this.hasTag("switched")) return;
		this.Tag("switched");

		if (isClient())
		{
			this.getSprite().PlaySound("ResearchComplete.ogg", 1.5f, 1.0f);
		}
		if (isServer())
		{
			CBlob@ b = CreateMigrant(this.getPosition(), 1, "knight");
			if (b !is null)
			{
				SetStrategy(b, FStrategy::idle);
				this.server_Die();
			}
		}
	}
	else if (cmd == this.getCommandID("sync_strategy"))
	{
		if (isClient())
		{
			bool change = params.read_bool();
			u8 strategy = params.read_u8();

			this.set_bool("changed_strategy", change);
			this.set_u8("strategy", strategy);
		}
	}
}

void onTick(CBlob@ this)
{
	DoKnockedUpdate(this);

	if (this.hasTag("dead"))
		return;

	if (this.hasTag("idle"))
	{
		this.Untag(pickable_tag);
		this.Sync(pickable_tag, true);

		return;
	}

	if (!getNet().isServer()) return; //---------------------SERVER ONLY
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return (this.getTeamNum() == byBlob.getTeamNum() && !this.getShape().isStatic() && this.hasTag(pickable_tag));
}
