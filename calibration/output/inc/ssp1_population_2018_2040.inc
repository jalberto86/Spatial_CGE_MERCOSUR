* =============================================================================
* SSP1 population-driven socioeconomic path
*
* Population and labor supply grow at the same annual SSP population rate.
* No GDP target. No afeall. No DynCal.
* Include inside loop(tsim,...) after iterloop.gms.
* Base year 2017 remains fixed in model.gms.
* =============================================================================

* --- 2018 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2018") = pop.l("Argentina","2017") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2018") = aft("Argentina",l,"2017") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2018") = pop.l("Bolivia","2017") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2018") = aft("Bolivia",l,"2017") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2018") = pop.l("Brazil","2017") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2018") = aft("Brazil",l,"2017") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2018") = pop.l("China","2017") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2018") = aft("China",l,"2017") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2018") = pop.l("EU27","2017") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2018") = aft("EU27",l,"2017") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2018") = pop.l("Paraguay","2017") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2018") = aft("Paraguay",l,"2017") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2018") = pop.l("ROW","2017") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2018") = aft("ROW",l,"2017") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2018") = pop.l("RestLatAm","2017") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2018") = aft("RestLatAm",l,"2017") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2018") = pop.l("US","2017") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2018") = aft("US",l,"2017") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2018") = pop.l("Uruguay","2017") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2018") = aft("Uruguay",l,"2017") * 1.00005755049;

* --- 2019 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2019") = pop.l("Argentina","2018") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2019") = aft("Argentina",l,"2018") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2019") = pop.l("Bolivia","2018") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2019") = aft("Bolivia",l,"2018") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2019") = pop.l("Brazil","2018") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2019") = aft("Brazil",l,"2018") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2019") = pop.l("China","2018") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2019") = aft("China",l,"2018") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2019") = pop.l("EU27","2018") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2019") = aft("EU27",l,"2018") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2019") = pop.l("Paraguay","2018") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2019") = aft("Paraguay",l,"2018") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2019") = pop.l("ROW","2018") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2019") = aft("ROW",l,"2018") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2019") = pop.l("RestLatAm","2018") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2019") = aft("RestLatAm",l,"2018") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2019") = pop.l("US","2018") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2019") = aft("US",l,"2018") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2019") = pop.l("Uruguay","2018") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2019") = aft("Uruguay",l,"2018") * 1.00005755049;

* --- 2020 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2020") = pop.l("Argentina","2019") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2020") = aft("Argentina",l,"2019") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2020") = pop.l("Bolivia","2019") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2020") = aft("Bolivia",l,"2019") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2020") = pop.l("Brazil","2019") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2020") = aft("Brazil",l,"2019") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2020") = pop.l("China","2019") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2020") = aft("China",l,"2019") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2020") = pop.l("EU27","2019") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2020") = aft("EU27",l,"2019") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2020") = pop.l("Paraguay","2019") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2020") = aft("Paraguay",l,"2019") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2020") = pop.l("ROW","2019") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2020") = aft("ROW",l,"2019") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2020") = pop.l("RestLatAm","2019") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2020") = aft("RestLatAm",l,"2019") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2020") = pop.l("US","2019") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2020") = aft("US",l,"2019") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2020") = pop.l("Uruguay","2019") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2020") = aft("Uruguay",l,"2019") * 1.00005755049;

* --- 2021 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2021") = pop.l("Argentina","2020") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2021") = aft("Argentina",l,"2020") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2021") = pop.l("Bolivia","2020") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2021") = aft("Bolivia",l,"2020") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2021") = pop.l("Brazil","2020") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2021") = aft("Brazil",l,"2020") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2021") = pop.l("China","2020") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2021") = aft("China",l,"2020") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2021") = pop.l("EU27","2020") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2021") = aft("EU27",l,"2020") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2021") = pop.l("Paraguay","2020") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2021") = aft("Paraguay",l,"2020") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2021") = pop.l("ROW","2020") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2021") = aft("ROW",l,"2020") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2021") = pop.l("RestLatAm","2020") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2021") = aft("RestLatAm",l,"2020") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2021") = pop.l("US","2020") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2021") = aft("US",l,"2020") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2021") = pop.l("Uruguay","2020") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2021") = aft("Uruguay",l,"2020") * 1.00005755049;

* --- 2022 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2022") = pop.l("Argentina","2021") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2022") = aft("Argentina",l,"2021") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2022") = pop.l("Bolivia","2021") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2022") = aft("Bolivia",l,"2021") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2022") = pop.l("Brazil","2021") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2022") = aft("Brazil",l,"2021") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2022") = pop.l("China","2021") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2022") = aft("China",l,"2021") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2022") = pop.l("EU27","2021") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2022") = aft("EU27",l,"2021") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2022") = pop.l("Paraguay","2021") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2022") = aft("Paraguay",l,"2021") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2022") = pop.l("ROW","2021") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2022") = aft("ROW",l,"2021") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2022") = pop.l("RestLatAm","2021") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2022") = aft("RestLatAm",l,"2021") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2022") = pop.l("US","2021") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2022") = aft("US",l,"2021") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2022") = pop.l("Uruguay","2021") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2022") = aft("Uruguay",l,"2021") * 1.00005755049;

* --- 2023 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2023") = pop.l("Argentina","2022") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2023") = aft("Argentina",l,"2022") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2023") = pop.l("Bolivia","2022") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2023") = aft("Bolivia",l,"2022") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2023") = pop.l("Brazil","2022") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2023") = aft("Brazil",l,"2022") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2023") = pop.l("China","2022") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2023") = aft("China",l,"2022") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2023") = pop.l("EU27","2022") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2023") = aft("EU27",l,"2022") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2023") = pop.l("Paraguay","2022") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2023") = aft("Paraguay",l,"2022") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2023") = pop.l("ROW","2022") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2023") = aft("ROW",l,"2022") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2023") = pop.l("RestLatAm","2022") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2023") = aft("RestLatAm",l,"2022") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2023") = pop.l("US","2022") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2023") = aft("US",l,"2022") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2023") = pop.l("Uruguay","2022") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2023") = aft("Uruguay",l,"2022") * 1.00005755049;

* --- 2024 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2024") = pop.l("Argentina","2023") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2024") = aft("Argentina",l,"2023") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2024") = pop.l("Bolivia","2023") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2024") = aft("Bolivia",l,"2023") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2024") = pop.l("Brazil","2023") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2024") = aft("Brazil",l,"2023") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2024") = pop.l("China","2023") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2024") = aft("China",l,"2023") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2024") = pop.l("EU27","2023") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2024") = aft("EU27",l,"2023") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2024") = pop.l("Paraguay","2023") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2024") = aft("Paraguay",l,"2023") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2024") = pop.l("ROW","2023") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2024") = aft("ROW",l,"2023") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2024") = pop.l("RestLatAm","2023") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2024") = aft("RestLatAm",l,"2023") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2024") = pop.l("US","2023") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2024") = aft("US",l,"2023") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2024") = pop.l("Uruguay","2023") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2024") = aft("Uruguay",l,"2023") * 1.00005755049;

* --- 2025 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2025") = pop.l("Argentina","2024") * 1.00632828093;
aft("Argentina",l,tsim)$sameas(tsim,"2025") = aft("Argentina",l,"2024") * 1.00632828093;
pop.fx("Bolivia",tsim)$sameas(tsim,"2025") = pop.l("Bolivia","2024") * 1.01346536454;
aft("Bolivia",l,tsim)$sameas(tsim,"2025") = aft("Bolivia",l,"2024") * 1.01346536454;
pop.fx("Brazil",tsim)$sameas(tsim,"2025") = pop.l("Brazil","2024") * 1.00587426022;
aft("Brazil",l,tsim)$sameas(tsim,"2025") = aft("Brazil",l,"2024") * 1.00587426022;
pop.fx("China",tsim)$sameas(tsim,"2025") = pop.l("China","2024") * 1.0020333777;
aft("China",l,tsim)$sameas(tsim,"2025") = aft("China",l,"2024") * 1.0020333777;
pop.fx("EU27",tsim)$sameas(tsim,"2025") = pop.l("EU27","2024") * 1.0007198321;
aft("EU27",l,tsim)$sameas(tsim,"2025") = aft("EU27",l,"2024") * 1.0007198321;
pop.fx("Paraguay",tsim)$sameas(tsim,"2025") = pop.l("Paraguay","2024") * 1.01320049603;
aft("Paraguay",l,tsim)$sameas(tsim,"2025") = aft("Paraguay",l,"2024") * 1.01320049603;
pop.fx("ROW",tsim)$sameas(tsim,"2025") = pop.l("ROW","2024") * 1.01317791134;
aft("ROW",l,tsim)$sameas(tsim,"2025") = aft("ROW",l,"2024") * 1.01317791134;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2025") = pop.l("RestLatAm","2024") * 1.00875404676;
aft("RestLatAm",l,tsim)$sameas(tsim,"2025") = aft("RestLatAm",l,"2024") * 1.00875404676;
pop.fx("US",tsim)$sameas(tsim,"2025") = pop.l("US","2024") * 1.00518429832;
aft("US",l,tsim)$sameas(tsim,"2025") = aft("US",l,"2024") * 1.00518429832;
pop.fx("Uruguay",tsim)$sameas(tsim,"2025") = pop.l("Uruguay","2024") * 1.00005755049;
aft("Uruguay",l,tsim)$sameas(tsim,"2025") = aft("Uruguay",l,"2024") * 1.00005755049;

* --- 2026 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2026") = pop.l("Argentina","2025") * 1.00421649516;
aft("Argentina",l,tsim)$sameas(tsim,"2026") = aft("Argentina",l,"2025") * 1.00421649516;
pop.fx("Bolivia",tsim)$sameas(tsim,"2026") = pop.l("Bolivia","2025") * 1.01097302701;
aft("Bolivia",l,tsim)$sameas(tsim,"2026") = aft("Bolivia",l,"2025") * 1.01097302701;
pop.fx("Brazil",tsim)$sameas(tsim,"2026") = pop.l("Brazil","2025") * 1.00355054662;
aft("Brazil",l,tsim)$sameas(tsim,"2026") = aft("Brazil",l,"2025") * 1.00355054662;
pop.fx("China",tsim)$sameas(tsim,"2026") = pop.l("China","2025") * 0.998810204498;
aft("China",l,tsim)$sameas(tsim,"2026") = aft("China",l,"2025") * 0.998810204498;
pop.fx("EU27",tsim)$sameas(tsim,"2026") = pop.l("EU27","2025") * 0.999318825992;
aft("EU27",l,tsim)$sameas(tsim,"2026") = aft("EU27",l,"2025") * 0.999318825992;
pop.fx("Paraguay",tsim)$sameas(tsim,"2026") = pop.l("Paraguay","2025") * 1.01009061009;
aft("Paraguay",l,tsim)$sameas(tsim,"2026") = aft("Paraguay",l,"2025") * 1.01009061009;
pop.fx("ROW",tsim)$sameas(tsim,"2026") = pop.l("ROW","2025") * 1.01054250575;
aft("ROW",l,tsim)$sameas(tsim,"2026") = aft("ROW",l,"2025") * 1.01054250575;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2026") = pop.l("RestLatAm","2025") * 1.00656901485;
aft("RestLatAm",l,tsim)$sameas(tsim,"2026") = aft("RestLatAm",l,"2025") * 1.00656901485;
pop.fx("US",tsim)$sameas(tsim,"2026") = pop.l("US","2025") * 1.00456934681;
aft("US",l,tsim)$sameas(tsim,"2026") = aft("US",l,"2025") * 1.00456934681;
pop.fx("Uruguay",tsim)$sameas(tsim,"2026") = pop.l("Uruguay","2025") * 0.998848663913;
aft("Uruguay",l,tsim)$sameas(tsim,"2026") = aft("Uruguay",l,"2025") * 0.998848663913;

* --- 2027 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2027") = pop.l("Argentina","2026") * 1.00421649516;
aft("Argentina",l,tsim)$sameas(tsim,"2027") = aft("Argentina",l,"2026") * 1.00421649516;
pop.fx("Bolivia",tsim)$sameas(tsim,"2027") = pop.l("Bolivia","2026") * 1.01097302701;
aft("Bolivia",l,tsim)$sameas(tsim,"2027") = aft("Bolivia",l,"2026") * 1.01097302701;
pop.fx("Brazil",tsim)$sameas(tsim,"2027") = pop.l("Brazil","2026") * 1.00355054662;
aft("Brazil",l,tsim)$sameas(tsim,"2027") = aft("Brazil",l,"2026") * 1.00355054662;
pop.fx("China",tsim)$sameas(tsim,"2027") = pop.l("China","2026") * 0.998810204498;
aft("China",l,tsim)$sameas(tsim,"2027") = aft("China",l,"2026") * 0.998810204498;
pop.fx("EU27",tsim)$sameas(tsim,"2027") = pop.l("EU27","2026") * 0.999318825992;
aft("EU27",l,tsim)$sameas(tsim,"2027") = aft("EU27",l,"2026") * 0.999318825992;
pop.fx("Paraguay",tsim)$sameas(tsim,"2027") = pop.l("Paraguay","2026") * 1.01009061009;
aft("Paraguay",l,tsim)$sameas(tsim,"2027") = aft("Paraguay",l,"2026") * 1.01009061009;
pop.fx("ROW",tsim)$sameas(tsim,"2027") = pop.l("ROW","2026") * 1.01054250575;
aft("ROW",l,tsim)$sameas(tsim,"2027") = aft("ROW",l,"2026") * 1.01054250575;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2027") = pop.l("RestLatAm","2026") * 1.00656901485;
aft("RestLatAm",l,tsim)$sameas(tsim,"2027") = aft("RestLatAm",l,"2026") * 1.00656901485;
pop.fx("US",tsim)$sameas(tsim,"2027") = pop.l("US","2026") * 1.00456934681;
aft("US",l,tsim)$sameas(tsim,"2027") = aft("US",l,"2026") * 1.00456934681;
pop.fx("Uruguay",tsim)$sameas(tsim,"2027") = pop.l("Uruguay","2026") * 0.998848663913;
aft("Uruguay",l,tsim)$sameas(tsim,"2027") = aft("Uruguay",l,"2026") * 0.998848663913;

* --- 2028 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2028") = pop.l("Argentina","2027") * 1.00421649516;
aft("Argentina",l,tsim)$sameas(tsim,"2028") = aft("Argentina",l,"2027") * 1.00421649516;
pop.fx("Bolivia",tsim)$sameas(tsim,"2028") = pop.l("Bolivia","2027") * 1.01097302701;
aft("Bolivia",l,tsim)$sameas(tsim,"2028") = aft("Bolivia",l,"2027") * 1.01097302701;
pop.fx("Brazil",tsim)$sameas(tsim,"2028") = pop.l("Brazil","2027") * 1.00355054662;
aft("Brazil",l,tsim)$sameas(tsim,"2028") = aft("Brazil",l,"2027") * 1.00355054662;
pop.fx("China",tsim)$sameas(tsim,"2028") = pop.l("China","2027") * 0.998810204498;
aft("China",l,tsim)$sameas(tsim,"2028") = aft("China",l,"2027") * 0.998810204498;
pop.fx("EU27",tsim)$sameas(tsim,"2028") = pop.l("EU27","2027") * 0.999318825992;
aft("EU27",l,tsim)$sameas(tsim,"2028") = aft("EU27",l,"2027") * 0.999318825992;
pop.fx("Paraguay",tsim)$sameas(tsim,"2028") = pop.l("Paraguay","2027") * 1.01009061009;
aft("Paraguay",l,tsim)$sameas(tsim,"2028") = aft("Paraguay",l,"2027") * 1.01009061009;
pop.fx("ROW",tsim)$sameas(tsim,"2028") = pop.l("ROW","2027") * 1.01054250575;
aft("ROW",l,tsim)$sameas(tsim,"2028") = aft("ROW",l,"2027") * 1.01054250575;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2028") = pop.l("RestLatAm","2027") * 1.00656901485;
aft("RestLatAm",l,tsim)$sameas(tsim,"2028") = aft("RestLatAm",l,"2027") * 1.00656901485;
pop.fx("US",tsim)$sameas(tsim,"2028") = pop.l("US","2027") * 1.00456934681;
aft("US",l,tsim)$sameas(tsim,"2028") = aft("US",l,"2027") * 1.00456934681;
pop.fx("Uruguay",tsim)$sameas(tsim,"2028") = pop.l("Uruguay","2027") * 0.998848663913;
aft("Uruguay",l,tsim)$sameas(tsim,"2028") = aft("Uruguay",l,"2027") * 0.998848663913;

* --- 2029 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2029") = pop.l("Argentina","2028") * 1.00421649516;
aft("Argentina",l,tsim)$sameas(tsim,"2029") = aft("Argentina",l,"2028") * 1.00421649516;
pop.fx("Bolivia",tsim)$sameas(tsim,"2029") = pop.l("Bolivia","2028") * 1.01097302701;
aft("Bolivia",l,tsim)$sameas(tsim,"2029") = aft("Bolivia",l,"2028") * 1.01097302701;
pop.fx("Brazil",tsim)$sameas(tsim,"2029") = pop.l("Brazil","2028") * 1.00355054662;
aft("Brazil",l,tsim)$sameas(tsim,"2029") = aft("Brazil",l,"2028") * 1.00355054662;
pop.fx("China",tsim)$sameas(tsim,"2029") = pop.l("China","2028") * 0.998810204498;
aft("China",l,tsim)$sameas(tsim,"2029") = aft("China",l,"2028") * 0.998810204498;
pop.fx("EU27",tsim)$sameas(tsim,"2029") = pop.l("EU27","2028") * 0.999318825992;
aft("EU27",l,tsim)$sameas(tsim,"2029") = aft("EU27",l,"2028") * 0.999318825992;
pop.fx("Paraguay",tsim)$sameas(tsim,"2029") = pop.l("Paraguay","2028") * 1.01009061009;
aft("Paraguay",l,tsim)$sameas(tsim,"2029") = aft("Paraguay",l,"2028") * 1.01009061009;
pop.fx("ROW",tsim)$sameas(tsim,"2029") = pop.l("ROW","2028") * 1.01054250575;
aft("ROW",l,tsim)$sameas(tsim,"2029") = aft("ROW",l,"2028") * 1.01054250575;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2029") = pop.l("RestLatAm","2028") * 1.00656901485;
aft("RestLatAm",l,tsim)$sameas(tsim,"2029") = aft("RestLatAm",l,"2028") * 1.00656901485;
pop.fx("US",tsim)$sameas(tsim,"2029") = pop.l("US","2028") * 1.00456934681;
aft("US",l,tsim)$sameas(tsim,"2029") = aft("US",l,"2028") * 1.00456934681;
pop.fx("Uruguay",tsim)$sameas(tsim,"2029") = pop.l("Uruguay","2028") * 0.998848663913;
aft("Uruguay",l,tsim)$sameas(tsim,"2029") = aft("Uruguay",l,"2028") * 0.998848663913;

* --- 2030 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2030") = pop.l("Argentina","2029") * 1.00421649516;
aft("Argentina",l,tsim)$sameas(tsim,"2030") = aft("Argentina",l,"2029") * 1.00421649516;
pop.fx("Bolivia",tsim)$sameas(tsim,"2030") = pop.l("Bolivia","2029") * 1.01097302701;
aft("Bolivia",l,tsim)$sameas(tsim,"2030") = aft("Bolivia",l,"2029") * 1.01097302701;
pop.fx("Brazil",tsim)$sameas(tsim,"2030") = pop.l("Brazil","2029") * 1.00355054662;
aft("Brazil",l,tsim)$sameas(tsim,"2030") = aft("Brazil",l,"2029") * 1.00355054662;
pop.fx("China",tsim)$sameas(tsim,"2030") = pop.l("China","2029") * 0.998810204498;
aft("China",l,tsim)$sameas(tsim,"2030") = aft("China",l,"2029") * 0.998810204498;
pop.fx("EU27",tsim)$sameas(tsim,"2030") = pop.l("EU27","2029") * 0.999318825992;
aft("EU27",l,tsim)$sameas(tsim,"2030") = aft("EU27",l,"2029") * 0.999318825992;
pop.fx("Paraguay",tsim)$sameas(tsim,"2030") = pop.l("Paraguay","2029") * 1.01009061009;
aft("Paraguay",l,tsim)$sameas(tsim,"2030") = aft("Paraguay",l,"2029") * 1.01009061009;
pop.fx("ROW",tsim)$sameas(tsim,"2030") = pop.l("ROW","2029") * 1.01054250575;
aft("ROW",l,tsim)$sameas(tsim,"2030") = aft("ROW",l,"2029") * 1.01054250575;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2030") = pop.l("RestLatAm","2029") * 1.00656901485;
aft("RestLatAm",l,tsim)$sameas(tsim,"2030") = aft("RestLatAm",l,"2029") * 1.00656901485;
pop.fx("US",tsim)$sameas(tsim,"2030") = pop.l("US","2029") * 1.00456934681;
aft("US",l,tsim)$sameas(tsim,"2030") = aft("US",l,"2029") * 1.00456934681;
pop.fx("Uruguay",tsim)$sameas(tsim,"2030") = pop.l("Uruguay","2029") * 0.998848663913;
aft("Uruguay",l,tsim)$sameas(tsim,"2030") = aft("Uruguay",l,"2029") * 0.998848663913;

* --- 2031 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2031") = pop.l("Argentina","2030") * 1.00323762566;
aft("Argentina",l,tsim)$sameas(tsim,"2031") = aft("Argentina",l,"2030") * 1.00323762566;
pop.fx("Bolivia",tsim)$sameas(tsim,"2031") = pop.l("Bolivia","2030") * 1.00876012367;
aft("Bolivia",l,tsim)$sameas(tsim,"2031") = aft("Bolivia",l,"2030") * 1.00876012367;
pop.fx("Brazil",tsim)$sameas(tsim,"2031") = pop.l("Brazil","2030") * 1.00209686788;
aft("Brazil",l,tsim)$sameas(tsim,"2031") = aft("Brazil",l,"2030") * 1.00209686788;
pop.fx("China",tsim)$sameas(tsim,"2031") = pop.l("China","2030") * 0.99783098874;
aft("China",l,tsim)$sameas(tsim,"2031") = aft("China",l,"2030") * 0.99783098874;
pop.fx("EU27",tsim)$sameas(tsim,"2031") = pop.l("EU27","2030") * 0.999383398193;
aft("EU27",l,tsim)$sameas(tsim,"2031") = aft("EU27",l,"2030") * 0.999383398193;
pop.fx("Paraguay",tsim)$sameas(tsim,"2031") = pop.l("Paraguay","2030") * 1.0073850642;
aft("Paraguay",l,tsim)$sameas(tsim,"2031") = aft("Paraguay",l,"2030") * 1.0073850642;
pop.fx("ROW",tsim)$sameas(tsim,"2031") = pop.l("ROW","2030") * 1.00857163917;
aft("ROW",l,tsim)$sameas(tsim,"2031") = aft("ROW",l,"2030") * 1.00857163917;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2031") = pop.l("RestLatAm","2030") * 1.00476415762;
aft("RestLatAm",l,tsim)$sameas(tsim,"2031") = aft("RestLatAm",l,"2030") * 1.00476415762;
pop.fx("US",tsim)$sameas(tsim,"2031") = pop.l("US","2030") * 1.00428157927;
aft("US",l,tsim)$sameas(tsim,"2031") = aft("US",l,"2030") * 1.00428157927;
pop.fx("Uruguay",tsim)$sameas(tsim,"2031") = pop.l("Uruguay","2030") * 0.998257443444;
aft("Uruguay",l,tsim)$sameas(tsim,"2031") = aft("Uruguay",l,"2030") * 0.998257443444;

* --- 2032 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2032") = pop.l("Argentina","2031") * 1.00323762566;
aft("Argentina",l,tsim)$sameas(tsim,"2032") = aft("Argentina",l,"2031") * 1.00323762566;
pop.fx("Bolivia",tsim)$sameas(tsim,"2032") = pop.l("Bolivia","2031") * 1.00876012367;
aft("Bolivia",l,tsim)$sameas(tsim,"2032") = aft("Bolivia",l,"2031") * 1.00876012367;
pop.fx("Brazil",tsim)$sameas(tsim,"2032") = pop.l("Brazil","2031") * 1.00209686788;
aft("Brazil",l,tsim)$sameas(tsim,"2032") = aft("Brazil",l,"2031") * 1.00209686788;
pop.fx("China",tsim)$sameas(tsim,"2032") = pop.l("China","2031") * 0.99783098874;
aft("China",l,tsim)$sameas(tsim,"2032") = aft("China",l,"2031") * 0.99783098874;
pop.fx("EU27",tsim)$sameas(tsim,"2032") = pop.l("EU27","2031") * 0.999383398193;
aft("EU27",l,tsim)$sameas(tsim,"2032") = aft("EU27",l,"2031") * 0.999383398193;
pop.fx("Paraguay",tsim)$sameas(tsim,"2032") = pop.l("Paraguay","2031") * 1.0073850642;
aft("Paraguay",l,tsim)$sameas(tsim,"2032") = aft("Paraguay",l,"2031") * 1.0073850642;
pop.fx("ROW",tsim)$sameas(tsim,"2032") = pop.l("ROW","2031") * 1.00857163917;
aft("ROW",l,tsim)$sameas(tsim,"2032") = aft("ROW",l,"2031") * 1.00857163917;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2032") = pop.l("RestLatAm","2031") * 1.00476415762;
aft("RestLatAm",l,tsim)$sameas(tsim,"2032") = aft("RestLatAm",l,"2031") * 1.00476415762;
pop.fx("US",tsim)$sameas(tsim,"2032") = pop.l("US","2031") * 1.00428157927;
aft("US",l,tsim)$sameas(tsim,"2032") = aft("US",l,"2031") * 1.00428157927;
pop.fx("Uruguay",tsim)$sameas(tsim,"2032") = pop.l("Uruguay","2031") * 0.998257443444;
aft("Uruguay",l,tsim)$sameas(tsim,"2032") = aft("Uruguay",l,"2031") * 0.998257443444;

* --- 2033 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2033") = pop.l("Argentina","2032") * 1.00323762566;
aft("Argentina",l,tsim)$sameas(tsim,"2033") = aft("Argentina",l,"2032") * 1.00323762566;
pop.fx("Bolivia",tsim)$sameas(tsim,"2033") = pop.l("Bolivia","2032") * 1.00876012367;
aft("Bolivia",l,tsim)$sameas(tsim,"2033") = aft("Bolivia",l,"2032") * 1.00876012367;
pop.fx("Brazil",tsim)$sameas(tsim,"2033") = pop.l("Brazil","2032") * 1.00209686788;
aft("Brazil",l,tsim)$sameas(tsim,"2033") = aft("Brazil",l,"2032") * 1.00209686788;
pop.fx("China",tsim)$sameas(tsim,"2033") = pop.l("China","2032") * 0.99783098874;
aft("China",l,tsim)$sameas(tsim,"2033") = aft("China",l,"2032") * 0.99783098874;
pop.fx("EU27",tsim)$sameas(tsim,"2033") = pop.l("EU27","2032") * 0.999383398193;
aft("EU27",l,tsim)$sameas(tsim,"2033") = aft("EU27",l,"2032") * 0.999383398193;
pop.fx("Paraguay",tsim)$sameas(tsim,"2033") = pop.l("Paraguay","2032") * 1.0073850642;
aft("Paraguay",l,tsim)$sameas(tsim,"2033") = aft("Paraguay",l,"2032") * 1.0073850642;
pop.fx("ROW",tsim)$sameas(tsim,"2033") = pop.l("ROW","2032") * 1.00857163917;
aft("ROW",l,tsim)$sameas(tsim,"2033") = aft("ROW",l,"2032") * 1.00857163917;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2033") = pop.l("RestLatAm","2032") * 1.00476415762;
aft("RestLatAm",l,tsim)$sameas(tsim,"2033") = aft("RestLatAm",l,"2032") * 1.00476415762;
pop.fx("US",tsim)$sameas(tsim,"2033") = pop.l("US","2032") * 1.00428157927;
aft("US",l,tsim)$sameas(tsim,"2033") = aft("US",l,"2032") * 1.00428157927;
pop.fx("Uruguay",tsim)$sameas(tsim,"2033") = pop.l("Uruguay","2032") * 0.998257443444;
aft("Uruguay",l,tsim)$sameas(tsim,"2033") = aft("Uruguay",l,"2032") * 0.998257443444;

* --- 2034 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2034") = pop.l("Argentina","2033") * 1.00323762566;
aft("Argentina",l,tsim)$sameas(tsim,"2034") = aft("Argentina",l,"2033") * 1.00323762566;
pop.fx("Bolivia",tsim)$sameas(tsim,"2034") = pop.l("Bolivia","2033") * 1.00876012367;
aft("Bolivia",l,tsim)$sameas(tsim,"2034") = aft("Bolivia",l,"2033") * 1.00876012367;
pop.fx("Brazil",tsim)$sameas(tsim,"2034") = pop.l("Brazil","2033") * 1.00209686788;
aft("Brazil",l,tsim)$sameas(tsim,"2034") = aft("Brazil",l,"2033") * 1.00209686788;
pop.fx("China",tsim)$sameas(tsim,"2034") = pop.l("China","2033") * 0.99783098874;
aft("China",l,tsim)$sameas(tsim,"2034") = aft("China",l,"2033") * 0.99783098874;
pop.fx("EU27",tsim)$sameas(tsim,"2034") = pop.l("EU27","2033") * 0.999383398193;
aft("EU27",l,tsim)$sameas(tsim,"2034") = aft("EU27",l,"2033") * 0.999383398193;
pop.fx("Paraguay",tsim)$sameas(tsim,"2034") = pop.l("Paraguay","2033") * 1.0073850642;
aft("Paraguay",l,tsim)$sameas(tsim,"2034") = aft("Paraguay",l,"2033") * 1.0073850642;
pop.fx("ROW",tsim)$sameas(tsim,"2034") = pop.l("ROW","2033") * 1.00857163917;
aft("ROW",l,tsim)$sameas(tsim,"2034") = aft("ROW",l,"2033") * 1.00857163917;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2034") = pop.l("RestLatAm","2033") * 1.00476415762;
aft("RestLatAm",l,tsim)$sameas(tsim,"2034") = aft("RestLatAm",l,"2033") * 1.00476415762;
pop.fx("US",tsim)$sameas(tsim,"2034") = pop.l("US","2033") * 1.00428157927;
aft("US",l,tsim)$sameas(tsim,"2034") = aft("US",l,"2033") * 1.00428157927;
pop.fx("Uruguay",tsim)$sameas(tsim,"2034") = pop.l("Uruguay","2033") * 0.998257443444;
aft("Uruguay",l,tsim)$sameas(tsim,"2034") = aft("Uruguay",l,"2033") * 0.998257443444;

* --- 2035 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2035") = pop.l("Argentina","2034") * 1.00323762566;
aft("Argentina",l,tsim)$sameas(tsim,"2035") = aft("Argentina",l,"2034") * 1.00323762566;
pop.fx("Bolivia",tsim)$sameas(tsim,"2035") = pop.l("Bolivia","2034") * 1.00876012367;
aft("Bolivia",l,tsim)$sameas(tsim,"2035") = aft("Bolivia",l,"2034") * 1.00876012367;
pop.fx("Brazil",tsim)$sameas(tsim,"2035") = pop.l("Brazil","2034") * 1.00209686788;
aft("Brazil",l,tsim)$sameas(tsim,"2035") = aft("Brazil",l,"2034") * 1.00209686788;
pop.fx("China",tsim)$sameas(tsim,"2035") = pop.l("China","2034") * 0.99783098874;
aft("China",l,tsim)$sameas(tsim,"2035") = aft("China",l,"2034") * 0.99783098874;
pop.fx("EU27",tsim)$sameas(tsim,"2035") = pop.l("EU27","2034") * 0.999383398193;
aft("EU27",l,tsim)$sameas(tsim,"2035") = aft("EU27",l,"2034") * 0.999383398193;
pop.fx("Paraguay",tsim)$sameas(tsim,"2035") = pop.l("Paraguay","2034") * 1.0073850642;
aft("Paraguay",l,tsim)$sameas(tsim,"2035") = aft("Paraguay",l,"2034") * 1.0073850642;
pop.fx("ROW",tsim)$sameas(tsim,"2035") = pop.l("ROW","2034") * 1.00857163917;
aft("ROW",l,tsim)$sameas(tsim,"2035") = aft("ROW",l,"2034") * 1.00857163917;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2035") = pop.l("RestLatAm","2034") * 1.00476415762;
aft("RestLatAm",l,tsim)$sameas(tsim,"2035") = aft("RestLatAm",l,"2034") * 1.00476415762;
pop.fx("US",tsim)$sameas(tsim,"2035") = pop.l("US","2034") * 1.00428157927;
aft("US",l,tsim)$sameas(tsim,"2035") = aft("US",l,"2034") * 1.00428157927;
pop.fx("Uruguay",tsim)$sameas(tsim,"2035") = pop.l("Uruguay","2034") * 0.998257443444;
aft("Uruguay",l,tsim)$sameas(tsim,"2035") = aft("Uruguay",l,"2034") * 0.998257443444;

* --- 2036 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2036") = pop.l("Argentina","2035") * 1.00235761204;
aft("Argentina",l,tsim)$sameas(tsim,"2036") = aft("Argentina",l,"2035") * 1.00235761204;
pop.fx("Bolivia",tsim)$sameas(tsim,"2036") = pop.l("Bolivia","2035") * 1.00666618288;
aft("Bolivia",l,tsim)$sameas(tsim,"2036") = aft("Bolivia",l,"2035") * 1.00666618288;
pop.fx("Brazil",tsim)$sameas(tsim,"2036") = pop.l("Brazil","2035") * 1.00074400935;
aft("Brazil",l,tsim)$sameas(tsim,"2036") = aft("Brazil",l,"2035") * 1.00074400935;
pop.fx("China",tsim)$sameas(tsim,"2036") = pop.l("China","2035") * 0.997105819665;
aft("China",l,tsim)$sameas(tsim,"2036") = aft("China",l,"2035") * 0.997105819665;
pop.fx("EU27",tsim)$sameas(tsim,"2036") = pop.l("EU27","2035") * 0.999503044467;
aft("EU27",l,tsim)$sameas(tsim,"2036") = aft("EU27",l,"2035") * 0.999503044467;
pop.fx("Paraguay",tsim)$sameas(tsim,"2036") = pop.l("Paraguay","2035") * 1.00549546099;
aft("Paraguay",l,tsim)$sameas(tsim,"2036") = aft("Paraguay",l,"2035") * 1.00549546099;
pop.fx("ROW",tsim)$sameas(tsim,"2036") = pop.l("ROW","2035") * 1.00702723183;
aft("ROW",l,tsim)$sameas(tsim,"2036") = aft("ROW",l,"2035") * 1.00702723183;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2036") = pop.l("RestLatAm","2035") * 1.00315881355;
aft("RestLatAm",l,tsim)$sameas(tsim,"2036") = aft("RestLatAm",l,"2035") * 1.00315881355;
pop.fx("US",tsim)$sameas(tsim,"2036") = pop.l("US","2035") * 1.0039233534;
aft("US",l,tsim)$sameas(tsim,"2036") = aft("US",l,"2035") * 1.0039233534;
pop.fx("Uruguay",tsim)$sameas(tsim,"2036") = pop.l("Uruguay","2035") * 0.9975909083;
aft("Uruguay",l,tsim)$sameas(tsim,"2036") = aft("Uruguay",l,"2035") * 0.9975909083;

* --- 2037 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2037") = pop.l("Argentina","2036") * 1.00235761204;
aft("Argentina",l,tsim)$sameas(tsim,"2037") = aft("Argentina",l,"2036") * 1.00235761204;
pop.fx("Bolivia",tsim)$sameas(tsim,"2037") = pop.l("Bolivia","2036") * 1.00666618288;
aft("Bolivia",l,tsim)$sameas(tsim,"2037") = aft("Bolivia",l,"2036") * 1.00666618288;
pop.fx("Brazil",tsim)$sameas(tsim,"2037") = pop.l("Brazil","2036") * 1.00074400935;
aft("Brazil",l,tsim)$sameas(tsim,"2037") = aft("Brazil",l,"2036") * 1.00074400935;
pop.fx("China",tsim)$sameas(tsim,"2037") = pop.l("China","2036") * 0.997105819665;
aft("China",l,tsim)$sameas(tsim,"2037") = aft("China",l,"2036") * 0.997105819665;
pop.fx("EU27",tsim)$sameas(tsim,"2037") = pop.l("EU27","2036") * 0.999503044467;
aft("EU27",l,tsim)$sameas(tsim,"2037") = aft("EU27",l,"2036") * 0.999503044467;
pop.fx("Paraguay",tsim)$sameas(tsim,"2037") = pop.l("Paraguay","2036") * 1.00549546099;
aft("Paraguay",l,tsim)$sameas(tsim,"2037") = aft("Paraguay",l,"2036") * 1.00549546099;
pop.fx("ROW",tsim)$sameas(tsim,"2037") = pop.l("ROW","2036") * 1.00702723183;
aft("ROW",l,tsim)$sameas(tsim,"2037") = aft("ROW",l,"2036") * 1.00702723183;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2037") = pop.l("RestLatAm","2036") * 1.00315881355;
aft("RestLatAm",l,tsim)$sameas(tsim,"2037") = aft("RestLatAm",l,"2036") * 1.00315881355;
pop.fx("US",tsim)$sameas(tsim,"2037") = pop.l("US","2036") * 1.0039233534;
aft("US",l,tsim)$sameas(tsim,"2037") = aft("US",l,"2036") * 1.0039233534;
pop.fx("Uruguay",tsim)$sameas(tsim,"2037") = pop.l("Uruguay","2036") * 0.9975909083;
aft("Uruguay",l,tsim)$sameas(tsim,"2037") = aft("Uruguay",l,"2036") * 0.9975909083;

* --- 2038 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2038") = pop.l("Argentina","2037") * 1.00235761204;
aft("Argentina",l,tsim)$sameas(tsim,"2038") = aft("Argentina",l,"2037") * 1.00235761204;
pop.fx("Bolivia",tsim)$sameas(tsim,"2038") = pop.l("Bolivia","2037") * 1.00666618288;
aft("Bolivia",l,tsim)$sameas(tsim,"2038") = aft("Bolivia",l,"2037") * 1.00666618288;
pop.fx("Brazil",tsim)$sameas(tsim,"2038") = pop.l("Brazil","2037") * 1.00074400935;
aft("Brazil",l,tsim)$sameas(tsim,"2038") = aft("Brazil",l,"2037") * 1.00074400935;
pop.fx("China",tsim)$sameas(tsim,"2038") = pop.l("China","2037") * 0.997105819665;
aft("China",l,tsim)$sameas(tsim,"2038") = aft("China",l,"2037") * 0.997105819665;
pop.fx("EU27",tsim)$sameas(tsim,"2038") = pop.l("EU27","2037") * 0.999503044467;
aft("EU27",l,tsim)$sameas(tsim,"2038") = aft("EU27",l,"2037") * 0.999503044467;
pop.fx("Paraguay",tsim)$sameas(tsim,"2038") = pop.l("Paraguay","2037") * 1.00549546099;
aft("Paraguay",l,tsim)$sameas(tsim,"2038") = aft("Paraguay",l,"2037") * 1.00549546099;
pop.fx("ROW",tsim)$sameas(tsim,"2038") = pop.l("ROW","2037") * 1.00702723183;
aft("ROW",l,tsim)$sameas(tsim,"2038") = aft("ROW",l,"2037") * 1.00702723183;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2038") = pop.l("RestLatAm","2037") * 1.00315881355;
aft("RestLatAm",l,tsim)$sameas(tsim,"2038") = aft("RestLatAm",l,"2037") * 1.00315881355;
pop.fx("US",tsim)$sameas(tsim,"2038") = pop.l("US","2037") * 1.0039233534;
aft("US",l,tsim)$sameas(tsim,"2038") = aft("US",l,"2037") * 1.0039233534;
pop.fx("Uruguay",tsim)$sameas(tsim,"2038") = pop.l("Uruguay","2037") * 0.9975909083;
aft("Uruguay",l,tsim)$sameas(tsim,"2038") = aft("Uruguay",l,"2037") * 0.9975909083;

* --- 2039 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2039") = pop.l("Argentina","2038") * 1.00235761204;
aft("Argentina",l,tsim)$sameas(tsim,"2039") = aft("Argentina",l,"2038") * 1.00235761204;
pop.fx("Bolivia",tsim)$sameas(tsim,"2039") = pop.l("Bolivia","2038") * 1.00666618288;
aft("Bolivia",l,tsim)$sameas(tsim,"2039") = aft("Bolivia",l,"2038") * 1.00666618288;
pop.fx("Brazil",tsim)$sameas(tsim,"2039") = pop.l("Brazil","2038") * 1.00074400935;
aft("Brazil",l,tsim)$sameas(tsim,"2039") = aft("Brazil",l,"2038") * 1.00074400935;
pop.fx("China",tsim)$sameas(tsim,"2039") = pop.l("China","2038") * 0.997105819665;
aft("China",l,tsim)$sameas(tsim,"2039") = aft("China",l,"2038") * 0.997105819665;
pop.fx("EU27",tsim)$sameas(tsim,"2039") = pop.l("EU27","2038") * 0.999503044467;
aft("EU27",l,tsim)$sameas(tsim,"2039") = aft("EU27",l,"2038") * 0.999503044467;
pop.fx("Paraguay",tsim)$sameas(tsim,"2039") = pop.l("Paraguay","2038") * 1.00549546099;
aft("Paraguay",l,tsim)$sameas(tsim,"2039") = aft("Paraguay",l,"2038") * 1.00549546099;
pop.fx("ROW",tsim)$sameas(tsim,"2039") = pop.l("ROW","2038") * 1.00702723183;
aft("ROW",l,tsim)$sameas(tsim,"2039") = aft("ROW",l,"2038") * 1.00702723183;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2039") = pop.l("RestLatAm","2038") * 1.00315881355;
aft("RestLatAm",l,tsim)$sameas(tsim,"2039") = aft("RestLatAm",l,"2038") * 1.00315881355;
pop.fx("US",tsim)$sameas(tsim,"2039") = pop.l("US","2038") * 1.0039233534;
aft("US",l,tsim)$sameas(tsim,"2039") = aft("US",l,"2038") * 1.0039233534;
pop.fx("Uruguay",tsim)$sameas(tsim,"2039") = pop.l("Uruguay","2038") * 0.9975909083;
aft("Uruguay",l,tsim)$sameas(tsim,"2039") = aft("Uruguay",l,"2038") * 0.9975909083;

* --- 2040 ---
pop.fx("Argentina",tsim)$sameas(tsim,"2040") = pop.l("Argentina","2039") * 1.00235761204;
aft("Argentina",l,tsim)$sameas(tsim,"2040") = aft("Argentina",l,"2039") * 1.00235761204;
pop.fx("Bolivia",tsim)$sameas(tsim,"2040") = pop.l("Bolivia","2039") * 1.00666618288;
aft("Bolivia",l,tsim)$sameas(tsim,"2040") = aft("Bolivia",l,"2039") * 1.00666618288;
pop.fx("Brazil",tsim)$sameas(tsim,"2040") = pop.l("Brazil","2039") * 1.00074400935;
aft("Brazil",l,tsim)$sameas(tsim,"2040") = aft("Brazil",l,"2039") * 1.00074400935;
pop.fx("China",tsim)$sameas(tsim,"2040") = pop.l("China","2039") * 0.997105819665;
aft("China",l,tsim)$sameas(tsim,"2040") = aft("China",l,"2039") * 0.997105819665;
pop.fx("EU27",tsim)$sameas(tsim,"2040") = pop.l("EU27","2039") * 0.999503044467;
aft("EU27",l,tsim)$sameas(tsim,"2040") = aft("EU27",l,"2039") * 0.999503044467;
pop.fx("Paraguay",tsim)$sameas(tsim,"2040") = pop.l("Paraguay","2039") * 1.00549546099;
aft("Paraguay",l,tsim)$sameas(tsim,"2040") = aft("Paraguay",l,"2039") * 1.00549546099;
pop.fx("ROW",tsim)$sameas(tsim,"2040") = pop.l("ROW","2039") * 1.00702723183;
aft("ROW",l,tsim)$sameas(tsim,"2040") = aft("ROW",l,"2039") * 1.00702723183;
pop.fx("RestLatAm",tsim)$sameas(tsim,"2040") = pop.l("RestLatAm","2039") * 1.00315881355;
aft("RestLatAm",l,tsim)$sameas(tsim,"2040") = aft("RestLatAm",l,"2039") * 1.00315881355;
pop.fx("US",tsim)$sameas(tsim,"2040") = pop.l("US","2039") * 1.0039233534;
aft("US",l,tsim)$sameas(tsim,"2040") = aft("US",l,"2039") * 1.0039233534;
pop.fx("Uruguay",tsim)$sameas(tsim,"2040") = pop.l("Uruguay","2039") * 0.9975909083;
aft("Uruguay",l,tsim)$sameas(tsim,"2040") = aft("Uruguay",l,"2039") * 0.9975909083;

