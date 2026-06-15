clear all
global dir=".."



use "$dir/Data/data_for_prices_reg.dta", replace

*Merge with data on protection plans
merge n:1 MUNICIPALITY using "$dir\pprn_by_municipality.dta", generate(merge)
drop if merge==2
drop merge

drop PPRN
gen PPRN=(PPRN_DATE=="2016"|PPRN_DATE=="2015"|PPRN_DATE=="2014"|PPRN_DATE=="2013"|PPRN_DATE=="2012"|PPRN_DATE=="2011"|PPRN_DATE=="2010"|PPRN_DATE=="2009"|PPRN_DATE=="2008"|PPRN_DATE=="2007")

*Generate a variable for owner's income squared
gen OWNER_INCOME2=OWNER_INCOME^2

*Define ownership categories
replace OWNERSHIP=1 if OWNERSHIP<=2
replace OWNERSHIP=2 if OWNERSHIP>2

*Run regressions for each exposure to risk
foreach risk in FLOOD1 RGA2{

*For each owner category
foreach group in 1 2 3 4 5{

*For every set of fixed effects
foreach geo in MUN IRIS STREET{
reghdfe LOG_PRICE_M2 `risk'_EXPOSED_INTER `risk' `risk'_EXPOSED SURFACE CONSTRUCTION_DATE i.NATLOC OWNER_INCOME OWNER_INCOME2 if OWNERSHIP==`group' & `geo'_`risk'>0 [aweight=WEIGHT], absorb(`geo' DATE_OWNERSHIP FLOOR PPRN) cluster(DATE_OWNERSHIP)
global coef_`risk'_group`group'_g`geo'=_b[`risk'_EXPOSED_INTER]
global se_`risk'_group`group'_g`geo'=_se[`risk'_EXPOSED_INTER]
}

}
}


************************
****Build the graphs****
************************

clear 
set obs 3
egen n =seq()

*Generate variables
foreach disaster in FLOOD1 RGA2{
foreach outcome of num 1/2{
	gen `disaster'_`outcome'=.
	gen min_`disaster'_`outcome'=.
	gen max_`disaster'_`outcome'=.
} 
}


*Replace variables by the corresponding regression coefficients and confidence intervalls
foreach group of num 1/2{
	
	foreach disaster in FLOOD1 RGA2{
		
	global geo_count=1
	foreach geo in NULL ZE MUN IRIS STREET{
	replace `disaster'_`group'=100*${coef_`disaster'_group`group'_g`geo'} if n==$geo_count
	replace min_`disaster'_`group'=100*(${coef_`disaster'_group`group'_g`geo'} - 1.96 * ${se_`disaster'_group`group'_g`geo'} ) if n==$geo_count
	replace max_`disaster'_`group'=100*(${coef_`disaster'_group`group'_g`geo'} + 1.96 * ${se_`disaster'_group`group'_g`geo'} ) if n==$geo_count
	
global geo_count=${geo_count} + 1
}
}
}



*Adjust y axis
replace n=4-n

gen n1=n+0.2
gen n2=n+0.1
gen n3=n
gen n4=n-0.1
gen n5=n-0.2


grstyle init
grstyle set plain
				
		
*Graphs
*Flooding
twoway (scatter n1 FLOOD1_1, mcolor(maroon)) ///
	   (scatter n2 FLOOD1_2, mcolor(dknavy%80)) ///
	   (rcap max_FLOOD1_1 min_FLOOD1_1 n1, horizontal color(maroon)) ///
	   (rcap max_FLOOD1_2 min_FLOOD1_2 n2, horizontal color(dknavy%80)), ///
xline(0, lcolor(black)) yline(4.5, lcolor(gray%70) lpattern(dash))  ///
ylab(1 "Street FE" 2 "Iris FE" 3 "Municipality FE" , nogrid angle(0)) ///
legend(order(1 2) col(1) lab (1 "Owner-occupied") lab (2 "Rentals, second homes or vacant dwellings")) ///
xtitle(Price per meter squared gap in %)
				graph export "$dir/Figures/Figure 5a.png", replace
				
*Subsidence			
twoway (scatter n1 RGA2_1, mcolor(maroon)) ///
	   (scatter n2 RGA2_2, mcolor(dknavy%80)) ///
	   (rcap max_RGA2_1 min_RGA2_1 n1, horizontal color(maroon)) ///
	   (rcap max_RGA2_2 min_RGA2_2 n2, horizontal color(dknavy%80)), ///
xline(0, lcolor(black)) yline(4.5, lcolor(gray%70) lpattern(dash))  ///
ylab(1 "Street FE" 2 "Iris FE" 3 "Municipality FE" , nogrid angle(0)) ///
legend(order(1 2) col(1) lab (1 "Owner-occupied") lab (2 "Rentals, second homes or vacant dwellings")) ///
xtitle(Price per meter squared gap in %)
				graph export "\$dir/Data/Figure 5b.png", replace				
				
				
				
				
				