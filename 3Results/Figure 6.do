clear all
global dir="..."
global output="..."




*******Lower prices?
use "$dir\data_housing_2017.dta", replace

*Create a variable for multi property owners
gen COUNT=1
bysort ID_OWNER :egen TOTAL_COUNT=total(COUNT)

*Differentiate owner-occupants and absentee landlords
gen OWNERSHIP=1 if HOUSING_TYPE==1
replace OWNERSHIP=2 if HOUSING_TYPE>1

*Modify prices variables to get the log price per meter squared
drop PRICE_M2
gen PRICE_M2=PRICE/SURFACE
keep if PRICE_M2!=.
gen LOG_PRICE_M2=log(PRICE_M2)

*Flag basements
gen BASEMENT=(FLOOR=="80"|FLOOR=="81"|FLOOR=="82"|FLOOR=="83"|FLOOR=="84"|FLOOR=="85"|FLOOR=="86"|FLOOR=="87"|FLOOR=="88"|FLOOR=="89"| ///
FLOOR=="90"|FLOOR=="91"|FLOOR=="92"|FLOOR=="93"|FLOOR=="94"|FLOOR=="95"|FLOOR=="96"|FLOOR=="97"|FLOOR=="98"|FLOOR=="99")


*Measure individual damages for risk level r and type of flood t (river or coastal)
foreach r in 1 2 3{
foreach t in 1 3{
	
	gen DAMAGE_RISK`r'_TYPE`t'=.
	
	*Homes on the first floor
	replace DAMAGE_RISK`r'_TYPE`t'=(91.8 + 102.2) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==1
	replace DAMAGE_RISK`r'_TYPE`t'=(113.8 + 151.6) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==2
	replace DAMAGE_RISK`r'_TYPE`t'=(154 + 190.1) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==3
	replace DAMAGE_RISK`r'_TYPE`t'=(237.9 + 194.4) *SURFACE if FLOOR=="00" & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==4
	
	*Basements (individual damages)
	replace DAMAGE_RISK`r'_TYPE`t'=(0.9) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==1
	replace DAMAGE_RISK`r'_TYPE`t'=(1.2) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==2
	replace DAMAGE_RISK`r'_TYPE`t'=(1.7) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==3
	replace DAMAGE_RISK`r'_TYPE`t'=(8.2) *SURFACE if BASEMENT==1 & NATLOC==2 & RISK`r'_TYPE`t'_DEPTH==4
	
	*Appartments on the first floor
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
*Compute aggregate damages for each risk level
gen DAMAGE_RISK`r'=DAMAGE_RISK`r'_TYPE1 + DAMAGE_RISK`r'_TYPE3
}

*Drop useless variables
drop DAMAGE_RISK1_TYPE1 DAMAGE_RISK1_TYPE3 DAMAGE_RISK2_TYPE1 DAMAGE_RISK2_TYPE3 DAMAGE_RISK3_TYPE1 DAMAGE_RISK3_TYPE3 


*Compute the NPV
gen DAMAGE=.5 * (1.5 * DAMAGE_RISK3 + DAMAGE_RISK3) * (0.001 - 0) + ///
.5 * (DAMAGE_RISK3 + DAMAGE_RISK2) * (0.01 - 0.001) + ///
.5 * (DAMAGE_RISK2 + DAMAGE_RISK1) * (0.1 - 0.01)

gen NPV=DAMAGE

foreach t of num 1/30{
replace NPV=NPV+DAMAGE*(1.033)^(-`t') if HOUSING_TYPE!=2
replace NPV=NPV+DAMAGE*(1.035)^(-`t') if HOUSING_TYPE==2
}




*******In all risky areas*******


*Set the discount rate from the reduced-form section
global degree=2
global discount_rate=-0.01 * $degree


*******Observed overvaluation*******

*Compute the current efficient price with a price discount only for owner-occupants
gen FAIR_MARKET_VALUE=PRICE

gen RISK_FREE_MARKET_VALUE=PRICE/(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==1 // 0.96= 1+delta with delta=-0.04
replace RISK_FREE_MARKET_VALUE=PRICE if DAMAGE>0 & OWNERSHIP==2 // For absentee landlords
replace RISK_FREE_MARKET_VALUE=PRICE if DAMAGE==0 // 

gen EFFICIENT_PRICE=RISK_FREE_MARKET_VALUE-NPV

*Compute the implied overvaluation
gen OVERVALUATION = (FAIR_MARKET_VALUE-EFFICIENT_PRICE)/FAIR_MARKET_VALUE
*Replace the extreme values
replace OVERVALUATION=1 if OVERVALUATION>1
replace OVERVALUATION=-1 if OVERVALUATION<-1

*Store the level of overvaluation
sum OVERVALUATION if DAMAGE>0 & TRI_RISK3==1,d
global overvaluation_$degree = 100*round(r(mean),.001)

dis ${overvaluation_$degree}

drop FAIR_MARKET_VALUE RISK_FREE_MARKET_VALUE EFFICIENT_PRICE OVERVALUATION

*******Counterfactual overvaluation*******

*Compute the counterfactual efficient price with a price discount for all owners
gen FAIR_MARKET_VALUE=PRICE
replace FAIR_MARKET_VALUE=PRICE*(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==2

gen RISK_FREE_MARKET_VALUE=PRICE/(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==1 // 0.96= 1+delta with delta=-0.04
replace RISK_FREE_MARKET_VALUE=PRICE/(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==2 // For absentee landlords, same price discount as for owner-occupants
replace RISK_FREE_MARKET_VALUE=PRICE if DAMAGE==0 // 

gen EFFICIENT_PRICE=RISK_FREE_MARKET_VALUE-NPV

*Compute the implied overvaluation
gen OVERVALUATION_COUNTER = (FAIR_MARKET_VALUE-EFFICIENT_PRICE)/FAIR_MARKET_VALUE
*Replace the extreme values
replace OVERVALUATION_COUNTER=1 if OVERVALUATION_COUNTER>1
replace OVERVALUATION_COUNTER=-1 if OVERVALUATION_COUNTER<-1

*Store the level of overvaluation
sum OVERVALUATION_COUNTER if DAMAGE>0 & TRI_RISK3==1,d
global overvaluation_counter_$degree = 100*round(r(mean),.001)

dis ${overvaluation_counter_$degree}

drop FAIR_MARKET_VALUE RISK_FREE_MARKET_VALUE EFFICIENT_PRICE OVERVALUATION_COUNTER






*******In high-risk areas*******


*Set the discount rate from the reduced-form section
global degree=5
global discount_rate=-0.01 * $degree


*******Observed overvaluation*******

*Compute the current efficient price with a price discount only for owner-occupants
gen FAIR_MARKET_VALUE=PRICE

gen RISK_FREE_MARKET_VALUE=PRICE/(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==1 // 0.96= 1+delta with delta=-0.04
replace RISK_FREE_MARKET_VALUE=PRICE if DAMAGE>0 & OWNERSHIP==2 // For absentee landlords
replace RISK_FREE_MARKET_VALUE=PRICE if DAMAGE==0 // 

gen EFFICIENT_PRICE=RISK_FREE_MARKET_VALUE-NPV

*Compute the implied overvaluation
gen OVERVALUATION = (FAIR_MARKET_VALUE-EFFICIENT_PRICE)/FAIR_MARKET_VALUE
*Replace the extreme values
replace OVERVALUATION=1 if OVERVALUATION>1
replace OVERVALUATION=-1 if OVERVALUATION<-1

*Store the level of overvaluation
sum OVERVALUATION if DAMAGE>0 & TRI_RISK1==1,d
global overvaluation_$degree = 100*round(r(mean),.001)

dis ${overvaluation_$degree}

drop FAIR_MARKET_VALUE RISK_FREE_MARKET_VALUE EFFICIENT_PRICE OVERVALUATION

*******Counterfactual overvaluation*******

*Compute the counterfactual efficient price with a price discount for all owners
gen FAIR_MARKET_VALUE=PRICE
replace FAIR_MARKET_VALUE=PRICE*(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==2

gen RISK_FREE_MARKET_VALUE=PRICE/(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==1 // 0.96= 1+delta with delta=-0.04
replace RISK_FREE_MARKET_VALUE=PRICE/(1+${discount_rate}) if DAMAGE>0 & OWNERSHIP==2 // For absentee landlords
replace RISK_FREE_MARKET_VALUE=PRICE if DAMAGE==0 // 

gen EFFICIENT_PRICE=RISK_FREE_MARKET_VALUE-NPV

*Compute the implied overvaluation
gen OVERVALUATION_COUNTER = (FAIR_MARKET_VALUE-EFFICIENT_PRICE)/FAIR_MARKET_VALUE
*Replace the extreme values
replace OVERVALUATION_COUNTER=1 if OVERVALUATION_COUNTER>1
replace OVERVALUATION_COUNTER=-1 if OVERVALUATION_COUNTER<-1

*Store the level of overvaluation
sum OVERVALUATION_COUNTER if DAMAGE>0 & TRI_RISK1==1,d
global overvaluation_counter_$degree = 100*round(r(mean),.001)

dis ${overvaluation_counter_$degree}

drop FAIR_MARKET_VALUE RISK_FREE_MARKET_VALUE EFFICIENT_PRICE OVERVALUATION_COUNTER







***Produce the figure


clear 
set obs 2
egen n =seq()

*Generate scenarios to plot (observed or counterfactual)
foreach scenario in overvaluation overvaluation_counter{
	gen `scenario'=.
} 


*Replace by the corresponding values
global j=1
foreach degree in 2 5{
foreach scenario in overvaluation overvaluation_counter{

replace `scenario'=${`scenario'_`degree'} if n==$j

}
global j = $j +1
}

*Generate difference in percentages
gen difference = 100* (overvaluation-overvaluation_counter)/overvaluation

*Adjust graph coordinates
gen n1=n-0.2
gen n2=n+0.2

grstyle init
grstyle set plain
				

*Graph
twoway (bar  overvaluation n1, bcolor(cranberry) barwidth(.4))  ///
(bar  overvaluation_counter n2, bcolor(dknavy) barwidth(.4)) , ///
xlab(1 "In all risky areas" 2 "In high-risk areas" , nogrid angle(0)) ///
yline(0, lcolor(black)) ///
ylab(0[2]26, angle(0)) ytitle("Overvaluation" "of the housing stock" "in flood-prone areas" " " "in percentages", orient(horizontal)) ///
legend(order(1 2 3 4 5) col(1) lab (1 "{bf:Observed overvaluation} - flood risk discount for owner-occupants only") lab (2 "{bf:Counterfactual overvaluation} - flood risk discount for all owners")) ///
xtitle("") xsize(7)
				graph export "$output\overvaluation.png", replace

