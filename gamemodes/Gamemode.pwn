/*
 *  Modo CW/TG (Clan War & Training)
 *  © por Andrew Manu :)
*/

#include <a_samp>
#include <zcmd>

#define NOMBRE_EQUIPO_NARANJA 	"Naranja"
#define NOMBRE_EQUIPO_VERDE 	"Verde"

#define EQUIPO_NARANJA   	0
#define EQUIPO_VERDE   		1
#define EQUIPO_ESPECTADOR  	2

#define RONDA_POR_DEFECTO   1
#define PUNTAJE_POR_DEFECTO 10

#define CLAN_NOMBRE         0
#define CLAN_TAG            1

#define COLOR_BLANCO 		0xFFFFFFFF
#define COLOR_NARANJA 		0xF78411FF
#define COLOR_VERDE 		0x77CC77FF
#define COLOR_ROJO      	0xBF0000FF

#define GRISEADO            "{C3C3C3}"
#define GRISEADOS           "{C7C7C7}"
#define ROJO	            "{F51111}"

#define DIALOG_REGISTRO 	1
#define DIALOG_LOGEAR   	2
#define DIALOG_COMANDOS 	3
#define DIALOG_STATS        4
#define DIALOG_FPSALL       5
#define DIALOG_SEQUIPO      6    /* Seleccionar equipo */
#define DIALOG_CREDITOS     7
#define DIALOG_IFCLAN       8	/* Verificacion de crear un clan */
#define DIALOG_INCLAN       9	/*¨Ingresar nombre del clan */
#define DIALOG_TGCLAN       10	/* Ingresar tag del clan */
#define DIALOG_IFELCLAN     11  /*¨Verrificacion de borrar un clan */
#define DIALOG_TOP          30
#define DIALOG_TOPRANKED    31
#define DIALOG_TOPDUELOSG   32  /* Duelos ganados */
#define DIALOG_TOPDUELOSP   33  /* Duelos perdidos */
#define DIALOG_TOPCKILLS    34 	/* Clan kills */
#define DIALOG_TOPCWGANADAS 35
#define DIALOG_TOPCWPERD    36


new bool:FALSE = false;
#define ForPlayers(%0) for(new %0; %0 <= Conectados;%0++) if(IsPlayerConnected(%0))
#define SCMF(%0,%1,%2,%3) do{new _string[128]; format(_string,sizeof(_string),%2,%3); SendClientMessage(%0,%1,_string);} while(FALSE)
#define SCMTAF(%0,%1,%2) do{new _string[128]; format(_string,sizeof(_string),%1,%2); SendClientMessageToAll(%0,_string);} while(FALSE)

#pragma tabsize 0
#undef MAX_PLAYERS
#define MAX_PLAYERS 50

new Equipo[MAX_PLAYERS], nombreEquipo[3][50], totalJugadores[3], bool:equiposBloqueados;
new bool:modoDeJuego;
new maximoPuntaje, maximaRonda, rondaActual;

enum DataE{
	Rondas,
	Puntaje
};
new dataEquipo[2][DataE];

new killsJugador[MAX_PLAYERS];
new muertesJugador[MAX_PLAYERS];

new mapaElegido,
	Float:spawnMapas[4][3][4] =
	{
		{   /* Las venturas */
			{1136.34, 1206.73, 11.14},
			{1139.53, 1353.59, 10.83},
			{1173.81, 1360.58, 14.47}
		},{ /* Aeropuerto LV */
			{1617.4435, 1629.5537, 11.5618},
			{1497.5476, 1501.1267, 10.3481},
			{1599.2198, 1512.4071, 22.0793}
		},{ /* Aeropuerto SF */
			{-1313.0103, -55.3676, 13.4844},
			{-1186.4745, -182.016, 14.1484,44.5505},
			{-1227.1295, -76.7832, 29.0887}
		},{ /* Auto-escuela */
			{-2047.4285, -117.2283, 35.2487, 178.9484},
			{-2051.0955, -267.9533, 35.3203, 358.7801},
			{-2092.7380, -107.3132, 44.5237}
		}
	};

//{{843.9710,-2835.3689,12.79},{760.48,-2720.81,12.79},{733.13,-2775.95,25.3693}},	Jardín-mágico */

new DB:Cuentas, DB:Clanes, DB_Query[1000];
new FPS[MAX_PLAYERS], FPSS[MAX_PLAYERS];
new Conectados;

new bool:procesoClan, clanNuevoNombre[30], clanNuevoTag[6];
enum Data
{
	idDB,
 	Nombre[MAX_PLAYER_NAME],
    Password[24],
	ip[20],
	Admin,
	duelosGanados,
	duelosPerdidos,
	puntajeRanked,
	Clan,
    bool:Registrado
};
new infoJugador[MAX_PLAYERS][Data];

new Text:tituloServer, Text:nombreEquipos, Text:puntajeEquipos, Text:partidaRondas;
new PlayerText:mostrarFps[MAX_PLAYERS], PlayerText:mostrarPing[MAX_PLAYERS];
new PlayerText:mostrarKills[MAX_PLAYERS], PlayerText:mostrarMuertes[MAX_PLAYERS];

forward establecerVariables(playerid);
public establecerVariables(playerid)
{
	Equipo[playerid] = EQUIPO_ESPECTADOR;
	establecerColor(playerid);
}

main()
{
	print("\n");
	print("Gamemode: CW/TG\n");
	print("Desarrollador: Andrew_Manu\n");
}

public OnGameModeInit()
{
    mapaElegido = 2;
	maximaRonda = RONDA_POR_DEFECTO;
	maximoPuntaje = PUNTAJE_POR_DEFECTO;
	rondaActual = 1;
	modoDeJuego = false;
	resetearTodo();
    format(nombreEquipo[EQUIPO_NARANJA], 50, "%s", NOMBRE_EQUIPO_NARANJA);
    format(nombreEquipo[EQUIPO_VERDE], 50, "%s", NOMBRE_EQUIPO_VERDE);
	equiposBloqueados = false;
	procesoClan = false;

    Cuentas = db_open("jugadores/cuentas.db");
	Clanes = db_open("clanes/registro.db");
	new DBResult:asignacion;
    if(Cuentas){
        printf("Cuentas db abierto");
		asignacion = db_query(Cuentas, "CREATE TABLE IF NOT EXISTS cuentas (id INTEGER PRIMARY KEY AUTOINCREMENT, nick TEXT, password TEXT, ip INTEGER, nivelAdmin INTEGER, puntajeRanked INTEGER, duelosGanados INTEGER, duelosPerdidos INTEGER, clan INTEGER)");
		db_free_result(asignacion);
	}else print("Cuentas db no se pudo abrir");
	if(Clanes){
	    printf("Clanes db abierto");
	    asignacion = db_query(Clanes, "CREATE TABLE IF NOT EXISTS registro (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT, tag TEXT, propietario TEXT, kills INTEGER, cwGanadas INTEGER, cwPerdidas INTEGER, miembros INTEGER)");
        db_free_result(asignacion);
	}else printf("Clanes db no se pudo abrir");

	SetGameModeText("CW/TG (v0.2)");
 	SetWorldTime(15);
  	SetWeather(7);
	ShowPlayerMarkers(1);
	ShowNameTags(1);
	AllowAdminTeleport(1);
	
 	tituloServer = TextDrawCreate(100, 428, "Toxic Warriors Server CW/TG");
	TextDrawLetterSize(tituloServer, 0.200000, 1.000000);
	TextDrawTextSize(tituloServer, 428.000000, 0.000000);
	TextDrawAlignment(tituloServer, 1);
	TextDrawColor(tituloServer, -1);
	TextDrawSetShadow(tituloServer, 0);
	TextDrawSetOutline(tituloServer, 1);
	TextDrawBackgroundColor(tituloServer, 51);
	TextDrawFont(tituloServer, 1);
	TextDrawSetProportional(tituloServer, 1);
	
    nombreEquipos = TextDrawCreate(100, 428, "Naranja vs Verde");
	TextDrawLetterSize(nombreEquipos, 0.200000, 1.000000);
	TextDrawTextSize(nombreEquipos, 428.000000, 0.000000);
	TextDrawAlignment(nombreEquipos, 1);
	TextDrawColor(nombreEquipos, -1);
	TextDrawSetShadow(nombreEquipos, 0);
	TextDrawSetOutline(nombreEquipos, 1);
	TextDrawBackgroundColor(nombreEquipos, 51);
	TextDrawFont(nombreEquipos, 1);
	TextDrawSetProportional(nombreEquipos, 1);
 	TextDrawBackgroundColor(nombreEquipos, 0x000000AA);

	puntajeEquipos = TextDrawCreate(190, 428, "Puntos: (1) 5 - 14 (2)");
	TextDrawLetterSize(puntajeEquipos, 0.200000, 1.000000);
	TextDrawAlignment(puntajeEquipos, 1);
	TextDrawColor(puntajeEquipos, -1);
	TextDrawSetShadow(puntajeEquipos, 0);
	TextDrawSetOutline(puntajeEquipos, 1);
	TextDrawBackgroundColor(puntajeEquipos, 51);
	TextDrawFont(puntajeEquipos, 1);
	TextDrawSetProportional(puntajeEquipos, 1);
	TextDrawBackgroundColor(puntajeEquipos, 0x000000AA);

	partidaRondas = TextDrawCreate(270, 428, "Ronda: 2/3");
	TextDrawLetterSize(partidaRondas, 0.200000, 1.000000);
	TextDrawAlignment(partidaRondas, 1);
	TextDrawColor(partidaRondas, -1);
	TextDrawSetShadow(partidaRondas, 0);
	TextDrawSetOutline(partidaRondas, 1);
	TextDrawBackgroundColor(partidaRondas, 51);
	TextDrawFont(partidaRondas, 1);
	TextDrawSetProportional(partidaRondas, 1);
	TextDrawBackgroundColor(partidaRondas, 0x000000AA);

	AddPlayerClass(265,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);

	return 1;
}



mostrarTextPlayer(playerid){
	PlayerTextDrawShow(playerid, mostrarFps[playerid]);
	PlayerTextDrawShow(playerid, mostrarPing[playerid]);
}

actualizarTextGlobales(){
	new string[100];
    format(string, sizeof(string), "~y~%s vs ~g~%s", nombreEquipo[EQUIPO_NARANJA], nombreEquipo[EQUIPO_VERDE]);
    TextDrawSetString(nombreEquipos, string);
    format(string, sizeof(string), "P: ~y~(%d) %d ~w~- ~g~%d (%d)", dataEquipo[EQUIPO_NARANJA][Rondas], dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje], dataEquipo[EQUIPO_VERDE][Rondas]);
    TextDrawSetString(puntajeEquipos, string);
    format(string, sizeof(string), "R: ~b~%d~w~/~b~%d", rondaActual, maximaRonda);
    TextDrawSetString(partidaRondas, string);
	ForPlayers(i){
 		format(string, sizeof(string), "Kills: ~b~%d", killsJugador[i]);
    	PlayerTextDrawSetString(i, mostrarKills[i], string);
 		format(string, sizeof(string), "Muertes: ~b~%d", muertesJugador[i]);
    	PlayerTextDrawSetString(i, mostrarMuertes[i], string);
	}
   	ForPlayers(i){
		TextDrawHideForPlayer(i, partidaRondas);
		TextDrawHideForPlayer(i, puntajeEquipos);
		TextDrawHideForPlayer(i, nombreEquipos);
		TextDrawHideForPlayer(i, tituloServer);
		PlayerTextDrawHide(i, mostrarKills[i]);
		PlayerTextDrawHide(i, mostrarMuertes[i]);
		if(modoDeJuego){
			TextDrawShowForPlayer(i, partidaRondas);
			TextDrawShowForPlayer(i, puntajeEquipos);
			TextDrawShowForPlayer(i, nombreEquipos);
		    if(Equipo[i] != EQUIPO_ESPECTADOR){
   				PlayerTextDrawShow(i, mostrarKills[i]);
				PlayerTextDrawShow(i, mostrarMuertes[i]);
		    }
		}else{
		    TextDrawShowForPlayer(i, tituloServer);
		}
	}
}

resetearPuntos(){
	for(new i=0;i<2;i++) dataEquipo[i][Puntaje] = 0;
}

resetearRondas(){
	for(new i=0;i<2;i++) dataEquipo[i][Rondas] = 0;
}

resetearTodo(){
	for(new i=0;i<2;i++){
	    dataEquipo[i][Rondas] = 0;
	    dataEquipo[i][Puntaje] = 0;
	}
}

public OnGameModeExit(){
    db_close(Cuentas);
    return 1;
}

public OnPlayerConnect(playerid)
{
    if(playerid > Conectados) Conectados = playerid;
    
	establecerVariables(playerid);
    establecerJugadores();
    
	infoJugador[playerid][Nombre] = nombre(playerid);
	infoJugador[playerid][ip] = IP(playerid);

    new DBResult:resultado;
    format(DB_Query, sizeof(DB_Query), "SELECT * FROM cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
    resultado = db_query(Cuentas, DB_Query);
    printf("%d", db_num_rows(resultado));
    
	new Dialogo[240];
    if(db_num_rows(resultado)){
        db_get_field_assoc(resultado, "password", infoJugador[playerid][Password], 20);
        format(Dialogo, sizeof(Dialogo),"{7C7C7C}Escribi la {FFFFFF}contraseña {7C7C7C}para proceder.\n");
        ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, "{7C7C7C}Cuenta registrada", Dialogo, "Logear", "Salir");
	}else{
        format(Dialogo, sizeof(Dialogo),"{7C7C7C}Escribí una {FFFFFF}contraseña {7C7C7C}si queres registrar esta cuenta, sino cancela el registro.\n");
        ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, "{7C7C7C}Cuenta no registrada:", Dialogo, "Registrar", "Cancelar");
    }
    
   	mostrarFps[playerid] = CreatePlayerTextDraw(playerid, 500, 8, "Fps: 102");
	PlayerTextDrawLetterSize(playerid, mostrarFps[playerid], 0.200000, 1.000000);
	PlayerTextDrawAlignment(playerid, mostrarFps[playerid], 1);
	PlayerTextDrawColor(playerid, mostrarFps[playerid], -1);
	PlayerTextDrawSetShadow(playerid, mostrarFps[playerid], 0);
	PlayerTextDrawSetOutline(playerid, mostrarFps[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarFps[playerid], 51);
	PlayerTextDrawFont(playerid, mostrarFps[playerid], 1);
	PlayerTextDrawSetProportional(playerid, mostrarFps[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarFps[playerid], 0x000000AA);
	
	mostrarPing[playerid] = CreatePlayerTextDraw(playerid, 540, 8, "Ms: 194 (0.3%)");
	PlayerTextDrawLetterSize(playerid, mostrarPing[playerid], 0.200000, 1.000000);
	PlayerTextDrawAlignment(playerid, mostrarPing[playerid], 1);
	PlayerTextDrawColor(playerid, mostrarPing[playerid], -1);
	PlayerTextDrawSetShadow(playerid, mostrarPing[playerid], 0);
	PlayerTextDrawSetOutline(playerid, mostrarPing[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarPing[playerid], 51);
	PlayerTextDrawFont(playerid, mostrarPing[playerid], 1);
	PlayerTextDrawSetProportional(playerid, mostrarPing[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarPing[playerid], 0x000000AA);
	
	mostrarKills[playerid] = CreatePlayerTextDraw(playerid, 341.666748, 428.088806, "Kills: 14");
	PlayerTextDrawLetterSize(playerid, mostrarKills[playerid], 0.200000, 1.000000);
	PlayerTextDrawAlignment(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawColor(playerid, mostrarKills[playerid], -1);
	PlayerTextDrawSetShadow(playerid, mostrarKills[playerid], 0);
	PlayerTextDrawSetOutline(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarKills[playerid], 51);
	PlayerTextDrawFont(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawSetProportional(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarKills[playerid], 0x000000AA);
	
	mostrarMuertes[playerid] = CreatePlayerTextDraw(playerid, 380.333282, 427.259277, "Muertes: 10");
	PlayerTextDrawLetterSize(playerid, mostrarMuertes[playerid], 0.200000, 1.000000);
	PlayerTextDrawAlignment(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawColor(playerid, mostrarMuertes[playerid], -1);
	PlayerTextDrawSetShadow(playerid, mostrarMuertes[playerid], 0);
	PlayerTextDrawSetOutline(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarMuertes[playerid], 51);
	PlayerTextDrawFont(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawSetProportional(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarMuertes[playerid], 0x000000AA);

	//GameTextForPlayer(playerid,"~w~SA-MP: ~r~Bare Script",5000,5);
	return 1;
}

public OnPlayerDisconnect(playerid, reason){
    new Mensaje[124], razonesDesconexion[3][] = {"Crash/Timeout", "Salió", "Kick/Ban"};
    format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"se ha desconectado ({7C7C7C}%s"GRISEADO").", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], razonesDesconexion[reason]);
	SendClientMessageToAll(GetPlayerColor(playerid), Mensaje);
	guardarDatos(playerid);
	if(playerid == Conectados){
		warp:
		Conectados--;
		if(!IsPlayerConnected(Conectados) && Conectados > 0) goto warp;
	}
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_REGISTRO:
        {
        	if(!response){
				SendClientMessage(playerid, COLOR_ROJO, "Has cancelado el registro, ten en cuenta que no se te guardaran los stats.");
				return infoJugador[playerid][Registrado] = false;
			}
            if(strlen(inputtext) < 4 || strlen(inputtext) > 20){
                SendClientMessage(playerid, COLOR_ROJO, "La contraseña debe tener de 4 a 20 letras.");
                new Dialogo[240];
        		format(Dialogo, sizeof(Dialogo),"{7C7C7C}La contraseña que introduciste es errónea\nIntentalo devuelta ingresando otra contraseña..\n");
        		ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, ""ROJO"Error de registro", Dialogo, "Registrar", "Cancelar");
			}else{
                format(infoJugador[playerid][Password], 24, inputtext);
                registrarDatos(playerid);
                SendClientMessage(playerid, COLOR_VERDE, "Te has registrado correctamente.");
                mostrarTextPlayer(playerid);
            }
        }
   		case DIALOG_LOGEAR:
        {
            if(!response) return Kick(playerid);
            if(isnull(inputtext) || !strcmp(inputtext, "0")) return ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, ""ROJO"Error de conexión", "{7C7C7C}La {FFFFFF}contraseña {7C7C7C}que introduciste es "ROJO"errónea{7C7C7C}, intentalo devuelta.\n", "Logear", "Salir");
            if(!strcmp(infoJugador[playerid][Password], inputtext, true, 20)){
				infoJugador[playerid][Registrado] = true;
				cargarDatos(playerid);
				mostrarTextPlayer(playerid);
			}else ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, ""ROJO"Error de conexión", "{7C7C7C}La {FFFFFF}contraseña {7C7C7C}que introduciste es "ROJO"errónea{7C7C7C}, intentalo devuelta.\n", "Logear", "Salir");
        }
        case DIALOG_SEQUIPO:
        {
        	if(response){
        	    establecerJugadores();
        		switch(listitem){
        		    case 0:
					{
						if(Equipo[playerid] == EQUIPO_NARANJA) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"se integró al equipo {F69521}%s", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_NARANJA]);
                		Equipo[playerid] = EQUIPO_NARANJA;
					}
					case 1:
					{
						if(Equipo[playerid] == EQUIPO_VERDE) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"se integró al equipo {77CC77}%s", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_VERDE]);
                		Equipo[playerid] = EQUIPO_VERDE;
					}
					case 2:
					{
						if(Equipo[playerid] == EQUIPO_ESPECTADOR) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"se integró al equipo {FFFFFF}Espectador", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre]);
                		Equipo[playerid] = EQUIPO_ESPECTADOR;
					}
				}
				establecerJugadores();
        		establecerColor(playerid);
        		actualizarTextGlobales();
        		SpawnPlayer(playerid);
			}else{
			
			}
        }
        case DIALOG_IFCLAN:
        {
        	if(!response) return SendClientMessage(playerid, COLOR_ROJO, "Has cancelado el registro de clan.");
        	else{
	        	new string[1000];
				strcat(string,"{FFFFFF}Ingresa el nombre completo del clan que querés registrar, no ingreses el tag.\n");
				strcat(string,"{7C7C7C}- No sobrepases el limite de carácteres (30)\n");
				strcat(string,"- Evita poner cosas raras, ¿sí?\n");
				procesoClan = true;
				ShowPlayerDialog(playerid, DIALOG_INCLAN, DIALOG_STYLE_INPUT, "Nombre del clan", string, "Siguiente", "Cancelar");
        	}
        }
		case DIALOG_INCLAN:
		{
			if(!response){
                procesoClan = false;
                return SendClientMessage(playerid, COLOR_ROJO, "Has cancelado el registro de clan.");
			}
			if(isnull(inputtext) || !strcmp(inputtext, "0")) return ShowPlayerDialog(playerid, DIALOG_INCLAN, DIALOG_STYLE_INPUT, ""ROJO"Error", "{FFFFFF}Te dije que no pongas boludeces, ingresa un nombre válido.", "Siguiente", "Cancelar");
            if(strlen(inputtext) < 4 || strlen(inputtext) > 30) return ShowPlayerDialog(playerid, DIALOG_INCLAN, DIALOG_STYLE_INPUT, ""ROJO"Error", "{FFFFFF}Te dije que no pongas boludeces, ingresa un nombre válido.", "Siguiente", "Cancelar");
			if(clanTextoValido("nombre", inputtext)){
  				strcat(clanNuevoNombre, "");
				return ShowPlayerDialog(playerid, DIALOG_INCLAN, DIALOG_STYLE_INPUT, ""ROJO"Error", "{FFFFFF}Este nombre ya existe, ingresa otro.", "Siguiente", "Cancelar");
			}else{
				strcat(clanNuevoNombre, inputtext);
  				new string[1000];
				strcat(string,"{FFFFFF}Ingresa el TAG completo del clan que querés registrar\n");
  				strcat(string,"{7C7C7C} No sobrepases el limite de carácteres (6)\n");
				strcat(string,"- No ingreses los corchetes [ ]\n");
            	ShowPlayerDialog(playerid, DIALOG_TGCLAN, DIALOG_STYLE_INPUT, "Tag del clan", string, "Crear", "Cancelar");
			}
		}
		case DIALOG_TGCLAN:
		{
			if(!response){
			    strcat(clanNuevoNombre, "");
			    strcat(clanNuevoTag, "");
			    procesoClan = false;
                return SendClientMessage(playerid, COLOR_ROJO, "Has cancelado el registro de clan.");
			}
			if(isnull(inputtext) || !strcmp(inputtext, "0")) return ShowPlayerDialog(playerid, DIALOG_TGCLAN, DIALOG_STYLE_INPUT, ""ROJO"Error", "{FFFFFF}Te dije que no pongas boludeces, ingresa un TAG válido.", "Crear", "Cancelar");
            if(strlen(inputtext) < 2 || strlen(inputtext) > 6) return ShowPlayerDialog(playerid, DIALOG_TGCLAN, DIALOG_STYLE_INPUT, ""ROJO"Error", "{FFFFFF}Te dije que no pongas boludeces, ingresa un TAG válido.", "Crear", "Cancelar");
			if(strfind(inputtext, "[", true) != -1 || strfind(inputtext, "]", true) != -1) return ShowPlayerDialog(playerid, DIALOG_TGCLAN, DIALOG_STYLE_INPUT, ""ROJO"Error", "{FFFFFF}Te dije que no pongas boludeces, ingresa un TAG válido.", "Crear", "Cancelar");
            if(clanTextoValido("tag", inputtext)){
   				strcat(clanNuevoTag, "");
				return ShowPlayerDialog(playerid, DIALOG_TGCLAN, DIALOG_STYLE_INPUT, ""ROJO"Error", "{FFFFFF}Este TAG ya esta ocupado, ingresa otro.", "Crear", "Cancelar");
			}else{
                strcat(clanNuevoTag, inputtext);
				registrarClan(playerid);
			}
		}
		case DIALOG_TOP:
		{
 			if(response){
        		switch(listitem){
        		    case 0:
						mostrarTopRanked(playerid);
					case 1:
					    mostrarTopDuelosGanados(playerid);
					case 2:
						mostrarTopDuelosPerdidos(playerid);
					case 3:
					    mostrarTopClanKills(playerid);
					case 4:
					    mostrarTopClanCWG(playerid);
					case 5:
					    mostrarTopClanCWP(playerid);
					
				}
			}else{
			}
		}
		case DIALOG_TOPRANKED: 		if(response) mostrarTop(playerid);
		case DIALOG_TOPDUELOSG: 	if(response) mostrarTop(playerid);
		case DIALOG_TOPDUELOSP: 	if(response) mostrarTop(playerid);
		case DIALOG_TOPCKILLS: 		if(response) mostrarTop(playerid);
		case DIALOG_TOPCWGANADAS: 	if(response) mostrarTop(playerid);
		case DIALOG_TOPCWPERD: 		if(response) mostrarTop(playerid);
	}
    return 1;
}
//, kills, cwGanadas, cwPerdidas, miembros
registrarClan(playerid)
{
	new str[80];
    format(DB_Query, sizeof(DB_Query), "INSERT INTO registro (nombre, tag, propietario, kills, cwGanadas, cwPerdidas, miembros) VALUES ");
    format(str, sizeof(str), "('%s',", clanNuevoNombre);				strcat(DB_Query, str);
    format(str, sizeof(str), "'%s',", clanNuevoTag);     				strcat(DB_Query, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][Nombre]);   strcat(DB_Query, str);
    format(str, sizeof(str), "0,");     								strcat(DB_Query, str);
    format(str, sizeof(str), "0,");     								strcat(DB_Query, str);
    format(str, sizeof(str), "0,");     								strcat(DB_Query, str);
    format(str, sizeof(str), "1)");     								strcat(DB_Query, str);
    db_query(Clanes, DB_Query);
    procesoClan = false;
    SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"ha registrado el clan {FFFFFF}%s", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], clanNuevoNombre);
    printf("Nuevo clan %s, [%s] por %s", clanNuevoNombre, clanNuevoTag, infoJugador[playerid][Nombre]);

    new DBResult:resultado, nuevaConsulta[1000], idClan;
    format(nuevaConsulta, sizeof(nuevaConsulta), "SELECT * FROM registro WHERE nombre = '%s'", clanNuevoNombre);
    resultado = db_query(Clanes, nuevaConsulta);
    printf("Registro clan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado))
		idClan = db_get_field_assoc_int(resultado, "id");
    db_free_result(resultado);
    
    format(nuevaConsulta, sizeof(nuevaConsulta), "UPDATE Cuentas SET clan = %d WHERE id = %d", idClan, infoJugador[playerid][idDB]);
	db_query(Cuentas, nuevaConsulta);

	return 1;
}

mostrarTop(playerid){
    return ShowPlayerDialog(playerid, DIALOG_TOP, DIALOG_STYLE_LIST, "{7C7C7C}Tops", "{00779E}Ranked\n{00779E}Duelos ganados\n{00779E}Duelos perdidos\n{00779E}Clan kills\n{00779E}Clan Wars ganadas\n{00779E}Clan Wars perdidas", "Selec.", "Cancelar");
}
mostrarTopRanked(playerid){
	new i = 1, selece[1000], string[100];
	db_query(Cuentas, "UPDATE cuentas SET puntajeRanked = 900 WHERE id = 2");
	new DBResult:resultado, Puntos, nNick[40];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY puntajeRanked DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Puntos");
	do{
		Puntos = db_get_field_assoc_int(resultado, "puntajeRanked");
		db_get_field_assoc(resultado, "nick", nNick, 24);
		format(string, sizeof(string), "\n{7C7C7C}%d\t{FFFFFF}%s\t"GRISEADO"%d", i, nNick, Puntos);
		strcat(selece, string);
		printf("%d %s %d", i, nNick, Puntos);
		i++;
	}while(db_next_row(resultado));
	db_free_result(resultado);
	ShowPlayerDialog(playerid, DIALOG_TOPRANKED, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}Ranked", selece, "Volver", "Cerrar");
}

mostrarTopDuelosGanados(playerid){
	new i = 1, selece[1000], string[100];
	db_query(Cuentas, "UPDATE cuentas SET duelosGanados = 44 WHERE id = 3");
	new DBResult:resultado, Duelos, nNick[24];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY duelosGanados DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Duelos");
	do{
		Duelos = db_get_field_assoc_int(resultado, "duelosGanados");
		db_get_field_assoc(resultado, "nick", nNick, 24);
		format(string, sizeof(string), "\n{7C7C7C}%d\t{FFFFFF}%s\t"GRISEADO"%d", i, nNick, Duelos);
		strcat(selece, string);
		printf("%d %s %d", i, nNick, Duelos);
		i++;
	}while(db_next_row(resultado));
	db_free_result(resultado);
	ShowPlayerDialog(playerid, DIALOG_TOPDUELOSG, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}Duelos ganados", selece, "Volver", "Cerrar");
}

mostrarTopDuelosPerdidos(playerid){
	new i = 1, selece[1000], string[100];
	db_query(Cuentas, "UPDATE cuentas SET duelosGanados = 44 WHERE id = 3");
	new DBResult:resultado, Duelos, nNick[24];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY duelosPerdidos DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Duelos");
	do{
		Duelos = db_get_field_assoc_int(resultado, "duelosPerdidos");
		db_get_field_assoc(resultado, "nick", nNick, 24);
		format(string, sizeof(string), "\n{7C7C7C}%d\t{FFFFFF}%s\t"GRISEADO"%d", i, nNick, Duelos);
		strcat(selece, string);
		printf("%d %s %d", i, nNick, Duelos);
		i++;
	}while(db_next_row(resultado));
	db_free_result(resultado);
	ShowPlayerDialog(playerid, DIALOG_TOPDUELOSP, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}Duelos perdidos", selece, "Volver", "Cerrar");
}

mostrarTopClanKills(playerid){
	new i = 1, selece[1000], string[100];
	db_query(Clanes, "UPDATE registro SET kills = 100 WHERE id = 2");
	new DBResult:resultado, killsTotales, TAG[6];
    resultado = db_query(Clanes, "SELECT * FROM registro ORDER BY kills DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Clan\t{7C7C7C}Kills");
	do{
		killsTotales = db_get_field_assoc_int(resultado, "kills");
		db_get_field_assoc(resultado, "tag", TAG, 6);
		format(string, sizeof(string), "\n{7C7C7C}%d\t{FFFFFF}%s\t"GRISEADO"%d", i, TAG, killsTotales);
		strcat(selece, string);
		printf("%d %s %d", i, TAG, killsTotales);
		i++;
	}while(db_next_row(resultado));
	db_free_result(resultado);
	ShowPlayerDialog(playerid, DIALOG_TOPCKILLS, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}Clan kills", selece, "Volver", "Cerrar");
}

mostrarTopClanCWG(playerid){
	new i = 1, selece[1000], string[100];
	db_query(Clanes, "UPDATE registro SET cwGanadas = 2 WHERE id = 2");
	new DBResult:resultado, clanWars, TAG[6];
    resultado = db_query(Clanes, "SELECT * FROM registro ORDER BY cwGanadas DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Clan\t{7C7C7C}Cantidad");
	do{
		clanWars = db_get_field_assoc_int(resultado, "cwGanadas");
		db_get_field_assoc(resultado, "tag", TAG, 6);
		format(string, sizeof(string), "\n{7C7C7C}%d\t{FFFFFF}%s\t"GRISEADO"%d", i, TAG, clanWars);
		strcat(selece, string);
		printf("%d %s %d", i, TAG, clanWars);
		i++;
	}while(db_next_row(resultado));
	db_free_result(resultado);
	ShowPlayerDialog(playerid, DIALOG_TOPCWGANADAS, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}CW's ganadas", selece, "Volver", "Cerrar");
}

mostrarTopClanCWP(playerid){
	new i = 1, selece[1000], string[100];
	db_query(Clanes, "UPDATE registro SET cwPerdidas = 2 WHERE id = 2");
	new DBResult:resultado, clanWars, TAG[6];
    resultado = db_query(Clanes, "SELECT * FROM registro ORDER BY cwPerdidas DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Clan\t{7C7C7C}Cantidad");
	do{
		clanWars = db_get_field_assoc_int(resultado, "cwPerdidas");
		db_get_field_assoc(resultado, "tag", TAG, 6);
		format(string, sizeof(string), "\n{7C7C7C}%d\t{FFFFFF}%s\t"GRISEADO"%d", i, TAG, clanWars);
		strcat(selece, string);
		printf("%d %s %d", i, TAG, clanWars);
		i++;
	}while(db_next_row(resultado));
	db_free_result(resultado);
	ShowPlayerDialog(playerid, DIALOG_TOPCWPERD, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}CW's perdidas", selece, "Volver", "Cerrar");
}

/*
maxClan(){
	new DBResult:resultado, maxClanes;
    format(DB_Query, sizeof(DB_Query), "SELECT COUNT(id) as 'max' FROM registro");
    resultado = db_query(Clanes, DB_Query);
    printf("sacar maximoclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado))
		maxClanes = db_get_field_assoc_int(resultado, "max");
  	return maxClanes;
}
*/
tagClan(playerid){
	new DBResult:resultado, TAG[10], idClan;
    format(DB_Query, sizeof(DB_Query), "SELECT * FROM Cuentas WHERE id = %d", infoJugador[playerid][idDB]);
    resultado = db_query(Cuentas, DB_Query);
    printf("Sacar tag idclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado)){
        idClan = db_get_field_assoc_int(resultado, "clan");
        printf("el clan es %d", idClan);
        db_free_result(resultado);
		if(idClan > 0){
        	format(DB_Query, sizeof(DB_Query), "SELECT * FROM registro WHERE id = %d", idClan);
        	resultado = db_query(Clanes, DB_Query);
			db_get_field_assoc(resultado, "tag", TAG, 10);
  			db_free_result(resultado);
		}else
			strcat(TAG, "No tiene");
	}
	return TAG;
}
/*
propietarioClan(playerid){
	new DBResult:resultado;
    format(DB_Query, sizeof(DB_Query), "SELECT * FROM registro WHERE propietario = '%s'", infoJugador[playerid][Nombre]);
    resultado = db_query(Cuentas, DB_Query);
    printf("propietarioclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado)){
		db_free_result(resultado);
		return 1;
    }else{
		db_free_result(resultado);
		return 0;
    }
}
*/
tieneClan(playerid)
{
	new DBResult:resultado, idClan;
    format(DB_Query, sizeof(DB_Query), "SELECT * FROM Cuentas WHERE id = %d", infoJugador[playerid][idDB]);
    resultado = db_query(Cuentas, DB_Query);
    printf("Tieneclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado))
		idClan = db_get_field_assoc_int(resultado, "clan");
	db_free_result(resultado);
	if(idClan > 0)
		return 1;
	else
		return 0;
}

sacarClanId(playerid)
{
	new DBResult:resultado, idClan;
    format(DB_Query, sizeof(DB_Query), "SELECT * FROM Cuentas WHERE id = %d", infoJugador[playerid][idDB]);
    resultado = db_query(Cuentas, DB_Query);
    printf("Tieneclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado))
		idClan = db_get_field_assoc_int(resultado, "clan");
	db_free_result(resultado);
	return idClan;
}

clanTextoValido(celda[], nombre[]){
    new DBResult:resultado;
    format(DB_Query, sizeof(DB_Query), "SELECT * FROM registro WHERE %s = '%s'", celda, nombre);
    resultado = db_query(Clanes, DB_Query);
    printf("%d", db_num_rows(resultado));
	return db_num_rows(resultado);
}
registrarDatos(playerid)
{
    new str[80];
    format(DB_Query, sizeof(DB_Query), "INSERT INTO cuentas (nick, password, ip, nivelAdmin, puntajeRanked, duelosGanados, duelosPerdidos, clan) VALUES ");
    format(str, sizeof(str), "('%s',", infoJugador[playerid][Nombre]);		strcat(DB_Query, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][Password]);     strcat(DB_Query, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][ip]);     		strcat(DB_Query, str);
    format(str, sizeof(str), "0,");     									strcat(DB_Query, str);
    format(str, sizeof(str), "500,");     									strcat(DB_Query, str);
    format(str, sizeof(str), "0,");     									strcat(DB_Query, str);
    format(str, sizeof(str), "0,");     									strcat(DB_Query, str);
    format(str, sizeof(str), "0)");     									strcat(DB_Query, str);
    db_query(Cuentas, DB_Query);

    new DBResult:resultado;
    format(DB_Query, sizeof(DB_Query), "SELECT id FROM Cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
    resultado = db_query(Cuentas, DB_Query);
    if(db_num_rows(resultado)) infoJugador[playerid][idDB] = db_get_field_assoc_int(resultado, "id");
    db_free_result(resultado);

    infoJugador[playerid][Admin] 			= 0;
    infoJugador[playerid][duelosGanados] 	= 0;
    infoJugador[playerid][duelosPerdidos] 	= 0;
    infoJugador[playerid][puntajeRanked] 	= 500;
    infoJugador[playerid][Clan] 			= 0;
    infoJugador[playerid][Registrado] 		= true;
    guardarDatos(playerid);
    return 1;
}

cargarDatos(playerid)
{
	if(infoJugador[playerid][Registrado] == true){
    	new DBResult:resultado;
    	format(DB_Query, sizeof(DB_Query), "SELECT * FROM Cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
    	resultado = db_query(Cuentas, DB_Query);
    	if(db_num_rows(resultado)){
        	infoJugador[playerid][idDB] 			= db_get_field_assoc_int(resultado, "id");
        	infoJugador[playerid][Admin] 			= db_get_field_assoc_int(resultado, "nivelAdmin");
        	infoJugador[playerid][duelosGanados] 	= db_get_field_assoc_int(resultado, "duelosGanados");
        	infoJugador[playerid][duelosPerdidos] 	= db_get_field_assoc_int(resultado, "duelosPerdidos");
        	infoJugador[playerid][puntajeRanked] 	= db_get_field_assoc_int(resultado, "puntajeRanked");
        	infoJugador[playerid][Clan] 			= db_get_field_assoc_int(resultado, "clan");
   	 	}
    	db_free_result(resultado);
    	infoJugador[playerid][Registrado] = true;
		SendClientMessage(playerid, COLOR_VERDE, "Has logeado correctamente (stats cargados)");
		guardarDatos(playerid);
	}
	return 1;
}

guardarDatos(playerid)
{
    if(infoJugador[playerid][Registrado] == false)
		return printf("El jugador no esta registrado");
    new str[100], nuevaConsulta[1000];
    strcat(nuevaConsulta, "UPDATE Cuentas SET ");
    format(str, sizeof(str), "nick = '%s', password = '%s', ip = '%s', nivelAdmin = '%d' WHERE id = %d", infoJugador[playerid][Nombre], infoJugador[playerid][Password], infoJugador[playerid][ip], infoJugador[playerid][Admin], infoJugador[playerid][idDB]);
 	strcat(nuevaConsulta, str);
	db_query(Cuentas, nuevaConsulta);
    strcat(nuevaConsulta, "UPDATE Cuentas SET ");
    format(str, sizeof(str), "duelosGanados = '%d', duelosPerdidos = '%d', puntajeRanked = '%d', clan = '&d' WHERE id = %d", infoJugador[playerid][duelosGanados],infoJugador[playerid][duelosPerdidos], infoJugador[playerid][puntajeRanked], infoJugador[playerid][Clan], infoJugador[playerid][idDB]);
    strcat(nuevaConsulta, str);
    db_query(Cuentas, nuevaConsulta);
	printf("Datos guardados id: %d", infoJugador[playerid][idDB]);
    return 1;
}

stock colorEquipo(id){
	new s[6];
	if(id == EQUIPO_NARANJA)
		format(s, 6, "F69521");
	else
	    format(s, 6, "77CC77");
	return s;
}

verificarGanador(){
	new ganador;
	if(dataEquipo[Equipo[EQUIPO_NARANJA]][Rondas] > dataEquipo[Equipo[EQUIPO_VERDE]][Rondas]) ganador = EQUIPO_NARANJA;
	else ganador = EQUIPO_NARANJA;
	return ganador;
}
resetearJugadoresEnPartida(){
	ForPlayers(i){
	    if(Equipo[i] != EQUIPO_ESPECTADOR){
     		killsJugador[i] = 0;
        	muertesJugador[i] = 0;
        	SpawnPlayer(i);
	    }
	}
}
verificarRonda(playerid){
	new i = Equipo[playerid];
	if(dataEquipo[Equipo[i]][Puntaje] == maximoPuntaje){
		dataEquipo[Equipo[i]][Rondas]++;
		resetearPuntos();
		if(rondaActual < maximaRonda){
  			if(totalJugadores[EQUIPO_NARANJA] == 1 && totalJugadores[EQUIPO_VERDE] == 1){
  				new playerid2;
				if(Equipo[playerid] == EQUIPO_NARANJA)
					playerid2 = jugadorVerde();
				else
					playerid2 = jugadorNaranja();
                SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha ganado la %d ronda contra {%06x}%s", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], rondaActual, GetPlayerColor(playerid2) >>> 8, infoJugador[playerid2][Nombre]);
        	}else
      			SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha ganado la %d ronda.", GetPlayerColor(playerid) >>> 8, nombreEquipo[i], rondaActual);
	    	rondaActual++;
  			SCMTAF(COLOR_BLANCO, "La partida va %d:%d, empieza la %d ronda.", dataEquipo[Equipo[EQUIPO_NARANJA]][Rondas], dataEquipo[Equipo[EQUIPO_VERDE]][Rondas], rondaActual);
  			resetearJugadoresEnPartida();
		}else if(rondaActual == maximaRonda){
            SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha ganado la ultima ronda.", GetPlayerColor(playerid) >>> 8);
			verificarGanador();
		}
	}
	actualizarTextGlobales();
}

jugadorVerde(){
	new id;
	ForPlayers(i){
		if(Equipo[i] == EQUIPO_VERDE)
  			id = i;
	}
	return id;
}
jugadorNaranja(){
	new id;
	ForPlayers(i){
		if(Equipo[i] == EQUIPO_NARANJA)
  			id = i;
	}
	return id;
}
actualizarEquipo(playerid, killerid){
    if(Equipo[playerid] == Equipo[killerid]){
        SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha hecho teamkill.", GetPlayerColor(playerid) >>> 8);
        new equipoOpuesto;
        if(Equipo[playerid] == EQUIPO_NARANJA) equipoOpuesto = EQUIPO_VERDE;
        else equipoOpuesto = EQUIPO_NARANJA;
        dataEquipo[Equipo[equipoOpuesto]][Puntaje]++;
    }else{
        dataEquipo[Equipo[killerid]][Puntaje]++;
    }
    verificarRonda(killerid);
    actualizarTextGlobales();
    return 1;
}

forward establecerColor(playerid);
public establecerColor(playerid){
	if(Equipo[playerid] == EQUIPO_ESPECTADOR)
		SetPlayerColor(playerid, COLOR_BLANCO);
	if(Equipo[playerid] == EQUIPO_NARANJA)
		SetPlayerColor(playerid, COLOR_NARANJA);
	if(Equipo[playerid] == EQUIPO_VERDE)
		SetPlayerColor(playerid, COLOR_VERDE);
}

stock establecerJugadores(){
    totalJugadores[EQUIPO_NARANJA] 		= 0;
    totalJugadores[EQUIPO_VERDE]		= 0;
    totalJugadores[EQUIPO_ESPECTADOR] 	= 0;
	ForPlayers(i){
	    if(Equipo[i] == EQUIPO_NARANJA)
			totalJugadores[EQUIPO_NARANJA]++;
	    if(Equipo[i] == EQUIPO_VERDE)
	        totalJugadores[EQUIPO_VERDE]++;
	    if(Equipo[i] == EQUIPO_ESPECTADOR)
	        totalJugadores[EQUIPO_ESPECTADOR]++;
	}
}

stock nombreModo(){
	new s[25];
	if(modoDeJuego)
		format(s, 25, "CW");
	else
		format(s,25, "TG");
	return s;
}

public OnPlayerUpdate(playerid){
	new FPSSS = GetPlayerDrunkLevel(playerid), fps;
	if(FPSSS < 100){
		SetPlayerDrunkLevel(playerid, 2000);
	}else{
		if(FPSSS != FPSS[playerid]){
			fps = FPSS[playerid] - FPSSS;
			if(fps > 0 && fps < 200) FPS[playerid] = fps;
			FPSS[playerid] = FPSSS;
		}
	}
	new string[60], string2[60];
	format(string, sizeof(string), "~w~Fps: ~g~%d", FPS[playerid]);
	PlayerTextDrawSetString(playerid, mostrarFps[playerid], string);
	format(string2, sizeof(string2), "~w~Ms: ~g~%d ~w~(~g~%.1f",  GetPlayerPing(playerid), NetStats_PacketLossPercent(playerid));
	strcat(string2, "%~w~)");
	PlayerTextDrawSetString(playerid, mostrarPing[playerid], string2);
	return 1;
}

public OnPlayerText(playerid, text[]){
    new Mensaje[128]; 
	format(Mensaje, sizeof(Mensaje), "{B8B8B8}[%i] {%06x}%s {C3C3C3}[%d]{FFFFFF}: %s", infoJugador[playerid][puntajeRanked], GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], playerid, text);
	SendClientMessageToAll(GetPlayerColor(playerid), Mensaje);
	SetPlayerChatBubble(playerid, text, COLOR_BLANCO, 50, 5000);
    return 0;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(!success)
	{
    	PlayerPlaySound(playerid,1054,0.0,0.0,0.0);
    	SendClientMessage(playerid, COLOR_ROJO, "El comando que escribiste no existe!");
	}
	return 1;
}


public OnPlayerSpawn(playerid)
{
	GivePlayerWeapon(playerid, 22, 9999);
	GivePlayerWeapon(playerid, 28, 9999);
	GivePlayerWeapon(playerid, 26, 9999);
	
    SetPlayerHealth(playerid,100);
    SetPlayerPos(playerid, spawnMapas[mapaElegido][Equipo[playerid]][0], spawnMapas[mapaElegido][Equipo[playerid]][1], spawnMapas[mapaElegido][Equipo[playerid]][2]);
	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason){
	if(killerid == INVALID_PLAYER_ID)
		return SpawnPlayer(playerid);
    if(Equipo[playerid] == EQUIPO_ESPECTADOR || Equipo[killerid] == EQUIPO_ESPECTADOR)
		return SpawnPlayer(playerid);
		
    SpawnPlayer(playerid);
    SendDeathMessage(killerid, playerid, reason);
   	killsJugador[killerid]++;
	muertesJugador[playerid]++;
	
	if(modoDeJuego)
	    actualizarEquipo(playerid, killerid);
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


CMD:cmds(playerid, params[]){
	new selece[600], string[100], Nivel = infoJugador[playerid][Admin];
	strcat(selece, "{00779E}Jugadores\n{{FFFFFF}Espectadores");
	switch(Nivel){
	    case 1:
	    {
	        format(string, sizeof(string), "\n{F78411}Administrador 1\t{7C7C7C}%d");	strcat(selece, string);
	    }
	    case 2:
	    {
	        format(string, sizeof(string), "\n{F78411}Administrador 1\t{7C7C7C}%d");	strcat(selece, string);
	        format(string, sizeof(string), "\n{F78411}Administrador 2\t{7C7C7C}%d");	strcat(selece, string);
		}
		case 3:
		{
		    format(string, sizeof(string), "\n{F78411}Administrador 1\t{7C7C7C}%d");	strcat(selece, string);
		    format(string, sizeof(string), "\n{F78411}Administrador 2\t{7C7C7C}%d");	strcat(selece, string);
		    format(string, sizeof(string), "\n{F78411}Administrador 3\t{7C7C7C}%d");	strcat(selece, string);
		}
	}
	//if(Admin[playerid] == 1) ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, "Comandos del sevidor", "Jugadores\nEspectador\nAdministrador nivel 1", "Selec", "Cancelar");
	ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, ""GRISEADO"Comandos del sevidor", selece, "Selec.", "Cancelar");
	return 1;
}
CMD:setadmin(playerid, params[]){
	new Nivel, i;
	if(sscanf(params, "ii", i, Nivel))
		return SendClientMessage(playerid, COLOR_ROJO,"Escribiste mal el comando; {FFFFFF}/setadmin ID Nivel");
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
 	if(Nivel > 3 || Nivel < 0)
		return SendClientMessage(playerid, COLOR_ROJO,"Solo hay 3 niveles.");

    infoJugador[i][Admin] = Nivel;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" le dio a {%06x}%s "GRISEADO"administrador nivel {FFFFFF}%d", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], GetPlayerColor(i) >>> 8, infoJugador[i][Nombre], Nivel);
	guardarDatos(i);
	return 1;
}
CMD:equipo(playerid, params[]){
	if(equiposBloqueados) return SendClientMessage(playerid, COLOR_ROJO, "Los equipos están bloqueados.");
	new selece[600], string[100];
 	strcat(selece, "{7C7C7C}Nombre\t{7C7C7C}Jugadores");
	format(string, sizeof(string), "\n{F78411}%s\t{7C7C7C}%d", nombreEquipo[EQUIPO_NARANJA], totalJugadores[EQUIPO_NARANJA]);	strcat(selece, string);
	format(string, sizeof(string), "\n{77CC77}%s\t{7C7C7C}%d", nombreEquipo[EQUIPO_VERDE], totalJugadores[EQUIPO_VERDE]); 		strcat(selece, string);
	format(string, sizeof(string), "\n{FFFFFF}Espectador\t{7C7C7C}%d", totalJugadores[EQUIPO_ESPECTADOR]);						strcat(selece, string);
    ShowPlayerDialog(playerid, DIALOG_SEQUIPO, DIALOG_STYLE_TABLIST_HEADERS, "Selección de equipos", selece, "Selec.", "Cerrar");
	return 1;
}


CMD:stats(playerid, params[]){
    new i, stats[256];
    if(isnull(params)) i = playerid;
    else i = strval(params);
	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	    
    format(stats, sizeof(stats), "{7C7C7C}Nick: {%06x}%s", GetPlayerColor(playerid) >>> 8, infoJugador[i][Nombre]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Clan: {FFFFFF}%s", stats, tagClan(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Ping: {FFFFFF}%d", stats, GetPlayerPing(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}PacketLoss: {FFFFFF}%.2f", stats, NetStats_PacketLossPercent(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Skin: {FFFFFF}%d", stats, GetPlayerSkin(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Admin: {FFFFFF}%d", stats, infoJugador[i][Admin]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Ranked: {FFFFFF}%d", stats, infoJugador[i][puntajeRanked]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Duelos ganados: {FFFFFF}%d", stats, infoJugador[i][duelosGanados]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Duelos perdidos: {FFFFFF}%d", stats, infoJugador[i][duelosPerdidos]);
    
    ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, "Estadistica:", stats, "Cerrar", "");
    return 1;
}

CMD:creditos(playerid, params[]){
    new string[1200];
	strcat(string,"{FFFFFF}> {7C7C7C}Desarrollador de la GM{B8B8B8}: \n");
	strcat(string,"{FFFFFF}- [WTx]Andrew_Manu\n");
	strcat(string,"\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Ubicación del hosting: \n");
	strcat(string,"{FFFFFF}- Miami, Estados Unidos\n");
	strcat(string,"\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Anti-cheat: \n");
	strcat(string,"{FFFFFF}- Se encuentra desactivado\n");
	strcat(string,"\n");
	strcat(string,"{FFFFFF} {7C7C7C}Contacto:\n");
	strcat(string,"{FFFFFF}- wtxclanx@hotmail.com\n");
	strcat(string,"\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Versión: {FFFFFF}0.3b\n");
	ShowPlayerDialog(playerid, DIALOG_CREDITOS, 0, "Información sobre el servidor", string, "Ok", "");
	return 1;
}
//GetPlayerColor(playerid) >>> 8
CMD:fpsall(playerid, params[]){
	SendClientMessageToAll(COLOR_BLANCO,"[FPS]");
	ForPlayers(i)
		SCMTAF(COLOR_BLANCO, "- {%06x}%s {FFFFFF}> "GRISEADO"%d {FFFFFF}FPS", GetPlayerColor(playerid) >>> 8, infoJugador[i][Nombre], GetPlayerFPS(i));
	return 1;
}
stock GetPlayerFPS(playerid) return FPS[playerid];


CMD:crearclan(playerid, params[]){
	if(tieneClan(playerid) > 0) return SendClientMessage(playerid, COLOR_ROJO, "Ya estas en un clan, utiliza /salirclan si queres salir.");
	if(procesoClan) return SendClientMessage(playerid, COLOR_BLANCO, "Ya hay alguien creando un clan, espera a que registre el suyo.");
	if(!infoJugador[playerid][Registrado]) return SendClientMessage(playerid, COLOR_ROJO, "Debes estar registrado.");
    new string[1000];
	strcat(string,"{FFFFFF}¿Estas seguro de que querés registrar un clan?\n");
	strcat(string,"{7C7C7C}- Al crear el clan vos serás el único propietario/dueño y será permanente\n");
	strcat(string,"- También tené en cuenta que si el clan no es real se te sancionará..\n");
	ShowPlayerDialog(playerid, DIALOG_IFCLAN, 0, "Registro de clanes", string, "Si", "No");
	return 1;
}

CMD:clan(playerid, params[]){
	if(tieneClan(playerid) == 0)
		return SendClientMessage(playerid, COLOR_ROJO, "No estas en ningún clan.");
	if(infoJugador[playerid][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	    
	printf("idclanplayerid: %d", sacarClanId(playerid));
	
    new DBResult:resultado, idClan = sacarClanId(playerid), consultita[1000], str[100];
	new propietario[24], miembros, nombreClan[30], TAG[6], killsTotales, cwPerdidas, cwGanadas;
	
    format(consultita, sizeof(consultita), " SELECT * FROM registro WHERE id = %d", idClan);
 	strcat(consultita, str);
	resultado = db_query(Clanes, consultita);
	
	db_get_field_assoc(resultado, "nombre", nombreClan, 30);
	db_get_field_assoc(resultado, "propietario", propietario, 24);
	db_get_field_assoc(resultado, "tag", TAG, 6);
    miembros 		= db_get_field_assoc_int(resultado, "miembros");
    killsTotales 	= db_get_field_assoc_int(resultado, "kills");
    cwGanadas 		= db_get_field_assoc_int(resultado, "cwGanadas");
    cwPerdidas 		= db_get_field_assoc_int(resultado, "cwPerdidas");
    printf("nombre:%s dueño:%s tag:%s\n", nombreClan, propietario, TAG);
    printf("kills:%d cwg:%d cwp:%d miembros:%d\n", killsTotales, cwGanadas, cwPerdidas, miembros);
    
	new statsClan[1000], nombreDelClan[30];
	format(nombreDelClan, sizeof(nombreDelClan), "{7C7C7C}%s", nombreClan);
	
    format(statsClan, sizeof(statsClan), "{7C7C7C}Dueño: {FFFFFF}%s", propietario);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Tag: {FFFFFF}%s", statsClan, TAG);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Miembros: {FFFFFF}%d", statsClan, miembros);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Kills: {FFFFFF}%d", statsClan, killsTotales);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Clan Wars ganadas: {FFFFFF}%d", statsClan, cwGanadas);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Clan Wars perdidas: {FFFFFF}%d", statsClan, cwPerdidas);
    ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, nombreDelClan, statsClan, "Cerrar", "");
    db_free_result(resultado);
	return 1;
}

CMD:top(playerid, params[]){
	return mostrarTop(playerid);
}

CMD:cambiarmodo(playerid, params[]){
	printf("%s", nombreModo());
	if(modoDeJuego)
		modoDeJuego = false;
	else
		modoDeJuego = true;
    SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha cambiado el modo de juego a {FFFFFF}%s", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], nombreModo());
   	printf("%s", nombreModo());
    actualizarTextGlobales();
	return 1;
}

CMD:rondas(playerid, params[]){
    if(isnull(params))
  		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/rondas [1:10]");
	new i = strval(params);
 	if(i > 10 || i < 1)
		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/rondas [1:10]");
    maximaRonda = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció la ronda máxima a {FFFFFF}%d",GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Desde ahora se jugará: {FFFFFF}%dx%d", maximaRonda, maximoPuntaje);
	actualizarTextGlobales();
	return 1;
}

CMD:puntajederonda(playerid, params[]){
    if(isnull(params))
  		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/puntajederonda [1:100]");
	new i = strval(params);
 	if(i > 100 || i < 1)
		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/puntajederonda [1:100]");
    maximoPuntaje = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció el puntaje máximo a {FFFFFF}%d",GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Desde ahora se jugará: {FFFFFF}%dx%d", maximaRonda, maximoPuntaje);
	actualizarTextGlobales();
	return 1;
}

CMD:puntajenaranja(playerid, params[]){
    if(isnull(params)){
   		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/puntajenaranja [1:%d]", maximoPuntaje-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
    }
	new i = strval(params);
 	if(i > (maximoPuntaje-1) || i < 1){
		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/puntajenaranja [1:%d]", maximoPuntaje-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
 	}
 	if(i == dataEquipo[EQUIPO_NARANJA][Puntaje])
 	    return SendClientMessage(playerid, COLOR_ROJO, "No establezcas el mismo valor actual");

    dataEquipo[EQUIPO_NARANJA][Puntaje] = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció el puntaje del equipo {F69521}%s "GRISEADO"a {FFFFFF}%d", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_NARANJA], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Marcador actual > {F69521}%d"GRISEADO":{77CC77}%d", dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje]);
	actualizarTextGlobales();
	return 1;
}
CMD:puntajeverde(playerid, params[]){
    if(isnull(params)){
   		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/puntajeverde [1:%d]", maximoPuntaje-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
    }
	new i = strval(params);
 	if(i > (maximoPuntaje-1) || i < 1){
		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/puntajeverde [1:%d]", maximoPuntaje-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
 	}
 	if(i == dataEquipo[EQUIPO_VERDE][Puntaje])
 	    return SendClientMessage(playerid, COLOR_ROJO, "No establezcas el mismo valor actual");

    dataEquipo[EQUIPO_VERDE][Puntaje] = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció el puntaje del equipo {77CC77}%s "GRISEADO"a {FFFFFF}%d", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_VERDE], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Marcador actual > {F69521}%d"GRISEADO":{77CC77}%d", dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje]);
	actualizarTextGlobales();
	return 1;
}


CMD:kill(playerid, params[]){
    SetPlayerHealth(playerid,-1);
	return 1;
}
CMD:actualizar(playerid, params[]){
    format(nombreEquipo[EQUIPO_NARANJA],50,"%s",params);
    actualizarTextGlobales();
	return 1;
}


CMD:rondanaranja(playerid, params[]){
	new i = strval(params);
    dataEquipo[EQUIPO_NARANJA][Rondas] = i;
    actualizarTextGlobales();
    return 1;
}

CMD:rondaverde(playerid, params[]){
	new i = strval(params);
    dataEquipo[EQUIPO_VERDE][Rondas] = i;
    actualizarTextGlobales();
}

CMD:resetrondas(playerid, params[]){
	resetearRondas();
    actualizarTextGlobales();
    return 1;
}

CMD:resetpuntos(playerid, params[]){
	resetearPuntos();
    actualizarTextGlobales();
    return 1;
}

stock IP(i){
	new x[20];
	GetPlayerIp(i, x, 20);
	return x;
}

stock nombre(playerid){
	new Nick[MAX_PLAYER_NAME];
	GetPlayerName(playerid, Nick, MAX_PLAYER_NAME);
	return Nick;
}

stock sscanf(string[], format[], {Float,_}:...)
{
        #if defined isnull
                if (isnull(string))
        #else
                if (string[0] == 0 || (string[0] == 1 && string[1] == 0))
        #endif
                {
                        return format[0];
                }
        #pragma tabsize 4
        new
                formatPos = 0,
                stringPos = 0,
                paramPos = 2,
                paramCount = numargs(),
                delim = ' ';
        while (string[stringPos] && string[stringPos] <= ' ')
        {
                stringPos++;
        }
        while (paramPos < paramCount && string[stringPos])
        {
                switch (format[formatPos++])
                {
                        case '\0':
                        {
                                return 0;
                        }
                        case 'i', 'd':
                        {
                                new
                                        neg = 1,
                                        num = 0,
                                        ch = string[stringPos];
                                if (ch == '-')
                                {
                                        neg = -1;
                                        ch = string[++stringPos];
                                }
                                do
                                {
                                        stringPos++;
                                        if ('0' <= ch <= '9')
                                        {
                                                num = (num * 10) + (ch - '0');
                                        }
                                        else
                                        {
                                                return -1;
                                        }
                                }
                                while ((ch = string[stringPos]) > ' ' && ch != delim);
                                setarg(paramPos, 0, num * neg);
                        }
                        case 'h', 'x':
                        {
                                new
                                        num = 0,
                                        ch = string[stringPos];
                                do
                                {
                                        stringPos++;
                                        switch (ch)
                                        {
                                                case 'x', 'X':
                                                {
                                                        num = 0;
                                                        continue;
                                                }
                                                case '0' .. '9':
                                                {
                                                        num = (num << 4) | (ch - '0');
                                                }
                                                case 'a' .. 'f':
                                                {
                                                        num = (num << 4) | (ch - ('a' - 10));
                                                }
                                                case 'A' .. 'F':
                                                {
                                                        num = (num << 4) | (ch - ('A' - 10));
                                                }
                                                default:
                                                {
                                                        return -1;
                                                }
                                        }
                                }
                                while ((ch = string[stringPos]) > ' ' && ch != delim);
                                setarg(paramPos, 0, num);
                        }
                        case 'c':
                        {
                                setarg(paramPos, 0, string[stringPos++]);
                        }
                        case 'f':
                        {

                                new changestr[16], changepos = 0, strpos = stringPos;
                                while(changepos < 16 && string[strpos] && string[strpos] != delim)
                                {
                                        changestr[changepos++] = string[strpos++];
                                }
                                changestr[changepos] = '\0';
                                setarg(paramPos,0,_:floatstr(changestr));
                        }
                        case 'p':
                        {
                                delim = format[formatPos++];
                                continue;
                        }
                        case '\'':
                        {
                                new
                                        end = formatPos - 1,
                                        ch;
                                while ((ch = format[++end]) && ch != '\'') {}
                                if (!ch)
                                {
                                        return -1;
                                }
                                format[end] = '\0';
                                if ((ch = strfind(string, format[formatPos], false, stringPos)) == -1)
                                {
                                        if (format[end + 1])
                                        {
                                                return -1;
                                        }
                                        return 0;
                                }
                                format[end] = '\'';
                                stringPos = ch + (end - formatPos);
                                formatPos = end + 1;
                        }
                        case 'u':
                        {
                                new
                                        end = stringPos - 1,
                                        id = 0,
                                        bool:num = true,
                                        ch;
                                while ((ch = string[++end]) && ch != delim)
                                {
                                        if (num)
                                        {
                                                if ('0' <= ch <= '9')
                                                {
                                                        id = (id * 10) + (ch - '0');
                                                }
                                                else
                                                {
                                                        num = false;
                                                }
                                        }
                                }
                                if (num && IsPlayerConnected(id))
                                {
                                        setarg(paramPos, 0, id);
                                }
                                else
                                {
                                        #if !defined foreach
                                                #define foreach(%1,%2) for (new %2 = 0; %2 < MAX_PLAYERS; %2++) if (IsPlayerConnected(%2))
                                                #define __SSCANF_FOREACH__
                                        #endif
                                        string[end] = '\0';
                                        num = false;
                                        new
                                                name[MAX_PLAYER_NAME];
                                        id = end - stringPos;
                                        foreach (Player, playerid)
                                        {
                                                GetPlayerName(playerid, name, sizeof (name));
                                                if (!strcmp(name, string[stringPos], true, id))
                                                {
                                                        setarg(paramPos, 0, playerid);
                                                        num = true;
                                                        break;
                                                }
                                        }
                                        if (!num)
                                        {
                                                setarg(paramPos, 0, INVALID_PLAYER_ID);
                                        }
                                        string[end] = ch;
                                        #if defined __SSCANF_FOREACH__
                                                #undef foreach
                                                #undef __SSCANF_FOREACH__
                                        #endif
                                }
                                stringPos = end;
                        }
                        case 's', 'z':
                        {
                                new
                                        i = 0,
                                        ch;
                                if (format[formatPos])
                                {
                                        while ((ch = string[stringPos++]) && ch != delim)
                                        {
                                                setarg(paramPos, i++, ch);
                                        }
                                        if (!i)
                                        {
                                                return -1;
                                        }
                                }
                                else
                                {
                                        while ((ch = string[stringPos++]))
                                        {
                                                setarg(paramPos, i++, ch);
                                        }
                                }
                                stringPos--;
                                setarg(paramPos, i, '\0');
                        }
                        default:
                        {
                                continue;
                        }
                }
                while (string[stringPos] && string[stringPos] != delim && string[stringPos] > ' ')
                {
                        stringPos++;
                }
                while (string[stringPos] && (string[stringPos] == delim || string[stringPos] <= ' '))
                {
                        stringPos++;
                }
                paramPos++;
        }
        do
        {
                if ((delim = format[formatPos++]) > ' ')
                {
                        if (delim == '\'')
                        {
                                while ((delim = format[formatPos++]) && delim != '\'') {}
                        }
                        else if (delim != 'z')
                        {
                                return delim;
                        }
                }
        }
        while (delim > ' ');
        return 0;
}

