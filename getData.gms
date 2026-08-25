* ========================================================================================
*  PROJECT OVERRIDES — MERCOSUR2 / GTAP-LU
*
*  1. AEZ land-supply elasticities:
*       %outDir%/%BaseName%etaf_v1_country_aez.inc
*
*  2. GAEZ v5 climate land-productivity factors:
*       lndtfp(a,r,climscen) stored in %outDir%/%BaseName%Prm.gdx
*       and loaded here as gaezLndTfp(a,r,climscen).
*
*  3. Annual bilateral tariff paths:
*       Input/trade_tariffs_2019_2050_long.csv
*       Values are decimal ad-valorem tariff rates and are loaded here as
*       tradeTariff(s,i,d,tradecase,t).
*
*  The recursive launch files decide which tariff path and whether the GAEZ
*  productivity factor are applied in each simulation.
*
* ========================================================================================

* --------------------------------------------------------------------------------------------------
*
*     Read in the GTAP SETS
*
* --------------------------------------------------------------------------------------------------

sets
   acts           "Activities"
   comm           "Commodities"
   marg(comm)     "Margin commodities"
   reg            "Regions"
   endw           "Endowments"
   endwf(endw)    "Fixed factors"
   endwm(endw)    "Mobile factors"
   endws(endw)    "Sluggish factors"
;

$ifthen exist "%outDir%/%BaseName%Dat.gdx"
    $$gdxin "%outDir%/%BaseName%Dat.gdx"
    $$load acts, comm, reg, endw
    $$loaddc marg, endwf, endwm, endws
$else
    abort "No dat file found in %outDir%"
$endif

*  CREATE THE SAM SETS

set stdlab "Standard SAM labels" /
   TRD               "Trade account"
   regY              "Regional household"
   hhd               "Household"
   gov               "Government"
   inv               "Investment"
   deprY             "Depreciation"
   tmg               "Trade margins"
   itax              "Indirect tax"
   ptax              "Production tax"
   mtax              "Import tax"
   etax              "Export tax"
   vtax              "Taxes on factors of production"
   vsub              "Subsidies on factors of production"
   dtax              "Direct taxation"
   ctax              "Carbon tax"
   ntmY              "Non-tariff revenues"
   bop               "Balance of payments account"
   tot               "Total for row/column sums"
/ ;

set findem(stdlab) "Final demand accounts" /
   hhd               "Household"
   gov               "Government"
   inv               "Investment"
   tmg               "Trade margins"
/ ;

set is "SAM accounts for aggregated SAM" /

*  User-defined activities

   set.acts

*  User-defined commodities

   set.comm

*  User-defined factors

   set.endw

*  Standard SAM accounts

   set.stdlab

*  User-defined regions

   set.reg

/ ;

alias(is, js) ;

set aa(is) "Armington agents" /

   set.acts

   set.findem

/ ;

set a(aa) "Activities" /

   set.acts

/ ;

set i(is) "Commodities" /

   set.comm

/ ;
alias(i, j) ;

set r(is) "Regions" /

   set.reg

/ ;

alias(r,s) ; alias(r,d) ; alias(r,rp) ;


* --------------------------------------------------------------------------------------------------
*
*     Project scenario domains and annual tariff paths
*
* --------------------------------------------------------------------------------------------------

sets
   climscen        "GAEZ climate scenarios"
                   / SSP126, SSP370 /

   tradecase       "Trade-policy tariff path"
                   / baseline_no_cooperation
                     cooperation_eu_mercosur /

   tradeYear       "Years available in the tariff workbook"
                   / 2019*2050 /

   tradeMetric     "Columns imported from compact tariff CSV"
                   / tariff_rate, present /

   tradeTariffData(s,i,d,tradecase,t)                  "Cells explicitly supplied by the tariff workbook for model years"
;

parameters
   tradeTariffRaw(s,i,d,tradecase,tradeYear,tradeMetric)                    "Compact tariff CSV imported to GDX"

   tradeTariff(s,i,d,tradecase,t)                    "Annual bilateral tariff rate in decimal ad-valorem units"
;

*  Convert the canonical long tariff CSV to GDX. storeZero=y preserves explicit
*  zero tariffs as policy observations.
$call csv2gdx "Input\trade_tariffs_2019_2050_long.csv" output="Input\trade_tariffs_2019_2050_long.gdx" id=TRADETARIFFRAW index=1,2,3,4,5 values=6,7 useHeader=y storeZero=y
$if errorlevel 1 $abort "csv2gdx failed for Input/trade_tariffs_2019_2050_long.csv"

execute_loaddc "Input\trade_tariffs_2019_2050_long.gdx",
   tradeTariffRaw=TRADETARIFFRAW
;

*  Keep the source workbook through 2050, but expose only years contained in
*  the current model time set t.
tradeTariff(s,i,d,tradecase,t)
   = sum(tradeYear$sameas(tradeYear,t),
      tradeTariffRaw(s,i,d,tradecase,tradeYear,"tariff_rate")) ;

tradeTariffData(s,i,d,tradecase,t)
   = yes$sum(tradeYear$sameas(tradeYear,t),
      tradeTariffRaw(s,i,d,tradecase,tradeYear,"present")) ;

abort$(sum((s,i,d,tradecase,t)$tradeTariffData(s,i,d,tradecase,t),1) = 0)
   "No tariff observations loaded for the model time horizon" ;

abort$(smin((s,i,d,tradecase,t)$tradeTariffData(s,i,d,tradecase,t),
            tradeTariff(s,i,d,tradecase,t)) < 0)
   "Negative tariff rate found in tradeTariff" ;


set fp(is)  "Factors of production" /

   set.endw

/ ;

set fnm(fp) "Non-mobile factors" ;
loop((fp,endwf)$sameas(fp,endwf),
   fnm(fp) = yes ;
) ;

set fm(fp) "Mobile factors" ;
fm(fp)$(not fnm(fp)) = yes ;

sets
   l(fp)       "Labor"
   lnd(fp)     "Land endowment"
   imuv(i)     "MUV commodities"
   rmuv(r)     "MUV regions"
;
singleton set cap(fp) "Capital endowment" ;
singleton set nrs(fp) "Natural resource endowment" ;
singleton set rres(r) "Residual region" ;

$gdxin "%outDir%/%BaseName%Dat.gdx"
$loaddc l, cap, lnd, nrs, rres, imuv, rmuv

set fd(aa) "Domestic final demand agents" /

   set.findem

/ ;

set h(fd) "Households" /
   hhd               "Household"
/ ;

set gov(fd) "Government" /
   gov               "Government"
/ ;

set inv(fd) "Investment" /
   inv               "Investment"
/ ;

set fdc(fd) "Final demand accounts with CES expenditure function" /
   gov               "Government"
   inv               "Investment"
/ ;

set tmg(fd) "Domestic supply of trade margins services" /
   tmg               "Trade margins"
/ ;

alias(i0,i) ; alias(a0,a) ; alias(i,j) ; alias(j0,i0) ;

sets
   mapa0(a,a0)
   mapi0(i,i0)
;

*  No aggregation needed for this version of the model--so map a0 to a and i0 to i

mapa0(a,a) = yes ;
mapi0(i,i) = yes ;

* --------------------------------------------------------------------------------------------------
*
*     Read in the GTAP database
*
* --------------------------------------------------------------------------------------------------

parameters
   VDFB(i0, a0, r)      "Firm purchases of domestic goods at basic prices"
   VDFP(i0, a0, r)      "Firm purchases of domestic goods at purchaser prices"
   VMFB(i0, a0, r)      "Firm purchases of imported goods at basic prices"
   VMFP(i0, a0, r)      "Firm purchases of domestic goods at purchaser prices"
   VDPB(i0, r)          "Private purchases of domestic goods at basic prices"
   VDPP(i0, r)          "Private purchases of domestic goods at purchaser prices"
   VMPB(i0, r)          "Private purchases of imported goods at basic prices"
   VMPP(i0, r)          "Private purchases of domestic goods at purchaser prices"
   VDGB(i0, r)          "Government purchases of domestic goods at basic prices"
   VDGP(i0, r)          "Government purchases of domestic goods at purchaser prices"
   VMGB(i0, r)          "Government purchases of imported goods at basic prices"
   VMGP(i0, r)          "Government purchases of domestic goods at purchaser prices"
   VDIB(i0, r)          "Investment purchases of domestic goods at basic prices"
   VDIP(i0, r)          "Investment purchases of domestic goods at purchaser prices"
   VMIB(i0, r)          "Investment purchases of imported goods at basic prices"
   VMIP(i0, r)          "Investment purchases of domestic goods at purchaser prices"

   EVFB(fp, a0, r)      "Primary factor purchases at basic prices"
   EVFP(fp, a0, r)      "Primary factor purchases at purchaser prices"
   EVOS(fp, a0, r)      "Factor remuneration after income tax"

   VXSB(i0, r, rp)      "Exports at basic prices"
   VFOB(i0, r, rp)      "Exports at FOB prices"
   VCIF(i0, r, rp)      "Import at CIF prices"
   VMSB(i0, r, rp)      "Imports at basic prices"

   VST(i0, r)           "Exports of trade and transport services"
   VTWR(i0, j0, r, rp)  "Margins by margin commodity"

   SAVE(r)              "Net saving, by region"
   VDEP(r)              "Capital depreciation"
   VKB(r)               "Capital stock"
   POP0(r)              "Population"

   MAKS(i0,a0,r)        "Make matrix at supply prices"
   MAKB(i0,a0,r)        "Make matrix at basic prices (incl taxes)"
   PTAX(i0,a0,r)        "Output taxes"

   fbep(fp, a0, r)      "Factor subsidies"
   ftrv(fp, a0, r)      "Tax on factor use"
   tvom(a0,r)           "Value of output"

   check(a0,r)          "Check"
;

execute_load "%outDir%%BaseName%Dat.gdx",
   vdfb, vdfp, vmfb, vmfp,
   vdpb, vdpp, vmpb, vmpp,
   vdgb, vdgp, vmgb, vmgp,
   vdib, vdip, vmib, vmip,
   evfb, evfp, evos,
   vxsb, vfob, vcif, vmsb,
   vst, vtwr,
   save, vdep, vkb, pop0=pop,
   maks, makb

;


fbep(fp,a0,r) = 0 ;
ftrv(fp,a0,r) = evfp(fp,a0,r) - evfb(fp,a0,r) ;
ptax(i0,a0,r) = makb(i0,a0,r) - maks(i0,a0,r) ;
if(0,
   save(r)       = save(r) + vdep(r) ;
   vdep(r)       = 0 ;
) ;

* --------------------------------------------------------------------------------------------------
*
*     Read in CO2 emissions data
*
* --------------------------------------------------------------------------------------------------

Parameters
   mdf(i0, a0, r)          "CO2 emissions from domestic intermediate demand"
   mmf(i0, a0, r)          "CO2 emissions from domestic intermediate demand"
   mdp(i0, r)              "CO2 emissions from domestic private demand"
   mmp(i0, r)              "CO2 emissions from domestic private demand"
   mdg(i0, r)              "CO2 emissions from domestic public demand"
   mmg(i0, r)              "CO2 emissions from domestic public demand"
   mdi(i0, r)              "CO2 emissions from investment demand"
   mmi(i0, r)              "CO2 emissions from investment demand"
;

$ifthen exist "%outDir%%BaseName%Emiss.gdx"
   execute_load "%outDir%%BaseName%Emiss.gdx", mdf, mmf, mdp, mmp, mdg, mmg, mdi, mmi ;
$else
   mdf(i0,a0,r) = 0 ;
   mmf(i0,a0,r) = 0 ;
   mdp(i0,r)    = 0 ;
   mmp(i0,r)    = 0 ;
   mdg(i0,r)    = 0 ;
   mmg(i0,r)    = 0 ;
   mdi(i0,r)    = 0 ;
   mmi(i0,r)    = 0 ;
$endif

* --------------------------------------------------------------------------------------------------
*
*     Read in the MRIO data if requested
*
* --------------------------------------------------------------------------------------------------

set amrio "MRIO broad agents" /
   INT      "Aggregate intermediate demand"
   CONS     "Private and public demand"
   CGDS     "Investment demand"
/ ;

Parameters
   viuws(i0, amrio,s,d)       "Bilateral imports by broad agent at border prices"
   viums(i0, amrio,s,d)       "Bilateral imports by broad agent at post-tariff prices"
;

if(MRIO,
   $$ifthen exist "%outDir%%BaseName%MRIO.gdx"
      execute_loaddc "%outDir%%BaseName%MRIO.gdx", viums, viuws ;
   $$else
      put screen ; put / ;
      put "Requested MRIO version, but could not locate MRIO database" / ;
      put "Check for existence or set the MRIO flag to 0" / ;
      abort "No MRIO file" ;
   $$endif
else
   viuws(i0, amrio, s, d) = 0 ;
   viums(i0, amrio, s, d) = 0 ;
) ;

file csvmrio / mrio.csv / ;
if(0 and MRIO,
   put csvmrio ;
   put "Var,Comm,Agent,Source,Dest,Value" / ;
   csvmrio.pc=5 ;
   csvmrio.nd=9 ;
   loop((i,r),
      loop(amrio,
         if(sameas(amrio,"INT"),
            put "VMFB",  i.tl, amrio.tl, "Tot", r.tl, (sum(a, VMFB(i,a,r))) / ;
            put "VIUWS", i.tl, amrio.tl, "Tot", r.tl, (sum(s, viums(i,amrio,s,r))) / ;
         elseif(sameas(amrio,"CONS")),
            put "VMCB",  i.tl, amrio.tl, "Tot", r.tl, (VMPB(i,r)+VMGB(i,r)) / ;
            put "VIUWS", i.tl, amrio.tl, "Tot", r.tl, (sum(s, viums(i,amrio,s,r))) / ;
         elseif(sameas(amrio,"CGDS")),
            put "VMIB",  i.tl, amrio.tl, "Tot", r.tl, (VMIB(i,r)) / ;
            put "VIUWS", i.tl, amrio.tl, "Tot", r.tl, (sum(s, viums(i,amrio,s,r))) / ;
         ) ;
      ) ;
   ) ;
   abort "Temp" ;
) ;

* --------------------------------------------------------------------------------------------------
*
*     Read in the GTAP Parameters
*
* --------------------------------------------------------------------------------------------------

Parameter
   gaezLndTfp(a,r,climscen)       "Final GAEZ v5 land-productivity factor loaded from aggregate Prm.gdx"
;

Parameters
   esubt(a0,r)       "Top level CES substitution elasticity"
   esubc(a0,r)       "ND nest CES substitution elasticity"
   esubva(a0,r)      "VA nest CES substitution elasticity"
   esubkl(a0,r)      "K-L CES substitution elasticity"
   esublnd(a0,r)     "Cross-land CES substitution elasticity"

   etraq(a0,r)       "CET make elasticity"
   esubq(i0,r)       "CES make elasticity"

   incpar(i0,r)      "CDE expansion parameter"
   subpar(i0,r)      "CDE substitution parameter"

   esubg(r)          "CES government expenditure elasticity"
   esubi(r)          "CES investment expenditure elasticity"

   esubd(i0,r)       "Top level Armington elasticity"
   esubm(i0,r)       "Second level Armington elasticity"
   esubs(i0)         "CES margin elasticity"

   etrae(fp,r)       "CET elasticity for factors"
   rorFlex0(r)       "Flexibility of foreign capital"
;

execute_loaddc "%outDir%/%BaseName%Prm.gdx"
   esubt=esubt, esubc=esubc, esubva=esubva,
   esubkl=esubkl, esublnd=esublnd,
   etraq=etraq, esubq=esubq,
   incpar=incpar, subpar=subpar, esubg=esubg, esubi=esubi,
   esubd=esubd, esubm=esubm, esubs=esubs,
   etrae=etrae, rorFlex0=rorFlex,
   gaezLndTfp=lndtfp
   ;

abort$(smin((a,r,climscen), gaezLndTfp(a,r,climscen)) < 0)
   "Negative GAEZ land-productivity factor loaded from Prm.gdx",
   gaezLndTfp ;

* --------------------------------------------------------------------------------------------------
*
*     Declare and initialize the model parameters--overrides can be inserted before 'cal.gms'
*
* --------------------------------------------------------------------------------------------------

Parameters

*  Parameters normally sourced from GTAP

   sigmap(r,a)       "Top level CES production elasticity (ND/VA)"
   sigmand(r,a)      "CES elasticity across intermediate inputs"
   sigmav(r,a)       "CES elasticity across factors of production"

   sigmakl(r,a)      "CES elasticity between capital and labor (and NRS)"
   sigmalnd(r,a)     "CES elasticity across land types"

   omegas(r,a)       "Commodity supply CET elasticity"
   sigmas(r,i)       "Commodity supply CES elasticity"

   eh0(r,i)          "CDE expansion parameter"
   bh0(r,i)          "CDE substitution parameter"

   sigmag(r)         "CES government expenditure elasticity"
   sigmai(r)         "CES investment expenditure elasticity"

   sigmam(r,i,aa)    "Top level Armington elasticity"
   sigmaw(r,i)       "Second level Armington elasticity"
   sigmamg(i)        "CES expenditure elasticity for margin services exports"

   omegaf(r,fp)      "CET mobility elasticity for mobile factors"
   rorFlex(r,t)      "Flexibility of foreign capital"

*  Parameters in addition to standard GTAP model

   omegax(r,i)       "Top level output CET elasticity"
   omegaw(r,i)       "Second level export CET elasticity"

   etaf(r,fp)        "Aggregate factor supply elasticity"
   etaff(r,fp,a)     "Sector specific supply elasticity for non-mobile factors"

   mdtx0(r)          "Initial marginal tax rate"
   RoRFlag           "Capital account closure flag"

   sigmawa(r,i,aa)   "MRIO agent specific sourcing elasticity"
;

*  Overrides for GTAP-based parameters
*  If no overrides, parameters will be set in 'cal.gms'

sigmap(r,a)    = na ;
sigmand(r,a)   = na ;
sigmav(r,a)    = na ;
sigmakl(r,a)   = na ;
sigmalnd(r,a)  = na ;

*  !!!! Explicitly assumes that these are not aggregated

omegas(r,a)    = -etraq(a, r) ;
sigmas(r,i)    = inf$(esubq(i,r) eq 0)
               + (1/esubq(i,r))$(esubq(i,r) ne 0)
               ;

eh0(r,i)       = na ;
bh0(r,i)       = na ;

sigmag(r)      = na ;
sigmai(r)      = na ;

sigmam(r,i,aa) = na ;
sigmaw(r,i)    = na ;
sigmamg(i)     = na ;

loop(fm,
   loop(endwm,
      omegaf(r,fm)$sameas(endwm,fm) = inf ;
   ) ;
   loop(endws,
      omegaf(r,fm)$sameas(endws,fm) = na ;
   ) ;
) ;
rorFlex(r,t)   = rorFlex0(r) ;

*  Other initialization -- use default GTAP assumptions

omegax(r,i)     = inf ;
omegaw(r,i)     = inf ;

etaf(r,fm)      = 0 ;
etaff(r,fp,a)   = 0 ;

* --------------------------------------------------------------------------------------------------
*
*     Project-specific v1 AEZ land-supply elasticities
*
*     The external calibration overrides only the observed country x AEZ cells for:
*        Argentina, Bolivia, Brazil, Paraguay, Uruguay.
*
* --------------------------------------------------------------------------------------------------
$ontext
$ifthen exist "Input/etaf_v1_country_aez.inc"
   $$include "Input/etaf_v1_country_aez.inc"
$else
   $$abort "Missing calibrated etaf include file: Input/etaf_v1_country_aez.inc"
$endif

* Hard bounds check. The calibrated v1 specification is constrained to [0, 0.5].
abort$(smin((r,lnd), etaf(r,lnd)) < 0)
   "Negative AEZ land-supply elasticity found after loading etaf_v1_country_aez.inc",
   etaf ;

abort$(smax((r,lnd), etaf(r,lnd)) > 0.5)
   "AEZ land-supply elasticity above 0.5 found after loading etaf_v1_country_aez.inc",
   etaf ;
$offtext

$ifthen exist "%outDir%/%BaseName%etaf_v1_country_aez.inc" 
   $$include "%outDir%/%BaseName%etaf_v1_country_aez.inc"
$else
   $$abort "Missing calibrated etaf include file: %outDir%/%BaseName%etaf_v1_country_aez.inc"
$endif

* Hard bounds check. The calibrated v1 specification is constrained to [0, 0.5].
abort$(smin((r,lnd), etaf(r,lnd)) < 0)
   "Negative AEZ land-supply elasticity found after loading etaf_v1_country_aez.inc",
   etaf ;

abort$(smax((r,lnd), etaf(r,lnd)) > 0.5)
   "AEZ land-supply elasticity above 0.5 found after loading etaf_v1_country_aez.inc",
   etaf ;
*$offtext



mdtx0(r)        = na ;

sigmawa(r,i,aa) = na ;

