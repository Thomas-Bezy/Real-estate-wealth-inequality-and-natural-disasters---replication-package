*clear all
global dir="..."
global output="..."





*Import data
use "$dir\data_housing_2017.dta", replace

*Drop variables that are not important for the insurance analysis and that make the dataset heavier
drop TRI_ID ADRENV x y IRIS PRICE_M2 SALES_TOTAL ZE PRICE JRC_100


*Merge for owners
merge n:n id_log using "$dir/premiums_owners.dta", generate(merge)
drop merge

*Replace negative predictions by zeros
replace OWNER_ASSU_PRINC=0 if OWNER_ASSU_PRINC<0

tab OWNER_DECILE if HOUSING_TYPE==1, sum(OWNER_ASSU_PRINC)

*Merge for renters
merge n:n id_log using "$dir/premiums_renters.dta", generate(merge)
drop merge 

*Replace negative predictions by zeros
replace RENTER_ASSU_PRINC=0 if RENTER_ASSU_PRINC<0

tab RENTER_DECILE if HOUSING_TYPE==2, sum(RENTER_ASSU_PRINC)


*****Check consistency + scale down or up depending on insurance data available online

*Average premiums for main residence appartments: 190€, for owners: 244€, for renters: 166€
*Average premiums for main residence houses: 400€, for owners: 429€, for renters: 256€
*Average premiums for residents: 290€, non-residents: 155€
*Average premiums for main residence appartments: 190€, second residence: 158€
*AVerage premiums for main residence houses: 400€, second residence: 329€

*Average premiums for main residence appartments
*In the data, owners : 272€
sum OWNER_ASSU_PRINC if HOUSING_TYPE==1 & NATLOC==1 [aweight=WEIGHT]
global v1=`r(mean)'
*In the data, renters : 172€
sum RENTER_ASSU_PRINC if HOUSING_TYPE==2 & NATLOC==1 [aweight=WEIGHT]
global v2=`r(mean)'

global ratio=$v1 / $v2
global correction=$ratio /1.46
*Ratio should be 1.46 and is 1.6. We readjust by 1.1
replace RENTER_ASSU_PRINC=RENTER_ASSU_PRINC*$correction if HOUSING_TYPE==2 & NATLOC==1

*Average premiums for main residence houses
*In the data, owners : 362€
sum OWNER_ASSU_PRINC if HOUSING_TYPE==1 & NATLOC==2 [aweight=WEIGHT]
global v1=`r(mean)'
*In the data, renters : 263€
sum RENTER_ASSU_PRINC if HOUSING_TYPE==2 & NATLOC==2 [aweight=WEIGHT]
global v2=`r(mean)'

global ratio=$v1 / $v2
global correction=$ratio /1.68
*Ratio should be 1.68 and is 1.37. We readjust by 0.81
replace RENTER_ASSU_PRINC = RENTER_ASSU_PRINC*$correction if HOUSING_TYPE==2 & NATLOC==2

*Average premiums for residents vs non-residents
*In the data, residents: 297€
gen RESIDENT_ASSU_PRINC=OWNER_ASSU_PRINC if HOUSING_TYPE==1 | HOUSING_TYPE==3
replace RESIDENT_ASSU_PRINC=RENTER_ASSU_PRINC if HOUSING_TYPE==2
sum RESIDENT_ASSU_PRINC   [aweight=WEIGHT]
global v1=`r(mean)'
*In the data, non-residents: 262€
sum OWNER_ASSU_PRINC if HOUSING_TYPE==2 | HOUSING_TYPE==4  [aweight=WEIGHT]
global v2=`r(mean)'

global ratio=$v1 / $v2
global correction=$ratio /1.87
*Ratio should be 1.87 and is 1.13. We readjust by 0.6
replace OWNER_ASSU_PRINC=OWNER_ASSU_PRINC*$correction if  HOUSING_TYPE==2 | HOUSING_TYPE==4

*Average premiums for appartments main vs second residence
*In the data, main residence: 223€
sum RESIDENT_ASSU_PRINC if (HOUSING_TYPE==1 | HOUSING_TYPE==2) & NATLOC==1   [aweight=WEIGHT]
global v1=`r(mean)'
*In the data, second residence: 215€
sum OWNER_ASSU_PRINC if HOUSING_TYPE==3 & NATLOC==1  [aweight=WEIGHT]
global v2=`r(mean)'

global ratio=$v1 / $v2
global correction=$ratio /1.2
*Ratio should be 1.20 and is 1.03. We readjust by 0.85
replace OWNER_ASSU_PRINC=OWNER_ASSU_PRINC*$correction if HOUSING_TYPE==3 & NATLOC==1 

*Average premiums for houses main vs second residence
*In the data, main residence: 339€
sum RESIDENT_ASSU_PRINC if (HOUSING_TYPE==1 | HOUSING_TYPE==2) & NATLOC==2  [aweight=WEIGHT]
global v1=`r(mean)'
*In the data, second residence: 325€
sum OWNER_ASSU_PRINC if HOUSING_TYPE==3 & NATLOC==2  [aweight=WEIGHT]
global v1=`r(mean)'

global ratio=$v1 / $v2
global correction=$ratio /1.21
*Ratio should be 1.21 and is 1.04. We readjust by 0.86
replace OWNER_ASSU_PRINC=OWNER_ASSU_PRINC*$correction if HOUSING_TYPE==3 & NATLOC== 2


*Drop useless variables
drop merge RESIDENT_ASSU_PRINC


*Export
save "$dir\data_housing_insurance_2017.dta", replace
