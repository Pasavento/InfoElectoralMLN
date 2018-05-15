*Importación completa de tablas de participación, resultados y candidaturas (esta última para remplazar el código del partido de las tablas precedentes por su nombre y siglas);

data Candidaturas_global;
	infile '/folders/myfolders/sasuser.v94/_SENADO/2011 Senado/03031111.DAT' ENCODING='wlatin1';
	input Tipo 1-2 Year 3-6 Mes 7-8 Partido $ 12-14 Siglas $ 15-64 Nombre $ 65-214 
		Codigo_prov 215-220 Codigo_CCAA 221-226 Codigo_nac 227-232;
run;

data Candidatos_global;
	infile '/folders/myfolders/sasuser.v94/_SENADO/2011 Senado/04031111.DAT' ENCODING='wlatin1';
	input Tipo 1-2 Year 3-6 Mes 7-8 Vuelta 9 Prov 10-11 Distr_elect 12 Partido_senador $ 13-15 
		Partido $ 19-21 Orden 22-24 Titular $ 25 Nombre_senador $ 26-50 Apellido_1 $ 51-75 Apellido_2 $ 76-100 
		Sexo $ 101 Dia_birth 102-103 Mes_birth 104-105 Year_birth 106-109 DNI $ 110-119 Electo $ 120;
	if Prov=52;
	Senador=TRIM(Nombre_senador)||' '||TRIM(Apellido_1)||' '||TRIM(Apellido_2);
run;

data Participacion_MLN;
	infile '/folders/myfolders/sasuser.v94/_SENADO/2011 Senado/09031111.DAT' ENCODING='wlatin1';
	input Tipo 1-2 Year 3-6 Mes 7-8 Vuelta 9 CCAA 10-11 Prov 12-13 Mun 14-16 
		Distr $ 18 Secc $ 21-22 Mesa $ 23 INE 24-30 CERA 31-37 CERE 38-44 CEREV 45-51 
		AV1 52-58 AV2 59-65 Blanco 66-72 Nulo 73-79 Cand 80-86 Si 87-93 No 94-100 
		Oficial $ 101;
	ID=Distr||'-'||Secc;

	if Prov=52;
run;

data Resultados_MLN;
	infile '/folders/myfolders/sasuser.v94/_SENADO/2011 Senado/10031111.DAT' ENCODING='wlatin1';
	input Tipo 1-2 Year 3-6 Mes 7-8 Vuelta 9 CCAA 10-11 Prov 12-13 Mun 14-16 
		Distr $ 18 Secc $ 21-22 Mesa $ 23 Partido_senador $ 27-29 Votos 30-36;
	ID=Distr||'-'||Secc;

	if Prov=52;
run;

*Reducción de mesas a secciones de RESULTADOS y PARTICIPACION;

PROC SUMMARY DATA=Resultados_MLN nway;
	class ID Distr Secc Partido_Senador;
	var Votos;
	output out=Resultados_Secciones (drop=_freq_ _type_) sum=;
run;

PROC SUMMARY DATA=Participacion_MLN nway;
	class ID Distr Secc;
	var INE CERA CERE CEREV AV1 AV2 Blanco Nulo Cand Si No;
	output out=Participacion_Secciones (drop=_freq_ _type_) sum=;
run;

*Fusión de datos de candidaturas con los datos de cada candidato para averiguar cuáles corresponden a Melilla;

PROC SORT DATA=Candidatos_global;
	BY Partido;
run;

PROC SORT DATA=Candidaturas_global;
	BY Partido;
run;

data Candidatos_MLN_Siglas;
	MERGE Candidatos_global (IN=a) Candidaturas_global (IN=b);
	BY Partido;
	Senador_siglas=TRIM(Senador)||' ('||TRIM(Siglas)||')';
	IF a=1 and b=1 then
		output;
run;

*Ordenar tablas de resultados y candidaturas y fusión remplazando códigos de partidos por su nombre y siglas y eliminando otros partidos nivel nacional;

PROC SORT DATA=Resultados_Secciones;
	BY Partido_senador;
run;

PROC SORT DATA=Candidatos_MLN_Siglas;
	BY Partido_senador;
run;

data Resultados_secciones_senador;
	MERGE Resultados_Secciones (IN=a) Candidatos_MLN_Siglas (IN=b);
	DROP Year Mes Vuelta Prov Codigo_prov Codigo_CCAA Codigo_nac Distr_elect Senador Partido Orden Titular Sexo Dia_birth Mes_birth Year_birth DNI Electo;
	BY Partido_senador;

	IF a=1 and b=1 then
		output;
run;

*Reducir tabla de resultados por partidos y no por senadores a nivel de secciones electorales + transposición a votos a partidos;

PROC SUMMARY DATA=Resultados_secciones_senador nway;
	class ID Distr Secc Siglas;
	var Votos;
	output out=Resultados_Secciones_partidos (drop=_freq_ _type_) sum=;
run;

PROC SORT DATA=Resultados_Secciones_partidos;
	BY Distr Secc;
run;

PROC TRANSPOSE DATA=Resultados_secciones_partidos OUT=Resultados_secc_partidos_transp;
	BY ID distr secc;
	VAR Votos;
	ID Siglas;
	IDLABEL Siglas;
RUN;

*Transposición de votos y siglas. Votos a cada senador, no a partido;

PROC SORT DATA=Resultados_secciones_senador;
	BY Distr Secc;
run;

PROC TRANSPOSE DATA=Resultados_secciones_senador OUT=Resultados_secc_senador_transp;
	BY ID distr secc;
	VAR Votos;
	ID Senador_siglas;
	IDLABEL Senador_siglas;
RUN;

*Ordenar tablas de resultados con nombre de senador y siglas de partido y fusión con datos de participación por mesa. RESULTADO: DATOS COMPLETOS POR MESA ELECTORAL PARA CADA SENADOR;

PROC SORT DATA=Participacion_secciones;
	BY Distr Secc;
run;

PROC SORT DATA=Resultados_secc_senador_transp;
	BY Distr Secc;
run;

data Todo_MLN_Secc_Senador;
	MERGE Resultados_secc_senador_transp (IN=a) Participacion_secciones (IN=b);
	DROP _Name_ Si No;
	BY ID Distr Secc;

	IF a=1 and b=1 then
		output;
run;


*Ordenar tablas de resultados por siglas de partido y fusión con datos de participación por mesa. RESULTADO: DATOS COMPLETOS POR MESA ELECTORAL PARA CADA PARTIDO (suma ambos senadores);

PROC SORT DATA=Participacion_secciones;
	BY Distr Secc;
run;

PROC SORT DATA=Resultados_secc_partidos_transp;
	BY Distr Secc;
run;

data Todo_MLN_Secc_Partidos;
	MERGE Resultados_secc_Partidos_transp (IN=a) Participacion_secciones (IN=b);
	DROP _Name_ Si No;
	BY ID Distr Secc;

	IF a=1 and b=1 then
		output;
run;

*Exportación a Excel;

PROC EXPORT DATA=Todo_MLN_Secc_Senador DBMS=XLS LABEL 
		OUTFILE='/folders/myfolders/sasuser.v94/ELECIONNES_MLN_FINAL_SECCIONES' REPLACE;
		SHEET='12011 Senadores'; *UTILIZAR cambiando el nombre de SHEET para añadir nueva hoja al mismo fichero Excel, p.ej. año de elecciones;
RUN;

PROC EXPORT DATA=Todo_MLN_Secc_Partidos DBMS=XLS LABEL 
		OUTFILE='/folders/myfolders/sasuser.v94/ELECIONNES_MLN_FINAL_SECCIONES' REPLACE;
		SHEET='12011 Senado'; *UTILIZAR cambiando el nombre de SHEET para añadir nueva hoja al mismo fichero Excel, p.ej. año de elecciones;
RUN;
