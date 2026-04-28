global dir="..."
global output="..."




use "$dir/data_housing_2017_full.dta", replace

*rename ID id_log

drop PRICE STAGE SURF

merge n:n id_log using "$dir\id_log_prices2017.dta", generate(merge)
drop if merge==2
drop merge


save "$dir/data_housing_2017_full.dta", replace


drop TRI_RISK1_TYPE2 TRI_RISK2_TYPE1 TRI_RISK2_TYPE2 TRI_RISK2_TYPE3 TRI_RISK3_TYPE1 TRI_RISK3_TYPE2 TRI_RISK3_TYPE3 REFCAD OWNER_FONCIER OWNER_MOB RENTER_FONCIER RENTER_MOB OWNER_MUN_BIRTH OWNER_TYPE_HH RENTER_MUN_BIRTH RENTER_TYPE_HH INCOME_TOTAL_MUN INCOME_MUN OWNER_INCOME_TOTAL_MUN OWNER_INCOME_MUN



save "$dir\data_housing_2017.dta", replace


