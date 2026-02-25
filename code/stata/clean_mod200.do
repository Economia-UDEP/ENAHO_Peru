/*==========================================================================

                            ENAHO | PLANTILLAS DE LIMPIEZA

===========================================================================
Do-file:              clean_mod200.do
Módulo:               200 (Características de los miembros del hogar)
Propósito:            Limpiar/estandarizar estructura del módulo 200
                      (anti-basura estructural), lista para merges/builds
                      posteriores. NO FILTRA variables (sin keep).

Autor:                Vladimir Baños Calle
Creado:               19 Feb 2026
Última modificación:  23 Feb 2026

===========================================================================*/

clear
set more off
version 16.0

********************************************************************************
**# 0) Parámetros
********************************************************************************
args Y RAW_BASE CLEAN_BASE OUTFILE

if ("`Y'"=="") | ("`RAW_BASE'"=="") | ("`CLEAN_BASE'"=="") | ("`OUTFILE'"=="") {
    di as error "clean_mod200.do (MASTER-FIRST) requiere 4 argumentos:"
    di as error "  do clean_mod200.do <Y> <RAW_BASE> <CLEAN_BASE> <OUTFILE>"
    exit 198
}

local YNUM = real("`Y'")
if missing(`YNUM') {
    di as error "Año inválido: `Y'"
    exit 198
}

********************************************************************************
**# 1) Construcción de rutas de input
********************************************************************************
local INDIR  "`RAW_BASE'\raw_`YNUM'"
local INFILE "`INDIR'\enaho01-`YNUM'-200.dta"

di as txt "=============================================================="
di as txt " MOD200 CLEAN | Año = `YNUM'"
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
**# 4) Chequeos básicos de llaves (nivel persona)
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
    di as error "WARNING: La llave NO es única en mod200 `YNUM'. Revisar duplicados:"
    duplicates report `KEY'
    exit 459
}

di as txt "---- OK: Llaves presentes y únicas (`KEY')"

********************************************************************************
**# 5) Limpieza selectiva por variable
********************************************************************************
* Edad: p208a (99 = missing)
cap confirm numeric variable p208a
if !_rc quietly replace p208a = . if p208a==99

* Variable presente en años recientes: p211a (99 = missing)
cap confirm numeric variable p211a
if !_rc quietly replace p211a = . if p211a==99

* Horas: p211d (999 = missing)
cap confirm numeric variable p211d
if !_rc quietly replace p211d = . if p211d==999

di as txt "---- OK: Limpieza mínima selectiva aplicada (p208a/p211a/p211d si existían)"

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

di as txt "================= FIN CLEAN MOD200 `YNUM' ================="