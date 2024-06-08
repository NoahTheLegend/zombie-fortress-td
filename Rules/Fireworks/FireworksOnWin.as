#include "FW_Explosion"

u8 rand = 45;
u16 fw_spawn_delay = 0;
void onTick(CRules@ this)
{
	if (this.isGameOver())
	{
		CMap@ map = getMap();

		if (map !is null)
		{
			f32 side = (XORRandom(2) == 0 ? -8 : 8);
			f32 mapMid = ((map.tilemapwidth+side) * map.tilesize)/2;
			Vec2f spawnpos = Vec2f(mapMid, map.getLandYAtX(mapMid / map.tilesize) * map.tilesize - 16.0f);	

			if (fw_spawn_delay == 0)
			{				
				u8 rand = 30+XORRandom(60);
			}

			if (fw_spawn_delay < 90)
			{
				fw_spawn_delay++;
			}		

			if (fw_spawn_delay == rand) 
			{	
				Fireworks::FireworksBullet(spawnpos);

				string launchsound;
				switch (XORRandom(3))
				{
					case 0: launchsound = "FW_Whistle1.ogg"; break;
					case 1: launchsound = "FW_Whistle2.ogg"; break;
					case 2: launchsound = "FW_Launch.ogg"; break;
				}
				Sound::Play(launchsound, spawnpos, 0.6f);

				fw_spawn_delay = 0;			
			}
		}
	}
}
