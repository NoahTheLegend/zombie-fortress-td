const int FIRE_FREQUENCY = 90;
const f32 ORB_SPEED = 2.0f;

void onInit( CBlob@ this )
{
	this.set_u32("last teleport", 0 );
}

void onTick( CBlob@ this )
{
	if (this.isKeyPressed( key_action2 ))
	{
		{
			u32 lastFireTime = this.get_u32("last teleport");
			const u32 gametime = getGameTime();
			int diff = gametime - (lastFireTime + FIRE_FREQUENCY);
			
			
			if (diff > 0)
			{
				ParticleZombieLightning( this.getPosition() );
				//if (getNet().isServer())
				{
					this.setPosition(this.getAimPos());
				}
				lastFireTime = gametime;
				this.set_u32("last teleport", lastFireTime);
			}
		}
	}	
}
