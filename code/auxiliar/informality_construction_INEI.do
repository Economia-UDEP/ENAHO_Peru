
*========================================================================================
*=============== ocupación principal===============
*========================================================================================
*variables de población residente.
gen pob_res_prin = ((p204 == 1 & p205 == 2) | (p204 == 2 & p206 == 1)) & ocu500 == 1 
label define pob_res_prin 1 "personal ocupado residente op"
label val pob_res_prin pob_res_prin

*creando variable agricultura silvicultura y pesca (CIIU rev.4)*.
recode p506r4 (111/990=1)(1000/max=2) if ocu500==1, gen(a_rev4_p)
label var a_rev4_p "agricultura silvicultura y pesca rev4 principal"
label define a_rev4_p 1"agropecuario" 2"no agropecuario"
label val a_rev4_p a_rev4_p
 
*construyendo tamaño de empresa para calcular cuasisociedades.
recode p512b(1/5=1)(6/10=2)(11/30=3)(31/9998 =4)(9999=9)(.=9) if(ocu500 == 1), gen (num_trab_op)
label var num_trab_op "número de trabajadores principal"
label define  num_trab_op 1"de 01 a 05 personas" 2"de 06 a 10 personas" 3"de 11 a 30 personas" 4"de 31 a más personas" 9"nep"
label val num_trab_op num_trab_op

************adicionado para ajustar diferencia*********************
*recodificando a los missing (9) para llegar al total, repartiéndolos según tamaño implícito.
recode num_trab_op  (nonmissing=1)(missing=1) if (p507 == 2 & ocu500 == 1)
recode num_trab_op  (nonmissing=1)(missing=1) if (p507 == 6 & ocu500 == 1)
recode num_trab_op  (9=4) if ( p512a > 2 & p512a < 6 & ocu500 == 1)
recode num_trab_op  (9=4)if (p510 < 4 & ocu500 == 1)

*-------------------------------------.
*indentificando a los trabajadores que pertenecen al sector institucional de los hogares según scn.
*observación: sólo pasan a la p510 los empleados, obreros y otros.
recode p510(1=1)(2=1)(3=1)(5=9)(6=9)(7=9)(.=9) if (ocu500== 1), gen (hogar_op)
label var hogar_op "unidad productiva donde trabaja en su ocupación principal"
label define hogar_op 1"sociedades y otros" 0"sector hogar"

recode hogar_op (missing=9)  if (ocu500 == 1)
 
*jurídicos son sociedades.
recode hogar_op (9=1) if p510a1 == 1 & ocu500==1

*no jurídicos son hogares.
recode hogar_op (9=0) if (p510a1 > 1 & ocu500==1)
 
*trabajadores del hogar pertenecen al sector hogares  (no pasan por la p510a1 ni p510b)
recode hogar_op (nonmissing=0) (missing=0) if p507 == 6  & ocu500==1

*corrección eliminando cuasisociedades
recode hogar_op (nonmissing=1) (missing=1) if (a_rev4_p==2 & hogar_op==0 & num_trab_op > 3  & ocu500==1)

*tfnr juridicos pasarlos a hogares porque en cuentas nacionales (cn) no hay tfnr en sociedades
recode hogar_op(nonmissing=0)(missing=0)if (hogar_op == 1 & (p507==5 | p507 ==7)  & ocu500==1)

*-----------------------------------------------------------------------------.
*actividades de gobierno que aparecen en sector hogares, se pasan a sociedades.
recode p506r4 (8411=50001)(8412=50001)(8413=50001)(8421=50001)(8422=50001)(8423=50001)(8430=50001), gen (nivelp)								

*actividades de gobierno a formales.
recode hogar_op  (nonmissing=1)(missing=1) if (nivelp == 50001 & ocu500==1)

*adiciono en dncn correccion pasa a sociedades
recode hogar_op (0=1) if (p507 ==7 & p510==2 & ocu500==1)



*========================================================================================.
*===============////////////////////// ocupación principal ===============.
*========================================================================================.
*--------------------------------------------------------------------------.
****                  sector informal (unidades productivas), ocupación principal.
*-------------------------------------------------------------------------------------------.

**defnicion operativa.
*unidades productivas informales (upi): son aquellas dirigidas por trabajadores independientes y patronos, no están constituidas en sociedad y no están registradas en sunat.
*los empleados, obreros y otros, trabajan en una upi si esta empresa es una no constituida en sociedad que no tiene libros o sistema de constabilidad.
*los tfrn trabajan en una upi si esta empresa tiene un tamaño mayor o igual a 5 trabajadores.
*los trabajadores del hogar, se han dejado en el sector formal, sin embargo se precisa que según la xv ciet se incluyen en el sector informal, pero según la xvii se excluyen del sector informal.
*el resto de po pertenece al sector formal: sociedades, gobierno y empresas de hogares formales. 

*========= trabajadores independientes , patronos , asalariados y tfnr =========.

*sector formal si es que es sociedad. 
gen sector_oit_p=1 if (hogar_op ==1) 
replace sector_oit_p=3 if  (p507 == 6)
recode sector_oit_p (missing=9)if (ocu500== 1)

*sector informal para hogares agropecuarios y pesca (sección a rev. 4)
replace sector_oit_p=2 if  (sector_oit_p==9 & hogar_op == 0 & a_rev4_p==1)
label var sector_oit_p "sector según oit (ocupación principal)"
label define sector_oit_p 1"sector formal" 2"sector informal" 3"hogar con servicio doméstico"
label val sector_oit_p sector_oit_p 

*actividades no agrícolas son formales cuando son jurídicas y/o están registradas en sunat.
replace sector_oit_p=1 if  (sector_oit_p==9 & p510a1 <= 2 )
replace sector_oit_p=2 if  (sector_oit_p==9 & p510a1 == 3)

*========= trabajadores familiares no remunerados =========.
*los tfrn, trabajan en una empresa informal si esta empresa tiene un tamaño mayor o igual a 5 trabajadores.
recode sector_oit_p  (1=2)  if ((p507 ==5 | p507 ==7) & (p512b < 6))


*--------------------------------------------------------------------------------------------------------------------.
****                         empleo informal (ocupación principal).
*--------------------------------------------------------------------------------------------------------------------.

*construimos la variable categoría de empleos según oit.
recode p507 (2=1) (1=2) (5=3) (7=3) (3=4) (4=4) (6=4) if (ocu500==1) ,gen (cat_ocup_oit_p)  
label var cat_ocup_oit_p "categoría de empleo (ocup. principal)"
label define cat_ocup_oit_p 1"trabajadores por cuenta propia" 2"empleadores" 3"trabajadores familiares auxiliares" 4"asalariados"

*construyendo la variable de informalidad del trabajador.
***informalidad del asalariado.
* redefinimos propiedades de variables p419.

gen seguro_empleador=2 if  ((p419a1 == 1 | p419a2 == 1 | p419a3 == 1 | p419a4 == 1 | p419a5 == 1 | p419a8 == 1) & ocu500==1)
label var seguro_empleador "tiene seguro (cualquiera) pagado por el empleador"
label define seguro_empleador 1"no" 2"sí"

recode seguro_empleador (missing=1)if (ocu500== 1)

*si el empleador le paga algún seguro, entonces es formal.
gen informal_p=seguro_empleador if  (cat_ocup_oit_p == 4)
label var  informal_p "situación de informalidad (ocup.principal)"
label define informal_p 1"empleo informal" 2"empleo formal" 
label val informal_p informal_p

***informalidad del tfnr.
recode informal_p (nonmissing=1)(missing=1) if (cat_ocup_oit_p == 3)

***informalidad de empleadores.
recode informal_p (nonmissing=2)(missing=2)if (cat_ocup_oit_p == 2 & sector_oit_p == 1)

***informalidad de empleadores.
recode informal_p (nonmissing=1)(missing=1)if (cat_ocup_oit_p == 2 & sector_oit_p == 2)

***informalidad de trab por cuenta propia.
recode informal_p (nonmissing=2)(missing=2)if (cat_ocup_oit_p == 1 & sector_oit_p == 1)

***informalidad de trab por cuenta propia.
recode informal_p (nonmissing=1)(missing=1)if (cat_ocup_oit_p == 1 & sector_oit_p == 2)

*corrección de informales asalariados (asalariados formales en sector informal se consideran informales). 
recode informal_p (nonmissing=1)(missing=1) if (cat_ocup_oit_p == 4 & sector_oit_p == 2)

*empleo en el sector informal y fuera del sector informal.
gen emplensi_p=1 if  (informal_p == 1 & sector_oit_p == 2)
replace emplensi_p=2 if  (informal_p == 1 & (sector_oit_p == 1 | sector_oit_p == 3))
label var emplensi_p "empleo informal dentro y fuera del sector informal (ocup. principal)"
label define emplensi_p 1"empleo informal en el sector informal" 2"empleo informal fuera del sector informal" 
label val emplensi_p  emplensi_p

rename emplensi_p  emplpsec
rename informal_p  ocupinf

gen sector_p=2 if  ocupinf == 2
replace sector_p=emplpsec if  sector_p==.

drop nivelp a_rev4_p num_trab_op hogar_op sector_oit_p cat_ocup_oit_p seguro_empleador pob_res_prin sector_p p419*

order i518 i513t i520 i530a i524a1 i524b1 i524c1 i524d1 i524e1 i538a1 i538b1 i538c1 i538d1 i538e1 i5294b i5404b i541a ocu500, last
order ocupinf emplpsec, last
order fac500*, last

label define ocupinf 1"Empleo Informal" 2"Empleo formal", modify 
label val ocupinf ocupinf 


*------------------------
*TABULADOS **************
*------------------------
tab a*o ocupinf [iw=fac500a] if((p204==1 & p205==2)|(p204==2 & p206==1)) & ocu500==1, row nofreq  //residentes ocupados

