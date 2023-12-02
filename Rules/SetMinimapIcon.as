void onInit(CBlob@ this)
{
    u8 ico = 8;
    if (this.isMyPlayer()) ico = 0;

    this.SetMinimapVars("mipmip.png", ico, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);
}