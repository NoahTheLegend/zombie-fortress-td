// function for setting a builder blob to migrant
#include "RunnerCommon.as";
#include "ArcherCommon.as"

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
		defend,
		find_crystal,
		follow,
		sum
	}
};


const f32 SEEK_RANGE = 400.0f;
const f32 ENEMY_RANGE = 100.0f;

void SetStrategy(CBlob@ blob, const u8 strategy)
{
	if (!isServer()) return;

	blob.set_u8("strategy_delay", 45);
	blob.set_Vec2f("last_order_pos", blob.getPosition());

	blob.set_bool("changed_strategy", true);
	blob.set_u8("strategy", strategy);
	
	CBitStream params;
	params.write_bool(true);
	params.write_u8(strategy);
	blob.SendCommand(blob.getCommandID("sync_strategy"), params);
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

void Runaway(CBlob@ blob, CBlob@ target)
{
	blob.setKeyPressed(key_left, false);
	blob.setKeyPressed(key_right, false);
	if (target.getPosition().x > blob.getPosition().x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}
}

void AttackBlobKnight(CBlob@ blob, CBlob @target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	Vec2f targetVector = targetPos - mypos;
	f32 targetDistance = targetVector.Length();
	const s32 difficulty = 10;

	if (targetDistance > blob.getRadius() + 15.0f)
	{
		if (!isFriendAheadOfMe(blob, target))
		{
			Chase(blob, target);
		}
	}

	JumpOverObstacles(blob, targetPos);

	// aim always at enemy
	blob.setAimPos(targetPos);

	const u32 gametime = getGameTime();

	bool shieldTime = gametime - blob.get_u32("shield time") < uint(8 + difficulty * 1.33f + XORRandom(20));
	bool backOffTime = gametime - blob.get_u32("backoff time") < uint(1 + XORRandom(20));

	if (target.isKeyPressed(key_action1))   // enemy is attacking me
	{
		int r = XORRandom(35);
		if (difficulty > 2 && r < 2 && (!backOffTime || difficulty > 4))
		{
			blob.set_u32("shield time", gametime);
			shieldTime = true;
		}
		else if (difficulty > 1 && r > 32 && !shieldTime)
		{
			// raycast to check if there is a hole behind

			Vec2f raypos = mypos;
			raypos.x += targetPos.x < mypos.x ? 32.0f : -32.0f;
			Vec2f col;
			if (getMap().rayCastSolid(raypos, raypos + Vec2f(0.0f, 32.0f), col))
			{
				blob.set_u32("backoff time", gametime);								    // base on difficulty
				backOffTime = true;
			}
		}
	}
	else
	{
		// start attack
		if (XORRandom(Maths::Max(3, 30 - (difficulty + 4) * 2)) == 0 && (getGameTime() - blob.get_u32("attack time")) > 10)
		{
			// base on difficulty
			blob.set_u32("attack time", gametime);
		}
	}

	if (shieldTime)   // hold shield for a while
	{
		blob.setKeyPressed(key_action2, true);
	}
	else if (backOffTime)   // back off for a bit
	{
		Runaway(blob, target);
	}
	else if (targetDistance < 32.0f && getGameTime() - blob.get_u32("attack time") < (Maths::Min(11, 30))) // release and attack when appropriate
	{
		if (!target.isKeyPressed(key_action1))
		{
			blob.setKeyPressed(key_action2, false);
		}

		blob.setKeyPressed(key_action1, true);
	}
}

void AttackBlobArcher(CBlob@ blob, CBlob @target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	Vec2f targetVector = targetPos - mypos;
	f32 targetDistance = targetVector.Length();
	const s32 difficulty = 1;

	JumpOverObstacles(blob, targetPos);

	const u32 gametime = getGameTime();

	// fire

	if (targetDistance > 8.0f)
	{
		u32 fTime = blob.get_u32("fire time");  // first shot
		bool fireTime = gametime < fTime;

		if (!fireTime && (fTime == 0 || XORRandom(10) == 0))
		{
			const f32 vert_dist = Maths::Abs(targetPos.y - mypos.y);
			const u32 shootTime = ArcherParams::ready_time*1.5f;
			blob.set_u32("fire time", gametime + shootTime);
		}

		if (fireTime)
		{
			bool hardShot = true;
			blob.setAimPos(target.getPosition() + target.getVelocity());
			blob.setKeyPressed(key_action1, true);
		}
	}
	else
	{
		blob.setAimPos(targetPos);
	}
}

void Chase(CBlob@ blob, CBlob@ target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	blob.setKeyPressed(key_left, false);
	blob.setKeyPressed(key_right, false);
	if (targetPos.x < mypos.x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}

	if (targetPos.y + getMap().tilesize < mypos.y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

bool isFriendAheadOfMe(CBlob @blob, CBlob @target, const f32 spread = 70.0f)
{
	// optimization
	if ((getGameTime() + blob.getNetworkID()) % 10 > 0 && blob.exists("friend ahead of me"))
	{
		return blob.get_bool("friend ahead of me");
	}

	CBlob@[] players;
	getBlobsByTag("player", @players);
	Vec2f pos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	for (uint i = 0; i < players.length; i++)
	{
		CBlob@ potential = players[i];
		Vec2f pos2 = potential.getPosition();
		if (potential !is blob && blob.getTeamNum() == potential.getTeamNum()
		        && (pos2 - pos).getLength() < spread
		        && (blob.isFacingLeft() && pos.x > pos2.x && pos2.x > targetPos.x) || (!blob.isFacingLeft() && pos.x < pos2.x && pos2.x < targetPos.x)
		        && !potential.hasTag("dead") && !potential.hasTag("migrant")
		   )
		{
			blob.set_bool("friend ahead of me", true);
			return true;
		}
	}
	blob.set_bool("friend ahead of me", false);
	return false;
}

void RandomTurn(CBlob@ blob)
{
	if (XORRandom(6) == 0)
	{
		CMap@ map = getMap();
		blob.setAimPos(Vec2f(XORRandom(int(map.tilemapwidth * map.tilesize)), XORRandom(int(map.tilemapheight * map.tilesize))));
	}
}

void JumpOverObstacles(CBlob@ blob, Vec2f target_pos, bool reverse = false)
{
	Vec2f pos = blob.getPosition();
	if (!blob.isOnLadder())
	{

		if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(pos + Vec2f(1.3f * blob.getRadius(), blob.getRadius()) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
		        (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(pos + Vec2f(-1.3f * blob.getRadius(), blob.getRadius()) * 1.0f) || blob.getShape().vellen < 0.1f)))
		{
			blob.setKeyPressed(key_up, true);
		}

		if (blob.isOnWall())
		{
			RunnerMoveVars@ moveVars;
			if (blob.get("moveVars", @moveVars))
			{
				bool go_left = target_pos.x < pos.x;
				if (moveVars.wallrun_count < 2)
					blob.setKeyPressed(go_left ? key_left : key_right, true);

				blob.setKeyPressed(key_up, true);
			}
		}
	}
	else
	{
		bool below = target_pos.y > pos.y;
		if (reverse) below = !below;

		if (below)
			blob.setKeyPressed(key_down, true);
		else
			blob.setKeyPressed(key_up, true);
	}
}