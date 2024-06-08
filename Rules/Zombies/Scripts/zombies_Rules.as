
//Zombies gamemode logic script
//Modded by Eanmig
#define SERVER_ONLY

#include "CTF_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";
#include "zombies_Technology.as";
#include "MigrantCommon.as";

const int base_pool = 1500;
const int day_pool = 100;

//simple config function - edit the variables below to change the basics

void Config(ZombiesCore@ this)
{
    string configstr = "../Mods/" + sv_gamemode + "/Rules/" + "Zombies" + "/zombies_vars.cfg";
	if (getRules().exists("Zombiesconfig")) {
	   configstr = getRules().get_string("Zombiesconfig");
	}
	ConfigFile cfg = ConfigFile( configstr );
	
	//how long for the game to play out?
    s32 gameDurationMinutes = cfg.read_s32("game_time",-1);
    if (gameDurationMinutes <= 0)
    {
		this.gameDuration = 0;
		getRules().set_bool("no timer", true);
	}
    else
    {
		this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes);
	}
	
    bool destroy_dirt = cfg.read_bool("destroy_dirt",true);
	getRules().set_bool("destroy_dirt", destroy_dirt);
	bool gold_structures = cfg.read_bool("gold_structures",false);
	bool scrolls_spawn = cfg.read_bool("scrolls_spawn",false);
	bool techstuff_spawn = cfg.read_bool("techstuff_spawn",false);
	getRules().set_bool("gold_structures", gold_structures);
	
	s32 max_zombies = cfg.read_s32("game_time",125);
	max_zombies = 180 + getPlayersCount() * 10;
	getRules().set_s32("max_zombies", max_zombies);
	getRules().set_bool("scrolls_spawn", scrolls_spawn);
	getRules().set_bool("techstuff_spawn", techstuff_spawn);
    //spawn after death time 
    this.spawnTime = (getTicksASecond() * cfg.read_s32("spawn_time", 30));
	
}

//Zombies spawn system

const s32 spawnspam_limit_time = 10;

shared class ZombiesSpawns : RespawnSystem
{
    ZombiesCore@ Zombies_core;

    bool force;
    s32 limit;
	
	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@Zombies_core = cast<ZombiesCore@>(core);
		
		limit = spawnspam_limit_time;
		getRules().set_bool("everyones_dead",false);
	}

    void Update()
    {
		int everyone_dead=0;
		int total_count=Zombies_core.players.length;
        for (uint team_num = 0; team_num < Zombies_core.teams.length; ++team_num )
        {
            CTFTeamInfo@ team = cast<CTFTeamInfo@>( Zombies_core.teams[team_num] );

            for (uint i = 0; i < team.spawns.length; i++)
            {
                CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(team.spawns[i]);
                
                UpdateSpawnTime(info, i);
				if ( info !is null )
				{
					if (info.can_spawn_time>0) everyone_dead++;
					//total_count++;
				}
                DoSpawnPlayer( info );
            }
        }
		if (getRules().isMatchRunning())
		{
			if (everyone_dead == total_count && total_count!=0) getRules().set_bool("everyones_dead",true); 
			//if (getGameTime() % (10*getTicksASecond()) == 0) warn("ED:"+everyone_dead+" TC:"+total_count);
		}
    }
    
    void UpdateSpawnTime(CTFPlayerInfo@ info, int i)
    {
		if ( info !is null )
		{
			u8 spawn_property = 255;
			CPlayer@ p = getPlayerByUsername(info.username);
			if (p !is null && p.getBlob() !is null)
			{
				RemovePlayerFromSpawn(info);
			}

			if(info.can_spawn_time > 0) {
				f32 daytime = getMap().getDayTime();
				if (daytime>0.2f&&daytime<0.75f) info.can_spawn_time = Maths::Min(60*30, info.can_spawn_time);
				info.can_spawn_time--;
				spawn_property = u8(info.can_spawn_time / 30);
			}
			
			string propname = "Zombies spawn time "+info.username;
			
			Zombies_core.rules.set_u8( propname, spawn_property );
			Zombies_core.rules.SyncToPlayer( propname, getPlayerByUsername(info.username) );
		}
	}

	bool SetMaterials( CBlob@ blob,  const string &in name, const int quantity )
	{
		CInventory@ inv = blob.getInventory();

		//already got them?
		if(inv.isInInventory(name, quantity))
			return false;

		//otherwise...
		inv.server_RemoveItems(name, quantity); //shred any old ones

		CBlob@ mat = server_CreateBlob( name );
		if (mat !is null)
		{
			mat.Tag("do not set materials");
			mat.server_SetQuantity(quantity);
			if (!blob.server_PutInInventory(mat))
			{
				mat.setPosition( blob.getPosition() );
			}
		}

		return true;
	}

    void DoSpawnPlayer( PlayerInfo@ p_info )
    {
        if (canSpawnPlayer(p_info))
        {
			//limit how many spawn per second
			if(limit > 0)
			{
				limit--;
				return;
			}
			else
			{
				limit = spawnspam_limit_time;
			}
			
            CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?

            if (player is null)
            {
				RemovePlayerFromSpawn(p_info);
                return;
            }
            if (player.getTeamNum() != int(p_info.team))
            {
				player.server_setTeamNum(1);
			}

			// remove previous players blob	  			
			if (player.getBlob() !is null)
			{
				CBlob @blob = player.getBlob();
				blob.server_SetPlayer( null );
				blob.server_Die();					
			}

			p_info.blob_name = "builder"; //hard-set the respawn blob
            CBlob@ playerBlob = SpawnPlayerIntoWorld( getSpawnLocation(p_info), p_info);

            if (playerBlob !is null)
            {
                p_info.spawnsCount++;
                RemovePlayerFromSpawn(player);

				// spawn resources
				if (getGameTime() < 30)
				{
					SetMaterials( playerBlob, "mat_wood", 250 );
					SetMaterials( playerBlob, "mat_stone", 100 );
				}
				else SetMaterials( playerBlob, "mat_wood", 50 );
            }
        }
    }

    bool canSpawnPlayer(PlayerInfo@ p_info)
    {
        CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(p_info);

		//return true;
        //if (force) { return true; }

        return info.can_spawn_time <= 0;
    }

    Vec2f getSpawnLocation(PlayerInfo@ p_info)
    {
        CTFPlayerInfo@ c_info = cast<CTFPlayerInfo@>(p_info);
		if(c_info !is null)
        {
			CMap@ map = getMap();
			if(map !is null)
			{
				CBlob@[] crystals;
				getBlobsByTag("crystal", @crystals);
				if (crystals.length > 0)
				{
					if (crystals.length == 1 && crystals[0] !is null)
						return crystals[0].getPosition();

					u8 rand = 0;
					for (u8 i = 0; i < 10; i++)
					{
						rand = XORRandom(crystals.length);
					}

					if (crystals[rand] !is null)
						return crystals[rand].getPosition();
				}
				
				f32 x = XORRandom(2) == 0 ? 32.0f : map.tilemapwidth * map.tilesize - 32.0f;
				return Vec2f(x, map.getLandYAtX(s32(x/map.tilesize))*map.tilesize - 16.0f);
			}
        }

        return Vec2f(0,0);
    }

    void RemovePlayerFromSpawn(CPlayer@ player)
    {
        RemovePlayerFromSpawn(core.getInfoFromPlayer(player));
    }
    
    void RemovePlayerFromSpawn(PlayerInfo@ p_info)
    {
        CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(p_info);
        
        if (info is null) { warn("Zombies LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(PlayerInfo@ p_info) )"); return; }

        string propname = "Zombies spawn time "+info.username;
        
        for (uint i = 0; i < Zombies_core.teams.length; i++)
        {
			CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1) {
				team.spawns.erase(pos);
				break;
			}
		}
		
		Zombies_core.rules.set_u8( propname, 255 ); //not respawning
		Zombies_core.rules.SyncToPlayer( propname, getPlayerByUsername(info.username) ); 
		
		info.can_spawn_time = 0;
	}

    void AddPlayerToSpawn( CPlayer@ player )
    {
		s32 tickspawndelay = 0;
		if (player.getDeaths() != 0)
		{
			int gamestart = getRules().get_s32("gamestart");
			int day_cycle = getRules().daycycle_speed*60;
			int timeElapsed = ((getGameTime()-gamestart)/getTicksASecond()) % day_cycle;

			f32 daytime = getMap().getDayTime();
			tickspawndelay = daytime>0.2f&&daytime<0.75f?60*30:180*30;
			warn("DC: "+day_cycle+" TE:"+timeElapsed+" TD:"+tickspawndelay);
			if (timeElapsed<10) tickspawndelay=0;
		}
	
		//; //
        
        CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(core.getInfoFromPlayer(player));

        if (info is null) { warn("Zombies LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; }

		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;

		if (info.team < Zombies_core.teams.length)
		{
			CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[info.team]);
			
			info.can_spawn_time = tickspawndelay;
			
			info.spawn_point = player.getSpawnPoint();
			team.spawns.push_back(info);
		}
		else
		{
			error("PLAYER TEAM NOT SET CORRECTLY!");
		}
    }

	bool isSpawning( CPlayer@ player )
	{
		CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(core.getInfoFromPlayer(player));
		for (uint i = 0; i < Zombies_core.teams.length; i++)
        {
			CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1) {
				return true;
			}
		}
		return false;
	}

};

const u8 bots_per_player = 2;
const u8 max_bots = 16;

shared class ZombiesCore : RulesCore
{
    s32 warmUpTime;
    s32 gameDuration;
    s32 spawnTime;

    ZombiesSpawns@ Zombies_spawns;

    ZombiesCore() {}

    ZombiesCore(CRules@ _rules, RespawnSystem@ _respawns )
    {
        super(_rules, _respawns );
    }
    
    void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
    {
        RulesCore::Setup(_rules, _respawns);
        @Zombies_spawns = cast<ZombiesSpawns@>(_respawns);
        server_CreateBlob( "Entities/Meta/WARMusic.cfg" );
		int gamestart = getGameTime();
		rules.set_s32("gamestart",gamestart);
		rules.SetCurrentState(WARMUP);
    }

    void Update()
    {
        if (rules.isGameOver()) { return; }
		int day_cycle = getRules().daycycle_speed * 60;
		int transition = rules.get_s32("transition");
		int max_zombies = rules.get_s32("max_zombies");
		int num_zombies = rules.get_s32("num_zombies");
		int gamestart = rules.get_s32("gamestart");
		int timeElapsed = getGameTime()-gamestart;
		float difficulty = 2.0*(getGameTime()-gamestart)/getTicksASecond()/day_cycle;
		float actdiff = 4.0*((getGameTime()-gamestart)/getTicksASecond()/day_cycle);
		int dayNumber = ((getGameTime()-gamestart)/getTicksASecond()/day_cycle)+1;
		if (actdiff>9) { actdiff=9; difficulty=difficulty-1.0; } else { difficulty=1.0; }

		CMap@ map = getMap();
		if (map.getDayTime() > 0.3f && map.getDayTime() < 0.75f)
		{				
			f32 mod = Maths::Log(dayNumber)+Maths::Min(10, dayNumber);
			rules.set_f32("pool", base_pool + (getPlayersCount()*1.5f) * (day_pool+XORRandom(day_pool)) * mod);
		}
		
		if (rules.isWarmup() && timeElapsed>getTicksASecond()*30) { rules.SetCurrentState(GAME);}
		rules.set_f32("difficulty", Maths::Clamp(difficulty, 1.5f, 4.0f)); // change some time later
		int intdif = difficulty;
		if (intdif<=0) intdif=1;
		int spawnRate = 240/((dayNumber+1)/2);
		int extra_zombies = 0;
		if (dayNumber > 10) extra_zombies=(dayNumber-10)*10;
		if (extra_zombies>max_zombies-10) extra_zombies=max_zombies-10;
		if (spawnRate<5) spawnRate=5;
		int wraiteRate = 2 + (intdif/4);
		if (getGameTime() % 300 == 0)
		{
			CBlob@[] zombie_blobs;
			getBlobsByTag("zombie", @zombie_blobs );
			num_zombies = zombie_blobs.length;
			rules.set_s32("num_zombies",num_zombies);
			//printf("Zombies: "+num_zombies+" Extra: "+extra_zombies);			
		}
			
	    if (getGameTime() % (spawnRate) == 0 && num_zombies<300)
        {
			CMap@ map = getMap();
			if (map !is null)
			{
				Vec2f[] zombiePlaces;
				rules.SetGlobalMessage( "Day "+ dayNumber);			
				
				getMap().getMarkers("zombie spawn", zombiePlaces );
				
				if (zombiePlaces.length<=0)
				{
					
					for (int zp=8; zp<16; zp++)
					{
						Vec2f col;
						getMap().rayCastSolid( Vec2f(zp*8, 0.0f), Vec2f(zp*8, map.tilemapheight*8), col );
						col.y-=16.0;
						zombiePlaces.push_back(col);
						
						getMap().rayCastSolid( Vec2f((map.tilemapwidth-zp)*8, 0.0f), Vec2f((map.tilemapwidth-zp)*8, map.tilemapheight*8), col );
						col.y-=16.0;
						zombiePlaces.push_back(col);
					}
					//zombiePlaces.push_back(Vec2f((map.tilemapwidth-8)*4,(map.tilemapheight/2)*8));
				}
				//if (map.getDayTime()>0.1 && map.getDayTime()<0.2)
				if (map.getDayTime() > 0.8f || map.getDayTime() < 0.15)
				{
					//Vec2f sp(XORRandom(4)*(map.tilemapwidth/4)*8+(90*8),(map.tilemapheight/2)*8);
					
					Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
					
					string[] names = {"Skeleton", "Zombie", "ZombieArm", "ZombieKnight", "Greg", "Wraith"};
					int[]    weights={25,         125,       50,          500,            100,   150};
					int[]    probs  ={33,         33,        25,          20,             5,     15};

					int pool = int(rules.get_f32("pool"));

					for (u8 k = 0; k < Maths::Max(1, Maths::Ceil(pool/1000)); k++)
					{
						for (u8 i = 0; i < Maths::Min(dayNumber, names.size()); i++)
						{
							if (XORRandom(pool)< weights[i]) continue;
							if (XORRandom(100) < probs[i])
							{
								Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
								if (names[i] == "Greg" || names[i] == "Wraith")
								{
									sp = Vec2f(XORRandom(map.tilemapwidth*8.0f),16+XORRandom(49));
								}
								
								server_CreateBlob(names[i], -1, sp);
								rules.add_f32("pool", -weights[i]);

								printf("Spawning: "+names[i]+" remaining pool: "+int(rules.get_f32("pool"))+" roll: "+k);
							}
						}
					}
					
					/*if (transition == 1 && (dayNumber % 5) == 0)
					{
						transition=0;
						rules.set_s32("transition",0);
						Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
						server_CreateBlob( "BossZombieKnight", -1, sp);
					}*/
				}
				else if (map.getDayTime() > 0.5f && map.getDayTime() < 0.7f)
				{
					CBlob@[] bots;
					getBlobsByTag("player", @bots);
					getBlobsByName("migrant", @bots);

					u16 actual_bots = 0;
					for (u16 i = 0; i < bots.size(); i++)
					{
						CBlob@ b = bots[i];
						if (b is null) continue;
						if (b.getPlayer() !is null) continue;

						actual_bots++;
					}
					if (actual_bots < Maths::Min(getPlayersCount() * bots_per_player, max_bots)
						&& XORRandom(7) == 0)
					{
						Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
						CreateMigrant(sp, 1);
					}

					if (transition == 0)
					{	
						rules.set_s32("transition",1);
					}
				}
			}
		}
		
        RulesCore::Update(); //update respawns
        CheckTeamWon();
    }

    //team stuff

    void AddTeam(CTeam@ team)
    {
        CTFTeamInfo t(teams.length, team.getName());
        teams.push_back(t);
    }

    void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
    {
        CTFPlayerInfo p(player.getUsername(), 0, "builder" );
        players.push_back(p);
        ChangeTeamPlayerCount(p.team, 1);
		getRules().Sync("gold_structures",true);
    }

	void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
	{
		if (!rules.isMatchRunning()) { return; }

		if (victim !is null )
		{
			if (killer !is null && killer.getTeamNum() != victim.getTeamNum())
			{
				addKill(killer.getTeamNum());
			}
		}
	}

    //checks
    void CheckTeamWon( )
    {
        if (!rules.isMatchRunning()) { return; }
		if (getRules().get_bool("everyones_dead")) 
		{
            rules.SetCurrentState(GAME_OVER);
			getRules().SetTeamWon(7);
			int gamestart = rules.get_s32("gamestart");			
			int day_cycle = getRules().daycycle_speed*60;			
			int dayNumber = ((getGameTime()-gamestart)/getTicksASecond()/day_cycle)+1;
            rules.SetGlobalMessage( "You survived for "+ dayNumber+" days" );		
			getRules().set_bool("everyones_dead",false); 
		}
    }

    void addKill(int team)
    {
        if (team >= 0 && team < int(teams.length))
        {
            CTFTeamInfo@ team_info = cast<CTFTeamInfo@>( teams[team] );
        }
    }

};

//pass stuff to the core from each of the hooks

void spawnPortal(Vec2f pos)
{
	server_CreateBlob("ZombiePortal",-1,pos+Vec2f(0,-24.0));
}


void spawnRandomTech(Vec2f pos)
{
	bool techstuff_spawn = getRules().get_bool("techstuff_spawn");
	if (techstuff_spawn)
	{
		int r = XORRandom(2);
		if (r == 0)
			server_CreateBlob("RocketLauncher",-1,pos+Vec2f(0,-16.0));
		else
		if (r == 1)
			server_CreateBlob("megasaw",-1,pos+Vec2f(0,-16.0));
	}
}

void spawnRandomScroll(Vec2f pos)
{
	bool scrolls_spawn = getRules().get_bool("scrolls_spawn");
	if (scrolls_spawn)
	{
		int r = XORRandom(3);
		if (r == 0)
			server_MakePredefinedScroll( pos+Vec2f(0,-16.0), "carnage" );
		else
		if (r == 1)
			server_MakePredefinedScroll( pos+Vec2f(0,-16.0), "midas" );				
		else
		if (r == 2)
			server_MakePredefinedScroll( pos+Vec2f(0,-16.0), "tame" );				
	}
}

void onInit(CRules@ this)
{
	this.set_u32("match", 0);
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	this.add_u32("match", 1);
	int gamestart = this.get_s32("gamestart");			
	int day_cycle = getRules().daycycle_speed*60;			
	int dayNumber = ((getGameTime()-gamestart)/getTicksASecond()/day_cycle)+1;

	f32 mod = Maths::Log(dayNumber)+Maths::Min(10 + (getPlayersCount() * 2), dayNumber);
	this.set_f32("pool", base_pool + getPlayersCount()/2 * (day_pool+XORRandom(day_pool)) * mod);

    printf("Restarting rules script: " + getCurrentScriptName() );
    ZombiesSpawns spawns();
    ZombiesCore core(this, spawns);
    Config(core);
    SetupScrolls(getRules());
	Vec2f[] zombiePlaces;
	getMap().getMarkers("zombie portal", zombiePlaces );
	if (zombiePlaces.length>0)
	{
		for (int i=0; i<zombiePlaces.length; i++)
		{
			spawnPortal(zombiePlaces[i]);
		}
	}
	Vec2f[] techPlaces;
	getMap().getMarkers("random tech", techPlaces );
	if (techPlaces.length>0)
	{
		for (int i=0; i<techPlaces.length; i++)
		{
			spawnRandomTech(techPlaces[i]);
		}
	}

	Vec2f[] scrollPlaces;
	getMap().getMarkers("random scroll", scrollPlaces );
	if (scrollPlaces.length>0)
	{
		for (int i=0; i<scrollPlaces.length; i++)
		{
			spawnRandomScroll(scrollPlaces[i]);
		}
	}

    //this.SetCurrentState(GAME);
    
    this.set("core", @core);
    this.set("start_gametime", getGameTime() + core.warmUpTime);
    this.set_u32("game_end_time", getGameTime() + core.gameDuration); //for TimeToEnd.as
}

