* ========================================================================================
*  GTAP 11 / GTAP-LULC AEZ mapping for the MERCOSUR deforestation project
*
*  File       : MercosurMap.gms
*  Purpose    : Define the aggregation used by agggtap.gms for the hybrid
*               standard-GTAP-11 + GTAP-LULC-AEZ database.
*
*  Project WD : C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn
*  Updated    : 2026-08-11
*
*  TARGET AGGREGATION
*
*    Regions (10):
*      Brazil, Argentina, Paraguay, Uruguay, Bolivia,
*      EU27, China, US, RestLatAm, ROW
*
*    Factors (22):
*      UnSkLab, SkLab, Capital, AEZ1...AEZ18, NatRes
*
*    Activities / commodities:
*      Existing 21-activity / 21-commodity aggregation retained unchanged.
*
*  SOURCE-SET ARCHITECTURE
*
*    Standard GTAP 11 DAT : Input/GSDF11DAT.GDX
*       -> REG, COMM, MARG
*
*    GTAP-LULC AEZ DAT    : Input/GDX11cAEZ17/GSDFDAT.GDX
*       -> ENDW (five labour types + Capital + AEZ1...AEZ18 + NatlRes)
*
*    Standard VOLE/EMISS  : Input/GSDF11VOLE.GDX and Input/GSDF11EMISS.GDX
*       -> ERG and FUEL
*
*  REGION DESIGN
*
*    - Uses the GTAP 11 final 160-region source structure.
*    - XCF is NOT a GTAP 11 final source region and is not mapped here.
*    - GTAP 11 newly disaggregated countries are mapped explicitly.
*    - EU27 contains the current 27 EU members and excludes GBR.
*    - China is CHN only; HKG and TWN remain in ROW.
*    - RestLatAm contains Mexico, non-MERCOSUR South/Central America,
*      and Caribbean regions, including HTI.
*    - ROW is the residual region for the investment/foreign-savings closure.
*    - RMUV uses EU27 + US only because ROW is a mixed-income aggregate.
*
*  FACTOR DESIGN
*
*    - AEZ1...AEZ18 are retained one-for-one; they are not collapsed to Land.
*    - Labour is aggregated from five GTAP-LULC labour endowments to two groups.
*    - ETRAE1 is supplied directly here: labour/capital mobile, AEZ land sluggish,
*      NatRes sector-specific. Standard GTAP ETRAE is not used by agggtap.gms.
*
*  NOTE
*
*    This file supersedes the earlier provisional GTAP-11 mapping that
*    incorrectly treated XCF as a final GTAP 11 region.
*
* ========================================================================================

$setGlobal gtpDir   "Input"
$setGlobal GTAPBASE "GSDF11"
$setGlobal AEZDir   "Input/GDX11cAEZ17"

Sets
   reg         "Regions in GTAP 11"
   comm        "Commodities / activities in GTAP 11"
   marg(comm)  "Margin activities"
   erg(comm)   "Energy commodities"
   fuel(erg)   "Fuel commodities"
   endw        "GTAP-LULC endowments including AEZ1...AEZ18"
;

* Standard GTAP 11 owns the regional, commodity and margin source sets.
$gdxin "%gtpDir%/%GTAPBASE%DAT.gdx"
$load reg
$load comm
$load marg

* GTAP-LULC owns the active factor/endowment source set used by the LU model.
$gdxin "%AEZDir%/GSDFDAT.gdx"
$load endw

* Energy/emissions source sets remain standard GTAP 11.
$gdxin "%gtpDir%/%GTAPBASE%VOLE.gdx"
$load erg

$gdxin "%gtpDir%/%GTAPBASE%EMISS.gdx"
$load fuel

alias(acts,comm) ;
alias(reg,r0) ;
alias(reg,rp0) ;
alias(comm,i0) ;
alias(acts,a0) ;
alias(endw,fp0) ;
alias(img0,marg) ;

$onempty

sets

   i  "Commodities"   /
         c_PDR          "Paddy rice"
         c_WHT          "Wheat"
         c_GRO          "Cereals, grains nec"
         c_V_F          "Vegetable, fruit, nuts"
         c_OSD          "Oil seeds"
         c_C_B          "Sugar cane, sugar beet"
         c_PFB          "Plant-based fibers"
         c_OCR          "Other crop products"
         c_CTL          "Bovine cattle, sheep and goats, horses"
         c_OAP          "Other animal products"
         c_RMK          "Raw milk"
         c_WOL          "Wool, silk-worm cocoons"
         c_FRS          "Forestry"
         c_Extraction   "Extraction"
         c_ProcFood     "Processed foods"
         c_TextWapp     "Textile and wearing apparel"
         c_LightMnfc    "Light manufacturing"
         c_HeavyMnfc    "Heavy manufacturing"
         c_Util_Cons    "Utility and consumption"
         c_TransComm    "Transportation and communication"
         c_OthService   "Other services"
      /

   m(i)  "Margin commodities"

   a  "Activities"   /
         a_PDR          "Paddy rice"
         a_WHT          "Wheat"     
         a_GRO          "Cereals, grains nec"
         a_V_F          "Vegetable, fruit, nuts"
         a_OSD          "Oil seeds"
         a_C_B          "Sugar cane, sugar beet"
         a_PFB          "Plant-based fibers"
         a_OCR          "Other crop products"
         a_CTL          "Bovine cattle, sheep and goats, horses"
         a_OAP          "Other animal products"
         a_RMK          "Raw milk"
         a_WOL          "Wool, silk-worm cocoons"
         a_FRS          "Forestry"
         a_Extraction   "Extraction"
         a_ProcFood     "Processed foods"
         a_TextWapp     "Textile and wearing apparel"
         a_LightMnfc    "Light manufacturing"
         a_HeavyMnfc    "Heavy manufacturing"
         a_Util_Cons    "Utility and consumption"
         a_TransComm    "Transportation and communication"
         a_OthService   "Other services"
      /

   r  "Regions" /
         Brazil         "Brazil"
         Argentina      "Argentina"
         Paraguay       "Paraguay"
         Uruguay        "Uruguay"
         Bolivia        "Bolivia"
         EU27           "European Union - 27 members, excluding the United Kingdom"
         China          "China"
         US             "United States"
         RestLatAm      "Rest of Latin America and the Caribbean"
         ROW            "Rest of the world"
      /

   fp  "Factors of production"  /
         UnSkLab        "Unskilled labor"
         SkLab          "Skilled labor"
         Capital        "Capital"
         AEZ1           "Land - AEZ1"
         AEZ2           "Land - AEZ2"
         AEZ3           "Land - AEZ3"
         AEZ4           "Land - AEZ4"
         AEZ5           "Land - AEZ5"
         AEZ6           "Land - AEZ6"
         AEZ7           "Land - AEZ7"
         AEZ8           "Land - AEZ8"
         AEZ9           "Land - AEZ9"
         AEZ10          "Land - AEZ10"
         AEZ11          "Land - AEZ11"
         AEZ12          "Land - AEZ12"
         AEZ13          "Land - AEZ13"
         AEZ14          "Land - AEZ14"
         AEZ15          "Land - AEZ15"
         AEZ16          "Land - AEZ16"
         AEZ17          "Land - AEZ17"
         AEZ18          "Land - AEZ18"
         NatRes         "Natural resources"
      /

   l(fp)  "Labor factors" /
         UnSkLab        "Unskilled labor"
         SkLab          "Skilled labor"
      /
   cap(fp) "Capital" /
         Capital        "Capital"
      /
   lnd(fp) "Land endowments by agro-ecological zone" /
         AEZ1
         AEZ2
         AEZ3
         AEZ4
         AEZ5
         AEZ6
         AEZ7
         AEZ8
         AEZ9
         AEZ10
         AEZ11
         AEZ12
         AEZ13
         AEZ14
         AEZ15
         AEZ16
         AEZ17
         AEZ18
      /
   nrs(fp) "Natural resource" /
         NatRes         "Natural resources"
      /
;

Parameter
   etrae1(fp,r) "CET transformation elasticities for factor allocation"
;

*  Use the GTAP convention that CET elasticities are entered as negative numbers.
*  All 18 AEZ land endowments retain the standard sluggish-land elasticity.

Parameter etrae0(fp) "CET transformation elasticities for factor allocation" /
   UnSkLab   inf
   SkLab     inf
   Capital   inf
   AEZ1     -1.0
   AEZ2     -1.0
   AEZ3     -1.0
   AEZ4     -1.0
   AEZ5     -1.0
   AEZ6     -1.0
   AEZ7     -1.0
   AEZ8     -1.0
   AEZ9     -1.0
   AEZ10    -1.0
   AEZ11    -1.0
   AEZ12    -1.0
   AEZ13    -1.0
   AEZ14    -1.0
   AEZ15    -1.0
   AEZ16    -1.0
   AEZ17    -1.0
   AEZ18    -1.0
   NatRes   -0.001
/ ;

etrae1(fp,r) = etrae0(fp) ;

set
   fpf(fp)     "Sector specific factors"
   fps(fp)     "Sluggish factors"
   fpm(fp)     "Mobile factors"
;

fpf(fp)$(abs(etrae0(fp)) lt 0.01) = yes ;
fpm(fp)$(etrae0(fp) eq inf)       = yes ;
fps(fp)$(not fpf(fp) and not fpm(fp)) = yes ;

*  NEW -- MAKE ELASTICITIES

Parameter
   etraq1(a,r)       "MAKE CET Elasticity"
   esubq1(i,r)       "MAKE CES Elasticity"
;
etraq1(a,r) = -5 ;
esubq1(i,r) = inf ;

*  NEW -- EXPENDITURE ELASTICITIES

Parameter
   esubg1(r)         "Government expenditure CES elasticity"
   esubi1(r)         "Investment expenditure CES elasticity"
   esubs1(i)         "Transport margins CES elasticity"
;

esubg1(r) = 1 ;
esubi1(r) = 0 ;
esubs1(i) = 1 ;

*  This set is ignored for GTAP-LU
set mapt(a) "Merge land and capital payments in the following sectors" /

/ ;

set mapn(a) "Merge natl. res. and capital payments in the following sectors" /

/ ;

*  MAPPINGS TO GTAP

set mapa(acts,a) /
   PDR.a_PDR
   WHT.a_WHT
   GRO.a_GRO
   V_F.a_V_F
   OSD.a_OSD
   C_B.a_C_B
   PFB.a_PFB
   OCR.a_OCR
   CTL.a_CTL
   OAP.a_OAP
   RMK.a_RMK
   WOL.a_WOL
   FRS.a_FRS
   FSH.a_Extraction
   COA.a_Extraction
   OIL.a_Extraction
   GAS.a_Extraction
   OXT.a_Extraction
   CMT.a_ProcFood
   OMT.a_ProcFood
   VOL.a_ProcFood
   MIL.a_ProcFood
   PCR.a_ProcFood
   SGR.a_ProcFood
   OFD.a_ProcFood
   B_T.a_ProcFood
   TEX.a_TextWapp
   WAP.a_TextWapp
   LEA.a_LightMnfc
   LUM.a_LightMnfc
   PPP.a_LightMnfc
   P_C.a_HeavyMnfc
   CHM.a_HeavyMnfc
   BPH.a_HeavyMnfc
   RPP.a_HeavyMnfc
   NMM.a_HeavyMnfc
   I_S.a_HeavyMnfc
   NFM.a_HeavyMnfc
   FMP.a_LightMnfc
   ELE.a_LightMnfc
   EEQ.a_LightMnfc
   OME.a_HeavyMnfc
   MVH.a_HeavyMnfc
   OTN.a_HeavyMnfc
   OMF.a_LightMnfc
   ELY.a_Util_Cons
   GDT.a_Util_Cons
   WTR.a_Util_Cons
   CNS.a_Util_Cons
   TRD.a_TransComm
   AFS.a_TransComm
   OTP.a_TransComm
   WTP.a_TransComm
   ATP.a_TransComm
   WHS.a_TransComm
   CMN.a_TransComm
   OFI.a_OthService
   INS.a_OthService
   RSA.a_OthService
   OBS.a_OthService
   ROS.a_OthService
   OSG.a_OthService
   EDU.a_OthService
   HHT.a_OthService
   DWE.a_OthService
/ ;

set mapi(comm,i) /
   PDR.c_PDR
   WHT.c_WHT
   GRO.c_GRO
   V_F.c_V_F
   OSD.c_OSD
   C_B.c_C_B
   PFB.c_PFB
   OCR.c_OCR
   CTL.c_CTL
   OAP.c_OAP
   RMK.c_RMK
   WOL.c_WOL
   FRS.c_FRS
   FSH.c_Extraction
   COA.c_Extraction
   OIL.c_Extraction
   GAS.c_Extraction
   OXT.c_Extraction
   CMT.c_ProcFood
   OMT.c_ProcFood
   VOL.c_ProcFood
   MIL.c_ProcFood
   PCR.c_ProcFood
   SGR.c_ProcFood
   OFD.c_ProcFood
   B_T.c_ProcFood
   TEX.c_TextWapp
   WAP.c_TextWapp
   LEA.c_LightMnfc
   LUM.c_LightMnfc
   PPP.c_LightMnfc
   P_C.c_HeavyMnfc
   CHM.c_HeavyMnfc
   BPH.c_HeavyMnfc
   RPP.c_HeavyMnfc
   NMM.c_HeavyMnfc
   I_S.c_HeavyMnfc
   NFM.c_HeavyMnfc
   FMP.c_LightMnfc
   ELE.c_LightMnfc
   EEQ.c_LightMnfc
   OME.c_HeavyMnfc
   MVH.c_HeavyMnfc
   OTN.c_HeavyMnfc
   OMF.c_LightMnfc
   ELY.c_Util_Cons
   GDT.c_Util_Cons
   WTR.c_Util_Cons
   CNS.c_Util_Cons
   TRD.c_TransComm
   AFS.c_TransComm
   OTP.c_TransComm
   WTP.c_TransComm
   ATP.c_TransComm
   WHS.c_TransComm
   CMN.c_TransComm
   OFI.c_OthService
   INS.c_OthService
   RSA.c_OthService
   OBS.c_OthService
   ROS.c_OthService
   OSG.c_OthService
   EDU.c_OthService
   HHT.c_OthService
   DWE.c_OthService
/ ;

* GTAP 11 final 160-region mapping.
* All source regions map exactly once. XCF is absent from the GTAP 11 final source set.
* EU27 = current EU-27 only; GBR/CHE/NOR/XEF -> ROW.
* China = CHN only; HKG/TWN -> ROW.
* RestLatAm = Mexico + remaining South/Central America + Caribbean (including HTI).

set mapr(reg,r) /
   AUS.ROW
   NZL.ROW
   XOC.ROW
   CHN.China
   HKG.ROW
   JPN.ROW
   KOR.ROW
   MNG.ROW
   TWN.ROW
   XEA.ROW
   BRN.ROW
   KHM.ROW
   IDN.ROW
   LAO.ROW
   MYS.ROW
   PHL.ROW
   SGP.ROW
   THA.ROW
   VNM.ROW
   XSE.ROW
   AFG.ROW
   BGD.ROW
   IND.ROW
   NPL.ROW
   PAK.ROW
   LKA.ROW
   XSA.ROW
   CAN.ROW
   USA.US
   MEX.RestLatAm
   XNA.ROW
   ARG.Argentina
   BOL.Bolivia
   BRA.Brazil
   CHL.RestLatAm
   COL.RestLatAm
   ECU.RestLatAm
   PRY.Paraguay
   PER.RestLatAm
   URY.Uruguay
   VEN.RestLatAm
   XSM.RestLatAm
   CRI.RestLatAm
   GTM.RestLatAm
   HND.RestLatAm
   NIC.RestLatAm
   PAN.RestLatAm
   SLV.RestLatAm
   XCA.RestLatAm
   DOM.RestLatAm
   HTI.RestLatAm
   JAM.RestLatAm
   PRI.RestLatAm
   TTO.RestLatAm
   XCB.RestLatAm
   AUT.EU27
   BEL.EU27
   BGR.EU27
   HRV.EU27
   CYP.EU27
   CZE.EU27
   DNK.EU27
   EST.EU27
   FIN.EU27
   FRA.EU27
   DEU.EU27
   GRC.EU27
   HUN.EU27
   IRL.EU27
   ITA.EU27
   LVA.EU27
   LTU.EU27
   LUX.EU27
   MLT.EU27
   NLD.EU27
   POL.EU27
   PRT.EU27
   ROU.EU27
   SVK.EU27
   SVN.EU27
   ESP.EU27
   SWE.EU27
   GBR.ROW
   CHE.ROW
   NOR.ROW
   XEF.ROW
   ALB.ROW
   SRB.ROW
   BLR.ROW
   RUS.ROW
   UKR.ROW
   XEE.ROW
   XER.ROW
   KAZ.ROW
   KGZ.ROW
   TJK.ROW
   UZB.ROW
   XSU.ROW
   ARM.ROW
   AZE.ROW
   GEO.ROW
   BHR.ROW
   IRN.ROW
   IRQ.ROW
   ISR.ROW
   JOR.ROW
   KWT.ROW
   LBN.ROW
   OMN.ROW
   PSE.ROW
   QAT.ROW
   SAU.ROW
   SYR.ROW
   TUR.ROW
   ARE.ROW
   XWS.ROW
   DZA.ROW
   EGY.ROW
   MAR.ROW
   TUN.ROW
   XNF.ROW
   BEN.ROW
   BFA.ROW
   CMR.ROW
   CIV.ROW
   GHA.ROW
   GIN.ROW
   MLI.ROW
   NER.ROW
   NGA.ROW
   SEN.ROW
   TGO.ROW
   XWF.ROW
   CAF.ROW
   TCD.ROW
   COG.ROW
   COD.ROW
   GNQ.ROW
   GAB.ROW
   XAC.ROW
   COM.ROW
   ETH.ROW
   KEN.ROW
   MDG.ROW
   MWI.ROW
   MUS.ROW
   MOZ.ROW
   RWA.ROW
   SDN.ROW
   TZA.ROW
   UGA.ROW
   ZMB.ROW
   ZWE.ROW
   XEC.ROW
   BWA.ROW
   SWZ.ROW
   NAM.ROW
   ZAF.ROW
   XSC.ROW
   XTW.ROW
/ ;

* GTAP 11 endowment mapping.
* Five GTAP labor types are aggregated to two labor factors; all 18 AEZ land
* endowments are retained separately for GTAP-LU land-use accounting.

set mapf(endw, fp) /
   ag_othlowsk  . UnSkLab
   service_shop . UnSkLab
   clerks       . UnSkLab
   tech_aspros  . SkLab
   off_mgr_pros . SkLab
   Capital      . Capital
   AEZ1         . AEZ1
   AEZ2         . AEZ2
   AEZ3         . AEZ3
   AEZ4         . AEZ4
   AEZ5         . AEZ5
   AEZ6         . AEZ6
   AEZ7         . AEZ7
   AEZ8         . AEZ8
   AEZ9         . AEZ9
   AEZ10        . AEZ10
   AEZ11        . AEZ11
   AEZ12        . AEZ12
   AEZ13        . AEZ13
   AEZ14        . AEZ14
   AEZ15        . AEZ15
   AEZ16        . AEZ16
   AEZ17        . AEZ17
   AEZ18        . AEZ18
   NatlRes      . NatRes
/ ;

* --------------------------------------------------------------------------------------------------
*
*  Additional definitions for the GTAP in GAMS model
*
* --------------------------------------------------------------------------------------------------

* Use the large diversified ROW aggregate as the residual investment/foreign-savings region.
* This avoids putting the residual closure directly on one of the focal MERCOSUR countries
* or one of the principal policy/trade partners.
singleton set rres(r) "Residual region" /
   ROW
/ ;

* RMUV is intended to represent manufactured-export prices from high-income regions.
* Under this 10-region aggregation, EU27 and US are the only clean high-income aggregates;
* ROW is mixed and is therefore deliberately excluded.
set rmuv(r) "RMUV regions" /
   EU27, US
/ ;

set imuv(i) "IMUV commodities" /
   c_procfood, c_textWapp, c_LightMnfc, c_HeavyMnfc
/ ;
