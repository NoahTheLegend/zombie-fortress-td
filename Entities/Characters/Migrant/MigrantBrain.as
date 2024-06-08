// Migrant brain

#define SERVER_ONLY

#include "EmotesCommon.as"
#include "MigrantCommon.as"

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	blob.set_bool("justgo", false);
	blob.set_Vec2f("target spot", Vec2f_zero);
	blob.set_u8("strategy", Strategy::find_crystal);
	blob.set_Vec2f("last_order_pos", Vec2f_zero);
	blob.set_u16("follow_id", 0);

	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || blob.getTeamNum() > 10)
		return;

	if (this.getCurrentScript().tickFrequency == 30)
		RandomTurn(blob);

	if (blob.getName() == "migrant")
		MigrantTick(this, blob);
	else
		FighterTick(this, blob);
}

void FighterTick(CBrain@ this, CBlob@ blob)
{
	const bool isStatic = blob.getShape().isStatic();

	if (isStatic)
	{
		this.getCurrentScript().tickFrequency = 30;
	}
		
	u8 delay = blob.get_u8("strategy_delay");
	u8 retreating = blob.get_u16("retreating");
	u8 strategy = delay == 0 ? blob.get_u8("strategy") : FStrategy::idle;
	CBlob@ enemy = null;
	CBlob@ nearest_ally = null;

	bool idle = strategy == FStrategy::idle;
	bool follow = strategy == FStrategy::follow;
	bool defend = strategy == FStrategy::defend;
	bool find_crystal = strategy == FStrategy::find_crystal;
	Vec2f pos = blob.getPosition();

	bool archer = blob.getName() == "archer";
	CBlob@ latest_enemy = blob.get_u16("attack_id") == 0 ? null : getBlobByNetworkID(blob.get_u16("attack_id"));

	if (!isStatic)
	{
		//printf("strat: "+strategy);

		CMap@ map = getMap();
		CBlob@[] bs;
		if (map !is null)
		{
			f32 enemy_dist = 999.0f;
			f32 ally_dist = 999.0f;
			map.getBlobsInRadius(blob.getPosition(), archer ? 256.0f : 96.0f, @bs);
			for (u16 i = 0; i < bs.size(); i++)
			{
				CBlob@ b = bs[i];
				if (b is null || b is blob) continue;
				bool raycast = map.rayCastSolidNoBlobs(blob.getPosition(), b.getPosition());
				
				if (b.hasTag("player"))
				{
					f32 temp_ally_dist = b.getDistanceTo(blob);
					if (raycast && temp_ally_dist > 48.0f) continue;

					ally_dist = temp_ally_dist;
					@nearest_ally = @b;
				}

				if (b.hasTag("zombie") || (b.getName() == "ZombiePortal" && !archer))
				{
					f32 temp_enemy_dist = b.getDistanceTo(blob);
					if (raycast && temp_enemy_dist > 32.0f) continue;

					bool wraith = (b.getName() == "Wraith" && temp_enemy_dist < 64.0f);
					if (temp_enemy_dist < enemy_dist || wraith)
					{
						printf(""+wraith);
						if (wraith) blob.set_u32("shield time", getGameTime());
						enemy_dist = temp_enemy_dist;
						@enemy = @b;
					}
				}
			}
		}
		// normal AI
		if (blob.getHealth() / blob.getInitialHealth() > 0.25f || find_crystal || retreating > 0)
		{
			CBlob@ target = idle ? enemy : this.getTarget();
			this.getCurrentScript().tickFrequency = idle && enemy is null && retreating == 0 ? 30 : 1;

			if (find_crystal) //crystals should heal nearby bots
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
					@target = getBlobByNetworkID(target_id);
					if (target !is null && target.hasTag("player"))
						blob.set_u16("follow_id", target_id);
					this.SetTarget(target);
				}
			}

			Vec2f last_order_pos = blob.get_Vec2f("last_order_pos");
			u16 follow_id = blob.get_u16("follow_id");
			if (follow || defend)
			{
				@target = getBlobByNetworkID(follow_id);
				if (target is null) SetStrategy(blob, Strategy::find_crystal);
				this.SetTarget(target);
			}

			if (!find_crystal && enemy is null)
			{
				const bool stuck = this.getState() == CBrain::stuck;
				if (!stuck) // retreat back to ally or order pos
				{
					if (idle && (pos-last_order_pos).Length() > 96.0f)
					{
						blob.set_u16("retreating", 30);
						GoToBlob(this, null, last_order_pos);
					}
					else if (follow && blob.getDistanceTo(target) > 96.0f)
					{
						blob.set_u16("retreating", 60);
						GoToBlob(this, target);
					}
				}
			}

			if (retreating > 0)
			{
				if (idle)
					GoToBlob(this, null, last_order_pos);
				else
					GoToBlob(this, target);
			}
			else if (latest_enemy is null && strategy != FStrategy::idle && target !is null) // follow or defend
			{
				GoToBlob(this, target);
			}

			blob.set_u16("attack_id", enemy !is null && (enemy.hasTag("zombie") || enemy.getName() == "ZombiePortal") ? enemy.getNetworkID() : 0);
			if (target !is null)
			{
				const int state = this.getState();

				// lose target if its killed (with random cooldown)
				if (target !is null)
					if ((XORRandom(10) == 0 && target.hasTag("dead")))
					{
						if (defend)
							SetStrategy(blob, FStrategy::find_crystal);

						this.SetTarget(null);
					}
			}
		}
	}

	if (!isStatic && blob.getHealth() / blob.getInitialHealth() <= 0.25f)
	{
		if (nearest_ally is null || find_crystal)
		{
			set_emote(blob, Emotes::attn, 30);
			if (!find_crystal) SetStrategy(blob, FStrategy::find_crystal);
		}
		else
		{
			bool visible = enemy !is null && !getMap().rayCastSolidNoBlobs(pos, enemy.getPosition());
			if (visible && enemy !is null && blob.getDistanceTo(enemy) < 32.0f)
			{
				bool go_right = enemy.getPosition().x < pos.x;
				blob.setKeyPressed(go_right ? key_right : key_left, true);
				blob.set_u32("shield time", getGameTime());
				JumpOverObstacles(blob, pos + Vec2f(go_right ? 32.0f : -32.0f, -32.0f));

				set_emote(blob, Emotes::attn, 30);
			}
			else
			{
				GoToBlob(this, nearest_ally);
				if (XORRandom(30) == 0)
					set_emote(blob, XORRandom(2) == 0 ? Emotes::heart : Emotes::frown, 90);
			}
		}
	}

	if (latest_enemy !is null) // attack
	{
		if (blob.getName() == "archer")
		{
			bool visible = enemy !is null && !getMap().rayCastSolidNoBlobs(pos, enemy.getPosition());
			if (visible)
			{
				if (retreating == 0)
				{
					AttackBlobArcher(blob, latest_enemy);
					if (XORRandom(80) == 0)
					{
						set_emote(blob, Emotes::mad, 75);
					}
				}

				if (blob.getDistanceTo(latest_enemy) < 40.0f)
				{
					bool go_right = enemy.getPosition().x < pos.x;
					blob.setKeyPressed(go_right ? key_right : key_left, true);
					blob.set_u32("shield time", getGameTime());
					JumpOverObstacles(blob, pos + Vec2f(go_right ? 32.0f : -32.0f, -32.0f));

					if (XORRandom(30) == 0)
					{
						set_emote(blob, Emotes::attn, 75);
					}
				}
			}
		}
		else
		{
			if (retreating == 0)
			{
				AttackBlobKnight(blob, latest_enemy);
				if (XORRandom(80) == 0)
				{
					set_emote(blob, Emotes::mad, 75);
				}
			}
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

	if (retreating > 0)
	{
		this.getCurrentScript().tickFrequency = 1;
		blob.sub_u16("retreating", 1);
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

				bool raycast = map.rayCastSolidNoBlobs(blob.getPosition(), b.getPosition());
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
	if (this.getTarget() is null && force_pos == Vec2f_zero) return;
	this.SetPathTo(force_pos == Vec2f_zero ? this.getTarget().getPosition() : force_pos, false);
}

const f32 max_path = 312.0f;
void GoToBlob(CBrain@ this, CBlob@ target, Vec2f force_pos = Vec2f_zero)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f targetpos = force_pos == Vec2f_zero && target !is null ? target.getPosition() : force_pos;
	u8 strategy = blob.get_u8("strategy");

	bool visible = !getMap().rayCastSolidNoBlobs(pos, targetpos);
	f32 dist = force_pos == Vec2f_zero && target !is null ? blob.getDistanceTo(target) : (pos-force_pos).Length();
	bool go_directly = visible && dist < 96.0f;

	Vec2f to = go_directly ? targetpos : this.getNextPathPosition();
	Vec2f targetVector = to - blob.getPosition();
	f32 targetDistance = targetVector.Length();
	
	Controls(this, blob, target, to, targetVector, targetDistance, strategy, visible, go_directly);
}

void Controls(CBrain@ this, CBlob@ blob, CBlob@ target, Vec2f to, Vec2f targetVector, f32 targetDistance, u8 strategy, bool visible, bool go_directly)
{
	Vec2f pos = blob.getPosition();
	bool justGo = false;

	if (target !is null && targetDistance < 16.0f + (blob.getNetworkID()%16) + (blob.getName() == "archer" ? 8 : 0) && go_directly && target.hasTag("player"))
	{
		return;
	}
	
	if (visible || targetDistance > max_path)
		justGo = true;

	// repath if no clear path after going at it
	if (((!justGo && blob.get_bool("justgo"))
		|| ((pos-to).Length() < 16.0f && XORRandom(15) == 0)))
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
			if (target is null)
				JustGo(this, null, to);
			else
				JustGo(this, target);
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
					f32 dist = Maths::Abs(to.x - pos.x);
					if (dist > 20.0f)
					{
						if (dist < 50.0f)
							set_emote(blob, to.y > pos.y ? Emotes::down : Emotes::up);
						else
							set_emote(blob, to.x > pos.x ? Emotes::right : Emotes::left);
					}
				}
				break;

			case CBrain::wrong_path:
				Repath(this);
				if (XORRandom(100) == 0)
				{
					if (Maths::Abs(to.x - pos.x) < 50.0f)
						set_emote(blob, to.y > pos.y ? Emotes::down : Emotes::up);
					else
						set_emote(blob, to.x > pos.x ? Emotes::right : Emotes::left);
				}
				break;
		}
	}

	// face the enemy
	blob.setAimPos(target is null ? to : target.getPosition());
	// jump over small blocks

	JumpOverObstacles(blob, to);
}

bool JustGo(CBrain@ this, CBlob@ target, Vec2f force_pos = Vec2f_zero)
{
	CBlob @blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f target_pos = force_pos == Vec2f_zero && target !is null ? target.getPosition() : force_pos;
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

		if (target !is null && target_pos.y + getMap().tilesize * 0.7f < pos.y && (target.isOnGround() || target.getShape().isStatic()))  	 // dont hop with me
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
