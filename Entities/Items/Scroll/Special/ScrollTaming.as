// scroll script that makes enemies insta gib within some radius

#include "Hitters.as";

void onInit( CBlob@ this )
{
	this.addCommandID( "tame" );
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton( 11, Vec2f_zero, this, this.getCommandID("tame"), "Use this to make nearby enemies instantly turn into allies.", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("tame"))
	{
		ParticleZombieLightning( this.getPosition() );

		bool hit = false;
		CBlob@ caller = getBlobByNetworkID( params.read_u16() );
		if (caller !is null)
		{
			const int team = caller.getTeamNum();
			CBlob@[] blobsInRadius;	   
			if (this.getMap().getBlobsInRadius( this.getPosition(), 100.0f, @blobsInRadius )) 
			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @b = blobsInRadius[i];
					if (b.getTeamNum() != team && b.hasTag("flesh"))
					{
						ParticleZombieLightning( b.getPosition() ); 
						if (getNet().isServer())
						{
							b.server_setTeamNum(team);
						}
						//	caller.server_Hit( b, this.getPosition(), Vec2f(0,0), 10.0f, Hitters::suddengib, true );
						hit = true;
					}
				}
			}
		}

		if (hit)
		{
			this.server_Die();
			Sound::Play( "SuddenGib.ogg" );
		}
	}
}