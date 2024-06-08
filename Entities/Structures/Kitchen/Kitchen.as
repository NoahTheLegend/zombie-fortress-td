// Kitchen

#include "PotionEffectsCommon.as";

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.addCommandID("playsound");
	this.addCommandID("open_menu");
	this.addCommandID("add1");
	this.addCommandID("add2");
	this.addCommandID("add3");
	this.addCommandID("add4");
	
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().getConsts().accurateLighting = true;

	this.getCurrentScript().tickFrequency = 87; // opt
	this.inventoryButtonPos = Vec2f(-8, 0);

	string[] components;
	this.set("components", components);

	string[] crafts;
	string[][] recipes;

	Shuffle(this, crafts, recipes);
	this.set("crafts", crafts);
	this.set("recipes", recipes);
}

void CreatePotion(CBlob@ this, string[] components)
{
	if (!isServer()) return;
	if (components.size() != potion_size) return;

	string[] crafts;
	string[][] recipes;
	if (!this.get("crafts", crafts)) return;
	if (!this.get("recipes", recipes)) return;

	int found = -1;
	for (u8 i = 0; i < recipes.size(); i++)
	{
		string[] recipe = recipes[i];
		bool correct = true;
		bool do_continue = false;
		//printf("iterating comparison");
		for (u8 j = 0; j < recipe.size(); j++)
		{
			//if (do_continue) continue;
			//printf("COMPARING "+components[j]+" with "+recipe[j]);
			if (components[j] != recipe[j])
			{
				correct = false;
				do_continue = true;
			}
		}

		if (correct)
		{
			found = i;
			break;
		}
	}

	//printf(""+found);
	if (found != -1)
	{
		CBitStream params;
		params.write_string("Cooked.ogg");
		this.SendCommand(this.getCommandID("playsound"), params);

		if (isServer())
		{
			CBlob@ b = server_CreateBlobNoInit("potion");
			if (b !is null)
			{
				b.server_setTeamNum(found%7);
				if (!this.server_PutInInventory(b))
					b.setPosition(this.getPosition());
				b.Init();

				string craft = crafts[found];
				string[] spl = craft.split("_");
				b.set_u8("tier", parseInt(spl[0]));
				b.set_u8("effect", found % potion_types);
			}
		}
	}
	else
	{
		CBitStream params;
		params.write_string("Wings.ogg");
		this.SendCommand(this.getCommandID("playsound"), params);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null || !this.isOverlapping(caller)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());
	CButton@ button = caller.CreateGenericButton(
			23,                                
			Vec2f(4, 0),
			this,                                                    
			this.getCommandID("open_menu"),                                              
			"Brew",
			params
		);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("playsound"))
	{
		if (isClient())
		{
			this.getSprite().PlaySound(params.read_string(), 1.0f, 1.0f + XORRandom(11)*0.01f);
		}
	}
	else if (cmd == this.getCommandID("open_menu"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);

		if (caller is null || !caller.isMyPlayer()) return;
		OpenMenu(this, caller);
	}
	else if (cmd == this.getCommandID("add1"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		string item = pool_components[0];
		if (!caller.hasBlob(item, 1)) return;
		
		caller.TakeBlob(item, 1);
		AddComponent(this, item);
	}
	else if (cmd == this.getCommandID("add2"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		string item = pool_components[1];
		if (!caller.hasBlob(item, 1)) return;
		
		caller.TakeBlob(item, 1);
		AddComponent(this, item);
	}
	else if (cmd == this.getCommandID("add3"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		string item = pool_components[2];
		if (!caller.hasBlob(item, 1)) return;
		
		caller.TakeBlob(item, 1);
		AddComponent(this, item);
	}
	else if (cmd == this.getCommandID("add4"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		string item = pool_components[3];
		if (!caller.hasBlob(item, 1)) return;
		
		caller.TakeBlob(item, 1);
		AddComponent(this, item);
	}
}

void AddComponent(CBlob@ this, string component)
{
	string[] components;
	this.get("components", components);

	components.push_back(component);
	this.set("components", components);
	//if (isServer()) printf(component+": added component, total: "+components.size());

	if (components.size() >= potion_size)
	{
		CreatePotion(this, components);
		string[] empty;
		this.set("components", empty);
	}
}

void OpenMenu(CBlob@ this, CBlob@ caller)
{
	CControls@ controls = getControls();
	if (controls is null) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());
	CGridMenu@ menu = CreateGridMenu(controls.getMouseScreenPos(), this, Vec2f(4, 1), "Add component");
	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		string[] items = {"wheatbunch", "nut", "grass", "bone"};
		CGridButton@ button1 = menu.AddButton("$"+items[0]+"$", "Add component", this.getCommandID("add1"), Vec2f(1, 1), params);
		CGridButton@ button2 = menu.AddButton("$"+items[1]+"$", "Add component", this.getCommandID("add2"), Vec2f(1, 1), params);
		CGridButton@ button3 = menu.AddButton("$"+items[2]+"$", "Add component", this.getCommandID("add3"), Vec2f(1, 1), params);
		CGridButton@ button4 = menu.AddButton("$"+items[3]+"$", "Add component", this.getCommandID("add4"), Vec2f(1, 1), params);
		
		for (u8 i = 0; i < potion_size; i++)
		{
			CGridButton@ button;
			if (i == 0) @button = @button1;
			else if (i == 1) @button = @button2;
			else if (i == 2) @button = @button3;
			else if (i == 3) @button = @button4;

			if (button !is null)
			{
				CInventory@ inv = caller.getInventory();
				if (inv !is null)
				{
					if (inv.getItem(items[i]) is null)
						button.SetEnabled(false);
				}
			}
		}
	}
}

void Shuffle(CBlob@ this, string[] &out crafts, string[][] &out recipes)
{
    u32 seed = getRules().get_u32("match");
	
    string[] shuffledPool = pool_crafts;
    FisherYatesShuffle(shuffledPool, seed);

	//if (isServer())
	//{
    //	for (uint i = 0; i < shuffledPool.length; i++)
    //	{
    //	    printf("PRODUCT: " + shuffledPool[i]);
    //	}
	//}

    crafts = shuffledPool;

    string[][] generatedRecipes;
    for (uint i = 0; i < shuffledPool.length; i++)
    {
        string[] recipe;
        string srecipe = "";
        for (uint j = 0; j < pool_components.size(); j++)
        {
			recipe.push_back(GetRandomComponent(pool_components, seed + i*(j+1)));
		    srecipe += recipe[j] + ", ";
        }

		generatedRecipes.push_back(recipe);
        if (isServer()) printf("RECIPE: " + srecipe);
    }

    recipes = generatedRecipes;
}

u32 NextRandom(u32 max, u32 seed)
{
    seed = seed * 1103515245 + 12345;
    return (seed / 65536) % max;
}

void FisherYatesShuffle(string[]@ arr, u32 seed)
{
    for (int i = arr.length() - 1; i > 0; i--)
    {
        u32 j = NextRandom(i + 1, seed);
        string temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}

string GetRandomComponent(const string[] &in components, u32 seed)
{
    u32 index = NextRandom(components.length(), seed);
    return components[index];
}
