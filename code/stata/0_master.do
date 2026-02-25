/*==========================================================================

                            ENAHO | MASTER DO-FILE

===========================================================================
Do-file:              0_master.do
Objective:            Construir la base final ENAHO 2007–2024 (MASTER-FIRST):
                      limpia módulos por año (solo estructural),
                      aplica KEEP por módulo (ÚNICOS keeps del pipeline),
                      construye HOGAR/PERSONA, integra mod500 y acumula años.

Authors:                Vladimir Baños Calle, Paúl Corcuera.

===========================================================================*/

clear*
set more off
version 16.0

********************************************************************************
**# 0) Parameter Customization
********************************************************************************
local START_YEAR 2007
local END_YEAR   2024

global RAW   "C:\Users\vladi\Desktop\ENAHO_RAW"
global CLEAN "C:\Users\vladi\Desktop\ENAHO_CLEAN"
global DO    "C:\Users\vladi\Desktop\dofile"

global OUTDIR "C:\Users\vladi\Desktop\ENAHO_BUILD"
cap mkdir "$OUTDIR"
local OUTFILE "$OUTDIR\enaho_build_`START_YEAR'_`END_YEAR'.dta"

local SAVE_YEARLY 0

* Vars que cambian de tipo entre años (ya detectadas)
local FORCE_STRING_VARS "p301a1o p201p"

********************************************************************************
**# 0.1) Especificaciones KEEP
********************************************************************************
local ID_HOGAR   "conglome vivienda hogar anio"
local ID_PERSONA "conglome vivienda hogar codperso anio"

local KEEP_SUMARIA ///
    `ID_HOGAR' ubigeo dominio estrato mieperho percepho linpe pobreza inghog1d gashog1d

local KEEP_100 ///
    `ID_HOGAR' ubigeo dominio estrato p101 p102 p103 p104 p105

local KEEP_200 ///
    `ID_PERSONA' ubigeo dominio estrato p204 p205 p206 p207 p208a

local KEEP_300 ///
    `ID_PERSONA' ubigeo dominio estrato p301 p301a p302 p303 p304 t313

local KEEP_400 ///
    `ID_PERSONA' ubigeo dominio estrato p401 p401a p402 p402a t401 t402

local KEEP_500 ///
    `ID_PERSONA' ubigeo dominio estrato p500a p500b p501 p502 p503 p513a p524a

********************************************************************************
**# 0.2) Auto-fix mismatch de tipos para APPEND
********************************************************************************
capture program drop __append_fix_types
program define __append_fix_types
    args MASTER_DTA USING_DTA

    preserve
        use "`MASTER_DTA'", clear
        ds
        local M_ALL `r(varlist)'
        foreach v of local M_ALL {
            local M_isstr_`v' = 0
            capture confirm string variable `v'
            if !_rc local M_isstr_`v' = 1
        }
    restore

    preserve
        use "`USING_DTA'", clear
        ds
        local U_ALL `r(varlist)'
        foreach v of local U_ALL {
            local U_isstr_`v' = 0
            capture confirm string variable `v'
            if !_rc local U_isstr_`v' = 1
        }
    restore

    local BOTH : list M_ALL & U_ALL

    local TOFIX ""
    foreach v of local BOTH {
        if (`M_isstr_`v''==1 & `U_isstr_`v''==0) local TOFIX `TOFIX' `v'
        if (`M_isstr_`v''==0 & `U_isstr_`v''==1) local TOFIX `TOFIX' `v'
    }
    local TOFIX : list uniq TOFIX
    if "`TOFIX'"=="" exit

    di as error "---- APPEND TYPE-FIX: tostring (master+using) para:"
    di as error "     `TOFIX'"

    preserve
        use "`MASTER_DTA'", clear
        foreach v of local TOFIX {
            capture confirm variable `v'
            if !_rc capture tostring `v', replace force
        }
        save "`MASTER_DTA'", replace
    restore

    preserve
        use "`USING_DTA'", clear
        foreach v of local TOFIX {
            capture confirm variable `v'
            if !_rc capture tostring `v', replace force
        }
        save "`USING_DTA'", replace
    restore
end

********************************************************************************
**# 0.3) SAFE KEEP
********************************************************************************
capture program drop __safe_keep
program define __safe_keep
    args DTA
    macro shift
    local WANTLIST `"`*'"'

    use "`DTA'", clear

    local KEEP ""
    foreach v of local WANTLIST {
        capture confirm variable `v'
        if !_rc local KEEP "`KEEP' `v'"
    }
    local KEEP : list uniq KEEP

    if "`KEEP'"=="" {
        di as error "SAFE_KEEP quedó vacío para: `DTA'"
        exit 459
    }

    keep `KEEP'
    compress
    save "`DTA'", replace
end

********************************************************************************
**# 1) Tempfile acumulado
********************************************************************************
tempfile FINAL_ACCUM
local HAVE_FINAL 0

********************************************************************************
**# 2) Loop por año
********************************************************************************
forvalues Y = `START_YEAR'/`END_YEAR' {

    di as txt "=============================================================="
    di as txt " MASTER BUILD | Año = `Y'"
    di as txt "=============================================================="

    tempfile msum m100 m200 m300 m400 m500

    * 2.1) CLEANs
    cap noisily do "$DO\clean_sumaria.do" `Y' "$RAW" "$CLEAN" "`msum'"
    if _rc {
        di as error ">> FALLÓ clean_sumaria `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily do "$DO\clean_mod100.do"  `Y' "$RAW" "$CLEAN" "`m100'"
    if _rc {
        di as error ">> FALLÓ clean_mod100 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily do "$DO\clean_mod200.do"  `Y' "$RAW" "$CLEAN" "`m200'"
    if _rc {
        di as error ">> FALLÓ clean_mod200 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily do "$DO\clean_mod300.do"  `Y' "$RAW" "$CLEAN" "`m300'"
    if _rc {
        di as error ">> FALLÓ clean_mod300 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily do "$DO\clean_mod400.do"  `Y' "$RAW" "$CLEAN" "`m400'"
    if _rc {
        di as error ">> FALLÓ clean_mod400 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily do "$DO\clean_mod500.do"  `Y' "$RAW" "$CLEAN" "`m500'"
    if _rc {
        di as error ">> FALLÓ clean_mod500 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    * 2.2) MASTER-KEEPS
    cap noisily __safe_keep "`msum'" `KEEP_SUMARIA'
    if _rc {
        di as error ">> FALLÓ SAFE_KEEP SUMARIA `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily __safe_keep "`m100'" `KEEP_100'
    if _rc {
        di as error ">> FALLÓ SAFE_KEEP MOD100 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily __safe_keep "`m200'" `KEEP_200'
    if _rc {
        di as error ">> FALLÓ SAFE_KEEP MOD200 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily __safe_keep "`m300'" `KEEP_300'
    if _rc {
        di as error ">> FALLÓ SAFE_KEEP MOD300 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily __safe_keep "`m400'" `KEEP_400'
    if _rc {
        di as error ">> FALLÓ SAFE_KEEP MOD400 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    cap noisily __safe_keep "`m500'" `KEEP_500'
    if _rc {
        di as error ">> FALLÓ SAFE_KEEP MOD500 `Y' (rc=`_rc'). Se salta año."
        continue
    }

    * 2.3) MERGE ANUAL
    tempfile YEAR_MERGED HOGAR PERSONA

    * (A) HOGAR = sumaria + mod100 (1:1)
    use "`msum'", clear
    cap isid conglome vivienda hogar
    if _rc {
        di as error "SUMARIA no es única por hogar en `Y'. Se salta año."
        continue
    }

    preserve
        use "`m100'", clear
        cap isid conglome vivienda hogar
        if _rc {
            di as error "MOD100 no es único por hogar en `Y'. Diagnóstico:"
            duplicates report conglome vivienda hogar

            duplicates tag conglome vivienda hogar, gen(dup)
            keep if dup
            cap save "$OUTDIR\debug_dup_mod100_`Y'.dta", replace

            restore
            continue
        }
    restore

    merge 1:1 conglome vivienda hogar using "`m100'", nogen
    di as txt "---- OK: HOGAR = SUMARIA + MOD100 (`Y')"
    compress
    save "`HOGAR'", replace

    * (B) PERSONA = mod200 + mod300 + mod400 (1:1 por persona)
    use "`m200'", clear
    cap isid conglome vivienda hogar codperso
    if _rc {
        di as error "MOD200 no es único por persona en `Y'. Se salta año."
        continue
    }

    merge 1:1 conglome vivienda hogar codperso using "`m300'"
    tab _merge
    drop if _merge==2
    drop _merge
    di as txt "---- OK: PERSONA + MOD300 (`Y')"
    compress

    merge 1:1 conglome vivienda hogar codperso using "`m400'"
    tab _merge
    drop if _merge==2
    drop _merge
    di as txt "---- OK: PERSONA + MOD400 (`Y')"
    compress

    * (C) MOD500 1:m
    merge 1:m conglome vivienda hogar codperso using "`m500'"
    tab _merge
    drop if _merge==2
    drop _merge
    di as txt "---- OK: PERSONA 1:m + MOD500 (`Y')"
    compress

    save "`PERSONA'", replace

    * (D) FINAL = PERSONA m:1 HOGAR
    use "`PERSONA'", clear
    merge m:1 conglome vivienda hogar using "`HOGAR'"
    tab _merge
    drop if _merge==2
    drop _merge
    di as result "---- OK: MERGE ANUAL FINAL (PERSONA m:1 HOGAR) `Y'"
    compress

    * [ORDER FIX] IDs primero (incluye anio)
    capture order anio conglome vivienda hogar codperso ubigeo dominio estrato, first

    * 2.4) Fix strings antes de guardar el año
    foreach v of local FORCE_STRING_VARS {
        cap confirm variable `v'
        if !_rc {
            cap confirm numeric variable `v'
            if !_rc tostring `v', replace force
        }
    }

    cap confirm variable anio
    if _rc {
        di as error "ERROR: faltó anio en el merge final del año `Y' (no se puede append)."
        exit 459
    }

    compress
    save "`YEAR_MERGED'", replace

    if (`SAVE_YEARLY'==1) {
        local yfile "$OUTDIR\year_`Y'_merged.dta"
        save "`yfile'", replace
    }

    * 2.5) APPEND acumulado
    if (`HAVE_FINAL'==0) {
        use "`YEAR_MERGED'", clear
        compress
        save "`FINAL_ACCUM'", replace
        local HAVE_FINAL 1
        di as result "OK `Y' -> inicializa acumulado."
    }
    else {
        __append_fix_types "`FINAL_ACCUM'" "`YEAR_MERGED'"

        use "`FINAL_ACCUM'", clear
        foreach v of local FORCE_STRING_VARS {
            cap confirm variable `v'
            if !_rc {
                cap confirm numeric variable `v'
                if !_rc tostring `v', replace force
            }
        }
        compress
        save "`FINAL_ACCUM'", replace

        use "`YEAR_MERGED'", clear
        foreach v of local FORCE_STRING_VARS {
            cap confirm variable `v'
            if !_rc {
                cap confirm numeric variable `v'
                if !_rc tostring `v', replace force
            }
        }
        compress
        save "`YEAR_MERGED'", replace

        use "`FINAL_ACCUM'", clear
        append using "`YEAR_MERGED'"
        compress

        * [ORDER FIX] también en el acumulado
        capture order anio conglome vivienda hogar codperso ubigeo dominio estrato, first

        save "`FINAL_ACCUM'", replace
        di as result "OK `Y' -> append acumulado."
    }
}

********************************************************************************
**# 3) Guardar producto final
********************************************************************************
if (`HAVE_FINAL'==0) {
    di as error "No se generó ningún año. Revisa inputs / dofiles."
    exit 459
}

use "`FINAL_ACCUM'", clear
compress

* [ORDER FIX] asegurar orden en output final
capture order anio conglome vivienda hogar codperso ubigeo dominio estrato, first

save "`OUTFILE'", replace

di as txt "=============================================================="
di as result "FINAL GUARDADO: `OUTFILE'"
di as txt "=============================================================="