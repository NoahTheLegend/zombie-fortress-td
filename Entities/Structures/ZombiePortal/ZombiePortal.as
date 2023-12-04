// Builder Workshop

//#include "Requirements.as"
//#include "ShopCommon.as";
//#include "Descriptions.as";
//#include "WARCosts.as";
//#include "CheckSpam.as";
#include "Hitters.as";

void onInit( CBlob@ this )
{	 
	//this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;

	this.getSprite().SetZ(-50); //background
	CSpriteLayer@ portal = this.getSprite().addSpriteLayer( "portal", "ZombiePortal.png" , 64, 64, -1, -1 );
	CSpriteLayer@ lightning = this.getSprite().addSpriteLayer( "lightning", "EvilLightning.png" , 32, 32, -1, -1 );
	Animation@ anim = portal.addAnimation( "default", 0, true );
	Animation@ lanim = lightning.addAnimation( "default", 4, false );
	for (int i=0; i<7; i++) lanim.AddFrame(i*4);
	Animation@ lanim2 = lightning.addAnimation( "default2", 4, false );
	for (int i=0; i<7; i++) lanim2.AddFrame(i*4+1);
	anim.AddFrame(1);
	portal.SetRelativeZ( 1000 );
//	portal.SetOffset(Vec2f(0,-24));
//	lightning.SetOffset(Vec2f(0,-24));
	this.getShape().getConsts().mapCollisions = false;
	this.set_bool("portalbreach",false);
	this.set_bool("portalplaybreach",false);
	this.SetLight(false);
	this.SetLightRadius( 64.0f );
	
	this.SetMinimapVars("mipmip.png", 2, Vec2f(16, 8));
	this.SetMinimapRenderAlways(true);
}

void onDie(CBlob@ this)
{
	server_DropCoins(this.getPosition() + Vec2f(0,-32.0f), 100);

	CBlob@[] portals;
	getBlobsByName("ZombiePortal", @portals);

	if (portals.length == 0)
	{
		u8 team = 1;
		getRules().SetTeamWon(team);
		getRules().SetCurrentState(GAME_OVER);
		CTeam@ teamis = getRules().getTeam(team);
		getRules().set_s32("restart_rules_after_game", getGameTime() + 1200);

		if (teamis !is null)
		{
			getRules().SetGlobalMessage(teamis.getName() + ", you've destroyed all portals, congratulations!");
		}

		CBlob@[] zombies;
		getBlobsByTag("zombie", @zombies);
		for (u16 i = 0; i < zombies.length; i++)
		{
			if (zombies[i] !is null) zombies[i].server_Die();
		}
	}
}

void onTick( CBlob@ this)
{
	if(this is null){ return; }
	if(this.getHealth() <= 0){ return; }

	int spawnRate = 16 + (184*this.getHealth() / 42.0);
	
	if(spawnRate <= 0){ return; }

	if (getGameTime() % spawnRate == 0 && this.get_bool("portalbreach"))
	{
		this.getSprite().PlaySound("Thunder");
		CSpriteLayer@ lightning = this.getSprite().getSpriteLayer("lightning");
		if (XORRandom(4)>2) lightning.SetAnimation("default"); else lightning.SetAnimation("default2");
		//lightning.SetFrame(0);
	}

	if (this.get_bool("portalplaybreach")) {
		this.getSprite().PlaySound("PortalBreach");
		this.set_bool("portalplaybreach",false);
		this.SetLight(true);
		this.SetLightRadius( 64.0f );		
	}
	if (!getNet().isServer()) return;
	int num_zombies = getRules().get_s32("num_zombies");
	if (this.get_bool("portalbreach"))
	{
		if ((getGameTime() % spawnRate == 0) && num_zombies < 100)
		{
		CBlob@[] blobs;
		getMap().getBlobsInRadius( this.getPosition(), 256, @blobs );
		if (blobs.length == 0) return;

		CBlob@[] zambies;
		getMap().getBlobsInRadius( this.getPosition(), 128, @zambies );
		int zombies = 0;
		for (u16 i = 0; i < zambies.length; i++)
		{
			if (zambies[i] !is null && zambies[i].hasTag("zombie")) zombies++;
		}
		if (zombies > 16) return;
		
			Vec2f sp = this.getPosition();
			
			int r;
			r = XORRandom(9);
			int rr = XORRandom(8);
			if (r==8 && rr<3)
			server_CreateBlob( "Wraith", -1, sp);
			else										
			if (r==7 && rr<3)
			server_CreateBlob( "Greg", -1, sp);
			else					
			if (r==6)
			server_CreateBlob( "ZombieKnight", -1, sp);
			else
			if (r>=3)
			server_CreateBlob( "Zombie", -1, sp);
			else
			server_CreateBlob( "Skeleton", -1, sp);
			if ((r==7 && rr<3) || (r==8 && rr<3) || (r<7))
			{
				num_zombies++;
				getRules().set_s32("num_zombies",num_zombies);
				
			}
		}
	}
	else
	{
		if (getGameTime() % 600 == 0)
		{
			Vec2f sp = this.getPosition();
			
		
			CBlob@[] blobs;
			this.getMap().getBlobsInRadius( sp, 64, @blobs );
			for (uint step = 0; step < blobs.length; ++step)
			{
				CBlob@ other = blobs[step];
				if (other.hasTag("player"))
				{
					this.set_bool("portalbreach",true);
					this.set_bool("portalplaybreach",true);
					this.Sync("portalplaybreach",true);
					this.Sync("portalbreach",true);
				}
			}
		}
	}
}
void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
//	this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "builder"*/ );
}
							   
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::cata_stones)
	{
		damage *= 0.05f;
	}

	if (customData == Hitters::explosion)
	{
		damage *= 4;
	}
	
	if (customData == Hitters::keg)
	{
		damage *= 2;
	}

	if (customData == Hitters::builder)
	{
		damage *= 0.75f;
	}

	Vec2f sp = this.getPosition();
	
	if (!this.get_bool("portalbreach") && XORRandom(8) == 0)
	{
		CBlob@[] blobs;
		this.getMap().getBlobsInRadius( sp, 64, @blobs );
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ other = blobs[step];
			if (other.hasTag("player"))
			{
				this.set_bool("portalbreach",true);
				this.set_bool("portalplaybreach",true);
				this.Sync("portalplaybreach",true);
				this.Sync("portalbreach",true);
			}
		}
	}

	return damage;
}
