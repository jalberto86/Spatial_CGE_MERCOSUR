* ========================================================================================
*  etaf_v1_country_aez.inc
*
*  Final externally calibrated v1 AEZ land-supply elasticities.
*  Source: etaf_v1_country_aez.csv
*  Loaded by getData.gms AFTER the model default etaf(r,fm)=0 initialization.
*
*  Only the five focal countries are overridden here.
*  All other regions retain the model default etaf = 0.
*
*  CSV-to-model mapping embedded in these assignments:
*    ARG -> Argentina   BOL -> Bolivia   BRA -> Brazil
*    PRY -> Paraguay    URY -> Uruguay
*    numeric AEZ n -> model factor AEZn
*
*  Number of calibrated country x AEZ cells: 41
*  Zero-valued calibrated cells are retained explicitly.
* ========================================================================================

* Argentina
etaf("Argentina","AEZ3") = 0.06834620440201906 ;
etaf("Argentina","AEZ4") = 0.05 ;
etaf("Argentina","AEZ5") = 0.05 ;
etaf("Argentina","AEZ6") = 0.05 ;
etaf("Argentina","AEZ7") = 0.05 ;
etaf("Argentina","AEZ8") = 0.05 ;
etaf("Argentina","AEZ9") = 0.05 ;
etaf("Argentina","AEZ10") = 0.05 ;
etaf("Argentina","AEZ11") = 0.05 ;
etaf("Argentina","AEZ12") = 0.05 ;
etaf("Argentina","AEZ13") = 0.05 ;
etaf("Argentina","AEZ14") = 0.05 ;
etaf("Argentina","AEZ15") = 0.05 ;
etaf("Argentina","AEZ16") = 0.05 ;
etaf("Argentina","AEZ17") = 0.05 ;

* Bolivia
etaf("Bolivia","AEZ3") = 0.08474254115453185 ;
etaf("Bolivia","AEZ4") = 0.0748936025276138 ;
etaf("Bolivia","AEZ5") = 0.07563337109047379 ;
etaf("Bolivia","AEZ6") = 0.07563337109047379 ;
etaf("Bolivia","AEZ7") = 0.05 ;
etaf("Bolivia","AEZ8") = 0.060451484531472977 ;
etaf("Bolivia","AEZ9") = 0.05 ;
etaf("Bolivia","AEZ10") = 0.05642962092891481 ;
etaf("Bolivia","AEZ11") = 0.05 ;
etaf("Bolivia","AEZ12") = 0.05 ;

* Brazil
etaf("Brazil","AEZ1") = 0.17880445133796963 ;
etaf("Brazil","AEZ2") = 0.32814036392446705 ;
etaf("Brazil","AEZ3") = 0.1258291369887359 ;
etaf("Brazil","AEZ4") = 0.19562461177049206 ;
etaf("Brazil","AEZ5") = 0.14101348434370156 ;
etaf("Brazil","AEZ6") = 0.2555538616401587 ;
etaf("Brazil","AEZ10") = 0.072647436176441 ;
etaf("Brazil","AEZ11") = 0.05299476631616636 ;
etaf("Brazil","AEZ12") = 0.08645489251807026 ;

* Paraguay
etaf("Paraguay","AEZ2") = 0.5 ;
etaf("Paraguay","AEZ3") = 0.2194481380644323 ;
etaf("Paraguay","AEZ4") = 0.5 ;
etaf("Paraguay","AEZ5") = 0.30579245325970833 ;
etaf("Paraguay","AEZ6") = 0.2194481380644323 ;
etaf("Paraguay","AEZ12") = 0.2194481380644323 ;

* Uruguay
etaf("Uruguay","AEZ12") = 0.0654087008637123 ;
