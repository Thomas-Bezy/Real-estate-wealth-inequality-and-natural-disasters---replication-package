global dir="..."


****Change code postal en code commune pour dvf****

use "$dir/data_housing_2022.dta", replace


keep ID SURFACE CONSTRUCTION_DATE MUNICIPALITY NATLOC


merge n:1 ID using "$dir\info_for_dvf2022.dta", generate(merge)
drop if merge==2
drop merge

save "$dir/data_for_merge_dvf.dta", replace
