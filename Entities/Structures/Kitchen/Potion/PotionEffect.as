#include "PotionEffectsCommon.as";
#include "RunnerCommon.as";
#include "Hitters.as";

void onTick(CBlob@ this)
{
	bool remove = false;

	if (!this.hasTag("potion_drunk"))
	{
        ResetVars(this);
		this.Tag("potion_drunk");
	}

    u32 duration = this.get_u32("potion_duration");
    u8 type = this.get_u8("potion_effect");
    u8 tier = this.get_u8("potion_tier");

    if (getGameTime() > duration)
    {
        remove = true;
    }

    RunnerMoveVars@ moveVars;
    if (!this.get("moveVars", @moveVars)) return;

    switch(type)
    {
        case 0: // slowness
        {
            f32 factor = 0.15f * tier;
            moveVars.walkFactor = 0.85f - factor;
            moveVars.jumpFactor = 0.925f - factor/2;
            break;
        }
        case 1: // poison
        {
            if (isServer() && (getGameTime()+this.getNetworkID()) % 30 == 0)
            {
                this.server_Hit(this, this.getPosition(), Vec2f_zero, 0.1f, Hitters::fall, true);
            }
            break;
        }
        case 2: // speed
        {
            f32 factor = 0.1f * tier;
            moveVars.walkFactor = 1.1f + factor;

            break;
        }
        case 3: // regen
        {
            f32 hp = this.getHealth();
            f32 init_hp = this.getInitialHealth();
            if ((getGameTime()+this.getNetworkID()) % 15 == 0 && hp < init_hp)
            {
                if (isServer())
                {
                    this.server_Heal(Maths::Min(0.1f, init_hp-hp));
                }
                else
                {
                    this.getSprite().PlaySound("Heart.ogg", 0.33f, 1.25f + XORRandom(11)*0.01f);
                }
            }
            break;
        }
        case 4: // damage resistance
        {
            this.set_f32("damage_resistance", 1.0f - (0.111f + 0.111f * tier));
            break;
        }
        case 5: // weakness
        {
            this.set_f32("weakness", 1.0f - (0.15f + 0.15f * tier));
            break;
        }
        case 6: // sickness
        {
            if (isServer())
            {
                f32 hp = this.getHealth();
                f32 init_hp = this.getInitialHealth() * (1.0f - (0.2f + 0.2f * tier));

                if (hp > init_hp)
                {
                    f32 reduce_time = hp/init_hp * (5 * 30);
                    this.set_u32("potion_duration", Maths::Max(0, int(this.get_u32("potion_duration")) - reduce_time));
                    
                    this.server_SetHealth(init_hp);
                }
            }
        }
        break;
    }

	if (remove)
	{
        ResetVars(this);
		this.RemoveScript("PotionEffect.as");
	}
}

void ResetVars(CBlob@ this)
{
    this.set_f32("damage_resistance", 1);
    this.set_f32("weakness", 1);
}