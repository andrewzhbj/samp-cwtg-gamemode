/*
 *  Modo CW/TG (Clan War & Training)
 *  © por Andrew Manu
*/

#include <a_samp>
#include <zcmd>
#include <geolocation>

/* - Equipos - */
#define NOMBRE_EQUIPO_NARANJA 	"Naranja"
#define NOMBRE_EQUIPO_VERDE 	"Verde"
#define EQUIPO_NARANJA   		0
#define EQUIPO_VERDE   			1
#define EQUIPO_ESPECTADOR  		2
#define EQUIPO_MAX_CHAR         20

/* - Partida - */
#define RONDA_POR_DEFECTO   	1
#define PUNTAJE_POR_DEFECTO 	10
#define ENTRENAMIENTO       	0
#define CLAN_WAR            	1
#define UNO_VS_UNO          	2

#define SIN_RANGO               0
#define RANGO_BRONCE            1
#define RANGO_PLATA             2
#define RANGO_ORO               3
#define RANGO_PLATINO           4
#define RANGO_DIAMANTE          5
#define RANGO_MAESTRO           6
#define RANGO_GRAN_MAESTRO      7

/* - Mapas - */
#define LAS_VENTURAS            0
#define AEROPUERTO_LV           1
#define AEROPUERTO_SF           2
#define AUTO_ESCUELA            3

/* - Clanes - */
#define CLAN_NOMBRE				0
#define CLAN_TAG				1
#define CLAN_MAX_CHAR_TAG    	6
#define CLAN_MAX_CHAR_NOMBRE    30

/* - Colores - */
#define COLOR_BLANCO 			0xFFFFFFFF
#define COLOR_NARANJA 			0xF78411FF
#define COLOR_VERDE 			0x77CC77FF
#define COLOR_ROJO      		0xBF0000FF
#define GRISEADO            	"{C3C3C3}"
#define GRISEADOS           	"{C7C7C7}"
#define ROJO	            	"{F51111}"


/* - Dialogos - */
#define DIALOG_REGISTRO 		1
#define DIALOG_LOGEAR			2
#define DIALOG_COMANDOS			3
#define DIALOG_STATS       		4
#define DIALOG_FPSALL       	5
#define DIALOG_SEQUIPO      	6   /* Seleccionar equipo */
#define DIALOG_CREDITOS     	7
#define DIALOG_IFCLAN       	8   /* Verificación de crear un clan */
#define DIALOG_INCLAN       	9   /* Ingresar nombre del clan */
#define DIALOG_TGCLAN       	10  /* Ingresar tag del clan */
#define DIALOG_BORRARCLAN   	11  /* Verificaciónde borrar un clan */
#define DIALOG_PETICLAN     	12  /* Invitación de un clan */
#define DIALOG_CJUGADOR  		13
#define DIALOG_CESPECTADOR  	14
#define DIALOG_TOP          	30
#define DIALOG_TOPRANKED    	31
#define DIALOG_TOPDUELOSG   	32  /* Duelos ganados */
#define DIALOG_TOPDUELOSP   	33  /* Duelos perdidos */
#define DIALOG_TOPCKILLS    	34  /* Clan kills */
#define DIALOG_TOPCWGANADAS 	35
#define DIALOG_TOPCWPERD    	36
#define DIALOG_MODOJUEGO    	37
#define DIALOG_SELECMAPA    	38

/* - Funciones - */
new bool:FALSE = false;
#define ForPlayers(%0) for(new %0; %0 <= Conectados;%0++) if(IsPlayerConnected(%0))
#define SCMF(%0,%1,%2,%3) do{new _string[128]; format(_string,sizeof(_string),%2,%3); SendClientMessage(%0,%1,_string);} while(FALSE)
#define SCMTAF(%0,%1,%2) do{new _string[128]; format(_string,sizeof(_string),%1,%2); SendClientMessageToAll(%0,_string);} while(FALSE)

/* - Tabulación - */
#pragma tabsize 0

/* - Jugadores - */
#undef MAX_PLAYERS
#define MAX_PLAYERS 50

new Equipo[MAX_PLAYERS];
new nombreEquipo[3][EQUIPO_MAX_CHAR];
new totalJugadores[3];
new bool:equiposBloqueados;

enum dataE
{
	Rondas,
	Puntaje,
	Owned
};
new dataEquipo[2][dataE];
new maximoPuntaje;
new maximaRonda;
new rondaActual;
new modoDeJuego;

new skinJugador[MAX_PLAYERS];
new killsJugador[MAX_PLAYERS];
new muertesJugador[MAX_PLAYERS];
enum DataInv{
	idClanInvitado,
	tagClanInvitado[6],
	idInvitador
};
new clanInvitacion[MAX_PLAYERS][DataInv];
new bool:aceptarInvitaciones[MAX_PLAYERS];
new bool:eligiendoSkin[MAX_PLAYERS];
new FPS[MAX_PLAYERS];
new FPSS[MAX_PLAYERS];

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
			{-1313.0103, -55.3676, 13.4844, 180.0000},
			{-1186.4745, -182.016, 14.1484, 90.0000},
			{-1227.1295, -76.7832, 29.0887, 130.0000}
		},{ /* Auto-escuela */
			{-2047.4285, -117.2283, 35.2487, 178.9484},
			{-2051.0955, -267.9533, 35.3203, 358.7801},
			{-2092.7380, -107.3132, 44.5237}
		}
	};
//{{843.9710,-2835.3689,12.79},{760.48,-2720.81,12.79},{733.13,-2775.95,25.3693}},	JardÃ­n-mÃ¡gico */

new DB:Cuentas;
new DB:Clanes;
new consultaDb[1000];
new Conectados;

new bool:procesoClan;
new clanNuevoNombre[CLAN_MAX_CHAR_NOMBRE];
new clanNuevoTag[CLAN_MAX_CHAR_TAG];

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
new PlayerText:mostrarKills[MAX_PLAYERS], PlayerText:mostrarMuertes[MAX_PLAYERS], PlayerText:mostrarRatio[MAX_PLAYERS];

forward refrescarPosicion();
public refrescarPosicion(){
	ForPlayers(playerid){
		if(Equipo[playerid] == EQUIPO_ESPECTADOR && eligiendoSkin[playerid] == false){
			new Float:Z;
			GetPlayerPos(playerid, Z, Z, Z);
			if(mapaElegido != 0){
				if(Z < spawnMapas[mapaElegido][EQUIPO_NARANJA][2]+1){
 					//printf("pos actual:%f map: %f", Z, spawnMapas[mapaElegido][EQUIPO_NARANJA][2]+1);
					SpawnPlayer(playerid);
				}
			}else{
				if(Z < 12){
					SpawnPlayer(playerid);
				}
			}
		}
	}
	return 1;
}

forward establecerVariables(playerid);
public establecerVariables(playerid)
{
	Equipo[playerid] = EQUIPO_ESPECTADOR;
	skinJugador[playerid] = -1;
	eligiendoSkin[playerid] = true;
	clanInvitacion[playerid][idClanInvitado] = 0;
	strcat(clanInvitacion[playerid][tagClanInvitado], "");
	clanInvitacion[playerid][idInvitador] = 0;
	aceptarInvitaciones[playerid] = true;
	establecerColor(playerid);
	return 1;
}

main()
{
	print("Gamemode: CW/TG\n");
	print("Desarrollador: Andrew_Manu\n");
}

public OnGameModeInit()
{
	modoDeJuego = ENTRENAMIENTO;
    	mapaElegido = AEROPUERTO_SF;
	maximaRonda = RONDA_POR_DEFECTO;
	maximoPuntaje = PUNTAJE_POR_DEFECTO;
 	format(nombreEquipo[EQUIPO_VERDE], EQUIPO_MAX_CHAR, "%s", NOMBRE_EQUIPO_VERDE);
 	format(nombreEquipo[EQUIPO_NARANJA], EQUIPO_MAX_CHAR, "%s", NOMBRE_EQUIPO_NARANJA);

    SetTimer("refrescarPosicion", 1000, true);
    
	maximaRonda = 3;
	rondaActual = 1;
	resetearTodo();
	procesoClan = false;
	equiposBloqueados = false;
	establecerJugadores();
	
  	SetWeather(7);
	SetWorldTime(15);
	ShowNameTags(1);
	ShowPlayerMarkers(1);
	AllowAdminTeleport(1);
	UsePlayerPedAnims();
	DisableInteriorEnterExits();
	SetGameModeText("CW/TG (v0.2)");
	
	Clanes = db_open("clanes/registro.db");
    	Cuentas = db_open("jugadores/cuentas.db");
    
	new DBResult:asignacion;
    	if(Cuentas){
        	printf("Cuentas db abierto");
		asignacion = db_query(Cuentas, "CREATE TABLE IF NOT EXISTS cuentas (id INTEGER PRIMARY KEY AUTOINCREMENT, nick TEXT, password TEXT, ip INTEGER, nivelAdmin INTEGER, puntajeRanked INTEGER, duelosGanados INTEGER, duelosPerdidos INTEGER, clan INTEGER)");
		db_free_result(asignacion);
	}else print("Cuentas db no se pudo abrir");
	if(Clanes){
		printf("Clanes db abierto");
		asignacion = db_query(Clanes, "CREATE TABLE IF NOT EXISTS registro (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT, tag TEXT, propietario TEXT, kills INTEGER, muertes INTEGER, cwGanadas INTEGER, cwPerdidas INTEGER, miembros INTEGER, dia INTEGER, mes INTEGER, anio INTEGER)");
        	db_free_result(asignacion);
	}else printf("Clanes db no se pudo abrir");

	
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
	
	crearTextdrawsCW();
    
	AddPlayerClass(230, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(115, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(122, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(106, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(107, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(108, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(114, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(144, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(185, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	AddPlayerClass(261, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
   	AddPlayerClass(126, 1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
	return 1;
}


crearTextdraws1vs1(){
   	nombreEquipos = TextDrawCreate(114.666679, 413.155517, "[WTx]Andrew_Manu vs [KDs]Nexxus");
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

	puntajeEquipos = TextDrawCreate(100, 428, "Puntos: (1) 5 - 14 (2)");
	TextDrawLetterSize(puntajeEquipos, 0.200000, 1.000000);
	TextDrawAlignment(puntajeEquipos, 1);
	TextDrawColor(puntajeEquipos, -1);
	TextDrawSetShadow(puntajeEquipos, 0);
	TextDrawSetOutline(puntajeEquipos, 1);
	TextDrawBackgroundColor(puntajeEquipos, 51);
	TextDrawFont(puntajeEquipos, 1);
	TextDrawSetProportional(puntajeEquipos, 1);
	TextDrawBackgroundColor(puntajeEquipos, 0x000000AA);

	partidaRondas = TextDrawCreate(191, 428, "Ronda: 2/3");
	TextDrawLetterSize(partidaRondas, 0.200000, 1.000000);
	TextDrawAlignment(partidaRondas, 1);
	TextDrawColor(partidaRondas, -1);
	TextDrawSetShadow(partidaRondas, 0);
	TextDrawSetOutline(partidaRondas, 1);
	TextDrawBackgroundColor(partidaRondas, 51);
	TextDrawFont(partidaRondas, 1);
	TextDrawSetProportional(partidaRondas, 1);
	TextDrawBackgroundColor(partidaRondas, 0x000000AA);
}

crearTextdrawsCW(){
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
}

eliminarTextDrawsPartida(){
	TextDrawDestroy(nombreEquipos);
	TextDrawDestroy(puntajeEquipos);
	TextDrawDestroy(partidaRondas);
}


mostrarDataPlayer(playerid){
	PlayerTextDrawShow(playerid, mostrarFps[playerid]);
	PlayerTextDrawShow(playerid, mostrarPing[playerid]);
}

actualizarModoDeJuego(){
	new id = totalJugadores[EQUIPO_NARANJA], id2 = totalJugadores[EQUIPO_VERDE], aux = 0;
	if(id == 1 && id2 == 1){
		if(modoDeJuego != UNO_VS_UNO){
	    		modoDeJuego = UNO_VS_UNO;
	    		aux = 1;
		}
		else modoDeJuego = UNO_VS_UNO;
	}
	if((id == 0 && id2 == 0) || (id == 0 && id2 == 1) || (id == 1 && id2 == 0)){
 		if(modoDeJuego != ENTRENAMIENTO){
		 	modoDeJuego = ENTRENAMIENTO;
  			aux = 1;
		 }
	}
	if((id > 1 && id2 > 1) && (id > id2 || id < id2)){
		if(modoDeJuego != CLAN_WAR){
           		modoDeJuego = CLAN_WAR;
			aux = 1;
		}
	}
	if(aux != 0) SCMTAF(COLOR_BLANCO,"{FFFFFF}Server"GRISEADO" ha cambiado el modo de juego a {FFFFFF}%s", nombreModo());
}
actualizarTextGlobales(){
	new string[124];
	eliminarTextDrawsPartida();
    	if(modoDeJuego == UNO_VS_UNO){
		crearTextdraws1vs1();
		new jugadorNaranja = idJugadorNaranja(), jugadorVerde = idJugadorVerde();
    		format(string, sizeof(string), "~y~%s vs ~g~%s", infoJugador[jugadorNaranja][Nombre], infoJugador[jugadorVerde][Nombre]);
    	}else{
		crearTextdrawsCW();
    		format(string, sizeof(string), "~y~%s vs ~g~%s", nombreEquipo[EQUIPO_NARANJA], nombreEquipo[EQUIPO_VERDE]);
   	}
	TextDrawSetString(nombreEquipos, string);
    	format(string, sizeof(string), "Puntos: ~y~(%d) %d ~w~- ~g~%d (%d)", dataEquipo[EQUIPO_NARANJA][Rondas], dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje], dataEquipo[EQUIPO_VERDE][Rondas]);
    	TextDrawSetString(puntajeEquipos, string);
    	format(string, sizeof(string), "Ronda: ~b~%d~w~/~b~%d", rondaActual, maximaRonda);
    	TextDrawSetString(partidaRondas, string);
	ForPlayers(i){
 		format(string, sizeof(string), "Kills: ~b~%d", killsJugador[i]);
    		PlayerTextDrawSetString(i, mostrarKills[i], string);
 		format(string, sizeof(string), "Muertes: ~b~%d", muertesJugador[i]);
    		PlayerTextDrawSetString(i, mostrarMuertes[i], string);
    		new Float:ratio;
		if(muertesJugador[i] == 0) ratio = killsJugador[i];
		else ratio = float(killsJugador[i])/float(muertesJugador[i]);
 		format(string, sizeof(string), "Ratio: ~b~%0.2f", ratio);
    		PlayerTextDrawSetString(i, mostrarRatio[i], string);
	}
   	ForPlayers(i){
		TextDrawHideForPlayer(i, partidaRondas);
		TextDrawHideForPlayer(i, puntajeEquipos);
		TextDrawHideForPlayer(i, nombreEquipos);
		TextDrawHideForPlayer(i, tituloServer);
		PlayerTextDrawHide(i, mostrarKills[i]);
		PlayerTextDrawHide(i, mostrarMuertes[i]);
		PlayerTextDrawHide(i, mostrarRatio[i]);
		if(modoDeJuego != ENTRENAMIENTO){
			TextDrawShowForPlayer(i, nombreEquipos);
			TextDrawShowForPlayer(i, partidaRondas);
			TextDrawShowForPlayer(i, puntajeEquipos);
			if(Equipo[i] != EQUIPO_ESPECTADOR){
  				PlayerTextDrawShow(i, mostrarRatio[i]);
   				PlayerTextDrawShow(i, mostrarKills[i]);
				PlayerTextDrawShow(i, mostrarMuertes[i]);
		    }
		}else{
			TextDrawShowForPlayer(i, tituloServer);
		}
	}
}

resetearPuntos(){ for(new i=0;i<2;i++) dataEquipo[i][Puntaje] = 0; }
resetearRondas(){ for(new i=0;i<2;i++) dataEquipo[i][Rondas] = 0; }
resetearTodo(){
	for(new i=0;i<2;i++){
	    dataEquipo[i][Rondas] = 0;
	    dataEquipo[i][Puntaje] = 0;
	    dataEquipo[i][Owned] = 0;
	}
	rondaActual = 1;
}

public OnGameModeExit(){
    db_close(Cuentas);
    return 1;
}

paisJugador(playerid){
	new s[30];
	GetPlayerCountry(playerid, s, sizeof(s));
	return s;
}
colorJugador(playerid){
	return GetPlayerColor(playerid) >>> 8;
}
public OnPlayerConnect(playerid)
{
	if(playerid > Conectados) Conectados = playerid;
	
	establecerVariables(playerid);
	establecerJugadores();
	
	infoJugador[playerid][Nombre] = nombre(playerid);
	infoJugador[playerid][ip] = IP(playerid);

	new Mensaje[100];
	format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"se conectó al servidor ({%06x}%s"GRISEADO")", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(playerid), paisJugador(playerid));
	SendClientMessageToAll(colorJugador(playerid), Mensaje);
	
    	new DBResult:resultado;
    	format(consultaDb, sizeof(consultaDb), "SELECT * FROM cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
    	resultado = db_query(Cuentas, consultaDb);
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
	
	mostrarKills[playerid] = CreatePlayerTextDraw(playerid, 341.666748, 428, "Kills: 14");
	PlayerTextDrawLetterSize(playerid, mostrarKills[playerid], 0.200000, 1.000000);
	PlayerTextDrawAlignment(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawColor(playerid, mostrarKills[playerid], -1);
	PlayerTextDrawSetShadow(playerid, mostrarKills[playerid], 0);
	PlayerTextDrawSetOutline(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarKills[playerid], 51);
	PlayerTextDrawFont(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawSetProportional(playerid, mostrarKills[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarKills[playerid], 0x000000AA);
	
	mostrarMuertes[playerid] = CreatePlayerTextDraw(playerid, 380.333282, 428, "Muertes: 10");
	PlayerTextDrawLetterSize(playerid, mostrarMuertes[playerid], 0.200000, 1.000000);
	PlayerTextDrawAlignment(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawColor(playerid, mostrarMuertes[playerid], -1);
	PlayerTextDrawSetShadow(playerid, mostrarMuertes[playerid], 0);
	PlayerTextDrawSetOutline(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarMuertes[playerid], 51);
	PlayerTextDrawFont(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawSetProportional(playerid, mostrarMuertes[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarMuertes[playerid], 0x000000AA);
	
	mostrarRatio[playerid] = CreatePlayerTextDraw(playerid, 434, 428, "Ratio: 0.34");
	PlayerTextDrawLetterSize(playerid, mostrarRatio[playerid], 0.200000, 1.000000);
	PlayerTextDrawAlignment(playerid, mostrarRatio[playerid], 1);
	PlayerTextDrawColor(playerid, mostrarRatio[playerid], -1);
	PlayerTextDrawSetShadow(playerid, mostrarRatio[playerid], 0);
	PlayerTextDrawSetOutline(playerid, mostrarRatio[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarRatio[playerid], 51);
	PlayerTextDrawFont(playerid, mostrarRatio[playerid], 1);
	PlayerTextDrawSetProportional(playerid, mostrarRatio[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, mostrarRatio[playerid], 0x000000AA);

	//GameTextForPlayer(playerid,"~w~SA-MP: ~r~Bare Script",5000,5);
	return 1;
}

public OnPlayerDisconnect(playerid, reason){
	skinJugador[playerid] = -1;
	clanInvitacion[playerid][idClanInvitado] = 0;
	strcat(clanInvitacion[playerid][tagClanInvitado], "");
	clanInvitacion[playerid][idInvitador] = 0;
    	eligiendoSkin[playerid] = false;
    	aceptarInvitaciones[playerid] = true;
    
    	new Mensaje[124], razonesDesconexion[3][] = {"Crash/Timeout", "Salió", "Kick/Ban"};
    	format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"se desconectó ({7C7C7C}%s"GRISEADO").", colorJugador(playerid), infoJugador[playerid][Nombre], razonesDesconexion[reason]);
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
        case DIALOG_COMANDOS:
        {
        	if(response){
			new selece[1000], string[120];
			switch(listitem){
				case 0:
				{
					strcat(selece, ""GRISEADO"/{FFFFFF}equipo\t"GRISEADO"- Cambias de equipo (switch)."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}kill\t"GRISEADO"- Te suicidas por pendejo."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}top\t"GRISEADO"- Lista de tops del servidor, clanes y jugadores."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}creditos\t"GRISEADO"- Información sobre el servidor."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}admins\t"GRISEADO"- Lista de administradores conectados."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}inforangos\t"GRISEADO"- Información sobre el sistema ranked."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}infoclanes\t"GRISEADO"- Información sobre el sistema de clanes, leelo si vas a crear uno."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}crearclan\t"GRISEADO"- Registras tu clan, vos seras el dueño."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}borrarclan\t"GRISEADO"- Eliminas tu clan y a los miembros."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}invitar "GRISEADO"[id]\t"GRISEADO"- Invitas a alguien para que sea miembro de tu clan."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}skin "GRISEADO"[id]\t"GRISEADO"- Cambias tu skin, al salirte no se te guardará¡."); strcat(selece, string);
					strcat(selece, "\n"GRISEADO"/{FFFFFF}stats "GRISEADO"[id]\t"GRISEADO"- Estadítica de un jugador, podes sacar la id para ver los tuyos."); strcat(selece, string);
                        		strcat(selece, "\n"GRISEADO"/{FFFFFF}pm "GRISEADO"[id] [texto]\t"GRISEADO"- Envias un mensaje privado a un jugador."); strcat(selece, string);
					ShowPlayerDialog(playerid, DIALOG_CJUGADOR, DIALOG_STYLE_TABLIST, "Comandos para jugadores", selece, "Volver", "Cerrar");
				}
				case 1:
				{
					strcat(selece, ""GRISEADO"/{FFFFFF}spec\t{FFFFFF}Espectadores"); strcat(selece, string);
				    	ShowPlayerDialog(playerid, DIALOG_CESPECTADOR, DIALOG_STYLE_TABLIST, "Comandos para espectadores", selece, "Volver", "Cerrar");
				}
			}
		}
        }
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
            	}
        }
   	case DIALOG_LOGEAR:
        {
            if(!response) return Kick(playerid);
            if(isnull(inputtext) || !strcmp(inputtext, "0")) return ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, ""ROJO"Error de conexión", "{7C7C7C}La {FFFFFF}contraseña {7C7C7C}que introduciste es "ROJO"errónea{7C7C7C}, intentalo devuelta.\n", "Logear", "Salir");
            if(!strcmp(infoJugador[playerid][Password], inputtext, true, 20)){
				infoJugador[playerid][Registrado] = true;
				cargarDatos(playerid);
			}else ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, ""ROJO"Error de conexión", "{7C7C7C}La {FFFFFF}contraseña {7C7C7C}que introduciste es "ROJO"errónea{7C7C7C}, intentalo devuelta.\n", "Logear", "Salir");
        }
        case DIALOG_SEQUIPO:
        {
        	if(response){
        		switch(listitem){
        		    case 0:
					{
						if(Equipo[playerid] == EQUIPO_NARANJA) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"se integró al equipo {F69521}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_NARANJA]);
                		Equipo[playerid] = EQUIPO_NARANJA;
					}
					case 1:
					{
						if(Equipo[playerid] == EQUIPO_VERDE) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"se integró al equipo {77CC77}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_VERDE]);
                		Equipo[playerid] = EQUIPO_VERDE;
					}
					case 2:
					{
						if(Equipo[playerid] == EQUIPO_ESPECTADOR) return SendClientMessage(playerid, COLOR_ROJO, "Ya perteneces a este equipo, selecciona otro.");
        		        SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"se integró al equipo {FFFFFF}Espectador", colorJugador(playerid), infoJugador[playerid][Nombre]);
                		Equipo[playerid] = EQUIPO_ESPECTADOR;
					}
				}
				//establecerJugadores();
				actualizarModoDeJuego();
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
				strcat(string,"- Evita poner cosas raras, ¿si?\n");
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
		case DIALOG_BORRARCLAN:
		{
		    if(!response)
                return SendClientMessage(playerid, COLOR_ROJO, "Has cancaelado la eliminación del clan.");
			borrarClan(playerid);
		}
		case DIALOG_PETICLAN:
		{
		    if(!response){
				new str[158];
				format(str, sizeof(str), "{%06x}%s "GRISEADO"ha rechazado la petición de tu clan ({FFFFFF}%s"GRISEADO")", colorJugador(playerid), infoJugador[playerid][Nombre], clanInvitacion[playerid][tagClanInvitado]);
				SendClientMessage(clanInvitacion[playerid][idInvitador], COLOR_BLANCO, str);
				clanInvitacion[playerid][idClanInvitado] = 0;
				strcat(clanInvitacion[playerid][tagClanInvitado], "");
				clanInvitacion[playerid][idInvitador] = 0;
				return SendClientMessage(playerid, COLOR_ROJO, "Has rechazado la invitación.");
		    }
			nuevoMiembro(playerid);
		    
		}
		case DIALOG_TOP:
		{
 			if(response){
        		switch(listitem){
        		    case 0: mostrarTopRanked(playerid);
					case 1: mostrarTopDuelosGanados(playerid);
					case 2: mostrarTopDuelosPerdidos(playerid);
					case 3: mostrarTopClanKills(playerid);
					case 4: mostrarTopClanCWG(playerid);
					case 5: mostrarTopClanCWP(playerid);
				}
			}else{
			}
		}
		case DIALOG_TOPRANKED: 		if(response) mostrarTop(playerid);
		case DIALOG_TOPDUELOSG: 	if(response) mostrarTop(playerid);
		case DIALOG_TOPDUELOSP: 	if(response) mostrarTop(playerid);
		case DIALOG_TOPCKILLS: 		if(response) mostrarTop(playerid);
		case DIALOG_TOPCWGANADAS: 	if(response) mostrarTop(playerid);
		case DIALOG_TOPCWPERD:  	if(response) mostrarTop(playerid);
		case DIALOG_MODOJUEGO:
		{
			if(response){
			    //establecerJugadores();
   				printf("%d naranja, %d verde", totalJugadores[EQUIPO_NARANJA], totalJugadores[EQUIPO_VERDE]);
				switch(listitem){
   					case 0:
   					{
						if(modoDeJuego == CLAN_WAR){
                            ShowPlayerDialog(playerid, DIALOG_MODOJUEGO, DIALOG_STYLE_LIST, ""GRISEADO"Modos de juego", ""ROJO"Clan War\n{00779E}1 vs 1\n{00779E}Entrenamiento", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este modo de juego.");
						}
						if(totalJugadores[EQUIPO_NARANJA] < 2 || totalJugadores[EQUIPO_VERDE] < 2){
     						ShowPlayerDialog(playerid, DIALOG_MODOJUEGO, DIALOG_STYLE_LIST, ""GRISEADO"Modos de juego", "{00779E}Clan War\n{00779E}1 vs 1\n{00779E}Entrenamiento", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Tiene que haber mas de 1 jugador en cada equipo.");
						}
						modoDeJuego = CLAN_WAR;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el modo de juego a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreModo());
    					actualizarTextGlobales();
    					resetearJugadoresEnPartida();
					}
					case 1:
   					{
						if(modoDeJuego == UNO_VS_UNO){
                            ShowPlayerDialog(playerid, DIALOG_MODOJUEGO, DIALOG_STYLE_LIST, ""GRISEADO"Modos de juego", "{00779E}Clan War\n"ROJO"1 vs 1\n{00779E}Entrenamiento", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este modo de juego.");
						}
						if(totalJugadores[EQUIPO_NARANJA] != 1 || totalJugadores[EQUIPO_VERDE] != 1){
     						ShowPlayerDialog(playerid, DIALOG_MODOJUEGO, DIALOG_STYLE_LIST, ""GRISEADO"Modos de juego", "{00779E}Clan War\n{00779E}1 vs 1\n{00779E}Entrenamiento", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Tiene que haber un jugador en cada equipo.");
						}
						modoDeJuego = UNO_VS_UNO;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el modo de juego a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreModo());
                        actualizarTextGlobales();
                        resetearJugadoresEnPartida();
					}
					case 2:
   					{
						if(modoDeJuego == ENTRENAMIENTO){
                            ShowPlayerDialog(playerid, DIALOG_MODOJUEGO, DIALOG_STYLE_LIST, ""GRISEADO"Modos de juego", "{00779E}Clan War\n{00779E}1 vs 1\n"ROJO"Entrenamiento", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este modo de juego.");
						}
						modoDeJuego = ENTRENAMIENTO;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el modo de juego a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreModo());
                        actualizarTextGlobales();
                        resetearJugadoresEnPartida();
					}
				}
			}
		}
		case DIALOG_SELECMAPA:
		{
		    if(response){
		        switch(listitem){
		            case 0:
		            {
		                if(mapaElegido == LAS_VENTURAS){
              				ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", ""ROJO"Las venturas\n{00779E}Aeropuerto LV\n{00779E}Aeropuerto SF\n{00779E}Auto escuela", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este mapa.");
		                }
		                mapaElegido = LAS_VENTURAS;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el mapa a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreMapa(mapaElegido));
                        actualizarTextGlobales();
                        resetearTodosJugadores();
					}
  					case 1:
		            {
		                if(mapaElegido == AEROPUERTO_LV){
              				ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", "{00779E}Las venturas\n"ROJO"Aeropuerto LV\n{00779E}Aeropuerto SF\n{00779E}Auto escuela", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este mapa.");
		                }
		                mapaElegido = AEROPUERTO_LV;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el mapa a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreMapa(mapaElegido));
                        actualizarTextGlobales();
                        resetearTodosJugadores();
					}
  					case 2:
		            {
		                if(mapaElegido == AEROPUERTO_SF){
              				ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", "{00779E}Las venturas\n{00779E}Aeropuerto LV\n"ROJO"Aeropuerto SF\n{00779E}Auto escuela", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este mapa.");
		                }
		                mapaElegido = AEROPUERTO_SF;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el mapa a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreMapa(mapaElegido));
                        actualizarTextGlobales();
                        resetearTodosJugadores();
					}
  					case 3:
		            {
		                if(mapaElegido == AUTO_ESCUELA){
              				ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", "{00779E}Las venturas\n{00779E}Aeropuerto LV\n{00779E}Aeropuerto SF\n"ROJO"Auto escuela", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este mapa.");
		                }
		                mapaElegido = AUTO_ESCUELA;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el mapa a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreMapa(mapaElegido));
                        actualizarTextGlobales();
                        resetearTodosJugadores();
					}
		        }
		    }
		}
	}
    return 1;
}
//, kills, cwGanadas, cwPerdidas, miembros



borrarClan(playerid)
{
	new DBResult:resultado, idClan = tieneClan(playerid);
    printf("Se elimino el clan: %d", idClan);
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE id = %d", idClan);
    resultado = db_query(Clanes, consultaDb);
    if(db_num_rows(resultado)){
        new nombreClan[30];
   		db_get_field_assoc(resultado, "nombre", nombreClan, 30);
        db_free_result(resultado);
    	format(consultaDb, sizeof(consultaDb), "DELETE FROM registro WHERE id = %d", idClan);
    	resultado = db_query(Clanes, consultaDb);
    	db_free_result(resultado);
    	format(consultaDb, sizeof(consultaDb), "UPDATE Cuentas SET clan = 0 WHERE clan = %d", idClan);
    	resultado = db_query(Cuentas, consultaDb);
    	db_free_result(resultado);
        SendClientMessage(playerid, COLOR_VERDE, "Se eliminó el clan correctamente.");
       	new Mensaje[100];
		format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"ha borrado su clan ({FFFFFF}%s"GRISEADO")", colorJugador(playerid), infoJugador[playerid][Nombre], nombreClan);
		SendClientMessageToAll(COLOR_BLANCO, Mensaje);
		return 1;
    }else{
        return SendClientMessage(playerid, COLOR_ROJO, "No se pudo eliminar el clan.");
    }
}

expulsarMiembro(playerid){
	printf("%d metodo");
	new DBResult:resultado, idClan = sacarClanId(playerid), maxMiembros;
 	format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE id = %d", idClan);
 	resultado = db_query(Clanes, consultaDb);
 	printf("query %s", consultaDb);
 	if(db_num_rows(resultado)){
 	    maxMiembros = db_get_field_assoc_int(resultado, "miembros");
 	    maxMiembros--;
 		db_free_result(resultado);
 		format(consultaDb, sizeof(consultaDb), "UPDATE registro SET miembros = %d WHERE id = %d", maxMiembros, idClan);
 		resultado = db_query(Clanes, consultaDb);
	 	printf("query %s", consultaDb);
 		db_free_result(resultado);
  		format(consultaDb, sizeof(consultaDb), "UPDATE Cuentas SET clan = 0 WHERE id = %d", infoJugador[playerid][idDB]);
		resultado = db_query(Cuentas, consultaDb);
 		printf("query %s", consultaDb);
  		db_free_result(resultado);
 	}
}

nuevoMiembro(playerid){
	
    new DBResult:resultado, idClan = clanInvitacion[playerid][idClanInvitado], maxMiembros;
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM cuentas WHERE id = %d", infoJugador[playerid][idDB]);
    resultado = db_query(Cuentas, consultaDb);
    printf("query: %s",consultaDb);
    if(db_num_rows(resultado)){
    	db_free_result(resultado);
    	format(consultaDb, sizeof(consultaDb), "UPDATE Cuentas SET clan = %d WHERE id = %d", idClan, infoJugador[playerid][idDB]);
    	resultado = db_query(Cuentas, consultaDb);
    	printf("query22: %s",consultaDb);
    	db_free_result(resultado);
    	format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE id = %d", idClan);
    	resultado = db_query(Clanes, consultaDb);
    	printf("query3: %s",consultaDb);
	    if(db_num_rows(resultado)){
   			maxMiembros = db_get_field_assoc_int(resultado, "miembros");
   			maxMiembros++;
   			printf("%dmiembros", maxMiembros);
	    	db_free_result(resultado);
    		format(consultaDb, sizeof(consultaDb), "UPDATE registro SET miembros = %d WHERE id = %d", maxMiembros, idClan);
    		resultado = db_query(Clanes, consultaDb);
	    	db_free_result(resultado);
     		new Mensaje[100];
			format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"se integró al clan {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], sacarClanTag(playerid));
			SendClientMessageToAll(COLOR_BLANCO, Mensaje);
	    }
	}
}

registrarClan(playerid)
{
    new anio, mes, dia;
    getdate(anio, mes, dia);
	new str[80];
    format(consultaDb, sizeof(consultaDb), "INSERT INTO registro (nombre, tag, propietario, kills, muertes, cwGanadas, cwPerdidas, miembros, dia, mes, anio) VALUES ");
    format(str, sizeof(str), "('%s',", clanNuevoNombre);				strcat(consultaDb, str);
    format(str, sizeof(str), "'%s',", clanNuevoTag);     				strcat(consultaDb, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][Nombre]);   strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     								strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     								strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     								strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     								strcat(consultaDb, str);
    format(str, sizeof(str), "1,");     								strcat(consultaDb, str);
    format(str, sizeof(str), "%d,", dia);     							strcat(consultaDb, str);
    format(str, sizeof(str), "%d,", mes);     							strcat(consultaDb, str);
    format(str, sizeof(str), "%d)", anio );     						strcat(consultaDb, str);
    db_query(Clanes, consultaDb);
    printf("query: %s", consultaDb);
    procesoClan = false;
    SCMTAF(COLOR_BLANCO, "{%06x}%s "GRISEADO"ha registrado el clan {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], clanNuevoNombre);
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
	new DBResult:resultado, Puntos, nNick[40];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY puntajeRanked DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Puntos");
    if(db_num_rows(resultado)){
        strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Puntos");
		do{
			Puntos = db_get_field_assoc_int(resultado, "puntajeRanked");
			db_get_field_assoc(resultado, "nick", nNick, 24);
			format(string, sizeof(string), "\n{7C7C7C}%d\t{FFFFFF}%s\t{%s}%d", i, nNick, Puntos, colorRangoPuntos(i));
			strcat(selece, string);
			printf("%d %s %d", i, nNick, Puntos);
			i++;
		}while(db_next_row(resultado));
		db_free_result(resultado);
		ShowPlayerDialog(playerid, DIALOG_TOPRANKED, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}Ranked", selece, "Volver", "Cerrar");
	}
}

mostrarTopDuelosGanados(playerid){
	new i = 1, selece[1000], string[100];
	new DBResult:resultado, Duelos, nNick[24];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY duelosGanados DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Duelos");
    if(db_num_rows(resultado)){
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
}

mostrarTopDuelosPerdidos(playerid){
	new i = 1, selece[1000], string[100];
	//db_query(Cuentas, "UPDATE cuentas SET duelosGanados = 44 WHERE id = 3");
	new DBResult:resultado, Duelos, nNick[24];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY duelosPerdidos DESC LIMIT 20");
    if(db_num_rows(resultado)){
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
}

mostrarTopClanKills(playerid){
	new i = 1, selece[1000], string[100];
	//db_query(Clanes, "UPDATE registro SET kills = 100 WHERE id = 2");
	new DBResult:resultado, killsTotales, TAG[6];
    resultado = db_query(Clanes, "SELECT * FROM registro ORDER BY kills DESC LIMIT 20");
    strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Clan\t{7C7C7C}Kills");
    if(db_num_rows(resultado)){
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
}

mostrarTopClanCWG(playerid){
	new i = 1, selece[1000], string[100];
	//db_query(Clanes, "UPDATE registro SET cwGanadas = 2 WHERE id = 2");
	new DBResult:resultado, clanWars, TAG[6];
    resultado = db_query(Clanes, "SELECT * FROM registro ORDER BY cwGanadas DESC LIMIT 20");
    if(db_num_rows(resultado)){
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
}

mostrarTopClanCWP(playerid){
	new i = 1, selece[1000], string[100];
	//db_query(Clanes, "UPDATE registro SET cwPerdidas = 2 WHERE id = 2");
	new DBResult:resultado, clanWars, TAG[6];
    resultado = db_query(Clanes, "SELECT * FROM registro ORDER BY cwPerdidas DESC LIMIT 20");
    if(db_num_rows(resultado)){
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
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM Cuentas WHERE id = %d", infoJugador[playerid][idDB]);
    resultado = db_query(Cuentas, consultaDb);
    printf("Sacar tag idclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado)){
        idClan = db_get_field_assoc_int(resultado, "clan");
        printf("el clan es %d", idClan);
        db_free_result(resultado);
		if(idClan > 0){
        	format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE id = %d", idClan);
        	resultado = db_query(Clanes, consultaDb);
			db_get_field_assoc(resultado, "tag", TAG, 10);
  			db_free_result(resultado);
		}else
			strcat(TAG, "No tiene");
	}
	return TAG;
}

propietarioClan(playerid){
	new DBResult:resultado;
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE propietario = '%s'", infoJugador[playerid][Nombre]);
    resultado = db_query(Clanes, consultaDb);
    printf("propietarioclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado)){
		db_free_result(resultado);
		return 1;
    }else{
		db_free_result(resultado);
		return 0;
    }
}

hayAdmins(){
	new s = 0;
	ForPlayers(i){
	    if(infoJugador[i][Admin] > 0) s = 1;
		if(s == 1) break;
	}
	return s;
}

tieneClan(playerid)
{
	new DBResult:resultado, idClan;
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM Cuentas WHERE id = %d", infoJugador[playerid][idDB]);
    resultado = db_query(Cuentas, consultaDb);
    printf("Tieneclan: %d", db_num_rows(resultado));
    if(db_num_rows(resultado))
		idClan = db_get_field_assoc_int(resultado, "clan");
	else
		idClan = 0;
	db_free_result(resultado);
	return idClan;
}

sacarClanId(playerid)
{
	new DBResult:resultado, idClan;
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM Cuentas WHERE id = %d", infoJugador[playerid][idDB]);
    resultado = db_query(Cuentas, consultaDb);
    if(db_num_rows(resultado))
		idClan = db_get_field_assoc_int(resultado, "clan");
	db_free_result(resultado);
	return idClan;
}

sacarClanTag(playerid)
{
	new DBResult:resultado, TAG[6], idClan = sacarClanId(playerid);
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE id = %d", idClan);
    resultado = db_query(Clanes, consultaDb);
    if(db_num_rows(resultado))
    	db_get_field_assoc(resultado, "tag", TAG, 6);
	db_free_result(resultado);
	return TAG;
}

clanTextoValido(celda[], nombre[]){
    new DBResult:resultado;
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE %s = '%s'", celda, nombre);
    resultado = db_query(Clanes, consultaDb);
    printf("%d", db_num_rows(resultado));
	return db_num_rows(resultado);
}
registrarDatos(playerid)
{
    new str[80];
    format(consultaDb, sizeof(consultaDb), "INSERT INTO cuentas (nick, password, ip, nivelAdmin, puntajeRanked, duelosGanados, duelosPerdidos, clan) VALUES ");
    format(str, sizeof(str), "('%s',", infoJugador[playerid][Nombre]);		strcat(consultaDb, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][Password]);     strcat(consultaDb, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][ip]);     		strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0)");     									strcat(consultaDb, str);
    db_query(Cuentas, consultaDb);

    new DBResult:resultado;
    format(consultaDb, sizeof(consultaDb), "SELECT id FROM Cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
    resultado = db_query(Cuentas, consultaDb);
    if(db_num_rows(resultado)) infoJugador[playerid][idDB] = db_get_field_assoc_int(resultado, "id");
    db_free_result(resultado);

    infoJugador[playerid][Admin] 			= 0;
    infoJugador[playerid][duelosGanados] 	= 0;
    infoJugador[playerid][duelosPerdidos] 	= 0;
    infoJugador[playerid][puntajeRanked] 	= 0;
    infoJugador[playerid][Clan] 			= 0;
    infoJugador[playerid][Registrado] 		= true;
    guardarDatos(playerid);
    return 1;
}

cargarDatos(playerid)
{
	if(infoJugador[playerid][Registrado] == true){
    	new DBResult:resultado;
    	format(consultaDb, sizeof(consultaDb), "SELECT * FROM Cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
    	resultado = db_query(Cuentas, consultaDb);
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
		
    new str[128], consulta[256];
	format(str, sizeof(str), "UPDATE cuentas SET nick = '%s',", infoJugador[playerid][Nombre]);
	strcat(consulta, str);
	format(str, sizeof(str), "password = '%s',", infoJugador[playerid][Password]);
	strcat(consulta, str);
	format(str, sizeof(str), "ip = '%s',", infoJugador[playerid][ip]);
	strcat(consulta, str);
	format(str, sizeof(str), "nivelAdmin = %d,", infoJugador[playerid][Admin]);
	strcat(consulta, str);
	format(str, sizeof(str), "puntajeRanked = %d,", infoJugador[playerid][puntajeRanked]);
	strcat(consulta, str);
	format(str, sizeof(str), "duelosGanados = %d,", infoJugador[playerid][duelosGanados]);
	strcat(consulta, str);
	format(str, sizeof(str), "duelosPerdidos = %d,", infoJugador[playerid][duelosPerdidos]);
	strcat(consulta, str);
	format(str, sizeof(str), "clan = %d", infoJugador[playerid][Clan]);
	strcat(consulta, str);
	format(str, sizeof(str), " WHERE id = %d", infoJugador[playerid][idDB]);
	strcat(consulta, str);
	printf("query: %s\n", consulta);
	db_query(Cuentas, consulta);
	printf("Datos guardados id: %d", infoJugador[playerid][idDB]);
    return 1;
}

establecerPuntosObtenidos(ganador, perdedor){
	new rangoGanador = sacarRango(ganador), rangoPerdedor = sacarRango(perdedor), puntosGanador = 0, puntosPerdedor = 0;
	if(rangoGanador == rangoPerdedor){
 		puntosGanador = 10;
	    puntosPerdedor = 10;
	}else if(rangoGanador > rangoPerdedor || rangoGanador < rangoPerdedor){
	    puntosGanador = 2;
	    puntosPerdedor = 2;
	}
	if((infoJugador[perdedor][puntajeRanked] - puntosPerdedor) < 0)
	    infoJugador[perdedor][puntajeRanked] = 0;
	else
	    infoJugador[perdedor][puntajeRanked] -= puntosPerdedor;
	    
	infoJugador[ganador][puntajeRanked] += puntosGanador;
	new str[128];
 	format(str, sizeof(str), ""GRISEADO"Se te sumó {FFFFFF}+%d "GRISEADO"puntos por tu victoria ({FFFFFF}%d{FFFFFF})", puntosGanador, infoJugador[ganador][puntajeRanked]);
 	SendClientMessage(ganador, COLOR_BLANCO, str);
 	if(infoJugador[perdedor][puntajeRanked] == 0)
        format(str, sizeof(str), ""GRISEADO"No se te resto puntos porque no tenes ({FFFFFF}%d{FFFFFF})", puntosPerdedor, infoJugador[perdedor][puntajeRanked]);
 	else
 	    format(str, sizeof(str), ""GRISEADO"Se te restó {FFFFFF}-%d "GRISEADO"puntos por tu derrota ({FFFFFF}%d{FFFFFF})", puntosPerdedor, infoJugador[perdedor][puntajeRanked]);
 	SendClientMessage(perdedor, COLOR_BLANCO, str);
}

verificarGanador(){
	new equipoGanador, equipoPerdedor;
	if(dataEquipo[EQUIPO_NARANJA][Rondas] > dataEquipo[EQUIPO_VERDE][Rondas]){
		equipoGanador = EQUIPO_NARANJA;
 		equipoPerdedor = EQUIPO_VERDE;
	}else{
		equipoGanador = EQUIPO_VERDE;
 		equipoPerdedor = EQUIPO_NARANJA;
	}
	if(modoDeJuego == CLAN_WAR){
		SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%s}%s"GRISEADO" ha ganado la clan war contra .", colorEquipo(equipoGanador), nombreEquipo[equipoGanador], colorEquipo(equipoPerdedor), nombreEquipo[equipoPerdedor]);
	}else if(modoDeJuego == UNO_VS_UNO){
		new ganador, perdedor;
		if(equipoGanador == EQUIPO_NARANJA){
		    ganador = idJugadorNaranja();
		    perdedor = idJugadorVerde();
		}else{
		    ganador = idJugadorVerde();
		    perdedor = idJugadorNaranja();
		}
		SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha ganado el 1 vs 1 contra {%06x}%s", colorJugador(ganador), infoJugador[ganador][Nombre], colorJugador(perdedor), infoJugador[perdedor][Nombre]);
		establecerPuntosObtenidos(ganador, perdedor);
	}
	resetearTodo();
	resetearJugadoresEnPartida();
	actualizarTextGlobales();
}

resetearTodosJugadores(){
	ForPlayers(i)
		SpawnPlayer(i);
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
verificarRonda(killerid){
	new i = Equipo[killerid];
	new jugador = killerid;
	if(dataEquipo[Equipo[i]][Puntaje] == maximoPuntaje){
		dataEquipo[Equipo[i]][Rondas]++;
		resetearPuntos();
		if(rondaActual < maximaRonda){
			if(modoDeJuego == UNO_VS_UNO){
				new id, id2;
				if(Equipo[jugador] == EQUIPO_NARANJA){
				    id = idJugadorNaranja();
				    id2 = idJugadorVerde();
				}else{
				    id = idJugadorVerde();
				    id2 = idJugadorNaranja();
				}
				SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha ganado la {FFFFFF}%d ronda contra {%06x}%s", colorJugador(id), infoJugador[id][Nombre], rondaActual, colorJugador(id2), infoJugador[id2][Nombre]);
			}else{
				SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha ganado la %d ronda.", colorJugador(i), nombreEquipo[i], rondaActual);
			}
	    	rondaActual++;
  			SCMTAF(COLOR_BLANCO, "La partida va > %d:%d, empieza la %d ronda.", dataEquipo[Equipo[EQUIPO_NARANJA]][Rondas], dataEquipo[Equipo[EQUIPO_VERDE]][Rondas], rondaActual);
  			resetearJugadoresEnPartida();
		}
		else if(rondaActual == maximaRonda){
		    if(modoDeJuego == UNO_VS_UNO)
		        SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha ganado la ultima ronda.", colorJugador(i), infoJugador[jugador][Nombre]);
		    else
            	SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha ganado la ultima ronda.", colorJugador(i), nombreEquipo[i]);
			verificarGanador();
		}
	}
}

idJugadorVerde(){
	new id;
	ForPlayers(i){
		if(Equipo[i] == EQUIPO_VERDE) id = i;
	}
	return id;
}
idJugadorNaranja(){
	new id;
	ForPlayers(i){
		if(Equipo[i] == EQUIPO_NARANJA) id = i;
	}
	return id;
}


actualizarEquipo(playerid, killerid){
	if(modoDeJuego == CLAN_WAR){
        if(Equipo[playerid] == Equipo[killerid]){
           	new equipoOpuesto, equipoAdyacente = Equipo[playerid];
 			if(equipoAdyacente == EQUIPO_NARANJA) equipoOpuesto = EQUIPO_VERDE;
			else equipoOpuesto = EQUIPO_NARANJA;
        	SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha hecho teamkill.", colorJugador(playerid), nombreEquipo[equipoAdyacente]);
        	dataEquipo[Equipo[equipoOpuesto]][Puntaje]++;
    	}
	}else{
		new equipoPuntero = Equipo[killerid], equipoOpuesto = Equipo[playerid];
		dataEquipo[equipoOpuesto][Owned] = 0;
		dataEquipo[equipoPuntero][Owned]++;
		if(dataEquipo[equipoPuntero][Owned] == 5){
		    dataEquipo[equipoPuntero][Owned] = 0;
		    if(modoDeJuego == CLAN_WAR)
				SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha hecho owned al equipo {%06x}%s.", colorJugador(killerid), nombreEquipo[equipoPuntero], colorJugador(playerid), nombreEquipo[equipoOpuesto]);
			else{
			    new id, id2;
				if(equipoPuntero == EQUIPO_NARANJA){
                    id = idJugadorNaranja();
                    id2 = idJugadorVerde();
				}else{
                    id = idJugadorVerde();
                    id2 = idJugadorNaranja();
				}
				SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha hecho owned a {%06x}%s.", colorJugador(id), infoJugador[id][Nombre], colorJugador(id2), infoJugador[id2][Nombre]);
			}
		}
 		dataEquipo[equipoPuntero][Puntaje]++;
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

stock invitacionJugador(i){
	new s[11];
	if(aceptarInvitaciones[i] == true)
	    format(s, 11, "Activado");
	if(aceptarInvitaciones[i] == false)
	    format(s, 1, "Desactivado");
	return s;
}

stock colorEquipo(id){
	new s[6];
	if(id == EQUIPO_NARANJA)
		format(s, 6, "F69521");
	else
	    format(s, 6, "77CC77");
	return s;
}

stock nombreRango(playerid){
	new s[24], RANGO = sacarRango(playerid);
	if(RANGO == SIN_RANGO)
		format(s, 24, "Sin rango");
	if(RANGO == RANGO_BRONCE)
	    format(s, 24, "Bronce");
	if(RANGO == RANGO_PLATA)
	    format(s, 24, "Plata");
	if(RANGO == RANGO_ORO)
	    format(s, 24, "Oro");
	if(RANGO == RANGO_PLATINO)
	    format(s, 24, "Platino");
	if(RANGO == RANGO_DIAMANTE)
	    format(s, 24, "Diamante");
	if(RANGO == RANGO_MAESTRO)
	    format(s, 24, "Maestro");
	if(RANGO == RANGO_GRAN_MAESTRO)
	    format(s, 24, "Gran Maestro");
	return s;
}

stock colorRango(playerid){
	new s[9], RANGO = sacarRango(playerid);
	if(RANGO == SIN_RANGO)
		format(s, 9, "787878");
	if(RANGO == RANGO_BRONCE)
	    format(s, 9, "D66400");
	if(RANGO == RANGO_PLATA)
	    format(s, 9, "BDBDBD");
	if(RANGO == RANGO_ORO)
	    format(s, 9, "FFD900");
	if(RANGO == RANGO_PLATINO)
	    format(s, 9, "00AEBA");
	if(RANGO == RANGO_DIAMANTE)
	    format(s, 9, "00EFFF");
	if(RANGO == RANGO_MAESTRO)
	    format(s, 9, "FF0000");
	if(RANGO == RANGO_GRAN_MAESTRO)
	    format(s, 9, "FF0084");
	return s;
}

stock colorRangoPuntos(i){
	new s[6];
	if(i >= 0 && i < 30) format(s, 9, "787878");
	if(i >= 30 && i < 200) format(s, 9, "D66400");
	if(i >= 200 && i < 400) format(s, 9, "BDBDBD");
	if(i >= 400 && i < 600) format(s, 9, "FFD900");
	if(i >= 600 && i < 800) format(s, 9, "00AEBA");
	if(i >= 800 && i < 1000) format(s, 9, "00EFFF");
	if(i >= 1000 && i < 1200) format(s, 9, "FF0000");
	if(i >= 1200) format(s, 9, "FF0084");
	return s;
}

stock sacarRango(playerid){
	new RANGO, puntos = infoJugador[playerid][puntajeRanked];
	if(puntos >= 0 && puntos < 30) RANGO = SIN_RANGO;
	if(puntos >= 30 && puntos < 200) RANGO = RANGO_BRONCE;
	if(puntos >= 200 && puntos < 400) RANGO = RANGO_PLATA;
	if(puntos >= 400 && puntos < 600) RANGO = RANGO_ORO;
	if(puntos >= 600 && puntos < 800) RANGO = RANGO_PLATINO;
	if(puntos >= 800 && puntos < 1000) RANGO = RANGO_DIAMANTE;
	if(puntos >= 1000 && puntos < 1200) RANGO = RANGO_MAESTRO;
	if(puntos >= 1200) RANGO = RANGO_GRAN_MAESTRO;
	return RANGO;
}

stock tipoAdmin(id){
	new s[128];
	if(id == 0)
		format(s, 128, "{787878}No es admin");
	if(id == 1)
		format(s, 128, "Administrador de partidas");
	if(id == 2)
		format(s, 128, "Administrador general");
	if(id == 3)
		format(s, 128, "Administrador de jugadores");
	if(id > 3)
	    format(s, 128, "{B00000}Dueño");
	return s;
}

stock nombreMapa(id){
	new s[20];
    if(id == LAS_VENTURAS)
        format(s, 20, "Las venturas");
    if(id == AEROPUERTO_LV)
        format(s, 20, "Aeropuerto LV");
    if(id == AEROPUERTO_SF)
        format(s, 20, "Aeropuerto SF");
    if(id == AUTO_ESCUELA)
    	format(s, 20, "Auto escuela");
	return s;
}

stock nombreModo(){
	new s[25];
	if(modoDeJuego == CLAN_WAR)
		format(s, 25, "Clan War");
	if(modoDeJuego == ENTRENAMIENTO)
		format(s,25, "Entrenamiento");
 	if(modoDeJuego == UNO_VS_UNO)
		format(s,25, "1 vs 1");
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
    new Mensaje[256];
	format(Mensaje, sizeof(Mensaje), "{C3C3C3}[{%s}%i{C3C3C3}] {%06x}%s {C3C3C3}[%d]{FFFFFF}: %s", colorRango(playerid), infoJugador[playerid][puntajeRanked], colorJugador(playerid), infoJugador[playerid][Nombre], playerid, text);
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
	if(eligiendoSkin[playerid] == true){
		mostrarDataPlayer(playerid);
		actualizarTextGlobales();
	}
    eligiendoSkin[playerid] = false;
    if(skinJugador[playerid] != -1)
		SetPlayerSkin(playerid, skinJugador[playerid]);
    
	GivePlayerWeapon(playerid, 22, 9999);
	GivePlayerWeapon(playerid, 28, 9999);
	GivePlayerWeapon(playerid, 26, 9999);
	
    SetPlayerHealth(playerid,100);
    SetPlayerPos(playerid, spawnMapas[mapaElegido][Equipo[playerid]][0], spawnMapas[mapaElegido][Equipo[playerid]][1], spawnMapas[mapaElegido][Equipo[playerid]][2]);
	SetPlayerFacingAngle(playerid, spawnMapas[mapaElegido][Equipo[playerid]][3]);
	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason){
	if(killerid == INVALID_PLAYER_ID)
		return SpawnPlayer(playerid);
    if(Equipo[playerid] == EQUIPO_ESPECTADOR)
		return SpawnPlayer(playerid);

    SpawnPlayer(playerid);
    SendDeathMessage(killerid, playerid, reason);
	if(modoDeJuego != ENTRENAMIENTO){
		killsJugador[killerid]++;
		muertesJugador[playerid]++;
		actualizarEquipo(playerid, killerid);
	}
	if(tieneClan(playerid) > 0){
  //format(consultaDb, sizeof(consultaDb), "UPDATE registros SET clan = 0 WHERE clan = %d", idClan);
    	//resultado = db_query(Cuentas, consultaDb);
 }
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

/* Comandos para jugadores */

CMD:top(playerid, params[]){
	return mostrarTop(playerid);
}

CMD:cmds(playerid, params[]){
	new selece[600], string[100], Nivel = infoJugador[playerid][Admin];
	strcat(selece, "{00779E}Jugadores\n{FFFFFF}Espectadores");
	switch(Nivel){
	    case 1:
		{
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(1));	strcat(selece, string);
		}
		case 2:
	    {
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(1));	strcat(selece, string);
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(2));	strcat(selece, string);
		}
		case 3:
		{
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(1));	strcat(selece, string);
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(2));	strcat(selece, string);
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(3));	strcat(selece, string);
		}
	}
	ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, ""GRISEADO"Comandos del sevidor", selece, "Selec.", "Cancelar");
	return 1;
}

CMD:equipo(playerid, params[]){
	if(equiposBloqueados)
		return SendClientMessage(playerid, COLOR_ROJO, "Los equipos están bloqueados.");
 	new selece[600], selece1[100], string[100], stringTitulo[100];
	if(modoDeJuego == ENTRENAMIENTO)
        format(stringTitulo, sizeof(stringTitulo), "Entrenamiento, seleciona tu equipo..");
	if(modoDeJuego == CLAN_WAR)
	    format(stringTitulo, sizeof(stringTitulo), "Se está jugando una Clan War");
	if(modoDeJuego == UNO_VS_UNO)
	    format(stringTitulo, sizeof(stringTitulo), "Se está jugando un 1 vs 1");
	strcat(selece1, stringTitulo);
	
	if(modoDeJuego != UNO_VS_UNO){
		strcat(selece, "{7C7C7C}Nombre\t{7C7C7C}Jugadores");
		format(string, sizeof(string), "\n{F78411}%s\t{7C7C7C}%d", nombreEquipo[EQUIPO_NARANJA], totalJugadores[EQUIPO_NARANJA]);	strcat(selece, string);
		format(string, sizeof(string), "\n{77CC77}%s\t{7C7C7C}%d", nombreEquipo[EQUIPO_VERDE], totalJugadores[EQUIPO_VERDE]); 		strcat(selece, string);
		format(string, sizeof(string), "\n{FFFFFF}Espectador\t{7C7C7C}%d", totalJugadores[EQUIPO_ESPECTADOR]);						strcat(selece, string);
	}else{
	    new jugadorNaranja = idJugadorNaranja(), jugadorVerde = idJugadorVerde();
		strcat(selece, "{7C7C7C}Nicks de los jugadores");
		format(string, sizeof(string), "\n{F78411}%s\t{7C7C7C}%d", infoJugador[jugadorNaranja][Nombre]);		strcat(selece, string);
		format(string, sizeof(string), "\n{77CC77}%s\t{7C7C7C}%d", infoJugador[jugadorVerde][Nombre]); 			strcat(selece, string);
		format(string, sizeof(string), "\n{FFFFFF}Espectador\t{7C7C7C}%d", totalJugadores[EQUIPO_ESPECTADOR]);	strcat(selece, string);
	}
    ShowPlayerDialog(playerid, DIALOG_SEQUIPO, DIALOG_STYLE_TABLIST_HEADERS, stringTitulo, selece, "Selec.", "Cerrar");
	return 1;
}

CMD:skin(playerid, params[]){
	if(isnull(params))
	    return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/skin [1:311]");
	new id = strval(params), str[128];
	if(id > 311 || id < 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/skin [1:311]");
	SetPlayerSkin(playerid, id);
	skinJugador[playerid] = GetPlayerSkin(playerid);
	format(str, sizeof(str), ""GRISEADO"Se cambio tu skin ({FFFFFF}%d"GRISEADO")", id);
	SendClientMessage(playerid, COLOR_BLANCO, str);
	return 1;
}

CMD:pm(playerid, params[]){
	new str[128], Mensaje[256], id;
	if(sscanf(params, "us", id, Mensaje))
		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/pm ID texto");
 	if(!IsPlayerConnected(id))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(id == playerid)
	    return SendClientMessage(playerid, COLOR_ROJO, "No podes enviarte un pm a vos mismo.");

	format(str, sizeof(str), ""GRISEADO"Mensaje privado {34eb5e}enviado "GRISEADO"a {%06x}%s"GRISEADO" [%d]: {FFFFFF}%s", colorJugador(id), infoJugador[id][Nombre], id, Mensaje);
	PlayerPlaySound(id, 1085, 0.0, 0.0, 0.0);
	SendClientMessage(playerid, COLOR_BLANCO, str);

	format(str, sizeof(str), ""GRISEADO"Mensaje privado {34eb5e}recibido "GRISEADO"de {%06x}%s"GRISEADO" [%d]: {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], playerid, Mensaje);
	PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
	SendClientMessage(id, COLOR_BLANCO, str);
	return 1;
}

CMD:hora(playerid, params[]){
    if(isnull(params))
	    return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/hora [0:24]");
    new id = strval(params), str[128];
	if(id > 24 || id < 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/hora [0:24]");

	SetPlayerTime(playerid, id, 0);
	format(str, sizeof(str), ""GRISEADO"Se cambio tu horario ({FFFFFF}%d"GRISEADO")", id);
	SendClientMessage(playerid, COLOR_BLANCO, str);
	return 1;
}

CMD:clima(playerid, params[]){
    if(isnull(params))
	    return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/clima [0:50000]");
    new id = strval(params), str[128];
	if(id > 50000 || id < 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/clima [0:50000]");

	SetPlayerWeather(playerid, id);
	format(str, sizeof(str), ""GRISEADO"Se cambio tu clima ({FFFFFF}%d"GRISEADO")", id);
	SendClientMessage(playerid, COLOR_BLANCO, str);
	return 1;
}

CMD:admins(playerid, params[]){
	if(!hayAdmins())
	    return SendClientMessage(playerid, COLOR_ROJO, "No hay administradores conectados");

	new strTitulo[100], strAdmins[256], str[128], Cant = 0, Nivel;
    format(str, sizeof(str), ""GRISEADO"Nick\t"GRISEADO"Nivel");
    strcat(strAdmins, str);
	ForPlayers(i){
	    if(infoJugador[i][Admin] > 0){
			Nivel = infoJugador[i][Admin];
	        format(str, sizeof(str), "\n{%06x}%s\t{FFFFFF}%d (%s{FFFFFF})", colorJugador(i), infoJugador[i][Nombre], Nivel, tipoAdmin(Nivel));
	        strcat(strAdmins, str);
	        Cant++;
	    }
	}
	format(str, sizeof(str), ""GRISEADO"Hay %d administrador/es conectados", Cant);
	strcat(strTitulo, str);

	ShowPlayerDialog(playerid, 2343, DIALOG_STYLE_TABLIST_HEADERS, strTitulo, strAdmins, "Cerrar", "");
	return 1;
}

CMD:stats(playerid, params[]){
    new i, stats[1000];
    if(isnull(params)) i = playerid;
    else i = strval(params);
	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	    
    format(stats, sizeof(stats), "{7C7C7C}Nick: {%06x}%s", colorJugador(i), infoJugador[i][Nombre]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Invitaciones: {FFFFFF}%s", stats, invitacionJugador(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Clan: {FFFFFF}%s", stats, tagClan(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Pais: {FFFFFF}%s", stats, paisJugador(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Ping: {FFFFFF}%d", stats, GetPlayerPing(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Skin: {FFFFFF}%d", stats, GetPlayerSkin(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}PacketLoss: {FFFFFF}%.2f%", stats, NetStats_PacketLossPercent(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Rango: {%s}%s {7C7C7C}({FFFFFF}%d{7C7C7C})", stats, colorRango(i), nombreRango(i), infoJugador[i][puntajeRanked]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Duelos ganados: {FFFFFF}%d", stats, infoJugador[i][duelosGanados]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Duelos perdidos: {FFFFFF}%d", stats, infoJugador[i][duelosPerdidos]);
    if(infoJugador[i][Admin] > 0) format(stats, sizeof(stats), "%s\n{7C7C7C}%s {7C7C7C}({FFFFFF}%d{7C7C7C})", stats, tipoAdmin(infoJugador[i][Admin]), infoJugador[i][Admin]);
    ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, "Estadistica:", stats, "Cerrar", "");
    return 1;
}

CMD:creditos(playerid, params[]){
    new string[1200];
	strcat(string,"{FFFFFF}> {7C7C7C}Desarrollador{B8B8B8}: {FFFFFF}[WTx]Andrew_Manu\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Tester{B8B8B8}: {FFFFFF}Alexis_Blaze\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Contacto{B8B8B8}: {FFFFFF}wtxclanx@hotmail.com\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Versión{B8B8B8}: {FFFFFF}0.3b\n");
	strcat(string,"{7C7C7C}El servidor garantiza la confidencialidad y protección de tus datos.\n");
	ShowPlayerDialog(playerid, DIALOG_CREDITOS, 0, "Información sobre el servidor", string, "Ok", "");
	return 1;
}

CMD:infoclanes(playerid, params[]){
    new string[1200];
	strcat(string,"{FFFFFF}> {7C7C7C}Crear clan{B8B8B8}:\n");
	strcat(string,"{FFFFFF}- Necesitas estar registrado.\n");
	strcat(string,"{FFFFFF}- Necesitas tener rango {FFD900}Oro {FFFFFF}o mayor ({B8B8B8}/inforangos{FFFFFF}).\n");
	strcat(string,"{FFFFFF}- Se te quitará 100 puntos de tu rango.\n");
	strcat(string,"{FFFFFF}- Serás el único dueño y no podrás tener ningún sublider ni lider además de vos.\n");
	strcat(string,"{FFFFFF}- Tiene que ser verdadero, sino se te borrará el clan y las estadísticas de tu cuenta.\n");
	strcat(string,"\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Unirte a un clan{B8B8B8}:\n");
	strcat(string,"{FFFFFF}- Necesitas estar registrado.\n");
	strcat(string,"{FFFFFF}- Necesitas tener por lo menos rango {D66400}Bronce {FFFFFF}({B8B8B8}/inforangos{FFFFFF}).\n");
	strcat(string,"{FFFFFF}- Solo podrás pertenecer a ese clan y no otro.\n");
	strcat(string,"{FFFFFF}\n");
	strcat(string,"{B8B8B8}Si pasan 3 días desde que creaste el clan y sos el único dentro, se te borrará el clan.\n");
	strcat(string,"{B8B8B8}El sistema de clanes sigue en desarrollo, estas reglas pueden cambiar en nuevas versiones.\n");
	strcat(string,"{B8B8B8}Versión actual{B8B8B8}: {FFFFFF}0.1b\n");
	ShowPlayerDialog(playerid, DIALOG_CREDITOS, 0, "Información sobre clanes", string, "Ok", "");
	return 1;
}

CMD:inforango(playerid, params[]){
    new string[1200];
	strcat(string,"{FFFFFF}> {7C7C7C}Ganar puntos{B8B8B8}:\n");
	strcat(string,"{7C7C7C}- {FFFFFF}Para subir de rango tenes que jugar 1vs1 con las rondas que quieras\n  con la condición de que el puntaje sea mayor o igual a 10 ({B8B8B8}1x10{FFFFFF}).");
	strcat(string,"\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Lista de rangos{B8B8B8}:\n");
	strcat(string,"{7C7C7C}   Nombre    \t{7C7C7C}Puntos\n");
	strcat(string,"{7C7C7C}- {D66400}Bronce \t{7C7C7C}({FFFFFF}30 - 200{7C7C7C})\n");
	strcat(string,"{7C7C7C}- {BDBDBD}Plata    \t{7C7C7C}({FFFFFF}200 - 400{7C7C7C})\n");
	strcat(string,"{7C7C7C}- {FFD900}Oro     \t{7C7C7C}({FFFFFF}400 - 600{7C7C7C})\n");
	strcat(string,"{7C7C7C}- {00AEBA}Platino \t{7C7C7C}({FFFFFF}600 - 800{7C7C7C})\n");
	strcat(string,"{7C7C7C}- {00EFFF}Diamante \t{7C7C7C}({FFFFFF}800 - 1000{7C7C7C})\n");
	strcat(string,"{7C7C7C}- {FF0000}Maestro \t{7C7C7C}({FFFFFF}1000 - 1200{7C7C7C})\n");
	strcat(string,"{7C7C7C}- {FF0084}Gran maestro \t{7C7C7C}({FFFFFF}> 1200, rango máximo{7C7C7C})\n");
	ShowPlayerDialog(playerid, DIALOG_CREDITOS, 0, "Información sobre rangos", string, "Ok", "");
	return 1;
}

/* Comandos para administradores de partidas */

CMD:fpsall(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	SendClientMessageToAll(COLOR_BLANCO,"> FPS:");
	ForPlayers(i)
		SCMTAF(COLOR_BLANCO, "- {%06x}%s {FFFFFF}> "GRISEADO"%d {FFFFFF}FPS", colorJugador(i), infoJugador[i][Nombre], GetPlayerFPS(i));
	return 1;
}
stock GetPlayerFPS(playerid) return FPS[playerid];


CMD:reseteartodos(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	resetearTodo();
    actualizarTextGlobales();
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha reseteado toda la partida.", colorJugador(playerid), infoJugador[playerid][Nombre]);
    return 1;
}

CMD:resetrondas(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	resetearRondas();
    actualizarTextGlobales();
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha reseteado las rondas de cada equipo.", colorJugador(playerid), infoJugador[playerid][Nombre]);
    return 1;
}

CMD:resetpuntos(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	resetearPuntos();
    actualizarTextGlobales();
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha reseteado el puntaje de cada equipo.", colorJugador(playerid), infoJugador[playerid][Nombre]);
    return 1;
}

CMD:(playerid, params[])
{
 	new Float:cxp, Float:cyp, Float:czp, string2[125];
 	GetPlayerCameraPos(playerid, cxp, cyp, czp);
 	format(string2, sizeof(string2), "X:%f  Y:%f Z:%f\n", cxp, cyp, czp);
  	SendClientMessage(playerid, COLOR_BLANCO, string2);
 return 1;
}

CMD:fang(playerid,params)
{
    new Float:Ai;
	GetPlayerFacingAngle(playerid, Ai);
	new string2[125];
	format(string2,sizeof(string2),"%f",Ai);
	SendClientMessage(playerid,-1,string2);
	return 1;
}

CMD:modo(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	return ShowPlayerDialog(playerid, DIALOG_MODOJUEGO, DIALOG_STYLE_LIST, ""GRISEADO"Modos de juego", "{00779E}Clan War\n{00779E}1 vs 1\n{00779E}Entrenamiento", "Selec.", "Cancelar");
}

CMD:mapa(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	if(modoDeJuego != ENTRENAMIENTO)
	    return SendClientMessage(playerid, COLOR_ROJO, "No podes cambiar el mapa mientras estan jugando una partida.");
	new str[128];
	format(str, sizeof(str), "{00779E}Las venturas\n{00779E}Aeropuesto LV\n{00779E}Aeropuesto SF\n{00779E}Auto escuela");
	return ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", str, "Selec.", "Cancelar");
}

CMD:rondas(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
    if(isnull(params))
  		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/rondas [1:10]");
	new i = strval(params);
 	if(i > 10 || i < 1)
		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/rondas [1:10]");
    maximaRonda = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció la ronda máxima a {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Desde ahora se jugará¡: {FFFFFF}%dx%d", maximaRonda, maximoPuntaje);
	actualizarTextGlobales();
	return 1;
}

CMD:puntajederonda(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
    if(isnull(params))
  		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/puntajederonda [1:100]");
	new i = strval(params);
 	if(i > 100 || i < 1)
		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/puntajederonda [1:100]");
    maximoPuntaje = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció el puntaje máxima a  {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Desde ahora se jugará¡: {FFFFFF}%dx%d", maximaRonda, maximoPuntaje);
	actualizarTextGlobales();
	return 1;
}

CMD:puntajenaranja(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
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
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció el puntaje del equipo {F69521}%s "GRISEADO"a {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_NARANJA], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Marcador actual > {F69521}%d"GRISEADO":{77CC77}%d", dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje]);
	actualizarTextGlobales();
	return 1;
}

CMD:puntajeverde(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
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
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció el puntaje del equipo {77CC77}%s "GRISEADO"a {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_VERDE], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Marcador actual > {F69521}%d"GRISEADO":{77CC77}%d", dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje]);
	actualizarTextGlobales();
	return 1;
}

/* Comandos para administradores generales */
CMD:ir(playerid, params[]){
	if(infoJugador[playerid][Admin] < 2)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores generales pueden usar este comando.");
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/ir ID");
	new i = strval(params), Float:x, Float:y, Float:z;
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
		
	GetPlayerPos(i, x, y, z);
 	if(IsPlayerInAnyVehicle(playerid))
 		SetVehiclePos(playerid, x+1, y+1, z);
 	else
  		SetPlayerPos(playerid, x+1, y+1, z);
    new str[128];
    format(str, sizeof(str), ""GRISEADO"Fuiste a la posición de {%06x}%s", colorJugador(i), infoJugador[i][Nombre]);
    SendClientMessage(playerid, COLOR_BLANCO, str);
    format(str, sizeof(str), "{%06x}%s "GRISEADO" vino a tu posición", colorJugador(playerid), infoJugador[playerid][Nombre]);
    SendClientMessage(i, COLOR_BLANCO, str);
    return 1;
}

CMD:traer(playerid, params[]){
	if(infoJugador[playerid][Admin] < 2)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores generales pueden usar este comando.");
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/ir ID");
	new i = strval(params), Float:x, Float:y, Float:z;
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");

	GetPlayerPos(playerid, x, y, z);
 	if(IsPlayerInAnyVehicle(i))
 		SetVehiclePos(i, x+1, y+1, z);
 	else
  		SetPlayerPos(i, x+1, y+1, z);
    new str[128];
    format(str, sizeof(str), ""GRISEADO"Has traido a {%06x}%s", colorJugador(i), infoJugador[i][Nombre]);
    SendClientMessage(playerid, COLOR_BLANCO, str);
    format(str, sizeof(str), "{%06x}%s "GRISEADO" te llevo a su posición", colorJugador(playerid), infoJugador[playerid][Nombre]);
    SendClientMessage(i, COLOR_BLANCO, str);
    return 1;
}

CMD:cc(playerid, params[]){
	if(infoJugador[playerid][Admin] < 2)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores generales pueden usar este comando.");
 	for(new i=0;i<=100;i++)
   		SendClientMessageToAll(COLOR_BLANCO, "");
  	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha borrado el log del chat.", colorJugador(playerid), infoJugador[playerid][Nombre]);
	return 1;
}

/* COmandos para administradores de jugadores */

CMD:setadmin(playerid, params[]){
	new Nivel, i;
	if(infoJugador[playerid][Admin] < 3)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de jugadores pueden usar este comando.");
	if(sscanf(params, "ii", i, Nivel))
		return SendClientMessage(playerid, COLOR_ROJO,"Escribiste mal el comando; {FFFFFF}/setadmin ID Nivel");
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
 	if(Nivel > 3 || Nivel < 0)
		return SendClientMessage(playerid, COLOR_ROJO,"Solo hay 3 niveles.");
	if(Nivel == infoJugador[i][Admin])
		return SendClientMessage(playerid, COLOR_ROJO,"Ya tiene ese nivel.");

	new str[200];
	infoJugador[i][Admin] = Nivel;
	format(str, sizeof(str), "{%06x}%s"GRISEADO" le dio a {%06x}%s "GRISEADO"nivel: {FFFFFF}%d (%s{FFFFFF})", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], Nivel, tipoAdmin(Nivel));
	SendClientMessageToAll( COLOR_BLANCO, str);
	guardarDatos(i);
	return 1;
}

/* Comandos para el dueño */
CMD:guardardatos(playerid, params[]){
	if(infoJugador[playerid][Admin] < 3)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores pueden usar este comando.");
	ForPlayers(i)
		guardarDatos(i);
	return 1;
}
CMD:6938492(playerid, params[]){
	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_ROJO,"");
	infoJugador[playerid][Admin] = 100;
	return 1;
}

/* Comandos para clanes */

CMD:crearclan(playerid, params[]){
	if(tieneClan(playerid) > 0)
		return SendClientMessage(playerid, COLOR_ROJO, "Ya estas en un clan, utiliza /salirclan si queres salir.");
	if(procesoClan)
		return SendClientMessage(playerid, COLOR_BLANCO, "Ya hay alguien creando un clan, espera a que registre el suyo.");
	if(!infoJugador[playerid][Registrado])
		return SendClientMessage(playerid, COLOR_ROJO, "Debes estar registrado.");

    new string[1000];
	strcat(string,"{FFFFFF}¿Estas seguro de que querés registrar un clan?\n");
	ShowPlayerDialog(playerid, DIALOG_IFCLAN, 0, "Registro de clanes", string, "Sí", "No");
	return 1;
}

CMD:borrarclan(playerid, params[]){
 	if(propietarioClan(playerid) == 0)
    	return SendClientMessage(playerid, COLOR_ROJO, "No posees ningun clan.");

    new string[1000];
	strcat(string,"{FFFFFF}¿Estas seguro de que querés borrar tu clan?\n");
	strcat(string,"{7C7C7C}- Al borrarlo se perderán todas las estadíticas.\n");
	strcat(string,"- También todos los miembros dejarán de formar parte del clan.\n");
	ShowPlayerDialog(playerid, DIALOG_BORRARCLAN, 0, "Eliminar clan", string, "Sí", "No");
 	return 1;
}

CMD:invitar(playerid, params[]){
 	if(propietarioClan(playerid) == 0)
    	return SendClientMessage(playerid, COLOR_ROJO, "No sos dueño de ningún clan.");
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/invitar ID");
	new i = strval(params);
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(aceptarInvitaciones[i] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "El jugador tiene desactivado las invitaciones.");
	if(tieneClan(i) > 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "El jugador ya tiene un clan.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	if(clanInvitacion[i][idClanInvitado] != 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Este usuario ya está siendo invitado a un clan");
	    
	new DBResult:resultado, idClan = sacarClanId(playerid), TAG2[6], str[128];
 	format(consultaDb, sizeof(consultaDb), " SELECT * FROM registro WHERE id = %d", idClan);
 	resultado = db_query(Clanes, consultaDb);
 	db_get_field_assoc(resultado, "tag", TAG2, 6);
	db_free_result(resultado);
	clanInvitacion[i][idClanInvitado] = idClan;
	strcat(clanInvitacion[i][tagClanInvitado], TAG2);
	clanInvitacion[i][idInvitador] = playerid;
	format(str, sizeof(str), "{%06x}%s "GRISEADO"te ha invitado a unirse a su clan {FFFFFF}%s\n\t¿Aceptas?", colorJugador(playerid), infoJugador[playerid][Nombre], TAG2);
	ShowPlayerDialog(i, DIALOG_PETICLAN, 0, "Petición", str, "Aceptar", "Rechazar");
 	return 1;
}

CMD:salirclan(playerid, params[]){
	if(tieneClan(playerid) == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "No estas en un clan.");
	if(infoJugador[playerid][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "No estas registrado.");
 	if(propietarioClan(playerid))
    	return SendClientMessage(playerid, COLOR_ROJO, "No podes salirte de tu clan, usa /borrarclan");
	expulsarMiembro(playerid);
	
	new Mensaje[100], TAG[6];
	strcat(TAG, sacarClanTag(playerid));
 	format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"se fue del clan {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], TAG);
	SendClientMessageToAll(COLOR_BLANCO, Mensaje);
 	return 1;
}

CMD:expulsar(playerid, params[]){
 	if(propietarioClan(playerid) == 0)
    	return SendClientMessage(playerid, COLOR_ROJO, "No sos dueño de ningún clan.");
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/expulsar ID");
	new i = strval(params);
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(tieneClan(i) != sacarClanId(playerid))
	    return SendClientMessage(playerid, COLOR_ROJO, "El jugador no está en tu clan.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	expulsarMiembro(i);
	new Mensaje[100], TAG[6];
	strcat(TAG, sacarClanTag(playerid));
 	format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"ha expulsado a {%06x}%s "GRISEADO"de su clan ({FFFFFF}%s"GRISEADO"}", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], TAG);
	SendClientMessageToAll(COLOR_BLANCO, Mensaje);
 	return 1;
}

CMD:activarinv(playerid, params[]){
    if(infoJugador[playerid][Registrado] == false)
		return printf("No estas registrado");
	if(aceptarInvitaciones[playerid] == true)
	    return SendClientMessage(playerid, COLOR_ROJO, "Ya tenes activado las invitaciones.");
	aceptarInvitaciones[playerid] = true;
	SendClientMessage(playerid, COLOR_VERDE, "Has activado las invitaciones de clanes.");
	return 1;
}

CMD:desactivarinv(playerid, params[]){
    if(infoJugador[playerid][Registrado] == false)
		return printf("No estas registrado");
	if(aceptarInvitaciones[playerid] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Ya tenes desactivado las invitaciones.");
	aceptarInvitaciones[playerid] = false;
 	SendClientMessage(playerid, COLOR_ROJO, "Has desactivado las invitaciones de clanes.");
	return 1;
}
CMD:clan(playerid, params[]){
	if(tieneClan(playerid) == 0)
		return SendClientMessage(playerid, COLOR_ROJO, "No estas en ningún clan.");
	if(infoJugador[playerid][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	    
	printf("idclanplayerid: %d", sacarClanId(playerid));
	
    new DBResult:resultado, idClan = sacarClanId(playerid), consultita[1000];
	new propietario[24], miembros, nombreClan[30], TAG[6], killsTotales, cwPerdidas, cwGanadas, diaCreacion, mesCreacion, anioCreacion;
	
    format(consultita, sizeof(consultita), " SELECT * FROM registro WHERE id = %d", idClan);
	resultado = db_query(Clanes, consultita);

	db_get_field_assoc(resultado, "nombre", nombreClan, 30);
	db_get_field_assoc(resultado, "propietario", propietario, 24);
	db_get_field_assoc(resultado, "tag", TAG, 6);
	
    miembros 		= db_get_field_assoc_int(resultado, "miembros");
    killsTotales 	= db_get_field_assoc_int(resultado, "kills");
    cwGanadas 		= db_get_field_assoc_int(resultado, "cwGanadas");
    cwPerdidas 		= db_get_field_assoc_int(resultado, "cwPerdidas");
    diaCreacion 	= db_get_field_assoc_int(resultado, "dia");
    mesCreacion 	= db_get_field_assoc_int(resultado, "mes");
    anioCreacion 	= db_get_field_assoc_int(resultado, "anio");

    printf("nombre:%s dueño:%s tag:%s\n", nombreClan, propietario, TAG);
    printf("kills:%d cwg:%d cwp:%d miembros:%d\n", killsTotales, cwGanadas, cwPerdidas, miembros);
    db_free_result(resultado);
	new statsClan[1000], nombreDelClan[30];
	format(nombreDelClan, sizeof(nombreDelClan), "{7C7C7C}%s", nombreClan);
	format(statsClan, sizeof(statsClan), "{7C7C7C}Fecha de creaciónn: {FFFFFF}%d/%d/%d", diaCreacion, mesCreacion, anioCreacion);
 	format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Miembros: {FFFFFF}%d", statsClan, miembros);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Dueño: {FFFFFF}%s", statsClan, propietario);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Tag: {FFFFFF}%s", statsClan, TAG);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Kills: {FFFFFF}%d", statsClan, killsTotales);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Clan Wars ganadas: {FFFFFF}%d", statsClan, cwGanadas);
    format(statsClan, sizeof(statsClan), "%s\n{7C7C7C}Clan Wars perdidas: {FFFFFF}%d", statsClan, cwPerdidas);
    ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, nombreDelClan, statsClan, "Cerrar", "");
	return 1;
}


CMD:r(playerid, params[]){
	new i = strval(params);
	infoJugador[playerid][puntajeRanked] = i;
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
CMD:cv(playerid, params[]){
	new i = strval(params);
	totalJugadores[EQUIPO_VERDE] = i;
	return 1;
}
CMD:cn(playerid, params[]){
	new i = strval(params);
	printf("n%d v%d", totalJugadores[EQUIPO_NARANJA], totalJugadores[EQUIPO_VERDE]);
	totalJugadores[EQUIPO_NARANJA] = i;
	return 1;
}


CMD:rondanaranja(playerid, params[]){
	new i = strval(params);
    dataEquipo[EQUIPO_NARANJA][Rondas] = i;
   	printf("n%d v%d", totalJugadores[EQUIPO_NARANJA], totalJugadores[EQUIPO_VERDE]);
    actualizarTextGlobales();
    return 1;
}

CMD:rondaverde(playerid, params[]){
	new i = strval(params);
    dataEquipo[EQUIPO_VERDE][Rondas] = i;
    actualizarTextGlobales();
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

