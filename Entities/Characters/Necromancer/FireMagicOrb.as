const int FIRE_FREQUENCY = 15;
const int RECHARGE_FREQUENCY = 75;

const f32 ORB_SPEED = 4.0f;

void onInit( CBlob@ this )
{
	this.set_u32("last magic fire", 0 );
	this.set_u32("fire count", 0 );
}

void onTick( CBlob@ this )
{
	if (getNet().isServer() && this.isKeyPressed( key_action1 ))
	{
		u32 lastFireTime = this.get_u32("last magic fire");
		const u32 gametime = getGameTime();
		int diff = gametime - (lastFireTime + FIRE_FREQUENCY);
		int diff_r = gametime - (lastFireTime + RECHARGE_FREQUENCY);
		if (diff_r > 0) this.set_u32("fire count",0);
		if (diff > 0 && this.get_u32("fire count")<3)
		{
			this.set_u32("fire count", this.get_u32("fire count")+1);
			Vec2f pos = this.getPosition();
			Vec2f aim = this.getAimPos();
			
			u16 targetID = 0xffff;
			CMap@ map = this.getMap();
			if(map !is null)
			{
				CBlob@[] targets;
				if(map.getBlobsInRadius( aim, 64.0f, @targets ))
				{
					for(int i = 0; i < targets.length; i++)
					{
						CBlob@ b = targets[i];
						if (b !is null && b.getTeamNum() != this.getTeamNum() && b.hasTag("player"))
						{
							targetID = b.getNetworkID();
						}
					}
				}
			}
			
			Vec2f norm = aim - pos;
			norm.Normalize();
			lastFireTime = gametime;
			this.set_u32("last magic fire", lastFireTime);

			CBlob@ orb = server_CreateBlob( "orb", this.getTeamNum(), pos + norm*this.getRadius() );   
			if (orb !is null)
			{
				orb.setVelocity( norm * ORB_SPEED );
				
				if(targetID != 0xffff)
				{
					orb.set_u16("target", targetID);
				}
			}
		}
	}   
}
