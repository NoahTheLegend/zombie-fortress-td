void onInit(CBlob@ this)
{
	this.Tag("potion_component");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (blob.hasTag("flesh") || blob.hasTag("potion_component") ? false : blob.isCollidable());
}