libname data "..\Data";
libname raw_data "..\Data\Raw_datasets";
libname baseline "\\casd.fr\casdfs\Projets\..\Data\Logement_FIDELI_2017";


*This code links the FIDELI dataset with information on owners.

*********************
********PART6********
*********************;
*Here we add owners for rental and vacant units;
data raw_data.owned;
set raw_data.fideli_dem2;
where OCC="P";
run;

data raw_data.rented;
set raw_data.fideli_dem2;
where OCC not ="P";
run;

****************************************
*****************Owners*****************
****************************************;


******For Fideli_diff_1;

data raw_data.fideli_ind1 (keep= id_ind ID_HH_OWNER);
set baseline.fideli_individu17_diff_1 ;
rename id_log=ID_HH_OWNER;
run;


******For Fideli_diff_2;

data raw_data.fideli_ind2 (keep= id_ind ID_HH_OWNER);
set baseline.fideli_individu17_diff_2 ;
rename id_log=ID_HH_OWNER;
run;


******For Fideli_diff_3;

data raw_data.fideli_ind3 (keep= id_ind ID_HH_OWNER);
set baseline.fideli_individu17_diff_3 ;
rename id_log=ID_HH_OWNER;
run;

proc append base=raw_data.fideli_ind1 data=raw_data.fideli_ind2;
run;

proc append base=raw_data.fideli_ind1 data=raw_data.fideli_ind3;
run;

data raw_data.fideli_ind ;
set raw_data.fideli_ind1 ;
run;


*******Delete datasets;
proc datasets library=raw_data nolist;
delete fideli_ind1 fideli_ind2 fideli_ind3;
quit;

***************************
*Link with owned dwellings*
***************************;

data raw_data.fideli_links_owners (keep= id_loc id_ind);
set baseline.LIENS_LOGEMENTS_PROPRIETAIRES ;
where id_loc not =.;
run;

proc sort data=raw_data.fideli_ind out=raw_data.fideli_ind;
by id_ind;
run;

data raw_data.fideli_owners;
merge raw_data.fideli_links_owners  raw_data.fideli_ind;
by id_ind;
run;

*Remove observations with no ownership link and drop id_ind which is now useless;
data raw_data.fideli_owners (drop=id_ind);
set raw_data.fideli_owners;
where id_loc not=.;
run;

*Remove duplicates (which correspond to multiple individuals in a same household;
proc sort data=raw_data.fideli_owners out=raw_data.fideli_owners nodupkey;
by id_loc id_HH_OWNER;
run;



***********************************
*Link owned dwellings with renters*
***********************************;

******For Fideli_diff_1;

data raw_data.fideli_loc_link1 (keep= id_log id_loc);
set baseline.fideli_local17_diff_1 ;
run;


******For Fideli_diff_2;

data raw_data.fideli_loc_link2 (keep= id_log id_loc);
set baseline.fideli_local17_diff_2 ;
run;


******For Fideli_diff_3;

data raw_data.fideli_loc_link3 (keep= id_log id_loc);
set baseline.fideli_local17_diff_3 ;
run;

proc append base=raw_data.fideli_loc_link1 data=raw_data.fideli_loc_link2;
run;

proc append base=raw_data.fideli_loc_link1 data=raw_data.fideli_loc_link3;
run;

data raw_data.fideli_loc_link ;
set raw_data.fideli_loc_link1 ;
where id_log not=.;
run;


*******Delete datasets;
proc datasets library=raw_data nolist;
delete fideli_loc_link1 fideli_loc_link2 fideli_loc_link3;
quit;



****Merge with id_owners;
proc sort data=raw_data.fideli_loc_link out=raw_data.fideli_loc_link nodupkey;
by id_loc id_log;
run;

data raw_data.fideli_to_merge;
merge raw_data.fideli_owners  raw_data.fideli_loc_link;
by id_loc;
run;

*rearrange dataset;
*We drop observations with no IDs as we won't be able to match them in any case;
data raw_data.fideli_to_merge (drop=id_loc);
set raw_data.fideli_to_merge ;
where id_log not=.;
run;

proc sort data=raw_data.fideli_to_merge out=raw_data.fideli_to_merge;
by id_log;
run;



****************************************
*Link with dataset from previous script*
****************************************;

****Merge;
proc sort data=raw_data.rented out=raw_data.rented;
by id_log;
run;

data raw_data.rented2 (drop=ID_OWNER);
merge raw_data.fideli_to_merge  raw_data.rented;
by id_log;
run;

data raw_data.rented2;
set raw_data.rented2;
where OCC not ="";
run;

*Create a variable indicating the number of owners and put a weight;
data raw_data.rented2;
set raw_data.rented2;
num=1;
run;

proc sql;
create table raw_data.rented2 as
select *,sum(num) as count 
from raw_data.rented2 group by id_log;
quit;

data raw_data.rented2 (drop=count num);
set raw_data.rented2;
WEIGHT=1/count;
run;

data raw_data.rented2 (drop=OWNER_FONCIER OWNER_MOB OWNER_INCOME_TOTAL OWNER_INCOME);
set raw_data.rented2;
rename ID_HH_OWNER=ID_OWNER;
run;

*Add owners' income;
data raw_data.fideli_income (keep= id_log zfonm zvamm revdispm nivviem);
set baseline.fideli_revenus_filosofi17 ;
where id_log not =.;
run;

data raw_data.fideli_income;
set raw_data.fideli_income ;
rename id_log=ID_OWNER;
rename zfonm=OWNER_FONCIER;
rename zvamm=OWNER_MOB;
rename revdispm=OWNER_INCOME_TOTAL;
rename nivviem=OWNER_INCOME;
run;

*Duplicates were included because there is information on past income in the dataset;
*We do not care about this here so we can simply gather observations with the same IDs;
proc sort data=raw_data.fideli_income out=raw_data.fideli_income nodupkey;
by ID_OWNER;
run;

*Merge with dataset on dwellings;
proc sort data=raw_data.rented2 out=raw_data.rented2;
by ID_OWNER;
run;

data raw_data.rented3;
merge raw_data.rented2  raw_data.fideli_income;
by ID_OWNER;
run;

data raw_data.rented3;
set raw_data.rented3;
where OCC not = "";
run;


*********************
********PART7********
*********************;
*Here I link data on owner occupied homes and renter-occupied ones;
data raw_data.fideli_dem3;
set raw_data.owned;
run;

proc append base=raw_data.fideli_dem3 data=raw_data.rented3;
run;

proc sort data=raw_data.fideli_dem3 out=raw_data.fideli_dem3;
by id_log;
run;



*********************
********PART8********
*********************;

*****ADD CODNAIS;


******For Fideli_diff_1;

data raw_data.fideli_ind1 (keep= id_log CODNAIS type_menf);
set baseline.fideli_individu17_diff_1 ;
run;


******For Fideli_diff_2;

data raw_data.fideli_ind2 (keep= id_log CODNAIS type_menf);
set baseline.fideli_individu17_diff_2 ;
run;


******For Fideli_diff_3;

data raw_data.fideli_ind3 (keep= id_log CODNAIS type_menf);
set baseline.fideli_individu17_diff_3 ;
run;

proc append base=raw_data.fideli_ind1 data=raw_data.fideli_ind2;
run;

proc append base=raw_data.fideli_ind1 data=raw_data.fideli_ind3;
run;

data raw_data.fideli_ind ;
set raw_data.fideli_ind1 ;
run;

****Concatenate CODNAIS for each household;

proc sort data=raw_data.fideli_ind out=raw_data.fideli_ind;
by id_log;
run;

data raw_data.codnais;
length MUN_BIRTH $50;
do until(last.id_log);
set raw_data.fideli_ind; 
by id_log;
MUN_BIRTH=catx(", ",MUN_BIRTH,CODNAIS);
end;
run;




****Merge for owners;
data raw_data.codnais (drop=codnais) ;
set raw_data.codnais ;
flag=1;
rename id_log=ID_OWNER;
where id_log not=.;
run;

proc sort data=raw_data.fideli_dem3 out=raw_data.fideli_dem3;
by ID_OWNER;
run;

data raw_data.fideli_dem4;
merge raw_data.fideli_dem3  raw_data.codnais;
by ID_OWNER;
run;


data raw_data.fideli_dem4 (drop=flag) ;
set raw_data.fideli_dem4 ;
rename type_menf=OWNER_TYPE_HH;
rename MUN_BIRTH=OWNER_MUN_BIRTH;
where OCC not="";
run;




****Merge for renters;
data raw_data.codnais (drop=codnais) ;
set raw_data.codnais ;
rename ID_OWNER=ID_RENTER;
run;

proc sort data=raw_data.fideli_dem4 out=raw_data.fideli_dem4;
by ID_RENTER;
run;

data raw_data.fideli_dem4;
merge raw_data.fideli_dem4  raw_data.codnais;
by ID_RENTER;
run;

data raw_data.fideli_dem4 (drop=flag) ;
set raw_data.fideli_dem4 ;
rename type_menf=RENTER_TYPE_HH;
rename MUN_BIRTH=RENTER_MUN_BIRTH;
where OCC not="";
run;



*****last changes;
data raw_data.fideli_dem4 ;
set raw_data.fideli_dem4 ;
rename id_log=ID;
run;






*We export the data;
proc export data=raw_data.fideli_dem4 DBMS=dta
outfile="..\Data\_fideli_dem.dta"
replace;
run;





