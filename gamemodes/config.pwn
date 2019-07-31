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

