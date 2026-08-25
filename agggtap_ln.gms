* ========================================================================================
*  GTAP 11 / GTAP-LULC AEZ aggregation for the MERCOSUR deforestation project
*
*  File       : agggtap.gms
*  Purpose    : Aggregate a hybrid GTAP 11 + GTAP-LULC (AEZ) database for the
*               recursive-dynamic GTAP-LU model used in the coupled SAR/CGE project.
*
*  Project WD : C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn
*  Updated    : 2026-08-11
*
*  SOURCE ARCHITECTURE (locked after the pre-aggregation audits)
*
*    Standard GTAP 11 DAT : Input/GSDF11DAT.GDX
*       -> ordinary GTAP SAM / trade / demand / make / macroeconomic accounts
*
*    GTAP-LULC AEZ DAT    : Input/GDX11cAEZ17/GSDFDAT.GDX
*       -> ENDW is loaded by the mapping file
*       -> EVFB, EVFP, EVOS, FBEP, FTRV are loaded here as one coherent
*          reconstructed factor-account block
*
*    Standard GTAP 11 PAR : Input/GSDF11PAR.GDX
*       -> source parameters actually aggregated in this file:
*          ESUBT, ESUBC, ESUBVA, INCPAR, SUBPAR, ESUBD, ESUBM, RORFLEX
*
*    GTAP-LULC AEZ PAR    : Input/GDX11cAEZ17/GSDFPAR.GDX
*       -> AEZS and ESUBAEZ
*       -> ETFA, ETPC and ETCR are intentionally NOT used. They belong to the
*          classic multi-tier AEZ land-supply CET structure, which is not the
*          land-supply specification used by this model.
*
*    Standard VOLE/EMISS  : Input/GSDF11VOLE.GDX and Input/GSDF11EMISS.GDX
*       -> unchanged
*
*  IMPORTANT MODEL CHOICES
*
*    1. AEZ1...AEZ18 are separate source and aggregate land endowments.
*    2. The mapping supplies ETRAE1(fp,r) directly (mobile labour/capital,
*       sluggish AEZ land, sector-specific natural resources). Standard GTAP
*       ETRAE(ENDW,REG) is therefore not loaded.
*    3. ESUBLND1(a,r) is aggregated from official ESUBAEZ(ACTS,REG), weighted
*       by source AEZ-land expenditure at purchasers' prices (EVFP).
*    4. ESUBKL1(a,r) remains tied to ESUBVA1(a,r), as in the existing GTAP-LU
*       implementation, because the AEZ parameter package has no separate
*       non-land substitution parameter.
*
*  VALIDATION HISTORY
*
*    - Standard and AEZ EVFB/EVFP/EVOS are NOT identical.
*    - AEZ land rents do not simply sum to standard GTAP Land.
*    - Non-land EV values are also reconstructed.
*    - Total EVFP is essentially conserved after the land/non-land reallocation.
*    -> Decision: use the AEZ factor-payment block coherently rather than splice
*       standard non-land payments with AEZ land payments.
*
*  RUN GATE
*
*    This file is written for the corrected GTAP 11 MercosurMap.gms.
*    Do NOT run the aggregation with the superseded provisional mapping.
*
* ========================================================================================

$oneolcom

* ----------------------------------------------------------------------------------------
*  User / project options
* ----------------------------------------------------------------------------------------

$setGlobal outDir "C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\outdir\"
$setGlobal gtpDir   "Input"
$setGlobal GTAPBASE "GSDF11"
$setGlobal AEZDir   "Input/GDX11cAEZ17"
$setGlobal Aggregation "Mercosur2"
$setGlobal BaseNameF "GTAPF11AEZ_"

* ----------------------------------------------------------------------------------------
*  GAEZ climate-productivity integration
*
*  The finalized source REG x AEZ x crop-activity climate factors are read from
*  Input\gaez_lndtfp_reg_aez_v2.csv. They are aggregated with the locked
*  Mercosur2Map mappings and 2017 GTAP-LULC AEZ-land EVFP weights.
*
*  The final parameter lndtfp(a,r,climscen) is written into the standard
*  aggregate Prm.gdx. Dat.gdx, Emiss.gdx and Vole.gdx are otherwise unchanged.
* ----------------------------------------------------------------------------------------

$setGlobal GAEZCSV "Input\gaez_lndtfp_reg_aez_v2.csv"
$setGlobal GAEZGDX "Input\gaez_lndtfp_reg_aez_v2.gdx"


set DREL / v11C_2017_2025 / ;

acronyms none, har, gdx, both ;
scalar cleanup / none / ;

* ----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------


*  Define the aggregation macros. Here v0 is the dissag parameter. v is the final aggregation

$macro AGG1(v0,v,x0,x,mapx)                     v(x)     = sum(x0$mapx(x0,x), v0(x0))
$macro AGG2(v0,v,x0,x,mapx,y0,y,mapy)           v(x,y)   = sum((x0,y0)$(mapx(x0,x) and mapy(y0,y)), v0(x0,y0))
$macro AGG3(v0,v,x0,x,mapx,y0,y,mapy,z0,z,mapz) v(x,y,z) = sum((x0,y0,z0)$(mapx(x0,x) and mapy(y0,y) and mapz(z0,z)), v0(x0,y0,z0))
$macro AGG4(v0,v,x0,x,mapx,y0,y,mapy,z0,z,mapz,w0,w,mapw) v(x,y,z,w) = sum((x0,y0,z0,w0)$(mapx(x0,x) and mapy(y0,y) and mapz(z0,z) and mapw(w0,w)), v0(x0,y0,z0,w0))

*  Load the aggregation mappings

$include "%Aggregation%Map.gms"
*execute_unload  "test.gdx"
*$exit
* put  "FS = ", "%system.filesys%" / ;

$set OPSYS
$If %system.filesys% == UNIX     $set OPSYS "UNIX"
$If %system.filesys% == DOS      $set OPSYS "DOS"
$If %system.filesys% == "MSNT"   $set OPSYS "DOS"
$If "%OPSYS%." == "." Abort "filesys not recognized" ;

$set console
$iftheni "%OPSYS%" == "UNIX"
   $$set console /dev/tty
$elseifi "%OPSYS%" == "DOS"
   $$set console con
$else
   Abort "Unknown operating system" ;
$endif

file screen / '%console%' /;

put screen ;
put / ;

* ------------------------------------------------------------------------------
*
*  Validate the aggregations
*
* ------------------------------------------------------------------------------

parameters
   r0Flag(r0)
   rFlag(r)
   a0Flag(a0)
   aFlag(a)
   i0Flag(i0)
   iFlag(i)
   fpFlag(fp)
   fp0Flag(endw)
   total
   work
   ifFirstPass    / 1 /
   ifCheck        / 1 /
   ifFirst        / 1 /
   order          / 0 /
;

r0Flag(r0) = sum(mapr(r0,r), 1) ;
loop(r0,
   if(r0Flag(r0) ne 1,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following GTAP region(s) have not been mapped:" / ;
      ) ;
      put r0.tl:<10, "     ", r0.te(r0) / ;
   ) ;
) ;

put screen ; put / ;

ifFirst = 1 ;
rFlag(r) = sum(mapr(r0,r), 1) ;
loop(r,
   if(rFlag(r) eq 0,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following aggregate region(s) have no GTAP regions mapped to them:" / ;
      ) ;
      put r.tl:<10, "     ", r.te(r) / ;
   ) ;
) ;

ifFirst = 1 ;

i0Flag(i0) = sum(mapi(i0,i), 1) ;
loop(i0,
   if(i0Flag(i0) ne 1,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following GTAP sector(s) have not been mapped:" / ;
      ) ;
      put i0.tl:<10, "     ", i0.te(i0) / ;
   ) ;
) ;

put screen ; put / ;

ifFirst = 1 ;
iFlag(i) = sum(mapi(i0,i), 1) ;
loop(i,
   if(iFlag(i) eq 0,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following aggregate sector(s) have no GTAP sectors mapped to them:" / ;
      ) ;
      put i.tl:<10, "     ", i.te(i) / ;
   ) ;
) ;

ifFirst = 1 ;

a0Flag(a0) = sum(mapa(a0,a), 1) ;
loop(a0,
   if(a0Flag(a0) ne 1,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following GTAP activity (ies) have not been mapped:" / ;
      ) ;
      put a0.tl:<10, "     ", a0.te(a0) / ;
   ) ;
) ;

put screen ; put / ;

ifFirst = 1 ;
aFlag(a) = sum(mapa(a0,a), 1) ;
loop(a,
   if(aFlag(a) eq 0,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following aggregate activity(ies) have no GTAP sectors mapped to them:" / ;
      ) ;
      put a.tl:<10, "     ", a.te(a) / ;
   ) ;
) ;

fp0Flag(endw) = sum(mapf(endw,fp), 1) ;
loop(endw,
   if(fp0Flag(endw) lt 1,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following GTAP factor(s) have not been mapped:" / ;
      ) ;
      put endw.tl:<10, "     ", endw.te(endw) / ;
   ) ;
) ;

put screen ; put / ;

ifFirst = 1 ;
fpFlag(fp) = sum(mapf(endw,fp), 1) ;
loop(fp,
   if(fpFlag(fp) eq 0,
      put screen ;
      if(ifFirst eq 1,
         ifFirst = 0 ;
         ifCheck = 0 ;
         put "The following aggregate factor(s) have no GTAP factors mapped to them:" / ;
      ) ;
      put fp.tl:<10, "     ", fp.te(fp) / ;
   ) ;
) ;



put screen ; put / ;

abort$(ifCheck eq 0) "Invalid mapping file" ;

put screen ;
put "All mappings have passed standard checks..." / / ;

putclose screen ;

* ------------------------------------------------------------------------------
*
*  Aggregate the GTAP data
*
* ------------------------------------------------------------------------------

parameters

*  From the standard database

   VDFB(COMM, ACTS, REG)            "Firm purchases of domestic goods at basic prices"
   VDFP(COMM, ACTS, REG)            "Firm purchases of domestic goods at purchaser prices"
   VMFB(COMM, ACTS, REG)            "Firm purchases of imported goods at basic prices"
   VMFP(COMM, ACTS, REG)            "Firm purchases of domestic goods at purchaser prices"
   VDPB(COMM, REG)                  "Private purchases of domestic goods at basic prices"
   VDPP(COMM, REG)                  "Private purchases of domestic goods at purchaser prices"
   VMPB(COMM, REG)                  "Private purchases of imported goods at basic prices"
   VMPP(COMM, REG)                  "Private purchases of domestic goods at purchaser prices"
   VDGB(COMM, REG)                  "Government purchases of domestic goods at basic prices"
   VDGP(COMM, REG)                  "Government purchases of domestic goods at purchaser prices"
   VMGB(COMM, REG)                  "Government purchases of imported goods at basic prices"
   VMGP(COMM, REG)                  "Government purchases of domestic goods at purchaser prices"
   VDIB(COMM, REG)                  "Investment purchases of domestic goods at basic prices"
   VDIP(COMM, REG)                  "Investment purchases of domestic goods at purchaser prices"
   VMIB(COMM, REG)                  "Investment purchases of imported goods at basic prices"
   VMIP(COMM, REG)                  "Investment purchases of domestic goods at purchaser prices"

   EVFB(ENDW, ACTS, REG)            "Primary factor purchases at basic prices"
   EVFP(ENDW, ACTS, REG)            "Primary factor purchases at purchaser prices"
   EVOS(ENDW, ACTS, REG)            "Factor remuneration after income tax"

   VXSB(COMM, REG, REG)             "Exports at basic prices"
   VFOB(COMM, REG, REG)             "Exports at FOB prices"
   VCIF(COMM, REG, REG)             "Import at CIF prices"
   VMSB(COMM, REG, REG)             "Imports at basic prices"

   VST(MARG, REG)                   "Exports of trade and transport services"
   VTWR(MARG, COMM, REG, REG)       "Margins by margin commodity"

   SAVE(REG)                        "Net saving, by region"
   VDEP(REG)                        "Capital depreciation"
   VKB(REG)                         "Capital stock"
   POP(REG)                         "Population"
   MAKS(COMM,ACTS,REG)              "Make matrix at supply prices" 
   MAKB(COMM,ACTS,REG)              "Make matrix at basic prices (incl taxes)"
   PTAX(COMM,ACTS,REG)              "Output taxes"

   FBEP(endw,acts,reg)              "Factor-based subsidies"             
   FTRV(endw,acts,reg)              "Gross factor employment tax revenue"

*  Auxiliary data

   VOA(ACTS, REG)                   "Value of output pre-tax"
;

* ----------------------------------------------------------------------------------------
*  Load the hybrid GTAP 11 / GTAP-LULC data block
*
*  Standard GTAP 11 provides the ordinary SAM/trade/macro accounts.
*  The GTAP-LULC AEZ DAT replaces the complete factor-payment/tax block used here.
* ----------------------------------------------------------------------------------------

execute_loaddc "%gtpDir%/%GTAPBASE%DAT.gdx",
   vdfb, vdfp, vmfb, vmfp,
   vdpb, vdpp, vmpb, vmpp,
   vdgb, vdgp, vmgb, vmgp,
   vdib, vdip, vmib, vmip,
   vxsb, vfob, vcif, vmsb,
   vst, vtwr,
   save, vdep, vkb, pop,
   maks, makb, ptax
;

execute_loaddc "%AEZDir%/GSDFDAT.gdx",
   evfb, evfp, evos,
   FBEP, FTRV
;

voa(acts,reg) = sum(comm, maks(comm,acts,reg)) ;

parameter
   gdpmp(reg)
;

alias(reg,dst) ; alias(reg,src) ;

* ----------------------------------------------------------------------------------------
*
*  Declare the aggregated parameters
*
* ----------------------------------------------------------------------------------------

alias(r,rp) ; alias(r,s) ; alias(r,d) ; alias(img,i) ; alias(a,a1) ;
alias(reg,src) ; alias(reg,dst) ;

parameters
   VDFB1(i, a, r)             "Firm purchases of domestic goods at basic prices"
   VDFP1(i, a, r)             "Firm purchases of domestic goods at purchaser prices"
   VMFB1(i, a, r)             "Firm purchases of imported goods at basic prices"
   VMFP1(i, a, r)             "Firm purchases of domestic goods at purchaser prices"
   VDPB1(i, r)                "Private purchases of domestic goods at basic prices"
   VDPP1(i, r)                "Private purchases of domestic goods at purchaser prices"
   VMPB1(i, r)                "Private purchases of imported goods at basic prices"
   VMPP1(i, r)                "Private purchases of domestic goods at purchaser prices"
   VDGB1(i, r)                "Government purchases of domestic goods at basic prices"
   VDGP1(i, r)                "Government purchases of domestic goods at purchaser prices"
   VMGB1(i, r)                "Government purchases of imported goods at basic prices"
   VMGP1(i, r)                "Government purchases of domestic goods at purchaser prices"
   VDIB1(i, r)                "Investment purchases of domestic goods at basic prices"
   VDIP1(i, r)                "Investment purchases of domestic goods at purchaser prices"
   VMIB1(i, r)                "Investment purchases of imported goods at basic prices"
   VMIP1(i, r)                "Investment purchases of domestic goods at purchaser prices"

   EVFB1(fp, a, r)            "Primary factor purchases at basic prices"
   EVFP1(fp, a, r)            "Primary factor purchases at purchaser prices"
   EVOS1(fp, a, r)            "Factor remuneration after income tax"

   VXSB1(i, r, r)             "Exports at basic prices"
   VFOB1(i, r, r)             "Exports at FOB prices"
   VCIF1(i, r, r)             "Import at CIF prices"
   VMSB1(i, r, r)             "Imports at basic prices"

   VST1(img, r)               "Exports of trade and transport services"
   VTWR1(img, i, r, r)        "Margins by margin commodity"

   SAVE1(r)                   "Net saving, by region"
   VDEP1(r)                   "Capital depreciation"
   VKB1(r)                    "Capital stock"
   POP1(r)                    "Population"
   
   MAKS1(i,a,r)                 "Make matrix at supply prices"
   MAKB1(i,a,r)               "Make matrix at basic prices (incl taxes)"
   PTAX1(i,a,r)               "Output taxes"
   FBEP1(fp, a, r)            "Factor-based subsidies"                 
   FTRV1(fp, a, r)            "Gross factor employment tax revenue"
   
*  Auxiliary data
   voa1(a,r)                  "Value of output pre-tax"
   voi1(i,r)                  "Value of supply post-tax"
;

*  Aggregate the GTAP matrices

Agg3(vdfb,vdfb1,i0,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg3(vdfp,vdfp1,i0,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg3(vmfb,vmfb1,i0,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg3(vmfp,vmfp1,i0,i,mapi,a0,a,mapa,r0,r,mapr) ;

Agg2(vdpb,vdpb1,i0,i,mapi,r0,r,mapr) ;
Agg2(vdpp,vdpp1,i0,i,mapi,r0,r,mapr) ;
Agg2(vmpb,vmpb1,i0,i,mapi,r0,r,mapr) ;
Agg2(vmpp,vmpp1,i0,i,mapi,r0,r,mapr) ;

Agg2(vdgb,vdgb1,i0,i,mapi,r0,r,mapr) ;
Agg2(vdgp,vdgp1,i0,i,mapi,r0,r,mapr) ;
Agg2(vmgb,vmgb1,i0,i,mapi,r0,r,mapr) ;
Agg2(vmgp,vmgp1,i0,i,mapi,r0,r,mapr) ;

Agg2(vdib,vdib1,i0,i,mapi,r0,r,mapr) ;
Agg2(vdip,vdip1,i0,i,mapi,r0,r,mapr) ;
Agg2(vmib,vmib1,i0,i,mapi,r0,r,mapr) ;
Agg2(vmip,vmip1,i0,i,mapi,r0,r,mapr) ;

Agg3(VXSB,VXSB1,i0,i,mapi,r0,r,mapr,rp0,rp,mapr) ;
Agg3(VFOB,VFOB1,i0,i,mapi,r0,r,mapr,rp0,rp,mapr) ;
Agg3(VCIF,VCIF1,i0,i,mapi,r0,r,mapr,rp0,rp,mapr) ;
Agg3(VMSB,VMSB1,i0,i,mapi,r0,r,mapr,rp0,rp,mapr) ;

Agg3(evfb,evfb1,endw,fp,mapf,a0,a,mapa,r0,r,mapr) ;
Agg3(evfp,evfp1,endw,fp,mapf,a0,a,mapa,r0,r,mapr) ;
Agg3(evos,evos1,endw,fp,mapf,a0,a,mapa,r0,r,mapr) ;
Agg3(FBEP,FBEP1,endw,fp,mapf,a0,a,mapa,r0,r,mapr) ;
Agg3(FTRV,FTRV1,endw,fp,mapf,a0,a,mapa,r0,r,mapr) ;

Agg2(VST,VST1,img0,img,mapi,r0,r,mapr) ;

Agg4(VTWR,VTWR1,img0,img,mapi,i0,i,mapi,r0,r,mapr,rp0,rp,mapr) ;

Agg1(SAVE,SAVE1,r0,r,mapr) ;
Agg1(VDEP,VDEP1,r0,r,mapr) ;
Agg1(VKB,VKB1,r0,r,mapr) ;
Agg1(POP,POP1,r0,r,mapr) ;

Agg3(maks,maks1,i0,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg3(makb,makb1,i0,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg3(ptax,ptax1,i0,i,mapi,a0,a,mapa,r0,r,mapr) ;

voa1(a,r) = sum(i, maks1(i,a,r)) ;
voi1(i,r) = sum(a, makb1(i,a,r)) ;

*  Move natural resource to capital

loop((cap,nrs,a)$mapn(a),
   evfp1(cap,a,r) = evfp1(cap,a,r) + evfp1(nrs,a,r) ;
   evfp1(nrs,a,r) = 0 ;
   evfb1(cap,a,r) = evfb1(cap,a,r) + evfb1(nrs,a,r) ;
   evfb1(nrs,a,r) = 0 ;
   evos1(cap,a,r) = evos1(cap,a,r) + evos1(nrs,a,r) ;
   evos1(nrs,a,r) = 0 ;
) ;

*  Save the data

sets
   img1(i)  "Margin commodities"
;

img1(i)$(sum(r,vst1(i,r)) > 0) = yes ;

*$exit 
execute_unload "%outdir%%baseNameF%%Aggregation%Dat.gdx",

*  Add the key sets
   a=acts, i=comm, img1=marg, r=reg, fp=endw,
   fpf=endwf, fpm=endwm, fps=endws,
   l, cap, lnd, nrs,
   
   rres, rmuv, imuv,
   vdfb1=vdfb, vdfp1=vdfp, vmfb1=vmfb, vmfp1=vmfp,
   vdpb1=vdpb, vdpp1=vdpp, vmpb1=vmpb, vmpp1=vmpp,
   vdgb1=vdgb, vdgp1=vdgp, vmgb1=vmgb, vmgp1=vmgp,
   vdib1=vdib, vdip1=vdip, vmib1=vmib, vmip1=vmip,
   evfb1=evfb, evfp1=evfp, evos1=evos,
   vxsb1=vxsb, vfob1=vfob, vcif1=vcif, vmsb1=vmsb,
   vst1=vst,   vtwr1=vtwr,
   save1=save, vdep1=vdep,
   vkb1=vkb,   pop1=pop,
   maks1=maks,
   makb1=makb, ptax1=ptax,

*  Additional data
   FBEP1=FBEP, FTRV1=FTRV
;

* ------------------------------------------------------------------------------
*
*  Aggregate GTAP parameters
*
* ------------------------------------------------------------------------------

* ----------------------------------------------------------------------------------------
*  Source parameters
*
*  Only parameters actually aggregated below are loaded from the standard GTAP
*  parameter file. ETRAQ1, ESUBQ1, ESUBG1, ESUBI1, ESUBS1 and ETRAE1 are
*  supplied directly by the mapping file.
* ----------------------------------------------------------------------------------------

parameters
   ESUBT(ACTS,REG)         "Top level production elasticity"
   ESUBC(ACTS,REG)         "Elasticity across intermediate inputs"
   ESUBVA(ACTS,REG)        "Value-added / land-vs-non-land substitution elasticity"
   INCPAR(COMM,REG)        "CDE expansion parameter"
   SUBPAR(COMM,REG)        "CDE substitution parameter"
   ESUBD(COMM,REG)         "Top level Armington elasticity"
   ESUBM(COMM,REG)         "Second level Armington elasticity"
   RORFLEX(REG)            "Flexibility of expected net ROR wrt investment"
   ESUBAEZ(ACTS,REG)       "GTAP-LULC substitution elasticity across AEZ land types"
;

set
   AEZS(ENDW)              "Source AEZ land endowments from GTAP-LULC"
;

execute_load "%gtpDir%/%GTAPBASE%PAR.gdx",
   ESUBT, ESUBC, ESUBVA,
   INCPAR, SUBPAR,
   ESUBD, ESUBM, RORFLEX
;

execute_load "%AEZDir%/GSDFPAR.gdx",
   AEZS, ESUBAEZ
;

scalar nAEZS "Number of AEZ source land endowments loaded" ;
nAEZS = card(AEZS) ;
abort$(nAEZS ne 18)
   "GTAP-LULC parameter file must provide exactly 18 AEZ land endowments", nAEZS ;


* ----------------------------------------------------------------------------------------
*  GAEZ climate land-productivity factor -- MOCK integration
*
*  Input:
*    Input\gaez_lndtfp_reg_aez_v2.csv
*
*  Required CSV columns:
*    1  REG
*    2  AEZ
*    3  gtap_activity
*    4  scenario
*    7  lndtfp_factor
*   13  effective_harvested_area_used
*
*  The CSV already contains the finalized source REG x AEZ x GTAP crop-activity
*  factor. Harvested area has already been used inside the GAEZ calibration.
*
*  This aggregation stage therefore uses source 2017 GTAP-LULC AEZ land
*  expenditure at purchasers' prices, EVFP(AEZS,ACTS,REG), to collapse:
*
*       source REG x AEZ x source crop activity
*                         ->
*       aggregate r x aggregate a
*
*  Missing source CSV combinations are intentionally treated as neutral
*  (factor = 1). This prevents positive GTAP land expenditure from disappearing
*  merely because a GAEZ harvested-area observation was absent.
*
*  No clipping/winsorization is applied here.
* ----------------------------------------------------------------------------------------

set
   gaezZ                         "GAEZ/GTAP AEZ number in CSV" / 1*18 /
   climscen                      "GAEZ climate scenarios"       / SSP126, SSP370 /
   gaezMetric                    "Imported CSV value columns"
                                 / lndtfp_factor, effective_harvested_area_used /
   gaezCropActs(ACTS)            "GTAP crop activities calibrated by GAEZ"
                                 / PDR, WHT, GRO, V_F, OSD, C_B, PFB, OCR /
   mapGaezZ(gaezZ,ENDW)          "Numeric CSV AEZ -> GTAP-LULC AEZ land endowment"
   gaezPresent(REG,gaezZ,ACTS,climscen)                                  "CSV combinations with positive effective harvested area"
;

mapGaezZ("1","AEZ1")   = yes ;
mapGaezZ("2","AEZ2")   = yes ;
mapGaezZ("3","AEZ3")   = yes ;
mapGaezZ("4","AEZ4")   = yes ;
mapGaezZ("5","AEZ5")   = yes ;
mapGaezZ("6","AEZ6")   = yes ;
mapGaezZ("7","AEZ7")   = yes ;
mapGaezZ("8","AEZ8")   = yes ;
mapGaezZ("9","AEZ9")   = yes ;
mapGaezZ("10","AEZ10") = yes ;
mapGaezZ("11","AEZ11") = yes ;
mapGaezZ("12","AEZ12") = yes ;
mapGaezZ("13","AEZ13") = yes ;
mapGaezZ("14","AEZ14") = yes ;
mapGaezZ("15","AEZ15") = yes ;
mapGaezZ("16","AEZ16") = yes ;
mapGaezZ("17","AEZ17") = yes ;
mapGaezZ("18","AEZ18") = yes ;

parameters
   GAEZCSVRAW(REG,gaezZ,ACTS,climscen,gaezMetric)       "Selected values imported from finalized GAEZ CSV"
   GAEZSRC(REG,gaezZ,ACTS,climscen)       "Source GAEZ factor; neutral (=1) for missing CSV combinations"
   GAEZEVFPWGT1(a,r)       "2017 GTAP-LULC AEZ-land EVFP denominator used for final aggregation"
   GAEZNUM1(a,r,climscen)       "EVFP-weighted GAEZ factor numerator"
   LNDTFP1(a,r,climscen)       "Final GAEZ v5 land-productivity factor"
;

scalars
   nGaezRecords
   nGaezZeroFactors
   nBadGaezAEZ
   nBadGaezActivityMap
;

* Convert just the two required numerical CSV columns to GDX.
* storeZero=y is essential because factor=0 is a legitimate GAEZ result.
$call csv2gdx "%GAEZCSV%" output="%GAEZGDX%" id=GAEZRAW index=1,2,3,4 values=7,13 useHeader=y storeZero=y
$if errorlevel 1 $abort "csv2gdx failed for finalized GAEZ lndtfp CSV"

execute_loaddc "%GAEZGDX%",
   GAEZCSVRAW=GAEZRAW
;

gaezPresent(REG,gaezZ,ACTS,climscen) =
   yes$(GAEZCSVRAW(REG,gaezZ,ACTS,climscen,"effective_harvested_area_used") > 0) ;

nGaezRecords =
   sum((REG,gaezZ,ACTS,climscen)$gaezPresent(REG,gaezZ,ACTS,climscen), 1) ;

abort$(nGaezRecords = 0)
   "No usable records were imported from the GAEZ CSV" ;

nBadGaezAEZ =
   sum(gaezZ$(
      sum(ENDW$(
         mapGaezZ(gaezZ,ENDW)
         and AEZS(ENDW)
      ), 1) ne 1
   ), 1) ;

abort$(nBadGaezAEZ ne 0)
   "Each numeric GAEZ AEZ must map to exactly one loaded AEZS endowment",
   nBadGaezAEZ ;

nBadGaezActivityMap =
   sum(ACTS$(
      gaezCropActs(ACTS)
      and (sum(a$mapa(ACTS,a),1) ne 1)
   ), 1) ;

abort$(nBadGaezActivityMap ne 0)
   "Each GAEZ source crop activity must map to exactly one aggregate activity",
   nBadGaezActivityMap ;

* Conservative default: every source crop/REG/AEZ/scenario combination is
* climate-neutral unless the finalized CSV explicitly provides a factor.
GAEZSRC(REG,gaezZ,ACTS,climscen)$gaezCropActs(ACTS) = 1 ;

GAEZSRC(REG,gaezZ,ACTS,climscen)$gaezPresent(REG,gaezZ,ACTS,climscen) =
   GAEZCSVRAW(REG,gaezZ,ACTS,climscen,"lndtfp_factor") ;

nGaezZeroFactors =
   sum((REG,gaezZ,ACTS,climscen)$(
      gaezPresent(REG,gaezZ,ACTS,climscen)
      and (GAEZSRC(REG,gaezZ,ACTS,climscen) = 0)
   ), 1) ;

* Final aggregation uses the SAME source EVFP block already loaded above.
* Only the 18 AEZ land endowments enter the denominator.
GAEZEVFPWGT1(a,r) =
   sum((REG,ACTS,gaezZ,ENDW)$(
      mapr(REG,r)
      and mapa(ACTS,a)
      and gaezCropActs(ACTS)
      and mapGaezZ(gaezZ,ENDW)
      and AEZS(ENDW)
   ),
      EVFP(ENDW,ACTS,REG)
   ) ;

GAEZNUM1(a,r,climscen) =
   sum((REG,ACTS,gaezZ,ENDW)$(
      mapr(REG,r)
      and mapa(ACTS,a)
      and gaezCropActs(ACTS)
      and mapGaezZ(gaezZ,ENDW)
      and AEZS(ENDW)
   ),
      EVFP(ENDW,ACTS,REG)
      * GAEZSRC(REG,gaezZ,ACTS,climscen)
   ) ;

* Fully populate the mock factor. Non-crop activities and crop-region cells
* with zero AEZ-land EVFP remain neutral.
LNDTFP1(a,r,climscen) = 1 ;

LNDTFP1(a,r,climscen)$GAEZEVFPWGT1(a,r) =
   GAEZNUM1(a,r,climscen)
   / GAEZEVFPWGT1(a,r) ;

display
   nGaezRecords,
   nGaezZeroFactors,
   nBadGaezAEZ,
   nBadGaezActivityMap,
   GAEZEVFPWGT1,
   LNDTFP1
;


*  Aggregate to intermediate levels

parameters
   ESUBT1(a,r)          "Top level production elasticity"
   ESUBC1(a,r)          "Elasticity across intermedate inputs"
   ESUBVA1(a,r)         "Inter-factor substitution elasticity"
*  USER SUPPLIED
*  ETRAQ1(a,r)          "CET make elasticity"
*  ESUBQ1(i,r)          "CES make elasticity"
   INCPAR1(i,r)         "CDE expansion parameter"
   SUBPAR1(i,r)         "CDE substitution parameter"
*  USER SUPPLIED
*  ESUBG1(r)            "CES government expenditure elasticity"
*  ESUBI1(r)            "CES investment expenditure elasticity"
   ESUBD1(i,r)          "Top level Armington elasticity"
   ESUBM1(i,r)          "Second level Armington elasticity"
*  USER SUPPLIED
   ESUBS1(img)          "CES margin elasticity"
   RORFLEX1(r)          "Flexibility of expected net ROR wrt investment"

*  New for land-use module
   ESUBKL1(a,r)         "Substitution elasticity across non-land factors"
   ESUBLND1(a,r)        "Substitution elasticity across AEZ land types"
   LANDVFP(ACTS,REG)    "Source AEZ-land expenditure at purchasers' prices"
   LANDVFP1(a,r)        "Aggregated AEZ-land expenditure used as ESUBAEZ weight"
;

*  Aggregate the data

*  ESUBT -- use regional output as weight

esubt1(a,r) = sum(a0$mapa(a0,a), sum(reg$mapr(reg,r), voa(a0, reg))) ;
esubt1(a,r)$esubt1(a,r) = sum(a0$mapa(a0,a),
      sum(reg$mapr(reg,r), voa(a0, reg)*ESUBT(a0,reg))) / esubt1(a,r) ;
      
*  ESUBC -- use regional intermediate demand at purchasers' prices as weight

esubc1(a,r) = sum(a0$mapa(a0,a), sum((reg,i0)$mapr(reg,r), (vdfp(i0,a0,reg)+vmfp(i0,a0,reg)))) ;
esubc1(a,r)$esubc1(a,r) = sum(a0$mapa(a0,a), sum((reg,i0)$mapr(reg,r),
      (vdfp(i0,a0,reg)+vmfp(i0,a0,reg))*ESUBC(a0,reg))) / esubc1(a,r) ;

*  ESUBVA -- use regional value added at agents' prices as weight

esubva1(a,r) = sum(a0$mapa(a0,a), sum((reg,fp0)$mapr(reg,r), evfp(fp0, a0, reg))) ;
esubva1(a,r)$esubva1(a,r) = sum(a0$mapa(a0,a),
      sum((reg,fp0)$mapr(reg,r), evfp(fp0, a0, reg)*ESUBVA(a0,reg))) / esubva1(a,r) ;

*  INCPAR, SUBPAR -- Use regional private demand at agents' prices

incpar1(i,r) = sum((i0,r0)$(mapi(i0,i) and mapr(r0,r)), vdpp(i0,r0) + vmpp(i0,r0)) ;
subpar1(i,r) = incpar1(i,r) ;
incpar1(i,r)$incpar1(i,r)
          = sum((i0,r0)$(mapi(i0,i) and mapr(r0,r)), INCPAR(i0,r0)*(vdpp(i0,r0) + vmpp(i0,r0)))
          / incpar1(i,r) ;
subpar1(i,r)$subpar1(i,r)
          = sum((i0,r0)$(mapi(i0,i) and mapr(r0,r)), SUBPAR(i0,r0)*(vdpp(i0,r0) + vmpp(i0,r0)))
          / subpar1(i,r) ;

*  ESUBD -- Use regional aggregate Armington demand

esubd1(i,r) = sum(i0$mapi(i0,i), sum(reg$mapr(reg,r),
               sum(a0, vdfp(i0,a0,reg) + vmfp(i0,a0,reg))
          +            vdpp(i0,reg) + vmpp(i0,reg)
          +            vdgp(i0,reg) + vmgp(i0,reg)
          +            vdip(i0,reg) + vmip(i0,reg)
               )) ;
esubd1(i,r)$esubd1(i,r)
          = sum(i0$mapi(i0,i), sum(reg$mapr(reg,r), ESUBD(i0,reg)*(
               sum(a0, vdfp(i0,a0,reg) + vmfp(i0,a0,reg))
          +            vdpp(i0,reg) + vmpp(i0,reg)
          +            vdgp(i0,reg) + vmgp(i0,reg)
          +            vdip(i0,reg) + vmip(i0,reg))))
          / esubd1(i,r) ;

*  ESUBM -- Use regional aggregate import demand

esubm1(i,r) = sum(i0$mapi(i0,i), sum(reg$mapr(reg,r),
            +  sum(a0, vmfp(i0,a0,reg))
            +          vmpp(i0,reg)
            +          vmgp(i0,reg)
            +          vmip(i0,reg))) ;
esubm1(i,r)$esubm1(i,r)
            = sum(i0$mapi(i0,i), sum(reg$mapr(reg,r), ESUBM(i0,reg)*(
            +  sum(a0, vmfp(i0,a0,reg))
            +          vmpp(i0,reg)
            +          vmgp(i0,reg)
            +          vmip(i0,reg))))
            / esubm1(i,r) ;

*  RORFLEX -- Use regional level of capital stock

RORFLEX1(r) = sum(r0$mapr(r0,r), vkb(r0)) ;
RORFLEX1(r)$RORFLEX1(r) =sum(r0$mapr(r0,r), RORFLEX(r0)*vkb(r0)) / RORFLEX1(r) ;

* ----------------------------------------------------------------------------------------
*  GTAP-LU land/non-land substitution parameters
* ----------------------------------------------------------------------------------------

* No separate AEZ-package parameter exists for substitution within the non-land
* bundle. Preserve the existing GTAP-LU assumption.
ESUBKL1(a,r) = ESUBVA1(a,r) ;

* Aggregate ESUBAEZ with source AEZ-land factor expenditure (EVFP) as weight.
LANDVFP(acts,reg) = sum(AEZS, EVFP(AEZS,acts,reg)) ;

LANDVFP1(a,r) =
   sum(a0$mapa(a0,a),
      sum(reg$mapr(reg,r), LANDVFP(a0,reg))) ;

ESUBLND1(a,r)$LANDVFP1(a,r) =
   sum(a0$mapa(a0,a),
      sum(reg$mapr(reg,r),
         LANDVFP(a0,reg) * ESUBAEZ(a0,reg)))
   / LANDVFP1(a,r) ;

* Safe fallback for zero-land activity-region cells. The value is economically
* inactive there but keeps the output parameter fully populated.
ESUBLND1(a,r)$(LANDVFP1(a,r) = 0) = ESUBVA1(a,r) ;

*  Save the data

execute_unload "%outdir%%baseNameF%%Aggregation%Prm.gdx",

   ESUBT1=ESUBT, ESUBC1=ESUBC, ESUBVA1=ESUBVA,
   ESUBKL1=ESUBKL, ESUBLND1=ESUBLND,
   ETRAQ1=ETRAQ, ESUBQ1=ESUBQ,
   INCPAR1=INCPAR, SUBPAR1=SUBPAR, ESUBG1=ESUBG, ESUBI1=ESUBI,
   ESUBD1=ESUBD, ESUBM1=ESUBM, ESUBS1=ESUBS, ETRAE1=ETRAE, RORFLEX1=RORFLEX,

* GAEZ v5 climate land-productivity factors, already aggregated to the
* model activity x region domains. Scenario members are SSP126 and SSP370.
   climscen,
   LNDTFP1=lndtfp
;

* ------------------------------------------------------------------------------
*
*  Aggregate energy data
*
* ------------------------------------------------------------------------------

*  Energy matrices

parameters
   EDF(ERG, ACTS, REG)     "Usage of domestic products by firm"
   EMF(ERG, ACTS, REG)     "Usage of imported products by firm"
   EDP(ERG,REG)            "Private consumption of domestic goods"
   EMP(ERG,REG)            "Private consumption of imported goods"
   EDG(ERG,REG)            "Public consumption of domestic goods"
   EMG(ERG,REG)            "Public consumption of imported goods"
   EDI(ERG,REG)            "Investment consumption of domestic goods"
   EMI(ERG,REG)            "Investment consumption of imported goods"
   EXI(ERG, REG, REG)      "Bilateral trade in energy"
;

execute_load "%gtpDir%/%GTAPBASE%vole.gdx",
   EDF, EMF, EDP, EMP, EDG, EMG, EDI, EMI, EXI
;

parameters
   EDF1(i, a, r)           "Usage of domestic products by firm"
   EMF1(i, a, r)           "Usage of imported products by firm"
   EDP1(i, r)              "Private consumption of domestic goods"
   EMP1(i, r)              "Private consumption of imported goods"
   EDG1(i, r)              "Public consumption of domestic goods"
   EMG1(i, r)              "Public consumption of imported goods"
   EDI1(i, r)              "Investment consumption of domestic goods"
   EMI1(i, r)              "Investment consumption of imported goods"
   EXI1(i, r, rp)          "Bilateral trade in energy"
;

Agg3(edf,edf1,ERG,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg3(emf,emf1,ERG,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg2(edp,edp1,ERG,i,mapi,r0,r,mapr) ;
Agg2(emp,emp1,ERG,i,mapi,r0,r,mapr) ;
Agg2(edg,edg1,ERG,i,mapi,r0,r,mapr) ;
Agg2(emg,emg1,ERG,i,mapi,r0,r,mapr) ;
Agg2(edi,edi1,ERG,i,mapi,r0,r,mapr) ;
Agg2(emi,emi1,ERG,i,mapi,r0,r,mapr) ;
Agg3(exi,exi1,ERG,i,mapi,r0,r,mapr,rp0,rp,mapr) ;

edf1(i,a,r)$(voi1(i,r) = 0)  = 0 ;
edp1(i,r)$(voi1(i,r) = 0)    = 0 ;
edg1(i,r)$(voi1(i,r) = 0)    = 0 ;
exi1(i,r,rp)$(voi1(i,r) = 0) = 0 ;

*  Save the data

execute_unload  "%outdir%%baseNameF%%Aggregation%Vole.gdx",
   EDF1=EDF, EMF1=EMF,
   EDP1=EDP, EMP1=EMP,
   EDG1=EDG, EMG1=EMG,
   EDI1=EDI, EMI1=EMI,
   EXI1=EXI
;

* ------------------------------------------------------------------------------
*
*  Aggregate CO2 emissions data
*
* ------------------------------------------------------------------------------

*  CO2 Emission matrices

parameters
   MDF(FUEL, ACTS, REG)          "Emissions from domestic product in current production, .."
   MMF(FUEL, ACTS, REG)          "Emissions from imported product in current production, .."
   MDP(FUEL, REG)                "Emissions from private consumption of domestic product, Mt CO2"
   MMP(FUEL, REG)                "Emissions from private consumption of imported product, Mt CO2"
   MDG(FUEL, REG)                "Emissions from govt consumption of domestic product, Mt CO2"
   MMG(FUEL, REG)                "Emissions from govt consumption of imported product, Mt CO2"
   MDI(FUEL, REG)                "Emissions from invt consumption of domestic product, Mt CO2"
   MMI(FUEL, REG)                "Emissions from invt consumption of imported product, Mt CO2"
;

execute_load "%gtpDir%/%GTAPBASE%emiss.gdx",
   MDF, MMF, MDP, MMP, MDG, MMG, MDI, MMI
;

parameters
   MDF1(i, a, r)         "Emissions from domestic product in current production, .."
   MMF1(i, a, r)         "Emissions from imported product in current production, .."
   MDP1(i, r)            "Emissions from private consumption of domestic product, Mt CO2"
   MMP1(i, r)            "Emissions from private consumption of imported product, Mt CO2"
   MDG1(i, r)            "Emissions from govt consumption of domestic product, Mt CO2"
   MMG1(i, r)            "Emissions from govt consumption of imported product, Mt CO2"
   MDI1(i, r)            "Emissions from invt consumption of domestic product, Mt CO2"
   MMI1(i, r)            "Emissions from invt consumption of imported product, Mt CO2"
;

Agg3(mdf,mdf1,fuel,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg3(mmf,mmf1,fuel,i,mapi,a0,a,mapa,r0,r,mapr) ;
Agg2(mdp,mdp1,fuel,i,mapi,r0,r,mapr) ;
Agg2(mmp,mmp1,fuel,i,mapi,r0,r,mapr) ;
Agg2(mdg,mdg1,fuel,i,mapi,r0,r,mapr) ;
Agg2(mmg,mmg1,fuel,i,mapi,r0,r,mapr) ;
Agg2(mdi,mdi1,fuel,i,mapi,r0,r,mapr) ;
Agg2(mmi,mmi1,fuel,i,mapi,r0,r,mapr) ;

*  Save the data

execute_unload  "%outdir%%baseNameF%%Aggregation%Emiss.gdx",
   MDF1=MDF, MMF1=MMF, MDP1=MDP, MMP1=MMP, MDG1=MDG, MMG1=MMG, MDI1=MDI, MMI1=MMI
;
* ----------------------------------------------------------------------------------------
*  End-of-run summary for the aggregation audit trail
* ----------------------------------------------------------------------------------------

put screen ;
put / "======================================================================" / ;
put "AGGGTAP SUMMARY" / ;
put "======================================================================" / ;
put "Aggregation mapping  : %Aggregation%Map.gms" / ;
put "Standard DAT         : %gtpDir%/%GTAPBASE%DAT.gdx" / ;
put "AEZ factor DAT       : %AEZDir%/GSDFDAT.gdx" / ;
put "Standard PAR         : %gtpDir%/%GTAPBASE%PAR.gdx" / ;
put "AEZ parameter PAR    : %AEZDir%/GSDFPAR.gdx" / ;
put "AEZ source factors   : ", nAEZS:0:0 / ;
put "Aggregate regions    : ", card(r):0:0 / ;
put "Aggregate activities : ", card(a):0:0 / ;
put "Aggregate commodities: ", card(i):0:0 / ;
put "Aggregate factors    : ", card(fp):0:0 / ;
put "ESUBLND source       : ESUBAEZ weighted by AEZ-land EVFP" / ;
put "ETFA/ETPC/ETCR       : intentionally not used" / ;
put "Standard ETRAE       : not loaded; ETRAE1 supplied by mapping" / ;
put "Status               : aggregation completed" / ;
put "======================================================================" / ;
putclose screen ;

*execute_unload  "testGTAP_SE2.gdx"