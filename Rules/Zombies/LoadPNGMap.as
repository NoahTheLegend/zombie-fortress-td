// loads a classic KAG .PNG map

#include "BasePNGLoader.as";
#include "ProceduralGeneration.as";
#include "MinimapHook.as";
#include "CustomTiles.as";
#include "DummyCommon.as";

bool LoadMap(CMap@ map, const string& in fileName)
{
	PNGLoader loader();

	map.legacyTileMinimap = false;
	
	bool procedural_map_gen = true;
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		procedural_map_gen = cfg.exists("procedural_map_gen") ? cfg.read_bool("procedural_map_gen") : true;
	}

	int map_seed = Time();
	CRules@ rules = getRules();
	if (rules.exists("new map seed"))
	{
		const int new_map_seed = rules.get_s32("new map seed");
		if (new_map_seed > -1)
		{
			map_seed = new_map_seed;
			rules.set_s32("new map seed", -1);
			procedural_map_gen = true;
		}
	}
	
	if (procedural_map_gen)
	{
		print("LOADING PROCEDURALLY GENERATED MAP - MAP SEED: "+map_seed, 0xff66C6FF);
		return loadProceduralGenMap(map, map_seed);
	}

	print("LOADING ZOMBIES MAP " + fileName, 0xff66C6FF);
	return loader.loadMap(map, fileName);
}