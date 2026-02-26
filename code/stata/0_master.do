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


** REQUIRED PACKAGES
foreach cmd in ftools moremata{
    cap which `cmd'
    if (_rc) {
        di as result "Installing command: `cmd'"
        ssc install `cmd', replace
    }
}


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
global RUN_PYSCRIPT 0 // <--- 0: don't run Python script, 1: run Python script


/// TODO ADD THIS FUNCTIONALITY 
* Set up whether you want to store cleaned files by year
global SAVE_YEARLY 0   // <--- 0: don't store intermediate yearly files, 1: store

* Verbose mode 
global VERBOSE 1 // <--- 0: no messages, 1: messages along the way

********************************************************************************
**# 0.1) Set up modules and variables to keep (empty lists are allowed)
********************************************************************************
/// TODO: ONLY TESTED IF YOU INCLUDE ALL MODULES SO FAR. CHECK WHAT NEEDS TO CHANGE ONCE WE ALLOW FOR MIXED MODULES.

* Módulo 100: Dwelling and Household Information 
global m100 = 1  // <--- 0: exclude, 1: include
global keepvars_m100 ///
	"ubigeo dominio estrato codccpp nomccpp longitud latitud altitud"

* Módulo 200: Household Members Characteristics 
global m200 = 1  // <--- 0: exclude, 1: include. Current version always stores this.
global keepvars_m200 ///
	"p204 p207 p208a p208a1 p209 p210 t211 p215 p216 " ///
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
    "p506 p506r4 p507 p510 p510a1 p512a p512b p513a1 p513a2 p514 p517 p519 p523 p524a1 p524e1 p538a1 p538e1 p530a p541a " ///
    "p545 p546 p547 p548 p549 p550 " ///
    "p550_1 p550_2 p550_3 p550_4 p550_5 p550_6 p550_7 " ///
    "p5566a p599 ocu500 ocupinf emplpsec fac500a " ///
	"i513t i518 i520 i530a i524a1 i524b1 i524c1 i524d1 i524e1 i538a1 i538b1 i538c1 i538d1 i538e1 i5294b i5404b i541a"

* Módulo Sumaria: Summary (Constructed) Variables by INEI
global msum = 1 // <--- 0: exclude, 1: include
global keepvars_msum ///
	"anio ubigeo dominio estrato mieperho percepho linpe pobreza percepho mieperho  "

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
**# 2) Informality measures not constructed for years 2024+. Fix the raw file.
********************************************************************************

use "${DATA}/raw_2024\enaho01a-2024-500", clear 
merge 1:1 conglome vivienda hogar codperso using "${DATA}/raw_2024\enaho01a-2024-400.dta", keepusing (p419*) keep(1 3) nogen
do "${CODE_AUX}/informality_construction_INEI.do"
save, replace 


********************************************************************************
**# 3) Loop over years 
********************************************************************************


* We set tempfile names for each year 
forvalues j = $START_YEAR / $END_YEAR {
    tempfile enaho`j'
}

* Next, we run the loop
forvalues yy = $START_YEAR / $END_YEAR {

    if ${VERBOSE} di as txt "Cleaning ENAHO `yy'"

    ** STEP 1: define tempfiles for all possible module names
    tempfile msum m100 m200 m300 m400 m500

    * Keys
    local key_hh   "conglome vivienda hogar"
    local key_pers "`key_hh' codperso"

    ** STEP 2: Load each module and save cleaned tempfiles

    * -----------------
    * Module 200 (master)
    * -----------------
    use "${DATA}/raw_`yy'\enaho01-`yy'-200", clear

    local keepvars_m200 ""
    foreach v of global keepvars_m200 {
        capture confirm variable `v'
        if !_rc local keepvars_m200 "`keepvars_m200' `v'"
    }

    keep `key_pers' `keepvars_m200'
    * optional integrity check (will error if duplicates)
    isid `key_pers'
    qui save "`m200'", replace

    * -----------------
    * Modules 100, 300, 400, 500
    * -----------------
    foreach mod in 100 300 400 500 {

        if `mod'==100 {
            use "${DATA}/raw_`yy'\enaho01-`yy'-`mod'", clear
        }
        else {
            use "${DATA}/raw_`yy'\enaho01a-`yy'-`mod'", clear
        }

        * IMPORTANT: store in local keepvars_m`mod' (consistent with later `keep`)
        local keepvars_m`mod' ""
        foreach v of global keepvars_m`mod' {
            capture confirm variable `v'
            if !_rc local keepvars_m`mod' "`keepvars_m`mod'' `v'"
        }

        if `mod'==100 {
            keep `key_hh' `keepvars_m`mod''
            isid `key_hh'
        }
        else {
            keep `key_pers' `keepvars_m`mod''
            isid `key_pers'
        }

        qui save "`m`mod''", replace
    }

    * -----------------
    * Sumaria (optional)
    * -----------------
    if ${msum}==1 {
        use "${DATA}/raw_`yy'\sumaria-`yy'", clear

        local keepvars_msum ""
        foreach v of global keepvars_msum {
            capture confirm variable `v'
            if !_rc local keepvars_msum "`keepvars_msum' `v'"
        }

        keep `key_hh' `keepvars_msum'
        isid `key_hh'
        qui save "`msum'", replace
    }

    ** STEP 3: Merge modules using Module 200 as the master file
    use "`m200'", clear
    merge 1:1 `key_pers' using "`m300'", keep(1 3) nogen nolabel
    merge 1:1 `key_pers' using "`m400'", keep(1 3) nogen nolabel
    merge 1:1 `key_pers' using "`m500'", keep(1 3) nogen nolabel
    merge m:1 `key_hh'   using "`m100'", keep(1 3) nogen nolabel

    if ${msum}==1 {
        merge m:1 `key_hh' using "`msum'", keep(1 3) nogen nolabel
    }

    cap drop year
    qui gen int year = `yy'
    qui label var year "Year"
    qui order year, first

    qui compress
    qui save `enaho`yy'', replace
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

* Run cleaning do file
qui do "${CODE_STATA}/1_clean_enaho.do"


compress

* Store final dataset
save "${OUTFILE}", replace


if ${VERBOSE} {
	di as result "Final dataset has been saved successfully." 
	beep
}
