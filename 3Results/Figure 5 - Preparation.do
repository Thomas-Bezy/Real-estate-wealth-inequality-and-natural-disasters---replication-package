clear all
global dir="..."
global output="..."



use "$dir\data_housing_2017_full.dta", replace

*Keep important variables
keep MUNICIPALITY IRIS TRI_RISK1 TRI_RISK2_TYPE1 TRI_RISK2_TYPE3 TRI_RISK3_TYPE1 TRI_RISK3_TYPE3 PRICE  SURFACE HOUSING_TYPE CONSTRUCTION_DATE DATEACTE OWNER_INCOME RENTER_INCOME DATEACTE TYPPMO ADDRESS_STREET WEIGHT id_log FLOOR CONSTRUCTION_DATE OCC NATLOC ZE RGA_RISK1 RGA_RISK2 RGA_RISK3 JRC_100 DIST_RIVER DIST_COAST FLOOR ADDRESS_NUM ADDRESS_STREET ID_OWNER

*Aggregate coastal and riverine flood risks in a single variable, for different levels of risk exposure
gen TRI_RISK2=TRI_RISK2_TYPE1+TRI_RISK2_TYPE3
replace TRI_RISK2=1 if TRI_RISK2>=1

gen TRI_RISK3=TRI_RISK3_TYPE1+TRI_RISK3_TYPE3
replace TRI_RISK3=1 if TRI_RISK3>=1

*Prepare the variable for exposure to subsidence
gen UPPER_FLOOR=(FLOOR!="00")
gen ID_BATIMENT=MUNICIPALITY+ADDRESS_STREET+ADDRESS_NUM
bysort ID_BATIMENT : egen UPPER_FLOOR_PRESENCE=total(UPPER_FLOOR)
gen RGA_EXPOSED=(FLOOR=="00" & UPPER_FLOOR_PRESENCE==0 & CONSTRUCTION_DATE>=1975 & CONSTRUCTION_DATE<=2008 & NATLOC==2)


*Create a variable for multi property owners
gen COUNT=1
bysort ID_OWNER :egen TOTAL_COUNT=total(COUNT)

*Keep variables
keep MUNICIPALITY IRIS TRI_RISK1 TRI_RISK2 TRI_RISK3 PRICE  SURFACE HOUSING_TYPE CONSTRUCTION_DATE DATEACTE OWNER_INCOME RENTER_INCOME DATEACTE TYPPMO ADDRESS_STREET WEIGHT id_log FLOOR CONSTRUCTION_DATE OCC NATLOC ZE UPPER_FLOOR_PRESENCE RGA_RISK1 RGA_RISK2 RGA_RISK3 TOTAL_COUNT JRC_100 DIST_RIVER DIST_COAST 

*Exclude social housing
drop if TYPPMO=="5"

*Modify prices variables to get the log price per meter squared
gen PRICE_M2=PRICE/SURFACE
keep if PRICE_M2!=.
gen LOG_PRICE_M2=log(PRICE_M2)

*Define geographic FE
gen MUN_IRIS=MUNICIPALITY+IRIS
gen MUN_STREET=MUNICIPALITY+ADDRESS_STREET

rename MUNICIPALITY MUN
drop IRIS
rename MUN_IRIS IRIS
rename MUN_STREET STREET


*Acquisition date
gen DATE_OWNERSHIP=substr(DATEACTE,-4,4)
destring DATE_OWNERSHIP,replace

*Renaming
rename TRI_RISK1 FLOOD1 
rename TRI_RISK2 FLOOD2
rename TRI_RISK3 FLOOD3

rename RGA_RISK3 RGA1 
rename RGA_RISK2 RGA2 
rename RGA_RISK1 RGA3 

*Compute the interaction and exposure variables for flooding and subsidence
foreach i of num 1/3{
	gen FLOOD`i'_EXPOSED=(FLOOR=="00")
	gen FLOOD`i'_EXPOSED_INTER=FLOOD`i'_EXPOSED*FLOOD`i'
	
	gen RGA`i'_EXPOSED=RGA_EXPOSED==1
	gen RGA`i'_EXPOSED_INTER=RGA`i'_EXPOSED*RGA`i'
}

*Define ownership categories
gen OWNERSHIP=1 if HOUSING_TYPE==1&TOTAL_COUNT==1
replace OWNERSHIP=2 if HOUSING_TYPE==1 &TOTAL_COUNT>1
replace OWNERSHIP=3 if HOUSING_TYPE==2 
replace OWNERSHIP=4 if HOUSING_TYPE==3
replace OWNERSHIP=5 if HOUSING_TYPE==4



********************************
*********GAPS IN PRICES*********
********************************

*Compute the number of dwellings at risk per geographic area (to flag those where there is no dwelling at risk later on)
foreach risk in FLOOD1 FLOOD2 FLOOD3  RGA1 RGA2 RGA3{
bysort MUN:egen MUN_`risk'=total(`risk')
bysort ZE:egen ZE_`risk'=total(`risk')
bysort IRIS:egen IRIS_`risk'=total(`risk')
bysort STREET:egen STREET_`risk'=total(`risk')
}

*Renaming
gen MUNICIPALITY=MUN

save "$dir\data_for_prices_reg.dta", replace
