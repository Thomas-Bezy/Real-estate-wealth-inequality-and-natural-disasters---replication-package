global dir=".."


******************************************
**********IMPORT, CLEAN AND SAVE**********
******************************************

**********TRI**********
use "$dir/Data/_fideli_w_tri_without_dem.dta", replace

*Change variable type to numeric
foreach i in 1 2 3{
	gen TRI_TYPE_`i'=0
	replace TRI_TYPE_`i'=1 if TRI_TYPE=="0`i'"
}

*Change variable type to numeric
global n=1
foreach i in 01For 02Moy 04Fai 03Mcc{
	gen TRI_SCENAR_$n=0
	replace TRI_SCENAR_$n=1 if SCENARIO=="`i'"
	global n=$n +1
}

*TRI for oversea departments are count as double: one for marine submergence and one for stream overflow
replace ID_TRI=118 if ID_TRI==119
replace ID_TRI=120 if ID_TRI==121
replace ID_TRI=122 if ID_TRI==123
replace ID_TRI=124 if ID_TRI==125
replace ID_TRI=126 if ID_TRI==127
replace ID_TRI=128 if ID_TRI==129

*Ensure to have one observation per ID
collapse (sum) TRI_TYPE_1 TRI_TYPE_2 TRI_TYPE_3 ///
TRI_SCENAR_1 TRI_SCENAR_2 TRI_SCENAR_3 TRI_SCENAR_4, by(ID ID_TRI)

*Renaming
rename ID_TRI TRI_ID

*Replace values >1 by 1
foreach i in 1 2 3{
	replace TRI_TYPE_`i'=1 if TRI_TYPE_`i'>0
}
foreach i in 1 2 3 4{
	replace TRI_SCENAR_`i'=1 if TRI_SCENAR_`i'>0
}


******FLOOD DEPTH******

*Remove missing
keep if DEPTH!=.
drop if SCENARIO=="03Mcc"

*Collapse to be sure to have one observation per dwelling and per risk type and level
collapse (max) DEPTH ///
, by(id_log TRI_TYPE SCENARIO)

*change the classification of depth
gen DEPTH2=1 if DEPTH==0 
replace DEPTH2=2 if DEPTH==0.5
replace DEPTH2=3 if DEPTH==1
replace DEPTH2=3 if DEPTH==1.5
replace DEPTH2=4 if DEPTH>=2
 
*Generate different variables for each risk level and type
foreach i in 1 3{ 
global n=1
foreach j in 01For 02Moy 04Fai{
	gen RISK${n}_TYPE`i'_DEPTH=0
	replace RISK${n}_TYPE`i'_DEPTH=DEPTH2 if SCENARIO=="`j'" & TRI_TYPE=="0`i'" 
	global n=$n +1
}
}

*Collapse to go back to one observation per dwelling
collapse (sum) RISK1_TYPE1_DEPTH RISK2_TYPE1_DEPTH RISK3_TYPE1_DEPTH RISK1_TYPE3_DEPTH RISK2_TYPE3_DEPTH RISK3_TYPE3_DEPTH ///
, by(id_log)

*Modify maximuml values
foreach var in RISK1_TYPE1_DEPTH RISK2_TYPE1_DEPTH RISK3_TYPE1_DEPTH RISK1_TYPE3_DEPTH RISK2_TYPE3_DEPTH RISK3_TYPE3_DEPTH{
replace `var'=4 if `var'>4
}


save "$dir/Data/_fideli_w_tri_without_dem.dta", replace






**********SUBSIDENCE**********

use "$dir/Data/_fideli_w_rga_without_dem1.dta", replace
append using "$dir/Data/_fideli_w_rga_without_dem2.dta"
append using "$dir/Data/_fideli_w_rga_without_dem3.dta"
duplicates tag id_log, gen(tag)

*When an observation is assigned with 2 risk levels, I only keep the highest value
collapse (max) NIVEAU, by(id_log)

save "$dir/Data/_fideli_w_rga_without_dem.dta", replace

