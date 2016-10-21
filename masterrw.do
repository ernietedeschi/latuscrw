* LAT/USC Reweight
* Ernie Tedeschi
* October 11, 2016

**** USER OPTIONS

global acsfile 	"usa_00012.dta"		// Name of the ACS extract file to use
global asecfile "cps_00044.dta"		// Name of the CPS ASEC extract file to use
global weight 	"w1011_main"		// Latest LAT/USC official weight (from polldata.dta)
					// NOTE: This variable names changes with every polldata.dta update!

local lastday td(11oct2016)					// Final day of analysis (Should be day before the date the LAT/USC file was updated)		
local wd "/Users/ernietedeschi/Documents/data/polling/final/"	// Working directory. Put all files here.

**** END USER OPTIONS

cd `wd'

do makeacs.do		// Creates ACS weights
do makeasec3.do		// Creates ASEC weights
do getuasid.do		// Gets the official LAT/USC

use fulldata, clear

** Create education recode
recode education (1/8 = 1 "Less than HS") (9 = 2 "HS/GED") (10/12 = 3 "Some College/AA") (13 = 4 "BA/BS") (14 = 5 "MA/MS") (15 = 6 "Prof") (16 = 7 "PhD") (else = .), gen(edu2)


** Fill in missing data
sort uasid polldate

capture program drop corrdata
program define corrdata
	replace `1' = -99 if `1' == .
	by uasid: egen `1'_t = max(`1')
	replace `1' = `1'_t if `1' != `1'_t
	drop `1'_t
	replace `1' = . if `1' == -99
end

corrdata age_cat
corrdata gender
corrdata inc_cat
corrdata racethn
corrdata edu2
corrdata statereside
corrdata maritalstatus


** Drop incomplete responses and <18 and oversamples
reg statereside age_cat gender inc_cat racethn edu2 maritalstatus
gen full = e(sample)
keep if full == 1
keep if age >= 18
keep if sampletype == 1


** Create gender/race interaction
sort gender racethn
egen gendrace = group(gender racethn)

** Create 7-day waves
expand 7
sort uasid polldate
egen seq = seq(), from(0) to(6)

gen ewave = polldate + seq

** Ensure maximum one response per wave, the latest one
bysort uasid ewave: egen wavecount = count(uasid)
gen sample = wavecount == 1
replace sample = 1 if wavecount > 1 & ewave[_n+1] != ewave
keep if sample == 1


** Generate ACS-based weight (acswt)
capture program drop getdata
program define getdata
	merge m:1 `1' using `1'ps_acs, nogen
end

getdata gendrace
getdata inc_cat
getdata age_cat
getdata racethn
getdata edu2
getdata statereside
getdata maritalstatus


gen acswt = 10000

capture program drop rewt
program define rewt
	bysort ewave: egen tpop = total(acswt)
	bysort ewave `1': egen spop = total(acswt)
	replace acswt = acswt*`1'p*tpop/(spop*100)
	drop tpop spop
end

forvalues i = 1/100 {
	rewt gendrace
	rewt statereside
    	rewt age_cat
    	rewt edu2
	rewt inc_cat
	rewt maritalstatus

}


by ewave: egen twt = total(acswt)
replace acswt = 250293000*acswt/twt

** Generate ASEC-based weights (asecwt)
drop gendracep inc_catp age_catp racethnp edu2p stateresidep maritalstatusp twt

capture program drop getdata
program define getdata
	merge m:1 `1' using `1'ps, nogen
end

getdata gendrace
getdata inc_cat
getdata age_cat
getdata racethn
getdata edu2
getdata statereside
getdata maritalstatus

gen asecwt = 10000

capture program drop rewt
program define rewt
	bysort ewave: egen tpop = total(asecwt)
	bysort ewave `1': egen spop = total(asecwt)
	replace asecwt = asecwt*`1'p*tpop/(spop*100)
	drop tpop spop
end

forvalues i = 1/100 {
	rewt gendrace
	rewt statereside
    	rewt age_cat
    	rewt edu2
	rewt inc_cat
	rewt maritalstatus
}


by ewave: egen twt = total(asecwt)
replace asecwt = 250293000*asecwt/twt

** Create composite weight (average of acswt & asecwt) 
gen finalwt = (acswt + asecwt)/2

format ewave %td

** Graph results
preserve
collapse (mean) prob_clint prob_trump prob_other [iw=acswt], by(ewave)
tsset ewave
gen nv = (100 - prob_clint - prob_trump - prob_other)
gen clinton = prob_clint/(1-nv/100)
gen trump = prob_trump/(1-nv/100)
gen other = prob_other/(1-nv/100)
keep if ewave <= `lastday'
keep if _n >= 8
tsline clinton trump
table ewave, con(mean clinton mean trump mean other)
restore


