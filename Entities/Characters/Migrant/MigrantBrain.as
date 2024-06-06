// Migrant brain

#define SERVER_ONLY

#include "EmotesCommon.as"
#include "MigrantCommon.as"
#include "RunnerCommon.as";

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	blob.set_bool("justgo", false);
	blob.set_Vec2f("target spot", Vec2f_zero);
	blob.set_u8("strategy", Strategy::find_crystal);
	blob.set_Vec2f("hold_position", Vec2f_zero);
	blob.set_u16("follow_id", 0);

	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || blob.getTeamNum() > 10)
		return;

	if (blob.getName() == "migrant")
		MigrantTick(this, blob);
	else if (blob.getName() == "knight")
		KnightTick(this, blob);
}

void KnightTick(CBrain@ this, CBlob@ blob) // todo: knight advanced movement? + attacks
{
	const bool isStatic = blob.getShape().isStatic();

	if (isStatic)
	{
		this.getCurrentScript().tickFrequency = 30;
	}
		
	u8 delay = blob.get_u8("strategy_delay");
	u8 strategy = FStrategy::idle;
	CBlob@ enemy = null;
	CBlob@ nearest_ally = null;
	
	Vec2f pos = blob.getPosition();
	if (!isStatic)
	{
		strategy = delay == 0 ? blob.get_u8("strategy") : FStrategy::idle;
		//printf("strat: "+strategy);

		CMap@ map = getMap();
		CBlob@[] bs;
		if (map !is null)
		{
			map.getBlobsInRadius(blob.getPosition(), 96.0f, @bs);
			for (u16 i = 0; i < bs.size(); i++)
			{
				CBlob@ b = bs[i];
				if (b is null || b is blob) continue;

				bool raycast = map.rayCastSolid(blob.getPosition(), b.getPosition());
				if (raycast) continue;

				if (b.hasTag("player"))
				{
					@nearest_ally = @b;
				}
				if (b.hasTag("zombie"))
				{
					@enemy = @b;
				}
			}
		}
		// normal AI
		if (blob.getHealth() / blob.getInitialHealth() > 0.25f || strategy == FStrategy::find_crystal)
		{
			CBlob@ target = strategy == FStrategy::idle ? null : this.getTarget();
			this.getCurrentScript().tickFrequency = strategy == FStrategy::idle ? 30 : 1;

			if (strategy == FStrategy::find_crystal) //crystals should heal nearby bots
			{
				CBlob@[] crystals;
				getBlobsByTag("crystal", @crystals);

				f32 dist = 99999.0f;
				u16 target_id = 0;
				for (u8 i = 0; i < crystals.size(); i++)
				{
					CBlob@ b = crystals[i];
					if (b is null) continue;

					f32 temp_dist = blob.getDistanceTo(b);
					if (temp_dist < dist)
					{
						dist = temp_dist;
						target_id = b.getNetworkID();
					}
				}

				if (target_id != 0)
				{
					blob.set_u16("follow_id", target_id);
					@target = getBlobByNetworkID(target_id);
					this.SetTarget(target);
				}
			}
			u16 follow_id = blob.get_u16("follow_id");
			if (strategy == FStrategy::follow || strategy == FStrategy::defend)
			{
				@target = getBlobByNetworkID(follow_id);
				if (target is null) SetStrategy(blob, Strategy::find_crystal);
				this.SetTarget(target);
			}

			if (strategy != FStrategy::idle && target !is null)
			{
				GoToBlob(this, target);
			}

			if (target !is null)
			{
				const int state = this.getState();

				// lose target if its killed (with random cooldown)
				if (target !is null)
					if ((XORRandom(10) == 0 && target.hasTag("dead")))
					{
						if (strategy == FStrategy::defend)
							SetStrategy(blob, FStrategy::find_crystal);

						this.SetTarget(null);
					}
			}
		}
	}

	if (!isStatic && blob.getHealth() / blob.getInitialHealth() <= 0.25f)
	{
		if (nearest_ally is null && strategy != FStrategy::find_crystal)
		{
			SetStrategy(blob, FStrategy::find_crystal);
		}
		else if (this.getTarget() !is null)
			GoToBlob(this, this.getTarget());
	}

	if (!isStatic && blob.isInWater())
	{
		this.getCurrentScript().tickFrequency = 1;
		blob.setKeyPressed(key_up, true);
	}

	if (delay > 0)
	{
		this.getCurrentScript().tickFrequency = 1;
		blob.sub_u8("strategy_delay", 1);
	}
}

void MigrantTick(CBrain@ this, CBlob@ blob)
{
	const bool isStatic = blob.getShape().isStatic();

	if (isStatic)
	{
		this.getCurrentScript().tickFrequency = 30;
	}
		
	u8 delay = blob.get_u8("strategy_delay");
	u8 strategy = Strategy::idle;
	bool has_player = false;
	bool has_zombie = false;
	bool panic = false;
	bool near_crystal = false;
	Vec2f enemy_pos = Vec2f_zero;
	CBlob@ nearest_ally = null;
	Vec2f pos = blob.getPosition();
	if (!isStatic)
	{
		strategy = delay == 0 ? blob.get_u8("strategy") : Strategy::idle;
		//printf("strat: "+strategy);

		CMap@ map = getMap();
		CBlob@[] bs;
		if (map !is null)
		{
			map.getBlobsInRadius(blob.getPosition(), 96.0f, @bs);
			for (u16 i = 0; i < bs.size(); i++)
			{
				CBlob@ b = bs[i];
				if (b is null || b is blob) continue;

				bool raycast = map.rayCastSolid(blob.getPosition(), b.getPosition());
				if (raycast) continue;

				if (b.hasTag("player"))
				{
					@nearest_ally = @b;
					has_player = true;
				}
				if (b.hasTag("zombie"))
				{
					enemy_pos = b.getPosition();
					has_zombie = true;
				}
				if (b.hasTag("crystal"))
					near_crystal = true;

				if (has_player && has_zombie)
					break;
			}

			if (has_zombie)
			{
				if (strategy == Strategy::idle || strategy == Strategy::find_crystal)
					panic = true;
			}
		}

		//printf("z: "+has_zombie+"; p: "+has_player);

		// normal AI
		if (!blob.get_bool("panic"))
		{
			CBlob @target = strategy == Strategy::idle ? null : this.getTarget();
			this.getCurrentScript().tickFrequency = strategy == Strategy::idle ? 30 : 1;

			if (strategy == Strategy::find_crystal)
			{
				CBlob@[] crystals;
				getBlobsByTag("crystal", @crystals);

				f32 dist = 99999.0f;
				u16 target_id = 0;
				for (u8 i = 0; i < crystals.size(); i++)
				{
					CBlob@ b = crystals[i];
					if (b is null) continue;

					f32 temp_dist = blob.getDistanceTo(b);
					if (temp_dist < dist)
					{
						dist = temp_dist;
						target_id = b.getNetworkID();
					}
				}

				if (target_id != 0)
				{
					blob.set_u16("follow_id", target_id);
					@target = getBlobByNetworkID(target_id);
					this.SetTarget(target);
				}
			}

			u16 follow_id = blob.get_u16("follow_id");
			if (strategy == Strategy::follow)
			{
				@target = getBlobByNetworkID(follow_id);
				if (target is null) SetStrategy(blob, Strategy::find_crystal);
				this.SetTarget(target);
			}

			if (strategy != Strategy::idle && target !is null)
			{
				GoToBlob(this, target);
			}

			if (target !is null)
			{
				const int state = this.getState();

				// lose target if its killed (with random cooldown)
				if (target !is null)
					if ((XORRandom(10) == 0 && target.hasTag("dead")))
					{
						this.SetTarget(null);
					}
			}
		}
	}

	if (!isStatic && blob.get_bool("panic"))
	{
		if (nearest_ally !is null)
		{
			GoToBlob(this, nearest_ally);
		}
		else
		{
			bool go_right = enemy_pos.x < pos.x;
			blob.setKeyPressed(go_right ? key_right : key_left, true);
			JumpOverObstacles(blob, blob.getPosition() + Vec2f(go_right ? 32.0f : -32.0f, -32.0f));
		}
	}

	if (!isStatic && blob.isInWater())
	{
		this.getCurrentScript().tickFrequency = 1;
		blob.setKeyPressed(key_up, true);
	}

	if (delay > 0)
	{
		this.getCurrentScript().tickFrequency = 1;
		blob.sub_u8("strategy_delay", 1);
	}

	blob.set_bool("panic", panic);
	blob.set_bool("zombie_nearby", has_zombie);
	blob.Sync("panic", true);
	blob.Sync("zombie_nearby", true);
}

void Repath(CBrain@ this, Vec2f force_pos = Vec2f_zero)
{
	this.SetPathTo(force_pos == Vec2f_zero ? this.getTarget().getPosition() : force_pos, false);
}

const f32 max_path = 312.0f;
void GoToBlob(CBrain@ this, CBlob@ target)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f targetpos = target.getPosition();
	u8 strategy = blob.get_u8("strategy");

	//Vec2f dir = targetpos-pos;
	//if (dir.Length() > max_path)
	//	Repath(this, Vec2f(max_path*0.9f, 0).RotateBy(-dir.Angle()));

	Vec2f col;
	bool visible = !getMap().rayCastSolid(pos, targetpos, col);
	bool go_directly = visible && blob.getDistanceTo(target) < 96.0f;

	Vec2f new_targetpos = go_directly ? targetpos : this.getNextPathPosition();
	Vec2f targetVector = new_targetpos - blob.getPosition();
	f32 targetDistance = targetVector.Length();

	// check if we have a clear area to the target
	bool justGo = false;

	if (targetDistance < 24.0f && go_directly &&  target.hasTag("player")) // keep distance from player
		return;

	if (visible || targetDistance > max_path) // works for fighters as well
		justGo = true;

	// repath if no clear path after going at it
	if ((!justGo && blob.get_bool("justgo"))
		|| ((pos-new_targetpos).Length() < 16.0f && XORRandom(10) == 0))
	{
		Repath(this);
	}

	//printf("targetDistance " + targetDistance );
	blob.set_bool("justgo", justGo);
	const bool stuck = this.getState() == CBrain::stuck;
	if (stuck && blob.get_u8("emote") == Emotes::off
		&& strategy != Strategy::idle)
	{
		set_emote(blob, Emotes::question, 90);
	}

	if (justGo)
	{
		if (!stuck || XORRandom(100) < 10)
		{
			JustGo(this, target);
			
			if (!stuck)
			{
				blob.set_u8("emote", Emotes::off);
			}
		}
		else
			justGo = false;
	}

	if (!justGo)
	{
		// printInt("state", this.getState() );
		switch (this.getState())
		{
			case CBrain::idle:
				Repath(this);
				break;

			case CBrain::searching:
				//if (XORRandom(100) == 0)
				//	set_emote( blob, "dots" );
				break;

			case CBrain::has_path:
				this.SetSuggestedKeys();  // set walk keys here
				break;

			case CBrain::stuck:
				Repath(this);
				if (XORRandom(100) == 0)
				{
					set_emote(blob, Emotes::frown);
					f32 dist = Maths::Abs(new_targetpos.x - pos.x);
					if (dist > 20.0f)
					{
						if (dist < 50.0f)
							set_emote(blob, new_targetpos.y > pos.y ? Emotes::down : Emotes::up);
						else
							set_emote(blob, new_targetpos.x > pos.x ? Emotes::right : Emotes::left);
					}
				}
				break;

			case CBrain::wrong_path:
				Repath(this);
				if (XORRandom(100) == 0)
				{
					if (Maths::Abs(new_targetpos.x - pos.x) < 50.0f)
						set_emote(blob, new_targetpos.y > pos.y ? Emotes::down : Emotes::up);
					else
						set_emote(blob, new_targetpos.x > pos.x ? Emotes::right : Emotes::left);
				}
				break;
		}
	}

	// face the enemy
	blob.setAimPos(new_targetpos);

	// jump over small blocks

	JumpOverObstacles(blob, new_targetpos);
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

bool JustGo(CBrain@ this, CBlob@ target)
{
	CBlob @blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f target_pos = target.getPosition();
	const f32 horiz_distance = Maths::Abs(target_pos.x - pos.x);

	if (horiz_distance > blob.getRadius() * 0.75f)
	{
		if (target_pos.x < pos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (target_pos.y + getMap().tilesize * 0.7f < pos.y && (target.isOnGround() || target.getShape().isStatic()))  	 // dont hop with me
		{
			blob.setKeyPressed(key_up, true);
		}

		if (blob.isOnLadder())
		{
			if (target_pos.y > pos.y)
				blob.setKeyPressed(key_down, true);
			else
				blob.setKeyPressed(key_up, true);
		}

		return true;
	}

	return false;
}


bool Runaway(CBrain@ this, CBlob@ blob, CBlob@ attacker)
{
	if (attacker is null)
		return false;

	Vec2f pos = blob.getPosition();
	Vec2f hispos = attacker.getPosition();
	const f32 horiz_distance = Maths::Abs(hispos.x - pos.x);

	if (hispos.x > pos.x)
	{
		blob.setKeyPressed(key_left, true);
		blob.setAimPos(pos + Vec2f(-10.0f, 0.0f));
	}
	else
	{
		blob.setKeyPressed(key_right, true);
		blob.setAimPos(pos + Vec2f(10.0f, 0.0f));
	}

	if (hispos.y - getMap().tilesize > pos.y)
	{
		blob.setKeyPressed(key_up, true);
	}

	JumpOverObstacles(blob, hispos, true);

	// end

	//out of sight?
	if ((pos - hispos).getLength() > 200.0f)
	{
		return false;
	}

	return true;
}
