
//script for a bison

#include "AnimalConsts.as";

const u8 DEFAULT_PERSONALITY = SCARED_BIT;
const s16 MAD_TIME = 600;
const string chomp_tag = "chomping";

//sprite

void onInit(CSprite@ this)
{
    this.ReloadSprites(0,0); //always blue
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
    if (this.isAnimation("revive") && !this.isAnimationEnded()) return;
	if (this.isAnimation("bite") && !this.isAnimationEnded()) return;
    if (blob.getHealth() > 0.0)
    {
		f32 x = blob.getVelocity().x;
		if (blob.get_u8(state_property) == MODE_FLEE)
		{
			if (!this.isAnimation("run")) {
				this.SetAnimation("run");
				this.PlaySound( "/MigrantScream1" );
			}
		}
		else if (Maths::Abs(x) > 0.1f)
		{
			if (!this.isAnimation("walk")) {
				this.SetAnimation("walk");
			}
		}
		else
		{
			if (XORRandom(240)==0)
			{
				this.PlaySound( "/MigrantSayHello" );
			}
			if (!this.isAnimation("idle")) {
			this.SetAnimation("idle");
			}
		}
	}
	else 
	{
		if (!this.isAnimation("dead"))
		{
			this.SetAnimation("dead");
			this.PlaySound( "/MigrantScream1" );
		}
		//this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

void onGib(CSprite@ this)
{
    if (g_kidssafe) {
        return;
    }

    CBlob@ blob = this.getBlob();
    Vec2f pos = blob.getPosition();
    Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
    f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	/*
	const u8 team = blob.getTeamNum();
    CParticle@ Body     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       0, 0, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm1     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 0, 1, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm2     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 0, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Shield   = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       0, 3, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
    CParticle@ Sword    = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp + 1 , 80 ),   0, 4, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
	*/
}

//blob
void onInit(CBrain@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags = 0;
}
void onInit(CBlob@ this)
{
	//for EatOthers
	string[] tags = {"zombie"};
	this.set("tags to eat", tags);
	
	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.set_u8("random move freq",8);
	this.set_f32(target_searchrad_property, 560.0f);
	this.set_f32(terr_rad_property, 185.0f);
	this.set_u8(target_lose_random,34);
	
	this.getBrain().server_SetActive( true );
	
	
	//for shape
	this.getShape().SetRotationsAllowed(false);
	
	//for flesh hit
	this.set_f32("gib health", -2.5f);
	
	this.Tag("flesh");
	this.set_s16("mad timer", 0);

	
	this.getCurrentScript().runFlags = 0;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false; //maybe make a knocked out state? for loading to cata?
}

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;
	if (this.hasAttached())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = this.getMap();
		const f32 radius = this.getRadius();
		
		f32 x = pos.x;
		Vec2f top = Vec2f(x, map.tilesize);
		Vec2f bottom = Vec2f(x, map.tilemapheight * map.tilesize);
		Vec2f end;
		
		if (map.rayCastSolid(top,bottom,end))
		{
			f32 y = end.y;
			
			if (y-pos.y>200 && XORRandom(20)==0)
			{	
				this.server_DetachAll();
			}
		}
	}
	

	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft( x < 0 );
	}
	else
	{
		if (this.isKeyPressed(key_left)) {
			this.SetFacingLeft( true );
		}
		if (this.isKeyPressed(key_right)) {
			this.SetFacingLeft( false );
		}
	}

	if (this.isOnGround() && (this.isKeyPressed(key_left) || this.isKeyPressed(key_right)) )
	{
		if ((this.getNetworkID() + getGameTime()) % 9 == 0)
		{
			f32 volume = Maths::Min( 0.1f + Maths::Abs(this.getVelocity().x)*0.1f, 1.0f );
			TileType tile = this.getMap().getTile( this.getPosition() + Vec2f( 0.0f, this.getRadius() + 4.0f )).type;

			if (this.getMap().isTileGroundStuff( tile )) {
				this.getSprite().PlaySound("/EarthStep", volume, 0.75f );
			}
			else {
				this.getSprite().PlaySound("/StoneStep", volume, 0.75f );
			}
		}
	}
}


f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{		
	if (damage>this.getHealth() && this.getHealth()>0)
	{
		if (!hitterBlob.hasTag("player"))
		{
			this.set_u8(state_property, MODE_FLEE);
			
			const u16 damageOwnerId = (hitterBlob.getDamageOwnerPlayer() !is null && hitterBlob.getDamageOwnerPlayer().getBlob() !is null) ? 
			hitterBlob.getDamageOwnerPlayer().getBlob().getNetworkID() : 0;

			if (damageOwnerId > 0) {
				this.set_netid(target_property, damageOwnerId );
			}
		}
	}
	if (customData == Hitters::arrow) damage*=2.0;
	this.getSprite().PlaySound("/MigrantScream1");
	return damage;
}														

#include "Hitters.as";

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if (blob.hasTag("dead"))
		return false;
	return true;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	if (hitBlob !is null && customData == Hitters::flying)
	{
		Vec2f force = velocity * this.getMass() * 0.35f ;
		force.y -= 7.0f;
		hitBlob.AddForce( force);
	}
}

