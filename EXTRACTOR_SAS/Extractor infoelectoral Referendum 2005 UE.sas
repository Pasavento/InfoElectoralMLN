*Importación completa de tablas de participación, resultados y candidaturas (esta última para remplazar el código del partido de las tablas precedentes por su nombre y siglas);

data Participacion_MLN;
	infile '/folders/myfolders/sasuser.v94/_REFERENDUM/2005 Referendum/09010502.DAT' ENCODING='wlatin1';
	input Prov 12-13 Distr $ 18 Secc $ 20-22 Mesa $ 23 INE 24-30 CERA 31-37 CERE 38-44 CEREV 45-51 
		AV1 52-58 AV2 59-65 Blanco 66-72 Nulo 73-79 Cand 80-86 Si 87-93 No 94-100 
		Oficial $ 101;
	ID=Distr||'-'||Secc;

	if Prov=52;
run;

PROC SORT DATA=Participacion_MLN;
	BY Distr Secc;
run;

PROC SUMMARY DATA=Participacion_MLN nway;
	class ID Distr Secc;
	var _NUMERIC_;
	output out=Todo_MLN_Secciones (drop=_freq_ _type_ Prov) sum=;
run;

PROC EXPORT DATA=Todo_MLN_Secciones DBMS=XLS LABEL 
		OUTFILE='/folders/myfolders/sasuser.v94/ELECIONNES_MLN_FINAL_SECCIONES' REPLACE;
		SHEET='22005 Ref. UE'; *UTILIZAR cambiando el nombre de SHEET para añadir nueva hoja al mismo fichero Excel, p.ej. año de elecciones;
RUN;
