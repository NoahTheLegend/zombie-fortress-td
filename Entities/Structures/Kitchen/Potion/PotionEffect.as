#include "PotionEffectsCommon.as";
#include "RunnerCommon.as";
#include "Hitters.as";

void onTick(CBlob@ this)
{
	bool remove = false;

	if (!this.hasTag("potion_drunk"))
	{
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
        case 1: // empty, skip
        {
            break;
        }
        case 2: // poison
        {
            if (isServer() && (getGameTime()+this.getNetworkID()) % 30 == 0)
            {
                this.server_Hit(this, this.getPosition(), Vec2f_zero, 0.1f, Hitters::fall, true);
            }
            break;
        }
        case 3: // speed
        {
            moveVars.walkFactor = 1.1f + 0.1f * tier;

            break;
        }
        case 4: // regen
        {
            f32 hp = this.getHealth();
            f32 init_hp = this.getInitialHealth();
            if ((getGameTime()+this.getNetworkID()) % 30 == 0 && hp < init_hp)
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
    }

	if (remove)
	{
		this.RemoveScript("PotionEffect.as");
	}
}