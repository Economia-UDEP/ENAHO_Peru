/*==========================================================================

                            ENAHO | CLEANING

===========================================================================

Author:     Paúl Corcuera

===========================================================================*/

********************************************************************************
**#  Cleaning and Creating Variables
********************************************************************************


******************************************
** Identifiers
******************************************

* Person and Household
cap drop idperson 
fegen idperson = group(conglome vivienda hogar codperso)
	la var idperson "Person Identifier"

cap drop idhogar
fegen idhogar = group(conglome vivienda hogar)
	la var idhogar "Household Identifier"


* Geographic IDs 
cap drop iddep 
gen iddep= real(substr(ubigeo,1,2))
	destring iddep, replace 
	la var iddep "Region ID"

cap drop idprov 
gen idprov = real(substr(ubigeo,1,4))
	la var idprov "Province ID"

cap drop iddist
gen iddist = real(substr(ubigeo,1,4))
	la var iddist "Province ID"
	
******************************************
** Demographic Variables
******************************************

* Rural Status
cap drop rural 
gen byte rural = !inrange(estrato,1,5) if !mi(estrato)
	la var rural "Rural"
	

* Married
cap drop married 
gen byte married = (p209==2) if !mi(p209)
	la var married "Married"
	
* Age
cap drop age
clonevar age = p208a
	la var age "Age"	
	
* Years of Education
cap drop edu_years
gen byte edu_years = . 
replace edu_years  = 0 if inlist(p301a,1,2) // sin nivel/inicial
replace edu_years  = p301c if !mi(p301c) & p301a==3   // cursando primaria 
replace edu_years  = p301b if  mi(p301c) & !mi(p301b) & p301a==3   // cursando primaria pero llenaron p301b
replace edu_years  = 6 if p301a==4 | (p301a==12 & year>=2012) // culminó primaria, para educación básica especial también
replace edu_years  = p301b + 6 if p301a == 5 // cursando secundaria
replace edu_years  = 11 if p301a == 6  // culminó secundaria 
replace edu_years  = 11 + p301b if inrange(p301a,7,10)  // cursó sup no universitaria
replace edu_years  = 11 + 5 + p301b if p301a==11  // cursó posgrado univ (asume 5 años de carrera)
	la var edu_years "Years of Education"
	

* Poverty Status
cap drop poor 
gen byte poor = pobreza==1 if inlist(pobreza,1,2)
	la var poor "Poverty"

* Extreme Poverty Status	
cap drop extreme_poor 
gen byte extreme_poor = pobreza==2 if inlist(pobreza,1,2)
	la var extreme_poor "Extreme Poor"
	
* Educational Level MTPE
cap drop nivel_educ
recode p301a (1 2 3=1) (4 5 = 2) (6 7 9 = 3) (8 = 4) (10 11 = 5) (12 = 6) (else=.), gen(nivel_educ)
	la var nivel_educ "Education Level"
	label define nivel_educ_lbl 1 "Sin educación" 2 "Primaria" 3 "Secundaria" 4 "Superior No Universitaria" 5 "Superior Universitaria" 6 "Básica Especial", modify
	label values nivel_educ nivel_educ_lbl
	
******************************************
** Labor Market Variables
******************************************

* Market Income variables
 foreach var in p524a1 p530a p538a1 p541a {
	    replace `var' = . if `var' == 999999  | `var' == 99999
		}

cap drop wage_pri 
gen wage_pri 		= 0 if !missing(p524a1) & !missing(p523)
replace wage_pri	= p524a1 * 260/12 if p523 == 1
replace wage_pri   	= p524a1 * 52/12  if p523 == 2
replace wage_pri   	= p524a1 * 2      if p523 == 3
replace wage_pri   	= p524a1 * 1      if p523 == 4			
	la var wage_pri "Monthly Wage"

	
cap drop wage_pri_net
clonevar wage_pri_net = p524e1
	la var wage_pri_net "Monthly Net Wage"

	
cap drop binc_pri 
clonevar binc_pri = p530a 
	la var binc_pri "Business Income"

	
cap drop wage_sec 
clonevar wage_sec = p538a1 
	la var wage_sec "Monthly Wage (Sec)"

	
cap drop wage_sec_net 
clonevar wage_sec_net = p538e1
	la var wage_sec_net "Monthly Net Wage (Sec)"
	
	
cap drop binc_sec 
clonevar binc_sec = p541a
	la var binc_sec "Business Income (Sec)"


cap drop labincome_pri 
egen labincome_pri = rowtotal(wage_pri binc_pri)
	la var labincome_pri "Labor Income"

	
cap drop labincome_sec 
egen labincome_sec = rowtotal(wage_sec binc_sec)
	la var labincome_pri "Labor Income (Sec)"

cap drop labincome 
egen labincome = rowtotal(labincome_pri labincome_sec)
	la var labincome "Labor Income"
	
	
* Intermediate Variables for Labor Force construction MTPE
d p5041-p50411
cap drop any504 
gen byte any504 = 1 if p5041==1 | p5042==1 | p5043==1 | p5044==1 | p5045==1 | p5046==1 | p5047==1 | p5048==1 | p5049==1 | p50410==1 | p50411==1 

cap drop all504
gen byte all504 = 1 if p5041==2 & p5042==2 & p5043==2 & p5044==2 & p5045==2 & p5046==2 & p5047==2 & p5048==2 & p5049==2 & p50410==2 & p50411==2 

* Labor force
d p501-p503 p507
cap drop condact 
gen byte condact = . 
	replace condact =  1 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,1,2,3,4,6)) 
	replace condact =  1 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t>=15 
	replace condact =  2 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==1 & inrange(p550,1,6)
	replace condact =  2 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==2 & inlist(p546,1,2)
	replace condact =  2 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==2 & inrange(p546,3,8) & p547==1 & p548==1 & p549==10 
	replace condact =  2 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==2 & inrange(p546,3,8) & p547==1 & p548==1 & p549==11 & inrange(p550,1,6) 
	replace condact =  2 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==1 & inrange(p550,1,6) 
	replace condact =  2 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==2 & inrange(p546,1,2) 
	replace condact =  2 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==2 & inrange(p546,3,8) & p547==1  & p548==1 & p549==10
	replace condact =  2 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==2 & inrange(p546,3,8) & p547==1  & p548==1 & p549==11 & inrange(p550,1,6)
	replace condact =  3 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==1 & p550==7
	replace condact =  3 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==2 & inrange(p546,3,8) & p547==1 & p548==1 & (inrange(p549,1,9) | p549==12) 
	replace condact =  3 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==2 & inrange(p546,3,8) & p547==1 & p548==2  
	replace condact =  3 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==2 & inrange(p546,3,8) & p547==2   
	replace condact =  3 if (p501==1 | p502==1 | p503==1 | any504==1) & (inlist(p507,5,7)) & i513t<15 & p545==2 & inrange(p546,3,8) & p547==1 & p548==1 & p549==11 & p550==7    
	replace condact =  3 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==1 & p550==7 
	replace condact =  3 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==2 & inrange(p546,3,8) & p547==1 & p548==1 & (inrange(p549,1,9) | p549==12) 
	replace condact =  3 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==2 & inrange(p546,3,8) & p547==1 & p548==2 
	replace condact =  3 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==2 & inrange(p546,3,8) & p547==2  
	replace condact =  3 if (p501==2 & p502==2 & p503==2 & all504==1) & p545==2 & inrange(p546,3,8) & p547==1 & p548==1 & p549==11 & p550==7 
	la var condact "Labor Market Status"
	la define condact 1 "Employed" 2 "Unemployed" 3 "Inactive", modify
	la values condact condact
	
	
* Dual Job Holder
cap drop dual_job
gen byte dual_job = (p514==1) if condact==1
	la var dual_job "Hold Multiple Jobs"
	

* Industry (based on CIIU 4 digits)
cap drop ind_sector
gen byte ind_sector = .
* 1. Agricultura, ganadería, silvicultura y pesca [farming, livestock, forestry,and fishing]
replace ind_sector = 1 if inrange(p506,111,113)  | inlist(p506,121,122,130,140,150,200,500)

* 2. Minería [mining]
replace ind_sector = 2 if inlist(p506,1010,1020,1030,1110,1120,1200,1310,1320,1410,1421) ///
    | inlist(p506,1422,1429)

* 3. Industria de bienes de consumo (ejemplo dividiendo bloques) [consumption goods industry]
replace ind_sector = 3 if inrange(p506,1511,1515) ///
    | inlist(p506,1520,1531,1532,1533,1541,1542,1543,1544,1549) ///
    | inlist(p506,1551,1552,1553,1554,1600,1711,1712,1721,1722,1723) ///
    | inlist(p506,1729,1730,1810,1820,1920,2029,2109,2211,2212) ///
    | inlist(p506,2219,2221,2222,2520,3312,3313,3320,3330) ///
    | inlist(p506,3610,3691,3692,3693,3694,3699)

* 4. Industria de bienes intermedios [intermediate goods industry]
replace ind_sector = 4 if inlist(p506,1911,1912,2010,2021,2022,2023,2101,2102,2310,2320) ///
	| inlist(p506,2330,2430,2511,2519,2610,2720,2731,2732,2891,2892) ///
	| inlist(p506,3710,3720) ///
    | inrange(p506,2411,2413) | inrange(p506,2421,2424) | inlist(p506,2429) | inlist(p506,2691,2692,2693,2694,2695,2696,2699)

* 5. Industria de bienes de capital [capital goods industry]
replace ind_sector = 5 if inlist(p506,2213,2710,2811,2812,2813,2893,2899,2911,2912,2913) ///
	| inlist(p506,2914,2915,2919,2921,2922,2923,2924,2925) | inlist(p506,2926,2927,2929,2930,2999,3000,3110,3120,3130) | inlist(p506,3140,3150,3190,3210,3220,3230,3311,3410,3420) | inlist(p506,3430,3511,3512,3520,3530,3591,3592,3599,7250)

* 6. Electricidad, gas y agua [electricity, natural gas, and water]
replace ind_sector = 6 if inlist(p506,4010,4020,4030,4100)

* 7. Construcción [construction/building]
replace ind_sector = 7 if inlist(p506,4510,4520,4530,4540,4550)

* 8. Comercio por mayor [wholesale trade]
replace ind_sector = 8 if inlist(p506,5110,5121,5122,5131,5139,5141,5142,5143,5149,5150) | inlist(p506,5190)

* 9. Comercio por menor [retail trade]
replace ind_sector = 9 if inlist(p506,2230,5010,5030,5040,5050,5211,5219,5220,5231,5232) | inlist(p506,5233,5234,5239,5240,5251,5252,5259,5270,7130)

* 10. Restaurantes y hoteles [restaurants and hotels]
replace ind_sector = 10 if inlist(p506,5510,5520)

* 11. Transporte, almacenamiento y comunicaciones [transportation, storage, and communications]
replace ind_sector = 11 if inlist(p506,6010,6030,6110,6120,6210,6220,6411,6412,6420,7111,7112,7113,9220) ///
    | inrange(p506,6021,6023) | inrange(p506,6301,6304) | inlist(p506,6309)

* 12. Estab. financieros, seguros, inmuebles, servicios a empresas
replace ind_sector = 12 if inlist(p506,6511,6519,6591,6592,6599,6601,6602,6603,6711,6712,6719,6720,7010) | inlist(p506,7020,7210,7220,7230,7240,7290,7411,7412,7413,7414) | inlist(p506,7421,7422,7430,7491,7492,7493,7495,7499) ///
    | inrange(p506,7121,7123) | inlist(p506,7129)

* 13. Servicios comunitarios, sociales y recreativos [community, social, and recreative services]
replace ind_sector = 13 if inlist(p506,7310,7320,7511,7512,7513,7514,7521,7522,7523,7530,8010,8021) | inlist(p506,8022,8030,8090,8511,8512,8519,8520,8531,8532,9000) | inlist(p506,9111,9112,9120,9191,9192,9199,9211) | inlist(p506,9212,9213,9214,9219,9231,9232,9233,9241,9249,9900)

* 14. Servicios personales [Personal services]
replace ind_sector = 14 if inlist(p506,5020,5260,7494,9301,9302,9303,9309)

* 15. Hogares [households]
replace ind_sector = 15 if p506==9500

* 99. No especificado [non-specified]
replace ind_sector = 99 if p506==9999


	* Labels in English
	label define sectorlbl ///
		1  "Agriculture, livestock, forestry, and fishing" 	///
		2  "Mining" 										///
		3  "Consumer goods industry" 						///
		4  "Intermediate goods industry" 					///
		5  "Capital goods industry" 						///
		6  "Electricity, gas, and water" 					///
		7  "Construction" 									///
		8  "Wholesale trade" 								///
		9  "Retail trade" 									///
		10 "Restaurants and hotels" 						///
		11 "Transport, storage, and communications" 		///
		12 "Financial establishments, real estate, business services" ///
		13 "Community, social, and recreational services" 	///
		14 "Personal services" 								///
		15 "Households" 									///
		99 "Not specified"
	label values ind_sector sectorlbl
	la var ind_sector "Industry Code"


* Unpaid Family Work
cap drop tfnr
gen tfnr = (p507 == 5) if condact==1
	label variable tfnr "Unpaid Family Worker"
	
* Hours	
cap drop horas_pri
clonevar horas_pri = i513t if condact==1 // asignamos 0 horas de trabajo para esos casos en que no está ocupado
	la var horas_pri "Hours Worked"
	*winsor2 horas_pri, replace cuts(0 99) by(year) //winsorize at the top


cap drop horas_sec 
gen horas_sec = i518 if condact==1
	la var horas_sec "Hours Worked (Secondary)"

	
cap drop horas_both 
egen horas_both = rowtotal(horas_pri i518) if p519==1 
replace horas_both = i520 if p519==2
replace horas_both = . if condact!=1
	la var horas_both "Total Hours Worked"
	

cap drop ranhoras
gen ranhoras = 1 if horas_both<15
replace ranhoras = 2 if inrange(horas_both,15,24)
replace ranhoras = 3 if inrange(horas_both,35,47)
replace ranhoras = 4 if horas_both==48
replace ranhoras = 5 if inrange(horas_both,49,59)
replace ranhoras = 6 if horas_both>=60 & !mi(horas_both)
replace ranhoras = . if inlist(condact,2,3)
	la var ranhoras "Range of Hours Worked (MTPE)"
	
	
* Self-employment: One is based on primary occupation, and the other on any occupation
cap drop indep 
gen byte indep = inlist(p507,1,2) if condact==1 
	la var indep "Self-Employed (Main Occ)"

cap drop indep2 
gen byte indep2 = inlist(p507,1,2) | inlist(p517,1,2) if condact==1
	la var indep2 "Self-Employed (Any Occ)"

	
* Tenure
cap drop temp 
gen temp = p513a2/12  // in years

cap drop tenure 
egen tenure = rowtotal(p513a1 temp) if condact==1
replace tenure = . if missing(p513a1) & missing(temp)
cap drop temp
	la var tenure "Tenure (years)"

	
* Employed
cap drop employed 
gen byte employed = (condact==1) if !mi(condact)
	la var employed "Employed"
	

* Formal Employment
cap drop formal_emp
gen byte formal_emp = (ocupinf == 2) if condact==1
	la var formal_emp "Formal Employed"

* Formal Sector (i.e. working at formal business)
cap drop formal_sec
gen byte formal_sec = (ocupinf==2 | emplpsec==2) if condact==1
	la var formal_sec "Formal Firm"

* Empleo Informal (~ working without contract)
cap drop informal_emp 
gen byte informal_emp = !(ocupinf==2)  if condact==1
	la var informal_emp "Informal Employed"

* Informal Sector
cap drop informal_sec 
gen byte informal_sec = !(ocupinf==2 | (ocupinf==1 & emplpsec==2)) if condact==1
	la var informal_sec "Informal Firm"