//tree making logs on death script

#include "MakeSeed.as"

void onDie(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	if (!getNet().isServer()) return; //SERVER ONLY

	Vec2f pos = this.getPosition();

	server_MakeSeed(pos, this.getName());

}
