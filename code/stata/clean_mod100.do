/*==========================================================================

                            ENAHO | PLANTILLAS DE LIMPIEZA

===========================================================================
Do-file:              clean_mod100.do
Módulo:               100 (Características de la Vivienda y del Hogar)
Propósito:            Limpiar/estandarizar estructura del módulo 100
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
**# 0) Parámetros
********************************************************************************
args Y RAW_BASE CLEAN_BASE OUTFILE

if ("`Y'"=="") | ("`RAW_BASE'"=="") | ("`CLEAN_BASE'"=="") | ("`OUTFILE'"=="") {
    di as error "clean_mod100.do (MASTER-FIRST) requiere 4 argumentos:"
    di as error "  do clean_mod100.do <Y> <RAW_BASE> <CLEAN_BASE> <OUTFILE>"
    exit 198
}

local YNUM = real("`Y'")
if missing(`YNUM') {
    di as error "Año inválido: `Y'"
    exit 198
}

********************************************************************************
**# 1) Rutas RAW
********************************************************************************
local INDIR  "`RAW_BASE'\raw_`YNUM'"
local INFILE "`INDIR'\enaho01-`YNUM'-100.dta"

di as txt "=============================================================="
di as txt " MOD100 CLEAN | Año = `YNUM'"
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
**# 3) Normalización mínima + estandarizar
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
**# 4) Chequeos llaves (nivel hogar)
********************************************************************************
local KEY "conglome vivienda hogar"

foreach k of local KEY {
    cap confirm variable `k'
    if _rc {
        di as error "Falta llave obligatoria: `k'"
        exit 459
    }
}

cap isid `KEY'
if _rc {
    di as error "WARNING: llave no única en mod100 `YNUM'"
    duplicates report `KEY'
    exit 459
}

di as txt "---- OK: Llaves presentes y únicas (`KEY')"

********************************************************************************
**# 5) Limpieza mínima segura
********************************************************************************
local MONEY_VARS ///
    p106 p106a p106b p106c ///
    p107 p107a p107b p107c ///
    p108 p108a p108b p108c ///
    p109 p109a p109b p109c ///
    p110 p110a p110b p110c

foreach v of local MONEY_VARS {
    cap confirm numeric variable `v'
    if !_rc {
        quietly replace `v' = . if inlist(`v', 99999, 999999, 9999999)
        quietly replace `v' = . if inlist(`v', 999999.9, 9999999.9, 999999.99, 9999999.99)
    }
}

di as txt "---- OK: Limpieza mínima aplicada (monetarias si existían)"

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

di as txt "================= FIN CLEAN MOD100 `YNUM' ================="