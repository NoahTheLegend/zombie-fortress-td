//knight HUD

#include "/Entities/Common/GUI/ActorHUDStartPos.as";

const string iconsFilename = "Entities/Characters/Knight/KnightIcons.png";
const int slotsSize = 6;

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void ManageCursors(CBlob@ this)
{
	if (getHUD().hasButtons())
	{
		getHUD().SetDefaultCursor();
	}
	else
	{
		if (this.isAttached() && this.isAttachedToPoint("GUNNER"))
		{
			getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32, 32));
			getHUD().SetCursorOffset(Vec2f(-32, -32));
		}
		else
		{
			getHUD().SetCursorImage("Entities/Characters/Knight/KnightCursor.png", Vec2f(32, 32));
		}
	}
}

//const int edges = 360;
//const f32 degree = 360 / edges;
//const f32 angle = degree * (Maths::Pi/180);
//const f32 radius = 512.0f;

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	CPlayer@ player = blob.getPlayer();
	/*
	{
		f32 screen_radius = radius * getCamera().targetDistance;
		f32 len = 2 * screen_radius * Maths::Sin(angle/2);

		Vec2f pos2d = Vec2f_lerp(blob.getOldPosition(), blob.getPosition(), getInterpolationFactor());
		pos2d = getDriver().getScreenPosFromWorldPos(pos2d);
		for (int i = 0; i < edges; i++)
		{
			f32 current_angle = angle * i;
    		f32 next_angle = angle * (i + 1);
			Vec2f startpos = pos2d + Vec2f(Maths::Cos(current_angle), Maths::Sin(current_angle)) * screen_radius;
			Vec2f endpos = pos2d + Vec2f(Maths::Cos(next_angle), Maths::Sin(next_angle)) * screen_radius;
			GUI::DrawLine2D(startpos, endpos, SColor(255, 255, 255, 0));
		}
	}
	*/
	ManageCursors(blob);

	// draw inventory

	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);
	DrawInventoryOnHUD(blob, tl);

	u8 type = blob.get_u8("bomb type");
	u8 frame = 1;
	if (type == 0)
	{
		frame = 0;
	}
	else if (type < 255)
	{
		frame = 1 + type;
	}

	// draw coins

	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD(blob, coins, tl, slotsSize - 2);

	// draw class icon

	GUI::DrawIcon(iconsFilename, frame, Vec2f(16, 32), tl + Vec2f(8 + (slotsSize - 1) * 40, -16), 1.0f);
}


