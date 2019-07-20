/*
 *  Modo CW/TG (Clan War & Training)
 *  © por Andrew Manu :)
 */

#include <a_samp>
#include <zcmd>
#include <sscanf2>

static Equipo[MAX_PLAYERS];
static Admin[MAX_PLAYERS];

#define EQUIPO_ESPECTADOR  	0
#define EQUIPO_NARANJA 		1
#define EQUIPO_VERDE 		2

#define COLOR_BLANCO 	0xFFFFFFFF
#define COLOR_NARANJA 	0xF78411FF
#define COLOR_VERDE 	0x77CC77FF
#define COLOR_ROJO      0x9C001fFF

#define DIALOG_COMANDOS 1

#pragma tabsize 0


forward establecerVariables(playerid);
public establecerVariables(playerid)
{
	Admin[playerid] = 0;
	Equipo[playerid] = 0;
	JugadorEstablecerColor(playerid);
}

forward JugadorEstablecerColor(playerid);
public JugadorEstablecerColor(playerid)
{
	if(Equipo[playerid] == EQUIPO_ESPECTADOR)
		SetPlayerColor(playerid, COLOR_BLANCO);
	if(Equipo[playerid] == EQUIPO_NARANJA)
		SetPlayerColor(playerid, COLOR_NARANJA);
	if(Equipo[playerid] == EQUIPO_VERDE)
		SetPlayerColor(playerid, COLOR_VERDE);
}

main()
{
	print("\n----------------------------------");
	print("  Gamemode: CW/TG\n");
	print("  Desarrollador: Andrew_Manu\n");
	print("----------------------------------\n");
}

public OnPlayerConnect(playerid)
{
	establecerVariables(playerid);
	//GameTextForPlayer(playerid,"~w~SA-MP: ~r~Bare Script",5000,5);
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(!success)
	{
    	PlayerPlaySound(playerid,1054,0.0,0.0,0.0);
    	SendClientMessage(playerid, 0xAA3333AA, "El comando que escribiste no existe (/cmds)");
	}
	return 1;
}


public OnPlayerSpawn(playerid)
{
	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
   	return 1;
}

SetupPlayerForClassSelection(playerid)
{
 	SetPlayerInterior(playerid,14);
	SetPlayerPos(playerid,258.4893,-41.4008,1002.0234);
	SetPlayerFacingAngle(playerid, 270.0);
	SetPlayerCameraPos(playerid,256.0815,-43.0475,1004.0234);
	SetPlayerCameraLookAt(playerid,258.4893,-41.4008,1002.0234);
}

public OnPlayerRequestClass(playerid, classid)
{
	SetupPlayerForClassSelection(playerid);
	return 1;
}

public OnGameModeInit()
{
	SetGameModeText("Bare Script");
	ShowPlayerMarkers(1);
	ShowNameTags(1);
	AllowAdminTeleport(1);

	AddPlayerClass(265,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);

	return 1;
}

CMD:setadmin(playerid, params[]){
	new id, nivel;
	if(unformat(params,"ii", id, nivel))
		return SendClientMessage(playerid, COLOR_ROJO, "Comando correcto:{FFFFFF} /setadmin [id] [0-2]");
	if(!IsPlayerConnected(id))
		return SendClientMessage(playerid, COLOR_ROJO, "Este jugador no está conectado en el servidor!");
	if(nivel > 3 || nivel < 0)
		return SendClientMessage(playerid, COLOR_ROJO, "Te pasaste un poco, solo hay 2 niveles!");
	if(GetPVarInt(id,"Logged") != 1)
		return SendClientMessage(playerid, COLOR_ROJO, "El jugador no està registrado!");
	Admin[id] = nivel;
	return 1;
}
CMD:cmds(playerid, params[]){
	if(Admin[playerid] == 1) ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, "Comandos del sevidor", "Jugadores\nEspectador\nAdministrador nivel 1", "Selec", "Cancelar");
	else ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, "Comandos del sevidor", "Jugadores\nEspectador", "Selec", "Cancelar");
	return 1;
}

