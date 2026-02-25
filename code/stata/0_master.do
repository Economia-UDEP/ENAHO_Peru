/*==========================================================================

                            ENAHO | MASTER DO-FILE

===========================================================================
Do-file:              0_master.do
Objective:            Store raw ENAHO folders according to customization. 
					  Code will clean each survey year separately, then append.
					  Store final ENAHO dataset in output folder.


Authors:              Paúl Corcuera, Vladimir Baños Calle

===========================================================================*/

clear*
set more off
version 16.0

********************************************************************************
**# 0) Path & Setup Parameters
********************************************************************************

* Set up years of interest 
global START_YEAR 2007
global END_YEAR   2024

* Set up the main folder
global MAIN   		"C:\Github\ENAHO_Peru"  // <--- Main repo folder
global DATA 		"${MAIN}/data" 		 
global OUTPUT 		"${MAIN}/output"
global CODE_PYTHON 	"${MAIN}/code/python"
global CODE_STATA   "${MAIN}/code/stata"
global CODE_AUX     "${MAIN}/code/auxiliary"

* Set up output name 
global OUTFILE "${OUTPUT}\enaho_${START_YEAR}_${END_YEAR}.dta" // <--- Name your final output  

* Set up whether you want to download and organize raw folders
global RUN_PYSCRIPT 1 // <--- 0: don't run Python script, 1: run Python script

* Set up whether you want to store cleaned files by year
global SAVE_YEARLY 0   // <--- 0: don't store intermediate yearly files, 1: store

* Verbose mode 
global VERBOSE 1 // <--- 0: no messages, 1: messages along the way

********************************************************************************
**# 0.1) Set up modules and variables to keep (empty lists are allowed)
********************************************************************************

* Módulo 100: Dwelling and Household Information 
global m100 = 1  // <--- 0: exclude, 1: include
global keepvars_m100 ///
	"ubigeo dominio estrato p101 p102 p103 p104 p105"

* Módulo 200: Household Members Characteristics 
global m200 = 1  // <--- 0: exclude, 1: include. Current version always stores this.
global keepvars_m200 ///
	"ubigeo dominio estrato p203 p204 p205 p206 p207 p208a p208a1 p208a2 p209 p210 t211"

* Módulo 300: Education
global m300 = 1 // <--- 0: exclude, 1: include
global keepvars_m300 ///
	"ubigeo dominio estrato p300a p301a p301b p301c p303 p306 p308a p308d"

* Módulo 400: Health
global m400 = 1 // <--- 0: exclude, 1: include
global keepvars_m400 ///
	"ubigeo dominio estrato p401 p401a p402 p402a p400a3 p401g1 p401g1 p419a1 p419a2 p419a3 p419a4 p419a5 p419a8 t401 t402"

* Módulo 500: Employment and Income
global m500 = 1 // <--- 0: exclude, 1: include
global keepvars_m500  ///
	"p501 p502 p503 " ///
    "p5041 p5042 p5043 p5044 p5045 p5046 p5047 p5048 p5049 p50410 p50411 " ///
    "p506 p506r4 p507 p510 p510a1 p512a p512b p514 p519 " ///
    "p545 p546 p547 p548 p549 p550 " ///
    "p550_1 p550_2 p550_3 p550_4 p550_5 p550_6 p550_7 " ///
    "p5566a p599 ocu500 ocupinf emplpsec fac500a" ///
	"i513t i518 i520 i530a i524a1 i524b1 i524c1 i524d1 i524e1 i538a1 i538b1 i538c1 i538d1 i538e1 i5294b i5404b i541a"

* Módulo Sumaria: Summary (Constructed) Variables by INEI
global msum = 1 // <--- 0: exclude, 1: include
global keepvars_msum "conglome vivienda hogar anio ubigeo dominio estrato mieperho percepho linpe pobreza inghog1d gashog1d"

** IMPORTANT: Other modules are not supported for the time being.


********************************************************************************
**# 1) Run Python Script if specified
********************************************************************************
if ${RUN_PYSCRIPT}{
    
python:
import os, sys, subprocess

CODE = r"${CODE_PYTHON}"
DATA  = r"${DATA}"

subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", os.path.join(CODE, "requirements.txt")],cwd=CODE)

subprocess.check_call([sys.executable, os.path.join(CODE, "master_enaho.py"),"--out", DATA, "--reset"],cwd=CODE)
end
	
}

********************************************************************************
**# 2) Loop over years 
********************************************************************************


* We set tempfile names for each year 
forval j=$START_YEAR/$END_YEAR {
	tempfile enaho`j'
	loc enaho`j' = "`enaho`j''"
}

* Next, we run the loop
forvalues yy = ${START_YEAR}/${END_YEAR} {

    if ${VERBOSE} {  
					di "Cleaning ENAHO `yy'" 
			      }

				  
	** STEP 1: define tempfiles for all possible module names
	
    tempfile msum m100 m200 m300 m400 m500

    ** STEP 2: Load each module and merge. Code ensures variables exist in the data.
	
	use "${DATA}/raw_`yy'\enaho01-`yy'-200", clear // Module 200 stored by default.
	ren *, lower 
	loc keepvars_ok ""
	foreach v of global keepvars_m200 {
		capture confirm variable `v'
		if !_rc local keepvars_ok "`keepvars_ok' `v'"
	}
	global keepvars_m200 "`keepvars_ok'"
	keep conglome vivienda hogar codperso p204 p207 p208a p208a1 p209 p210 t211 p215 p216 ${keepvars_m200}  
	save "`m200'", replace
	
	foreach mod in 100 300 400 500{
	        use "${DATA}/raw_`yy'\enaho01-`yy'-`mod'", clear
			ren *, lower 
			loc keepvars_ok ""
			foreach v of global keepvars_m`mod' {
				capture confirm variable `v'
				if !_rc local keepvars_ok "`keepvars_ok' `v'"
			}
			global keepvars_`mod' "`keepvars_ok'"
			keep conglome vivienda hogar codperso p204 p207 p208a p208a1 p209 p210 t211 p215 p216 ${keepvars_m`mod'}  
			save "`m`mod''", replace					
	}
	
	if ${msum}==1 {	
				use "${DATA}/raw_`yy'\sumaria-`yy'", clear 
				ren *, lower 
				loc keepvars_ok ""
				foreach v of global keepvars_m`mod' {
					capture confirm variable `v'
					if !_rc local keepvars_ok "`keepvars_ok' `v'"
				}
				global keepvars_`mod' "`keepvars_ok'"
				keep conglome vivienda hogar linea  linpe percepho mieperho ${keepvars_msum}  
				save "`msum'", replace
	}
	
	** STEP 3: Merge modules using Module 200 as the master file
	
	use "`m200'", clear 
	merge 1:1 conglome vivienda hogar codperso using "`m300'", keep(1 3) nogen    
	merge 1:1 conglome vivienda hogar codperso using "`m400'", keep(1 3) nogen   
	merge 1:1 conglome vivienda hogar codperso using "`m500'", keep(1 3) nogen   
	merge 1:1 conglome vivienda hogar 		   using "`m100'", keep(1 3) nogen 
	merge 1:1 conglome vivienda hogar          using "`msum'", keep(1 3) nogen 
	
	cap drop year 
	gen int year = `yy'
	la var year "Year"
	order year, first
		
	compress
	save `enaho`yy'', replace 
	
}



********************************************************************************
**# 3) Guardar producto final
********************************************************************************


* Now we append the datasets we created for each year 
use `enaho${START_YEAR}', clear
loc i = ${START_YEAR}+1
forval j=`i'/$END_YEAR {
	append using `enaho`j'', nolab force
}

* Run cleaning do files
do "${CODE}/clean_mod200.do"

foreach mod in 100 300 400 500{
    if ${m`mod'} {
	    do "${CODE}/clean_mod`mod'.do"
	}
}

if ${msum} {
	do "${CODE}/clean_sumaria.do"
}

compress

* Store final dataset
save "${OUTFILE}", replace


if ${VERBOSE} {
	di as result "Final dataset has been saved successfully." 
	beep
}
