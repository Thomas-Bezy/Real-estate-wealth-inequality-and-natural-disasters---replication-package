libname data "..\Data";
libname raw_data "..\Data\Raw_datasets";
libname baseline "\\casd.fr\casdfs\Projets\..\Data\Logement_FIDELI_2017";


****************************************************************
*********************Geographical Locations*********************
****************************************************************

*This code prepares the FIDELI dataset.


*First, I consider fideli_local17. I take the id_log of every building and its
coordinates. Then, I create 4 files: metropolitan France in 3 files + oversea
departments in 1 file.



******For Fideli_diff_1;

data raw_data.fideli_loc_metro (keep= id_log x y);
set baseline.fideli_local17_diff_1 ;
where id_log not =. AND x not =.;
run;

proc export data=raw_data.fideli_loc_metro DBMS=csv
outfile="..\Data\fideli_loc_1.csv"
replace;
delimiter=",";
run;


******For Fideli_diff_2;

data raw_data.fideli_loc_metro (keep= id_log x y);
set baseline.fideli_local17_diff_2 ;
where id_log not =. AND x not =.;
run;

proc export data=raw_data.fideli_loc_metro DBMS=csv
outfile="..\Data\fideli_loc_2.csv"
replace;
delimiter=",";
run;


******For Fideli_diff_3;

data raw_data.fideli_loc (keep= id_log x y depcom2);
set baseline.fideli_local17_diff_3 ;
where id_log not =. AND x not =.;
run;

data raw_data.fideli_loc;
set raw_data.fideli_loc ;
depcom2_substr=substr(depcom2,1,2);
depcom2_oversea_code=substr(depcom2,3,1);
run;

*Create 2 datasets: one for metropolitan France and one for oversea departments;
data raw_data.fideli_loc_metro raw_data.fideli_loc_om;
set raw_data.fideli_loc ;
if depcom2_substr=97  then output raw_data.fideli_loc_om;
else output raw_data.fideli_loc_metro;
run;

data raw_data.fideli_loc_metro (drop= depcom2 depcom2_substr depcom2_oversea_code);
set raw_data.fideli_loc_metro ;
run;

data raw_data.fideli_loc_om (drop= depcom2 depcom2_substr);
set raw_data.fideli_loc_om ;
run;

proc export data=raw_data.fideli_loc_metro DBMS=csv
outfile="..\Data\fideli_loc_3.csv"
replace;
delimiter=",";
run;

proc export data=raw_data.fideli_loc_om DBMS=csv
outfile="..\Data\fideli_loc_4.csv"
replace;
delimiter=",";
run;

proc export data=raw_data.fideli_loc_om (keep= id_log x y) DBMS=dta
outfile="..\Data\_fideli_nodata_4.dta"
replace;
run;


*******Delete datasets;
proc datasets library=raw_data nolist;
delete fideli_loc_metro fideli_loc_om fideli_loc;
quit;











****************************************************************
*****************Socio-Economic Characteristics*****************
****************************************************************

*Here I want to extract socio economic data + building characteristics from Fideli

*********************
********PART1********
*********************

*First, I take data on income from fideli_revenus;
data raw_data.fideli_income (keep= id_log revdispm id_log zfonm zvamm nivviem);
set baseline.fideli_revenus_filosofi17 ;
where id_log not =.;
run;

*Duplicates were included because there is information on past income in the dataset;
*We do not care about this here so we can simply gather observations with the same IDs;
proc sort data=raw_data.fideli_income out=raw_data.fideli_income nodupkey;
by id_log;
run;

*********************
********PART2********
*********************

*Second, I take data on housing characteristics from fideli_local;
*I have 3 datasets so I reproduce it 3 times and append datasets;
data raw_data.fideli_log (keep= id_log type_res2 NIVF OCC SURFTOT 
NATLOC depcom2 date_const ADRENV TYPPMO DATEACTE DATEPERS vloc17 tax_logement
REFCAD iris OCC2016 anais_prop x y rue1 noimm1);
set baseline.fideli_local17_diff_1 ;
run;

data raw_data.fideli_log_append (keep= id_log type_res2 NIVF OCC SURFTOT 
NATLOC depcom2 date_const ADRENV TYPPMO DATEACTE DATEPERS vloc17 tax_logement
REFCAD iris OCC2016 anais_prop x y rue1 noimm1);
set baseline.fideli_local17_diff_2 ;
run;

proc append base=raw_data.fideli_log data=raw_data.fideli_log_append;
run;

data raw_data.fideli_log_append (keep= id_log type_res2 NIVF OCC SURFTOT 
NATLOC depcom2 date_const ADRENV TYPPMO DATEACTE DATEPERS vloc17 tax_logement
REFCAD iris OCC2016 anais_prop x y rue1 noimm1);
set baseline.fideli_local17_diff_3 ;
run;

proc append base=raw_data.fideli_log data=raw_data.fideli_log_append;
run;

*We delete useless datasets;
proc datasets library=raw_data nolist;
delete fideli_log_append;
quit;


*There are just around 450 000 obs without id_log. We take them out.
*They correspond to observations of the past year;
data raw_data.fideli_log;
set raw_data.fideli_log ;
where id_log not =. AND (NATLOC="MA" OR NATLOC="ME" or NATLOC="AP");
run;

*400 observations appearing twice. We remove them;
proc sort data=raw_data.fideli_log out=raw_data.fideli_log nodupkey;
by id_log;
run;

*We only primary homes, secondary homes and empty dwellings;
data raw_data.fideli_log;
set raw_data.fideli_log ;
where type_res2="1" OR type_res2="2" OR type_res2="3" OR type_res2="4" OR type_res2="6";
run;
*36 626 008 dwellings that we cover;





*********************
********PART3********
*********************
*Here we need to link individuals with their secondary houses
*I must use fichiers individuels and link them to fideli_income thanks to id_log;

*We first create a dataset with secondary houses IDs;
data raw_data.fideli_sec (keep= id_log id_log_sec1 id_log_sec2);
set baseline.fideli_individu17_diff_1 ;
run;

data raw_data.fideli_sec_append (keep= id_log id_log_sec1 id_log_sec2);
set baseline.fideli_individu17_diff_2 ;
run;

proc append base=raw_data.fideli_sec data=raw_data.fideli_sec_append;
run;

data raw_data.fideli_sec_append (keep= id_log id_log_sec1 id_log_sec2);
set baseline.fideli_individu17_diff_3 ;
run;

proc append base=raw_data.fideli_sec data=raw_data.fideli_sec_append;
run;



*We create a dataset with just one column with id_log1 and id_log2;
*First secondary house;
data raw_data.fideli_sec1 (keep=id_log id_log_sec1);
set raw_data.fideli_sec;
where id_log_sec1 not =.;
run;

data raw_data.fideli_sec1;
rename id_log_sec1=id_log_sec;
set raw_data.fideli_sec1;
run;

*Second secondary house;
data raw_data.fideli_sec2 (keep=id_log id_log_sec2);
set raw_data.fideli_sec;
where id_log_sec2 not =.;
run;

data raw_data.fideli_sec2;
rename id_log_sec2=id_log_sec;
set raw_data.fideli_sec2;
run;

proc append base=raw_data.fideli_sec1 data=raw_data.fideli_sec2;
run;

*We rename the dataset of interest and delete useless datasets;
data raw_data.fideli_sec;
set raw_data.fideli_sec1;
run;

proc datasets library=raw_data nolist;
delete fideli_sec_append fideli_sec1 fideli_sec2;
quit;




***Here we merge with data on income to associate every secondary house to an 
income level;
*I remove the duplicated keys and keep households owning multiple sec homes;
proc sort data=raw_data.fideli_sec out=raw_data.fideli_sec nodupkey;
by id_log id_log_sec;
run;

*We merge;
data raw_data.fideli_sec_char;
merge raw_data.fideli_sec  raw_data.fideli_income;
by id_log;
run;

*Keep non missing values;
data raw_data.fideli_sec_char;
set raw_data.fideli_sec_char;
where id_log_sec not =.;
run;

*Some missing owner_id in Fideli_ind, we exclude them because in any case we won't
be able to find them later, se we can exclude them;
data raw_data.fideli_sec_char;
set raw_data.fideli_sec_char;
where id_log not =.;
run;

***Consistency checks;
proc sort data=raw_data.fideli_sec_char out=raw_data.fideli_sec_char;
by id_log;
run;
*The same household can ownmultiple secondary homes (e.g.: id_log=274);

proc sort data=raw_data.fideli_sec_char out=raw_data.temp nouniquekey;
by id_log_sec;
run;
*The same dwelling can belong to multiple households (example with id_log_sec=6071);

*If a dwellings belongs to several households, we put a weight;
*First we count the number of occurence;

data raw_data.fideli_sec_char;
set raw_data.fideli_sec_char;
num=1;
run;

proc sql;
create table raw_data.fideli_sec_char as
select *,sum(num) as count 
from raw_data.fideli_sec_char group by id_log_sec;
quit;

data raw_data.fideli_sec_char (drop=count num);
set raw_data.fideli_sec_char;
WEIGHT=1/count;
run;

proc sort data=raw_data.fideli_sec_char out=raw_data.aaa nouniquekey;
by id_log_sec;
run;
proc sort data=raw_data.aaa out=raw_data.aaa nodupkey;
by id_log_sec;
run;

*Here we rename columns: ID_OWNER and ID_DWELLING;
data raw_data.fideli_sec_char;
set raw_data.fideli_sec_char;
rename id_log=ID_OWNER;
rename id_log_sec=id_log;
run;



*********************
********PART4********
*********************;

data raw_data.fideli_princ_char;
set raw_data.fideli_income;
ID_OWNER=.;
WEIGHT=.;
run;


*We first append datasets on princ and secondary housing;
proc append base=raw_data.fideli_princ_char data=raw_data.fideli_sec_char ;
run;


*We merge the datasets from the 3 previous parts
*We first sort the data;
proc sort data=raw_data.fideli_princ_char out=raw_data.fideli_princ_char;
by id_log;
run;
proc sort data=raw_data.fideli_log out=raw_data.fideli_log;
by id_log;
run;

*We merge;
data raw_data.fideli_dem;
merge raw_data.fideli_log raw_data.fideli_princ_char ;
by id_log;
run;

proc sort data=raw_data.fideli_dem out=raw_data.temp nouniquekey;
by id_log;
run;

data raw_data.temp;
set raw_data.temp;
retain flag;
if missing(WEIGHT)  then flag=10;
else flag=WEIGHT;
run;

proc sql;
create table raw_data.temp as 
select *,
sum(flag) as flag2
from raw_data.temp
group by id_log;
quit;

data raw_data.temp;
set raw_data.temp;
where (WEIGHT=. AND flag2>10) OR flag2=1;
run;

data raw_data.temp (drop=flag flag2);
set raw_data.temp;
run;

*We remove all observations appearing twice;
data raw_data.temp2;
set raw_data.fideli_dem;
num=1;
run;

proc sql;
create table raw_data.temp2 as
select *,sum(num) as count 
from raw_data.temp2 group by id_log;
quit;

data raw_data.temp2;
set raw_data.temp2;
where count=1;
run;

data raw_data.temp2 (drop=num count);
set raw_data.temp2;
run;

**Now we append the duplicates and no duplicated observations;
proc append base=raw_data.temp data=raw_data.temp2 ;
run;


data raw_data.fideli_dem2;
set raw_data.temp;
where OCC not = "";
run;


*********************
********PART5********
*********************;

*Adjust OWNERS AND RENTERS IDs;
data raw_data.fideli_dem2;
set raw_data.fideli_dem2;
if type_res2=1 and OCC="P" then ID_OWNER=id_log;
if type_res2=1 and OCC="P" then WEIGHT=1;
if type_res2=1 and OCC="L" then ID_OWNER=.;
if type_res2=1 and OCC="L" then ID_RENTER=id_log;
if type_res2=1 and OCC="L" then WEIGHT=.;
run;

*Create new variables for income;
data raw_data.fideli_dem2;
set raw_data.fideli_dem2;
if OCC="P" then OWNER_FONCIER=zfonm;
if OCC="P" then OWNER_MOB=zvamm;
if OCC="P" then OWNER_INCOME_TOTAL=revdispm;
if OCC="P" then OWNER_INCOME=nivviem;
run;

data raw_data.fideli_dem2;
set raw_data.fideli_dem2;
if OCC="L" then RENTER_FONCIER=zfonm;
if OCC="L" then RENTER_MOB=zvamm;
if OCC="L" then RENTER_INCOME_TOTAL=revdispm;
if OCC="L" then RENTER_INCOME=nivviem;
run;


data raw_data.fideli_dem2 (drop=zfonm zvamm revdispm nivviem);
set raw_data.fideli_dem2;
run;


















