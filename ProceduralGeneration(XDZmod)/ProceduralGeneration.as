// Procedural Generation for Zombie Fortress
// Uses Pirate-Rob's generation as a base

#include "CustomTiles.as";

enum BiomeType
{
	Forest = 0, //forest/normal (grass/trees/bushes/ect)
	Desert,     //desert (grain/more gold)
	Meadow,     //meadow (grass/flowers)
	Swamp,      //swamp (land inline with sea, lots of shallow water
	Caves,      //caves (Big overhead cave/cliff)
	Count
};

const int min_portals = 4;
const int max_rnd_portals = 4;
const string[] crystals = {"glacial", "nebula", "celestial"};

bool loadProceduralGenMap(CMap@ map, int&in map_seed)
{
	if (!isServer())
	{
		SetupProceduralMap(map, 0, 0);
		SetupProceduralBackgrounds(map);
		return true;
	}

	Random r(map_seed);
	
	map.set_s32("map seed", map_seed);

	Noise@ map_noise = Noise(r.Next());
	Noise@ material_noise = Noise(r.Next());
	
	s32 width = m_width;
	s32 height = m_height;
	s32 MaxLandHeight = 20;
	s32 MinFloorHeight = 10;

	//LOAD PRESETS FROM CONFIG
	ConfigFile cfg;
	if (cfg.loadFile("MapPresets.cfg"))
	{
		string[] presets;
		cfg.readIntoArray_string(presets, "PRESETS");
		
		const string preset = presets[r.NextRanged(presets.length)];
		print("PROCEDURAL GENERATION TYPE: "+preset, 0xff66C6FF);
		
		s32[] vars;
		cfg.readIntoArray_s32(vars, preset);

		width = vars[0];
		height = vars[1];
		MaxLandHeight = vars[2];
		MinFloorHeight = vars[3];
	}
	
	MinFloorHeight = height - MinFloorHeight;
	
	SetupProceduralMap(map, width, height);
	SetupProceduralBackgrounds(map);

	const int SeaLevel = height/5*4;

	//gen heightmap
	int[] heightmap(width);
	
	const int BiomeTypes = 4;
	int[] biome(width);

	int max_portals = min_portals + XORRandom(max_rnd_portals);
	int portals_spawned = 0;
	
	for (int dbl = 0; dbl < 2; dbl += 1)
	{
		int LastHeight = height*3/5;
		int Straight = 4;
		int Crazy = 0;
		int Uphill = 0;
		int Downhill = 0;
		int CliffUp = 0;
		int CliffDown = 0;
		int ToSeaLevel = 0;
		int CliffChange = -int(r.NextRanged(10));
		int LastType = 0;
		int CurrentBiome = 2; //Always start with meadow
		int CaveLengthBuffer = 0; //This is to force caves to be above 50 wide
		int SwampDip = 0;
		int start = width/2;
		int add = dbl > 0 ? -1 : 1;

		for (int x = start; true; x += add)
		{
			if (x >= width || x < 0) break;
			
			CaveLengthBuffer += 1;
			
			if (Straight == 0 && Crazy == 0 && Uphill == 0 && Downhill == 0 && CliffUp == 0 && CliffDown == 0 && ToSeaLevel == 0)
			{
				if (LastType == BiomeType::Forest && r.NextRanged(10) == 0)
				{
					CurrentBiome = BiomeType::Caves;
					CaveLengthBuffer = 0;
				}

				if (CaveLengthBuffer > 50 + r.NextRanged(50) && CurrentBiome == BiomeType::Caves)
				{
					CurrentBiome = r.NextRanged(BiomeType::Caves);
					CaveLengthBuffer = 0;
				}
				
				if (CurrentBiome == BiomeType::Swamp && LastHeight != SeaLevel) LastType = 5; //Jump to sea level if swamp
				else if (LastType == BiomeType::Forest) LastType = r.NextRanged(4); //If last was stright, anything but cliff
				else if (LastType == BiomeType::Caves) LastType = 1 + r.NextRanged(3); //If last was cliff, anything but cliffs and straights
				else if (CurrentBiome == BiomeType::Caves) LastType = r.NextRanged(4); //If cave biome, anything but cliff
				else LastType = r.NextRanged(BiomeType::Count); // RANDOM!!!!1!
				
				switch(LastType)
				{
					case BiomeType::Forest: Straight = 1 + r.NextRanged(9);   break;
					case BiomeType::Desert: Crazy = r.NextRanged(50);         break;
					case BiomeType::Meadow: Uphill = 2 + r.NextRanged(13);    break;
					case BiomeType::Swamp: Downhill = 5 + r.NextRanged(15);  break;
					case BiomeType::Caves:
					{
						CurrentBiome = r.NextRanged(BiomeType::Caves); //Cliffs are a good time to do biome changes ;)
						
						if (CurrentBiome != BiomeType::Swamp)
						{
							if (CliffChange == 0)
							{
								if (r.NextRanged(2) == 0) CliffUp = 2 + r.NextRanged(8);
								else CliffDown = 5 + r.NextRanged(10);
							}
							if (CliffChange > 0) CliffDown = 5 + r.NextRanged(10);
							if (CliffChange < 0) CliffUp = 2 + r.NextRanged(8);
							
							CliffChange += CliffUp-CliffDown;
						}
						else
						{
							ToSeaLevel = 100; //Swamps get thier own special cliff code
						}

						break;
					}
					case 5: ToSeaLevel = 100; break;
				}
			}
			
			if (Straight > 0)
			{
				heightmap[x] = LastHeight;
				if (Straight > 4 && r.NextRanged(3) == 0)heightmap[x] += int(r.NextRanged(3))-1;
				Straight--;
			}
			else if (Uphill > 0)
			{
				heightmap[x] = LastHeight;
				if (r.NextRanged(3) == 0) heightmap[x] -= r.NextRanged(2);
				Uphill--;
			}
			else if (Downhill > 0)
			{
				heightmap[x] = LastHeight;
				if (r.NextRanged(3) == 0) heightmap[x] += r.NextRanged(2);
				Downhill--;
			}
			else if (CliffDown > 0)
			{
				heightmap[x] = LastHeight+(r.NextRanged(4) + 1);
				CliffDown--;
			}
			else if (CliffUp > 0)
			{
				heightmap[x] = LastHeight-(r.NextRanged(4) + 1);
				CliffUp--;
			}
			else if (ToSeaLevel > 0)
			{
				if (LastHeight > SeaLevel - 2 && LastHeight < SeaLevel + 2)
				{
					ToSeaLevel = 0;
					heightmap[x] = SeaLevel;
				}
				else
				{
					if (LastHeight > SeaLevel) heightmap[x] = LastHeight - int(r.NextRanged(4) + 1);
					else heightmap[x] = LastHeight + (r.NextRanged(4) + 1);
					ToSeaLevel--;
				}
			}
			else
			{
				heightmap[x] = LastHeight;
				if (r.NextRanged(2) == 0) heightmap[x] += int(r.NextRanged(3)) - 1;
				if (Crazy > 0) Crazy--;
			}
			
			if (ToSeaLevel == 0 && CurrentBiome == BiomeType::Swamp)
			{
				heightmap[x] = SeaLevel + SwampDip;
				if (r.NextRanged(8) == 0) SwampDip = r.NextRanged(2);
			}
			
			LastHeight = heightmap[x];
			if (LastHeight < MaxLandHeight+1) LastHeight += r.NextRanged(3) + 1;
			if (LastHeight > MinFloorHeight-1) LastHeight -= r.NextRanged(5) + 1;
			biome[x] = CurrentBiome;
		}
	}
	
	s16[][] World;
	
	for (int i = 0; i < width; i += 1) //Init world grid
	{
		s16[] temp;
		for (int j = 0; j < height; j += 1)
		{
			temp.push_back(0);
		}
		World.push_back(temp);
	}
	
	int CaveHeight = 4 + r.NextRanged(12);
	
	for (int i = 0; i < width; i += 1) //Dirty stones!
	{
		for (int j = 0; j < height; j += 1)
		{ 
			int FakeCaveHeightMap = heightmap[i];
			
			if (biome[i] == BiomeType::Caves) //Caves need special code~
			{
				//On second note, this code is evil beyond all belief, don't touch it.
				f32 Divide = 1;
				
				if (i > 3 && biome[i-4] != BiomeType::Caves) Divide = 0.8;
				if (i > 2 && biome[i-3] != BiomeType::Caves) Divide = 0.6;
				if (i > 1 && biome[i-2] != BiomeType::Caves) Divide = 0.4;
				if (i > 0 && biome[i-1] != BiomeType::Caves) Divide = 0.2;

				if (i < width-4 && biome[i+4] != BiomeType::Caves) Divide = 0.8;
				if (i < width-3 && biome[i+3] != BiomeType::Caves) Divide = 0.6;
				if (i < width-2 && biome[i+2] != BiomeType::Caves) Divide = 0.4;
				if (i < width-1 && biome[i+1] != BiomeType::Caves) Divide = 0.2;
				
				int Change = 5 + r.NextRanged(2);
				Change += Maths::Abs(12-(i % 24));
				Change = Change/4;
				
				FakeCaveHeightMap = (heightmap[i]-CaveHeight)-(Change*Divide)-5*Divide+1;
				
				if (j > (heightmap[i]-CaveHeight)-(Change*Divide)-5*Divide && j < (heightmap[i]-CaveHeight)+((Change*2+r.NextRanged(4))*Divide)-5*Divide)
				{
					World[i][j] = CMap::tile_ground;
				}
				else
				{
					if (j >= (heightmap[i]-CaveHeight)+((Change*2)*Divide)-5*Divide)
					{
						const int Top = (heightmap[i]-CaveHeight)+((Change*2)*Divide)-5*Divide;
						const int Bottom = heightmap[i];
						const int Length = Bottom - Top;
						if (j <= Top+((Divide)*(Length/2+1)) || j >= Bottom-((Divide)*(Length/2+1)))
						{
							World[i][j] = CMap::tile_ground_back;
						}
					}
				}
			} 
			else
			{
				CaveHeight = 10 + r.NextRanged(6);
			}
			
			const int Depth = j - FakeCaveHeightMap;

			if (heightmap[i] <= j)
			{
			    World[i][j] = CMap::tile_ground;
			}

			if (World[i][j] == CMap::tile_ground)
			{
			    bool isGoldCluster = (j > SeaLevel || Depth > 40) && r.NextRanged(1000) < (Maths::Clamp(Depth / 2, 5, 20));
			    bool isStoneCluster = !isGoldCluster && Depth > 10 && r.NextRanged(1000) < (Maths::Clamp(Depth, 30, 60));
				bool isPureGoldCluster = !isGoldCluster && !isStoneCluster && Depth > 80 && r.NextRanged(1000) < 20;

			    if (isGoldCluster || isStoneCluster || isPureGoldCluster)
			    {
			        int clusterValue = 20 + r.NextRanged(20);
			        array<int> xQueue, yQueue;

			        xQueue.push_back(i);
			        yQueue.push_back(j);

			        while (xQueue.size() > 0 && clusterValue > 0)
			        {
			            int x = xQueue[xQueue.size() - 1];
			            int y = yQueue[yQueue.size() - 1];
			            xQueue.pop_back();
			            yQueue.pop_back();

			            if (isGoldCluster)
			            {
			                if (World[x][y] == CMap::tile_ground)
			                {
			                    if (r.NextRanged(100) < 20)
			                    {
			                        World[x][y] = CMap::tile_gold;
			                    }
			                    else
			                    {
			                        World[x][y] = CMap::tile_stone;
			                    }
			                    clusterValue--;
			                }
			            }
						else if (isPureGoldCluster)
           				{
           				    if (World[x][y] == CMap::tile_ground)
           				    {
           				        World[x][y] = CMap::tile_gold;
           				        clusterValue--;
           				    }
           				}
			            else if (isStoneCluster)
			            {
			                if (World[x][y] == CMap::tile_ground)
			                {
			                    World[x][y] = (r.NextRanged(100) < 50) ? CMap::tile_stone : CMap::tile_thickstone;
			                    clusterValue--;
			                }
			            }

			            if (r.NextRanged(100) < 40)
			            {
			                for (int dx = -1; dx <= 1; dx++)
			                {
			                    for (int dy = -1; dy <= 1; dy++)
			                    {
			                        if (dx == 0 && dy == 0) continue;

			                        int nx = x + dx * (1 + r.NextRanged(2));
			                        int ny = y + dy * (1 + r.NextRanged(2));

			                        if (nx >= 0 && nx < map.tilemapwidth && ny >= 0 && ny < map.tilemapheight)
			                        {
			                            if (World[nx][ny] == CMap::tile_ground)
			                            {
			                                xQueue.push_back(nx);
			                                yQueue.push_back(ny);
			                            }
			                        }
			                    }
			                }
			            }
			        }
			    }
			}

		}
	}
	
	for (int i = 1; i < width-1; i += 1) //Set up the world for some corrosion, to remove dirt points
	{
		for (int j = 1; j < height-1; j += 1)
		{
			if (World[i][j] != CMap::tile_ground) continue;

			if (World[i][j-1] != 0) continue;

			if (World[i-1][j] == 0 || World[i+1][j] == 0)
			{
				World[i][j] = -1;
			}
		}
	}

	for (int i = 1; i < width-1; i += 1) //Corrode dirt points
	{
		for (int j = 1; j < height-1; j += 1)
		{ 
			if (World[i][j] == -1) World[i][j] = 0;
		}
	}
	
	int FakeCaveTile = 137;
	int FakeCaveTile2 = 138;
	
	for (int i = 0; i < width; i += 1)
	{
		if (r.NextRanged(3) == 0)
		{
			const int plusY = r.NextRanged(height);
			if (World[i][plusY] != CMap::tile_empty) World[i][plusY] = FakeCaveTile;
		}
	}
	
	for (int i = 0; i < 5; i++)
	{
		Vec2f WormPos = Vec2f(r.NextRanged(width), height/2);
		Vec2f WormDir = Vec2f(1,0);
		WormDir.RotateBy(45+r.NextRanged(45));
		
		for (int j = 0; j < 200+r.NextRanged(200); j += 1)
		{
			WormDir.RotateBy(int(r.NextRanged(41))-20);
			WormPos = WormPos + WormDir;
		
			if (WormPos.y < 1 || WormPos.y > height-1 || WormPos.x < 1 || WormPos.x > width-1) break;
			
			if (World[u16(WormPos.x)][u16(WormPos.y)] != 0) World[u16(WormPos.x)][u16(WormPos.y)] = FakeCaveTile2;
		}
	}
	
	for (int i = 2; i < width-2; i += 1) //Expand caves a bit
	{
		for (int j = 2; j < height-2; j += 1)
		{
			if (World[i][j] != FakeCaveTile) continue;

			for (int k = 0;k < 10; k += 1)
			{
				int plusX = int(r.NextRanged(5))-2;
				int plusY = int(r.NextRanged(5))-2;
				if (World[i+plusX][j+plusY] != CMap::tile_empty)World[i+plusX][j+plusY] = FakeCaveTile2;
			}
		}
	}
	
	for (int i = 2; i < width-2; i += 1) //Expand caves a bit Mooore
	{
		for (int j = 2; j < height-2; j += 1)
		{
			if (World[i][j] != FakeCaveTile2) continue;

			for (int k = 0; k < 10; k += 1)
			{
				const int plusX = int(r.NextRanged(5))-2;
				const int plusY = int(r.NextRanged(5))-2;
				if (World[i+plusX][j+plusY] != CMap::tile_empty && World[i+plusX][j+plusY] != FakeCaveTile2)
				{
					World[i+plusX][j+plusY] = FakeCaveTile;
				}
			}
		}
	}
	
	for (int i = 0; i < width; i += 1) //Replace caves with thier actual backgrounds
	{
		for (int j = 0; j < height; j += 1)
		{
			if (World[i][j] == FakeCaveTile || World[i][j] == FakeCaveTile2)
			{
				World[i][j] = CMap::tile_ground_back;
			}
		}
	}
	
	const int bed_start = 6;
	for (int i = 0; i < width; i += 1) //Set bedrock at bottom
	{
		for (int j = height - bed_start; j < height; j += 1)
		{
			const f32 frac = j + (map_noise.Fractal(i / 2.0f, j / 2.0f) * 2 - 1) * 3;
			if (frac > height - bed_start)
			{
				World[i][j] = CMap::tile_bedrock;
			}
		}
	}

	/// Unnatural structures ///
	
	const int NodeOffset = -2 - int(r.NextRanged(3));
	const int NodeSize = 7;

	/*const int SewerLine = (Maths::Floor(height/NodeSize)-1)*NodeSize+5+NodeOffset;
	for (int i = 0; i < width; i += 1)
	{
		if (World[i][SewerLine] != 0)
		{
			World[i][SewerLine] = GetRandomTunnelBackground(r);
		}
	}*/
	
	bool[][] Nodes(width / NodeSize);
	for (int i = 0; i < Nodes.length; i += 1)
	{
		Nodes[i].resize(height/NodeSize);
	}
	
	for (int i = 1; i < width/NodeSize-1; i += 1) //Find random suitable nodes
	{
		for (int j = 1; j < height/NodeSize; j += 1)
		{
			Nodes[i][j] = false;
			
			if (r.NextRanged(j) > (f32(height/NodeSize)*0.7f) || r.NextRanged(15) == 0)
			if (World[i*NodeSize][j*NodeSize+NodeOffset] != 0 && World[i*NodeSize][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
			if (World[i*NodeSize+1][j*NodeSize+NodeOffset] != 0 && World[i*NodeSize+1][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
			if (World[i*NodeSize+1][j*NodeSize+1+NodeOffset] != 0 && World[i*NodeSize+1][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
			if (World[i*NodeSize][j*NodeSize+1+NodeOffset] != 0 && World[i*NodeSize][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
			Nodes[i][j] = true;
		}
	}
	
	for (int i = 2; i < width/NodeSize-2; i += 1) //Extend nodes left or right
	{
		for (int j = 1; j < height/NodeSize; j += 1)
		{
			if(!Nodes[i][j]) continue;

			if (r.NextRanged(2) == 0)
			{
				if (World[(i-1)*NodeSize][j*NodeSize+NodeOffset] != 0 && World[(i-1)*NodeSize][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i-1)*NodeSize+1][j*NodeSize+NodeOffset] != 0 && World[(i-1)*NodeSize+1][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i-1)*NodeSize+1][j*NodeSize+1+NodeOffset] != 0 && World[(i-1)*NodeSize+1][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				if (World[(i-1)*NodeSize][j*NodeSize+1+NodeOffset] != 0 && World[(i-1)*NodeSize][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				Nodes[i-1][j] = true;
			}
			else
			{
				if (World[(i+1)*NodeSize][j*NodeSize+NodeOffset] != 0 && World[(i+1)*NodeSize][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i+1)*NodeSize+1][j*NodeSize+NodeOffset] != 0 && World[(i+1)*NodeSize+1][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i+1)*NodeSize+1][j*NodeSize+1+NodeOffset] != 0 && World[(i+1)*NodeSize+1][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				if (World[(i+1)*NodeSize][j*NodeSize+1+NodeOffset] != 0 && World[(i+1)*NodeSize][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				Nodes[i+1][j] = true;
			}
		}
	}
	
	for (int i = 1; i < width/NodeSize-1; i += 1) //Kill any singleton nodes with no connectors :(
	{
		for (int j = 1; j < height/NodeSize; j += 1)
		{
			if(!Nodes[i][j]) continue;

			if (j < height/NodeSize-1)
			{
				if(!Nodes[i-1][j])
				if(!Nodes[i+1][j])
				if(!Nodes[i][j-1])
				if(!Nodes[i][j+1])
				Nodes[i][j] = false;
			}
			else
			{
				if(!Nodes[i-1][j])
				if(!Nodes[i+1][j])
				if(!Nodes[i][j-1])
				Nodes[i][j] = false;
			}
		}
	}

	for (int i = 1; i < width/NodeSize-1; i += 1) //Build tunnels from nodes.
	{
		for (int j = 1; j < height/NodeSize; j += 1)
		{
			if(!Nodes[i][j]) continue;

			World[i*NodeSize][j*NodeSize+NodeOffset]     = GetRandomTunnelBackground(r);
			World[i*NodeSize+1][j*NodeSize+NodeOffset]   = GetRandomTunnelBackground(r);
			World[i*NodeSize][j*NodeSize+1+NodeOffset]   = GetRandomTunnelBackground(r);
			World[i*NodeSize+1][j*NodeSize+1+NodeOffset] = GetRandomTunnelBackground(r);
			
			World[i*NodeSize-1][j*NodeSize+NodeOffset]   = GetRandomCastleTile(r);
			World[i*NodeSize-1][j*NodeSize+NodeOffset+1] = GetRandomCastleTile(r);
			World[i*NodeSize+2][j*NodeSize+NodeOffset]   = GetRandomCastleTile(r);
			World[i*NodeSize+2][j*NodeSize+NodeOffset+1] = GetRandomCastleTile(r);
			World[i*NodeSize][j*NodeSize+NodeOffset-1]   = GetRandomCastleTile(r);
			World[i*NodeSize+1][j*NodeSize+NodeOffset-1] = GetRandomCastleTile(r);
			World[i*NodeSize][j*NodeSize+NodeOffset+2]   = GetRandomCastleTile(r);
			World[i*NodeSize+1][j*NodeSize+NodeOffset+2] = GetRandomCastleTile(r);
		}
	}
		
	for (int i = 1; i < width/NodeSize-1; i += 1) //Build tunnels from nodes.
	{
		for (int j = 1; j < height/NodeSize; j += 1)
		{
			if(!Nodes[i][j]) continue;

			if (Nodes[i+1][j])
			{
				for (int k = 0; k < NodeSize-2; k += 1)
				{
					World[i*NodeSize+k+2][j*NodeSize+NodeOffset] = GetRandomTunnelBackground(r);
					World[i*NodeSize+k+2][j*NodeSize+1+NodeOffset] = GetRandomTunnelBackground(r);
					
					if (r.NextRanged(3) != 0)World[i*NodeSize+k+2][j*NodeSize+2+NodeOffset] = GetRandomCastleTile(r);
					if (r.NextRanged(3) != 0)World[i*NodeSize+k+2][j*NodeSize-1+NodeOffset] = GetRandomCastleTile(r);
				}
			}
			
			if (j < height/NodeSize-1)
			{
				if (Nodes[i][j+1])
				{
					for (int k = 0; k < NodeSize-2; k += 1)
					{
						World[i*NodeSize][j*NodeSize+k+2+NodeOffset] = GetRandomTunnelBackground(r);
						World[i*NodeSize+1][j*NodeSize+k+2+NodeOffset] = GetRandomTunnelBackground(r);
						
						if (r.NextRanged(3) != 0)World[i*NodeSize-1][j*NodeSize+k+2+NodeOffset] = GetRandomCastleTile(r);
						if (r.NextRanged(3) != 0)World[i*NodeSize+2][j*NodeSize+k+2+NodeOffset] = GetRandomCastleTile(r);
					}
				}
			}
			/*else if (r.NextRanged(5) == 0) //Drain thing that leads to sewers, only spawns on the lowest tunnels.
			{
				World[i*NodeSize-1][j*NodeSize+NodeOffset+2] = CMap::tile_castle;
				World[i*NodeSize+1][j*NodeSize+NodeOffset+2] = CMap::tile_castle;
				World[i*NodeSize-2][j*NodeSize+NodeOffset+2] = CMap::tile_castle;
				World[i*NodeSize+2][j*NodeSize+NodeOffset+2] = CMap::tile_castle;
				World[i*NodeSize-1][j*NodeSize+NodeOffset+3] = CMap::tile_castle_moss;
				World[i*NodeSize+1][j*NodeSize+NodeOffset+3] = CMap::tile_castle_moss;
				
				for (int k = j*NodeSize+NodeOffset+2; k < SewerLine; k += 1)
				{
					World[i*NodeSize][k] = CMap::tile_castle_back_moss;
				}
			}*/
		}
	}

	bool[] SurfacePlanner(width); //The surface planner
	//Basically, if a building is generated, it sets the area in surface planner to false, so other buildings won't build there.
	//Almost all buildings won't build on/in cave biomes, cause that will heavily screw things up.
	for (int i = 1; i < width; i += 1)
	{
		SurfacePlanner[i] = true;
	}

	/// Piers ///

	/*for (int i = 10; i < width-10; i += 1)
	{
		if (r.NextRanged(10) != 0 || World[i][SeaLevel] != 0) continue;

		if (World[i-1][SeaLevel] == CMap::tile_ground || World[i+1][SeaLevel] == CMap::tile_ground)
		{
			for (int j = -5; j <= 5; j += 1)
			{
				if (World[i+j][SeaLevel] != 0) continue;

				World[i+j][SeaLevel] = CMap::tile_wood;
				if (j == 4 || j == -4)
				{
					if (World[i+j][SeaLevel-1] == 0)
						World[i+j][SeaLevel-1] = CMap::tile_wood_back;
					if (r.NextRanged(2) == 0 && World[i+j][SeaLevel-2] == 0)
						World[i+j][SeaLevel-2] = CMap::tile_wood_back;
				}
				
				if (Maths::Abs(j) % 2 == 0)
				{
					for (int k = 1; k < 5+r.NextRanged(10); k += 1)
					{
						if (World[i+j][SeaLevel+k] == 0) World[i+j][SeaLevel+k] = CMap::tile_wood_back;
					}
				}
			}
		}
	}*/
	
	/// WELLS ///

	for (int times = 0; times < 3 + r.NextRanged(2); times += 1)
	{
		for (int i = 1; i < width/NodeSize-1; i += 1)
		{
			bool CanBuild = r.NextRanged(20) == 0; //I know this is bad code, don't judge me;
			
			for (int j = -2; j < 4; j += 1)
			{
				if (!SurfacePlanner[i*NodeSize+j] || biome[i*NodeSize+j] == BiomeType::Caves) CanBuild = false;
			}
			
			if (!CanBuild) continue;

			int Highest = height;

			for (int j = -2; j < 4; j += 1)
			{
				if (Highest > heightmap[i*NodeSize+j]) Highest = heightmap[i*NodeSize+j];
			}

			if (Highest >= SeaLevel) continue;
			
			for (int j = 0; j < 5; j += 1)
			{
				World[i*NodeSize-1][Highest+j-1] = CMap::tile_castle;
				World[i*NodeSize+2][Highest+j-1] = CMap::tile_castle;
				World[i*NodeSize][Highest+j-1] = CMap::tile_castle_back;
				World[i*NodeSize+1][Highest+j-1] = CMap::tile_castle_back;
			}
			
			for (int j = Highest+2; j < height; j += 1)
			{
				if (World[i*NodeSize][j] == CMap::tile_bedrock || World[i*NodeSize+1][j] == CMap::tile_bedrock) break;

				if (j < Highest+((height-Highest)/2) || r.NextRanged(3) > 0) World[i*NodeSize][j] = GetRandomTunnelBackground(r);
				if (j < Highest+((height-Highest)/2) || r.NextRanged(3) > 0) World[i*NodeSize+1][j] = GetRandomTunnelBackground(r);
				if (r.NextRanged(3) == 0) World[i*NodeSize-1][j] = GetRandomCastleTile(r);
				if (r.NextRanged(3) == 0) World[i*NodeSize+2][j] = GetRandomCastleTile(r);
				
				if (j >= SeaLevel)
				{
					map.server_setFloodWaterWorldspace(Vec2f((i*NodeSize)*8,j*8),true);
					map.server_setFloodWaterWorldspace(Vec2f((i*NodeSize+1)*8,j*8),true);
				}
			}
			
			if (r.NextRanged(2) == 0) //Do we have a lid? As in, has the well been decommisioned?
			{
				World[i*NodeSize][Highest-1] = CMap::tile_wood;
				World[i*NodeSize+1][Highest-1] = CMap::tile_wood;
				
				if (r.NextRanged(2) == 0) server_CreateBlob("bucket",-1,Vec2f((i*NodeSize+1)*8,(Highest-2)*8)); //Place bucket on lid or it's lost :(
			}
			else //Other wise, make a pretty roof!
			{
				const int RoofType = r.NextRanged(2) == 0 ? CMap::tile_wood : CMap::tile_castle;
				const int PillarType = r.NextRanged(2) == 0 ? CMap::tile_wood_back : CMap::tile_castle_back;

				for (u8 g = 0; g < 5+XORRandom(25); g++)
				{
					if (XORRandom(3) == 0) continue;
					Vec2f gpos = Vec2f(i*NodeSize+XORRandom(2), Highest+g) * 8;
					server_CreateBlob("gravel", -1, gpos+Vec2f(4,4));
				}
				
				World[i*NodeSize-1][Highest-2] = PillarType;
				World[i*NodeSize-1][Highest-3] = PillarType;
				World[i*NodeSize+2][Highest-2] = PillarType;
				World[i*NodeSize+2][Highest-3] = PillarType;
				
				for (int j = 0; j < 4; j += 1)
				{
					World[i*NodeSize-1+j][Highest-4] = RoofType;
				}
				
				int bucketPos = -2;
				if (r.NextRanged(2) == 0)bucketPos = 4;
				
				server_CreateBlob("bucket", -1, Vec2f((i*NodeSize+bucketPos)*8,(Highest-1)*8));
			}
		
			for (int j = -2; j < 4; j += 1)
			{
				SurfacePlanner[i*NodeSize+j] = false;
			}
			
			break;
		}
	}
	
	/// NATURE ///
	
	for (int i = 0; i < width; i += 1) //Plants \o/
	{
		for (int j = 0; j < height-1; j += 1)
		{
			getNet().server_KeepConnectionsAlive();
			if (World[i][j] == 0 && World[i][j+1] == CMap::tile_ground)
			{
				if (biome[i] == BiomeType::Swamp)
				{
					if (r.NextRanged(25) == 0)
					{
						const string tree_name = r.NextRanged(2) == 0 ? "tree_pine" : "tree_bushy";
						SpawnTree(tree_name, Vec2f(i*8, j*8));
					}
					if (r.NextRanged(4) == 0)
					{
						server_CreateBlob("bush", -1, Vec2f(i*8, j*8));
					}
				}
				
				if (j < SeaLevel)
				{
					if((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(2) == 0) //Grass
					{
						World[i][j] = CMap::tile_grass + r.NextRanged(4);
					}
					if (biome[i] == BiomeType::Meadow || biome[i] == BiomeType::Swamp) //Grass
					{
						World[i][j] = CMap::tile_grass + r.NextRanged(4);
					}
					
					if((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(12) == 0) //Trees
					{
						const string tree_name = j < height/3 ? "tree_pine" : "tree_bushy";
						SpawnTree(tree_name, Vec2f(i*8, j*8));
					}
					
					//Rare chance for trees in meadows. This is incase world gen screws up and decides only meadows.
					if (biome[i] == BiomeType::Meadow && r.NextRanged(35) == 0)
					{
						const string tree_name = j < height/3 ? "tree_pine" : "tree_bushy";
						SpawnTree(tree_name, Vec2f(i*8, j*8));
					}
					
					if((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(25) == 0) //Flowers
					{
						SpawnPlant("flowers", Vec2f(i*8, j*8));
					}
					
					if((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(5) == 0) //Bushes
					{
						server_CreateBlob("bush", -1, Vec2f(i*8, j*8));
						
						if (r.NextRanged(25) == 0)
						{
							SpawnPlant("flowers", Vec2f(i*8, j*8));
						}
					}
					
					if (biome[i] == BiomeType::Desert || r.NextRanged(3) == 0) //Grain grows in the desert cause it's hipster like that.
					{
						if (r.NextRanged(10) == 0)
						{
							SpawnPlant("grain_plant", Vec2f(i*8, j*8));
						}
					}
					
					if (biome[i] == BiomeType::Meadow && r.NextRanged(8) == 0) //LOTSA FLOWERS!! @.@
					{
						SpawnPlant("flowers", Vec2f(i*8, j*8));
						
						if (r.NextRanged(5) == 0)
						{
							server_CreateBlob("bush", -1, Vec2f(i*8, j*8));
						}
					}
				}
				else if (j == SeaLevel)
				{
					if (biome[i] == BiomeType::Swamp)
					{
						World[i][j] = CMap::tile_grass + r.NextRanged(4); //Grass
						map.server_setFloodWaterWorldspace(Vec2f(i*8, j*8), true);
					}
				}
				
				break;
			}
		}
	}
	
	for (int i = 0; i < width; i += 1) //Start water dirt
	{
		for (int j = 0; j < height; j += 1)
		{
			if (World[i][j] == 0 && j >= SeaLevel)
			{
				if (i > 0 && World[i-1][j] != 0 && World[i-1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					World[i][j] = CMap::tile_ground_back;
				if (j < height-2 && World[i][j+1] != 0 && World[i][j+1] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					World[i][j] = CMap::tile_ground_back;
				if (i < width-2 && World[i+1][j] != 0 && World[i+1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					World[i][j] = CMap::tile_ground_back;
			}
		}
	}
	
	for (int k = 0; k < 8; k += 1)
	{
		for (int i = 1; i < width-1; i += 1) //Grow dirt in water
		{
			for (int j = SeaLevel+1; j < height-1; j += 1)
			{
				getNet().server_KeepConnectionsAlive();
				if (World[i][j] == CMap::tile_ground_back && r.NextRanged(4) == 0)
				{
					if (World[i-1][j] == 0 && r.NextRanged(2) == 0) World[i-1][j] = CMap::tile_ground_back;
					if (World[i][j+1] == 0 && r.NextRanged(2) == 0) World[i][j+1] = CMap::tile_ground_back;
					if (World[i+1][j] == 0 && r.NextRanged(2) == 0) World[i+1][j] = CMap::tile_ground_back;
					if (World[i][j-1] == 0 && r.NextRanged(2) == 0) World[i][j-1] = CMap::tile_ground_back;

					if (World[i][j+1] != 0 && World[i][j+1] != CMap::tile_ground_back)
					if (World[i][j-1] == 0 || World[i][j-2] == 0 || World[i][j-3] == 0 || World[i][j-4] == 0 || World[i][j-5] == 0)
					if (r.NextRanged(7) == 0)
					{
						//Small chance for bushes "seaweed"
						server_CreateBlob("bush", -1, Vec2f(i*8, j*8));

						if (r.NextRanged(15) == 0) //Small chance for shark, otherwise, fishies!
						{
							server_CreateBlob("shark", -1, Vec2f(i*8,j*8));
						}
						else
						{
							server_CreateBlob("fishy", -1, Vec2f(i*8, j*8));
						}
						map.server_setFloodWaterWorldspace(Vec2f(i*8, j*8), true);
					}
				}
			}
		}
	}

	for (int i = 0; i < width; i += 1) //Finally, set the tiles
	{
		for (int j = 0; j < height; j += 1)
		{
			getNet().server_KeepConnectionsAlive();
			map.server_SetTile(Vec2f(i*8, j*8), World[i][j]);
			if (World[i][j] == 0 && j >= SeaLevel)
			{
				map.server_setFloodWaterWorldspace(Vec2f(i*8, j*8), true);
				if (i > 0 && World[i-1][j] != 0 && World[i-1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					map.server_SetTile(Vec2f(i*8, j*8), CMap::tile_ground_back);
				if (j < height-2 && World[i][j+1] != 0 && World[i][j+1] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					map.server_SetTile(Vec2f(i*8, j*8), CMap::tile_ground_back);
				if (i < width-2 && World[i+1][j] != 0 && World[i+1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					map.server_SetTile(Vec2f(i*8, j*8), CMap::tile_ground_back);
			}
		}
	}
	
	// spawn crystals
	const int crystal_spawn_start = int(width * 0.35);
	const int crystal_spawn_end = int(width * 0.65);
	Vec2f lastCrystalPosition(-100, -100);
	bool spawned_first_crystal = false;
	bool spawned_second_crystal = false;

	Vec2f[] crystalPositions;
	
	for (int i = 0; i < 50; i++)
	{
	    int x = crystal_spawn_start + XORRandom(crystal_spawn_end - crystal_spawn_start);
	    Vec2f crystalPos(x * map.tilesize, heightmap[x] * map.tilesize);
 
	    bool validPosition = true;
	    for (int y_offset = 0; y_offset <= 1; y_offset++)
	    {
	        Vec2f checkPos = crystalPos + Vec2f(0, y_offset * map.tilesize);
	        if (!map.isTileSolid(map.getTile(checkPos).type))
	        {
	            validPosition = false;
	            break;
	        }
	    }
 
	    if (validPosition)
	    {
			for (int cx = -2; cx <= 2; cx++)
			{
				for (int cy = -9; cy <= -1; cy++)
				{
					Vec2f tpos = crystalPos + Vec2f(cx * 8, cy * 8);

					if (map.isTileSolid(tpos))
					{
						u16 tt = map.getTile(tpos).type;
						map.server_SetTile(tpos, tt == CMap::tile_ground || tt == CMap::tile_bedrock ? CMap::tile_ground_back : CMap::tile_empty);
					}
				}
			}

			for (int cz = -2; cz <= 2; cz++)
			{
				Vec2f tpos = crystalPos + Vec2f(cz * 8, 16);
				map.server_SetTile(tpos, CMap::tile_bedrock);
			}

			Vec2f flood_start_pos = crystalPos + Vec2f(0, 24);
			int flood_tiles_cap = 20 + XORRandom(10);
			uint[] tile_list;

			if (getTileListFromFlood(map, flood_start_pos, tile_list, true, 1.0f, 0.15f, flood_tiles_cap))
			{
			    for (u16 i = 0; i < tile_list.size(); i++)
			    {
			        map.server_SetTile(map.getTileWorldPosition(tile_list[i]), CMap::tile_bedrock);
			    }
			}

			if (!spawned_first_crystal)
	        {
	            server_CreateBlob("crystal" + crystals[XORRandom(crystals.size())], -1, crystalPos - Vec2f(-4,12));
	            lastCrystalPosition = crystalPos;
	            spawned_first_crystal = true;
				crystalPositions.push_back(crystalPos);
	        }
	        else if (!spawned_second_crystal && (crystalPos - lastCrystalPosition).Length() > 64.0f && XORRandom(100) < 33)
	        {
	            server_CreateBlob("crystal" + crystals[XORRandom(crystals.size())], -1, crystalPos - Vec2f(-4,12));
	            spawned_second_crystal = true;
				crystalPositions.push_back(crystalPos);
	            break;
	        }	
	    }
	}
 
	if (!spawned_first_crystal)
	{
	    int x = crystal_spawn_start + XORRandom(crystal_spawn_end - crystal_spawn_start);
	    Vec2f crystalPos(x * map.tilesize, heightmap[x] * map.tilesize);

	    server_CreateBlob("crystal" + crystals[XORRandom(crystals.size())], -1, crystalPos - Vec2f(-4,12));
		crystalPositions.push_back(crystalPos);
	}

	// spawn portals
	Vec2f[] portalPositions;

	for (int x = 0; x < width && portals_spawned < max_portals; x += 16)
	{
	    if (biome[x] == BiomeType::Caves && r.NextRanged(3) == 0)
	    {
	        Vec2f portalPos(x * map.tilesize, heightmap[x] * map.tilesize + 128 + XORRandom(1028));
			
			bool do_continue;
			for (int cr = 0; cr < crystalPositions.size(); cr++)
			{
			    if ((crystalPositions[cr] - portalPos).Length() < 512.0f)
			    {
			        do_continue = true;
			        break;
			    }
			}
			
			if (!do_continue)
			{
			    for (int pr = 0; pr < portalPositions.size(); pr++)
			    {
			        if ((portalPositions[pr] - portalPos).Length() < 64.0f)
			        {
			            do_continue = true;
			            break;
			        }
			    }
			}
			
			if (do_continue)
			{
			    do_continue = false;
			    continue;
			}

	        bool roomIsClear = true;
	        for (int x_offset = -4; x_offset <= 3; x_offset++)
	        {
	            for (int y_offset = -3; y_offset <= 4; y_offset++)
	            {
	                Vec2f blockPos = portalPos + Vec2f(x_offset * map.tilesize, y_offset * map.tilesize);
	                if (map.isTileSolid(map.getTile(blockPos).type))
	                {
	                    roomIsClear = false;
	                    break;
	                }
	            }
	            if (!roomIsClear) break;
	        }
 
	        if (!roomIsClear)
	        {
	            Vec2f flood_start_pos = portalPos;
				int flood_tiles_cap = 80 + XORRandom(200);
				uint[] tile_list;

				if (getTileListFromFlood(map, flood_start_pos, tile_list, true, 1.0f, 0.1f+XORRandom(11)*0.01f, flood_tiles_cap))
				{
				    for (u16 i = 0; i < tile_list.size(); i++)
				    {
						Vec2f tpos = map.getTileWorldPosition(tile_list[i]);
				        map.server_SetTile(tpos, CMap::tile_ground_back);
						server_CreateBlob("gravel", -1, tpos - Vec2f(4,4));
				    }
				}
	        }
			
	        server_CreateBlob("ZombiePortal", -1, portalPos);
	        portals_spawned++;
			portalPositions.push_back(portalPos);
	    }
	}
 
	while (portals_spawned < max_portals)
	{
	    int x = XORRandom(width);
	    Vec2f portalPos(x * map.tilesize, heightmap[x] * map.tilesize + 128 + XORRandom(1028));

		Vec2f flood_start_pos = portalPos;
		int flood_tiles_cap = 80 + XORRandom(200);
		uint[] tile_list;

		if (getTileListFromFlood(map, flood_start_pos, tile_list, true, 1.0f, 0.1f+XORRandom(11)*0.01f, flood_tiles_cap))
		{
		    for (u16 i = 0; i < tile_list.size(); i++)
		    {
				Vec2f tpos = map.getTileWorldPosition(tile_list[i]); 
		        map.server_SetTile(tpos, CMap::tile_ground_back);
				if (XORRandom(3)==0) server_CreateBlob("gravel", -1, tpos - Vec2f(4,4));
		    }
		}

	    server_CreateBlob("ZombiePortal", -1, portalPos);
	    portals_spawned++;
		portalPositions.push_back(portalPos);
	}
	
	return true;
}
const Vec2f[] neighbor_tile_dirs = {Vec2f(0,-8),Vec2f(8,0),Vec2f(0,8),Vec2f(-8,0)};

bool getTileListFromFlood(CMap@ map, Vec2f pos, uint[] &inout tile_list, bool solid = true, f32 x_factor = 1.0f, f32 y_factor = 1.0f, int max_tiles = 100)
{
    array<u32> list;
    list.push_back(map.getTileOffset(pos));
    int safety_counter = max_tiles * 10;

    while (list.size() > 0 && tile_list.size() < max_tiles && safety_counter > 0)
    {
        u32 index = list[0];
        list.erase(0);
        safety_counter--;

        TileType tileType = map.getTile(index).type;
        if (map.isTileSolid(tileType) == solid)
        {
            tile_list.push_back(index);

            u32 up = index - map.tilemapwidth;
            u32 down = index + map.tilemapwidth;
            u32 left = index - 1;
            u32 right = index + 1;

            if (tile_list.find(up) == -1 && (XORRandom(100) < y_factor * 100 || !map.isTileSolid(map.getTile(up).type))) list.push_back(up);
            if (tile_list.find(down) == -1 && (XORRandom(100) < y_factor * 100 || !map.isTileSolid(map.getTile(down).type))) list.push_back(down);
            if (tile_list.find(left) == -1 && (XORRandom(100) < x_factor * 100 || !map.isTileSolid(map.getTile(left).type))) list.push_back(left);
            if (tile_list.find(right) == -1 && (XORRandom(100) < x_factor * 100 || !map.isTileSolid(map.getTile(right).type))) list.push_back(right);
        }
    }

    return tile_list.size() > 0;
}

CBlob@ SpawnPlant(const string&in name, Vec2f pos)
{
	CBlob@ plant = server_CreateBlobNoInit(name);
	if (plant !is null)
	{
		plant.Tag("instant_grow");
		plant.setPosition(pos);
		plant.Init();
	}
	return plant;
}

CBlob@ SpawnTree(const string&in name, Vec2f pos)
{
	CBlob@ tree = server_CreateBlobNoInit(name);
	if (tree !is null)
	{
		tree.Tag("startbig");
		tree.setPosition(pos + Vec2f(4, 4));
		tree.Init();
	}
	return tree;
}

int GetRandomTunnelBackground(Random@ r)
{
	switch(r.NextRanged(4))
	{
		case 0: return CMap::tile_ground_back;
		case 1: return CMap::tile_ground_back;
		case 2: return CMap::tile_castle_back;
		case 3: return CMap::tile_castle_back_moss;
	}
	return CMap::tile_ground_back;
}

int GetRandomCastleTile(Random@ r)
{
	switch(r.NextRanged(2))
	{
		case 0: return CMap::tile_castle;
		case 1: return CMap::tile_castle_moss;
	}
	return CMap::tile_castle;
}

void SetupProceduralMap(CMap@ map, const int&in width, const int&in height)
{
	map.CreateTileMap(width, height, 8.0f, "Sprites/world.png");
}

void SetupProceduralBackgrounds(CMap@ map)
{
	// sky
	map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);
	map.CreateSkyGradient("Sprites/skygradient.png");   // override sky color with gradient

	// plains
	map.AddBackground("Sprites/Back/BackgroundPlains.png", Vec2f(0.0f, -50.0f), Vec2f(0.06f, 20.0f), color_white);
	map.AddBackground("Sprites/Back/BackgroundTrees.png", Vec2f(0.0f,  -220.0f), Vec2f(0.18f, 70.0f), color_white);
	//map.AddBackground( "Sprites/Back/BackgroundIsland.png", Vec2f(0.0f, 50.0f), Vec2f(0.5f, 0.5f), color_white ); 
	map.AddBackground("Sprites/Back/BackgroundCastle.png", Vec2f(0.0f, -580.0f), Vec2f(0.3f, 180.0f), color_white);

	// fade in
	SetScreenFlash(255, 0, 0, 0);
}
