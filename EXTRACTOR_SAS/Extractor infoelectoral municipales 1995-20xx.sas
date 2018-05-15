*Importación completa de tablas de participación, resultados y candidaturas (esta última para remplazar el código del partido de las tablas precedentes por su nombre y siglas);

data Candidaturas_global;
	infile '/folders/myfolders/sasuser.v94/_MUNICIPALES/2015 Municipales/03041505.csv' ENCODING='wlatin1';
	input Tipo 1-2 Year 3-6 Mes 7-8 Partido 9-14 Siglas $ 15-64 Nombre $ 65-214 
		Codigo_prov 215-220 Codigo_CCAA 221-226 Codigo_nac 227-232;
run;

data Participacion_MLN;
	infile '/folders/myfolders/sasuser.v94/_MUNICIPALES/2015 Municipales/09041505.csv' ENCODING='wlatin1';
	input Tipo 1-2 Year 3-6 Mes 7-8 Vuelta 9 CCAA 10-11 Prov 12-13 Mun 14-16 
		Distr $ 18 Secc $ 20-22 Mesa $ 23 INE 24-30 CERA 31-37 CERE 38-44 CEREV 45-51 
		AV1 52-58 AV2 59-65 Blanco 66-72 Nulo 73-79 Cand 80-86 Si 87-93 No 94-100 
		Oficial $ 101;
	ID=Distr||'-'||Secc;

	if Prov=52;
run;

data Resultados_MLN;
	infile '/folders/myfolders/sasuser.v94/_MUNICIPALES/2015 Municipales/10041505.csv' ENCODING='wlatin1';
	input Tipo 1-2 Year 3-6 Mes 7-8 Vuelta 9 CCAA 10-11 Prov 12-13 Mun 14-16 
		Distr $ 18 Secc $ 20-22 Mesa $ 23 Partido 24-29 Votos 30-36;
	ID=Distr||'-'||Secc;

	if Prov=52;
run;

*Ordenar tablas de resultados y candidaturas y fusión remplazando códigos de partidos por su nombre y siglas y eliminando otros partidos nivel nacional;

PROC SORT DATA=Resultados_MLN;
	BY Partido;
run;

PROC SORT DATA=Candidaturas_global;
	BY Partido;
run;

data Resultados_MLN_Siglas;
	MERGE Resultados_MLN (IN=a) Candidaturas_global (IN=b);
	BY Partido;

	IF a=1 and b=1 then
		output;
run;

*Transposición de votos y siglas;

PROC SORT DATA=Resultados_MLN_Siglas;
	BY Distr Secc Mesa;
run;

PROC TRANSPOSE DATA=Resultados_MLN_Siglas OUT=Resultados_MLN_Siglas_transp;
	BY distr secc mesa;
	VAR Votos;
	ID Siglas;
	IDLABEL Siglas;
RUN;

*Ordenar tablas de resultados con siglas y nombres de partido y fusión con datos de participación por mesa. RESULTADO: DATOS COMPLETOS POR MESA ELECTORAL;

PROC SORT DATA=Participacion_MLN;
	BY Distr Secc Mesa;
run;

PROC SORT DATA=Resultados_MLN_Siglas_transp;
	BY Distr Secc Mesa;
run;

data Todo_MLN_Partidos;
	MERGE Resultados_MLN_Siglas_transp (IN=a) Participacion_MLN (IN=b);
	DROP _Name_ Tipo Year Mes Vuelta CCAA Prov Mun Si No Oficial;
	BY Distr Secc Mesa;

	IF a=1 and b=1 then
		output;
run;

*Suma de mesas electorales. RESULTADO: DATOS COMPLETOS POR SECCION ELECTORAL;

PROC SUMMARY DATA=Todo_MLN_Partidos nway;
	class ID Distr Secc;
	var _NUMERIC_;
	output out=Todo_MLN_Secciones (drop=_freq_ _type_) sum=;
run;

PROC EXPORT DATA=Todo_MLN_Secciones DBMS=XLS LABEL 
		OUTFILE='/folders/myfolders/sasuser.v94/ELECIONNES_MLN_FINAL_SECCIONES' REPLACE;
		SHEET='12015 Locales'; *UTILIZAR cambiando el nombre de SHEET para añadir nueva hoja al mismo fichero Excel, p.ej. año de elecciones;
RUN;
