#include "FW_Explosion.as"

void EmitGreenFire(CParticle@ p) 	{Fireworks::MakeGreenFireTrail(p.oldposition);}
void EmitBlueFire(CParticle@ p) 	{Fireworks::MakeBlueFireTrail(p.oldposition);}
void EmitPurpleFire(CParticle@ p) 	{Fireworks::MakePurpleFireTrail(p.oldposition);}
void EmitDarkBFire(CParticle@ p) 	{Fireworks::MakeDarkBFireTrail(p.oldposition);}
void EmitRedFire(CParticle@ p) 		{Fireworks::MakeRedFireTrail(p.oldposition);}
void EmitTealFire(CParticle@ p) 	{Fireworks::MakeTealFireTrail(p.oldposition);}
void EmitOrangeFire(CParticle@ p) 	{Fireworks::MakeOrangeFireTrail(p.oldposition);}
void EmitGreyFire(CParticle@ p) 	{Fireworks::MakeGreyFireTrail(p.oldposition);}

void Explosion(CParticle@ p)
{
	string explodesound;	
	switch (XORRandom(4))
	{
		case 0: explodesound = "FW_Deep1.ogg"; break;
		case 1: explodesound = "FW_Deep2.ogg"; break;
		case 2: explodesound = "FW_Deep3.ogg"; break;
		case 3: explodesound = "FW_PopAndCrackle.ogg"; break;
	}
	Sound::Play2D(explodesound, 1.0, 0.5); // its everywhere 
	//Sound::Play(Sound::getFileVariation("FW_Deep?", 1, 3), p.position );
	Fireworks::Explode(p.oldposition, p.oldvelocity);
}