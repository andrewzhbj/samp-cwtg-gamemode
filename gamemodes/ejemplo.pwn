stock cargarDatos(playerid)
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

stock guardarDatos(playerid)
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
