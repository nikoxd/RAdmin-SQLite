#define FILTERSCRIPT
//=======: INCLUDES :======//
#include <a_samp>
#include <a_sampdb>
#include <zcmd>
#include <sscanf>
//===========: NEW :===========//
new Spawned[MAX_PLAYERS];
//=================: NATIVES :====================//
native WP_Hash(buffer[], len, const str[]);
native db_get_field_int(DBResult:result, field = 0);
native Float:db_get_field_float(DBResult:result, field = 0);
native db_get_field_assoc_int(DBResult:result, const field[]);
native Float:db_get_field_assoc_float(DBResult:result, const field[]);
native db_get_mem_handle(DB:db);
native db_get_result_mem_handle(DBResult:result);
native db_debug_openfiles();
native db_debug_openresults();
//============: FORWARDS :=============//
forward PKick(id);
forward PBan(id);
//============: STOCKS :==============//
stock DB_Escape(text[])
{
    new
        ret[80 * 2],
        ch,
        i,
        j;
    while ((ch = text[i++]) && j < sizeof (ret))
    {
        if (ch == '\'')
        {
            if (j < sizeof (ret) - 2)
            {
                ret[j++] = '\'';
                ret[j++] = '\'';
            }
        }
        else if (j < sizeof (ret))
        {
            ret[j++] = ch;
        }
        else
        {
            j++;
        }
    }
    ret[sizeof (ret) - 1] = '\0';
    return ret;
}

stock VehicleOccupied(vehicleid)
{
	for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerInVehicle(i, vehicleid)) return 1;
    }
    return 0;
}

//===========: BEGINING :==========//
new DB: Database;

main() {}

public OnFilterScriptInit()
{
    if ((Database = db_open("database.db")) == DB: 0)
    {
        print("SQLite: Failed to open a connection to \"databse.db\"");
    }
    else
    {
    	db_query(Database,"CREATE TABLE IF NOT EXISTS USRDB(NAME,LEVEL)");
    	print("RyderX's SQLite Administration system has been connected to database!");
    }
    return 1;
}

public OnFilterScriptExit()
{
    db_close(Database);
    return 1;
}

enum pData
{
    pAdmin
};

new PlayerInfo[MAX_PLAYERS][pData];


public OnPlayerConnect(playerid)
{

    new Query[120]; new DBResult:dbResult; new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(Query, sizeof(Query), "SELECT * FROM USRDB WHERE `NAME` = '%s' COLLATE NOCASE", DB_Escape(name));
    dbResult = db_query(Database, Query);
    if(db_num_rows(dbResult))
    {
        new Value[15];
        db_get_field_assoc(dbResult, "LEVEL", Value, 35);
        PlayerInfo[playerid][pAdmin] = strval(Value);
    }
    else
    {
        format(Query, sizeof(Query), "INSERT INTO USRDB(NAME, LEVEL) VALUES('%s', '0')", DB_Escape(name));
        db_query(Database, Query);
    }
    db_free_result(dbResult);

	if(PlayerInfo[playerid][pAdmin] >= 1)
	{
	new string[220];
	new ip[128];
	GetPlayerIp(playerid, ip,sizeof(ip));
	format(string,sizeof(string),"-AdminInfo- {f44f44}%s {666666}has logged to the server! {Ffffff}[IP: %i]",name,ip);
    SendClientMessage(playerid,0xf8f8f8fff,string);
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{

    new Query[120]; new name[MAX_PLAYER_NAME]; new DBResult:dbResult;
    GetPlayerName(playerid, name, sizeof(name));
    format(Query, sizeof(Query), "SELECT * FROM USRDB WHERE NAME = '%s'", DB_Escape(name));

    dbResult = db_query(Database, Query);
    if(db_num_rows(dbResult))
    {
        format(Query,sizeof(Query),"UPDATE USRDB SET LEVEL = '%d' WHERE `NAME` = '%s' COLLATE NOCASE", PlayerInfo[playerid][pAdmin] , DB_Escape(name));
        db_query(Database, Query);
    }
    db_free_result(dbResult);
    return 1;
}

public OnPlayerSpawn(playerid)
{
   Spawned[playerid] = 1;
   return 1;
}
//=========: Simple Commands and Administrators Commands :===========//
CMD:ask(playerid,params[])
{
        if(Spawned[playerid] == 0) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {F00f00}You can't use this command while you are not spawned!");
		new msg[100], str[128], pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname,sizeof( pname));
		if(sscanf(params,"s",msg)) SendClientMessage(playerid, 0xF8f8f8fff,"Syntax: {F00f00}/ask <question>");
        format(str,sizeof(str),"[QUESTION] {FFFFFF}%s(%i) => {f44f44}%s", pname,playerid, msg);
        SendClientMessage(playerid, 0xf8f8f8fff,"[QUESTION] {FFFFFF}Your question has been sent to online helpers/admins.");
		for(new i; i<MAX_PLAYERS; i++)
		{
			if(IsPlayerConnected(i) && PlayerInfo[i][pAdmin] > 0)
			{
 			  	SendClientMessage(i,0xF8f8f8ff,str);
 		  	}
		}
	    return 1;
}

CMD:admins(playerid, params[])
{
    new count = 0, string[256];
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    for(new i = 0; i < MAX_PLAYERS; i ++)
    {
    if(IsPlayerConnected(i))
    {
    if(PlayerInfo[i][pAdmin] == 1)
    {
    format(string, sizeof(string),"- {ffff00}%s%s | (ID:%d) | Trial Admin\n", string, name,i);
    count++;
    }
    if(PlayerInfo[i][pAdmin] == 2)
    {
    format(string, sizeof(string),"- {ff9900}%s%s | (ID:%d) | Moderator\n", string, name,i);
    count++;
    }
    if(PlayerInfo[i][pAdmin] == 3)
    {
    format(string, sizeof(string),"- {66ffcc}%s%s | (ID:%d) | Senior Admin\n", string, name, i);
    count++;
    }
    if(PlayerInfo[i][pAdmin] == 4)
    {
    format(string, sizeof(string),"- {033aff}%s%s | (ID:%d) | Head Admin\n", string, name, i);
    count++;
    }
    }
    }
    if(count == 0)
    {
    ShowPlayerDialog(playerid, 54, DIALOG_STYLE_MSGBOX, "{00ffff}Online Administrator(s):", "{ff0000}There isn't any online administrator Right Now!", "Ok", "");
    }
    else
    {
    ShowPlayerDialog(playerid, 45, DIALOG_STYLE_MSGBOX, "{00ffff}Online Administrator(s):", string, "Ok", "");
    }
    return 1;
}


//=========: LEVEL 1 :=========//
CMD:acmds(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 1)
    {
        new string[1400];
        format(string, sizeof(string), "%s{FFFFFF}Trial Admin [Level 1]- COMMANDS{f00f00}\n/clearchat, /goto, /setskin, /asay, /spawn, /announce, /ac(admins chat), /ans(wer)\n\n", string);
        format(string, sizeof(string), "%s{FFFFFF}Moderator [Level 2] - COMMANDS{f00f00}\n/sethp, /setarmour, /aheal, /aarmour, /kick, /explode, /vs(spawn car)\n\n", string);
        format(string, sizeof(string), "%s{FFFFFF}Senior Admin [Level 3] - COMMANDS{f00F00}\n /jetpack, /disarm, /akill, /(un)freeze, /respawncars, /giveweapon\n\n", string);
        format(string, sizeof(string), "%s{FFFFFF}Head Admin [Level 4] - COMMANDS{F00F00}\n/setlevel, /giveallmoney, /setscore\n\n", string);
        ShowPlayerDialog(playerid, 200, DIALOG_STYLE_MSGBOX, "Administration Commands", string, "Ok", "");
    }
    else
    {
       SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:asay(playerid, params[])
{
    if (PlayerInfo[playerid][pAdmin] >= 1)
    {
    if (isnull(params))
        return SendClientMessage(playerid, 0xf8f8f8fff, "Syntax: {ff0ff0}/asay <text>");

    new string[128], name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(string, sizeof(string),"Administrator {f00f00}%s(%i): {FFFfff}%s", name, playerid, params);
    SendClientMessageToAll(0xF8f8F8FFF, string);
    }
    else
    {
    SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:ans(playerid,params[])
{
if(PlayerInfo[playerid][pAdmin] >= 1)
{
		new msg[100], str[128], pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname,sizeof( pname));
		new id;
		if(sscanf(params,"is[128]",id,msg)) SendClientMessage(playerid, 0xF8f8f8fff,"Syntax: {F00f00}/ans <id> <answer>");
        format(str,sizeof(str),"[ANSWER] {FFFFFF}%s(%i) => {f44f44}%s", pname,playerid, msg);
		for(new i; i<MAX_PLAYERS; i++)
		{
			if(IsPlayerConnected(i) && PlayerInfo[i][pAdmin])
 		  	{
 			  	SendClientMessage(i,0xF8f8f8fff,str);
 		  	}
		}
}
else
{
SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
}
return 1;
}

CMD:ac(playerid, params[])
{
    if(Spawned[playerid] == 0) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {F00f00}You can't use this command while you are not spawned!");
    if(PlayerInfo[playerid][pAdmin] >= 1)
    {
        new msg[100], str[128], pname[MAX_PLAYER_NAME];
        GetPlayerName(playerid, pname,sizeof( pname));
        if(sscanf(params,"s",msg)) SendClientMessage(playerid, 0xF8f8f8fff,"Syntax: {F00f00}/ac <message>");
        format(str,sizeof(str),"{f44f44}<Admin Chat> {f00f00}%s(%i): {f8f8f4}%s", pname,playerid, msg);
        for(new i; i<MAX_PLAYERS; i++)
        {
            if(IsPlayerConnected(i) && PlayerInfo[i][pAdmin] >= 1)
            {
                SendClientMessage(i,0xFA9205FF,str);
            }
        }
    }
    else
    {
        SendClientMessage(playerid, 0xf8F8F8FFF,"ERROR: {FFFF00}You are not authorized to use this command!");
    }
    return 1;
}

CMD:setskin(playerid,params[])
{
   if(PlayerInfo[playerid][pAdmin] >= 1)
   {
   new string[128]; new SkinID; new id;
   if(sscanf(params,"ii",id,SkinID)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {f00f00}/setskin [ID] [SkinID]");
   if(SkinID < 0 || SkinID > 311) return SendClientMessage(playerid, 0xf8f8f8fff, "ERROR: {FFFFFF}Invalid skinID (0 -> 311).");
   if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
   format(string,sizeof(string),"{99bec3}An administrator has set your skin to %d!",SkinID);
   SendClientMessage(id,0xf8f8f8fff,string);
   SetPlayerSkin(id,SkinID);
   }
   else
   {
   SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
   }
   return 1;
}

CMD:spawn(playerid,params[])
{
   if(PlayerInfo[playerid][pAdmin] >= 1)
   {
     new string[128];
     new name[MAX_PLAYER_NAME];
     new tname[MAX_PLAYER_NAME];
     new id;
     GetPlayerName(playerid, name,sizeof(name));
     GetPlayerName(id, tname, sizeof(tname));
     if(sscanf(params,"i",id)) return SendClientMessage(playerid, 0xf8f8f8fff,"Syntax: {f00f00}/spawn <id>");
     if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
     SpawnPlayer(id);
     SetPlayerInterior(id, 0);
     SetPlayerVirtualWorld(id, 0);
     format(string, sizeof(string),"{A9C4E4}Administrator {f00f00}%s {A9C4E4}has spawned %s!",name,tname);
     SendClientMessageToAll(-1,string);
   }
   else
   {
   SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!"); // This Code return the Player IF he's not Login in as RCON admin
   }
   return 1;
}

CMD:clearchat(playerid,params[])
{
if(PlayerInfo[playerid][pAdmin] >= 1)
{
new name[MAX_PLAYER_NAME];
GetPlayerName(playerid, name,sizeof(name));
new string[128];
for(new i = 0; i < 100; i++) SendClientMessageToAll(0x00000000," ");
SendClientMessageToAll(0xf8f8f8fff,"==========================================");
format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has cleared the chat!", name);
SendClientMessageToAll(-1,string);
SendClientMessageToAll(0xf8f8f8fff,"==========================================");
}
else
{
SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
}
return 1;
}

CMD:announce(playerid, params[])
{
if(PlayerInfo[playerid][pAdmin] >= 1)
{
    if(isnull(params)) return SendClientMessage(playerid, 0xf8f8f8fff, "Syntax: {f00f00}/announce <text>");
    GameTextForAll(params, 6000, 3);
}
else
{
SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
}
return 1;
}

CMD:goto(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 1)
    {
        new ID;
        new Float:X;
        new Float:Y;
        new Float:Z;
        new Float:A;
        new string[128];
        if(sscanf(params,"i", ID)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {f00f00}/goto <id>");
        GetPlayerPos(ID, X,Y,Z);
        GetPlayerFacingAngle(ID, A);
        SetPlayerPos(playerid, X,Y,Z);
        SetPlayerFacingAngle(playerid, A);
        format(string,sizeof(string),"[ADMIN] {FFFFFF}You have been Teleported to Specified player.");
        SendClientMessage(playerid,0xf8f8f8fff,string);
    }
    else
    {
        SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}
//======: LEVEL 2 :=======//
CMD:explode(playerid,params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 2)
    {
        new ID;
        if(sscanf(params,"i",ID)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {f00f00}/explode <id>");
        if(!IsPlayerConnected(ID)) return SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected");
        if(PlayerInfo[ID][pAdmin] >= PlayerInfo[playerid][pAdmin]) return SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}You cant explode this admin.");
        new string[80],pname[MAX_PLAYER_NAME], pname2[MAX_PLAYER_NAME];
        GetPlayerName(playerid, pname, sizeof(pname));
        GetPlayerName(ID, pname2, sizeof(pname2));
        format(string, sizeof(string), "{A9C4E4}%s Has been Exploded by Server administrator %s.",pname2,pname);
        SendClientMessageToAll(0xf8f8f8fff,string);
        new Float:x,Float:y,Float:z;
        GetPlayerPos(ID,x,y,z);
        CreateExplosion(x,y,z,5,5);
    }
    else
    {
        SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:aheal(playerid,params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 2)
    {
    new ID;
    if(sscanf(params,"i",ID)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {F00f00}/aheal <ID>");
    if(!IsPlayerConnected(ID)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
    new string[128]; new pname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pname, sizeof(pname));
    format(string, sizeof(string), "{A9C4E4}Administrator %s has healed you!",pname);
    SendClientMessage(ID,0xf8f8f8fff,string);
    SetPlayerHealth(ID,100);
    SendClientMessage(playerid, 0xf8f8f8fff,"[ADMIN] {FFFFFF}Player's health has been refilled!");
    }
    else
    {
    SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:aarmour(playerid,params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 2)
    {
    new ID;
    if(sscanf(params,"i",ID)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {F00f00}/aarmour <ID>");
    if(!IsPlayerConnected(ID)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
    new string[128]; new pname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pname, sizeof(pname));
    format(string, sizeof(string), "{A9C4E4}Administrator %s has armoured you!",pname);
    SendClientMessage(ID,0xf8f8f8fff,string);
    SetPlayerArmour(ID,100);
    SendClientMessage(playerid, 0xf8f8f8fff,"[ADMIN] {FFFFFF}Player's armour has been refilled!");
    }
    else
    {
    SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:setarmour(playerid,params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 2)
    {
        new ID; new amount;
        if(sscanf(params,"ii",ID,amount)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {F00f00}/setarmour <ID> <amount>");
        if(!IsPlayerConnected(ID)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
        if(amount < 0 || amount > 100) return SendClientMessage(playerid, 0xf8f8f8fff, "ERROR: {FFFFFF}Invalid amount (0 -> 100).");
        new string[128]; new pname[MAX_PLAYER_NAME];
        GetPlayerName(playerid, pname, sizeof(pname));
        format(string, sizeof(string), "{A9C4E4}Administrator %s has set your armour amount to %d!",pname,amount);
        SendClientMessage(ID,0xf8f8f8fff,string);
        SetPlayerArmour(ID,amount);
        SendClientMessage(playerid, 0xf8f8f8fff,"[ADMIN] {FFFFFF}Player's armour has been set!");
    }
    else
    {
    SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:sethp(playerid,params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 2)
    {
    new ID; new amount;
    if(sscanf(params,"ii",ID,amount)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {F00f00}/sethp <ID> <amount>");
    if(!IsPlayerConnected(ID)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
    if(amount < 0 || amount > 100) return SendClientMessage(playerid, 0xf8f8f8fff, "ERROR: {FFFFFF}Invalid amount (0 -> 100).");
    new string[128]; new pname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pname, sizeof(pname));
    format(string, sizeof(string), "{A9C4E4}Administrator %s has set your health amount to %d!",pname,amount);
    SendClientMessage(ID,0xf8f8f8fff,string);
    SetPlayerHealth(ID,amount);
    SendClientMessage(playerid, 0xf8f8f8fff,"[ADMIN] {FFFFFF}Player's health has been set!");
    }
    else
    {
    SendClientMessage(playerid,0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:vs(playerid,params[])
{
   if(PlayerInfo[playerid][pAdmin] >= 2)
   {
   new ID;
   new Float:X,Float:Y,Float:Z;
   GetPlayerPos(playerid, X,Y,Z);
   if(sscanf(params,"i",ID)) return SendClientMessage(playerid, 0xf8f8f8fff, "Syntax: {f00f00}/vs <ID>");
   if(ID < 400 || ID > 611) return SendClientMessage(playerid, 0xf8f8f8fff, "ERROR: {FFFFFF}Invalid ID! (400 <> 611)");
   AddStaticVehicle(ID,X,Y,Z,179.7375,6,6);
   SendClientMessage(playerid, 0xf8f8f8fff,"[ADMIN] {FFFFFF}You have spawned a vehicle!");
   }
   else
   {
   SendClientMessage(playerid, 0xf8F8F8FFF,"ERROR: {FFFFFF}You aren't authorized to use this command.");
   }
   return 1;
}

CMD:kick(playerid,params[])
{
    new id;
    new name1[MAX_PLAYER_NAME];
    new name2[MAX_PLAYER_NAME];
    new string[128];
    if(PlayerInfo[playerid][pAdmin] >= 2)
    {
    if(sscanf(params,"i",id)) return SendClientMessage(playerid, 0xF8f8f8FFF,"Syntax: {F00F00}/kick <id>");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player is not connected");
    GetPlayerName(playerid,name1,sizeof(name1));
    GetPlayerName(id,name2,sizeof(name2));
    format(params,129, "{A9C4E4}%s was kicked From Server by %s",name2,name1);
    SendClientMessageToAll(0xf8f8f8fff,string);
    SendClientMessage(id, 0xf8f8f8fff,"{f00f00}You have been kicked from the server!");
    SetTimerEx("PKick", 1000, false, "i", id);
    }
    else
    {
    SendClientMessage(playerid,0xF8F8F8FFF,"ERROR: {FFFFFF}You're not authorized to use this command!");
    }
    return 1;
}

public PKick(id)
{
   Kick(id);
}

//==========: LEVEL 3 :============//
CMD:disarm(playerid,params[])
{
    new string[128]; new name[MAX_PLAYER_NAME]; new tname[MAX_PLAYER_NAME]; new id;
    if(PlayerInfo[playerid][pAdmin] >= 3)
    {
    GetPlayerName(playerid, name,sizeof(name));
    GetPlayerName(id,tname,sizeof(tname));
    if(sscanf(params,"i",id)) return SendClientMessage(playerid, 0xf8f8f8fff, "Syntax: {f00f00}/disarm [ID]");
    format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has disarmed you!",name);
    SendClientMessage(id,0x8f8f8fff,string);
    ResetPlayerWeapons(id);
    }
    else
    {
    SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:akill(playerid,params[])
{
    new string[128]; new name[MAX_PLAYER_NAME]; new tname[MAX_PLAYER_NAME]; new id;
    if(PlayerInfo[playerid][pAdmin] >= 3)
    {
    GetPlayerName(playerid, name,sizeof(name));
    GetPlayerName(id,tname,sizeof(tname));
    if(sscanf(params,"i",id)) return SendClientMessage(playerid, 0xf8f8f8fff, "Syntax: {f00f00}/akill [ID]");
    format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has killed you!",name);
    SendClientMessage(id,0x8f8f8fff,string);
    SetPlayerHealth(id, 0.0);
    }
    else
    {
    SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:freeze(playerid,params[])
{
    new string[128]; new name[MAX_PLAYER_NAME]; new tname[MAX_PLAYER_NAME]; new id;
    if(PlayerInfo[playerid][pAdmin] >= 3)
    {
    GetPlayerName(playerid, name,sizeof(name));
    GetPlayerName(id,tname,sizeof(tname));
    if(sscanf(params,"i",id)) return SendClientMessage(playerid, 0xf8f8f8fff, "Syntax: {f00f00}/freeze <id>");
    format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has freezed you!",name);
    SendClientMessage(id,0x8f8f8fff,string);
    TogglePlayerControllable(id, 0);
    SendClientMessage(playerid, 0xf8f8f8fff,"[ADMIN] {FFFFFF}Player is now Frozen!");
    }
    else
    {
    SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:unfreeze(playerid,params[])
{
    new string[128]; new name[MAX_PLAYER_NAME]; new tname[MAX_PLAYER_NAME]; new id;
    if(PlayerInfo[playerid][pAdmin] >= 3)
    {
    GetPlayerName(playerid, name,sizeof(name));
    GetPlayerName(id,tname,sizeof(tname));
    if(sscanf(params,"i",id)) return SendClientMessage(playerid, 0xf8f8f8fff, "Syntax: {f00f00}/unfreeze <id>");
    format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has unfreezed you!",name);
    SendClientMessage(id,0x8f8f8fff,string);
    TogglePlayerControllable(id, 1);
    SendClientMessage(playerid, 0xf8f8f8fff,"[ADMIN] {FFFFFF}Player is now Un-Frozen!");
    }
    else
    {
    SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:ban(playerid,params[])
{
    new id;
    new name1[MAX_PLAYER_NAME];
    new name2[MAX_PLAYER_NAME];
    new string[128];
    if(PlayerInfo[playerid][pAdmin] >= 3)
    {
    if(sscanf(params,"i",id)) return SendClientMessage(playerid, 0xF8f8f8FFF,"Syntax: {F00F00}/ban <id>");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player is not connected");
    GetPlayerName(playerid,name1,sizeof(name1));
    GetPlayerName(id,name2,sizeof(name2));
    format(params,129, "{A9C4E4}%s was ban From Server by %s",name2,name1);
    SendClientMessageToAll(0xf8f8f8fff,string);
    SendClientMessage(id, 0xf8f8f8fff,"{f00f00}You have been banned from the server!");
    SetTimerEx("PBan", 1000, false, "i", id);
    }
    else
    {
    SendClientMessage(playerid,0xF8F8F8FFF,"ERROR: {FFFFFF}You're not authorized to use this command!");
    }
    return 1;
}

public PBan(id)
{
   Ban(id);
}

CMD:respawncars(playerid,params[])
{
    new string[128]; new name[MAX_PLAYER_NAME];
    if(PlayerInfo[playerid][pAdmin] >= 3)
    {
    GetPlayerName(playerid, name,sizeof(name));
    format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has respawned all unoccupied cars!",name);
    SendClientMessageToAll(0x8f8f8fff,string);
    for(new cars=0; cars<MAX_VEHICLES; cars++)
    {
        if(!VehicleOccupied(cars))
        {
            SetVehicleToRespawn(cars);
        }
    }
    }
    else
    {
    SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:jetpack(playerid,params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 3)
    {
        SetPlayerSpecialAction(playerid,SPECIAL_ACTION_USEJETPACK);
        SendClientMessage(playerid,0xF8f8f8fff,"[ADMIN] {FFFFFF}You gotta jetpack!");
        GameTextForPlayer(playerid, "~Y~JETPACK!",3000,3);
    }
    else
    {
    SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
    }
    return 1;
}

CMD:giveweapon(playerid,params[])
{
   if(PlayerInfo[playerid][pAdmin] >= 3)
   {
	  new string[128];
	  new id;
	  new name[MAX_PLAYER_NAME];
	  new tname[MAX_PLAYER_NAME];
	  new weapon;
	  new amount;
	  GetPlayerName(playerid, name,sizeof(name));
	  GetPlayerName(id, tname,sizeof(tname));
	  if(sscanf(params,"iii",id,weapon,amount)) return SendClientMessage(playerid, 0xf8f8f8fff,"Syntax: {f00f00}/giveweapon <id> <weaponid> <rounds>");
	  if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
	  if(weapon < 0 || weapon > 46) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Invalid weapon! (0 <> 46)");
	  if(amount < 0 || amount > 10000) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Max Rounds (0 <> 10000)");
	  format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has gave %s weapon id %i with %i rounds!",name,tname,weapon,amount);
	  SendClientMessageToAll(-1, string);
	  GivePlayerWeapon(id, weapon,amount);
   }
   else
   {
     SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
   }
   return 1;
}
//======: LEVEL 4 :======//
CMD:giveallmoney(playerid, params[])
{
new value;
new string[128];
new name[MAX_PLAYER_NAME];
GetPlayerName(playerid, name,sizeof(name));
if(PlayerInfo[playerid][pAdmin] == 4)
{
if(sscanf(params, "d", value) != 0) SendClientMessage(playerid, 0xF8f8f8fff, "Syntax: {f00f00}/giveallmoney <amount>");
for(new i = 0; i<MAX_PLAYERS; i++)
{
if(IsPlayerConnected(i))
{
GivePlayerMoney(i, value);
format(string,sizeof(string),"{99bec3}Administrator {f00f00}%s {99bec3}has {15ff00}gave {99bec3}all {FFD700}+%d${99bec3}!", name,value);
SendClientMessageToAll(0xf8f8f8fff,string);
}
}
}
else
{
SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}You aren't authorized to use this command!");
}
return 1;
}

CMD:setlevel(playerid,params[])
{
	if(IsPlayerAdmin(playerid) || PlayerInfo[playerid][pAdmin] >= 4)
	{
		new string[128];
		new name[MAX_PLAYER_NAME];
		new tname[MAX_PLAYER_NAME];
		new id;
		new level;
		GetPlayerName(playerid,name,sizeof(name));
		GetPlayerName(id,tname,sizeof(tname));
		if(sscanf(params,"ii",id,level)) return SendClientMessage(playerid, 0xf8f8f8fff,"[SERVER] {FFFFFF}/setlevel <id> <level>");
		if(level < 0 || level > 4) return SendClientMessage(playerid, 0xf8f8f8fff,"[SERVER] {FFFFFF}Max level is 4!");
		if(!IsPlayerConnected(id)) return SendClientMessage(playerid,0xf8f8f8fff,"[SERVER] {FFFFFF}Player isn't online!");
		format(string,sizeof(string),"* {FFFFFF}Administrator %s has {1afb05}Made {FFFFFF}%s's level to {ffd700}%i!",name,tname,level);
		SendClientMessageToAll(0xf8f8f8fff,string);
		PlayerInfo[id][pAdmin] = level;
	}
	else
	{
		SendClientMessage(playerid,0xf8f8f8fff,"[SERVER] {FFFFFF}You need to be logged in to use this command!");
	}
	return 1;
}

CMD:setscore(playerid,params[])
{
   if(PlayerInfo[playerid][pAdmin] >= 4)
   {
   new string[128];
   new name[128];
   new id;
   new amount;
   GetPlayerName(id,name,sizeof(name));
   if(sscanf(params,"ii",id,amount)) return SendClientMessage(playerid,0xf8f8f8fff,"Syntax: {f00f00}/setscore <id> <amount>");
   if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xf8f8f8fff,"ERROR: {FFFFFF}Player isn't connected!");
   format(string,sizeof(string),"[INFO] {ffffff}Your score has been set to {FFD700}%d",amount);
   SendClientMessage(playerid,0xf8f8f8fff,string);
   SetPlayerScore(id, amount);
   SendClientMessage(playerid, 0xf8f8f8fff,"[INFO] {FFFFFF}Player's score has been set!");
   }
   else
   {
   SendClientMessage(playerid, 0xf8F8F8FFF,"ERROR: {FFFFFF}You aren't authorized to use this command!");
   }
   return 1;
}
//=========: End of the Script :=========//
