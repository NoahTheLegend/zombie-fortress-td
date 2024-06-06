// Simple chat processing example.
// If the player sends a command, the server does what the command says.
// You can also modify the chat message before it is sent to clients by modifying text_out

#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";
#include "MigrantCommon.as";

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null)
		return true;

	string name = player.getUsername();
	
	const bool superadmin = getSecurity().getPlayerSeclev(player).getName() == "Super Admin";
	const bool admin = getSecurity().getPlayerSeclev(player).getName() == "Admin";		

	CBlob@ blob = player.getBlob();

	if (blob is null)
	{
		return true;
	}

	//commands that don't rely on sv_test

	else if (text_in == "!bot" && player.isMod()) // TODO: whoaaa check seclevs
	{
		CPlayer@ bot = AddBot("Henry");
		return true;
	}
	else if (text_in == "!debug" && player.isMod())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");
		}
	}

	//spawning things

	//these all require sv_test - no spawning without it
	//some also require the player to have mod status
	if (admin || superadmin || sv_test)
	{
		Vec2f pos = blob.getPosition();
		int team = blob.getTeamNum();

		if (text_in == "!tree")
		{
			server_MakeSeed(pos, "tree_pine", 600, 1, 16);
		}
		else if (text_in == "!btree")
		{
			server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
		}
		else if (text_in == "!stones")
		{
			CBlob@ b = server_CreateBlob("Entities/Materials/MaterialStone.cfg", team, pos);

			if (b !is null)
			{
				b.server_SetQuantity(500);
			}
		}
		else if (text_in == "!whitepage")
		{
			CBlob@ b = server_CreateBlob("whitepage", team, pos);

			if (b !is null)
			{
				b.server_SetQuantity(5);
			}
		}		
		else if (text_in == "!arrows")
		{
			for (int i = 0; i < 3; i++)
			{
				CBlob@ b = server_CreateBlob("Entities/Materials/MaterialArrows.cfg", team, pos);

				if (b !is null)
				{
					b.server_SetQuantity(60);
				}
			}
		}
		else if (text_in == "!bombs")
		{
			//  for (int i = 0; i < 3; i++)
			CBlob@ b = server_CreateBlob("Entities/Materials/MaterialBombs.cfg", team, pos);

			if (b !is null)
			{
				b.server_SetQuantity(5);
			}
		}
		else if (text_in == "!spawnwater" && player.isMod())
		{
			getMap().server_setFloodWaterWorldspace(pos, true);
		}
		else if (text_in == "!seed")
		{
			// crash prevention?
		}
		else if (text_in == "!crate")
		{
			client_AddToChat("usage: !crate BLOBNAME [DESCRIPTION]", SColor(255, 255, 0, 0));
			server_MakeCrate("", "", 0, team, Vec2f(pos.x, pos.y - 30.0f));
		}
		else if (text_in == "!coins")
		{
			player.server_setCoins(player.getCoins() + 1000);
		}
		else if (text_in == "!m")
		{
			CreateMigrant(blob.getPosition(), blob.getTeamNum());
		}
		else if (text_in.substr(0, 1) == "!")
		{
			// check if we have tokens
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if (tokens[0] == "!crate")
				{
					int frame = tokens[1] == "catapult" ? 1 : 0;
					string description = tokens.length > 2 ? tokens[2] : tokens[1];
					server_MakeCrate(tokens[1], description, frame, -1, Vec2f(pos.x, pos.y));
				}
				else if (tokens[0] == "!team")
				{
					int team = parseInt(tokens[1]);
					blob.server_setTeamNum(team);
				}
				else if (tokens[0]=="!time") 
				{
					if (tokens.length < 2) return false;
					getMap().SetDayTime(parseFloat(tokens[1]));
					return false;
				}
				else if (tokens[0]=="!playerteam")
				{
					if (tokens.length!=3) return false;
					CPlayer@ user = GetPlayer(tokens[1]);

					if (user !is null && user.getBlob() !is null)
						user.getBlob().server_setTeamNum(parseInt(tokens[2]));
				}
				else if (tokens[0]=="!class")
				{
					if (tokens.length!=2) return false;
					CBlob@ newBlob = server_CreateBlob(tokens[1],blob.getTeamNum(),blob.getPosition());
					if (newBlob !is null)
					{
						CInventory@ inv = blob.getInventory();
						if (inv !is null)
						{
							blob.MoveInventoryTo(newBlob);
						}
						newBlob.server_SetPlayer(player);
						blob.server_Die();
					}
		}
				else if (tokens[0] == "!scroll")
				{
					string s = tokens[1];
					for (uint i = 2; i < tokens.length; i++)
						s += " " + tokens[i];
					server_MakePredefinedScroll(pos, s);
				}

				return true;
			}

			// try to spawn an actor with this name !actor
			string name = text_in.substr(1, text_in.size());

			if (server_CreateBlob(name, team, pos) is null)
			{
				client_AddToChat("blob " + text_in + " not found", SColor(255, 255, 0, 0));
			}
		}
	}

	return true;
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (text_in == "!debug" && !getNet().isServer())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");

			if (blob.getShape() !is null)
			{
				CBlob@[] overlapping;
				if (blob.getOverlapping(@overlapping))
				{
					for (uint i = 0; i < overlapping.length; i++)
					{
						CBlob@ overlap = overlapping[i];
						print("       " + overlap.getName() + " " + overlap.isLadder());
					}
				}
			}
		}
	}

	return true;
}

CPlayer@ GetPlayer(string username)
{
	username=			username.toLower();
	int playersAmount=	getPlayerCount();
	for (int i=0;i<playersAmount;i++)
	{
		CPlayer@ player=getPlayer(i);
		string playerName = player.getUsername().toLower();
		if (playerName==username || (username.size()>=3 && playerName.findFirst(username,0)==0)) return player;
	}
	return null;
}