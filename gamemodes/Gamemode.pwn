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

/* - Arenas de duelos - */

#define ARENA_WAREHOUSE         1
#define ARMAS_RAPIDAS           1
#define ARMAS_LENTAS            2

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
#define DIALOG_SEQUIPO     		6   /* Seleccionar equipo */
#define DIALOG_CREDITOS     	7
#define DIALOG_IFCLAN       	8   /* Verificación de crear un clan */
#define DIALOG_INCLAN       	9   /* Ingresar nombre del clan */
#define DIALOG_TGCLAN       	10  /* Ingresar tag del clan */
#define DIALOG_BORRARCLAN   	11  /* Verificaciónde borrar un clan */
#define DIALOG_PETICLAN     	12  /* Invitación de un clan */
#define DIALOG_CJUGADOR  		13
#define DIALOG_CESPECTADOR  	14
#define DIALOG_CADPARTIDAS      15
#define DIALOG_TOP          	30
#define DIALOG_TOPRANKED    	31
#define DIALOG_TOPDUELOSG   	32  /* Duelos ganados */
#define DIALOG_TOPDUELOSP   	33  /* Duelos perdidos */
#define DIALOG_TOPCKILLS    	34  /* Clan kills */
#define DIALOG_TOPCWGANADAS 	35
#define DIALOG_TOPCWPERD    	36
#define DIALOG_MODOJUEGO    	37
#define DIALOG_SELECMAPA    	38
#define DIALOG_DUELOARENAS      39

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

new estaEnDuelo[MAX_PLAYERS];
new jugadoresArena[2],
	Float:warehouseSpawns[][] =
	{
		{1361.3468, -46.1324, 1000.9240},
		{1408.0518, -34.1221, 1001.1148},
		{1414.5874, 1.0335, 1002.1307},
		{1363.0325, 0.7593, 1001.6202},
		{1392.8837, -25.6937, 1000.2111}
	};
	
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
new tipoArmas[MAX_PLAYERS];
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
	
	
new marcadores[12],
	Float:spawnMarcadores[11][4] =
	{
 		{320.31, -2833.04, 21.24, -180.0},    	/* Omega */
 		{1098.42, 1281.47, 12.5,90.0},      	/* Las Venturas */
 		{751.61, -2777.31, 15.5, 90.0},     	/* Jardin Mágico */
 		{1590.75, 1522.60, 12.91,-140.0},   	/* Aero LV */
 		{-1335.29, -636.29, 16.17, 180.0},
 		{-1396.88, -636.29, 16.17, 180.0},
 		{-1234.09, -84.41, 16.39,-44.94},
 		{2007.66, -2230.02, 16.15,0.00},  /* LS */
 		{1921.54, -2231.34, 16.15,0.00},  /* LS */
 		{-2096.01, -188.82, 37.45,90.04},
 		{-2011.62, -189.27, 37.45,-90.04}
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
	Baneado,
	Pais[80],
	bool:Registrado
};
new infoJugador[MAX_PLAYERS][Data];

new Text:tituloServer, Text:nombreEquipos, Text:puntajeEquipos, Text:partidaRondas;
new Text:fondoUnoEntrada, Text:toxicWarriorsEntrada, Text:versionEntrada, Text:fondoDosEntrada;
new PlayerText:mostrarFps[MAX_PLAYERS], PlayerText:mostrarPing[MAX_PLAYERS];
new PlayerText:mostrarKills[MAX_PLAYERS], PlayerText:mostrarMuertes[MAX_PLAYERS], PlayerText:mostrarRatio[MAX_PLAYERS];


/* Resultados CW */

new Text:fondoResultado;
new Text:textoResultado;
new Text:textoEquipoNaranja;
new Text:textoEquipoVerde;
new Text:textoNickNaranja;
new Text:textoDataNaranja;
new Text:nicksNaranja;
new Text:killsNaranja;
new Text:muertesNaranja;
new Text:ratiosNaranja;
new Text:textoNickVerde;
new Text:nicksVerde;
new Text:textoDataVerde;
new Text:killsVerde;
new Text:muertesVerde;
new Text:ratiosVerde;

new Text:fondoInfoPartida;
new Text:textoEquipoGanador;


new Text:fondoResultado1vs1;
new Text:textoResultado1vs1;
new Text:nombreNaranja1vs1;
new Text:nombreVerde1vs1;
new Text:textoVersus1vs1;
new Text:dataNara1vs1;
new Text:dataVerd1vs1;
new Text:killsNara1vs1;
new Text:muertesNara1vs1;
new Text:ratioNara1vs1;
new Text:killsVerd1vs1;
new Text:muertesVerd1vs1;
new Text:ratioVerd1vs1;
new Text:fondoInfo1vs1;
new Text:textoInfo1vs1;

forward ocultarResultados();
public ocultarResultados(){
 	ocultarTextResultadoCW();
 	ocultarTextResultado1vs1();
    ForPlayers(i){
        if(Equipo[i] != EQUIPO_ESPECTADOR)
			TogglePlayerControllable(i, 1);
	}
	return 1;
}
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
	estaEnDuelo[playerid] = 0;
	tipoArmas[playerid] = 0;
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
		asignacion = db_query(Cuentas, "CREATE TABLE IF NOT EXISTS cuentas (id INTEGER PRIMARY KEY AUTOINCREMENT, nick TEXT, password TEXT, ip INTEGER, nivelAdmin INTEGER, puntajeRanked INTEGER, duelosGanados INTEGER, duelosPerdidos INTEGER, clan INTEGER, baneado INTEGER, pais TEXT)");
		db_free_result(asignacion);
	}else print("Cuentas db no se pudo abrir");
	if(Clanes){
		printf("Clanes db abierto");
		asignacion = db_query(Clanes, "CREATE TABLE IF NOT EXISTS registro (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT, tag TEXT, propietario TEXT, kills INTEGER, muertes INTEGER, cwGanadas INTEGER, cwPerdidas INTEGER, miembros INTEGER, dia INTEGER, mes INTEGER, anio INTEGER)");
        	db_free_result(asignacion);
	}else printf("Clanes db no se pudo abrir");

	
 	tituloServer = TextDrawCreate(100, 428, "CLAN WAR & TRAINING (RUNNING WEAPONS)");
	TextDrawLetterSize(tituloServer, 0.200000, 1.000000);
	TextDrawTextSize(tituloServer, 428.000000, 0.000000);
	TextDrawAlignment(tituloServer, 1);
	TextDrawColor(tituloServer, -1);
	TextDrawSetShadow(tituloServer, 0);
	TextDrawSetOutline(tituloServer, 1);
	TextDrawBackgroundColor(tituloServer, 0x000000AA);
	TextDrawFont(tituloServer, 2);
	TextDrawSetProportional(tituloServer, 1);
	
	crearTextDrawsCW();
	crearTextDrawsEntrada();
	crearTextResultado1vs1();
    crearTextResultadoCW();
    actualizarMarcador();
    
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

stock actualizarArenaJugador(playerid){
    if(estaEnDuelo[playerid] != 0){
		new i = estaEnDuelo[playerid];
		tipoArmas[playerid] = 0;
		jugadoresArena[i]--;
		estaEnDuelo[playerid] = 0;
    }
}

stock mostrarMensajeDueloTerminado(playerid, killerid){
 	if(estaEnDuelo[playerid] != 0 && estaEnDuelo[killerid] != 0){
 	
		new Float:Vida, Float:Armor, s[2000], armasUsadas = 0;
		if(tipoArmas[playerid] == tipoArmas[killerid])
		    armasUsadas = tipoArmas[playerid];
		else
		    armasUsadas = 0;
		    
		GetPlayerHealth(killerid, Vida); GetPlayerArmour(killerid, Armor);
		format(s, sizeof(s), "%s {C3C3C3}ganó el duelo contra {FFFFFF}%s {C3C3C3}[V: {FFFFFF}%.2f /C: {FFFFFF}%.2f] a armas %s", infoJugador[killerid][Nombre], infoJugador[playerid][Nombre], Vida, Armor, nombreArmas(armasUsadas));
		SendClientMessageToAll(COLOR_BLANCO, s);
		infoJugador[killerid][duelosGanados]++;
		infoJugador[playerid][duelosPerdidos]++;
		SpawnPlayer(killerid);
		guardarDatos(playerid);
		guardarDatos(killerid);
	}
}

stock nombreArmas(id){
	new s[10];
	if(id == ARMAS_RAPIDAS)
		format(s, 10, "RW");
	if(id == ARMAS_LENTAS)
	    format(s, 10, "WW");
	if(id == 0)
	    format(s, 10, "RW/WW");
	return s;
}

stock actualizarModoDeJuego(){
	new id = totalJugadores[EQUIPO_NARANJA], id2 = totalJugadores[EQUIPO_VERDE], aux = 0;
	if(id == 1 && id2 == 1){
		if(modoDeJuego != UNO_VS_UNO){
	    		modoDeJuego = UNO_VS_UNO;
	    		aux = 1;
		}else
			modoDeJuego = UNO_VS_UNO;
	}else{
	    if(modoDeJuego != ENTRENAMIENTO){
 		 	modoDeJuego = ENTRENAMIENTO;
  			aux = 1;
	    }
	}
	if(aux != 0) SCMTAF(COLOR_BLANCO,"{FFFFFF}Server"GRISEADO" ha cambiado el modo de juego a {FFFFFF}%s", nombreModo());
}

stock actualizarMarcador(){
	new str[200];
	format(str, 200, "{FF8B00}%d{FFFFFF}:{007C0E}%d{FFFFFF}\n{E17B00}%d{FFFFFF}:{005904}%d{FFFFFF}",
	dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje], dataEquipo[EQUIPO_NARANJA][Rondas], dataEquipo[EQUIPO_VERDE][Rondas]);
	for(new i; i < 11;i++){
		DestroyObject(marcadores[i]);
		marcadores[i] = CreateObject(7914, spawnMarcadores[i][0], spawnMarcadores[i][1], spawnMarcadores[i][2],   0.00, 0.00,  spawnMarcadores[i][3]);
		SetObjectMaterialText(marcadores[i],str, 0, OBJECT_MATERIAL_SIZE_256x128, "Arial", 60, 0, 0x00000000, 0x00000000, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);
	}
}
stock actualizarTextGlobales(){
	new string[124];
	eliminarTextDrawsPartida();
	
	if(modoDeJuego == UNO_VS_UNO){
		crearTextdraws1vs1();
		new jugadorNaranja = idJugadorNaranja(), jugadorVerde = idJugadorVerde();
    		format(string, sizeof(string), "~y~%s vs ~g~%s", infoJugador[jugadorNaranja][Nombre], infoJugador[jugadorVerde][Nombre]);
    	}else{
			crearTextDrawsCW();
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

stock eliminarListaDeKills(){ for(new l=0; l<6; l++) SendDeathMessage(202, 202, 202); }

stock resetearPuntos(){ for(new i=0;i<2;i++) dataEquipo[i][Puntaje] = 0; }

stock resetearRondas(){ for(new i=0;i<2;i++) dataEquipo[i][Rondas] = 0; }

stock resetearTodo(){
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

stock paisJugador(playerid){
	new s[80];
	GetPlayerCountry(playerid, s, sizeof(s));
	return s;
}
stock colorJugador(playerid){
	return GetPlayerColor(playerid) >>> 8;
}

public OnPlayerConnect(playerid)
{
	if(playerid > Conectados) Conectados = playerid;
	
	actualizarClanRegitro();
	establecerVariables(playerid);
	establecerJugadores();
	
	infoJugador[playerid][Nombre] = nombre(playerid);
	infoJugador[playerid][ip] = IP(playerid);
	
	new DBResult:resultado, bool:real = false;
	format(consultaDb, sizeof(consultaDb), "SELECT * FROM cuentas WHERE ip = '%s'", infoJugador[playerid][ip]);
	resultado = db_query(Cuentas, consultaDb);
	if(db_num_rows(resultado)){
	    new nombreAux[30], cuentaBaneada = 0;
	    db_get_field_assoc(resultado, "nick", nombreAux, sizeof(nombreAux));
 		cuentaBaneada = db_get_field_assoc_int(resultado, "baneado");
	    printf("nombre sacado: %s. nombre real %s", nombreAux, infoJugador[playerid][Nombre]);
		if(strcmp(infoJugador[playerid][Nombre], nombreAux, true) != 0){
		    printf("nombre repetido");
		    new str[128];
			format(str, sizeof(str), ""GRISEADO"[Anti-fake]: {%06x}%s ({%06x}%s"GRISEADO") no pudo conectarse al servidor.", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(playerid), paisJugador(playerid));
			SendClientMessageToAll(colorJugador(playerid), str);
			Kick(playerid);
		}else if(cuentaBaneada == 1){
		    printf("Cuenta baneada");
		    new str[128];
			format(str, sizeof(str), ""GRISEADO"[Baneado]: {%06x}%s ({%06x}%s"GRISEADO") no pudo conectarse al servidor.", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(playerid), paisJugador(playerid));
			SendClientMessageToAll(colorJugador(playerid), str);
			Kick(playerid);
		}else
		    real = true;
	}
	if(real){
		new Mensaje[100];
		format(Mensaje, sizeof(Mensaje), "%s "GRISEADO"se conectó al servidor ({%06x}%s"GRISEADO")", infoJugador[playerid][Nombre], colorJugador(playerid), paisJugador(playerid));
		SendClientMessageToAll(COLOR_BLANCO, Mensaje);
	}
	db_free_result(resultado);
	
	format(consultaDb, sizeof(consultaDb), "SELECT * FROM cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
	resultado = db_query(Cuentas, consultaDb);
	
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
	actualizarArenaJugador(playerid);
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
			new selece[2048];
			switch(listitem){
				case 0:
				{
					strcat(selece, ""GRISEADO"/{FFFFFF}equipo\t"GRISEADO"- Cambias de equipo (switch)."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}x1\t"GRISEADO"- Vas a una arena de duelo.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}kill\t"GRISEADO"- Te suicidas por pendejo.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}top\t"GRISEADO"- Lista de tops del servidor, clanes y jugadores."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}creditos\t"GRISEADO"- Información sobre el servidor.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}admins\t"GRISEADO"- Lista de administradores conectados."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}inforangos\t"GRISEADO"- Información sobre el sistema ranked."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}infoclanes\t"GRISEADO"- Información sobre el sistema de clanes, leelo si vas a crear uno.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}desinv\t"GRISEADO"- Desactivas las invitaciones que te lleguen de clanes.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}actinv\t"GRISEADO"- Activas las invitaciones que te lleguen de clanes."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}crearclan\t"GRISEADO"- Registras tu clan, vos seras el dueño."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}borrarclan\t"GRISEADO"- Eliminas tu clan y a los miembros.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}salirclan\t"GRISEADO"- Te salis del clan en el que estas."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}invitar "GRISEADO"[id]\t"GRISEADO"- Invitas a alguien para que sea miembro de tu clan.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}expulsar "GRISEADO"[id]\t"GRISEADO"- Expulsas a un miembro de tu clan."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}skin "GRISEADO"[id]\t"GRISEADO"- Cambias tu skin, al salirte no se te guardará."); 
					strcat(selece, "\n"GRISEADO"/{FFFFFF}stats "GRISEADO"[id]\t"GRISEADO"- Estadítica de un jugador, podes sacar la id para ver los tuyos.");
   					strcat(selece, "\n"GRISEADO"/{FFFFFF}fps "GRISEADO"[id]\t"GRISEADO"- Te dice la cantidad de fps de un jugador.");
   					strcat(selece, "\n"GRISEADO"/{FFFFFF}pl "GRISEADO"[id]\t"GRISEADO"- Te dice la cantidad de packet loss de un jugador.");
   					strcat(selece, "\n"GRISEADO"/{FFFFFF}pm "GRISEADO"[id] [texto]\t"GRISEADO"- Envias un mensaje privado a un jugador.");
					ShowPlayerDialog(playerid, DIALOG_CJUGADOR, DIALOG_STYLE_TABLIST, "Comandos para jugadores", selece, "Volver", "Cerrar");
				}
				case 1:
				{
					strcat(selece, ""GRISEADO"No disponible todavia");
    				ShowPlayerDialog(playerid, DIALOG_CJUGADOR, DIALOG_STYLE_TABLIST, "Comandos para espectadores", selece, "Volver", "Cerrar");
				}
   				case 2:
				{
					strcat(selece, ""GRISEADO"/{FFFFFF}modo\t"GRISEADO"- Cambias el modo de juego.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}mapa\t"GRISEADO"- Cambias el mapa del servidor (solo en entrenamiento).");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}fpsall\t"GRISEADO"- Muestra los fps de todos los jugadores.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}plall\t"GRISEADO"- Muestra el packetloss de todos los jugadores.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}hpall\t"GRISEADO"- Establece la vida de todos los jugadores.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}armourall\t"GRISEADO"- Establece la armadura de todos los jugadores.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}spawnall\t"GRISEADO"- Respawnea a todos los jugadores.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}spawn "GRISEADO"[id]\t"GRISEADO"- Spawneas a un jugador específico.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}hp "GRISEADO"[id] [num]\t"GRISEADO"- Estableces la cantidad de vida a un jugador.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}armour "GRISEADO"[id] [num]\t"GRISEADO"- Estableces la cantidad de armadura a un jugador.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}naranja "GRISEADO"[id]\t"GRISEADO"- Cambias a un jugador al equipo naranja.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}verde "GRISEADO"[id]\t"GRISEADO"- Cambias a un jugador al equipo verde.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}espectador "GRISEADO"[id]\t"GRISEADO"- Cambias a un jugador al equipo espectador.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}rondas "GRISEADO"[num]\t"GRISEADO"- Estableces la maxima cantidad de rondas que se podrá jugar.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}puntajederonda "GRISEADO"[num]\t"GRISEADO"- Estableces la maxima cantidad de puntaje para que se termine la ronda.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}rondasnaranja "GRISEADO"[num]\t"GRISEADO"- Estableces la cantidad de rondas del equipo naranja.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}puntajenaranja "GRISEADO"[num]\t"GRISEADO"- Estableces la cantidad de puntaje del equipo naranja.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}rondasverde "GRISEADO"[num]\t"GRISEADO"- Estableces la cantidad de rondas del equipo verde.");
					strcat(selece, "\n"GRISEADO"/{FFFFFF}puntajeverde "GRISEADO"[num]\t"GRISEADO"- Estableces la cantidad de puntaje del equipo verde.");
    				ShowPlayerDialog(playerid, DIALOG_CADPARTIDAS, DIALOG_STYLE_TABLIST, "Comandos para Adm. de partida", selece, "Volver", "Cerrar");
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
   				mostrarTextDrawsEntrada(playerid);
        	}
        }
   	case DIALOG_LOGEAR:
        {
            if(!response) return Kick(playerid);
            if(isnull(inputtext) || !strcmp(inputtext, "0")) return ShowPlayerDialog(playerid, DIALOG_LOGEAR, DIALOG_STYLE_PASSWORD, ""ROJO"Error de conexión", "{7C7C7C}La {FFFFFF}contraseña {7C7C7C}que introduciste es "ROJO"errónea{7C7C7C}, intentalo devuelta.\n", "Logear", "Salir");
            if(!strcmp(infoJugador[playerid][Password], inputtext, true, 20)){
				infoJugador[playerid][Registrado] = true;
				cargarDatos(playerid);
   				mostrarTextDrawsEntrada(playerid);
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
				establecerJugadores();
				actualizarModoDeJuego();
 				actualizarTextGlobales();
 				actualizarMarcador();
        		establecerColor(playerid);
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
        		    case 0: mostrarTopRankedMundial(playerid);
        		    case 1: mostrarTopRankedMundial(playerid);
					case 2: mostrarTopDuelosGanados(playerid);
					case 3: mostrarTopDuelosPerdidos(playerid);
					case 4: mostrarTopClanKills(playerid);
					case 5: mostrarTopClanCWG(playerid);
					case 6: mostrarTopClanCWP(playerid);
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
			    establecerJugadores();
   				printf("%d naranja, %d verde", totalJugadores[EQUIPO_NARANJA], totalJugadores[EQUIPO_VERDE]);
   				respawnearJugadores();
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
    					actualizarMarcador();
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
                        actualizarMarcador();
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
                        actualizarMarcador();
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
					}
  					case 1:
		            {
		                if(mapaElegido == AEROPUERTO_LV){
              				ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", "{00779E}Las venturas\n"ROJO"Aeropuerto LV\n{00779E}Aeropuerto SF\n{00779E}Auto escuela", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este mapa.");
		                }
		                mapaElegido = AEROPUERTO_LV;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el mapa a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreMapa(mapaElegido));
					}
  					case 2:
		            {
		                if(mapaElegido == AEROPUERTO_SF){
              				ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", "{00779E}Las venturas\n{00779E}Aeropuerto LV\n"ROJO"Aeropuerto SF\n{00779E}Auto escuela", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este mapa.");
		                }
		                mapaElegido = AEROPUERTO_SF;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el mapa a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreMapa(mapaElegido));
					}
  					case 3:
		            {
		                if(mapaElegido == AUTO_ESCUELA){
              				ShowPlayerDialog(playerid, DIALOG_SELECMAPA, DIALOG_STYLE_LIST, ""GRISEADO"Mapas del servidor", "{00779E}Las venturas\n{00779E}Aeropuerto LV\n{00779E}Aeropuerto SF\n"ROJO"Auto escuela", "Selec.", "Cancelar");
                            return SendClientMessage(playerid, COLOR_ROJO, "Ya esta puesto este mapa.");
		                }
		                mapaElegido = AUTO_ESCUELA;
						SCMTAF(COLOR_BLANCO,"{%06x}%s"GRISEADO" ha cambiado el mapa a {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreMapa(mapaElegido));
					}
		        }
   				actualizarTextGlobales();
        		actualizarMarcador();
          		resetearTodosJugadores();
		    }
		}
		case DIALOG_DUELOARENAS:
		{
		    if(response){
		        switch(listitem){
		            case 0:
		            {
		                new c = jugadoresArena[ARENA_WAREHOUSE];
		                if(c == 2)
							return SendClientMessage(playerid, COLOR_ROJO, "Ya hay un duelo en curso en esta arena.");
						else{
						    estaEnDuelo[playerid] = ARENA_WAREHOUSE;
						    tipoArmas[playerid] = ARMAS_RAPIDAS;
                            jugadoresArena[ARENA_WAREHOUSE]++;
                            printf("%d jugador, %d arena", estaEnDuelo[playerid], jugadoresArena[ARENA_WAREHOUSE]);
                            SetPlayerVirtualWorld(playerid,3);
                    		SetPlayerInterior(playerid,1);
                      		new Random = random(sizeof(warehouseSpawns));
                    		SetPlayerPos(playerid, warehouseSpawns[Random][0], warehouseSpawns[Random][1], warehouseSpawns[Random][2]);
                            darArmasRW(playerid);
                      		SetPlayerHealth(playerid, 100);
                      		SetPlayerArmour(playerid, 100);
						}
		            }
		        }
				if(estaEnDuelo[playerid] != 0){
				    new s[256];
				    format(s, sizeof(s), "{%06x}%s"GRISEADO" fue a la arena {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], nombreArenaX1(estaEnDuelo[playerid]));
     				SendClientMessageToAll(COLOR_BLANCO, s);
				}
		    }
		}
  	}
    return 1;
}
//, kills, cwGanadas, cwPerdidas, miembros


stock darArmasRW(playerid){
	ResetPlayerWeapons(playerid);
	GivePlayerWeapon(playerid, 22, 9999);
	GivePlayerWeapon(playerid, 28, 9999);
	GivePlayerWeapon(playerid, 26, 9999);
}

stock darArmasWW(playerid){
	ResetPlayerWeapons(playerid);
	GivePlayerWeapon(playerid, 24, 9999);
	GivePlayerWeapon(playerid, 25, 9999);
	GivePlayerWeapon(playerid, 34, 9999);
}

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
       	new Mensaje[200];
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
			clanInvitacion[playerid][idClanInvitado] = 0;
			strcat(clanInvitacion[playerid][tagClanInvitado], "");
			clanInvitacion[playerid][idInvitador] = 0;
	    }
	}
}

actualizarClanRegitro(){
	new DBResult:resultado, anio, mesActual, diaActual;
	getdate(anio, mesActual, diaActual);
	format(consultaDb, sizeof(consultaDb), "DELETE FROM registro WHERE (%d-dia) >= 3 and miembros == 1", diaActual);
	resultado = db_query(Clanes, consultaDb);
	db_free_result(resultado);
	//SendClientMessageToAll(COLOR_BLANCO, ""GRISEADO"El servidor ha eliminado algunos clanes por inactividad.");
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
    return ShowPlayerDialog(playerid, DIALOG_TOP, DIALOG_STYLE_LIST, "{7C7C7C}Tops", "{00779E}Ranked Mundial\n{00779E}Ranked Nacional (No hay jugadores suficientes)", "Selec.", "Cancelar");
}
//{00779E}Clan kills\n{00779E}Clan Wars Ganadas\n{00779E}Clan Wars Perdidas
//{00779E}Duelos ganados\n{00779E}Duelos perdidos


mostrarTopRankedMundial(playerid){
	new i = 1, selece[1024], string[128];
	new DBResult:resultado, Puntos, nNick[40], nPais[80];
    resultado = db_query(Cuentas, "SELECT nick, puntajeRanked, pais FROM cuentas WHERE puntajeRanked > 0 ORDER BY puntajeRanked DESC LIMIT 20");
    if(db_num_rows(resultado)){
        strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Puntos\t{7C7C7C}Nick\t{7C7C7C}Pais");
		do{
			Puntos = db_get_field_assoc_int(resultado, "puntajeRanked");
			db_get_field_assoc(resultado, "nick", nNick, sizeof(nNick));
			db_get_field_assoc(resultado, "pais", nPais, sizeof(nPais));
			format(string, sizeof(string), "\n{7C7C7C}%d\t%d\t{FFFFFF}%s\t%s", i, Puntos, nNick, nPais);
			strcat(selece, string);
			i++;
		}while(db_next_row(resultado));
		db_free_result(resultado);
		ShowPlayerDialog(playerid, DIALOG_TOPRANKED, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}Ranked", selece, "Volver", "Cerrar");
	}
}

mostrarTopDuelosGanados(playerid){
	new i = 1, selece[1024], string[128];
	new DBResult:resultado, Duelos, nNick[24];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY duelosGanados DESC LIMIT 20");
    if(db_num_rows(resultado)){
        strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Duelos");
		do{
			Duelos = db_get_field_assoc_int(resultado, "duelosGanados");
			db_get_field_assoc(resultado, "nick", nNick, sizeof(nNick));
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
	new i = 1, selece[1024], string[128];
	new DBResult:resultado, Duelos, nNick[24];
    resultado = db_query(Cuentas, "SELECT * FROM cuentas ORDER BY duelosPerdidos DESC LIMIT 20");
    if(db_num_rows(resultado)){
    	strcat(selece, "{7C7C7C}pos.\t{7C7C7C}Nick\t{7C7C7C}Duelos");
		do{
			Duelos = db_get_field_assoc_int(resultado, "duelosPerdidos");
			db_get_field_assoc(resultado, "nick", nNick, sizeof(nNick));
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
	new i = 1, selece[1024], string[128];
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
	new i = 1, selece[1024], string[128];
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
	new i = 1, selece[1024], string[128];
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
	new DBResult:resultado, TAG[8], idClan = sacarClanId(playerid);
    format(consultaDb, sizeof(consultaDb), "SELECT tag FROM registro WHERE id = %d", idClan);
    resultado = db_query(Clanes, consultaDb);
    if(db_num_rows(resultado))
    	db_get_field_assoc(resultado, "tag", TAG, sizeof(TAG));
	db_free_result(resultado);
	return TAG;
}

clanTextoValido(celda[], nombre[]){
    new DBResult:resultado;
    format(consultaDb, sizeof(consultaDb), "SELECT * FROM registro WHERE %s = '%s'", celda, nombre);
    resultado = db_query(Clanes, consultaDb);
	return db_num_rows(resultado);
}
registrarDatos(playerid)
{
    new str[80];
    format(consultaDb, sizeof(consultaDb), "INSERT INTO cuentas (nick, password, ip, nivelAdmin, puntajeRanked, duelosGanados, duelosPerdidos, clan, baneado, pais) VALUES ");
    format(str, sizeof(str), "('%s',", infoJugador[playerid][Nombre]);		strcat(consultaDb, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][Password]);     strcat(consultaDb, str);
    format(str, sizeof(str), "'%s',", infoJugador[playerid][ip]);     		strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "0,");     									strcat(consultaDb, str);
    format(str, sizeof(str), "'%s')", paisJugador(playerid));     			strcat(consultaDb, str);
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
    infoJugador[playerid][Baneado] 			= 0;
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
        	infoJugador[playerid][Baneado] 			= db_get_field_assoc_int(resultado, "baneado");
			strcat(infoJugador[playerid][Pais], paisJugador(playerid));
   	 	}
    	db_free_result(resultado);
    	infoJugador[playerid][Registrado] = true;
		SendClientMessage(playerid, COLOR_VERDE, "Has logeado correctamente (stats cargados)");
		printf("pais: %s",infoJugador[playerid][Pais]);
		guardarDatos(playerid);
	}
	return 1;
}

guardarDatos(playerid)
{
    if(infoJugador[playerid][Registrado] == false)
		return printf("El jugador no esta registrado");
		
    new str[256], consulta[256];
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
	format(str, sizeof(str), "clan = %d,", infoJugador[playerid][Clan]);
	strcat(consulta, str);
	format(str, sizeof(str), "pais = '%s',", paisJugador(playerid));
	strcat(consulta, str);
	format(str, sizeof(str), "baneado = %d", infoJugador[playerid][Baneado]);
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
	}else if(rangoGanador > rangoPerdedor){
	    puntosGanador = 2;
	    puntosPerdedor = 2;
	}else if(rangoGanador < rangoPerdedor){
	    puntosGanador = 12;
	    puntosPerdedor = 12;
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
        format(str, sizeof(str), ""GRISEADO"No se te resto puntos porque no tenes ({FFFFFF}-%d{FFFFFF})", puntosPerdedor, infoJugador[perdedor][puntajeRanked]);
 	else
 	    format(str, sizeof(str), ""GRISEADO"Se te restó {FFFFFF}-%d "GRISEADO"puntos por tu derrota ({FFFFFF}%d{FFFFFF})", puntosPerdedor, infoJugador[perdedor][puntajeRanked]);
 	SendClientMessage(perdedor, COLOR_BLANCO, str);
 	guardarDatos(ganador);
 	guardarDatos(perdedor);
}

stock crearResultado1vs1(ganador){
	eliminarListaDeKills();
	new str[24], str2[24];
	ForPlayers(i){
	    if(Equipo[i] == EQUIPO_NARANJA){
			format(str, 24, "%s", infoJugador[i][Nombre]);
			TextDrawSetString(nombreNaranja1vs1, str);
			format(str, 24, "%d", killsJugador[i]);
			TextDrawSetString(killsNara1vs1, str);
			format(str, 24, "%d", muertesJugador[i]);
			TextDrawSetString(muertesNara1vs1, str);
			new Float:ratio;
			if(muertesJugador[i] == 0)
				ratio = killsJugador[i];
			else
				ratio = float(killsJugador[i])/float(muertesJugador[i]);
			format(str, 24, "%.2f", ratio);
			TextDrawSetString(ratioNara1vs1, str);
	    }
	    if(Equipo[i] == EQUIPO_VERDE){
			format(str2, 24, "%s", infoJugador[i][Nombre]);
			TextDrawSetString(nombreVerde1vs1, str2);
			format(str2, 24, "%d", killsJugador[i]);
			TextDrawSetString(killsVerd1vs1, str2);
			format(str2, 24, "%d", killsJugador[i]);
			TextDrawSetString(muertesVerd1vs1, str2);
			new Float:ratio;
			if(muertesJugador[i] == 0)
				ratio = killsJugador[i];
			else
				ratio = float(killsJugador[i])/float(muertesJugador[i]);
			format(str2, 24, "%.2f", ratio);
			TextDrawSetString(ratioVerd1vs1, str);
	    }
	}
	new strInfo[700], ministr[258], ganadorColor[5];
	if(Equipo[ganador] == EQUIPO_NARANJA) format(ganadorColor, 5, "~y~");
	else format(ganadorColor, 5, "~g~");
	format(strInfo[0], sizeof(strInfo), "~w~Ganador: %s%s~n~~w~Puntaje total: ~y~%d~w~:~g~%d ~w~(~y~%d~w~:~g~%d~w~)",
	ganadorColor, infoJugador[ganador][Nombre], dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje], dataEquipo[EQUIPO_NARANJA][Rondas], dataEquipo[EQUIPO_VERDE][Rondas]);
	format(ministr[0], 100, "~n~~w~Tipo de partida: ~b~~w~%d~w~x~b~~w~%d~n~~w~Mapa: ~b~~w~%s", maximaRonda, maximoPuntaje, nombreMapa(mapaElegido));
	strcat(strInfo, ministr);
	TextDrawSetString(textoInfo1vs1, strInfo[0]);
 	mostrarTextResultado1vs1();
	SetTimer("ocultarResultados", 30000, false);
 	SendClientMessageToAll(COLOR_BLANCO, "La tabla de resultados se ocultarà en 30 segundos.");
	resetearPartida();
}

stock crearResultadoCW(ganador){
    eliminarListaDeKills();
    ForPlayers(i){
        if(Equipo[i] != EQUIPO_ESPECTADOR)
			TogglePlayerControllable(i, 1);
	}
   	new nombreStr[2][MAX_PLAYER_NAME*10],
		killStr[2][MAX_PLAYER_NAME*10],
		muerteStr[2][MAX_PLAYER_NAME*10],
		ratioStr[2][MAX_PLAYER_NAME*10],
		idMejor,
		Float:maxPuntos = 0.00;
		
	ForPlayers(i){
	    if(Equipo[i] != EQUIPO_ESPECTADOR){
			format(nombreStr[Equipo[i]],300, "%s%s~n~", nombreStr[Equipo[i]],infoJugador[i][Nombre]);
			format(killStr[Equipo[i]],300, "%s%d~n~", killStr[Equipo[i]], killsJugador[i]);
			format(muerteStr[Equipo[i]],300, "%s%d~n~", muerteStr[Equipo[i]], muertesJugador[i]);
			new Float:ratio;
			if(muertesJugador[i] == 0)
				ratio = killsJugador[i];
			else
				ratio = float(killsJugador[i])/float(muertesJugador[i]);
			format(ratioStr[Equipo[i]], 300, "%s%0.2f~n~", ratioStr[Equipo[i]], ratio);
			if(ratio > maxPuntos){
			    maxPuntos = ratio;
			    idMejor = i;
			}
	    }
	}
	TextDrawSetString(nicksNaranja, nombreStr[EQUIPO_NARANJA]);
	TextDrawSetString(killsNaranja, killStr[EQUIPO_NARANJA]);
	TextDrawSetString(muertesNaranja, muerteStr[EQUIPO_NARANJA]);
	TextDrawSetString(ratiosNaranja, ratioStr[EQUIPO_NARANJA]);
	TextDrawSetString(nicksVerde, nombreStr[EQUIPO_VERDE]);
	TextDrawSetString(killsVerde, killStr[EQUIPO_VERDE]);
	TextDrawSetString(muertesVerde, muerteStr[EQUIPO_VERDE]);
	TextDrawSetString(ratiosVerde, ratioStr[EQUIPO_VERDE]);
	
	new ganadorColor[5];
	if(ganador == EQUIPO_NARANJA) format(ganadorColor, 5, "~y~");
	else format(ganadorColor, 5, "~g~");
	
	new strInfoPartida[1024], ministr[100];
	format(strInfoPartida[0], 1024, "~w~Equipo ganador: %s%s~n~~w~Mejor jugador: ~b~~w~%s~n~~w~Puntaje total: ~y~%d~w~:~g~%d ~w~(~y~%d~w~:~g~%d~w~)",
	ganadorColor, nombreEquipo[ganador], infoJugador[idMejor][Nombre], dataEquipo[EQUIPO_NARANJA][Puntaje], dataEquipo[EQUIPO_VERDE][Puntaje], dataEquipo[EQUIPO_NARANJA][Rondas], dataEquipo[EQUIPO_VERDE][Rondas]);
	format(ministr[0], 100, "~n~Tipo de partida: ~b~~w~%d~w~x~b~~w~%d~n~~w~Mapa: ~b~~w~%s", maximaRonda, maximoPuntaje, nombreMapa(mapaElegido));
	strcat(strInfoPartida, ministr);
	TextDrawSetString(textoEquipoGanador, strInfoPartida[0]);
    mostrarTextResultadoCW();
    SetTimer("ocultarResultados", 30000, false);
    SendClientMessageToAll(COLOR_BLANCO, "La tabla de resultados se ocultarà en 30 segundos.");
    resetearPartida();
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
		SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%s}%s"GRISEADO" ha ganado la clan war contra {%s}%s", colorEquipo(equipoGanador), nombreEquipo[equipoGanador], colorEquipo(equipoPerdedor), nombreEquipo[equipoPerdedor]);
		crearResultadoCW(equipoGanador);
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
		crearResultado1vs1(ganador);
	}
}

stock respawnearJugadores(){
	ForPlayers(i){
	    if(Equipo[i] != EQUIPO_ESPECTADOR){
	    	SetPlayerHealth(i, 100);
        	SpawnPlayer(i);
	    }
	}
}
stock resetearPartida(){
	resetearTodo();
	resetearJugadoresEnPartida();
	actualizarTextGlobales();
}
stock resetearTodosJugadores(){
	ForPlayers(i)
		SpawnPlayer(i);
}

stock resetearJugadoresEnPartida(){
	ForPlayers(i){
	    if(Equipo[i] != EQUIPO_ESPECTADOR){
	    	SetPlayerHealth(i, 100);
     		killsJugador[i] = 0;
        	muertesJugador[i] = 0;
        	SpawnPlayer(i);
	    }
	}
}

stock idJugadorVerde(){
	new id;
	ForPlayers(i){
		if(Equipo[i] == EQUIPO_VERDE)
			return id = i;
	}
	return id;
}

idJugadorNaranja(){
	new id;
	ForPlayers(i){
		if(Equipo[i] == EQUIPO_NARANJA)
			return id = i;
	}
	return id;
}


actualizarEquipo(playerid, killerid){
	if(modoDeJuego == CLAN_WAR){
		new equipoOpuesto, equipoAdyacente = Equipo[playerid];
		if(equipoAdyacente == EQUIPO_NARANJA) equipoOpuesto = EQUIPO_VERDE;
		else equipoOpuesto = EQUIPO_NARANJA;
		
        if(Equipo[playerid] == Equipo[killerid]){
        	SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha hecho teamkill.", colorJugador(playerid), nombreEquipo[equipoAdyacente]);
        	dataEquipo[Equipo[equipoOpuesto]][Puntaje]++;
    	}else
 			dataEquipo[Equipo[killerid]][Puntaje]++;
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
	new i = Equipo[killerid];
	if(dataEquipo[Equipo[killerid]][Puntaje] == maximoPuntaje){
		dataEquipo[Equipo[killerid]][Rondas]++;
		resetearPuntos();
		if(rondaActual < maximaRonda){
			if(modoDeJuego == UNO_VS_UNO){
				new id, id2;
				if(Equipo[killerid] == EQUIPO_NARANJA){
				    id = idJugadorNaranja();
				    id2 = idJugadorVerde();
				}else{
				    id = idJugadorVerde();
				    id2 = idJugadorNaranja();
				}
				SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha ganado la {FFFFFF}%d "GRISEADO"ronda contra {%06x}%s", colorJugador(id), infoJugador[id][Nombre], rondaActual, colorJugador(id2), infoJugador[id2][Nombre]);
			}else{
				SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha ganado la %d ronda.", colorJugador(i), nombreEquipo[i], rondaActual);
			}
	    	rondaActual++;
  			SCMTAF(COLOR_BLANCO, ""GRISEADO"Empieza la %d ronda.", rondaActual);
  			respawnearJugadores();
		}
		else if(rondaActual == maximaRonda){
		    if(modoDeJuego == UNO_VS_UNO)
		        SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha ganado la ultima ronda.", colorJugador(i), infoJugador[killerid][Nombre]);
		    else
            	SCMTAF(COLOR_BLANCO, ""GRISEADO"El equipo {%06x}%s"GRISEADO" ha ganado la ultima ronda.", colorJugador(i), nombreEquipo[i]);
			verificarGanador();
			respawnearJugadores();
		}
	}
    actualizarTextGlobales();
    actualizarMarcador();
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
	new s[16];
	if(aceptarInvitaciones[i] == true)
	    format(s, sizeof(s), "Activado");
	if(aceptarInvitaciones[i] == false)
	    format(s, sizeof(s), "Desactivado");
	return s;
}

stock colorEquipo(id){
	new s[10];
	if(id == EQUIPO_NARANJA)
		format(s, 10, "F69521");
	else
	    format(s, 10, "77CC77");
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
	    format(s, 24, "Elite");
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
	new rconS[40];
	format(rconS, 40, "mapname %s", s);
	SendRconCommand(rconS);
	return s;
}

stock tipoDuelo(id){
	new s[3];
	if(id >= 1 && id <= 3)
		format(s, 3, "RW");
	return s;
}
stock nombreArenaX1(id){
	new s[25];
	if(id == 1)
		format(s, 25, "Warehouse");
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
	if(text[0] == '$' && infoJugador[playerid][Admin] >= 1){
	    new string[300];
		format(string,sizeof(string),"{B8B8B8}[CHAT-ADMIN] {004444}%s {FFFFFF}[{B8B8B8}N-{70FBFF}%d{FFFFFF}]: {C3C3C3}%s", infoJugador[playerid][Nombre], infoJugador[playerid][Admin], text[1]);
		ForPlayers(i){
		    if(IsPlayerConnected(i) == 1)
				if(infoJugador[i][Admin] >= 1)
					SendClientMessage(i, COLOR_BLANCO, string);
		}
		return 0;
	}
	
    new Mensaje[256];
	format(Mensaje, sizeof(Mensaje), "{C3C3C3}[{%s}%i{C3C3C3}] {%06x}%s {C3C3C3}[%d]{FFFFFF}: %s", colorRango(playerid), infoJugador[playerid][puntajeRanked], colorJugador(playerid), infoJugador[playerid][Nombre], playerid, text);
	SendClientMessageToAll(GetPlayerColor(playerid), Mensaje);
	SetPlayerChatBubble(playerid, text, COLOR_BLANCO, 50, 5000);
    return 0;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(!success){
    	PlayerPlaySound(playerid,1054,0.0,0.0,0.0);
    	SendClientMessage(playerid, COLOR_BLANCO, ""GRISEADO"Comando incorrecto, usa {FFFFFF}/cmds");
 	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(eligiendoSkin[playerid] == true){
    	new string[400];
		strcat(string,"{FFFFFF}El servidor se encuentra en fase BETA\n");
		strcat(string,"{FFFFFF}Estará en desarrollo los siguientes días\n");
		strcat(string,"{FFFFFF}Comandos: /cmds\n");
		ShowPlayerDialog(playerid, DIALOG_CREDITOS, 0, "Información sobre el servidor", string, "Ok", "");
		mostrarDataPlayer(playerid);
		ocultarTextDrawsEntrada(playerid);
		actualizarTextGlobales();
  		eligiendoSkin[playerid] = false;
 	}
    if(skinJugador[playerid] != -1)
		SetPlayerSkin(playerid, skinJugador[playerid]);

	actualizarArenaJugador(playerid);
    
    if(Equipo[playerid] != EQUIPO_ESPECTADOR){
    	GivePlayerWeapon(playerid, 22, 9999);
		GivePlayerWeapon(playerid, 28, 9999);
		GivePlayerWeapon(playerid, 26, 9999);
    }
	
    SetPlayerHealth(playerid,100);
    SetPlayerPos(playerid, spawnMapas[mapaElegido][Equipo[playerid]][0], spawnMapas[mapaElegido][Equipo[playerid]][1], spawnMapas[mapaElegido][Equipo[playerid]][2]);
	SetPlayerFacingAngle(playerid, spawnMapas[mapaElegido][Equipo[playerid]][3]);
	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
    if(issuerid != INVALID_PLAYER_ID)
		if(weaponid > 21 && weaponid < 35)
			PlayerPlaySound(issuerid, 17802, 0.0, 0.0, 0.0);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason){
	if(killerid == INVALID_PLAYER_ID)
		return SpawnPlayer(playerid);

	mostrarMensajeDueloTerminado(playerid, killerid);
	
    if(Equipo[playerid] == EQUIPO_ESPECTADOR)
		return SpawnPlayer(playerid);

	if(modoDeJuego != ENTRENAMIENTO){
		killsJugador[killerid]++;
		muertesJugador[playerid]++;
		actualizarEquipo(playerid, killerid);
	}
	
	if(tieneClan(playerid) > 0){
  //format(consultaDb, sizeof(consultaDb), "UPDATE registros SET clan = 0 WHERE clan = %d", idClan);
    	//resultado = db_query(Cuentas, consultaDb);
 	}
  	SpawnPlayer(playerid);
    SendDeathMessage(killerid, playerid, reason);
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
	return 	mostrarTop(playerid);
}

CMD:saber(playerid, params[]){
	printf("cantidad %d", jugadoresArena[ARENA_WAREHOUSE]);
	return 1;
}
CMD:x1(playerid, params[]){
	if(Equipo[playerid] != EQUIPO_ESPECTADOR)
		return SendClientMessage(playerid, COLOR_ROJO, "Los duelos solamente son para {FFFFFF}Espectadores");
	if(estaEnDuelo[playerid] > 0){
	    new str[128], num = estaEnDuelo[playerid];
    	format(str, sizeof(str), ""GRISEADO"Ya estàs en la arena {FFFFFF}%s"GRISEADO", usa {FFFFFF}/salir", nombreArenaX1(num));
    	return SendClientMessage(playerid, COLOR_ROJO, str);
	}
	new string[128], selece[200];
	strcat(selece, "{7C7C7C}Arena\t{7C7C7C}Jugadores\n");
	format(string, sizeof(string), "{B8B8B8}Warehouse\t{7C7C7C}%d", jugadoresArena[ARENA_WAREHOUSE]);
	strcat(selece, string);
    ShowPlayerDialog(playerid, DIALOG_DUELOARENAS, DIALOG_STYLE_TABLIST_HEADERS, "{7C7C7C}Arenas de duelo", selece, "Selec.", "Cerrar");
	return 1;
}

CMD:salir(playerid, params[]){
	if(Equipo[playerid] != EQUIPO_ESPECTADOR)
		return SendClientMessage(playerid, COLOR_ROJO, "Los duelos solamente son para {FFFFFF}Espectadores");
	if(estaEnDuelo[playerid] == 0)
		return SendClientMessage(playerid, COLOR_ROJO, "No estas en ninguna arena para salir.");
	new s[128], num = estaEnDuelo[playerid];
	format(s, sizeof(s), "%s "GRISEADO"salió de la arena {FFFFFF}%s", infoJugador[playerid][Nombre], nombreArenaX1(num));
	SendClientMessageToAll(COLOR_BLANCO, s);
	SpawnPlayer(playerid);
	return 1;
}

CMD:fps(playerid, params[]){
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/fps ID");
	new i = strval(params);
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	SCMTAF(COLOR_BLANCO, "- {%06x}%s {FFFFFF}> "GRISEADO"%d {FFFFFF}FPS", colorJugador(i), infoJugador[i][Nombre], GetPlayerFPS(i));
	return 1;
}

CMD:pl(playerid, params[]){
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/pl ID");
	new i = strval(params);
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	SCMTAF(COLOR_BLANCO, "- {%06x}%s {FFFFFF}> "GRISEADO"%.2f{FFFFFF}%", colorJugador(i), infoJugador[i][Nombre], NetStats_PacketLossPercent(i));
	return 1;
}

CMD:cmds(playerid, params[]){
	new selece[600], string[100], Nivel = infoJugador[playerid][Admin];
	strcat(selece, "{00779E}Jugadores\n{FFFFFF}Espectadores (No disponible)");
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
	if(Nivel == 100){
 			format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(1));	strcat(selece, string);
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(2));	strcat(selece, string);
		    format(string, sizeof(string), "\n{00779E}%s", tipoAdmin(3));	strcat(selece, string);
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

	new strTitulo[100], strAdmins[256], str[2400], Cant = 0, Nivel;
    format(str, sizeof(str), ""GRISEADO"Nick\t"GRISEADO"Nivel");
    strcat(strAdmins, str);
	ForPlayers(i){
	    if(infoJugador[i][Admin] > 0){
			Nivel = infoJugador[i][Admin];
	        format(str, sizeof(str), "\n{%06x}%s\t{FFFFFF}%d", colorJugador(i), infoJugador[i][Nombre], Nivel);
	        strcat(strAdmins, str);
	        Cant++;
	    }
	}
	format(str, sizeof(str), ""GRISEADO"Hay %d administrador/es conectados", Cant);
	strcat(strTitulo, str);

	ShowPlayerDialog(playerid, 2343, DIALOG_STYLE_TABLIST_HEADERS, strTitulo, strAdmins, "Cerrar", "");
	return 1;
}
CMD:guardarmisdatos(playerid, params[]){
	guardarDatos(playerid);
	return 1;
}

CMD:rw(playerid, params[]){
	if(estaEnDuelo[playerid] == 0)
		return SendClientMessage(playerid, COLOR_ROJO, "No estas en una arena x1.");
	if(tipoArmas[playerid] == ARMAS_RAPIDAS)
	    return SendClientMessage(playerid, COLOR_ROJO, "Ya tenes puesto estas armas.");

	darArmasRW(playerid);
	tipoArmas[playerid] = ARMAS_RAPIDAS;
	SendClientMessage(playerid, COLOR_BLANCO, "Se te ha puesto el pack de armas RW.");
	return 1;
}

CMD:ww(playerid, params[]){
	if(estaEnDuelo[playerid] == 0)
		return SendClientMessage(playerid, COLOR_ROJO, "No estas en una arena x1.");
	if(tipoArmas[playerid] == ARMAS_LENTAS)
	    return SendClientMessage(playerid, COLOR_ROJO, "Ya tenes puesto estas armas.");
	    
	darArmasWW(playerid);
	tipoArmas[playerid] = ARMAS_LENTAS;
	SendClientMessage(playerid, COLOR_ROJO, "Se te ha puesto el pack de armas lentas (WW)");
	return 1;
}

CMD:stats(playerid, params[]){
    new i, stats[2000];
    if(isnull(params))
		i = playerid;
    else
		i = strval(params);
		
	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");

	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	    
    format(stats, sizeof(stats), "{7C7C7C}Nick: {%06x}%s", colorJugador(i), infoJugador[i][Nombre]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Invitaciones: {FFFFFF}%s", stats, invitacionJugador(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Clan: {FFFFFF}%s", stats, tagClan(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Pais: {FFFFFF}%s", stats, infoJugador[i][Pais]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Ping: {FFFFFF}%d", stats, GetPlayerPing(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Skin: {FFFFFF}%d", stats, GetPlayerSkin(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}PacketLoss: {FFFFFF}%.2f%", stats, NetStats_PacketLossPercent(i));
    format(stats, sizeof(stats), "%s\n{7C7C7C}Rango: {%s}%s {7C7C7C}({FFFFFF}%d{7C7C7C})", stats, colorRango(i), nombreRango(i), infoJugador[i][puntajeRanked]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Duelos ganados: {FFFFFF}%d", stats, infoJugador[i][duelosGanados]);
    format(stats, sizeof(stats), "%s\n{7C7C7C}Duelos perdidos: {FFFFFF}%d", stats, infoJugador[i][duelosPerdidos]);
    
    if(estaEnDuelo[i] > 0){
        if(jugadoresArena[estaEnDuelo[i]] == 1)
			format(stats, sizeof(stats), "%s\n{7C7C7C}Esperando en {FFFFFF}%s {7C7C7C}({FFFFFF}%s{7C7C7C})", stats, nombreArenaX1(estaEnDuelo[i]), tipoDuelo(estaEnDuelo[i]));
        else
			format(stats, sizeof(stats), "%s\n{7C7C7C}Dueleando en {FFFFFF}%s {7C7C7C}({FFFFFF}%s{7C7C7C})", stats, nombreArenaX1(estaEnDuelo[i]), tipoDuelo(estaEnDuelo[i]));
	}
    if(infoJugador[i][Admin] > 0)
		format(stats, sizeof(stats), "%s\n{7C7C7C}%s {7C7C7C}({FFFFFF}%d{7C7C7C})", stats, tipoAdmin(infoJugador[i][Admin]), infoJugador[i][Admin]);

    ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, "Stats", stats, "Cerrar", "");
    return 1;
}

CMD:creditos(playerid, params[]){
    new string[1200];
	strcat(string,"{FFFFFF}> {7C7C7C}Desarrollador{B8B8B8}: {FFFFFF}[WTx]Andrew_Manu\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Testers{B8B8B8}: {FFFFFF}Alexis_Blaze, Franco_Masucco\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Contacto{B8B8B8}: {FFFFFF}wtxclanx@hotmail.com\n");
	strcat(string,"{FFFFFF}> {7C7C7C}Versión{B8B8B8}: {FFFFFF}0.6b\n");
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

CMD:inforangos(playerid, params[]){
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
	strcat(string,"{7C7C7C}- {FF0084}Elite \t{7C7C7C}({FFFFFF}> 1200, rango máximo{7C7C7C})\n");
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

CMD:plall(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	SendClientMessageToAll(COLOR_BLANCO,"> PL:");
	ForPlayers(i)
		SCMTAF(COLOR_BLANCO, "- {%06x}%s {FFFFFF}> "GRISEADO"%.2f{FFFFFF}%", colorJugador(i), infoJugador[i][Nombre], NetStats_PacketLossPercent(i));
	return 1;
}

CMD:spawn(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	if(isnull(params))
  		return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/spawn ID");
	new i = strval(params);
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	SpawnPlayer(i);
	SetPlayerHealth(i,100);
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha respawneado a {%06x}%s", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre]);
	return 1;
}

CMD:spawnall(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	ForPlayers(i){
		if(Equipo[i] != EQUIPO_ESPECTADOR){
			SpawnPlayer(i);
			SetPlayerHealth(i, 100);
		}
	}
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" ha respawneado a todos los jugadores.", colorJugador(playerid), infoJugador[playerid][Nombre]);
	return 1;
}

CMD:hp(playerid, params[]){
	new i, cantidad;
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	if(sscanf(params, "ii", i, cantidad))
		return SendClientMessage(playerid, COLOR_ROJO,"Escribiste mal el comando; {FFFFFF}/hp ID cantidad");
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(cantidad > 100 || cantidad < 1)
		return SendClientMessage(playerid, COLOR_ROJO, "No podes ponerle esa vida.");
	SetPlayerHealth(i, cantidad);
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció la vida de {%06x}%s "GRISEADO"a {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], cantidad);
	return 1;
}

CMD:hpall(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	ForPlayers(i){
		if(Equipo[i] != EQUIPO_ESPECTADOR)
			SetPlayerHealth(i, 100);
	}
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" restableció la vida de todos los jugadores.", colorJugador(playerid), infoJugador[playerid][Nombre]);
	return 1;
}

CMD:armour(playerid, params[]){
	new i, cantidad;
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	if(sscanf(params, "ii", i, cantidad))
		return SendClientMessage(playerid, COLOR_ROJO,"Escribiste mal el comando; {FFFFFF}/armour ID cantidad");
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(cantidad > 100 || cantidad < 1)
		return SendClientMessage(playerid, COLOR_ROJO, "No podes ponerle esa armadura.");
	SetPlayerArmour(i, cantidad);
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció la armadura de {%06x}%s "GRISEADO"a {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], cantidad);
	return 1;
}

CMD:armourall(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de partidas pueden usar este comando.");
	ForPlayers(i){
		if(Equipo[i] != EQUIPO_ESPECTADOR)
			SetPlayerArmour(i, 100);
	}
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" restableció la armadura de todos los jugadores.", colorJugador(playerid), infoJugador[playerid][Nombre]);
	return 1;
}

CMD:naranja(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/naranja ID");
	new i = strval(params);
	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(Equipo[i] == EQUIPO_NARANJA)
		return SendClientMessage(playerid, COLOR_ROJO, "El jugador ya está en este equipo.");
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" envió a {%06x}%s "GRISEADO"al equipo {F69521}%s", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], nombreEquipo[EQUIPO_NARANJA]);
	Equipo[i] = EQUIPO_NARANJA;
	establecerJugadores();
	actualizarModoDeJuego();
	actualizarTextGlobales();
	actualizarMarcador();
	establecerColor(i);
	SpawnPlayer(i);
	return 1;
}

CMD:verde(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/verde ID");
	new i = strval(params);
	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(Equipo[i] == EQUIPO_VERDE)
		return SendClientMessage(playerid, COLOR_ROJO, "El jugador ya está en este equipo.");
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" envió a {%06x}%s "GRISEADO"al equipo {007C0E}%s", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], nombreEquipo[EQUIPO_VERDE]);
	Equipo[i] = EQUIPO_VERDE;
	establecerJugadores();
	actualizarModoDeJuego();
	actualizarTextGlobales();
	actualizarMarcador();
	establecerColor(i);
	SpawnPlayer(i);
	return 1;
}

CMD:espectador(playerid, params[]){
	if(infoJugador[playerid][Admin] < 1)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
	if(isnull(params))
	   	return SendClientMessage(playerid, COLOR_ROJO, "Escribiste mal el comando; {FFFFFF}/espectador ID");
	new i = strval(params);
	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(Equipo[i] == EQUIPO_ESPECTADOR)
		return SendClientMessage(playerid, COLOR_ROJO, "El jugador ya está en este equipo.");
   	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" envió a {%06x}%s "GRISEADO"al equipo {FFFFFF}Espectador", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre]);
	Equipo[i] = EQUIPO_ESPECTADOR;
	establecerJugadores();
	actualizarModoDeJuego();
	actualizarTextGlobales();
	actualizarMarcador();
	establecerColor(i);
	SpawnPlayer(i);
	return 1;
}

CMD:reseteartodo(playerid, params[]){
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
	SCMTAF(COLOR_BLANCO,""GRISEADO"Desde ahora se jugará: {FFFFFF}%dx%d", maximaRonda, maximoPuntaje);
	actualizarTextGlobales();
	return 1;
}

CMD:rondasnaranja(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
    if(isnull(params)){
   		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/rondasnaranja [0:%d]", maximaRonda-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
    }
	new i = strval(params);
 	if(i > (maximaRonda-1) || i < 0){
		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/rondasnaranja [0:%d]", maximaRonda-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
 	}
 	if(i == dataEquipo[EQUIPO_NARANJA][Rondas])
 	    return SendClientMessage(playerid, COLOR_ROJO, "No establezcas el mismo valor actual");

    dataEquipo[EQUIPO_NARANJA][Rondas] = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció las rondas del equipo {F69521}%s "GRISEADO"a {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_NARANJA], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Rondas actual = {F69521}%d"GRISEADO":{77CC77}%d", dataEquipo[EQUIPO_NARANJA][Rondas], dataEquipo[EQUIPO_VERDE][Rondas]);
	actualizarTextGlobales();
	actualizarMarcador();
	return 1;
}

CMD:rondasverde(playerid, params[]){
	if(infoJugador[playerid][Admin] == 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Solo los administradores de partidas pueden usar este comando.");
    if(isnull(params)){
   		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/rondasverde [0:%d]", maximaRonda-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
    }
	new i = strval(params);
 	if(i > (maximaRonda-1) || i < 0){
		new s[64];
		format(s, sizeof(s), "Escribiste mal el comando; {FFFFFF}/rondasverde [0:%d]", maximaRonda-1);
		return SendClientMessage(playerid, COLOR_ROJO, s);
 	}
 	if(i == dataEquipo[EQUIPO_VERDE][Rondas])
 	    return SendClientMessage(playerid, COLOR_ROJO, "No establezcas el mismo valor actual");

    dataEquipo[EQUIPO_VERDE][Rondas] = i;
	SCMTAF(COLOR_BLANCO, "{%06x}%s"GRISEADO" estableció las rondas del equipo {F69521}%s "GRISEADO"a {FFFFFF}%d", colorJugador(playerid), infoJugador[playerid][Nombre], nombreEquipo[EQUIPO_VERDE], i);
	SCMTAF(COLOR_BLANCO,""GRISEADO"Rondas actual = {F69521}%d"GRISEADO":{77CC77}%d", dataEquipo[EQUIPO_NARANJA][Rondas], dataEquipo[EQUIPO_VERDE][Rondas]);
	actualizarTextGlobales();
	actualizarMarcador();
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
	SCMTAF(COLOR_BLANCO,""GRISEADO"Desde ahora se jugará: {FFFFFF}%dx%d", maximaRonda, maximoPuntaje);
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
	actualizarMarcador();
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
    format(str, sizeof(str), "{%06x}%s "GRISEADO"vino a tu posición", colorJugador(playerid), infoJugador[playerid][Nombre]);
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

CMD:kick(playerid, params[]){
	if(infoJugador[playerid][Admin] < 3)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de jugadores pueden usar este comando.");
    new i, razon[64];
  	if(sscanf(params, "is", i, razon))
		return SendClientMessage(playerid, COLOR_ROJO,"Escribiste mal el comando; {FFFFFF}/ban ID Razón");
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	new str[328];
	format(str, sizeof(str), "{%06x}%s"GRISEADO" ha kickeado a {%06x}%s "GRISEADO" razón: {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], razon);
	SendClientMessageToAll(COLOR_BLANCO, str);
	ShowPlayerDialog(i, 3453, 0, "Kickeado", str, "Ok", "");
	printf("%s ha kickeado a %s por la razon %s",infoJugador[playerid][Nombre],infoJugador[i][Nombre], razon);
	Kick(i);
	return 1;
}

CMD:ban(playerid, params[]){
	if(infoJugador[playerid][Admin] < 3)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de jugadores pueden usar este comando.");
    new i, razon[64];
  	if(sscanf(params, "is", i, razon))
		return SendClientMessage(playerid, COLOR_ROJO,"Escribiste mal el comando; {FFFFFF}/ban ID Razón");
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	new str[328];
	format(str, sizeof(str), "{%06x}%s"GRISEADO" ha baneado a {%06x}%s "GRISEADO" razón: {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], razon);
	SendClientMessageToAll(COLOR_BLANCO, str);
	printf("%s ha baneado a %s por la razon %s",infoJugador[playerid][Nombre],infoJugador[i][Nombre], razon);
	infoJugador[playerid][Baneado] = 1;
	BanEx(i, razon);
	return 1;
}
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

CMD:equipoverde(playerid, params[]){
	new i= strval(params);
	Equipo[i] = EQUIPO_VERDE;
				establecerJugadores();
				actualizarModoDeJuego();
        		establecerColor(i);
        		actualizarTextGlobales();
        		SpawnPlayer(i);
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
	if(infoJugador[playerid][Admin] > 0)
	    return SendClientMessage(playerid, COLOR_ROJO,"Ya sos admin :)");
	infoJugador[playerid][Admin] = 100;
SendClientMessage(playerid, COLOR_ROJO,"Dueño establecido, disfruta.");
	return 1;
}

/* Comandos para clanes */


CMD:actualizarclanes(playerid, params[]){
	if(infoJugador[playerid][Admin] < 3)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores pueden usar este comando.");
	actualizarClanRegitro();
	return 1;
}

CMD:crearclan(playerid, params[]){
	if(tieneClan(playerid) > 0)
		return SendClientMessage(playerid, COLOR_ROJO, "Ya estas en un clan, utiliza /salirclan si queres salir.");
	if(procesoClan)
		return SendClientMessage(playerid, COLOR_BLANCO, "Ya hay alguien creando un clan, espera a que registre el suyo.");
	if(!infoJugador[playerid][Registrado])
		return SendClientMessage(playerid, COLOR_ROJO, "Debes estar registrado.");
	if(sacarRango(playerid) < RANGO_ORO)
	    return SendClientMessage(playerid, COLOR_ROJO, "No tenes rango.");
    new string[1024], anio, dia, mes;
    getdate(anio, mes, dia);
    if(dia == 1 || dia == 2 || dia == 3)
        return SendClientMessage(playerid, COLOR_ROJO, "Este dia no se pueden registrar clanes.");
        
	strcat(string,"{FFFFFF}¿Estas seguro de que querés registrar un clan?\n");
	ShowPlayerDialog(playerid, DIALOG_IFCLAN, 0, "Registro de clanes", string, "Sí", "No");
	actualizarClanRegitro();
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
	actualizarClanRegitro();
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
  	//if(propietarioClan(playerid) > 0)
    //	return SendClientMessage(playerid, COLOR_ROJO, "El jugador es dueño de un clan.");
	if(aceptarInvitaciones[i] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "El jugador tiene desactivado las invitaciones.");
	if(tieneClan(i) > 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "El jugador ya tiene un clan.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	if(clanInvitacion[i][idClanInvitado] != 0)
	    return SendClientMessage(playerid, COLOR_ROJO, "Este usuario ya está siendo invitado a un clan");
	    
	new DBResult:resultado, idClan = sacarClanId(playerid), TAG2[6], str[128];
 	format(consultaDb, sizeof(consultaDb), " SELECT tag FROM registro WHERE id = %d", idClan);
 	resultado = db_query(Clanes, consultaDb);
 	db_get_field_assoc(resultado, "tag", TAG2, sizeof(TAG2));
	db_free_result(resultado);
	clanInvitacion[i][idClanInvitado] = idClan;
	strcat(clanInvitacion[i][tagClanInvitado], TAG2);
	clanInvitacion[i][idInvitador] = playerid;
	format(str, sizeof(str), "{%06x}%s "GRISEADO"te ha invitado a unirse a su clan {FFFFFF}%s", colorJugador(playerid), infoJugador[playerid][Nombre], TAG2);
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
	new Mensaje[300], TAG[6];
	strcat(TAG, sacarClanTag(playerid));
 	format(Mensaje, sizeof(Mensaje), "{%06x}%s "GRISEADO"ha expulsado a {%06x}%s "GRISEADO"de su clan ({FFFFFF}%s"GRISEADO"}", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre], TAG);
	SendClientMessageToAll(COLOR_BLANCO, Mensaje);
 	return 1;
}

CMD:actinv(playerid, params[]){
    if(infoJugador[playerid][Registrado] == false)
		return printf("No estas registrado");
 	if(propietarioClan(playerid))
    	return SendClientMessage(playerid, COLOR_ROJO, "No podes activar ya que sos dueño de un clan.");
	if(aceptarInvitaciones[playerid] == true)
	    return SendClientMessage(playerid, COLOR_ROJO, "Ya tenes activado las invitaciones.");
	aceptarInvitaciones[playerid] = true;
	SendClientMessage(playerid, COLOR_VERDE, "Has activado las invitaciones de clanes.");
	return 1;
}

CMD:desinv(playerid, params[]){
    if(infoJugador[playerid][Registrado] == false)
		return printf("No estas registrado");
 	if(propietarioClan(playerid))
    	return SendClientMessage(playerid, COLOR_ROJO, "No podes desactivar ya que sos dueño de un clan.");
	if(aceptarInvitaciones[playerid] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Ya tenes desactivado las invitaciones.");

	aceptarInvitaciones[playerid] = false;
 	SendClientMessage(playerid, COLOR_ROJO, "Has desactivado las invitaciones de clanes.");
	return 1;
}

CMD:miembros(playerid, params[]){
	if(tieneClan(playerid) == 0)
		return SendClientMessage(playerid, COLOR_ROJO, "No estas en ningún clan.");
	if(infoJugador[playerid][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");

	new DBResult:resultado, nombreJugador[30], idClan = sacarClanId(playerid), str[1024], str2[30];
	format(consultaDb, sizeof(consultaDb), " SELECT nick FROM cuentas WHERE clan = %d", idClan);
	resultado = db_query(Cuentas, consultaDb);
 	if(db_num_rows(resultado)){
 	    do{
			db_get_field_assoc(resultado, "nick", nombreJugador, sizeof(nombreJugador));
			format(str2, sizeof(str2), "%s\n",nombreJugador);
			strcat(str, str2);
		}while(db_next_row(resultado));
 	}
 	ShowPlayerDialog(playerid, 12343124, DIALOG_STYLE_MSGBOX, "Miembros de tu clan", str, "Cerrar", "");
	return 1;
}
CMD:clan(playerid, params[]){
	if(tieneClan(playerid) == 0)
		return SendClientMessage(playerid, COLOR_ROJO, "No estas en ningún clan.");
	if(infoJugador[playerid][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");
	
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

CMD:dar(playerid, params[]){
	new cantidad, i;
	if(infoJugador[playerid][Admin] < 3)
	    return SendClientMessage(playerid, COLOR_ROJO,"Solo los administadores de jugadores pueden usar este comando.");
	if(sscanf(params, "ii", i, cantidad))
		return SendClientMessage(playerid, COLOR_ROJO,"Escribiste mal el comando; {FFFFFF}/dar ID cantidad");
 	if(!IsPlayerConnected(i))
		return SendClientMessage(playerid, COLOR_ROJO, "No existe la ID que pusiste.");
	if(infoJugador[i][Registrado] == false)
	    return SendClientMessage(playerid, COLOR_ROJO, "Cuenta no registrada.");

	new str[200];
	infoJugador[i][puntajeRanked] = cantidad;
	format(str, sizeof(str), "{%06x}%s"GRISEADO" actualizó el puntaje ranked de {%06x}%s", colorJugador(playerid), infoJugador[playerid][Nombre], colorJugador(i), infoJugador[i][Nombre]);
	SendClientMessageToAll( COLOR_BLANCO, str);
	guardarDatos(i);
	return 1;
}


CMD:kill(playerid, params[]){
    SetPlayerHealth(playerid, -1);
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

crearTextResultado1vs1(){
	fondoResultado1vs1 = TextDrawCreate(433.333374, 158.714721, "usebox");
	TextDrawLetterSize(fondoResultado1vs1, 0.000000, 7.933328);
	TextDrawTextSize(fondoResultado1vs1, 211.666687, 0.000000);
	TextDrawAlignment(fondoResultado1vs1, 1);
	TextDrawColor(fondoResultado1vs1, 0);
	TextDrawUseBox(fondoResultado1vs1, true);
	TextDrawBoxColor(fondoResultado1vs1, 102);
	TextDrawSetShadow(fondoResultado1vs1, 0);
	TextDrawSetOutline(fondoResultado1vs1, 0);
	TextDrawFont(fondoResultado1vs1, 0);

	textoResultado1vs1 = TextDrawCreate(258.666717, 162.607421, "Resultados de la partida");
	TextDrawLetterSize(textoResultado1vs1, 0.200000, 1.000000);
	TextDrawAlignment(textoResultado1vs1, 1);
	TextDrawColor(textoResultado1vs1, -1);
	TextDrawSetShadow(textoResultado1vs1, 0);
	TextDrawSetOutline(textoResultado1vs1, 1);
	TextDrawBackgroundColor(textoResultado1vs1, 0x000000AA);
	TextDrawFont(textoResultado1vs1, 2);
	TextDrawSetProportional(textoResultado1vs1, 1);

	nombreNaranja1vs1 = TextDrawCreate(226.666656, 180, "[WTx]Andrew_Manu");
	TextDrawLetterSize(nombreNaranja1vs1, 0.200000, 1.000000);
	TextDrawAlignment(nombreNaranja1vs1, 1);
	TextDrawColor(nombreNaranja1vs1, -5963521);
	TextDrawSetShadow(nombreNaranja1vs1, 0);
	TextDrawSetOutline(nombreNaranja1vs1, 1);
	TextDrawBackgroundColor(nombreNaranja1vs1, 0x000000AA);
	TextDrawFont(nombreNaranja1vs1, 1);
	TextDrawSetProportional(nombreNaranja1vs1, 1);

	nombreVerde1vs1 = TextDrawCreate(340.999938, 180, "[WTx]ScorpioN_");
	TextDrawLetterSize(nombreVerde1vs1, 0.200000, 1.000000);
	TextDrawAlignment(nombreVerde1vs1, 1);
	TextDrawColor(nombreVerde1vs1, 8388863);
	TextDrawSetShadow(nombreVerde1vs1, 0);
	TextDrawSetOutline(nombreVerde1vs1, 1);
	TextDrawBackgroundColor(nombreVerde1vs1, 0x000000AA);
	TextDrawFont(nombreVerde1vs1, 1);
	TextDrawSetProportional(nombreVerde1vs1, 1);

	textoVersus1vs1 = TextDrawCreate(313.666687, 180, "vs");
	TextDrawLetterSize(textoVersus1vs1, 0.200000, 1.000000);
	TextDrawAlignment(textoVersus1vs1, 1);
	TextDrawColor(textoVersus1vs1, -1061109505);
	TextDrawSetShadow(textoVersus1vs1, 0);
	TextDrawSetOutline(textoVersus1vs1, 1);
	TextDrawBackgroundColor(textoVersus1vs1, 0x000000AA);
	TextDrawFont(textoVersus1vs1, 2);
	TextDrawSetProportional(textoVersus1vs1, 1);

	dataNara1vs1 = TextDrawCreate(226.000015, 192, "Kills   Muertes   Ratio");
	TextDrawLetterSize(dataNara1vs1, 0.200000, 1.000000);
	TextDrawAlignment(dataNara1vs1, 1);
	TextDrawColor(dataNara1vs1, -2139062017);
	TextDrawSetShadow(dataNara1vs1, 0);
	TextDrawSetOutline(dataNara1vs1, 1);
	TextDrawBackgroundColor(dataNara1vs1, 0x000000AA);
	TextDrawFont(dataNara1vs1, 1);
	TextDrawSetProportional(dataNara1vs1, 1);

	dataVerd1vs1 = TextDrawCreate(338.000122, 192, "Kills   Muertes   Ratio");
	TextDrawLetterSize(dataVerd1vs1, 0.200000, 1.000000);
	TextDrawAlignment(dataVerd1vs1, 1);
	TextDrawColor(dataVerd1vs1, -2139062017);
	TextDrawSetShadow(dataVerd1vs1, 0);
	TextDrawSetOutline(dataVerd1vs1, 1);
	TextDrawBackgroundColor(dataVerd1vs1, 0x000000AA);
	TextDrawFont(dataVerd1vs1, 1);
	TextDrawSetProportional(dataVerd1vs1, 1);

	killsNara1vs1 = TextDrawCreate(228.999954, 205, "12");
	TextDrawLetterSize(killsNara1vs1, 0.200000, 1.000000);
	TextDrawAlignment(killsNara1vs1, 1);
	TextDrawColor(killsNara1vs1, -1061109505);
	TextDrawSetShadow(killsNara1vs1, 0);
	TextDrawSetOutline(killsNara1vs1, 1);
	TextDrawBackgroundColor(killsNara1vs1, 0x000000AA);
	TextDrawFont(killsNara1vs1, 1);
	TextDrawSetProportional(killsNara1vs1, 1);

	muertesNara1vs1 = TextDrawCreate(256.666687, 205, "13");
	TextDrawLetterSize(muertesNara1vs1, 0.200000, 1.000000);
	TextDrawAlignment(muertesNara1vs1, 1);
	TextDrawColor(muertesNara1vs1, -1061109505);
	TextDrawSetShadow(muertesNara1vs1, 0);
	TextDrawSetOutline(muertesNara1vs1, 1);
	TextDrawBackgroundColor(muertesNara1vs1, 0x000000AA);
	TextDrawFont(muertesNara1vs1, 1);
	TextDrawSetProportional(muertesNara1vs1, 1);

	ratioNara1vs1 = TextDrawCreate(287.333312, 205, "1.24");
	TextDrawLetterSize(ratioNara1vs1, 0.200000, 1.000000);
	TextDrawAlignment(ratioNara1vs1, 1);
	TextDrawColor(ratioNara1vs1, -1061109505);
	TextDrawSetShadow(ratioNara1vs1, 0);
	TextDrawSetOutline(ratioNara1vs1, 1);
	TextDrawBackgroundColor(ratioNara1vs1, 0x000000AA);
	TextDrawFont(ratioNara1vs1, 1);
	TextDrawSetProportional(ratioNara1vs1, 1);

	killsVerd1vs1 = TextDrawCreate(340.000122, 205, "14");
	TextDrawLetterSize(killsVerd1vs1, 0.200000, 1.000000);
	TextDrawAlignment(killsVerd1vs1, 1);
	TextDrawColor(killsVerd1vs1, -1061109505);
	TextDrawSetShadow(killsVerd1vs1, 0);
	TextDrawSetOutline(killsVerd1vs1, 1);
	TextDrawBackgroundColor(killsVerd1vs1, 0x000000AA);
	TextDrawFont(killsVerd1vs1, 1);
	TextDrawSetProportional(killsVerd1vs1, 1);

	muertesVerd1vs1 = TextDrawCreate(371.333404, 205, "15");
	TextDrawLetterSize(muertesVerd1vs1, 0.200000, 1.000000);
	TextDrawAlignment(muertesVerd1vs1, 1);
	TextDrawColor(muertesVerd1vs1, -1);
	TextDrawSetShadow(muertesVerd1vs1, 0);
	TextDrawSetOutline(muertesVerd1vs1, 1);
	TextDrawBackgroundColor(muertesVerd1vs1, 0x000000AA);
	TextDrawFont(muertesVerd1vs1, 1);
	TextDrawSetProportional(muertesVerd1vs1, 1);

	ratioVerd1vs1 = TextDrawCreate(400.333374, 205, "1.25");
	TextDrawLetterSize(ratioVerd1vs1, 0.200000, 1.000000);
	TextDrawAlignment(ratioVerd1vs1, 1);
	TextDrawColor(ratioVerd1vs1, -1);
	TextDrawSetShadow(ratioVerd1vs1, 0);
	TextDrawSetOutline(ratioVerd1vs1, 1);
	TextDrawBackgroundColor(ratioVerd1vs1, 0x000000AA);
	TextDrawFont(ratioVerd1vs1, 1);
	TextDrawSetProportional(ratioVerd1vs1, 1);

	fondoInfo1vs1 = TextDrawCreate(389.666687, 301.411102, "usebox");
	TextDrawLetterSize(fondoInfo1vs1, 0.000000, 0.000000);
	TextDrawTextSize(fondoInfo1vs1, 389.666687, 0.000000);
	TextDrawAlignment(fondoInfo1vs1, 1);
	TextDrawColor(fondoInfo1vs1, 0);
	TextDrawUseBox(fondoInfo1vs1, true);
	TextDrawBoxColor(fondoInfo1vs1, 102);
	TextDrawSetShadow(fondoInfo1vs1, 0);
	TextDrawSetOutline(fondoInfo1vs1, 0);
	TextDrawFont(fondoInfo1vs1, 0);

	textoInfo1vs1 = TextDrawCreate(264.666656, 242.666687, "Ganador: [WTx]Andrew_Manu");
	TextDrawLetterSize(textoInfo1vs1, 0.200000, 1.000000);
	TextDrawAlignment(textoInfo1vs1, 1);
	TextDrawColor(textoInfo1vs1, -1);
	TextDrawSetShadow(textoInfo1vs1, 0);
	TextDrawSetOutline(textoInfo1vs1, 1);
	TextDrawBackgroundColor(textoInfo1vs1, 0x000000AA);
	TextDrawFont(textoInfo1vs1, 1);
	TextDrawSetProportional(textoInfo1vs1, 1);
}

stock mostrarTextResultado1vs1(){
    TextDrawShowForAll(fondoResultado1vs1);
    TextDrawShowForAll(textoResultado1vs1);
    
    TextDrawShowForAll(nombreNaranja1vs1);
    TextDrawShowForAll(nombreVerde1vs1);
    
    TextDrawShowForAll(dataNara1vs1);
    TextDrawShowForAll(dataVerd1vs1);
    
    TextDrawShowForAll(killsNara1vs1);
    TextDrawShowForAll(muertesNara1vs1);
    TextDrawShowForAll(ratioNara1vs1);
    
    TextDrawShowForAll(killsVerd1vs1);
    TextDrawShowForAll(muertesVerd1vs1);
    TextDrawShowForAll(ratioVerd1vs1);
    
    TextDrawShowForAll(fondoInfo1vs1);
    TextDrawShowForAll(textoInfo1vs1);
}

stock ocultarTextResultado1vs1(){
    TextDrawHideForAll(fondoResultado1vs1);
    TextDrawHideForAll(textoResultado1vs1);

    TextDrawHideForAll(nombreNaranja1vs1);
    TextDrawHideForAll(nombreVerde1vs1);

    TextDrawHideForAll(dataNara1vs1);
    TextDrawHideForAll(dataVerd1vs1);

    TextDrawHideForAll(killsNara1vs1);
    TextDrawHideForAll(muertesNara1vs1);
    TextDrawHideForAll(ratioNara1vs1);

    TextDrawHideForAll(killsVerd1vs1);
    TextDrawHideForAll(muertesVerd1vs1);
    TextDrawHideForAll(ratioVerd1vs1);

    TextDrawHideForAll(fondoInfo1vs1);
    TextDrawHideForAll(textoInfo1vs1);
}

crearTextResultadoCW(){
	fondoResultado = TextDrawCreate(479.000274, 100.225967, "usebox");
	TextDrawLetterSize(fondoResultado, 0.000000, 19.933347);
	TextDrawTextSize(fondoResultado, 140.666580, 0.000000);
	TextDrawAlignment(fondoResultado, 1);
	TextDrawColor(fondoResultado, 0);
	TextDrawUseBox(fondoResultado, true);
	TextDrawBoxColor(fondoResultado, 102);
	TextDrawSetShadow(fondoResultado, 0);
	TextDrawSetOutline(fondoResultado, 0);
	TextDrawFont(fondoResultado, 0);
	
	textoResultado = TextDrawCreate(247.333297, 104.533332, "RESULTADOS DE LA PARTIDA");
	TextDrawLetterSize(textoResultado, 0.200000, 1.000000);
	TextDrawAlignment(textoResultado, 1);
	TextDrawColor(textoResultado, -1);
	TextDrawSetShadow(textoResultado, 0);
	TextDrawSetOutline(textoResultado, 1);
	TextDrawBackgroundColor(textoResultado, 51);
	TextDrawFont(textoResultado, 2);
	TextDrawSetProportional(textoResultado, 1);
	TextDrawBackgroundColor(textoResultado, 0x000000AA);
	
	textoEquipoNaranja = TextDrawCreate(203.333328, 118, "Equipo Naranja");
	TextDrawLetterSize(textoEquipoNaranja, 0.200000, 1.000000);
	TextDrawAlignment(textoEquipoNaranja, 1);
	TextDrawColor(textoEquipoNaranja, -5963521);
	TextDrawSetShadow(textoEquipoNaranja, 0);
	TextDrawSetOutline(textoEquipoNaranja, 1);
	TextDrawBackgroundColor(textoEquipoNaranja, 51);
	TextDrawFont(textoEquipoNaranja, 1);
	TextDrawSetProportional(textoEquipoNaranja, 1);
	TextDrawBackgroundColor(textoEquipoNaranja, 0x000000AA);
	
	textoEquipoVerde = TextDrawCreate(357.666534, 118, "Equipo Verde");
	TextDrawLetterSize(textoEquipoVerde, 0.200000, 1.000000);
	TextDrawAlignment(textoEquipoVerde, 1);
	TextDrawColor(textoEquipoVerde, 8388863);
	TextDrawSetShadow(textoEquipoVerde, 0);
	TextDrawSetOutline(textoEquipoVerde, 1);
	TextDrawBackgroundColor(textoEquipoVerde, 51);
	TextDrawFont(textoEquipoVerde, 1);
	TextDrawSetProportional(textoEquipoVerde, 1);
	TextDrawBackgroundColor(textoEquipoVerde, 0x000000AA);
	
	textoNickNaranja = TextDrawCreate(176.333328, 128, "Nick");
	TextDrawLetterSize(textoNickNaranja, 0.200000, 1.000000);
	TextDrawAlignment(textoNickNaranja, 1);
	TextDrawColor(textoNickNaranja, -2139062017);
	TextDrawSetShadow(textoNickNaranja, 0);
	TextDrawSetOutline(textoNickNaranja, 1);
	TextDrawBackgroundColor(textoNickNaranja, 51);
	TextDrawFont(textoNickNaranja, 1);
	TextDrawSetProportional(textoNickNaranja, 1);
	TextDrawBackgroundColor(textoNickNaranja, 0x000000AA);
	
	textoDataNaranja = TextDrawCreate(228.666824, 128, "K     M     R");
	TextDrawLetterSize(textoDataNaranja, 0.200000, 1.000000);
	TextDrawAlignment(textoDataNaranja, 1);
	TextDrawColor(textoDataNaranja, -2139062017);
	TextDrawSetShadow(textoDataNaranja, 0);
	TextDrawSetOutline(textoDataNaranja, 1);
	TextDrawBackgroundColor(textoDataNaranja, 51);
	TextDrawFont(textoDataNaranja, 1);
	TextDrawSetProportional(textoDataNaranja, 1);
	TextDrawBackgroundColor(textoDataNaranja, 0x000000AA);
	
	nicksNaranja = TextDrawCreate(145.333343, 143.940734, "[WTx]Andrew_Manu");
	TextDrawLetterSize(nicksNaranja, 0.200000, 1.000000);
	TextDrawAlignment(nicksNaranja, 1);
	TextDrawColor(nicksNaranja, -5963521);
	TextDrawSetShadow(nicksNaranja, 0);
	TextDrawSetOutline(nicksNaranja, 1);
	TextDrawBackgroundColor(nicksNaranja, 51);
	TextDrawFont(nicksNaranja, 1);
	TextDrawSetProportional(nicksNaranja, 1);
	TextDrawBackgroundColor(nicksNaranja, 0x000000AA);
	
	killsNaranja = TextDrawCreate(228.333374, 143, "5");
	TextDrawLetterSize(killsNaranja, 0.200000, 1.000000);
	TextDrawAlignment(killsNaranja, 1);
	TextDrawColor(killsNaranja, -1061109505);
	TextDrawSetShadow(killsNaranja, 0);
	TextDrawSetOutline(killsNaranja, 1);
	TextDrawBackgroundColor(killsNaranja, 51);
	TextDrawFont(killsNaranja, 1);
	TextDrawSetProportional(killsNaranja, 1);
	TextDrawBackgroundColor(killsNaranja, 0x000000AA);

	muertesNaranja = TextDrawCreate(250.000015, 143, "7");
	TextDrawLetterSize(muertesNaranja, 0.200000, 1.000000);
	TextDrawAlignment(muertesNaranja, 1);
	TextDrawColor(muertesNaranja, -1061109505);
	TextDrawSetShadow(muertesNaranja, 0);
	TextDrawSetOutline(muertesNaranja, 1);
	TextDrawBackgroundColor(muertesNaranja, 51);
	TextDrawFont(muertesNaranja, 1);
	TextDrawSetProportional(muertesNaranja, 1);
	TextDrawBackgroundColor(muertesNaranja, 0x000000AA);
	
	ratiosNaranja = TextDrawCreate(266.333190, 143, "1.23");
	TextDrawLetterSize(ratiosNaranja, 0.200000, 1.000000);
	TextDrawAlignment(ratiosNaranja, 1);
	TextDrawColor(ratiosNaranja, -1061109505);
	TextDrawSetShadow(ratiosNaranja, 0);
	TextDrawSetOutline(ratiosNaranja, 1);
	TextDrawBackgroundColor(ratiosNaranja, 51);
	TextDrawFont(ratiosNaranja, 1);
	TextDrawSetProportional(ratiosNaranja, 1);
	TextDrawBackgroundColor(ratiosNaranja, 0x000000AA);
	
	textoNickVerde = TextDrawCreate(332.000366, 128, "Nick");
	TextDrawLetterSize(textoNickVerde, 0.200000, 1.000000);
	TextDrawAlignment(textoNickVerde, 1);
	TextDrawColor(textoNickVerde, -2139062017);
	TextDrawSetShadow(textoNickVerde, 0);
	TextDrawSetOutline(textoNickVerde, 1);
	TextDrawBackgroundColor(textoNickVerde, 51);
	TextDrawFont(textoNickVerde, 1);
	TextDrawSetProportional(textoNickVerde, 1);
	TextDrawBackgroundColor(textoNickVerde, 0x000000AA);
	
	nicksVerde = TextDrawCreate(298.333251, 143, "[WTx]ScorpioN");
	TextDrawLetterSize(nicksVerde, 0.200000, 1.000000);
	TextDrawAlignment(nicksVerde, 1);
	TextDrawColor(nicksVerde, 8388863);
	TextDrawSetShadow(nicksVerde, 0);
	TextDrawSetOutline(nicksVerde, 1);
	TextDrawBackgroundColor(nicksVerde, 51);
	TextDrawFont(nicksVerde, 1);
	TextDrawSetProportional(nicksVerde, 1);
	TextDrawBackgroundColor(nicksVerde, 0x000000AA);
	
	textoDataVerde = TextDrawCreate(387.666717, 128, "K     M     R");
	TextDrawLetterSize(textoDataVerde, 0.200000, 1.000000);
	TextDrawAlignment(textoDataVerde, 1);
	TextDrawColor(textoDataVerde, -2139062017);
	TextDrawSetShadow(textoDataVerde, 0);
	TextDrawSetOutline(textoDataVerde, 1);
	TextDrawBackgroundColor(textoDataVerde, 51);
	TextDrawFont(textoDataVerde, 1);
	TextDrawSetProportional(textoDataVerde, 1);
	TextDrawBackgroundColor(textoDataVerde, 0x000000AA);
	
	killsVerde = TextDrawCreate(387.999664, 141.451873, "6");
	TextDrawLetterSize(killsVerde, 0.200000, 1.000000);
	TextDrawAlignment(killsVerde, 1);
	TextDrawColor(killsVerde, -1);
	TextDrawSetShadow(killsVerde, 0);
	TextDrawSetOutline(killsVerde, 1);
	TextDrawBackgroundColor(killsVerde, 51);
	TextDrawFont(killsVerde, 1);
	TextDrawSetProportional(killsVerde, 1);
	TextDrawBackgroundColor(killsVerde, 0x000000AA);
	
	muertesVerde = TextDrawCreate(409.333038, 141.451843, "8");
	TextDrawLetterSize(muertesVerde, 0.200000, 1.000000);
	TextDrawAlignment(muertesVerde, 1);
	TextDrawColor(muertesVerde, -1);
	TextDrawSetShadow(muertesVerde, 0);
	TextDrawSetOutline(muertesVerde, 1);
	TextDrawBackgroundColor(muertesVerde, 51);
	TextDrawFont(muertesVerde, 1);
	TextDrawSetProportional(muertesVerde, 1);
	TextDrawBackgroundColor(muertesVerde, 0x000000AA);
	
	ratiosVerde = TextDrawCreate(425.000061, 141.866638, "1.24");
	TextDrawLetterSize(ratiosVerde, 0.200000, 1.000000);
	TextDrawAlignment(ratiosVerde, 1);
	TextDrawColor(ratiosVerde, -1);
	TextDrawSetShadow(ratiosVerde, 0);
	TextDrawSetOutline(ratiosVerde, 1);
	TextDrawBackgroundColor(ratiosVerde, 51);
	TextDrawFont(ratiosVerde, 1);
	TextDrawSetProportional(ratiosVerde, 1);
	TextDrawBackgroundColor(ratiosVerde, 0x000000AA);

	fondoInfoPartida = TextDrawCreate(393.333312, 292.285095, "usebox");
	TextDrawLetterSize(fondoInfoPartida, 0.000000, 5.733328);
	TextDrawTextSize(fondoInfoPartida, 215.666687, 0.000000);
	TextDrawAlignment(fondoInfoPartida, 1);
	TextDrawColor(fondoInfoPartida, 0);
	TextDrawUseBox(fondoInfoPartida, true);
	TextDrawBoxColor(fondoInfoPartida, 102);
	TextDrawSetShadow(fondoInfoPartida, 0);
	TextDrawSetOutline(fondoInfoPartida, 0);
	TextDrawFont(fondoInfoPartida, 3);

	textoEquipoGanador = TextDrawCreate(228, 296.177978, "Equipo ganador: Naranja");
	TextDrawLetterSize(textoEquipoGanador, 0.200000, 1.000000);
	TextDrawAlignment(textoEquipoGanador, 1);
	TextDrawColor(textoEquipoGanador, -1);
	TextDrawSetShadow(textoEquipoGanador, 1);
	TextDrawSetOutline(textoEquipoGanador, 0);
	TextDrawBackgroundColor(textoEquipoGanador, 51);
	TextDrawFont(textoEquipoGanador, 1);
	TextDrawSetProportional(textoEquipoGanador, 1);
	TextDrawBackgroundColor(ratiosVerde, 0x000000AA);
}
mostrarTextResultadoCW(){
    TextDrawShowForAll(fondoResultado);
    TextDrawShowForAll(textoResultado);
	TextDrawShowForAll(textoEquipoNaranja);
    TextDrawShowForAll(textoEquipoVerde);

    TextDrawShowForAll(textoNickNaranja);
    TextDrawShowForAll(textoDataNaranja);
    TextDrawShowForAll(nicksNaranja);
    TextDrawShowForAll(killsNaranja);
	TextDrawShowForAll(muertesNaranja);
    TextDrawShowForAll(ratiosNaranja);
    
    TextDrawShowForAll(textoNickVerde);
    TextDrawShowForAll(textoDataVerde);
    TextDrawShowForAll(nicksVerde);
    TextDrawShowForAll(killsVerde);
	TextDrawShowForAll(muertesVerde);
    TextDrawShowForAll(ratiosVerde);
    
    TextDrawShowForAll(fondoInfoPartida);
	TextDrawShowForAll(textoEquipoGanador);
}

ocultarTextResultadoCW(){
    TextDrawHideForAll(fondoResultado);
    TextDrawHideForAll(textoResultado);
	TextDrawHideForAll(textoEquipoNaranja);
    TextDrawHideForAll(textoEquipoVerde);

    TextDrawHideForAll(textoNickNaranja);
    TextDrawHideForAll(textoDataNaranja);
    TextDrawHideForAll(nicksNaranja);
    TextDrawHideForAll(killsNaranja);
	TextDrawHideForAll(muertesNaranja);
    TextDrawHideForAll(ratiosNaranja);

    TextDrawHideForAll(textoNickVerde);
    TextDrawHideForAll(textoDataVerde);
    TextDrawHideForAll(nicksVerde);
    TextDrawHideForAll(killsVerde);
	TextDrawHideForAll(muertesVerde);
    TextDrawHideForAll(ratiosVerde);

    TextDrawHideForAll(fondoInfoPartida);
	TextDrawHideForAll(textoEquipoGanador);
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

crearTextDrawsEntrada(){
	fondoUnoEntrada = TextDrawCreate(389.000274, 351.188934, "usebox");
	TextDrawLetterSize(fondoUnoEntrada, 0.000000, 1.982100);
	TextDrawTextSize(fondoUnoEntrada, 247.333251, 0.000000);
	TextDrawAlignment(fondoUnoEntrada, 1);
	TextDrawColor(fondoUnoEntrada, 0);
	TextDrawUseBox(fondoUnoEntrada, true);
	TextDrawBoxColor(fondoUnoEntrada, 102);
	TextDrawSetShadow(fondoUnoEntrada, 0);
	TextDrawSetOutline(fondoUnoEntrada, 0);
	TextDrawFont(fondoUnoEntrada, 0);

	toxicWarriorsEntrada = TextDrawCreate(251.333282, 353.007385, "TOXIC WARRIORS");
	TextDrawLetterSize(toxicWarriorsEntrada, 0.449999, 1.600000);
	TextDrawAlignment(toxicWarriorsEntrada, 1);
	TextDrawColor(toxicWarriorsEntrada, -5963521);
	TextDrawSetShadow(toxicWarriorsEntrada, 0);
	TextDrawSetOutline(toxicWarriorsEntrada, 1);
	TextDrawBackgroundColor(toxicWarriorsEntrada, 51);
	TextDrawFont(toxicWarriorsEntrada, 1);
	TextDrawSetProportional(toxicWarriorsEntrada, 1);
	TextDrawBackgroundColor(toxicWarriorsEntrada, 0x000000AA);

	versionEntrada = TextDrawCreate(296.000000, 379.140747, "CW/TG v0.2");
	TextDrawLetterSize(versionEntrada, 0.200000, 1.000000);
	TextDrawAlignment(versionEntrada, 1);
	TextDrawColor(versionEntrada, -1061109505);
	TextDrawSetShadow(versionEntrada, 0);
	TextDrawSetOutline(versionEntrada, 1);
	TextDrawBackgroundColor(versionEntrada, 51);
	TextDrawFont(versionEntrada, 1);
	TextDrawSetProportional(versionEntrada, 1);
	TextDrawBackgroundColor(versionEntrada, 0x000000AA);

	fondoDosEntrada = TextDrawCreate(343.666625, 378.566741, "usebox");
	TextDrawLetterSize(fondoDosEntrada, 0.000000, 1.250407);
	TextDrawTextSize(fondoDosEntrada, 290.999969, 0.000000);
	TextDrawAlignment(fondoDosEntrada, 1);
	TextDrawColor(fondoDosEntrada, 0);
	TextDrawUseBox(fondoDosEntrada, true);
	TextDrawBoxColor(fondoDosEntrada, 102);
	TextDrawSetShadow(fondoDosEntrada, 0);
	TextDrawSetOutline(fondoDosEntrada, 0);
	TextDrawFont(fondoDosEntrada, 0);
}

ocultarTextDrawsEntrada(playerid){
		TextDrawHideForPlayer(playerid, fondoUnoEntrada);
		TextDrawHideForPlayer(playerid, fondoDosEntrada);
		TextDrawHideForPlayer(playerid, versionEntrada);
		TextDrawHideForPlayer(playerid, toxicWarriorsEntrada);
}
mostrarTextDrawsEntrada(playerid){
		TextDrawShowForPlayer(playerid, fondoUnoEntrada);
		TextDrawShowForPlayer(playerid, fondoDosEntrada);
		TextDrawShowForPlayer(playerid, versionEntrada);
		TextDrawShowForPlayer(playerid, toxicWarriorsEntrada);
}

crearTextDrawsCW(){
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

	puntajeEquipos = TextDrawCreate(180, 428, "Puntos: (1) 5 - 14 (2)");
	TextDrawLetterSize(puntajeEquipos, 0.200000, 1.000000);
	TextDrawAlignment(puntajeEquipos, 1);
	TextDrawColor(puntajeEquipos, -1);
	TextDrawSetShadow(puntajeEquipos, 0);
	TextDrawSetOutline(puntajeEquipos, 1);
	TextDrawBackgroundColor(puntajeEquipos, 51);
	TextDrawFont(puntajeEquipos, 1);
	TextDrawSetProportional(puntajeEquipos, 1);
	TextDrawBackgroundColor(puntajeEquipos, 0x000000AA);

	partidaRondas = TextDrawCreate(273, 428, "Ronda: 2/3");
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
