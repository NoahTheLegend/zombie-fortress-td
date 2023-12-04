//pretty straightforward, set properties for larger explosives
// wont work without "exploding"  tag

#include "Explosion.as";  // <---- onHit()

void onDie(CBlob@ this)
{
	if (this.hasTag("exploding"))
	{
		if (this.exists("explosive_radius") && this.exists("explosive_damage"))
		{
			Explode(this, this.get_f32("explosive_radius"), this.get_f32("explosive_damage"));
		}
		else //default "bomb" explosion
		{
			Explode(this, 64.0f, 3.0f);
		}

        Vec2f pos = this.getPosition();
        CMap@ map = getMap();

        if (this.getName() == "Wraith")
        {
            for (u8 i = 0; i < 4; i++)
            {
                for (u8 j = 0; j < 3; j++)
                {
                    map.server_setFireWorldspace(pos + Vec2f(8 * (j+1), 0).RotateBy(90*i), true);
                }
            }
        }
	}
}
