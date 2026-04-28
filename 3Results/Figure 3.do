clear all
global dir="..."
global output="..."



****************WITH AGGREGATE DATA WITH INCOME QUINTILES****************

use "$dir\data_housing_2017.dta", replace

replace WEIGHT=1 if WEIGHT==.

gen BASEMENT=(FLOOR=="80"|FLOOR=="81"|FLOOR=="82"|FLOOR=="83"|FLOOR=="84"|FLOOR=="85"|FLOOR=="86"|FLOOR=="87"|FLOOR=="88"|FLOOR=="89"| ///
FLOOR=="90"|FLOOR=="91"|FLOOR=="92"|FLOOR=="93"|FLOOR=="94"|FLOOR=="95"|FLOOR=="96"|FLOOR=="97"|FLOOR=="98"|FLOOR=="99")

*Define the exposed dwellings for flooding: only first floor is exposed
replace TRI_RISK1=0 if FLOOR!="00" & BASEMENT!=1
replace TRI_RISK2=0 if FLOOR!="00" & BASEMENT!=1
replace TRI_RISK3=0 if FLOOR!="00" & BASEMENT!=1

keep if  TYPPMO!="5"



*Define the exposed dwellings for subsidence: only dwellings with no upper floors are exposed
*Indicator for being on an upper floor
gen UPPER_FLOOR=(FLOOR!="00" & BASEMENT!=1)

*Derive the presence of an upper floor at the address level
gen ID_BATIMENT=MUNICIPALITY+ADDRESS_STREET+ADDRESS_NUM

bysort ID_BATIMENT : egen UPPER_FLOOR_PRESENCE=total(UPPER_FLOOR)

gen RGA_EXPOSED=(RGA_RISK3==1 & FLOOR=="00" & UPPER_FLOOR_PRESENCE==0 & CONSTRUCTION_DATE>=1975 & CONSTRUCTION_DATE<=2008 & NATLOC==2)

*Apply weights to the exposure variables
foreach var in TRI_RISK1 TRI_RISK2 TRI_RISK3 RGA_EXPOSED{
replace `var'=`var'*WEIGHT
}


gen COUNT=1

*Generate municipality-level income quintiles
egen QUINTILE = xtile(INCOME_MUN), nq(5) weights(WEIGHT)
drop if QUINTILE==.


*Collapse exposure variables by municipality income quintile
collapse (sum) WEIGHT TRI_RISK1 TRI_RISK2 TRI_RISK3 RGA_EXPOSED ///
			   , by(QUINTILE)

*Convert to shares
egen TOTAL=total(WEIGHT)
egen TOTAL_RISK1=total(TRI_RISK1)
egen TOTAL_RISK2=total(TRI_RISK2)
egen TOTAL_RISK3=total(TRI_RISK3)
egen TOTAL_RGA=total(RGA_EXPOSED)


gen COUNT_SHARE=100*WEIGHT/TOTAL
gen RISK1_SHARE=100*TRI_RISK1/TOTAL_RISK1
gen RISK2_SHARE=100*TRI_RISK2/TOTAL_RISK2
gen RISK3_SHARE=100*TRI_RISK3/TOTAL_RISK3
gen RGA_SHARE=100*RGA_EXPOSED/TOTAL_RGA



*Define the plot coordinates
gen COL1=0.7
replace COL1=0.85 if QUINTILE==2
replace COL1=1 if QUINTILE==3
replace COL1=1.15 if QUINTILE==4
replace COL1=1.3 if QUINTILE==5


gen COL2=1+COL1
gen COL3=1+COL2
gen COL4=1+COL3
gen COL5=1+COL4


*Graph
twoway  bar RISK1_SHARE COL1 if QUINTILE==1, bcolor(maroon%20) barw(0.15) || ///
		bar RISK1_SHARE COL1 if QUINTILE==2, bcolor(maroon%40) barw(0.15) || ///
		bar RISK1_SHARE COL1 if QUINTILE==3, bcolor(maroon%60) barw(0.15) || ///
		bar RISK1_SHARE COL1 if QUINTILE==4, bcolor(maroon%80) barw(0.15) || ///
		bar RISK1_SHARE COL1 if QUINTILE==5, bcolor(maroon) barw(0.15) || ///
		bar RGA_SHARE COL2 if QUINTILE==1, bcolor(maroon%20) barw(0.15) || ///
		bar RGA_SHARE COL2 if QUINTILE==2, bcolor(maroon%40) barw(0.15) || ///
		bar RGA_SHARE COL2 if QUINTILE==3, bcolor(maroon%60) barw(0.15) || ///
		bar RGA_SHARE COL2 if QUINTILE==4, bcolor(maroon%80) barw(0.15) || ///
		bar RGA_SHARE COL2 if QUINTILE==5, bcolor(maroon) barw(0.15)  ///
ylabel(0[10]50, angle(0)) xlabel(1 `" "Exposed to" "flooding" "' 2 `" "Exposed to" "subsidence" "' ) ///
graphregion(color(white))  ytitle("Distribution" "in percentages" ,orient(horizontal)) ///
legend(order(1 2 3 4 5) col(2) lab (1 "1st quintile (bottom 20%)") lab (2 "2nd quintile") lab (3 "3rd quintile")  lab (4 "4th quintile") lab (5 "5th quintile (top 20%)")) ///
xsize(9) ysize(5)
graph export "$output\shares_flooding_ownership_income_mun.png", replace

			   
			   
			   
			   
			   
			   
			   
			   
			   
			   