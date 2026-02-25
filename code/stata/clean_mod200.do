/*==========================================================================

                            ENAHO | CLEANING MODULE 200
							HOUSEHOLD MEMBER INFORMATION

===========================================================================

Authors:     Paúl Corcuera, Vladimir Baños Calle

===========================================================================*/

********************************************************************************
**# 1) Cleaning and Creating Variables
********************************************************************************

* Geographic Identifiers
cap drop id_dep 
gen id_dep = real(substr(ubigeo,1,2))
la var id_dep "ID Departamento"

cap drop id_prov
gen id_prov = real(substr(ubigeo,1,4))
la var id_prov "ID Provincia"

cap drop id_dist
gen id_prov = real(substr(ubigeo,1,4))
la var id_prov "ID Provincia"

* Age 
cap drop age 
clonevar age = p208a 
la var age "Age"

* Female
cap drop female 
clonevar female = p207
recode female (1=0) (2=1)
la var female "Female"
la def female 0 "Male" 1 "Female", modify 
la values female female




