*clear all
global dir="..."
global output="..."





*For renters
use "$dir\data_housing_2017.dta", replace

*Number of consumption units
gen NB_UC=RENTER_INCOME_TOTAL/RENTER_INCOME

*Drop owners
keep if ID_RENTER!=.

*Keep important variables for prediction
keep RENTER_INCOME_TOTAL NB_UC SURFACE id_log CONSTRUCTION_DATE NATLOC MUNICIPALITY

rename RENTER_INCOME_TOTAL INCOME_TOTAL
gen RENTER=1

save "$dir\renters_for_ML", replace


*For owners
use "$dir\data_housing_2017.dta", replace

*Number of conusmption units
gen NB_UC=OWNER_INCOME_TOTAL/OWNER_INCOME

*Drop renters
keep if ID_OWNER!=.

*Keep important variables for prediction
keep OWNER_INCOME_TOTAL NB_UC SURFACE id_log CONSTRUCTION_DATE NATLOC MUNICIPALITY

rename OWNER_INCOME_TOTAL INCOME_TOTAL

gen RENTER=0


*Append the datasets for renters and owners to predict both 
append using "$dir\renters_for_ML"

*Drop missing
keep if id_log!=.



*******Modify variables to be consistent with the Budget des Familles dataset*******

*DWELLING TYPE
drop if NATLOC==3
gen temp=1 if NATLOC==2
replace temp=2 if NATLOC==1
drop NATLOC
rename temp NATLOC

*CONSTRUCTION_DATE
gen CONS_1=(CONSTRUCTION_DATE<=1948)
gen CONS_2=(CONSTRUCTION_DATE>=1949 & CONSTRUCTION_DATE<=1961)
gen CONS_3=(CONSTRUCTION_DATE>=1962 & CONSTRUCTION_DATE<=1967)
gen CONS_4=(CONSTRUCTION_DATE>=1968 & CONSTRUCTION_DATE<=1974)
gen CONS_5=(CONSTRUCTION_DATE>=1975 & CONSTRUCTION_DATE<=1981)
gen CONS_6=(CONSTRUCTION_DATE>=1982 & CONSTRUCTION_DATE<=1989)
gen CONS_7=(CONSTRUCTION_DATE>=1990 & CONSTRUCTION_DATE<=1998)
gen CONS_8=(CONSTRUCTION_DATE>=1999 & CONSTRUCTION_DATE<=2003)
gen CONS_9=(CONSTRUCTION_DATE>=2004)

*MUNICIPALITY
gen DEP=substr(MUNICIPALITY,1,2)

*Add information on Departements and Regions
merge n:1 DEP using "$dir/depts2017.dta"
drop _merge

tab REGION, gen(REGION)
rename REGION1 REGION_11
rename REGION2 REGION_24
rename REGION3 REGION_27
rename REGION4 REGION_28
rename REGION5 REGION_32
rename REGION6 REGION_44
rename REGION7 REGION_52
rename REGION8 REGION_53
rename REGION9 REGION_75
rename REGION10 REGION_76
rename REGION11 REGION_84
rename REGION12 REGION_93
rename REGION13 REGION_94
rename REGION14 REGION_97



*Drop if missing
drop if missing(INCOME_TOTAL)
drop if missing(NB_UC)
drop if missing(SURFACE)
drop if missing(id_log)
drop if missing(CONSTRUCTION_DATE)
drop if missing(NATLOC)
drop if missing(MUNICIPALITY)

*Drop previously modified variables
drop CONSTRUCTION_DATE MUNICIPALITY DEP REGION

*Save
save "$dir\data_for_ML", replace
