use $asecfile, clear

replace hhincome = . if hhincome == 99999999

recode age (18/21 = 0) (22/34 = 1) (35/44 = 2) (45/54 = 3) (55/64 = 4) (65/max = 5) (min/17 = -1), gen(age_cat)
recode sex (2 = 0) (1 = 1), gen(gender)
recode hhincome (min/34999 = 1) (35000/74999 = 2) (75000/max = 3), gen(inc_cat)
recode educ (2/72 = 1 "Less than HS") (73/73 = 2 "HS/GED") (80/110 = 3 "Some College/AA") (111 = 4 "BA/BS") (123 = 5 "MA/MS") (124 = 6 "Prof") (125 = 7 "PhD") (else = .), gen(edu2)

gen racethn = 1 if race == 100 & (hispan == 0 | hispan == 902)
replace racethn = 2 if race == 200 & (hispan == 0 | hispan == 902)
replace racethn = 3 if racethn == . & (hispan == 0 | hispan == 902)
replace racethn = 4 if hispan > 0 & hispan <= 901

ren statefip statereside

gen constant = 1

keep if age >= 18
preserve
collapse (percent) constant [iw=wtsupp], by(statereside)
ren constant stateresidep
save stateresideps, replace
restore

preserve
collapse (percent) constant [iw=wtsupp], by(gender racethn)
ren constant gendracep
sort gender racethn
egen gendrace = group(gender racethn)
keep gendrace gendracep
save gendraceps, replace
restore


preserve
collapse (percent) constant [iw=wtsupp], by(gender)
ren constant genderp
save genderps, replace
restore

preserve
collapse (percent) constant [iw=wtsupp], by(edu2)
ren constant edu2p
save edu2ps, replace
restore

preserve
collapse (percent) constant [iw=wtsupp], by(age_cat)
ren constant age_catp
save age_catps, replace
restore

preserve
collapse (percent) constant [iw=wtsupp], by(inc_cat)
ren constant inc_catp
save inc_catps, replace
restore

preserve
collapse (percent) constant [iw=wtsupp], by(racethn)
ren constant racethnp
save racethnps, replace
restore
