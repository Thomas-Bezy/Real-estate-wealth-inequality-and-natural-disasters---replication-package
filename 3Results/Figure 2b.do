clear all
global dir="..."
global output="..."


********************************
***Primary vs secondary homes***
********************************

use "$dir\data_housing_2017.dta", replace

*Create a variable for multi property owners
gen COUNT=1
bysort ID_OWNER :egen TOTAL_COUNT=total(COUNT)

*Define ownership categories
gen OWNERSHIP=1 if OWNER==1 & OCC<=2&TOTAL_COUNT==1
replace OWNERSHIP=2 if OWNER==1 & OCC<=2&TOTAL_COUNT>1
replace OWNERSHIP=3 if OWNER==2 & (OCC<=2)
replace OWNERSHIP=4 if (OCC==3|OCC==4)
replace OWNERSHIP=5 if OCC==6


*Create a variable to indicate the presence of a basement
gen BASEMENT=(FLOOR=="80"|FLOOR=="81"|FLOOR=="82"|FLOOR=="83"|FLOOR=="84"|FLOOR=="85"|FLOOR=="86"|FLOOR=="87"|FLOOR=="88"|FLOOR=="89"| ///
FLOOR=="90"|FLOOR=="91"|FLOOR=="92"|FLOOR=="93"|FLOOR=="94"|FLOOR=="95"|FLOOR=="96"|FLOOR=="97"|FLOOR=="98"|FLOOR=="99")


*Measure individual damages for risk level r and type of flood t (river or coastal)
foreach r in 1 2 3{
foreach t in 1 3{
	
	gen DAMAGE_RISK`r'_TYPE`t'=.
	
	*Homes on the ground floor
	replace DAMAGE_RISK`r'_TYPE`t'=(91.8 + 102.2) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==1
	replace DAMAGE_RISK`r'_TYPE`t'=(113.8 + 151.6) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==2
	replace DAMAGE_RISK`r'_TYPE`t'=(154 + 190.1) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==3
	replace DAMAGE_RISK`r'_TYPE`t'=(237.9 + 194.4) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==4
	
	*Basements (individual damages)
	replace DAMAGE_RISK`r'_TYPE`t'=(0.9) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==1
	replace DAMAGE_RISK`r'_TYPE`t'=(1.2) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==2
	replace DAMAGE_RISK`r'_TYPE`t'=(1.7) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==3
	replace DAMAGE_RISK`r'_TYPE`t'=(8.2) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==4
	
	*Homes on the ground floor
	replace DAMAGE_RISK`r'_TYPE`t'=(78.9 + 86.1) *SURFACE if FLOOR=="00" & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==1
	replace DAMAGE_RISK`r'_TYPE`t'=(99 + 129.5) *SURFACE if FLOOR=="00" & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==2
	replace DAMAGE_RISK`r'_TYPE`t'=(135 + 163.2) *SURFACE if FLOOR=="00" & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==3
	replace DAMAGE_RISK`r'_TYPE`t'=(175.1 + 166) *SURFACE if FLOOR=="00" & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==4
	
	*Basements (individual damages)
	replace DAMAGE_RISK`r'_TYPE`t'=(74.3) *SURFACE if BASEMENT==1 & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==1
	replace DAMAGE_RISK`r'_TYPE`t'=(82.5) *SURFACE if BASEMENT==1 & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==2
	replace DAMAGE_RISK`r'_TYPE`t'=(82.5) *SURFACE if BASEMENT==1 & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==3
	replace DAMAGE_RISK`r'_TYPE`t'=(82.5) *SURFACE if BASEMENT==1 & NATLOC==1 & RISK`r'_TYPE`t'_DEPTH==4
	
	replace DAMAGE_RISK`r'_TYPE`t'=0 if DAMAGE_RISK`r'_TYPE`t'==.
}

*Generate a variable to aggregate river and coastal damages
gen DAMAGE_RISK`r'=DAMAGE_RISK`r'_TYPE1 + DAMAGE_RISK`r'_TYPE3
}

*Drop individual variables for river and coastal damages
drop DAMAGE_RISK1_TYPE1 DAMAGE_RISK1_TYPE3 DAMAGE_RISK2_TYPE1 DAMAGE_RISK2_TYPE3 DAMAGE_RISK3_TYPE1 DAMAGE_RISK3_TYPE3 


*Compute the net present value of future damages
gen DAMAGE=.5 * (1.5 * DAMAGE_RISK3 + DAMAGE_RISK3) * (0.001 - 0) + ///
.5 * (DAMAGE_RISK3 + DAMAGE_RISK2) * (0.01 - 0.001) + ///
.5 * (DAMAGE_RISK2 + DAMAGE_RISK1) * (0.1 - 0.01)

gen NPV=DAMAGE

foreach t of num 1/30{
replace NPV=NPV+DAMAGE*(1.033)^(-`t') if HOUSING_TYPE!=2
replace NPV=NPV+DAMAGE*(1.035)^(-`t') if HOUSING_TYPE==2
}


*Correcting weights
replace WEIGHT=1 if WEIGHT==.

*Define exposure to flooding
replace TRI_RISK1=0 if FLOOR!="00" & BASEMENT==0
replace TRI_RISK2=0 if FLOOR!="00" & BASEMENT==0
replace TRI_RISK3=0 if FLOOR!="00" & BASEMENT==0

*Exclude social housing
keep if  TYPPMO!="5"


*Generate the ratio NPV/Price
gen PRICE_FULL=SURFACE*PRICE_M2
gen RATIO=NPV/PRICE_FULL
replace NPV=PRICE_FULL if NPV>PRICE_FULL

*Drop useless variables
drop TRI_ID ADDRESS_STREET ADDRESS_NUM OWNER ADRENV TYPPMO DATEACTE DATEPERS CONSTRUCTION_DATE OCC IRIS MUNICIPALITY ID_RENTER NATLOC SALES_TOTAL ZE PRICE RGA_RISK1 RGA_RISK2 RGA_RISK3 RISK1_TYPE1_DEPTH RISK2_TYPE1_DEPTH RISK3_TYPE1_DEPTH RISK1_TYPE3_DEPTH RISK2_TYPE3_DEPTH RISK3_TYPE3_DEPTH DAMAGE_RISK1 DAMAGE_RISK2 DAMAGE_RISK3 DAMAGE

*Attribute weights to NPV
gen NPV_RISK1=NPV*WEIGHT if TRI_RISK1==1


***Define the key variables for the figure:
*The price of assets at risk
gen PRICE_RISK1=PRICE_FULL*WEIGHT if TRI_RISK1==1

*The total real estate wealth of owners in risky areas
bysort ID_OWNER :egen TOTAL_VALUE=total(PRICE_FULL)
gen TOTAL_VALUE_RISK1=TOTAL_VALUE*WEIGHT if TRI_RISK1==1

*Ratios of NPV over the price of assets at risk and total real estate wealth
gen RATIO1=NPV_RISK1/PRICE_RISK1
gen RATIO_FULL1=NPV_RISK1/TOTAL_VALUE_RISK1


*Collapse the ratios by ownership status
collapse (median) RATIO1 RATIO_FULL1 ///
			   , by(OWNERSHIP)

drop if  OWNERSHIP==. 


*Adjust the variables for the graph
replace RATIO1=100*RATIO1
replace RATIO_FULL1=100*RATIO_FULL1

gen COL1=0.7
replace COL1=0.85 if OWNERSHIP==2
replace COL1=1 if OWNERSHIP==3
replace COL1=1.15 if OWNERSHIP==4
replace COL1=1.3 if OWNERSHIP==5


gen COL2=1+COL1
gen COL3=1+COL2
gen COL4=1+COL3
gen COL5=1+COL4


*Graph
twoway  bar RATIO1 COL1 if OWNERSHIP==1, bcolor(maroon) barw(0.15) || ///
		bar RATIO1 COL1 if OWNERSHIP==2, bcolor(sienna) barw(0.15) || ///
		bar RATIO1 COL1 if OWNERSHIP==3, bcolor(forest_green) barw(0.15) || ///
		bar RATIO1 COL1 if OWNERSHIP==4, bcolor(dknavy) barw(0.15) || ///
		bar RATIO1 COL1 if OWNERSHIP==5, bcolor(stone) barw(0.15) || ///
		bar RATIO_FULL1 COL2 if OWNERSHIP==1, bcolor(maroon) barw(0.15) || ///
		bar RATIO_FULL1 COL2 if OWNERSHIP==2, bcolor(sienna) barw(0.15) || ///
		bar RATIO_FULL1 COL2 if OWNERSHIP==3, bcolor(forest_green) barw(0.15) || ///
		bar RATIO_FULL1 COL2 if OWNERSHIP==4, bcolor(dknavy) barw(0.15) || ///
		bar RATIO_FULL1 COL2 if OWNERSHIP==5, bcolor(stone) barw(0.15)  ///
ylabel(0[2]24, angle(0)) xlabel(1 "...the value of the dwelling" 2 "...the owner's total real estate wealth") ///
graphregion(color(white))  ytitle("Net present value" "of flood damages" "as a ratio of...",orient(horizontal)) ///
legend(order(1 2 3 4 5) col(1) lab (1 "Owner-occupied - Single-property owners") lab (2 "Owner-occupied - Multi-property owners") lab (3 "Rental dwellings") ///
lab(4 "Second homes") lab(5 "Vacant dwellings")) ///
xsize(9) ysize(5)
graph export "$output\expected_relative_damages.png", replace
