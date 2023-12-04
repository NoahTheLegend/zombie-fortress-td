#include "Hitters.as";
#include "GenericButtonCommon.as";

const int count = 2;

void onInit(CBlob@ this)
{
	this.addCommandID("revive");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("revive"), getTranslatedString("Use this to revive two of your allies."), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("revive"))
	{
		u32 timer = getGameTime() - this.get_u32("revive_called");
		if (timer < 30)
			return;
		this.set_u32("revive_called", getGameTime());

		bool acted = false;
		CMap@ map = this.getMap();
		
		u8 remaining_uses = count;
		for (u8 i = 0; i < getPlayersCount(); i++)
		{
			if (remaining_uses == 0) break;
			remaining_uses--;

			CPlayer@ p = getPlayer(i);
			if (p is null || p.getBlob() !is null) continue;
			if (p.getTeamNum() == getRules().getSpectatorTeamNum()) continue;

			ParticleZombieLightning(this.getPosition());
			ShakeScreen(48, 24, this.getPosition());
			
			acted = true;
			if (isServer())
			{
				CBlob@ b = server_CreateBlob(XORRandom(2)==0?"knight":"flail", 1, this.getPosition());
				if (b is null)
				{
					acted = false;
					continue;
				}

				b.server_SetPlayer(p);
				CBlob@ food = server_CreateBlob("food", 1, b.getPosition());
				CBlob@ food1= server_CreateBlob("food", 1, b.getPosition());

				if (food !is null) b.server_PutInInventory(food);
				if (food1 !is null)b.server_PutInInventory(food1);
			}
		}

		if (acted)
		{
			this.server_Die();
			Sound::Play("MagicWand.ogg", this.getPosition(), 1.0f, 0.9f);
		}
	}
}
