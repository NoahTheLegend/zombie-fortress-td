void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
    shape.SetGravityScale(0);

    shape.SetStatic(true);

    this.set_TileType("background tile", 0);

    this.getSprite().SetZ(-5);
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(2,2));	
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 12);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));
}