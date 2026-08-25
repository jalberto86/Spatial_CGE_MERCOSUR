* ========================================================================================
* policies/trade_eu_mercosur.gms
*
* Annual bilateral tariff path for the trade-policy experiment.
*
* REQUIRED SYMBOLS (loaded before the simulation loop)
* ----------------------------------------------------
* tradeTariff(s,i,d,tradecase,t)
*    Bilateral ad-valorem tariff rate in DECIMAL units.
*
* tradeTariffData(s,i,d,tradecase,t)
*    Set identifying cells explicitly supplied by the tariff workbook.
*
* tradecase
*    / baseline_no_cooperation, cooperation_eu_mercosur /
*
* REQUIRED RUN SWITCH
* -------------------
* scalar tradeShock
*    0 = baseline_no_cooperation
*    1 = cooperation_eu_mercosur
*
* TIMING
* ------
* This file is included inside loop(tsim,...) AFTER iterloop.gms.
* iterloop.gms first carries the previous imptx level forward. This policy then
* overwrites only the bilateral cells supplied by the tariff input for tsim.
*
* Cells not present in the workbook are left unchanged.
* Explicit zero tariffs in the workbook are valid and are applied.
*
* The workbook paths begin in 2019. Therefore 2017-2018 are untouched.
* ========================================================================================

if(tradeShock,

*  T / TC: EU-Mercosur cooperation tariff path.
   imptx.fx(s,i,d,tsim)$(
      xwFlag(s,i,d)
      and tradeTariffData(s,i,d,"cooperation_eu_mercosur",tsim)
   )
      = tradeTariff(s,i,d,"cooperation_eu_mercosur",tsim) ;

else

*  B / C: no-cooperation tariff path.
   imptx.fx(s,i,d,tsim)$(
      xwFlag(s,i,d)
      and tradeTariffData(s,i,d,"baseline_no_cooperation",tsim)
   )
      = tradeTariff(s,i,d,"baseline_no_cooperation",tsim) ;

) ;
