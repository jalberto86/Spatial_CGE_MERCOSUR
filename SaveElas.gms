set iw "Sectors" /
   AGR     "Farms and farm products (111CA)"
   FOF     "Forestry and fishing"
   FBP     "Food and beverage and tobacco products (311FT)"
   ALT     "Apparel and leather and allied products (315AL)"
   PMT     "Primary metals (331)"
   OGS     "Crude oil and natural gas"
   UTI     "Utilities (electricity-gas-water)"
   TEX     "Textiles"
   LUM     "Lumber and wood products"
   NMM     "Mineral products nec."
   FMP     "Metal products"
   MVH     "Motor vehicles and parts"
   OTN     "Transport equipment nec."
   OME     "Machinery and equipment nec."
   CNS     "Construction"
   WTP     "Water transport"
   ATP     "Air transport"
   ISR     "Insurance"
   COL     "Coal "
   OIL     "'Petroleum, coal products'"
   OMN     "Minerals nec."
   PPP     "'Paper products, publishing'"
   CRP     "'Chemical, rubber, plastic products'"
   EEQ     "Electronic equipment"
   OMF     "Manufactures nec."
   TRD     "Trade"
   OTP     "Transport nec."
   CMN     "Communication"
   OFI     "Financial services nec."
   OBS     "Business services nec."
   ROS     "Recreational and other services"
   OSG     "'Public Administration, Defense, Education, Health'"
   DWE     "Dwellings"
/ ;

set mapacts(iw,a) /
   AGR . AGR-a
   FOF . FOF-a
   FBP . FBP-a
   ALT . ALT-a
   PMT . PMT-a
   OGS . OGS-a
   UTI . UTI-a
   TEX . TEX-a
   LUM . LUM-a
   NMM . NMM-a
   FMP . FMP-a
   MVH . MVH-a
   OTN . OTN-a
   OME . OME-a
   CNS . CNS-a
   WTP . WTP-a
   ATP . ATP-a
   ISR . ISR-a
   COL . COL-a
   OIL . OIL-a
   OMN . OMN-a
   PPP . PPP-a
   CRP . CRP-a
   EEQ . EEQ-a
   OMF . OMF-a
   TRD . TRD-a
   OTP . OTP-a
   CMN . CMN-a
   OFI . OFI-a
   OBS . OBS-a
   ROS . ROS-a
   OSG . OSG-a
   DWE . DWE-a
/ ;

set mapcomm(iw,i) /
   AGR . AGR-c
   FOF . FOF-c
   FBP . FBP-c
   ALT . ALT-c
   PMT . PMT-c
   OGS . OGS-c
   UTI . UTI-c
   TEX . TEX-c
   LUM . LUM-c
   NMM . NMM-c
   FMP . FMP-c
   MVH . MVH-c
   OTN . OTN-c
   OME . OME-c
   CNS . CNS-c
   WTP . WTP-c
   ATP . ATP-c
   ISR . ISR-c
   COL . COL-c
   OIL . OIL-c
   OMN . OMN-c
   PPP . PPP-c
   CRP . CRP-c
   EEQ . EEQ-c
   OMF . OMF-c
   TRD . TRD-c
   OTP . OTP-c
   CMN . CMN-c
   OFI . OFI-c
   OBS . OBS-c
   ROS . ROS-c
   OSG . OSG-c
   DWE . DWE-c
/ ;

Parameters
   esubt1(iw,r)       "Top level CES substitution elasticity"
   esubc1(iw,r)       "ND nest CES substitution elasticity"
   esubva1(iw,r)      "VA nest CES substitution elasticity"

   etraq1(iw,r)       "CET make elasticity"
   esubq1(iw,r)       "CES make elasticity"

   incpar1(iw,r)      "CDE expansion parameter"
   subpar1(iw,r)      "CDE substitution parameter"

   esubg1(r)          "CES government expenditure elasticity"
   esubi1(r)          "CES investment expenditure elasticity"

   esubd1(iw,r)       "Top level Armington elasticity"
   esubm1(iw,r)       "Second level Armington elasticity"
   esubs1(iw)         "CES margin elasticity"

   etrae1(fp,r)       "CET elasticity for factors"
;


loop(mapacts(iw,a),
   esubt1(iw,r)  = esubt(a,r) ;
   esubc1(iw,r)  = esubc(a,r) ;
   esubva1(iw,r) = esubva(a,r) ;
   etraq1(iw,r)  = etraq(a,r) ;
) ;


loop(mapcomm(iw,i),
   esubq1(iw,r)  = esubq(i,r) ;
   esubd1(iw,r)  = esubd(i,r) ;
   esubm1(iw,r)  = esubm(i,r) ;
   incpar1(iw,r) = incpar(i,r) ;
   subpar1(iw,r) = subpar(i,r) ;
) ;

Execute_Unload "GTAPWElas.gdx",
   ESUBT1=ESUBT, ESUBC1=ESUBC, ESUBVA1=ESUBVA, ETRAQ1=ETRAQ,
   ESUBQ1=ESUBQ, ESUBD1=ESUBD, ESUBM1=ESUBM, INCPAR1=INCPAR, SUBPAR1=SUBPAR,
   ESUBG, ESUBI, ETRAE
;
