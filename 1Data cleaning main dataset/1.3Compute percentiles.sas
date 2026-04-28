libname data "C:\Users\Public\Documents\Thomas\Insurance\0Data";
libname raw_data "C:\Users\Public\Documents\Thomas\Insurance\0Data\Raw_datasets";




*Put the year, and also modify the year in the 4 following commands;
%let year=22;

******For menages_part1;

data raw_data.filosofi (keep= nb_UC revdispm decile_nivvie);
set "\\casd.fr\casdfs\Projets\ESSCODI\Data\FILOSOFI_FILOSOFI_20&year\Fichier détail apuré_partie1\menages22_part1" ;
where filtre_revdisp =1;
run;

******For menages_part2;

data raw_data.filosofi_append (keep= nb_UC revdispm decile_nivvie);
set "\\casd.fr\casdfs\Projets\ESSCODI\Data\FILOSOFI_FILOSOFI_20&year\Fichier détail apuré_partie2\menages22_part2" ;
where filtre_revdisp =1;
run;

proc append base=raw_data.filosofi data=raw_data.filosofi_append;
run;

******For menages_part3;

data raw_data.filosofi_append (keep= nb_UC revdispm decile_nivvie);
set "\\casd.fr\casdfs\Projets\ESSCODI\Data\FILOSOFI_FILOSOFI_20&year\Fichier détail apuré_partie3\menages22_part3" ;
where filtre_revdisp =1;
run;

proc append base=raw_data.filosofi data=raw_data.filosofi_append;
run;

******For menages_part4;

data raw_data.filosofi_append (keep= nb_UC revdispm decile_nivvie);
set "\\casd.fr\casdfs\Projets\ESSCODI\Data\FILOSOFI_FILOSOFI_20&year\Fichier détail apuré_partie4\menages22_part4" ;
where filtre_revdisp =1;
run;

proc append base=raw_data.filosofi data=raw_data.filosofi_append;
run;

*Create niveau de vie;
data raw_data.filosofi;
set raw_data.filosofi ;
INCOME=revdispm/nb_UC;
run;

*Create percentiles here;
proc rank datadata=raw_data.filosofi out=raw_data.filosofi groups=100;
var INCOME;
ranks INCOME_PERCENTILE;
run;

*Modify the dataset;
data raw_data.filosofi (keep=INCOME INCOME_PERCENTILE);
set raw_data.filosofi ;
INCOME_PERCENTILE=INCOME_PERCENTILE+1;
where INCOME>=0;
run;

*Get the min income by percentile;
proc means data=raw_data.filosofi min;
class INCOME_PERCENTILE;
var INCOME;
output out=raw_data.filosofi;
run;

*Modify the dataset;
data raw_data.filosofi (keep=INCOME_PERCENTILE INCOME);
set raw_data.filosofi ;
where INCOME_PERCENTILE not=. & _STAT_="MIN";
run;

*We export the data;
proc export data=raw_data.filosofi DBMS=dta
outfile="C:\Users\Public\Documents\Thomas\Insurance\0Data\percentiles20&year"
replace;
run;















****For 2022;
libname baseline "\\casd.fr\casdfs\Projets\ESSCODI\Data\Logement_FIDELI_2022";


data raw_data.filosofi (keep= nb_UC revdispm);
set baseline.fideli_revenus_menage22;
run;


*Create niveau de vie;
data raw_data.filosofi;
set raw_data.filosofi ;
INCOME=revdispm/nb_UC;
run;

*Create percentiles here;
proc rank datadata=raw_data.filosofi out=raw_data.filosofi groups=100;
var INCOME;
ranks INCOME_PERCENTILE;
run;

*Modify the dataset;
data raw_data.filosofi (keep=INCOME INCOME_PERCENTILE);
set raw_data.filosofi ;
INCOME_PERCENTILE=INCOME_PERCENTILE+1;
where INCOME>=0;
run;

*Get the min income by percentile;
proc means data=raw_data.filosofi min;
class INCOME_PERCENTILE;
var INCOME;
output out=raw_data.filosofi;
run;

*Modify the dataset;
data raw_data.filosofi (keep=INCOME_PERCENTILE INCOME);
set raw_data.filosofi ;
where INCOME_PERCENTILE not=. & _STAT_="MIN";
run;

*We export the data;
proc export data=raw_data.filosofi DBMS=dta
outfile="C:\Users\Public\Documents\Thomas\Insurance\0Data\percentiles2022"
replace;
run;