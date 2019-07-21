/*
 *  Modo CW/TG (Clan War & Training)
 *  © por Andrew Manu :)
*/

#include <a_samp>
#include <zcmd>

#define NOMBRE_EQUIPO_NARANJA 	"Naranja"
#define NOMBRE_EQUIPO_VERDE 	"Verde"

#define EQUIPO_ESPECTADOR  	0
#define EQUIPO_NARANJA 		1
#define EQUIPO_VERDE 		2

#define COLOR_BLANCO 		0xFFFFFFFF
#define COLOR_NARANJA 		0xF78411FF
#define COLOR_VERDE 		0x77CC77FF
#define COLOR_ROJO      	0xF51111FF

#define GRISEADO            "{C3C3C3}"
#define ROJO	            "{F51111}"

#define DIALOG_REGISTRO 	1
#define DIALOG_LOGEAR   	2
#define DIALOG_COMANDOS 	3
#define DIALOG_STATS        4
#define DIALOG_FPSALL       5
#define DIALOG_SEQUIPO      6 /* Seleccionar equipo */
#define DIALOG_CREDITOS     7

new bool:FALSE = false;
#define ForPlayers(%0) for(new %0; %0 <= Conectados;%0++) if(IsPlayerConnected(%0))
#define SCMTAF(%0,%1,%2) do{new _string[128]; format(_string,sizeof(_string),%1,%2); SendClientMessageToAll(%0,_string);} while(FALSE)

#pragma tabsize 0

new Equipo[MAX_PLAYERS];
new nombreEquipo[3][50];
new totalJugadores[3];
new bool:equiposBloqueados;



new mapaElegido;
new Float:spawnMapas[4][3][4] =
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

new DB:Cuentas;
new DB_Query[1000];
new FPS[MAX_PLAYERS], FPSS[MAX_PLAYERS];
new Conectados;

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
    bool:Registrado
};
new infoJugador[MAX_PLAYERS][Data];


forward establecerVariables(playerid);
public establecerVariables(playerid)
{
	Equipo[playerid] = EQUIPO_ESPECTADOR;
	establecerColor(playerid);
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
    totalJugadores[EQUIPO_NARANJA] 	= 0;
    totalJugadores[EQUIPO_VERDE]		= 0;
    totalJugadores[EQUIPO_ESPECTADOR] = 0;
	ForPlayers(i){
	    if(Equipo[i] == EQUIPO_NARANJA)
			totalJugadores[EQUIPO_NARANJA]++;
	    if(Equipo[i] == EQUIPO_VERDE)
	        totalJugadores[EQUIPO_VERDE]++;
	    if(Equipo[i] == EQUIPO_ESPECTADOR)
	        totalJugadores[EQUIPO_ESPECTADOR]++;
	}
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
    
    format(nombreEquipo[EQUIPO_NARANJA], 50, "%s", NOMBRE_EQUIPO_NARANJA);
    format(nombreEquipo[EQUIPO_VERDE], 50, "%s", NOMBRE_EQUIPO_VERDE);
	equiposBloqueados = false;
	
    Cuentas = db_open("jugadores/cuentas.db");

    if(Cuentas){
        printf("La bd Cuentas ha sido abierta ");
        new DBResult:asignacion;
		asignacion = db_query(Cuentas, "CREATE TABLE IF NOT EXISTS cuentas (id INTEGER PRIMARY KEY AUTOINCREMENT, nick TEXT, password TEXT, ip INTEGER, nivelAdmin INTEGER, puntajeRanked INTEGER, duelosGanados INTEGER, duelosPerdidos INTEGER)");
		db_free_result(asignacion);
	}else print("La bd Cuentas no pudo ser abierta");


	SetGameModeText("CW/TG Script");
 	SetWorldTime(15);
  	SetWeather(7);
	ShowPlayerMarkers(1);
	ShowNameTags(1);
	AllowAdminTeleport(1);

	AddPlayerClass(265,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);

	return 1;
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
        format(Dialogo, sizeof(Dialogo),""GRISEADO"Escribi la {FFFFFF}contraseña "GRISEADO"para proceder.\n");
        ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, ""GRISEADO"Cuenta ya registrada:", Dialogo, "Logear", "Salir");
	}else{
        format(Dialogo, sizeof(Dialogo),""GRISEADO"Escribí una {FFFFFF}contraseña si queres registrar esta cuenta, sino cancela el registro.\n");
        ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, ""GRISEADO"Cuenta no registrada:", Dialogo, "Registrar", "Cancelar");
    }
	//GameTextForPlayer(playerid,"~w~SA-MP: ~r~Bare Script",5000,5);
	return 1;
}

public OnPlayerDisconnect(playerid, reason){
    new Mensaje[64], razonesDesconexion[3][] = {"Crash/Timeout", "Salió", "Kick/Ban"};
    format(Mensaje, sizeof(Mensaje), "{%06x}%s se ha desconectado (%s).", GetPlayerColor(playerid) >>> 8, infoJugador[playerid][Nombre], razonesDesconexion[reason]);
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
        		format(Dialogo, sizeof(Dialogo),""GRISEADO"La contraseña que introduciste es errónea\nIntentalo devuelta ingresando otra contraseña..\n");
        		ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, ""ROJO"Error de registro", Dialogo, "Registrar", "Cancelar");
			}else{
                format(infoJugador[playerid][Password], 24, inputtext);
                registrarDatos(playerid);
                SendClientMessage(playerid, COLOR_VERDE, "Te has registrado correctamente.");
            }
        }
   		case DIALOG_LOGEAR:
        {
            if(!response) return Kick(playerid);
            if(!strcmp(infoJugador[playerid][Password], inputtext, true, 20)){
				infoJugador[playerid][Registrado] = true;
				cargarDatos(playerid);
			}else{
                new Dialogo[240];
                SendClientMessage(playerid, COLOR_ROJO, "Contraseña incorrecta, probá de nuevo.");
 				format(Dialogo, sizeof(Dialogo),""GRISEADO"La {FFFFFF}contraseña "GRISEADO"que introduciste es {FFFFFF}errónea, "GRISEADO"intentalo devuelta.\\n");
                ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, ""ROJO"Error de conexión", Dialogo, "Logear", "Salir");
            }
        }
        case DIALOG_SEQUIPO:
        {
        	if(response){
        	    establecerJugadores();
        		switch(listitem){
        		    case 0:
					{
						if(Equipo[playerid] == EQUIPO_NARANJA) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "%s "GRISEADO"se integró al equipo {F69521}%s", infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_NARANJA]);
                		Equipo[playerid] = EQUIPO_NARANJA;
					}
					case 1:
					{
						if(Equipo[playerid] == EQUIPO_VERDE) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "%s "GRISEADO"se integró al equipo {77CC77}%s", infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_VERDE]);
                		Equipo[playerid] = EQUIPO_VERDE;
					}
					case 2:
					{
						if(Equipo[playerid] == EQUIPO_ESPECTADOR) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "%s "GRISEADO"se integró al equipo {FFFFFF}Espectador", infoJugador[playerid][Nombre]);
                		Equipo[playerid] = EQUIPO_ESPECTADOR;
					}
				}
				establecerJugadores();
        		establecerColor(playerid);
			}else{
			
			}
        }
    }
    return 1;
}

registrarDatos(playerid)
{
    new str[80], anio, mes , dia;
    getdate(anio, mes, dia); 
    printf("%d %d %d", dia, mes, anio);
    format(DB_Query, sizeof(DB_Query), "INSERT INTO cuentas (nick, password, ip, nivelAdmin, puntajeRanked, duelosGanados, duelosPerdidos) VALUES ");
    format(str, sizeof(str), "('%s',", infoJugador[playerid][Nombre]);		strcat(DB_Query, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][Password]);     strcat(DB_Query, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][ip]);     		strcat(DB_Query, str);
    format(str, sizeof(str), "0,");     									strcat(DB_Query, str);
    format(str, sizeof(str), "500,");     									strcat(DB_Query, str);
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
    if(infoJugador[playerid][Registrado] == false) return 1;
    
    new str[64];
    format(DB_Query, sizeof(DB_Query), "");
    strcat(DB_Query, "UPDATE cuentas SET ");

    format(str, 64, "nick = '%s',", infoJugador[playerid][Nombre]);             		strcat(DB_Query, str);
    format(str, 64, "password = '%s',", infoJugador[playerid][Password]);       		strcat(DB_Query, str);
    format(str, 64, "ip = '%s',", infoJugador[playerid][ip]);             	 			strcat(DB_Query, str);
    format(str, 64, "nivelAdmin = '%d',", infoJugador[playerid][Admin]);             	strcat(DB_Query, str);
    format(str, 64, "duelosGanados = '%d',", infoJugador[playerid][duelosGanados]);     strcat(DB_Query, str);
    format(str, 64, "duelosPerdidos = '%d',", infoJugador[playerid][duelosPerdidos]);   strcat(DB_Query, str);
    format(str, 64, "puntajeRanked = '%d',", infoJugador[playerid][puntajeRanked]);     strcat(DB_Query, str);
    format(str, 64, "WHERE id = '%d'", infoJugador[playerid][idDB]);             		strcat(DB_Query, str);
    db_query(Cuentas, DB_Query);
	printf("Datos guardados");
   //PlayerInfo[playerid][Logado] = false;
    return 1;
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
    SetPlayerPos(playerid, spawnMapas[mapaElegido][Equipo[playerid]][0], spawnMapas[mapaElegido][Equipo[playerid]][1], spawnMapas[mapaElegido][Equipo[playerid]][2]);
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


CMD:cmds(playerid, params[]){
	//if(Admin[playerid] == 1) ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, "Comandos del sevidor", "Jugadores\nEspectador\nAdministrador nivel 1", "Selec", "Cancelar");
	ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, ""GRISEADO"Comandos del sevidor", ""GRISEADO"Comandos para {00779E}Jugadores\n"GRISEADO"Comando para {FFFFFF}Espectadores", "Selec.", "Cancelar");
	return 1;
}

CMD:equipo(playerid, params[]){
	if(equiposBloqueados) return SendClientMessage(playerid, COLOR_ROJO, "Los equipos están bloqueados.");
	new selece[600], string[100];
 	strcat(selece, ""GRISEADO"Nombre\t"GRISEADO"Jugadores");
	format(string, sizeof(string), "\n{F78411}%s\t"GRISEADO"%d", nombreEquipo[EQUIPO_NARANJA], totalJugadores[EQUIPO_NARANJA]);		strcat(selece, string);
	format(string, sizeof(string), "\n{77CC77}%s\t"GRISEADO"%d", nombreEquipo[EQUIPO_VERDE], totalJugadores[EQUIPO_VERDE]); 		strcat(selece, string);
	format(string, sizeof(string), "\n{FFFFFF}Espectador\t"GRISEADO"%d", totalJugadores[EQUIPO_ESPECTADOR]);						strcat(selece, string);
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

    format(stats, sizeof(stats), ""GRISEADO"Nick: {%06x}%s", GetPlayerColor(playerid) >>> 8, infoJugador[i][Nombre]);
    format(stats, sizeof(stats), "%s\n"GRISEADO"Duelos ganados: {00DFF7}%d", stats, infoJugador[i][duelosGanados]);
    format(stats, sizeof(stats), "%s\n"GRISEADO"Duelos perdidos: {00DFF7}%d", stats, infoJugador[i][duelosPerdidos]);
    format(stats, sizeof(stats), "%s\n"GRISEADO"Puntaje ranked: {00DFF7}%d", stats, infoJugador[i][puntajeRanked]);
    ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, "Estadistica:", stats, "Cerrar", "");
    return 1;
}

CMD:creditos(playerid, params[]){
    new string[1200];
	strcat(string,"{FFFFFF}> {7C7C7C}Creador de la GameMode{B8B8B8}: \n");
	strcat(string,"{FFFFFF}- [WTx]Andrew_Manu (2017)\n");
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
	strcat(string,"\n");
	ShowPlayerDialog(playerid, DIALOG_CREDITOS, 0, "Información sobre el servidor", string, "Ok", "");
	return 1;
}
//GetPlayerColor(playerid) >>> 8
CMD:fpsall(playerid, params[]){
	SendClientMessageToAll(COLOR_BLANCO,"[FPS]");
	ForPlayers(i) SCMTAF(COLOR_BLANCO, "- {%06x}%s {FFFFFF}> "GRISEADO"%d {FFFFFF}FPS", GetPlayerColor(playerid) >>> 8, infoJugador[i][Nombre], GetPlayerFPS(i));
	return 1;
}
stock GetPlayerFPS(playerid) return FPS[playerid];



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

