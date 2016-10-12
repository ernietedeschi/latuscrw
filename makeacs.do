use $acsfile, clear

replace hhincome = . if hhincome == 9999999

recode age (18/21 = 0) (22/34 = 1) (35/44 = 2) (45/54 = 3) (55/64 = 4) (65/max = 5) (min/17 = -1), gen(age_cat)
recode sex (2 = 0) (1 = 1), gen(gender)
recode hhincome (min/34999 = 1) (35000/74999 = 2) (75000/max = 3), gen(inc_cat)
recode educd (2/61 = 1 "Less than HS") (62/64 = 2 "HS/GED") (65/100 = 3 "Some College/AA") (101/113 = 4 "BA/BS") (114 = 5 "MA/MS") (115 = 6 "Prof") (116 = 7 "PhD") (else = .), gen(edu2)

gen racethn = 1 if race == 1 & (hispan == 0 | hispan == 9)
replace racethn = 2 if race == 2 & (hispan == 0 | hispan == 9)
replace racethn = 3 if racethn == . & (hispan == 0 | hispan == 9)
replace racethn = 4 if hispan > 0 & hispan <= 4

ren statefip statereside

gen constant = 1

keep if age >= 18 & year == 2014
preserve
collapse (percent) constant [iw=perwt], by(statereside)
ren constant stateresidep
save stateresideps_acs, replace
restore

preserve
collapse (percent) constant [iw=perwt], by(gender racethn)
ren constant gendracep
sort gender racethn
egen gendrace = group(gender racethn)
keep gendrace gendracep
save gendraceps_acs, replace
restore


preserve
collapse (percent) constant [iw=perwt], by(gender)
ren constant genderp
save genderps_acs, replace
restore

preserve
collapse (percent) constant [iw=perwt], by(edu2)
ren constant edu2p
save edu2ps_acs, replace
restore

preserve
collapse (percent) constant [iw=perwt], by(age_cat)
ren constant age_catp
save age_catps_acs, replace
restore

preserve
collapse (percent) constant [iw=perwt], by(inc_cat)
ren constant inc_catp
save inc_catps_acs, replace
restore

preserve
collapse (percent) constant [iw=perwt], by(racethn)
ren constant racethnp
save racethnps_acs, replace
restore
