#include "Hitters.as";

void onInit(CBlob@ this)
{   
    this.getSprite().SetZ(-50);
    
    CSpriteLayer@ portal = this.getSprite().addSpriteLayer("portal", "ZombiePortal.png", 64, 64);
    CSpriteLayer@ lightning = this.getSprite().addSpriteLayer("lightning", "EvilLightning.png", 32, 32);
    
    portal.addAnimation("default", 0, true).AddFrame(1);
    lightning.addAnimation("default", 4, false);
    lightning.addAnimation("default2", 4, false);
    
    for (int i = 0; i < 7; i++) {
        lightning.getAnimation("default").AddFrame(i * 4);
        lightning.getAnimation("default2").AddFrame(i * 4 + 1);
    }
    
    portal.SetRelativeZ(1000);
    
    this.getShape().getConsts().mapCollisions = false;
    this.set_bool("portalbreach", false);
    this.set_bool("portalplaybreach", false);
    this.SetLight(false);
    this.SetLightRadius(64.0f);
    
    this.SetMinimapVars("mipmip.png", 2, Vec2f(16, 8));
    this.SetMinimapRenderAlways(true);
}

void onDie(CBlob@ this)
{
    server_DropCoins(this.getPosition() + Vec2f(0, -32.0f), 100);

    CBlob@[] portals;
    getBlobsByName("ZombiePortal", @portals);

    if (portals.length == 0) {
        u8 team = 1;
        getRules().SetTeamWon(team);
        getRules().SetCurrentState(GAME_OVER);
        getRules().set_s32("restart_rules_after_game", getGameTime() + 1200);
        
        CTeam@ teamis = getRules().getTeam(team);
        if (teamis !is null) {
            getRules().SetGlobalMessage(teamis.getName() + ", you've destroyed all portals, congratulations!");
        }

        CBlob@[] zombies;
        getBlobsByTag("zombie", @zombies);
        for (u16 i = 0; i < zombies.length; i++) {
            if (zombies[i] !is null) zombies[i].server_Die();
        }
    }
}

void onTick(CBlob@ this)
{
    if (this.getHealth() <= 0) return;

	    int spawnRate = 150 + (this.getNetworkID() % 60);

	if (getGameTime() % spawnRate == 0 && this.get_bool("portalbreach")) {
	    this.getSprite().PlaySound("Thunder");
	    CSpriteLayer@ lightning = this.getSprite().getSpriteLayer("lightning");
	    lightning.SetAnimation(XORRandom(4) > 2 ? "default" : "default2");
	}	

	if (this.get_bool("portalplaybreach")) {
	    this.getSprite().PlaySound("PortalBreach");
	    this.set_bool("portalplaybreach", false);
	    this.SetLight(true);
	    this.SetLightRadius(64.0f);
	}

	if ((getGameTime() + this.getNetworkID()) % 450 == 0) {
        Vec2f spawnPos = this.getPosition();
        bool activate = false;

        CBlob@[] nearbyBlobs;
        this.getMap().getBlobsInRadius(spawnPos, 64, @nearbyBlobs);
        for (uint i = 0; i < nearbyBlobs.length; ++i) {
            if (nearbyBlobs[i].hasTag("player")) {
                activate = true;
                break;
            }
        }

        this.set_bool("portalbreach", activate);
        this.set_bool("portalplaybreach", activate);
        this.Sync("portalplaybreach", true);
        this.Sync("portalbreach", true);

		if (!activate) this.SetLight(false);
    }

	if (!getNet().isServer()) return;

	int num_zombies = getRules().get_s32("num_zombies");

	if (this.get_bool("portalbreach") && getGameTime() % spawnRate == 0 && num_zombies < 200) {
	    CBlob@[] players;
	    getMap().getBlobsInRadius(this.getPosition(), 256, @players);

	    int playerCount = 0;
	    for (u16 i = 0; i < players.length; i++) {
	        if (players[i] !is null && players[i].hasTag("player")) playerCount++;
	    }
	
	    int minZombies = playerCount;
	    int maxZombies = 1 + playerCount * 2;
	    int zombiesToSpawn = XORRandom(maxZombies - minZombies + 1) + minZombies;

	    float wraithChance = 0.05f;
	    float gregChance = 0.1f;
	    float knightChance = 0.15f;
	    float zombieChance = 0.5f;
	    float skeletonChance = 0.2f;

	    Vec2f spawnPos = this.getPosition();
	    for (int i = 0; i < zombiesToSpawn; i++) {
	        float rand = XORRandom(100) / 100.0f;

	        if (rand < wraithChance) {
	            server_CreateBlob("Wraith", -1, spawnPos);
	        } else if (rand < wraithChance + gregChance) {
	            server_CreateBlob("Greg", -1, spawnPos);
	        } else if (rand < wraithChance + gregChance + knightChance) {
	            server_CreateBlob("ZombieKnight", -1, spawnPos);
	        } else if (rand < wraithChance + gregChance + knightChance + zombieChance) {
	            server_CreateBlob("Zombie", -1, spawnPos);
	        } else {
	            server_CreateBlob("Skeleton", -1, spawnPos);
	        }

	        num_zombies++;
	        getRules().set_s32("num_zombies", num_zombies);

	        if (num_zombies >= 200) break;
	    }
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    switch (customData) {
        case Hitters::cata_stones: damage *= 0.05f; break;
        case Hitters::crush: damage *= 1.0f; break;
        case Hitters::explosion: damage *= 4.0f; break;
        case Hitters::keg: damage *= 2.0f; break;
        case Hitters::builder: damage *= 0.75f; break;
    }

    Vec2f pos = this.getPosition();

    if (!this.get_bool("portalbreach") && (XORRandom(8) == 0 || damage > 1.0f)) {
        CBlob@[] nearbyBlobs;
        this.getMap().getBlobsInRadius(pos, 64, @nearbyBlobs);

        for (uint i = 0; i < nearbyBlobs.length; ++i) {
            if (nearbyBlobs[i].hasTag("player")) {
                this.set_bool("portalbreach", true);
                this.set_bool("portalplaybreach", true);
                this.Sync("portalplaybreach", true);
                this.Sync("portalbreach", true);
                break;
            }
        }
    }

    return damage;
}