//not server only so the client also gets the game event setup stuff

#include "GameplayEvents.as"

const int coinsOnDamageAdd = 0;
const int coinsOnAssistAdd = 0;
const int coinsOnKillAdd = 0;

// bonus for being an offensive builder
const int coinsOnDamageAddBuilder = 0;
const int coinsOnAssistAddBuilder = 0;
const int coinsOnKillAddBuilder = 0;

const int coinsOnDeathLosePercent = 0;

const int coinsOnRestartAdd = 0;
const bool keepCoinsOnRestart = false;

const int coinsOnHitSiege = 0; //per heart of damage
const int coinsOnKillSiege = 0;

const int coinsOnCapFlag = 0;

const int coinsOnBuildStoneBlock = 1;
const int coinsOnBuildStoneDoor = 2;
const int coinsOnBuildWood = 0;
const int coinsOnBuildWorkshop = 0;

const int warmupFactor = 1;

const f32 killstreakFactor = 1.0f;

string[] names;

void GiveRestartCoins(CPlayer@ p)
{
	if (keepCoinsOnRestart)
		p.server_setCoins(p.getCoins() + coinsOnRestartAdd);
	else
		p.server_setCoins(coinsOnRestartAdd);
}

void GiveRestartCoinsIfNeeded(CPlayer@ player)
{
	const string s = player.getUsername();
	for (uint i = 0; i < names.length; ++i)
	{
		if (names[i] == s)
		{
			return;
		}
	}

	names.push_back(s);
	GiveRestartCoins(player);
}

//extra coins on start to prevent stagnant round start
void Reset(CRules@ this)
{
	if (!getNet().isServer())
		return;

	names.clear();

	uint count = getPlayerCount();
	for (uint p_step = 0; p_step < count; ++p_step)
	{
		CPlayer@ p = getPlayer(p_step);
		GiveRestartCoins(p);
		names.push_back(p.getUsername());
	}
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	this.addCommandID(game_event_id);
	Reset(this);
}

//also given when plugging player -> on first spawn
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (!getNet().isServer())
		return;

	if (player !is null)
	{
		GiveRestartCoinsIfNeeded(player);
	}
}

//
// give coins for killing

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (!getNet().isServer())
		return;

	if (victim !is null)
	{
		if (killer !is null)
		{
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
			{
				killer.server_setCoins(killer.getCoins() + coinsOnKillAdd);
			}
		}

		s32 lost = victim.getCoins() * (coinsOnDeathLosePercent * 0.01f);

		victim.server_setCoins(victim.getCoins() - lost);

		//drop coins
		CBlob@ blob = victim.getBlob();
		if (blob !is null)
			server_DropCoins(blob.getPosition(), XORRandom(lost));
	}
}

// give coins for damage

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	if (!getNet().isServer())
		return DamageScale;

	if (attacker !is null && attacker !is victim && attacker.getTeamNum() != victim.getTeamNum())
	{
        CBlob@ v = victim.getBlob();
        f32 health = 0.0f;
        if(v !is null)
            health = v.getHealth();
        f32 dmg = DamageScale;
        dmg = Maths::Min(health, dmg);

		attacker.server_setCoins(attacker.getCoins() + dmg * coinsOnDamageAdd / this.attackdamage_modifier);
	}

	return DamageScale;
}

// coins for various game events
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	//only important on server
	if (!getNet().isServer())
		return;

	if (cmd == getGameplayEventID(this))
	{
		GameplayEvent g(params);

		CPlayer@ p = g.getPlayer();
		if (p !is null)
		{
			u32 coins = 0;

			switch (g.getType())
			{
				case GE_built_block:
				{
					g.params.ResetBitIndex();
					u16 tile = g.params.read_u16();
					if (tile == CMap::tile_castle)
					{
						coins = coinsOnBuildStoneBlock;
					}
					else if (tile == CMap::tile_wood)
					{
						coins = coinsOnBuildWood;
					}
				}

				break;

				case GE_built_blob:

				{
					g.params.ResetBitIndex();
					string name = g.params.read_string();
					if (name == "stone_door")
					{
						coins = coinsOnBuildStoneDoor;
					}
				}

				break;

				case GE_hit_vehicle:
					coins = coinsOnHitSiege;
					break;

				case GE_kill_vehicle:
					coins = coinsOnKillSiege;
					break;

				case GE_captured_flag:
					coins = coinsOnCapFlag;
					break;
			}

			if (coins > 0)
			{
				if (this.isWarmup())
					coins /= warmupFactor;

				p.server_setCoins(p.getCoins() + coins);
			}
		}
	}
}
