
void onRender(CRules@ this)
{
    CBlob@[] crystals;
    getBlobsByTag("crystal", @crystals);

    for (u8 i = 0; i < crystals.size(); i++)
    {
        CBlob@ crystal = crystals[i];
        if (crystal is null) continue;

        CSprite@ sprite = crystal.getSprite();
        if (sprite is null) continue;

        int hp = Maths::Round(crystal.getHealth()/crystal.getInitialHealth()*100*10)/10;
        SpriteConsts@ consts = sprite.getConsts();
        string filename = consts.filename;

        GUI::SetFont("menu");

        Vec2f pos = Vec2f(20, 20 + (100 * i));
        GUI::DrawIcon(filename, sprite.animation !is null ? sprite.animation.frame : 0, Vec2f(consts.frameWidth, consts.frameHeight), pos, 0.6f);
        GUI::DrawTextCentered(hp+"%", pos + Vec2f(28,
        92), SColor(255,255,255,255));
    }
    GUI::DrawTextCentered("ZM HP: +"+(Maths::Round(getPlayersCount())*0.1f*100.0f)+"%", Vec2f(48,18), SColor(255,255,255,255));
}