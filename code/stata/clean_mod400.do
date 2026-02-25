/*==========================================================================

                            ENAHO | PLANTILLAS DE LIMPIEZA

===========================================================================
Do-file:              clean_mod400.do
Módulo:               400 (Salud)
Propósito:            Limpiar/estandarizar estructura del módulo 400
                      (anti-basura estructural), lista para merges/builds
                      posteriores. NO FILTRA variables (sin keep).

Autor:                Vladimir Baños Calle
Creado:               19 Feb 2026
Última modificación:  24 Feb 2026

===========================================================================*/

clear
set more off
version 16.0

********************************************************************************
**# 0) Parámetros (MASTER-FIRST)
********************************************************************************
args Y RAW_BASE CLEAN_BASE OUTFILE

if ("`Y'"=="") | ("`RAW_BASE'"=="") | ("`CLEAN_BASE'"=="") | ("`OUTFILE'"=="") {
    di as error "clean_mod400.do (MASTER-FIRST) requiere 4 argumentos:"
    di as error "  do clean_mod400.do <Y> <RAW_BASE> <CLEAN_BASE> <OUTFILE>"
    exit 198
}

local YNUM = real("`Y'")
if missing(`YNUM') {
    di as error "Año inválido: `Y'"
    exit 198
}

********************************************************************************
**# 1) Rutas input
********************************************************************************
local INDIR  "`RAW_BASE'\raw_`YNUM'"
local INFILE "`INDIR'\enaho01a-`YNUM'-400.dta"

di as txt "=============================================================="
di as txt " MOD400 CLEAN | Año = `YNUM'"
di as txt " Input : `INFILE'"
di as txt " Output(tempfile): `OUTFILE'"
di as txt "--------------------------------------------------------------"

********************************************************************************
**# 2) Abrir base RAW
********************************************************************************
cap use "`INFILE'", clear
if _rc {
    di as error "No se encontró el archivo: `INFILE'"
    exit 601
}

di as txt "---- OK: Base abierta (RAW)"
describe, short

********************************************************************************
**# 3) Normalización mínima + estandarizar anio
********************************************************************************
rename *, lower

cap confirm variable anio
local HAS_ANIO = (_rc==0)

cap confirm variable año
local HAS_ANIO_N = (_rc==0)

cap confirm variable aÑo
local HAS_ANIO_N2 = (_rc==0)

if `HAS_ANIO_N2' {
    cap rename aÑo año
    local HAS_ANIO_N = 1
}

if (`HAS_ANIO'==0) & (`HAS_ANIO_N'==1) {
    rename año anio
    local HAS_ANIO = 1
    local HAS_ANIO_N = 0
}

if (`HAS_ANIO'==1) & (`HAS_ANIO_N'==1) {
    drop año
    local HAS_ANIO_N = 0
}

if (`HAS_ANIO'==0) {
    gen anio = `YNUM'
    local HAS_ANIO = 1
}

cap confirm numeric variable anio
if _rc {
    destring anio, replace force
}

replace anio = `YNUM'

di as txt "---- OK: nombres lower + anio=`YNUM' (sin duplicar año/anio)"

********************************************************************************
**# 4) Llaves (nivel persona) + armonizar codpers/codperso
********************************************************************************
cap confirm variable codperso
if _rc {
    cap confirm variable codpers
    if !_rc {
        rename codpers codperso
        di as txt "---- INFO: codpers -> codperso (armonización de llave)"
    }
}

local KEY "conglome vivienda hogar codperso"
local ok 1

foreach k of local KEY {
    cap confirm variable `k'
    if _rc {
        di as error "Falta llave obligatoria: `k'"
        local ok 0
        continue, break
    }
}
if `ok'==0 exit 459

cap isid `KEY'
if _rc {
    di as error "WARNING: La llave NO es única en mod400 `YNUM'. Revisar duplicados:"
    duplicates report `KEY'
    exit 459
}

di as txt "---- OK: Llaves presentes y únicas (`KEY')"

********************************************************************************
**# 5) Limpieza
********************************************************************************
local I4_VARS ///
    i401 i402 i403 i404 i405 i406 i407 i408 i409 i410 ///
    i411 i412 i413 i414 i415 i416 i417 i418 i419 i420

foreach v of local I4_VARS {
    cap confirm numeric variable `v'
    if !_rc {
        quietly replace `v' = . if inlist(`v', 9999, 99999, 999999, 9999999)
        quietly replace `v' = . if inlist(`v', 999999.9, 9999999.9, 999999.99, 9999999.99)
    }
}

local D4_VARS ///
    d401 d402 d403 d404 d405 d406 d407 d408 d409 d410 ///
    d411 d412 d413 d414 d415 d416 d417 d418 d419 d420

foreach v of local D4_VARS {
    cap confirm numeric variable `v'
    if !_rc {
        quietly replace `v' = . if inlist(`v', 9999, 99999, 999999, 9999999)
        quietly replace `v' = . if inlist(`v', 999999.9, 9999999.9, 999999.99, 9999999.99)
    }
}

local P4_MONEY ///
    p4011 p4012 p4013 p4014 ///
    p4021 p4022 p4023 p4024 ///
    p4031 p4032 p4033 p4034 ///
    p4041 p4042 p4043 p4044 ///
    p4051 p4052 p4053 p4054

foreach v of local P4_MONEY {
    cap confirm numeric variable `v'
    if !_rc {
        quietly replace `v' = . if inlist(`v', 9999, 99999, 999999, 9999999)
        quietly replace `v' = . if inlist(`v', 999999.9, 9999999.9, 999999.99, 9999999.99)
    }
}

di as txt "---- OK: limpieza mínima aplicada (listas explícitas i4/d4/p4_money si existían)"

********************************************************************************
**# 6) Compress
********************************************************************************
compress
di as txt "---- OK: compress aplicado. Obs=" _N " | Vars=" c(k)
describe, short

********************************************************************************
**# 7) Guardar output limpio (SOLO tempfile)
********************************************************************************
save "`OUTFILE'", replace
di as result "GUARDADO (tempfile): `OUTFILE'"

di as txt "================= FIN CLEAN MOD400 `YNUM' ================="