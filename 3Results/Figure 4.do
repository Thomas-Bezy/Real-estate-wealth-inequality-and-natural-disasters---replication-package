*clear all
global dir="..."
global output="..."



use "$dir\data_housing_insurance_2017.dta", replace

*Exclude social housing
keep if HOUSING_TYPE<=4
keep if  TYPPMO!="5"

*Exclude observations where we don't know the owner's income
drop if OWNER_DECILE==.

*Define exposure to flooding
replace TRI_RISK1=0 if FLOOR!="00"
replace TRI_RISK2=0 if FLOOR!="00"
replace TRI_RISK3=0 if FLOOR!="00"

*Define exposure to subsidence
gen UPPER_FLOOR=(FLOOR!="00")

gen ID_BATIMENT=MUNICIPALITY+ADDRESS_STREET+ADDRESS_NUM
drop MUNICIPALITY ADDRESS_STREET ADDRESS_NUM

bysort ID_BATIMENT : egen UPPER_FLOOR_PRESENCE=total(UPPER_FLOOR)

*For different degrees of exposure to subsidence
gen RGA_EXPOSED1=(RGA_RISK1==1 & FLOOR=="00" & UPPER_FLOOR_PRESENCE==0 & CONSTRUCTION_DATE>=1975 & CONSTRUCTION_DATE<=2008 & NATLOC==2)
gen RGA_EXPOSED2=(RGA_RISK2==1 & FLOOR=="00" & UPPER_FLOOR_PRESENCE==0 & CONSTRUCTION_DATE>=1975 & CONSTRUCTION_DATE<=2008 & NATLOC==2)
gen RGA_EXPOSED3=(RGA_RISK3==1 & FLOOR=="00" & UPPER_FLOOR_PRESENCE==0 & CONSTRUCTION_DATE>=1975 & CONSTRUCTION_DATE<=2008 & NATLOC==2)

*Create a variable for multi property owners
gen COUNT=1
bysort ID_OWNER :egen TOTAL_COUNT=total(COUNT)


*Recover the empirical catnat contribution
gen ASSU_CATNAT=OWNER_ASSU_PRINC*0.12/1.12
sum ASSU_CATNAT
gen ASSU_CATNAT_FLOOD=0.52*ASSU_CATNAT
gen ASSU_CATNAT_SUBSIDENCE=0.43*ASSU_CATNAT

******************************
*********FOR FLOODING*********
******************************

*Probabilities based on the return periods:
*In high-risk: 5% proba to be flooded every year
*In middle risk: 2% proba to be flooded every year
*In low risk: 0.5% proba to be flooded every year
*Share affected every year: 0.18%
*In safe areas, recover XXX in: 0.18% = 5%*share_high + 2% * share_middle + 0.5% * share_low + XXX * share_safe
*To recover the shares:
sum TRI_RISK1 [aweight=WEIGHT] //share_high = 0.5%
sum TRI_RISK2 [aweight=WEIGHT] //share_middle = 2.1% - 0.5%
sum TRI_RISK3 [aweight=WEIGHT] //share_low = 3.3% - 2.1%
//share_safe = 96.7%

*So XXX = 0.12% proba to be flooded every year


*Set counterfactual contributions for flooding
gen ASSU_COUNTER_FLOOD=ASSU_CATNAT_FLOOD*5/0.18 if TRI_RISK1==1
replace ASSU_COUNTER_FLOOD=ASSU_CATNAT_FLOOD*2/0.18 if TRI_RISK2==1 & TRI_RISK1!=1
replace ASSU_COUNTER_FLOOD=ASSU_CATNAT_FLOOD*0.5/0.18 if TRI_RISK3==1 & TRI_RISK2!=1
replace ASSU_COUNTER_FLOOD=ASSU_CATNAT_FLOOD*0.12/0.18 if TRI_RISK3!=1


********************************
*********FOR SUBSIDENCE*********
********************************

*Set counterfactual contributions for subsidence
*In high-risk: 0.5% proba to be affected every year
*In middle risk: 0.3% proba to be affected avery year
*Share affected every year: 0.15%
*In no risk, retrieve XXX: 0.08% = 0.5%*share_high + 0.2% * share_middle + XXX * share_safe
sum RGA_EXPOSED3 [aweight=WEIGHT] //share_high = 4% 
sum RGA_EXPOSED2 [aweight=WEIGHT] //share_high = 13% 
sum RGA_EXPOSED1 [aweight=WEIGHT] //share_middle = 19.2%
//share_safe = 80.8%

*So XXX = 0.04%

*Set counterfactual contributions for subsidence
gen ASSU_COUNTER_SUBSIDENCE=ASSU_CATNAT_SUBSIDENCE*0.5/0.08 if RGA_EXPOSED3==1
replace ASSU_COUNTER_SUBSIDENCE=ASSU_CATNAT_SUBSIDENCE*0.3/0.08 if RGA_EXPOSED2==1 & RGA_EXPOSED3!=1
replace ASSU_COUNTER_SUBSIDENCE=ASSU_CATNAT_SUBSIDENCE*0.15/0.08 if RGA_EXPOSED1==1 & RGA_EXPOSED2!=1 & RGA_EXPOSED3!=1
replace ASSU_COUNTER_SUBSIDENCE=ASSU_CATNAT_SUBSIDENCE*0.04/0.08 if RGA_EXPOSED1==1 & RGA_EXPOSED2!=1 & RGA_EXPOSED3!=1

*Generate continuous variables of exposure to risks
*Flooding
gen FLOOD_RISK=3 if TRI_RISK1==1
replace FLOOD_RISK=2 if TRI_RISK2==1 & TRI_RISK1==0
replace FLOOD_RISK=1 if TRI_RISK3==1 & TRI_RISK2==0 & TRI_RISK1==0
replace FLOOD_RISK=0 if TRI_RISK3==0

*Subsidence
gen SUBSIDENCE_RISK=3 if RGA_EXPOSED3==1
replace SUBSIDENCE_RISK=2 if RGA_EXPOSED2==1 & RGA_EXPOSED3==0
replace SUBSIDENCE_RISK=1 if RGA_EXPOSED1==1 & RGA_EXPOSED2==0 & RGA_EXPOSED3==0
replace SUBSIDENCE_RISK=0 if RGA_EXPOSED1==0


*Weight observations
	foreach var in ASSU_CATNAT_FLOOD ASSU_COUNTER_FLOOD ASSU_CATNAT_SUBSIDENCE ASSU_COUNTER_SUBSIDENCE {
		replace `var'=`var'*WEIGHT
	}


				
				
*************COMPUTE TRANSFERS BY OWNER CATEGORY*************

	*Define owner categories
	gen OWNERSHIP=1 if HOUSING_TYPE==1 & TOTAL_COUNT==1
	replace OWNERSHIP=2 if HOUSING_TYPE==1 & TOTAL_COUNT>1
	replace OWNERSHIP=3 if HOUSING_TYPE==2
	replace OWNERSHIP=4 if HOUSING_TYPE==3
	replace OWNERSHIP=5 if HOUSING_TYPE==4
	
*Collapse premiums by owner category
collapse (sum) ASSU_CATNAT_FLOOD ASSU_COUNTER_FLOOD /// 
ASSU_CATNAT_SUBSIDENCE ASSU_COUNTER_SUBSIDENCE /// 
WEIGHT /// 
, by(OWNERSHIP)

*The risk factors are rounded numbers. I rescale the total amounts so that the amount raised is the same in the counterfactual and the observed scenarios
foreach var in FLOOD SUBSIDENCE{

*Convert to thousand euros and generate a variable for total transfers
egen TOTAL_CATNAT=total(ASSU_CATNAT_`var'/1000)
egen TOTAL_COUNTER=total(ASSU_COUNTER_`var'/1000)

*Derive the correction ratio
sum TOTAL_CATNAT
global catnat=r(mean)
sum TOTAL_COUNTER
global counter=r(mean)
global correction_ratio=$catnat/$counter

*Adjust variables
replace ASSU_COUNTER_`var'=ASSU_COUNTER_`var'*$correction_ratio
drop TOTAL_CATNAT TOTAL_COUNTER
}


*Derive the values transferred, as a share of total amounts spent on insurance
gen DIFF_FLOOD=-100*(ASSU_CATNAT_FLOOD-ASSU_COUNTER_FLOOD)/116600000
gen DIFF_SUBSIDENCE=-100*(ASSU_CATNAT_SUBSIDENCE-ASSU_COUNTER_SUBSIDENCE)/199900000


*Graphs

*FLOODS
twoway   bar DIFF_FLOOD OWNERSHIP if OWNERSHIP==1, bcolor("maroon") barwidth(.5) || ///
bar DIFF_FLOOD OWNERSHIP if OWNERSHIP==2, bcolor("sienna") barwidth(.5) || ///
bar DIFF_FLOOD OWNERSHIP if OWNERSHIP==3, bcolor("forest_green") barwidth(.5) || ///
bar DIFF_FLOOD OWNERSHIP if OWNERSHIP==4, bcolor("dknavy") barwidth(.5) || ///
bar DIFF_FLOOD OWNERSHIP if OWNERSHIP==5, bcolor("stone") barwidth(.5) ///
 ytitle(" ",orient(horizontal))  ylabel(-10[2]12, angle(0)) ///
xlabel(1 `""Owner-occupied" "Single-property" "owners""' 2 `""Owner-occupied" "Multi-property" "owners""' 3 "Rental dwellings" 4 "Second homes" 5 "Vacant dwellings")  xtitle(" ") graphregion(color(white))	///
 xsize(6) yline(0, lcolor(black)) legend(off)
				graph export "$output\transfers_floods_type_detailed.png", replace
				
				
*SUBSIDENCE
twoway   bar DIFF_SUBSIDENCE OWNERSHIP if OWNERSHIP==1, bcolor("maroon") barwidth(.5) || ///
bar DIFF_SUBSIDENCE OWNERSHIP if OWNERSHIP==2, bcolor("sienna") barwidth(.5) || ///
bar DIFF_SUBSIDENCE OWNERSHIP if OWNERSHIP==3, bcolor("forest_green") barwidth(.5) || ///
bar DIFF_SUBSIDENCE OWNERSHIP if OWNERSHIP==4, bcolor("dknavy") barwidth(.5) || ///
bar DIFF_SUBSIDENCE OWNERSHIP if OWNERSHIP==5, bcolor("stone") barwidth(.5) ///
 ytitle(" ",orient(horizontal))  ylabel(-10[2]12, angle(0)) ///
xlabel(1 `""Owner-occupied" "Single-property" "owners""' 2 `""Owner-occupied" "Multi-property" "owners""' 3 "Rental dwellings" 4 "Second homes" 5 "Vacant dwellings")  xtitle(" ") graphregion(color(white))	///
 xsize(6) yline(0, lcolor(black)) legend(off)
				graph export "$output\transfers_subsidence_type_detailed.png", replace

