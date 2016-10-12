use polldata, clear
keep uasid $weight
collapse (mean) $weight, by(uasid)
ren $weight uaswt
save uaswt, replace
