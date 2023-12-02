const int shine_delay = 75;
const int gradient_freq = 30;
const f32 light_radius = 200.0f;

void onInit(CBlob@ this)
{
    // CLASS
	this.set_Vec2f("class offset", Vec2f(0, 16));
	this.set_string("required class", "builder");

    CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
    consts.net_threshold_multiplier = 4.0f;
    shape.SetGravityScale(0);

    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;
    sprite.getConsts().accurateLighting = true;
    if (isClient())
    {
        sprite.SetEmitSound("crystal_loop.ogg");
        sprite.SetEmitSoundSpeed(0.9f+XORRandom(21)*0.01f);
        sprite.SetEmitSoundVolume(0.2f);
        sprite.SetEmitSoundPaused(false);
    }

    Animation@ shiny = sprite.addAnimation("shiny", 0, false);
    if (shiny is null) return;

    sprite.SetZ(-6);
    this.set_u32("sound_delay", 0);
    
    int size = 19*3; // glacial
    int light_breakpoint = 68423; // 23x 25y, hack (kys)
    u8 mapframe = 16;

    if (this.getMass() == 3000) // nebula
    {
        size = 12*3;
        light_breakpoint = 41495;
        mapframe = 17;
    }
    else if (this.getMass() == 6000) // celestial
    {
        size = 13*3;
        light_breakpoint = 54311;
        mapframe = 18;
    }
    this.set_u32("light_breakpoint", light_breakpoint);

    this.SetMinimapVars("mipmip.png", mapframe, Vec2f(16, 16));
	this.SetMinimapRenderAlways(true);

    int[] frames;
    for (int i = 0; i < size; i++)
    {frames.push_back(i);}
    for (int i = size-3; i > 0; i-=3)
    {
        frames.push_back(i);
        frames.push_back(i+1);
        frames.push_back(i+2);
    }

    //string fr = "";
    //for (u16 i = 0; i < frames.size(); i++)
    //{
    //    fr += frames[i]+";";
    //    if (i%21==0)fr+="\n";
    //}
    //printf(fr);

    shiny.AddFrames(frames);
    sprite.SetAnimation(shiny);

    this.setPosition(this.getPosition()-Vec2f(0,30));
    this.set_u32("shine_time", getGameTime()+shine_delay+XORRandom(shine_delay));
    if (isServer())
    {
        CBlob@ stand = server_CreateBlob("stand", this.getTeamNum(), this.getPosition()+Vec2f(0,30));
    }

    this.Tag("crystal");
    this.Tag("flesh"); // for zombiebrain.as
}
//TODO: sounds particles, fix world background
void onTick(CBlob@ this)
{
    u32 gt = getGameTime();

    if (!this.exists("init_pos")) this.set_Vec2f("init_pos", this.getPosition());
    else this.setPosition(this.get_Vec2f("init_pos") + Vec2f(0, -Maths::Sin(gt*0.015f)*5.0f));

    if (isClient())
    {
        CSprite@ sprite = this.getSprite();
        if (sprite is null) return;

        Animation@ shiny = sprite.animation;
        if (shiny is null) return;
        
        this.SetLightRadius(light_radius);
        this.SetLight(true);

        u16 netid = this.getNetworkID();
        if ((gt+netid) % gradient_freq == 0)
        {
            shiny.frame += 3;

            CFileImage@ image = CFileImage(sprite.getConsts().filename);

		    if (image.isLoaded())
		    {
		    	image.setPixelOffset(this.get_u32("light_breakpoint") + shiny.frame*48);
                SColor color = image.readPixel();
                this.SetLightColor(color);
                if (getMap() !is null) getMap().UpdateLightingAtPosition(this.getPosition(), light_radius);
            }
        }
        if (shiny.frame > shiny.getFramesCount()) shiny.frame = shiny.frame % shiny.getFramesCount();

        u8 shine_step = shiny.frame % 3;
        u32 shine_time = this.get_u32("shine_time");
        if (shine_time < gt)
        {
            this.set_u32("shine_time", shine_step == 2 ? gt+shine_delay+XORRandom(shine_delay) : gt+5);
            shiny.frame = shiny.frame + (shine_step == 2 ? -2 : 1);
        }   
    }
    
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob is null) return damage;
    //if (hitterBlob.hasTag("zombie")) damage *= 2;

    if (isClient() && damage > 0.25f && this.get_u32("sound_delay") < getGameTime())
    {
        this.set_u32("sound_delay", getGameTime()+30);
        this.getSprite().PlayRandomSound("crystal_hit", 1.0f, 0.85f+XORRandom(31)*0.01f);
    }

	return damage;
}

void onDie(CBlob@ this)
{
    CBlob@[] crystals;
	getBlobsByTag("crystal", @crystals);

	if (crystals.length == 0)
	{
		u8 team = 7;
		getRules().SetTeamWon(team);
		getRules().SetCurrentState(GAME_OVER);
		CTeam@ teamis = getRules().getTeam(team);

		getRules().SetGlobalMessage("All crystals are gone! It's over!");
		getRules().set_s32("restart_rules_after_game", getGameTime() + 150);
	}
}