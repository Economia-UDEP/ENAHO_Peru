/*==========================================================================

                            ENAHO | CLEANING MODULE 500
							EMPLOYMENT AND INCOME

===========================================================================

Authors:     Paúl Corcuera, Vladimir Baños Calle

===========================================================================*/


********************************************************************************
**#1 ) Cleaning and Creating Variables
********************************************************************************

*****************************
** Labor Force Participation based on Ministry of Labor
*****************************

* Self-employed defined by the Ministry of Labor
d p5041-p50411
cap drop any504 
gen byte any504 = 1 if p5041==1 | p5042==1 | p5043==1 | p5044==1 | p5045==1 | p5046==1 | p5047==1 | p5048==1 | p5049==1 | p50410==1 | p50411==1 

cap drop all504
gen byte all504 = 1 if p5041==2 & p5042==2 & p5043==2 & p5044==2 & p5045==2 & p5046==2 & p5047==2 & p5048==2 & p5049==2 & p50410==2 & p50411==2 

* Labor force: Employed (1), Unemployed (2), Inactive (3) 
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
 
la define condact 1 "Employed" 2 "Unemployed" 3 "Inactive", modify
la values condact condact


*****************************
** WAGE INCOME  
*****************************



*****************************
** SELFEMPLOYMENT INCOME  
*****************************
