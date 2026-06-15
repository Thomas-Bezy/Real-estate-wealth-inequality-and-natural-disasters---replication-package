global dir=".."


*********************************************
**********IMPORT AND MERGE DATASETS**********
*********************************************



**********TRI**********
use "$dir/Data/_fideli_w_tri_without_dem.dta", replace

**********Subsidence**********
merge n:1 id_log using "$dir/Data/_fideli_w_rga_without_dem.dta", generate(merge)
drop if merge==2
drop merge

**********Merge with demographics**********
merge 1:n ID using "$dir/Data/_fideli_dem.dta", generate(merge)
drop merge

*Keep only dwellings and remove other buildings
keep if OCC !=""

*change contruction date
destring date_const, replace

*****Rearrange columns
rename OCC OWNER
rename type_res2 OCC
rename depcom2 MUNICIPALITY
rename NIVF FLOOR
rename SURFTOT SURFACE
rename date_const CONSTRUCTION_DATE

rename rue1 ADDRESS_STREET 
rename noimm1 ADDRESS_NUM 
rename anais_prop OWNER_BIRTH_DATE 
rename tax_logement TAX_LGT 
rename vloc17 RENTAL_VALUE 
rename iris IRIS

*Building and creation dates
destring CONSTRUCTION_DATE, replace

*Percentiles from the filosofi dataset
foreach type in OWNER RENTER{
gen `type'_PERCENTILE=.
global n=1
foreach i in 0 3963.077 6021.923 7228.621 8090.833 8746.025 9215.143 9708.421 10095.26 10511.14 10917.35 11301.47 11656.29 11988.52 12301.56 12599.51 12872.07 13122.06 13403.03 13672.57 13935.15 14176.06 14411.03 14648.5 14884.06 15115.11 15346.09 15583.04 15815.76 16045.86 16275.85 16508.06 16733.46 16956.07 17177.58 17394.06 17609.62 17826.21 18044.07 18262.25 18481.07 18698.7 18918.8 19140.28 19360.83 19580.59 19796.79 20012.4 20231.05 20453.43 20677.37 20902.69 21130.71 21362.05 21597.24 21835.77 22078.7 22325.14 22575.22 22830.26 23089.09 23354.06 23622.08 23896.77 24178.28 24466.79 24763.03 25068.75 25382.69 25708.08 26045.36 26395.14 26758.85 27136.07 27529.38 27937.6 28364.17 28808.7 29275.14 29762.08 30274.17 30814.17 31390.71 32003.04 32661.07 33370.77 34136.09 34966.79 35874.17 36879.03 38001.33 39278.7 40770.3 42554.76 44701.54 47366.25 50880.8 55993.33 64092 80753.5{
	replace `type'_PERCENTILE=$n if `type'_INCOME>=`i'
	global n=$n +1
	display  "$n"
}
replace `type'_PERCENTILE=. if `type'_INCOME==.
}

*Deciles
foreach type in OWNER RENTER{
gen `type'_DECILE=.
foreach i of num 0/9{
	replace `type'_DECILE=`i'+1 if `type'_PERCENTILE>=1+`i'*10 &`type'_PERCENTILE<=10+`i'*10
}
}



*Rearrange columns for TRIs
drop TRI_SCENAR_4

rename TRI_SCENAR_1 TRI_RISK_1
rename TRI_SCENAR_2 TRI_RISK_2
rename TRI_SCENAR_3 TRI_RISK_3

foreach i in 1 2 3 {
	foreach k in 1 2 3 {
	gen TRI_RISK`i'_TYPE`k'=TRI_RISK_`i'*TRI_TYPE_`k'
	replace TRI_RISK`i'_TYPE`k'=0 if TRI_TYPE_`k'==.
}
}

*Drop previous variables
drop TRI_RISK_1
drop TRI_RISK_2
drop TRI_RISK_3
drop TRI_TYPE_1
drop TRI_TYPE_2
drop TRI_TYPE_3


*Rearrange columns for subsidence
rename NIVEAU RGA
foreach i in 1 2 3{
gen RGA_RISK`i'=0
replace RGA_RISK`i'=1 if RGA==`i'
}

replace RGA_RISK1=1 if RGA_RISK2==1|RGA_RISK3==1
replace RGA_RISK2=1 if RGA_RISK3==1

drop RGA

*****Relabel occupational variables*****
*OWNER variable
replace OWNER="1" if OWNER=="P"
replace OWNER="2" if OWNER=="L"
replace OWNER="3" if OWNER=="V"
replace OWNER="4" if OWNER=="W"
replace OWNER="5" if OWNER=="B"
replace OWNER="6" if OWNER=="D"
replace OWNER="7" if OWNER=="G"
replace OWNER="8" if OWNER=="N"
replace OWNER="9" if OWNER=="T"
replace OWNER="10" if OWNER=="X"
replace OWNER="11" if OWNER=="/"

destring OWNER,replace

label define OWNER 1 "Owner occupied (1)" 2 "Renter occupied (2)" 3 "Free (3)" 4 "Empty (4)" 5 "Rented occasionally (5)" 6 "Demolished (6)" 7 "Occupied for free (7)" 8 "Dépendance (8)" 9 "Professionally taxed (9)" 10 "Rural contract (10)" 11 "Other (11)"
label values OWNER OWNER


*OCC variable
destring OCC, replace

label define OCC 1 "Principal housing inside Fideli (1)" 2 "Principal housing outside Fideli (2)" 3 "Secondary housing inside Fideli (3)" 4 "Secondary housing outside Fideli (4)" 5 "Occupied occasionally (5)" 6 "Free (6)" 7 "Other (7)"
label values OCC OCC


*Convert variables to numeric
destring FLOOR, replace

encode NATLOC, gen(NATLOC_NUM)
drop NATLOC
rename NATLOC_NUM NATLOC

label define NATLOC 1 "Appartement" 2 "Maison" 3 "Maison exceptionnelle"
label values NATLOC NATLOC

***Add info on municipality income
merge n:1 MUNICIPALITY using "$dir/mun_income.dta"
drop if _merge==2
drop _merge

rename INCOME INCOME_MUN
rename INCOME_TOTAL INCOME_TOTAL_MUN

*Add house value
merge n:1 MUNICIPALITY using "$dir\dvf_communes.dta", generate(merge)
keep if merge !=2
drop merge

*Create a variable for housing_type
gen HOUSING_TYPE=1 if OWNER==1 & OCC==1 //Owner-occupied
replace HOUSING_TYPE=2 if OWNER==2 & OCC==1 //Rental
replace HOUSING_TYPE=3 if OCC==3 //Second home
replace HOUSING_TYPE=4 if OCC==6 //Vacant



*Redefine variables of exposure to flooding
gen TRI_RISK1=TRI_RISK1_TYPE1+TRI_RISK1_TYPE3
replace TRI_RISK1=1 if TRI_RISK1>=1

gen TRI_RISK2=TRI_RISK2_TYPE1+TRI_RISK2_TYPE3
replace TRI_RISK2=1 if TRI_RISK2>=1

gen TRI_RISK3=TRI_RISK3_TYPE1+TRI_RISK3_TYPE3
replace TRI_RISK3=1 if TRI_RISK3>=1

drop TRI_RISK1_TYPE2 TRI_RISK2_TYPE2 TRI_RISK3_TYPE2 REFCAD OWNER_BIRTH_DATE TAX_LGT RENTAL_VALUE OWNER_FONCIER OWNER_MOB RENTER_FONCIER RENTER_MOB OWNER_MUN_BIRTH OWNER_TYPE_HH RENTER_MUN_BIRTH RENTER_TYPE_HH INCOME_TOTAL_MUN OWNER_INCOME_TOTAL_MUN OWNER_INCOME_MUN

drop OCC2016 OWNER_INCOME_TOTAL RENTER_INCOME_TOTAL TRI_RISK1_TYPE1 TRI_RISK1_TYPE3 TRI_RISK2_TYPE1 TRI_RISK2_TYPE3 TRI_RISK3_TYPE1 TRI_RISK3_TYPE3 MUN_COAST DIST_COAST DIST_RIVER DIST_TRI STAGE SURF JRC_100 x y 


save "$dir/Data/data_housing_2017.dta", replace
