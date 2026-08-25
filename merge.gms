* -------------------------------------------------------------------------
*
*  Extract model indicators and save (and/or merge) in a CSV cube
*
* -------------------------------------------------------------------------

$setGlobal simType   CompStat
$setGlobal simName   %simName%
$setGlobal baseName  10x10
$setGlobal inDir     .
$setGlobal outDir    .
$setGlobal utility   cde
$setGlobal savfFlag  capFix
$setGlobal ifCal       0
$setGlobal ifSUB       1
$setGlobal MRIO        0

set
   t        "Time frame"   / base, check, shock /
   ts(t)    "Time flag"
;
alias(t,tsim) ;
singleton set t0(t)   "Base year" / base / ;
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
   ifCSV       "Flag for CSV file"                        / 1 /
   ifCSVAppend "Flag to append to existing CSV file"      / %ifCSVAppend% /
   ifMCP       "Set to 1 to solve using MCP"              / 1 /
   MRIO        "MRIO flag"                                / %MRIO% /
   ifAddLand   "Use ACES/ACET for land markets"           / 1 /
;

*  CSV results go to this file

file
   csv      / "%outDir%/%csvName%.csv" /
   screen   / con /
;

if(ifCSV,
   if(ifCSVAppend,
      csv.ap = 1 ;
      put csv ;
   else
      csv.ap = 0 ;
      put csv ;
      put "Variable,Region,Sector,Qualifier,Year,Value" / ;
   ) ;
   csv.pc=5 ;
   csv.nd=9 ;
) ;

* -------------------------------------------------------------------------
*
*  Retrieve GTAP sets, data and parameters
*
* -------------------------------------------------------------------------

$include "getData.gms"

* -------------------------------------------------------------------------
*
*  Load model, initialize variables and calibrate parameters
*
* -------------------------------------------------------------------------

*  Get the model specification

$include "model.gms"

*  Initialize the model

* $include "cal.gms"

set ra "Aggregate regions" /
   set.r
   "wld"
/ ;

set mapra(ra,r) "Mapping of regions" ;
mapra(ra,r)$(sameas(ra,r)) = yes ;
mapra("wld",r) = yes ;
alias(ra,rap) ;

set ia "Aggregate sectors" /
   set.i
   "tot"
/ ;

set mapia(ia,i) "Mapping of sectors" ;
mapia(ia,i)$(sameas(ia,i)) = yes ;
mapia("tot",i) = yes ;

set tr(t) "Reporting years" ;

loop(t$(ord(t) gt 1),
   if(not ifCSVAppend,
      if(ord(t) eq 2, tr(t) = yes ; ) ;
   ) ;
   if(ord(t) gt 2,
      tr(t) = yes ;
   ) ;
) ;

set sim / Base, %simName% / ;
set mapt(t,sim) /
   check.base
   shock.%simName%
/ ;

scalar val, vol ;

*  EV

execute_load "%simName%.gdx", ev, pg, yg, rsav, psave, ev0, pg0, yg0, rsav0 ;

loop((t,sim)$(tr(t) and mapt(t,sim)),
   loop(ra,
      put "EVP", ra.tl, "", "", sim.tl,
         (sum((r,h)$mapra(ra,r), ev0(r,h)*ev.l(r,h,t))/inscale) / ;
      put "EVG", ra.tl, "", "", sim.tl,
         (sum((r)$mapra(ra,r), pg.l(r,"check")*yg0(r)*yg.l(r,t)/pg.l(r,t))/inscale) / ;
      put "EVS", ra.tl, "", "", sim.tl,
         (sum((r)$mapra(ra,r), psave.l(r,"check")*rsav0(r)*rsav.l(r,t)/psave.l(r,t))/inscale) / ;
      PUT "EVT", ra.tl, "", "", sim.tl, (sum((r,h)$mapra(ra,r),
           ev0(r,h)*ev.l(r,h,t) + pg.l(r,"check")*yg0(r)*yg.l(r,t)/pg.l(r,t)
         + psave.l(r,"check")*rsav0(r)*rsav.l(r,t)/psave.l(r,t))/inscale) / ;
   ) ;
) ;

execute_load "%simName%.gdx", xw, pefob, pmcif, pm, xw0, pefob0, pmcif0, pm0 ;

$macro mXE(tp,tq) sum((s,i,d)$(mapra(ra,s) and mapia(ia,i)), \
      pefob0(s,i,d)*pefob.l(s,i,d,tp)*xw0(s,i,d)*xw.l(s,i,d,tq))
$macro mXM(tp,tq) sum((s,i,d)$(mapra(ra,d) and mapia(ia,i)), \
      pmcif.l(s,i,d,tp)*xw0(s,i,d)*xw.l(s,i,d,tq))

loop((t,sim)$(tr(t) and mapt(t,sim)),
   loop((ra,ia),
      put "XEX0P0", ra.tl, ia.tl, "", sim.tl, (mXE("check", "check")/inscale) / ;
      put "XEX1P0", ra.tl, ia.tl, "", sim.tl, (mXE("check", t)/inscale) / ;
      put "XEX1P1", ra.tl, ia.tl, "", sim.tl, (mXE(t, t)/inscale) / ;
      put "XEX0P1", ra.tl, ia.tl, "", sim.tl, (mXE(t, "check")/inscale) / ;
      put "XMX0P0", ra.tl, ia.tl, "", sim.tl, (mXM("check", "check")/inscale) / ;
      put "XMX1P0", ra.tl, ia.tl, "", sim.tl, (mXM("check", t)/inscale) / ;
      put "XMX1P1", ra.tl, ia.tl, "", sim.tl, (mXM(t, t)/inscale) / ;
      put "XMX0P1", ra.tl, ia.tl, "", sim.tl, (mXM(t, "check")/inscale) / ;
      PUT "PENDX", ra.tl, ia.tl, "", sim.tl,
         (sqrt((mXE(t,"Check")/mXE("Check","Check"))*(mXE(t,t)/mXE("Check",t)))) / ;
      PUT "PMNDX", ra.tl, ia.tl, "", sim.tl,
         (sqrt((mXM(t,"Check")/mXM("Check","Check"))*(mXM(t,t)/mXM("Check",t)))) / ;
      loop(rap,
         work = sum((s,i,d)$(mapra(ra,d) and mapia(ia,i) and mapra(rap,s)), xw0(s,i,d)*xw.l(s,i,d,t)) ;
         if(work ne 0,
            PUT "IMPTX", rap.tl, ia.tl, ra.tl, sim.tl,
               (sum((s,i,d)$(mapra(ra,d) and mapia(ia,i) and mapra(rap,s)),
                  (xw0(s,i,d)*pm0(s,i,d)/pmcif0(s,i,d))*(pm.l(s,i,d,t)/pmcif.l(s,i,d,t))*xw.l(s,i,d,t))
               /   work  - 1) / ;
         ) ;
      ) ;
   ) ;
) ;

execute_load "%simName%.gdx", savf, gdpmp, arent, rorc, rore, kstock,
                                    gdpmp0, arent0, rorc0, rore0, kstock0 ;

$macro mAggMacro0(var)        (sum(r$mapra(ra,r), var.l(r,t)))
$macro mAggMacro(var)         (sum(r$mapra(ra,r), &var&0(r)*var.l(r,t)))
$macro mWAggMacro(var,weight) (sum(r$mapra(ra,r), weight.l(r,t)*&var&0(r)*var.l(r,t)) \
                              /sum(r$mapra(ra,r), weight.l(r,t)))

loop((t,sim)$(tr(t) and mapt(t,sim)),
   loop(ra,
      put "savf",  ra.tl, "", "", sim.tl, (mAggMacro0(savf)/inscale) / ;
      put "gdpmp", ra.tl, "", "", sim.tl, (mAggMacro(gdpmp)/inscale) / ;
      put "arent", ra.tl, "", "", sim.tl, (mWAggMacro(arent, kstock)) / ;
      put "rorc",  ra.tl, "", "", sim.tl, (mWAggMacro(rorc, kstock)) / ;
      put "rore",  ra.tl, "", "", sim.tl, (mWAggMacro(rore, kstock)) / ;
   ) ;
) ;

execute_load "%simName%.gdx", xf, xft, pfy, pf, pft, xfFlag, xftFlag,
                              xf0, xft0, pfy0, pf0, pft0 ;

set tva /
   set.fp
   tlab
   tcap
   tlnd
   tva
/

set mapv(tva,fp) ;
mapv(tva,fp)$(sameas(tva,fp)) = yes ;
mapv("tlab",l) = yes ;
mapv("tcap",cap) = yes ;
mapv("tcap",lnd) = yes ;
mapv("tcap",nrs) = yes ;
mapv("tlnd",lnd) = yes ;
mapv("tva",fp) = yes ;

set aga /
   set.a
   tot
/ ;

set mapaa(aga,a) ;
mapaa(aga,a)$(sameas(aga,a)) = yes ;
mapaa("tot",a) = yes ;

$macro mPF(tp,tq)    sum((r,fp,a)$(mapra(ra,r) and mapv(tva,fp) and mapaa(aga,a)), \
      pf0(r,fp,a)*xf0(r,fp,a)*pf.l(r,fp,a,tp)*xf.l(r,fp,a,tq))

loop((t,sim)$(tr(t) and mapt(t,sim)),
   loop((ra,a,fp)$(fnm(fp)),
      work = sum((t0,r)$(mapra(ra,r) and xfFlag(r,fp,a)),
         pfy0(r,fp,a)*xf0(r,fp,a)*pfy.l(r,fp,a,t0)*xf.l(r,fp,a,t)) ;
      if(work, put "xf",  ra.tl, a.tl, fp.tl, sim.tl, (work/inscale) / ; ) ;
   ) ;
   loop((ra,fp)$(fm(fp)),
      work = sum((t0,r)$(mapra(ra,r) and xftFlag(r,fp)),
         pft0(r,fp)*xft0(r,fp)*pft.l(r,fp,t0)*xft.l(r,fp,t)) ;
      if(work, put "xft", ra.tl, "", fp.tl, sim.tl, (work/inscale) / ; ) ;
   ) ;
) ;

display mapv, mapaa ;

loop((t,sim)$(tr(t) and mapt(t,sim)),
   loop((ra,tva,aga),
      work = 0 ;
      work$mpf("Check","Check") =
         sqrt((mPF(t,"check")/mpf("Check","Check"))*(mpf(t,t)/mPF("Check",t))) ;
      if(work, put "PF", ra.tl, aga.tl, tva.tl, sim.tl, work / ; ) ;
   ) ;
) ;

*  XP

execute_load "%simName%.gdx", xp, px, vaLND, pvaLND, xp0, px0, vaLND0, pvaLND0 ;

loop((t,sim)$(tr(t) and mapt(t,sim)),
   loop((ra,aga),
      vol = sum((r,a)$(mapra(ra,r) and mapaa(aga,a)), xp.l(r,a,t)*xp0(r,a)*px0(r,a)) ;
      if(work,
         put "XP_N", ra.tl, aga.tl, "", sim.tl, (vol/inscale) / ;
      ) ;
      val = sum((r,a)$(mapra(ra,r) and mapaa(aga,a)), xp.l(r,a,t)*px.l(r,a,t)*xp0(r,a)*px0(r,a)) ;
      if(work,
         put "XP_D", ra.tl, aga.tl, "", sim.tl, (val/inscale) / ;
      ) ;
      vol = sum((r,a)$(mapra(ra,r) and mapaa(aga,a)), vaLND.l(r,a,t)*vaLND0(r,a)*pvaLND0(r,a)) ;
      if(work,
         put "VALND_N", ra.tl, aga.tl, "", sim.tl, (vol/inscale) / ;
      ) ;
      val = sum((r,a)$(mapra(ra,r) and mapaa(aga,a)), vaLND.l(r,a,t)*pvaLND.l(r,a,t)*vaLND0(r,a)*pvaLND0(r,a)) ;
      if(work,
         put "VALND_D", ra.tl, aga.tl, "", sim.tl, (val/inscale) / ;
      ) ;
   ) ;
) ;
