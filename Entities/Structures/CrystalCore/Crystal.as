const int shine_delay = 75;
const int gradient_freq = 30;

void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
    consts.net_threshold_multiplier = 4.0f;
    shape.SetGravityScale(0);

    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    Animation@ shiny = sprite.addAnimation("shiny", 0, false);
    if (shiny is null) return;

    sprite.SetZ(-6);
    
    int size = 19*3;
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

    this.setPosition(this.getPosition()-Vec2f(0,32));
    this.set_u32("shine_time", getGameTime()+shine_delay+XORRandom(shine_delay));
    if (isServer())
    {
        CBlob@ stand = server_CreateBlob("stand", this.getTeamNum(), this.getPosition()+Vec2f(0,28));
    }
}
//TODO: sounds particles
void onTick(CBlob@ this)
{
    u32 gt = getGameTime();

    if (!this.exists("init_pos"))
    {
        this.set_Vec2f("init_pos", this.getPosition());
    }
    else
    {
        this.setPosition(this.get_Vec2f("init_pos") + Vec2f(0, -Maths::Sin(gt*0.015f)*5.0f));
    }

    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    Animation@ shiny = sprite.animation;
    if (shiny is null) return;

    u16 netid = this.getNetworkID();
    if ((gt+netid) % gradient_freq == 0) shiny.frame += 3;
    if (shiny.frame > shiny.getFramesCount()) shiny.frame = shiny.frame % shiny.getFramesCount();

    u8 shine_step = shiny.frame % 3;
    u32 shine_time = this.get_u32("shine_time");
    if (shine_time < gt)
    {
        this.set_u32("shine_time", shine_step == 2 ? gt+shine_delay+XORRandom(shine_delay) : gt+5);
        shiny.frame = shiny.frame + (shine_step == 2 ? -2 : 1);
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