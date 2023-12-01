// Lamp.as

#include "MechanismsCommon.as";

class Lamp : Component
{
	u16 id;

	Lamp(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	void Activate(CBlob@ this)
	{
		this.SetLight(true);
		this.getSprite().SetAnimation("activate");
	}

	void Deactivate(CBlob@ this)
	{
		this.SetLight(false);
		this.getSprite().SetAnimation("default");
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if(!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;

	Lamp component(position, this.getNetworkID());
	this.set("component", component);

	if(getNet().isServer())
	{
		MapPowerGrid@ grid;
		if(!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_CARDINAL,                          // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	this.SetLight(false);
	this.SetLightRadius(110.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	CSprite@ sprite = this.getSprite();
	if(sprite is null) return;

	sprite.SetZ(-55);
	sprite.SetFacingLeft(false);

	
	// functionality for different colored lights
	const u8 team = this.getTeamNum();

	SColor[] lut = {
	SColor(255,  44, 175, 222),         // 0 blue
	SColor(255, 213,  84,  63),         // 1 red
	SColor(255, 157, 202,  34),         // 2 green
	SColor(255, 211, 121, 224),         // 3 purple
	SColor(255, 254, 165,  61),         // 4 orange
	SColor(255,  46, 229, 162),         // 5 cyan
	SColor(255,  95, 132, 236),         // 6 royal
	SColor(255, 255, 240, 171)};        // default

	this.SetLightColor(lut[team]);

	Animation@ activate = sprite.addAnimation("activate", 3, false);
	if(activate is null) return;

	int[] frames = {0, 1, 2};
	activate.AddFrames(frames);
	
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}