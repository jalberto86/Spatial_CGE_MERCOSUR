* ========================================================================================
*  SCENARIO: SSP370 / TC
*  tradeShock=1; climateShock=1; climScen=SSP370
* ========================================================================================

* 
* -------------------------------------------------------------------------
*
*  Standard model diagnostics
*
*  Model preamble -- user options
*
* -------------------------------------------------------------------------

$setGlobal simType   Rdyn 
$setGlobal simName  SSP370_TC
$setGlobal baseName  GTAPF11AEZ_Mercosur2
$setGlobal outDir    "C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\outdir\"
$setGlobal output    "C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\output\" 
$setGlobal utility   cd
$setGlobal savfFlag  capFlex
$setGlobal ifCal       0
$setGlobal ifSUB       0
$setGlobal MRIO        0
$setGlobal tradeShock    1
$setGlobal climateShock  1
$setGlobal climScen       SSP370


set
   t             "Time frame"                         / 2017*2040 /
   ts(t)         "Time flag"
   tClimate(t)   "GAEZ climate-shock application"     / 2021*2040 /
;
alias(t,tsim) ;
singleton set t0(t)   "Base year" / 2017 / ;
singleton set tLag(t) "Lagged time period" ;
tLag(t0) = yes ;

Parameter
   years(t)
   gap(t)
   FirstYear
;

years(t)  = ord(t) ;
gap(t)    = 1 ;
FirstYear = years(t0) ;

ts(t) = no ;

scalar
   ifSUB       "Set to 1 to reduce model size"            / %ifSUB% /
   ifCal       "Set to 1 to calibrate dynamically"        / %ifCal% /
   $$iftheni "%simType%" == "CompStat"
      ifDyn       "Set to 1 to for a dynamic scenario"    / 0 /
   $$else
      ifDyn       "Set to 1 to for a dynamic scenario"    / 1 /
   $$endif
   ifDebug     "Set to 1 to debug calibration"            / 0 /
   inScale     "Scale for input data"                     / 1e-6 / 
   ifCSV       "Flag for CSV file"                        / 0 /
   ifCSVAppend "Flag to append to existing CSV file"      / 0 /
   ifMCP       "Set to 1 to solve using MCP"              / 0 /
   MRIO         "MRIO flag"                                / %MRIO% /
   ifAddLand    "Use ACES/ACET for land markets"           / 1 /
   tradeShock   "0=baseline tariffs, 1=EU-Mercosur path"   / %tradeShock% /
   climateShock "0=no GAEZ shock, 1=apply GAEZ factor"     / %climateShock% /
*   ifSP         "Set to 1 to include Spillover effects"    / %ifSP% /   
;

*  CSV results go to this file

file
   csv      / "%output%/%simName%.csv" /
   screen   / con /
;

if(ifCSV,
   if(ifCSVAppend,
      csv.ap = 1 ;
      put csv ;
   else
      csv.ap = 0 ;
      put csv ;
      put "META,simName,%simName%" / ;
      put "META,simType,%simType%" / ;
      put "META,utility,%utility%" / ;
      put "META,savfFlag,%savfFlag%" / ;
      put "META,ifCal,%ifCal%" / ;
      put "META,ifSUB,%ifSUB%" / ;
      put "META,MRIO,%MRIO%" / ;
      put "META,tradeShock,%tradeShock%" / ;
      put "META,climateShock,%climateShock%" / ;
      put "META,climScen,%climScen%" / ;
      put "META,runCase,TC" / ;
      put / ;
      put "Variable,Region,Sector,Qualifier,Year,Value" / ;
   ) ;
   csv.pc=5 ;
   csv.nd=9 ;
) ;

*  This file is optional--sometimes useful to debug model

file debug / "%output%/%simName%DBG.csv" / ;
if(ifDebug,
   put debug ;
   put "Var,Region,Sector,Qual,Year,Value" / ;
   debug.pc=5 ;
   debug.nd=9 ;
) ;

* -------------------------------------------------------------------------
*
*  Retrieve GTAP sets, data and parameters
*
* -------------------------------------------------------------------------

$include "getData.gms"

* -------------------------------------------------------------------------
*
*  Parameter overrides, for example factor supply elasticities,
*     output transformation elasticities
*
* -------------------------------------------------------------------------


* -------------------------------------------------------------------------
*
*  Load model, initialize variables and calibrate parameters
*
* -------------------------------------------------------------------------

*  Get the model specification

$include "model.gms"

*  Initialize the model

$include "cal.gms"

* -------------------------------------------------------------------------
*
*  Load model, initialize variables and calibrate parameters
*
* -------------------------------------------------------------------------


etaff(r,fp,a)$nrs(fp) = 0.4 ;
etaf(r,l)  = 0.2;

* FIX for dynCal. Target: 1% per-cap GDP growth from the year after t0 onward
*ggdppc.fx(r,t)$(years(t) > FirstYear) = 0.01 ;


*piadd(r,l,a,t) = 0 ;
pimlt(r,l,a,t) = 1 ;

* initialize and bound afeall correctly. If DynGtap is used, afeall should be FIXED. If DynCal is used, afeall should free but bounded since it's solved in afealleq.
afeall.fx(r,fp,a,t) = 0 ;
*afeall.fx(r,fp,a,t) = 0.015 ;
*afeall.fx(r,l,a,t) = 0.015 ;
*afeall.fx(dcr,l,a,t) = 0.03 ;
*afeall.fx(ndcr,l,a,t) = 0.01 ;
*afeall.l(r,l,a,t)$(years(t) > FirstYear) = 0;
*afeall.lo(r,l,a,t)$(years(t) > FirstYear) = -0.9;
*afeall.up(r,l,a,t)$(years(t) > FirstYear) =  0.9;

* For DynCal, gl. should be free but bounded. In DynGtap, gl. is not used.
gl.l(r,t) = 0 ;
*gl.l(r,t)$(years(t) > FirstYear) = 0.001 ;
*gl.lo(r,t) = -0.3 ;
*gl.up(r,t) =  0.3 ;

lndtfp.fx(r,a,t)$(years(t) > FirstYear) = 1;

* avoid power-domain issues
lambdaf.lo(r,fp,a,t) = 1e-6 ;

*$exit
* -------------------------------------------------------------------------
*
*  Run the simulations for each time period
*
* -------------------------------------------------------------------------

rs(r) = yes ;
ts(t) = no ;

loop(tsim,

   ts(tsim) = yes ;

   $$include "iterloop.gms"

*  SSP population path: update population and labor AFT using the
*  same annual exogenous population growth factor.
   $$include "calibration/output/inc/ssp3_population_2018_2040.inc"

*  ----------------------------------------------------------------------
*  Scenario-specific shocks
*
*  Tariff path is always applied:
*     tradeShock = 0 -> baseline_no_cooperation
*     tradeShock = 1 -> cooperation_eu_mercosur
*  ----------------------------------------------------------------------
   $$include "policies/trade_eu_mercosur.gms"

*  GAEZ climate productivity.
*  Baseline through 2020; selected FP2140 factor applied for 2021-2040.
   if(climateShock,
      lndtfp.fx(r,a,tsim)$tClimate(tsim)
         = gaezLndTfp(a,r,"%climScen%") ;
   );

   options limrow = 300, limcol = 300, solprint = off, iterlim = 100000 ;

   if(years(tsim) gt firstYear,

      $$iftheni.solve "%simType%" == "CompStat"

         $$batinclude "solve.gms" gtap

      $$else.solve

         $$ifthen.calStatus %ifCal% == 1

            $$batinclude "solve.gms" dynCal

         $$else.calStatus

            $$batinclude "solve.gms" dynGTAP

         $$endif.calStatus

      $$endif.solve
   ) ;

   display walras.l, imptx.l ;
   put screen ;
   put / ;
   put "Walras: ", (walras.l(tsim)/inScale) / ;
   putclose screen ;

*   if(sameas(tsim,'2019'),
*      $$batinclude "createGDX.gms" 1 DEBUGDat.gdx
*   else
*      $$batinclude "createGDX.gms" 0
*   ) ;

   ts(tsim) = no ;
) ;

$include "postsim.gms"
execute_unload "%output%%simName%.gdx" ;
