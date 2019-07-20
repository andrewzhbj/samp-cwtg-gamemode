/*
 *  Modo CW/TG (Clan War & Training)
 *  © por Andrew Manu :)
*/

#include <a_samp>
#include <zcmd>

static Equipo[MAX_PLAYERS];

new DB:Cuentas;

#define EQUIPO_ESPECTADOR  	0
#define EQUIPO_NARANJA 		1
#define EQUIPO_VERDE 		2

#define COLOR_BLANCO 		0xFFFFFFFF
#define COLOR_NARANJA 		0xF78411FF
#define COLOR_VERDE 		0x77CC77FF
#define COLOR_ROJO      	0x9C001fFF

#define DIALOG_REGISTRO 	1
#define DIALOG_LOGEAR   	2
#define DIALOG_COMANDOS 	3


#pragma tabsize 0

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
new DB_Query[1000];


forward establecerVariables(playerid);
public establecerVariables(playerid)
{
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
	print("\n");
	print("Gamemode: CW/TG\n");
	print("Desarrollador: Andrew_Manu\n");
}

public OnPlayerConnect(playerid)
{
	establecerVariables(playerid);
	
	infoJugador[playerid][Nombre] = nombre(playerid);
	infoJugador[playerid][ip] = IP(playerid);
	
    new DBResult:resultado, Dialogo[240];
    format(DB_Query, sizeof(DB_Query), "SELECT * FROM cuentas WHERE nick = '%s'", infoJugador[playerid][Nombre]);
    resultado = db_query(Cuentas, DB_Query);
    printf("%d", db_num_rows(resultado));
    
    if(db_num_rows(resultado)){
    
	}else{
        format(Dialogo, sizeof(Dialogo),"Ésta cuenta no esta {C20000}registrada\n{FFFFFF}Digite una contraseña para registrarse con el siguiente nick: {7A7A7A}%s (IP:%s)", infoJugador[playerid][Nombre], infoJugador[playerid][ip]);
        ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, "Registro: ", Dialogo, "Registrar", "Cancelar");
    }
	//GameTextForPlayer(playerid,"~w~SA-MP: ~r~Bare Script",5000,5);
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(!success)
	{
    	PlayerPlaySound(playerid,1054,0.0,0.0,0.0);
    	SendClientMessage(playerid, COLOR_ROJO, "El comando que escribiste no existe (/cmds)");
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
    Cuentas = db_open("jugadores/cuentas.db");
    
    if(Cuentas){
        printf("La bd Cuentas ha sido abierta ");
        new DBResult:asignacion;
		asignacion = db_query(Cuentas, "CREATE TABLE IF NOT EXISTS cuentas (id INTEGER PRIMARY KEY AUTOINCREMENT, nick TEXT, password TEXT, puntajeRanked NUMERIC, duelosGanados NUMERIC, duelosPerdidos NUMERIC)");
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

public OnGameModeExit()
{
    db_close(Cuentas);
    return 1;
}

CMD:cmds(playerid, params[]){
	//if(Admin[playerid] == 1) ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, "Comandos del sevidor", "Jugadores\nEspectador\nAdministrador nivel 1", "Selec", "Cancelar");
	ShowPlayerDialog(playerid, DIALOG_COMANDOS, DIALOG_STYLE_LIST, "Comandos del sevidor", "Jugadores\nEspectador", "Selec", "Cancelar");
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

