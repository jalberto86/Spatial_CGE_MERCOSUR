acronym CDE, CD, capFlex, capshrFix, capFix, capSFix ;

set rs(r) "Simulation regions" ;

alias(is,js) ; alias(r,rp) ; alias(i,j) ; alias(j,jp) ; alias(m,i) ; alias(i0,j0) ; alias(m0,i0) ;

$macro M_PP(r,a,i,t)      \
      (((p0(r,a,i)*p(r,a,i,t)*(1 + prdtx(r,a,i,t)))/pp0(r,a,i))$ifSUB \
   +   (pp(r,a,i,t))$(not ifSUB))
$macro M_PDP(r,i,aa,t)    \
      (((pd0(r,i)*pd(r,i,t)*(1 + dintx(r,i,aa,t)))/pdp0(r,i,aa))$ifSUB \
   +   (pdp(r,i,aa,t))$(not ifSUB))
$macro M_PMP(r,i,aa,t)    \
      (((((pmt0(r,i)*pmt(r,i,t))$(not MRIO)+(pma0(r,i,aa)*pma(r,i,aa,t))$MRIO) \
   *     (1 + mintx(r,i,aa,t)))/pmp0(r,i,aa))$ifSUB \
   +   (pmp(r,i,aa,t))$(not ifSUB))
$macro M_XWMG(s,i,d,t)    \
      (((tmarg(s,i,d,t)*xw0(s,i,d)*xw(s,i,d,t))/xwmg0(s,i,d))$ifSUB \
   +   (xwmg(s,i,d,t))$(not ifSUB))
$macro M_XMGM(m,s,i,d,t)  \
      (((M_XWMG(s,i,d,t)/lambdamg(m,s,i,d,t)))$ifSUB \
   +   (xmgm(m,s,i,d,t))$(not ifSUB))
$macro M_PWMG(s,i,d,t)    \
      (((sum(m, amgm(m,s,i,d)*ptmg0(m)*ptmg(m,t)/lambdamg(m,s,i,d,t)))/pwmg0(s,i,d))$ifSUB \
   +   (pwmg(s,i,d,t))$(not ifSUB))
$macro M_PEFOB(s,i,d,t)   \
      ((((1 + exptx(s,i,d,t) + etax(s,i,t))*pe0(s,i,d)*pe(s,i,d,t))/pefob0(s,i,d))$ifSUB \
   +   (pefob(s,i,d,t))$(not ifSUB))
$macro M_PMCIF(s,i,d,t)   \
      (((M_PEFOB(s,i,d,t)*pefob0(s,i,d) \
   +     pwmg0(s,i,d)*M_PWMG(s,i,d,t)*tmarg(s,i,d,t))/pmcif0(s,i,d))$ifSUB \
   +   (pmcif(s,i,d,t))$(not ifSUB))
$macro M_PM(s,i,d,t)      \
      ((((1 + imptx(s,i,d,t) + mtax(d,i,t) + ntmAVE(s,i,d,t))*M_PMCIF(s,i,d,t) \
   *     pmcif0(s,i,d))/pm0(s,i,d))$ifSUB \
   +   (pm(s,i,d,t))$(not ifSUB))
$macro M_PFA(r,fp,a,t)    \
      (((pf0(r,fp,a)*pf(r,fp,a,t)*(1 + fctts(r,fp,a,t) + fcttx(r,fp,a,t)))/pfa0(r,fp,a))$ifSUB \
   +   (pfa(r,fp,a,t))$(not ifSUB))
$macro M_PFY(r,fp,a,t)    \
      (((pf0(r,fp,a)*pf(r,fp,a,t)*(1 - kappaf(r,fp,a,t)))/pfy0(r,fp,a))$(ifSUB) \
   +   (pfy(r,fp,a,t))$(not ifSUB))

$macro M_PDMA(s,i,d,aa,t) \
      ((((1 + imptxa(s,i,d,aa,t) + mtax(d,i,t)) \
   *     M_PMCIF(s,i,d,t)*pmcif0(s,i,d))/pdma0(s,i,d,aa))$IFSUB \
   +   (pdma(s,i,d,aa,t))$(not IFSUB))

sets
   gy Government tax stream revenues /
      pt       "Tax revenues from output taxes"
      fc       "Indirect tax revenues from firm consumption"
      pc       "Indirect tax revenues from private consumption"
      gc       "Indirect tax revenues from government consumption"
      ic       "Indirect tax revenues from investment consumption"
      dt       "Direct tax on factor income"
      mt       "Import tax revenues"
      et       "Export tax revenues"
      ft       "Tax revenues from factor taxes"
      fs       "Revenue costs of subsidies"
   /
;

Parameters
   nd0(r,a)          "Initial value of intermediate demand bundle"
   va0(r,a)          "Initial value of value added bundle"
   px0(r,a)          "Initial unit cost"
   pnd0(r,a)         "Initial cost of ND bundle"
   pva0(r,a)         "Initial cost of VA bundle"
   xp0(r,a)          "Initial output level"
*  GTAP-LU
   vaNLND0(r,a)      "Initial value of VANLND bundle"
   vaLND0(r,a)       "Initial value of VALND bundle"
   pvaNLND0(r,a)     "Initial price of VANLND bundle"
   pvaLND0(r,a)      "Initial price of VALND bundle"
   pvaLNDNDX0(r,a)   "Initial composite price of VALND bundle"
   xa0(r,i,aa)       "Initial Armington demand"
   pa0(r,i,aa)       "Initial Armington price"
   xf0(r,fp,a)       "Initial factor demand"
   pf0(r,fp,a)       "Initial factor price"
   pfa0(r,fp,a)      "Initial factor price at purchasers' price"
   pfy0(r,fp,a)      "Initial factor return post-income tax"
   x0(r,a,i)         "Initial 'make' level"
   p0(r,a,i)         "Initial pre-tax make price"
   pp0(r,a,i)        "Initial post-tax make price"
   xs0(r,i)          "Initial commodity supply"
   ps0(r,i)          "Initial commodity price"
   ytax0(r,gy)       "Initial tax revenue streams"
   yTaxTot0(r)       "Initial total tax revenue"
   yTaxInd0(r)       "Initial total indirect tax revenue"
   factY0(r)         "Initial total factor income"
   regY0(r)          "Initial regional income"
   rsav0(r)          "Initial regional saving"
   yg0(r)            "Initial public expenditure"
   yc0(r)            "Initial private expenditure"
   betaP0(r)         "Initial elasticity of private utility"
   betaG0(r)         "Initial elasticity of public utility"
   betaS0(r)         "Initial elasticity of saving utility"
   zcons0(r,i,h)     "Initial level of auxiliary zcons variable"
   xcshr0(r,i,h)     "Initial level of budget shares"
   pg0(r)            "Initial government price deflator"
   xg0(r)            "Initial real government expenditures"
   pi0(r)            "Initial investment price deflator"
   xi0(r)            "Initial real investment expenditures"
   yi0(r)            "Initial nominal investment expenditures"
   pd0(r,i)          "Initial price of domestic goods"
   pmt0(r,i)         "Initial price of aggregate imports"
   pdp0(r,i,aa)      "Tax inclusive price of domestic goods"
   pmp0(r,i,aa)      "Tax inclusive price of imported goods"
   xd0(r,i,aa)       "Demand for domestic goods"
   xm0(r,i,aa)       "Demand for imported goods"
   xmt0(r,i)         "Aggregate import demand"
   xw0(s,i,d)        "Bilateral import demand"
   pm0(s,i,d)        "Tariff inclusive price of imported goods"
   pe0(s,i,d)        "Initial pre-tax price of exports"
   pefob0(s,i,d)     "Initial post-tax price of exports"
   pmcif0(s,i,d)     "Initial CIF price of imports"
   xet0(s,i)         "Initial level of aggregate exports"
   pet0(s,i)         "Initial price of aggregate exports"
   xds0(s,i)         "Initial supply of domestic goods"
   xwmg0(s,i,d)
   xmgm0(m,s,i,d)
   pwmg0(s,i,d)
   xtmg0(m)
   ptmg0(m)
   pft0(r,fp)        "Initial aggregate factor price"
   pftNDX0(r,fp)     "Initial composite factor price"
   xft0(r,fp)        "Initial aggregate factor supply"
   pabs0(r)          "Initial absorption price index"
   kstock0(r)        "Initial stock of capital"
   kapend0(r)        "Initial end of period capital stock"
   arent0(r)         "Initial return to capital"
   rorc0(r)          "Initial net rate of return to capital"
   rore0(r)          "Initial expected rate of return to capital"
   rorg0             "Initial global return to capital"
   pigbl0            "Initial global price of investment"
   xigbl0            "Initial net investment"
   gdpmp0(r)         "Initial nominal GDP"
   rgdpmp0(r)        "Initial real GDP"
   ev0(r,h)          "Initial EV"
   cv0(r,h)          "Initial CV"
   obj0              "Initial obj"

*  MRIO
   pma0(r,i,aa)      "Initial agent's price of aggregate imports"
   xwa0(s,i,d,aa)    "Initial agent's imports by source"
   pdma0(s,i,d,aa)   "Initial agent's price of imports by source"
;

Variables
   axp(r,a,t)           "Production frontier shifter"
   lambdand(r,a,t)      "Shifter for ND bundle"
   lambdava(r,a,t)      "Shifter for VA bundle"
   nd(r,a,t)            "Demand for aggregate intermediate (ND)"
   va(r,a,t)            "Demand for aggregate value added  (VA)"
   px(r,a,t)            "Unit cost of production"

   lambdaio(r,i,a,t)    "Shifter for intermediate demand"
   pnd(r,a,t)           "Price of ND bundle"

   vtfp(r,a,t)          "Total factor productivity for VA bundle"
   nlndtfp(r,a,t)       "Non-land TFP in VA bundle"
   lndtfp(r,a,t)        "Land TFP in VA bundle"
   lambdaf(r,fp,a,t)    "Factor specific technical change"
   xf(r,fp,a,t)         "Factor demand"
   pva(r,a,t)           "Price of value added"

*  GTAP-LU
   vaNLND(r,a,t)        "Demand for non-land bundle"
   vaLND(r,a,t)         "Demand for land bundle"
   pvaNLND(r,a,t)       "Price of non-land bundle"
   pvaLND(r,a,t)        "Price of land  bundle"
   pvaLNDNDX(r,a,t)     "Composite price of land  bundle"

   ytax(r,gy,t)         "Government tax stream revenues"
   ytaxTot(r,t)         "Total government revenues"
   ytaxInd(r,t)         "Total revenues from indirect taxes"
   factY(r,t)           "Factor income net of depreciation"
   regY(r,t)            "Regional income"

*  Allocation of national income

   phiP(r,t)            "Elasticity of private exp. wrt to private utility"
   phi(r,t)             "Elasticity of total exp. wrt to total utility"
   yc(r,t)              "Nominal private expenditure on goods and services"
   yg(r,t)              "Nominal government expenditures"
   rsav(r,t)            "Regional savings"
   uh(r,h,t)            "Private utility per capita"
   ug(r,t)              "Utility per capita from public expenditure"
   us(r,t)              "Utility per capita from savings"
   u(r,t)               "Total per capita utility"

*  Private consumption

   zcons(r,i,h,t)       "Auxiliary consumption variable"
   xcshr(r,i,h,t)       "Household budget shares"
   pcons(r,t)           "Consumer expenditure deflator"

   pg(r,t)              "Public expenditure price deflator"
   xg(r,t)              "Aggregate volume of government expenditures"

   pi(r,t)              "Investment expenditure price deflator"
   yi(r,t)              "Nominal Investment expenditures"
   xi(r,t)              "Aggregate volume of Investment expenditures"

   xa(r,i,aa,t)         "Demand for Armington good"
   xd(r,i,aa,t)         "Demand for domestic goods"
   xm(r,i,aa,t)         "Demand for imported goods"
   pdp(r,i,aa,t)        "Purchasers price of domestic goods"
   pmp(r,i,aa,t)        "Purchasers price of imported goods"
   pa(r,i,aa,t)         "Agents price of Armington good"

   xmt(r,i,t)           "Aggregate import demand"
   xw(s,i,d,t)          "Bilateral demand for imports"
   pmt(r,i,t)           "Price of aggregate imports"

*  MRIO
   pma(r,i,aa,t)        "Agent's price of aggregate imports"
   xwa(s,i,d,aa,t)      "Agent's imports by source"
   pdma(s,i,d,aa,t)     "Agent's price of imports by source"

   xds(r,i,t)           "Supply of domestically produced goods"
   xet(r,i,t)           "Aggregate export supply"
   xp(r,a,t)            "Domestic output"
   xs(r,i,t)            "Domestic supply"
   ps(r,i,t)            "Price of domestic supply"
   x(r,a,i,t)           "Supply of commodity 'i' by activity 'a'"
   p(r,a,i,t)           "Pre-tax price of X"
   pp(r,a,i,t)          "Post-tax price of X"
   pe(s,i,d,t)          "Bilateral export supply"
   pet(r,i,t)           "Price of aggregate exports"

   xwmg(s,i,d,t)        "Demand for international trade and transport services"
   xmgm(m,s,i,d,t)      "Demand for TT services by mode"
   pwmg(s,i,d,t)        "Average price of TT services by node"
   xtmg(m,t)            "Global demand for TT services by mode"
   ptmg(m,t)            "Global price index of TT services by mode"

   pefob(s,i,d,t)       "Border price of exports"
   pmcif(s,i,d,t)       "Border price of imports"
   pm(s,i,d,t)          "Bilateral price of imports, tariff-inclusive"

   pd(r,i,t)            "Supply of domestically produced goods"

   xft(r,fp,t)          "Aggregate supply of mobile factors"
   pf(r,fp,a,t)         "Factor price tax exclusive"
   pft(r,fp,t)          "Aggregate price of mobile factors"
   pftndx(r,fp,t)       "Composite price of mobile factors"
   pfa(r,fp,a,t)        "Factor prices tax inclusive"
   pfy(r,fp,a,t)        "After tax factor prices"

*  Allocation of global savings

   arent(r,t)           "Aggregate rate of return to capital after tax"
   kapEnd(r,t)          "End of period capital stock"
   rorc(r,t)            "Net rate of return to capital"
   rore(r,t)            "Expected rate of return to capital"
   rorg(t)              "Global rate of return"
   chiSave(t)           "Global adjustment factor for price of savings"
   psave(r,t)           "Regional price of savings"
   xigbl(t)             "Global net investment"
   pigbl(t)             "Global price of investment"
   chiInv(r,t)          "Regional share of global net investment"
   chif(r,t)            "Share of nominal foreign savings in regional income"
   savf(r,t)            "Real foreign savings"

*  Prices and exchange rates

   pabs(r,t)            "Price of aggregate domestic absorption"
   pmuv(t)              "Price of HIC manufactured exports"
   pfact(r,t)           "Regional factor price index"
   pwfact(t)            "World factor price index"
   pnum(t)              "Model numeraire"

   walras(t)            "Walras check"
   obj                  "Objective function"

*  Closure variables

   dintx(r,i,aa,t)      "Indirect taxes on consumption of domestic goods"
   mintx(r,i,aa,t)      "Indirect taxes on consumption of import goods"
   ytaxshr(r,gy,t)      "Indirect tax revenues as share of regional income"

   gdpmp(r,t)           "Nominal GDP at market price"
   rgdpmp(r,t)          "Real GDP at market price"
   pgdpmp(r,t)          "GDP price deflator"
   rgdppc(r,t)          "Per capita income"
   rgdppcgr(r,t)        "Change in per capita income"

*  Policy variables

   fctts(r,fp,a,t)      "Subsidies on factors of production"
   fcttx(r,fp,a,t)      "Taxes on factors of production"
   prdtx(r,a,i,t)       "Production tax"
   prdtx_1(r,a,i,t)     "Production tax"
   dtxshft(r,i,aa,t)    "Shifter on domestic indirect taxes"
   mtxshft(r,i,aa,t)    "Shifter on imported indirect taxes"
   rtxshft(r,aa,t)      "Uniform shifter on indirect taxes"
   kappaf(r,fp,a,t)     "Income tax on factor f used in activity a"
   exptx(s,i,d,t)       "Bilateral export taxes"
   etax(r,i,t)          "Export tax shifter across destinations"
   imptx(s,i,d,t)       "Bilateral import taxes"
   imptxa(s,i,d,aa,t)   "Bilateral import taxes by agent for MRIO module"
   mtax(r,i,t)          "Import tax shifter uniform across sources"
   ntmAVE(s,i,d,t)      "NTM ad valorem equivalent"
   adtx(r,t)            "Direct tax schedule intercept"
   mdtx(r,t)            "Marginal rate of direct taxation"

   emid(r,i,aa,t)       "CO2 emissions from consumption of domestic goods"
   emim(r,i,aa,t)       "CO2 emissions from consumption of imported goods"

*  Technical variables

   axpsec(a,t)          "World-wide shift in production by sector"
   axpreg(r,t)          "Region-wide shift in production across sectors"
   axpall(r,a,t)        "Region and sector specific shift in production"

   andsec(a,t)          "World-wide technical shift in ND demand by sector"
   andreg(r,t)          "Region-wide technical shift in ND demand across sectors"
   andall(r,a,t)        "Region and sector specific technical shift in ND demand"

   avasec(a,t)          "World-wide technical shift in VA demand by sector"
   avareg(r,t)          "Region-wide technical shift in VA demand across sectors"
   avaall(r,a,t)        "Region and sector specific technical shift in VA demand"

   aiocom(i,t)          "World-wide technical shift in IO demand by input"
   aiosec(a,t)          "World-wide technical shift in IO demand by activity"
   aioreg(r,t)          "Region-wide tech. shift in IO demand across inputs/activities"
   aioall(r,i,a,t)      "Region/input/activity specific technical shift in IO demand"

   afecom(fp,t)         "World-wide technical shift in VA demand by factor"
   afesec(a,t)          "World-wide technical shift in VA demand by activity"
   afefac(r,fp,t)       "Region-wide tech. shift in VA demand across factors"
   afeLab(r,t)          "Region-wide labor augmenting technical shift"
   afereg(r,t)          "Region-wide tech. shift in VA demand across inputs/activities"
   afeall(r,fp,a,t)     "Region/factor/activity specific technical shift in VA demand"

   atm(m,t)             "Global tech change for mode m"
   atf(i,t)             "Global tech change for transporting good i"
   ats(r,t)             "Global tech change for transporting from region r"
   atd(r,t)             "Global tech change for transporting to region r"
   atall(m,s,i,d,t)     "Global tech change for transporint i from r to rp using mode m"

   lambdai(r,i,t)       "Technology changes in investment expenditure function"

   lambdam(s,i,d,t)     "Change in second-level Armington preferences"

   lambdamg(m,s,i,d,t)  "Technical change in TT demand"

   tmarg(s,i,d,t)       "International trade and transport margin"

*  Top level utility parameters

   betap(r,t)           "Private consumption share coefficient"
   betag(r,t)           "Public consumption share coefficient"
   betas(r,t)           "Savings share coefficients"

   aug(r,t)             "Public expenditure utility shifter"
   aus(r,t)             "Savings expenditure utility shifter"
   au(r,t)              "Aggregate utility shifter"

*  Consumer demand

   bh(r,i,t)            "CDE substitution parameters"
   eh(r,i,t)            "CDE expansion parameters"
   ued(r,i,j,t)         "Uncompensated price elasticities"
   ced(r,i,j,t)         "Compensated price elasticities"
   ape(r,i,j,t)         "Allen-Uzawa price elasticities"
   incelas(r,i,t)       "Income elasticities"

*  Other

   kstock(r,t)          "Beginning of period capital stock"
   pop(r,t)             "Population"

   ev(r,h,t)            "Equivalent variation"
   cv(r,h,t)            "Compensating variation"

   gl(r,t)              "Economy-wide labor productivity parameter"
   ggdppc(r,t)          "Growth of real GDP per capita"
;

Parameters
   andd(r,a,t)           "ND bundle share parameter"
   ava(r,a,t)           "VA bundle share parameter"
   sigmap(r,a)          "CES elasticity between ND and VA"

   io(r,i,a,t)          "Input output coefficient wrt ND"
   sigmand(r,a)         "CES elasticity across intermediate demand"

*  GTAP-LU
   anlnd(r,a,t)         "Share of non-land bundle in VA"
   alnd(r,a,t)          "Share of land bundle in VA"
   sigmav(r,a)          "CES elasticity across factors"

   af(r,fp,a,t)         "Factor shares wrt VA"
*  GTAP-LU
   sigmakl(r,a)         "Capital-labor substitution elasticity"
   sigmalnd(r,a)        "Land bundle substitution elasticities"

   gx(r,a,i,t)          "CET share parameter for commodity supply"
   omegas(r,a)          "CET elasticity for commodity supply"

   ax(r,a,i,t)          "CES share parameter for commodity demand"
   sigmas(r,i)          "CES elasticity for commodity demand"

   auh(r,h,t)           "Utility shifter for Cobb-Douglas"

   axg(r,t)             "CES aggregate shifter for government expenditures"
   sigmag(r)            "CES elasticity in government expenditures"
   axi(r,t)             "CES aggregate shifter for investment expenditures"
   sigmai(r)            "CES elasticity in investment"

   alphaa(r,i,aa,t)     "Armington demand shift parameter"
   alphad(r,i,aa,t)     "Armington demand domestic shift parameter"
   alpham(r,i,aa,t)     "Armington demand import shift parameter"
   sigmam(r,i,aa)       "Top level Armington elasticity"

   chiNTM(s,i,r)        "Allocation of NTM revenues across regions"

   amw(s,i,d,t)         "Import share parameters by region of origin"
   sigmaw(r,i)          "Second level Armington elasticity"

*  MRIO
   alphawa(s,i,r,aa)    "Source share by agent for MRIO module"
   sigmawa(r,i,aa)      "Armington elasticity by source"

   gd(r,i,t)            "Domestic CET share parameter"
   ge(r,i,t)            "Export CET share parameter"
   omegax(r,i)          "Top level CET elasticity"
   gw(s,i,d,t)          "Export share parameters by region of destination"
   omegaw(r,i)          "Second level CET elasticity"

   amgm(m,s,i,d)        "Share parameter for demand for TT services by mode"

   aft(r,fp,t)          "Aggregate factor supply shifter"
   etaf(r,fp)           "Aggregate factor supply elasticity"

   gf(r,fp,a,t)         "Sector supply share/shift parameter"
   omegaf(r,fp)         "CET elasticity of factor supply across sectors"
   etaff(r,fp,a)        "Sector specific factor supply elasticity"

   RoRflex(r,t)         "Flexibility of expected net ROR"
   fdepr(r,t)           "Fiscal depreciation rate"
   depr(r,t)            "Physical depreciation rate"
   risk(r,t)            "Regional risk factor"
   krat(r,t)            "Ratio of normalized capital stock & non-normalized capital stock"

   sigmamg(m)           "TT elasticity across suppliers"
   axmg(m,t)            "TT shift parameter"

   savfBar(r,t)         "Exogenous 'real' foreign savings flow"
   ggdppcT(r,t)         "Exogenous rate of growth of per capita GDP"

   invwgt(r,t)          "Regional share of global investment"
   savwgt(r,t)          "Regional share of global savings"

   piadd(r,l,a,t)       "Labor productivity additive sectoral shifter"
   pimlt(r,l,a,t)       "Labor productivity multiplicative sectoral shifter"

   dintx0(r,i,aa)       "Base year indirect tax on domestic consumption"
   mintx0(r,i,aa)       "Base year indirect tax on imported consumption"

   work                 "A working scalar"
   rwork(r)             "A working vector for regions"
   kron(is,js)          "Kronecker delta"
;

Parameters
   ndFlag(r,a)          "ND flags"
   vaNLNDFlag(r,a)      "vaNLND flags"
   vaLNDFlag(r,a)       "vaLND flags"
   vaFlag(r,a)          "VA flags"
   xpFlag(r,a)          "XP flags"
   xsFlag(r,i)          "XS flags"
   xFlag(r,a,i)         "X flags"

   xaFlag(r,i,aa)       "XA flags"
   xfFlag(r,fp,a)       "XF flags"
   xftFlag(r,fp)        "XFT flags"

   fdFlag(r,fd)         "FD flags"

   xatFlag(r,i)         "XAT flags"
   xdFlag(r,i)          "XD flags"
   xmtFlag(r,i)         "XMT flags"
   xetFlag(r,i)         "XET flags"
   xwFlag(s,i,d)        "XW flag"
   tmgFlag(s,i,d)       "TT flag"
   mFlag(m)             "Margin flags"
   RoRFlag              "Type of foreign savings closure"
   intxFlag(r,i,aa)     "Set to 1 for endogenous indirect sales tax, else to 0"
   afeFlag(r,fp)        "Factor or Hicks neutral tech change"

*  MRIO + NTM

   MRIO                 "Flag for MRIO"
   xwaFlag(s,i,r,aa)    "Flag for bilateral trade by agent"
;

Equations

*  Top production nest

   ndeq(r,a,t)          "Demand for aggregate intermediate (ND)"
   vaeq(r,a,t)          "Demand for aggregate value added  (VA)"
   pxeq(r,a,t)          "Unit cost of production"

*  Intermediate demand nest

   pndeq(r,a,t)         "Price of ND bundle"
   xapeq(r,i,a,t)       "Intermediate demand food goods and services"

*  Value added demand nest
*  GTAP-LU
   vaNLNDeq(r,a,t)      "Demand for non-land bundle"
   vaLNDeq(r,a,t)       "Demand for land bundle"
   pvaeq(r,a,t)         "Price of value added"

*  Factor demand nests
   xfeq(r,fp,a,t)       "Factor demand"
*  GTAP-LU
   pvaNLNDeq(r,a,t)     "Price of non-land bundle"
   pvaLNDNDXeq(r,a,t)   "Composite price of land bundle"
   pvaLNDeq(r,a,t)      "Price of land  bundle"

*  Commodity supply/demand

   xeq(r,a,i,t)         "Supply of commodity 'i' by activity 'a'"
   xpeq(r,a,t)          "Aggregate production by activity 'a'"
   ppeq(r,a,i,t)        "Post tax price of X"
   peq(r,a,i,t)         "Pre-tax price of X"
   pseq(r,i,t)          "Total domestic supply of commodity 'i'"

*  Income distribution

   ytaxeq(r,gy,t)       "Government tax revenues by stream"
   ytaxToteq(r,t)       "Total government tax revenues"
   ytaxIndeq(r,t)       "Total revenues from indirect taxes"
   factYeq(r,t)         "Factor income net of depreciation"
   regYeq(r,t)          "Regional income"

*  Top level regional expenditure decisions

   phiPeq(r,t)          "Elast. of priv. exp. wrt to priv. utility"
   phieq(r,t)           "Elast. of total exp. wrt to total utility"
   yceq(r,t)            "Determination of nominal private consumption"
   ygeq(r,t)            "Determination of government nominal expenditures"
   rsaveq(r,t)          "Determination of national savings"
   uheq(r,h,t)          "Private utility per capita"
   ugeq(r,t)            "Per capita utility from public spending"
   useq(r,t)            "Per capita utility from savings"
   ueq(r,t)             "Total utility"

*  Private demand

   zconseq(r,i,h,t)     "Auxiliary consumption variable"
   xcshreq(r,i,h,t)     "Household budget share"
   xaceq(r,i,h,t)       "Private demand for goods and services"
   pconseq(r,t)         "Household aggregate expenditure deflator"

*  Public demand

   xageq(r,i,gov,t)     "Public expenditure on Armington goods and services"
   pgeq(r,t)            "Public expenditure price deflator"
   xgeq(r,t)            "Real government expenditure"

*  Investment demand

   xaieq(r,i,inv,t)     "Investment expenditure on Armington goods and services"
   pieq(r,t)            "Investment expenditure price deflator"
   xieq(r,t)            "Nominal Investment expenditure"

*  Top level Armington demand

   pdpeq(r,i,aa,t)      "Agents price of domestic goods"
   pmpeq(r,i,aa,t)      "Agents price of import goods"
   paeq(r,i,aa,t)       "Agents composite (or Armington) price"
   xdeq(r,i,aa,t)       "Agents demand for domestic goods"
   xmeq(r,i,aa,t)       "Agents demand for import goods"

*  Second level Armington nest

   xmteq(r,i,t)         "Aggregate import demand"
   xweq(s,i,d,t)        "Bilateral demand for imports"
   pmteq(r,i,t)         "Price of aggregate imports"

*  MRIO
   pmaeq(r,i,aa,t)      "Aggregate agent price of imports"
   pdmaeq(s,i,r,aa,t)   "Agent price of imports by source"
   xwaeq(s,i,r,aa,t)    "Bilateral trade demand by agent"

*  Allocation of domestic production

   xdseq(r,i,t)         "Supply of for domestically produced goods"
   xeteq(r,i,t)         "Aggregate export supply"
   xpeq(r,a,t)          "Domestic output"
   xeq(r,a,i,t)         "Domestic output of 'i' by activity 'a'"
   xseq(r,i,t)          "Domestic supply of good 'i'"
   peq(r,a,i,t)         "Price of X"
   peeq(s,i,d,t)        "Bilateral export supply"
   peteq(r,i,t)         "Price of aggregate exports"

*  TT services

   xwmgeq(s,i,d,t)      "Demand for international trade and transport services by node"
   xmgmeq(m,s,i,d,t)    "Demand for TT services by mode and node"
   pwmgeq(s,i,d,t)      "Price index of TT services by node"
   xtmgeq(m,t)          "Global demand for TT services by mode"
   xatmgeq(r,m,tmg,t)   "Regional supply of TT services by mode"
   ptmgeq(m,t)          "Global price index of TT services by mode"

*  Bilateral price relations

   pefobeq(s,i,d,t)     "Border price of exports"
   pmcifeq(s,i,d,t)     "Border price of imports"
   pmeq(s,i,d,t)        "Bilateral price of imports, tariff-inclusive"

*  Commodity equilibrium

   pdeq(r,i,t)          "Price of domestically produced goods"
*  peeq(s,i,d,t)        "Equilibrium for bilateral trade (substituted out)"

*  Factor supply and allocation

   xfteq(r,fp,t)        "Aggregate supply of mobile factors"
   pfeq(r,fp,a,t)       "Factor price tax exclusive"
   pfteq(r,fp,t)        "Aggregate price of mobile factors"
   pftNDXeq(r,fp,t)     "Composite price of mobile factors"
   pfaeq(r,fp,a,t)      "Factor prices pre-tax/subsdidies"
   pfyeq(r,fp,a,t)      "Factor prices post-tax/subsdidies"
   kstockeq(r,t)        "Beginning of period capital stock"

*  Investment determination and its allocation

   arenteq(r,t)         "Aggregate rate of return"
   kapEndeq(r,t)        "End of period capital stock"
   rorceq(r,t)          "Net rate of return to capital"
   roreeq(r,t)          "Expected rate of return to capital"
   yieq(r,t)            "Gross investment by region"
   savfeq(r,t)          "Determination of foreign savings"
   rorgeq(t)            "Global rate of return"
   chifeq(r,t)          "Share of nominal foreign savings in regional income"
   capAccteq(t)         "Capital account consistency"
   chiSaveeq(t)         "Global adjustment factor for regional price of savings"
   psaveeq(r,t)         "Price of savings"
   xigbleq(t)           "Global net investment"
   pigbleq(t)           "Price of global net investment"

*  Price indices and numeraire

   pabseq(r,t)          "Aggregate price of domestic absorption"
   pmuveq(t)            "Price index of HIC manufactured exports"
   pfacteq(r,t)         "Regional factor price index"
   pwfacteq(t)          "World factor price index"
   pnumeq(t)            "Definition of numeraire"
   objeq                "Objtective function"

*  Closure equations

   dintxeq(r,i,aa,t)    "Indirect taxes on domestic consumption"
   mintxeq(r,i,aa,t)    "Direct taxes on import consumption"
   ytaxshreq(r,gy,t)    "Indirect tax revenues as share of regional income"

   gdpmpeq(r,t)         "Nominal GDP at market price"
   rgdpmpeq(r,t)        "Real GDP at market price"
   pgdpmpeq(r,t)        "GDP price deflator"

*  Technology equations

   axpeq(r,a,t)         "Production frontier shifter"
   lambdandeq(r,a,t)    "Tech shifter for ND bundle"
   lambdavaeq(r,a,t)    "Tech shifter for VA bundle"
   lambdaioeq(r,i,a,t)  "Tech shifter for IO demand"
   lambdafeq(r,fp,a,t)  "Factor specific technical change"

   glcaleq(r,t)         "Growth of real GDP per capita"
   afealleq(r,fp,a,t)   "Growth of labor productivity"

*  Other

   uedeq(r,i,j,h,t)     "Uncompensated price elasticities"
   incelaseq(r,i,h,t)   "Income elasticities"
   cedeq(r,i,j,h,t)     "Compensated price elasticities"
   apeeq(r,i,j,h,t)     "Allen-Uzawa price elasticities"

   eveq(r,h,t)          "Equivalent variation"
   cveq(r,h,t)          "Compensating variation"
;

*  -------------------------------------------------------------------------------------------------
*
*     Section 1 -- Production
*
*  -------------------------------------------------------------------------------------------------

$ontext

                    XP
                  /    \
                 /         \
                /              \
              ND               VA
            / | \            /    \
           /  |  \         /        \
          /   |   \      /            \
              XA       NLND            LND
                      /  | \          /   \
                     /   |  \        /     \
                    /    |   \      /       \
                 LAB(l) CAP NRS     land by AEZ

LAB(l)  KAP  NRS
$offtext

*  Demand for aggregate value added -- (E_qva (997), VADEMAND (1262))

vaeq(r,a,t)$(rs(r) and ts(t) and vaFlag(r,a))..
   va(r,a,t) =e= xp(r,a,t)*(px(r,a,t)/pva(r,a,t))**sigmap(r,a)
              *  (axp(r,a,t)*lambdava(r,a,t))**(sigmap(r,a)-1) ;

*  Top level nest -- (E_qint (983), no equivalent)

ndeq(r,a,t)$(rs(r) and ts(t) and ndFlag(r,a))..
   nd(r,a,t) =e= xp(r,a,t)*(px(r,a,t)/pnd(r,a,t))**sigmap(r,a)
              *  (axp(r,a,t)*lambdand(r,a,t))**(sigmap(r,a)-1) ;

*  Unit cost definition (also zero profit condition) -- (E_qo (1027), ZEROPROFITS (1464))

pxeq(r,a,t)$(rs(r) and ts(t) and xpFlag(r,a))..
   px(r,a,t) =e= (1/axp(r,a,t))
      *  (ava(r,a,t)*(pva(r,a,t)/lambdava(r,a,t))**(1-sigmap(r,a))
      +   andd(r,a,t)*(pnd(r,a,t)/lambdand(r,a,t))**(1-sigmap(r,a)))**(1/(1-sigmap(r,a))) ;

*  Value added decomposition

*     Production nesting has been modified to allow for multiple land-use type
*     VA is split into non-land and land factors
*     A subsequent nest disaggregates demand for the relevant factors according
*     to their mapping to the intermediate bundles (vaNLND and VALND)

*  Demand for non-land bundle -- (NA)

vanlndeq(r,a,t)$(rs(r) and ts(t) and vanlndFlag(r,a))..
   vaNLND(r,a,t) =e= va(r,a,t)*(pva(r,a,t)/pvaNLND(r,a,t))**sigmav(r,a)
                  *  ((vtfp(r,a,t)*nlndtfp(r,a,t))**(sigmav(r,a)-1)) ;

*  Demand for land bundle -- (NA)

valndeq(r,a,t)$(rs(r) and ts(t) and valndFlag(r,a))..
   vaLND(r,a,t) =e= va(r,a,t)*(pva(r,a,t)/pvaLND(r,a,t))**sigmav(r,a)
                 *  ((vtfp(r,a,t)*lndtfp(r,a,t))**(sigmav(r,a)-1)) ;

*  Price of value added bundle -- (E_pva (1110), VAPRICE (1403))

pvaeq(r,a,t)$(rs(r) and ts(t) and vaFlag(r,a))..
   pva(r,a,t) =e= (1/vtfp(r,a,t))
               *     (anlnd(r,a,t)*(pvaNLND(r,a,t)/nlndtfp(r,a,t))**(1-sigmav(r,a))
               +      alnd(r,a,t)*(pvaLND(r,a,t)/lndtfp(r,a,t))**(1-sigmav(r,a)))
               **(1/(1-sigmav(r,a))) ;

*  Demand for production factors -- (E_qfe (1103), ENDWDEMAND (1423))

xfeq(r,fp,a,t)$(rs(r) and ts(t) and xfFlag(r,fp,a))..
   0 =e= (xf(r,fp,a,t) - vaNLND(r,a,t)*(pvaNLND(r,a,t)/M_PFA(r,fp,a,t))**sigmakl(r,a)
      *   (lambdaf(r,fp,a,t))**(sigmakl(r,a)-1))
      $(not lnd(fp))

      +  (xf(r,fp,a,t) - vaLND(r,a,t)
      *  ((((pvaLNDNDX(r,a,t)$ifAddLand + pvaLND(r,a,t)$(not ifAddLand))
      /     M_PFA(r,fp,a,t))**sigmalnd(r,a))$sigmalnd(r,a) + 1$(not sigmalnd(r,a)))
      *   ((lambdaf(r,fp,a,t)**(sigmalnd(r,a)-1))$(not lnd(fp) or (lnd(fp) and not ifAddLand))
      +    (lambdaf(r,fp,a,t)**(-sigmalnd(r,a)))$(lnd(fp) and ifAddLand)))
      $lnd(fp)
      ;

*  Price of non-land value added bundle -- (NA)

pvaNLNDeq(r,a,t)$(rs(r) and ts(t) and vanlndFlag(r,a))..
   pvaNLND(r,a,t) =e= sum(fp$(not lnd(fp)), af(r,fp,a,t)
                   *     (M_PFA(r,fp,a,t)/lambdaf(r,fp,a,t))**(1-sigmakl(r,a)))
                   **(1/(1-sigmakl(r,a))) ;

*  Composite price of land value added bundle -- (NA)

pvaLNDNDXeq(r,a,t)$(rs(r) and ts(t) and valndFlag(r,a) and ifAddLand and sigmalnd(r,a))..
   pvaLNDNDX(r,a,t) =e= sum(fp$lnd(fp), af(r,fp,a,t)
                     *     (lambdaf(r,fp,a,t)*M_PFA(r,fp,a,t))**(-sigmalnd(r,a)))
                     **(-1/sigmalnd(r,a)) ;

pvaLNDeq(r,a,t)$(rs(r) and ts(t) and valndFlag(r,a))..
   pvaLND(r,a,t)*vaLND(r,a,t)
      =e= sum(fp$lnd(fp), M_PFA(r,fp,a,t)*xf(r,fp,a,t)
       *    (pfa0(r,fp,a)*xf0(r,fp,a)/(pvaLND0(r,a)*vaLND0(r,a)))) ;

*  Intermediate demand nest

*  Demand for intermediates -- (E_qfa (1052), ~INTDEMAND (1286))

xapeq(r,i,a,t)$(rs(r) and ts(t) and xaFlag(r,i,a))..
   xa(r,i,a,t) =e= nd(r,a,t)*(pnd(r,a,t)/pa(r,i,a,t))**sigmand(r,a)
                *  lambdaio(r,i,a,t)**(sigmand(r,a)-1) ;

*  Price if ND bundle -- (E_pint (1071), no equivalent)

pndeq(r,a,t)$(rs(r) and ts(t) and ndFlag(r,a))..
   pnd(r,a,t) =e= sum(i$io(r,i,a,t), io(r,i,a,t)
      *  (pa(r,i,a,t)/lambdaio(r,i,a,t))**(1-sigmand(r,a)))**(1/(1-sigmand(r,a))) ;

*  Sourcing of commodities by firm (see below xdeq, xmeq, paeq -- one set of Armington equations)
*  Consolidates E_qfd, E_qfm and E_pfa

*  -------------------------------------------------------------------------------------------------
*
*     Section 2 -- Commodity supply
*
*  -------------------------------------------------------------------------------------------------

*  Convert output into commodities -- (E_qca (1253), no equivalent)
*  N.B. The GAMS version allows for perfect transformation

xeq(r,a,i,t)$(rs(r) and ts(t) and xFlag(r,a,i))..
*  Finite elasticity
   0 =e= (x(r,a,i,t) - xp(r,a,t) * (p(r,a,i,t)/px(r,a,t))**omegas(r,a))
      $(omegas(r,a) ne inf)

*  Perfect transformation
      +  (p(r,a,i,t) - px(r,a,t))
      $(omegas(r,a) eq inf)
      ;

*  Zero profit for make 'CET' -- (E_po (1259), no equivalent)

xpeq(r,a,t)$(rs(r) and ts(t) and xpFlag(r,a))..
*  Perfect transformation
   0 =e= (xp(r,a,t) - sum(i$xFlag(r,a,i), (x0(r,a,i)/xp0(r,a))*x(r,a,i,t)))
      $  (omegas(r,a) eq inf)

*  Finite elasticity
      +  (px(r,a,t)
      -   sum(i$xFlag(r,a,i), gx(r,a,i,t)*p(r,a,i,t)**(1+omegas(r,a)))**(1/(1+omegas(r,a))))
      $  (omegas(r,a) ne inf)
      ;

*  Output tax on commodity i produced by activity a -- (E_ps (1264), ~OUTPUTPRICES (1436))

ppeq(r,a,i,t)$(rs(r) and ts(t) and xFlag(r,a,i) and not ifSUB)..
   pp(r,a,i,t) =e= (1 + prdtx(r,a,i,t))*p(r,a,i,t)*p0(r,a,i)/pp0(r,a,i) ;

*  N.B. We are not calculating pb in the GAMS version (E_pb (1286))

*  Aggregate commodities (E_pca (1327) -- no equivalent)

peq(r,a,i,t)$(rs(r) and ts(t) and xFlag(r,a,i))..
*  Finite elasticity
   0 =e= (x(r,a,i,t) - xs(r,i,t) * (ps(r,i,t)/M_PP(r,a,i,t))**sigmas(r,i))
      $(sigmas(r,i) ne inf)

*  Perfect substitutes
      +  (M_PP(r,a,i,t) - ps(r,i,t))$(sigmas(r,i) eq inf)
      ;

*  Price of domestic supply (E_qc (1333) -- no equivalent)

pseq(r,i,t)$(rs(r) and ts(t) and xsFlag(r,i))..

*  Perfect substitutes
   0 =e= (xs(r,i,t) - sum(a$xFlag(r,a,i), x(r,a,i,t)*x0(r,a,i)/xs0(r,i)))
      $  (sigmas(r,i) eq inf)

*  Imperfect substitutes
      +  (ps(r,i,t)
      -     sum(a$xFlag(r,a,i), ax(r,a,i,t)*M_PP(r,a,i,t)**(1-sigmas(r,i)))**(1/(1-sigmas(r,i))))
      $  (sigmas(r,i) ne inf)
      ;

*  -------------------------------------------------------------------------------------------------
*
*     Section 3 -- Income distribution
*
*  -------------------------------------------------------------------------------------------------

*  Income distribution

ytaxeq(r,gy,t)$(rs(r) and ts(t) and ytax0(r,gy))..

   ytax(r,gy,t) =e=

*  Tax revenues from production tax -- (E_del_taxrout (2582), TOUTRATIO (1446))
      + (sum((a,i)$xFlag(r,a,i),
            prdtx(r,a,i,t)*p(r,a,i,t)*x(r,a,i,t)*p0(r,a,i)*x0(r,a,i)/ytax0(r,gy)))
      $sameas(gy,"pt")

*  Tax revenues from factor taxes -- (E_del_taxrfu (2589), TFURATIO (1408))
      +  (sum((fp,a)$xfFlag(r,fp,a),
            fcttx(r,fp,a,t)*pf(r,fp,a,t)*xf(r,fp,a,t)*pf0(r,fp,a)*xf0(r,fp,a)/ytax0(r,gy)))
      $sameas(gy,"ft")

*  Revenue costs from factor subsidies -- N/A
      +  (sum((fp,a)$xfFlag(r,fp,a),
            fctts(r,fp,a,t)*pf(r,fp,a,t)*xf(r,fp,a,t)*pf0(r,fp,a)*xf0(r,fp,a)/ytax0(r,gy)))
      $sameas(gy,"fs")

*  Indirect tax revenues from firm consumption -- (E_del_taxriu (2596), TIURATIO (1327))
      + (sum((i,a),
            dintx(r,i,a,t)*pd(r,i,t)*xd(r,i,a,t)*pd0(r,i)*xd0(r,i,a)/ytax0(r,gy)
      +     mintx(r,i,a,t)*((pmt(r,i,t)*pmt0(r,i))$(not MRIO) + (pma(r,i,a,t)*pma0(r,i,a))$MRIO)
      *        xm(r,i,a,t)*xm0(r,i,a)/ytax0(r,gy)))
      $sameas(gy,"fc")

*  Indirect tax revenues from private consumption -- (E_del_taxrpc (2610), TPCRATIO (1133))
      +  (sum((i,h),
               dintx(r,i,h,t)*pd(r,i,t)*xd(r,i,h,t)*pd0(r,i)*xd0(r,i,h)/ytax0(r,gy)
      +        mintx(r,i,h,t)*((pmt(r,i,t)*pmt0(r,i))$(not MRIO) + (pma(r,i,h,t)*pma0(r,i,h))$MRIO)
      *           xm(r,i,h,t)*xm0(r,i,h)/ytax0(r,gy)))
      $sameas(gy,"pc")

*  Indirect tax revenues from government consumption -- (E_del_taxrgc (2619), TGCRATIO (965))
      +  (sum((i,gov),
            dintx(r,i,gov,t)*pd(r,i,t)*xd(r,i,gov,t)*pd0(r,i)*xd0(r,i,gov)/ytax0(r,gy)
      +     mintx(r,i,gov,t)*((pmt(r,i,t)*pmt0(r,i))$(not MRIO)+(pma(r,i,gov,t)*pma0(r,i,gov))$MRIO)
      *        xm(r,i,gov,t)*xm0(r,i,gov)/ytax0(r,gy)))
      $sameas(gy,"gc")

*  Indirect tax revenues from investment consumption -- (E_del_taxric (2628), TIURATIO (1327))
      +  (sum((i,inv),
            dintx(r,i,inv,t)*pd(r,i,t)*xd(r,i,inv,t)*pd0(r,i)*xd0(r,i,inv)/ytax0(r,gy)
      +     mintx(r,i,inv,t)*((pmt(r,i,t)*pmt0(r,i))$(not MRIO)+(pma(r,i,inv,t)*pma0(r,i,inv))$MRIO)
      *        xm(r,i,inv,t)*xm0(r,i,inv)/ytax0(r,gy)))
      $sameas(gy,"ic")

*  Export tax revenues -- (E_del_taxrexp (2642), TEXPRATIO (1768))
      +  (sum((i,d),
            (exptx(r,i,d,t)+etax(r,i,t))*pe(r,i,d,t)*xw(r,i,d,t)*pe0(r,i,d)*xw0(r,i,d)/ytax0(r,gy)))
      $sameas(gy,"et")

*  Import tax revenues -- (E_del_taxrimp (2649), TIMPRATIO (1842))
      +  ((sum((i,s), (imptx(s,i,r,t) + mtax(r,i,t))*M_PMCIF(s,i,r,t)*xw(s,i,r,t)
      *        pmcif0(s,i,r)*xw0(s,i,r)/ytax0(r,gy)))$(not MRIO)
      +   (sum((i,s,aa), (imptxa(s,i,r,aa,t) + mtax(r,i,t))*M_PMCIF(s,i,r,t)*xwa(s,i,r,aa,t)
      *        pmcif0(s,i,r)*xwa0(s,i,r,aa)/ytax0(r,gy)))$MRIO)
      $sameas(gy,"mt")

*  Direct tax revenues -- (E_del_taxrinc (2667), TINCRATIO (2141))
      +  (sum((fp,a)$xfFlag(r,fp,a),
            kappaf(r,fp,a,t)*pf(r,fp,a,t)*xf(r,fp,a,t)*pf0(r,fp,a)*xf0(r,fp,a)/ytax0(r,gy)))
      $sameas(gy,"dt")
      ;

*  Total tax revenue -- (E_del_ttaxr (2684), DTAXRATIO (2201))

ytaxToteq(r,t)$(rs(r) and ts(t))..
   ytaxTot(r,t) =e= sum(gy, ytax(r,gy,t)*ytax0(r,gy)/ytaxTot0(r)) ;

*  Total indirect tax revenues -- (E_del_indtaxr (2674), DINDTAXRATIO (2192))

ytaxIndeq(r,t)$(rs(r) and ts(t))..
   yTaxInd(r,t) =e= ytaxTot(r,t)*ytaxTot0(r)/yTaxInd0(r)-ytax(r,"dt",t)*ytax0(r,"dt")/yTaxInd0(r) ;

*  Factor income, net of depreciation -- (E_fincome (1351), FACTORINCOME (2183))

factYeq(r,t)$(rs(r) and ts(t))..
   factY(r,t) =e= sum((fp,a)$xfFlag(r,fp,a),
                     pf(r,fp,a,t)*xf(r,fp,a,t)*pf0(r,fp,a)*xf0(r,fp,a)/factY0(r))
               -     depr(r,t)*pi(r,t)*kstock(r,t)*pi0(r)*kstock0(r)/factY0(r) ;

*  Regional income -- (E_y (1370), REGIONALINCOME (2224))

regYeq(r,t)$(rs(r) and ts(t))..
   regY(r,t) =e= factY(r,t)*factY0(r)/regY0(r) + yTaxInd(r,t)*yTaxInd0(r)/regY0(r)
*                 Retained income from own imports
              +   sum((i,s), ntmAVE(s,i,r,t)*M_PMCIF(s,i,r,t)*xw(s,i,r,t)*chiNTM(s,i,r)
              *      (pmcif0(s,i,r)*xw0(s,i,r)/regY0(r)))
*                 Earnings from own exports
              +   sum((i,d), ntmAVE(r,i,d,t)*M_PMCIF(r,i,d,t)*xw(r,i,d,t)*(1-chiNTM(r,i,d))
              *      (pmcif0(r,i,d)*xw0(r,i,d)/regY0(r)))
              ;

*  -------------------------------------------------------------------------------------------------
*
*     Section 4 -- Allocation of regional income across expenditure categories
*
*  -------------------------------------------------------------------------------------------------

*  Elasticity of expenditure wrt utility from private consumption
*     -- (E_uepriv (1587), UTILELASPRIV (1026))

phiPeq(r,t)$(rs(r) and ts(t))..
   phiP(r,t) =e= sum((i,h)$xaFlag(r,i,h), xcshr0(r,i,h)*xcshr(r,i,h,t)*eh(r,i,t))$(%utility% eq CDE)
              +  sum((i,h)$xaFlag(r,i,h), xcshr0(r,i,h)*xcshr(r,i,h,t))$(%utility% eq CD)
              ;

*  Elasticity of total expenditure wrt to utility -- UTILITELASTIC (2255)

phieq(r,t)$(rs(r) and ts(t))..
   phi(r,t)*(betaP0(r)*betaP(r,t)/phiP(r,t) + betaG0(r)*betaG(r,t) + betaS0(r)*betaS(r,t)) =e= 1 ;
*  Total private consumption expenditure -- (E_yp (1404), PRIVCONSEXP (2260))

yceq(r,t)$(rs(r) and ts(t))..
   yc(r,t) =e= betaP(r,t)*(phi(r,t)/phiP(r,t))*regY(r,t)*betaP0(r)*regY0(r)/yc0(r) ;

*  Total government consumption expenditure -- (E_yg (1399), GOVCONSEXP (2265))

ygeq(r,t)$(rs(r) and ts(t))..
   yg(r,t) =e= betaG(r,t)*phi(r,t)*regY(r,t)*betaG0(r)*regY0(r)/yg0(r) ;

*  Total nominal saving -- (E_qsave (1394), SAVING (2270))

rsaveq(r,t)$(rs(r) and ts(t))..
   rsav(r,t) =e= betaS(r,t)*phi(r,t)*regY(r,t)*betaS0(r)*regY0(r)/rsav0(r) ;

*  Top level utility function -- (E_u (1496), UTILITY (2347))

ueq(r,t)$(rs(r) and ts(t))..
   log(u(r,t)) =e= log(au(r,t))
                +  betaP0(r)*betaP(r,t)*sum(h, log(uh(r,h,t)))
                +  betaG0(r)*betaG(r,t)*log(ug(r,t))
                +  betaS0(r)*betaS(r,t)*log(us(r,t)) ;

*  Utility from national savings consumption -- XXX (XXX)

useq(r,t)$(rs(r) and ts(t))..
   us(r,t) =e= (rsav0(r)*aus(r,t)/pop(r,t))*(rsav(r,t)/psave(r,t)) ;

*  -------------------------------------------------------------------------------------------------
*
*     Section 5 -- Domestic final demand
*
*  -------------------------------------------------------------------------------------------------

*  Factor needed for household consumption function

zconseq(r,i,h,t)$(rs(r) and ts(t) and xaFlag(r,i,h) ne 0)..
   zcons(r,i,h,t) =e= (alphaa(r,i,h,t)*bh(r,i,t)
                   * (((pop(r,t)*pa0(r,i,h)/yc0(r))**bh(r,i,t))/zcons0(r,i,h))
                   * (uh(r,h,t)**(eh(r,i,t)*bh(r,i,t)))
                   * ((pa(r,i,h,t)/yc(r,t))**bh(r,i,t)))$(%utility% eq CDE)
                   + (alphaa(r,i,h,t)/zcons0(r,i,h))$(%utility% eq CD) ;

*  Budget shares

xcshreq(r,i,h,t)$(rs(r) and ts(t) and xaFlag(r,i,h) ne 0)..
   xcshr(r,i,h,t)*sum(j$xaFlag(r,j,h), (xcshr0(r,i,h)*zcons0(r,j,h)/zcons0(r,i,h))*zcons(r,j,h,t))
      =e= zcons(r,i,h,t) ;

*  Household demands for goods and services -- (E_qpa (1570), PRIVDMNDS (1080))

xaceq(r,i,h,t)$(rs(r) and ts(t) and xaFlag(r,i,h) ne 0)..
  pa(r,i,h,t)*xa(r,i,h,t) =e= (xcshr0(r,i,h)*yc0(r)/(pa0(r,i,h)*xa0(r,i,h)))
                           *   xcshr(r,i,h,t)*yc(r,t) ;

*  Consumer expenditure deflator (approx.) -- (E_ppriv (1592), PHHLDINDEX (1005))

pconseq(r,t)$(rs(r) and ts(t))..
   pcons(r,t) =e= sum((i,h), xcshr0(r,i,h)*pa0(r,i,h)*xcshr(r,i,h,t)*pa(r,i,h,t)) ;

* Household utility (per capita) -- (E_up (1597), PRIVATEU (1010))

uheq(r,h,t)$(rs(r) and ts(t))..
   0 =e= (1 - sum(i$xaFlag(r,i,h), zcons0(r,i,h)*zcons(r,i,h,t)/bh(r,i,t)))$(%utility% eq CDE)
      +  (uh(r,h,t) - auh(r,h,t)*prod(i$xaFlag(r,i,h), (xa0(r,i,h)*xa(r,i,h,t))**alphaa(r,i,h,t)))
      $(%utility% eq CD) ;

*  Sourcing of commodities by households
*     (see below xdeq, xmeq, paeq -- one set of Armington equations)
*     Consolidates E_qpd, E_qpm and E_ppa

*  Decomposition of public demand

*  CES expenditure function -- (E_qga (1644), GOVDMNDS (913))

xageq(r,i,gov,t)$(rs(r) and ts(t) and xaFlag(r,i,gov) ne 0)..
   xa(r,i,gov,t) =e= xg(r,t)*(pg(r,t)/pa(r,i,gov,t))**sigmag(r) ;

*  Government expenditure price deflator -- (E_pgov (1649), GPRICEINDEX (908))

pgeq(r,t)$(rs(r) and ts(t))..
   0 =e= (pg0(r)*axg(r,t)*pg(r,t) - sum(gov, prod(i$(alphaa(r,i,gov,t) ne 0),
            (pa0(r,i,gov)*pa(r,i,gov,t)/alphaa(r,i,gov,t))**alphaa(r,i,gov,t))))
      $(sigmag(r) eq 1)

      +  (pg(r,t)**(1-sigmag(r))
      -     sum((gov,i)$alphaa(r,i,gov,t), alphaa(r,i,gov,t)*pa(r,i,gov,t)**(1-sigmag(r))))
      $(sigmag(r) ne 1)
      ;

*  Nominal government expenditures

xgeq(r,t)$(rs(r) and ts(t))..
   pg(r,t)*xg(r,t) =e= yg(r,t)*yg0(r)/(pg0(r)*xg0(r)) ;

*  Utility from government consumption -- (E_ug (1654), GOVU (918))

ugeq(r,t)$(rs(r) and ts(t))..
   ug(r,t) =e= (aug(r,t)*xg0(r)/pop(r,t))*xg(r,t) ;

*  Sourcing of commodities by government
*     (see below xdeq, xmeq, paeq -- one set of Armington equations)
*     Consolidates E_qgd, E_qgm and E_pga

*  Decomposition of investment demand
*  CES expenditure function -- (E_qia (1692), INTDEMAND (1286))

xaieq(r,i,inv,t)$(rs(r) and ts(t) and xaFlag(r,i,inv) ne 0)..
   xa(r,i,inv,t) =e= xi(r,t)*(lambdai(r,i,t)**(sigmai(r)-1))
                  *  (pi(r,t)/pa(r,i,inv,t))**sigmai(r) ;

*  Investment expenditure price deflator -- (E_pinv (1697), ZEROPROFITS (1464))

pieq(r,t)$(rs(r) and ts(t))..
   0 =e= (axi(r,t)*pi(r,t)*pi0(r) - sum(inv,prod(i$alphaa(r,i,inv,t),
            (pa0(r,i,inv)*pa(r,i,inv,t)/(lambdai(r,i,t)*alphaa(r,i,inv,t)))**alphaa(r,i,inv,t))))
      $(sigmai(r) eq 1)
      +  ((axi(r,t)*pi(r,t))**(1-sigmai(r)) - sum(inv,sum(i$alphaa(r,i,inv,t),
            alphaa(r,i,inv,t)*(pa(r,i,inv,t)/lambdai(r,i,t))**(1-sigmai(r)))))
      $(sigmai(r) ne 1)
      ;

*  Sourcing of commodities by investment
*     (see below xdeq, xmeq, paeq -- one set of Armington equations)
*     Consolidates E_qid, E_qim and E_pia

*  Volume of investment expenditures

xieq(r,t)$(rs(r) and ts(t))..
   pi(r,t)*xi(r,t) =e= yi(r,t)*yi0(r)/(pi0(r)*xi0(r)) ;

*  -------------------------------------------------------------------------------------------------
*
*     Section 6 -- Trade, goods market equilibrium and prices
*
*  -------------------------------------------------------------------------------------------------

*
*  Trade section
*
*  1. Armington decomposition across agents
*
*  Firm purchasers' prices

*  Domestic goods --
*           firms -- E_pfd (2141), DMNDDPRICE (1305)
*         private -- E_ppd (2168), PHHDPRICE  (1114)
*          public -- E_pgd (2183), GHHDPRICE  (935)
*      investment -- E_pid (2198), DMNDDPRICE (1305)
*              TT -- N/A

pdpeq(r,i,aa,t)$(rs(r) and ts(t) and alphad(r,i,aa,t) ne 0 and not ifSUB)..
   pdp(r,i,aa,t) =e= pd(r,i,t)*(1 + dintx(r,i,aa,t))*pd0(r,i)/pdp0(r,i,aa) ;

*  Imported goods --
*           firms -- E_pfm (2150), DMNDIPRICES (1317)
*         private -- E_ppm (2173), PHHIPRICES  (1128)
*          public -- E_pgm (2188), GHHIPRICES  (940)
*      investment -- E_pim (2203), DMNDIPRICES (1317)
*              TT -- N/A

pmpeq(r,i,aa,t)$(rs(r) and ts(t) and alpham(r,i,aa,t) ne 0 and not ifSUB)..
   pmp(r,i,aa,t) =e= (1 + mintx(r,i,aa,t))
                  *  ((pmt(r,i,t)*pmt0(r,i))$(not MRIO) + (pma(r,i,aa,t)*pma0(r,i,aa))$MRIO)
                  /  pmp0(r,i,aa) ;

*  Armington price --
*            firms -- E_pfa (1137), ICOMPRICE (1340)
*          private -- E_ppa (1623), PCOMPRICE (1147)
*           public -- E_pga (1675), GCOMPRICE (950)
*       investment -- E_pia (1717), ICOMPRICE (1340)
*               TT -- N/A

paeq(r,i,aa,t)$(rs(r) and ts(t) and xaFlag(r,i,aa) ne 0)..
   pa(r,i,aa,t)
     =e=  (alphad(r,i,aa,t)*M_PDP(r,i,aa,t)**(1-sigmam(r,i,aa))
      +    alpham(r,i,aa,t)*M_PMP(r,i,aa,t)**(1-sigmam(r,i,aa)))**(1/(1-sigmam(r,i,aa))) ;

*  Armington decomposition of purchases -- domestic
*            firms -- E_qfd (1120), INDDOM   (1350)
*          private -- E_qpd (1607), PHHLDDOM (1152)
*           public -- E_qgd (1665), GHHLDDOM (960)
*       investment -- E_qid (1702), INDDOM   (1350)
*               TT -- N/A

xdeq(r,i,aa,t)$(rs(r) and ts(t) and alphad(r,i,aa,t) ne 0)..
   xd(r,i,aa,t) =e= xa(r,i,aa,t) * (pa(r,i,aa,t)/M_PDP(r,i,aa,t))**sigmam(r,i,aa) ;

*  Armington decomposition of purchases -- imports
*            firms -- E_qfm (1125), INDIMP     (1345)
*          private -- E_qpm (1618), PHHLAGRIMP (1157)
*           public -- E_qgm (1670), GHHLAGRIMP (955)
*       investment -- E_qim (1707), INDIMP     (1345)
*               TT -- N/A

xmeq(r,i,aa,t)$(rs(r) and ts(t) and alpham(r,i,aa,t) ne 0)..
   xm(r,i,aa,t) =e= xa(r,i,aa,t) * (pa(r,i,aa,t)/M_PMP(r,i,aa,t))**sigmam(r,i,aa) ;

*  Allocation of aggregate import by region of origin --

*  Calculate total import demand -- (E_qms (1759), MKTCLIMP (2465))

xmteq(r,i,t)$(rs(r) and ts(t) and xmtFlag(r,i) and not MRIO)..
   xmt(r,i,t) =e= sum(aa$alpham(r,i,aa,t), xm(r,i,aa,t)*xm0(r,i,aa)/xmt0(r,i)) ;

*  01-May-2019: MRIO

xwaeq(s,i,r,aa,t)$(rs(r) and ts(t) and xwaFlag(s,i,r,aa) and MRIO)..
   xwa(s,i,r,aa,t) =e= xm(r,i,aa,t)*(pma(r,i,aa,t)/M_PDMA(s,i,r,aa,t))**sigmawa(r,i,aa) ;

pmaeq(r,i,aa,t)$(rs(r) and ts(t) and alpham(r,i,aa,t) ne 0 and MRIO)..
   pma(r,i,aa,t)**(1-sigmawa(r,i,aa)) =e=
      sum(s, alphawa(s,i,r,aa)*M_PDMA(s,i,r,aa,t)**(1-sigmawa(r,i,aa))) ;

pdmaeq(s,i,r,aa,t)$(rs(r) and ts(t) and xwaFlag(s,i,r,aa) and MRIO and not ifSUB)..
   pdma(s,i,r,aa,t) =e= (1 + imptxa(s,i,r,aa,t) + mtax(r,i,t))*M_PMCIF(s,i,r,t)
                     *     pmcif0(s,i,r)/pdma0(s,i,r,aa) ;

*  Calculate bilateral import demand -- (E_qxs (1777), IMPORTDEMAND (1835))

xweq(s,i,r,t)$(rs(r) and ts(t) and xwFlag(s,i,r))..
   xw(s,i,r,t) =e= (xmt(r,i,t)*((pmt(r,i,t)/(M_PM(s,i,r,t)))**sigmaw(r,i))
                *   lambdam(s,i,r,t)**(sigmaw(r,i) - 1))$(not MRIO)

                +  (sum(aa$xwa0(s,i,r,aa), xwa(s,i,r,aa,t)*xwa0(s,i,r,aa)/xw0(s,i,r)))$MRIO
                ;

*  Calculate aggregate import price -- (E_pms (1793), DPRICEIMP (1806))

pmteq(r,i,t)$(rs(r) and ts(t) and xmtFlag(r,i) and not MRIO)..
   pmt(r,i,t) =e= sum(s$xwFlag(s,i,r),
      amw(s,i,r,t)*(M_PM(s,i,r,t)/lambdam(s,i,r,t))**(1-sigmaw(r,i)))**(1/(1-sigmaw(r,i))) ;

*  Allocation of domestic supply (no equivalent as there is no CET)

*  Top nest

xdseq(r,i,t)$(rs(r) and ts(t) and xdFlag(r,i))..
   0 =e= (xds(r,i,t) - xs(r,i,t)*(pd(r,i,t)/ps(r,i,t))**omegax(r,i))
      $(omegax(r,i) ne inf)
      +  (pd(r,i,t) - ps(r,i,t))
      $(omegax(r,i) eq inf) ;

xeteq(r,i,t)$(rs(r) and ts(t) and xetFlag(r,i))..
   0 =e= (xet(r,i,t) - xs(r,i,t)*(pet(r,i,t)/ps(r,i,t))**omegax(r,i))
      $(omegax(r,i) ne inf)
      +  (pet(r,i,t) - ps(r,i,t))
      $(omegax(r,i) eq inf) ;

*  Corresponds to equilibrium condition for domestic output --
*     MKTCLTRD_MARG (2429) and MKTCLTRD_MARG (2437)

xseq(r,i,t)$(rs(r) and ts(t) and xsFlag(r,i))..
   0 =e= (ps(r,i,t) - (gd(r,i,t)*pd(r,i,t)**(1+omegax(r,i))
      +                ge(r,i,t)*pet(r,i,t)**(1+omegax(r,i)))**(1/(1+omegax(r,i))))
      $(omegax(r,i) ne inf)
      +  (xs(r,i,t) - (xds(r,i,t)*xds0(r,i)/xs0(r,i) + xet(r,i,t)*xet0(r,i)/xs0(r,i)))
      $(omegax(r,i) eq inf)
      ;

*  This function substitutes out the equilibrium condition for bilateral trade

peeq(s,i,d,t)$(rs(s) and ts(t) and xwFlag(s,i,d))..
   0 =e= (xw(s,i,d,t) - xet(s,i,t)*(pe(s,i,d,t)/pet(s,i,t))**omegaw(s,i))
      $(omegaw(s,i) ne inf)
      +  (pe(s,i,d,t) - pet(s,i,t))
      $(omegaw(s,i) eq inf) ;

peteq(s,i,t)$(rs(s) and ts(t) and xetFlag(s,i))..
   0 =e= (pet(s,i,t)
      -     sum(d$xwFlag(s,i,d), gw(s,i,d,t)*pe(s,i,d,t)**(1+omegaw(s,i)))**(1/(1+omegaw(s,i))))
      $(omegaw(s,i) ne inf)
      +  (xet(s,i,t) - sum(d$xwFlag(s,i,d), xw(s,i,d,t)*xw0(s,i,d)/xet0(s,i)))
      $(omegaw(s,i) eq inf)
      ;

*  Trade margins

*  Total demand for TT services from r to rp for good i -- Additional

xwmgeq(s,i,d,t)$(ts(t) and tmgFlag(s,i,d) and not ifSUB)..
   xwmg(s,i,d,t) =e= (tmarg(s,i,d,t)*xw0(s,i,d)/xwmg0(s,i,d))*xw(s,i,d,t) ;

*  Demand for TT services using m from r to rp for good i -- (E_qtmfsd (1829), QTRANS_MFSD (1951))

xmgmeq(m,s,i,d,t)$(rs(s) and ts(t) and amgm(m,s,i,d) ne 0 and not ifSUB)..
   xmgm(m,s,i,d,t) =e= M_XWMG(s,i,d,t) / lambdamg(m,s,i,d,t) ;

*  The aggregate price of transporting i between r and rp --
*        (E_ptrans (1883), TRANSCOSTINDEX (2029))
*  Note--the price per transport mode is uniform globally

pwmgeq(s,i,d,t)$(ts(t) and tmgFlag(s,i,d) and not ifSUB)..
   pwmg(s,i,d,t) =e= sum(m, amgm(m,s,i,d)*ptmg(m,t)/lambdamg(m,s,i,d,t)) ;

*  Global demand for TT services of type m -- (E_qtm (1916), TRANSDEMAND (1978))

xtmgeq(m,t)$(ts(t) and mFlag(m))..
   xtmg(m,t) =e= sum((s,i,d)$xmgm0(m,s,i,d), (xmgm0(m,s,i,d)/xtmg0(m))*M_XMGM(m,s,i,d,t)) ;

*  Allocation across regions -- (E_qst (1930), TRANSVCES (2040))

xatmgeq(r,m,tmg,t)$(rs(r) and ts(t) and xaFlag(r,m,tmg) ne 0)..
   xa(r,m,tmg,t) =e= xtmg(m,t)*(ptmg(m,t)/pa(r,m,tmg,t))**sigmamg(m) ;

*  The average global price of mode m -- (E_pt (1947), PTRANSPORT (1998))

ptmgeq(m,t)$(ts(t) and mFlag(m))..

   0 =e= (ptmg(m,t)
      - sum(tmg, sum(r, alphaa(r,m,tmg,t)*(pa(r,m,tmg,t))**(1-sigmamg(m)))**(1/(1-sigmamg(m)))))
      $(sigmamg(m) ne 1)

      +  (axmg(m,t)*ptmg(m,t)*ptmg0(m) - sum(tmg, prod(r$alphaa(r,m,tmg,t),
            (pa0(r,m,tmg)*pa(r,m,tmg,t)/alphaa(r,m,tmg,t))**(alphaa(r,m,tmg,t)))))
      $(sigmamg(m) eq 1)
      ;

*  Bilateral FOB export prices -- (E_pfob (2005), EXPRICES (1763))

pefobeq(s,i,d,t)$(rs(s) and ts(t) and xwFlag(s,i,d) and not ifSUB)..
   pefob(s,i,d,t) =e= (1 + exptx(s,i,d,t) + etax(s,i,t))*pe(s,i,d,t)*pe0(s,i,d)/pefob0(s,i,d) ;

*  Border price of bilateral imports -- (E_pcif (2027), FOBCIF (2066))

pmcifeq(s,i,d,t)$(rs(s) and ts(t) and xwFlag(s,i,d) and not ifSUB)..
   pmcif(s,i,d,t) =e= pefob(s,i,d,t)*pefob0(s,i,d)/pmcif0(s,i,d)
                   +  pwmg0(s,i,d)*pwmg(s,i,d,t)*tmarg(s,i,d,t)/pmcif0(s,i,d) ;

*  Calculate bilateral import prices tariff inclusive -- (E_pmds (2050), MKTPRICES (1797))

pmeq(s,i,d,t)$(rs(s) and ts(t) and xwFlag(s,i,d) and not ifSUB and not MRIO)..
   pm(s,i,d,t) =e= (1 + imptx(s,i,d,t) + mtax(d,i,t) + ntmAVE(s,i,d,t))*pmcif(s,i,d,t)
                *    pmcif0(s,i,d)/pm0(s,i,d) ;

*  Goods market equilibrium
*  The bilateral trade equilibrium is directly substituted out.
*  N.B. Without the CET, the two market equilibrium conditions collapse to the
*        GTAP market condition, i.e. XDS(r,i)+sum(d, XWD(r,i,d)) = XS(r,i)

*  Domestic goods market equilibrium --
*     (E_qds (2096) & E_pds (2124), MKTCLDOM (2398))

pdeq(r,i,t)$(rs(r) and ts(t) and xdFlag(r,i))..
   xds(r,i,t) =e= sum(aa$alphad(r,i,aa,t), xd(r,i,aa,t)*xd0(r,i,aa)/xds0(r,i)) ;

$ontext

*  Bilateral trade equilibrium condition is substituted out

peeq(s,i,d,t)$(rs(s) and ts(t) and xwFlag(s,i,d))..
   xwd(s,i,d,t) =e= xws(s,i,d,t) ;
$offtext

*  -------------------------------------------------------------------------------------------------
*
*     Section 7 -- Factor supply and market equilibrium
*
*  -------------------------------------------------------------------------------------------------

*  Aggregate supply of mobile factors -- N/A

xfteq(r,fm,t)$(rs(r) and ts(t) and xftFlag(r,fm))..
   xft(r,fm,t) =e= aft(r,fm,t) * (pft(r,fm,t)/pabs(r,t))**etaf(r,fm) ;

*  Sectoral supply of factors -- ENDW_SUPPLY (2166)  and MKTCLENDWS (2487)
*                                for sluggish commodities, eq. condition not explicit

pfeq(r,fp,a,t)$(rs(r) and ts(t) and xfFlag(r,fp,a))..

*  CET expression for partially mobile factors -- (E_qes2 (2283))
*  N.B. We substitute out the supply = demand equation for each activity,
*       wrt to GTAP this is represented by equation E_peb

   0 =e= (xf(r,fp,a,t) - xft(r,fp,t)
      *  (((M_PFY(r,fp,a,t)/
            (pft(r,fp,t)$(not lnd(fp) or (lnd(fp) and not ifAddLand))
      +      pftNDX(r,fp,t)$(lnd(fp) and ifAddLand)))**omegaf(r,fp))$omegaf(r,fp)
      +    1$(omegaf(r,fp) eq 0)))
      $(fm(fp) and omegaf(r,fp) ne inf)

*  Law of one price for perfectly mobile factors -- (E_qes1 (2266))
      +  (M_PFY(r,fp,a,t) - (pft0(r,fp)/pfy0(r,fp,a))*pft(r,fp,t))
      $(fm(fp) and omegaf(r,fp) eq inf)

*  Supply function (and equilibrium condition) for sector-specific factors (E_qes3 (2307))
      +  (xf(r,fp,a,t) - gf(r,fp,a,t)*(M_PFY(r,fp,a,t)/pabs(r,t))**etaff(r,fp,a))
      $(fnm(fp)) ;

*  Aggregate factor price -- (E_pe2 (2294), ENDW_PRICE (2152)) for sluggish commodities
*                         -- (E_pe1 (2261), MKTCLENDWM (2478)) for perfectly mobile commodities

pfteq(r,fm,t)$(rs(r) and ts(t) and xftFlag(r,fm))..
   pft(r,fm,t)*xft(r,fm,t) =e=
      sum(a, (pfy0(r,fm,a)*xf0(r,fm,a)/(pft0(r,fm)*xft0(r,fm)))*M_PFY(r,fm,a,t)*xf(r,fm,a,t)) ;

pftNDXeq(r,fm,t)$(rs(r) and ts(t) and lnd(fm) and omegaf(r,fm) and omegaf(r,fm) ne inf and ifAddLand)..
   pftNDX(r,fm,t) =e= sum(a, gf(r,fm,a,t)*(M_PFY(r,fm,a,t))**omegaf(r,fm))**(1/omegaf(r,fm)) ;

*  Agents' price of factors -- (E_pfe (2323), MPFACTPRICE (1364) and SPFACTPRICE (1369))

pfaeq(r,fp,a,t)$(rs(r) and ts(t) and xfFlag(r,fp,a) and not ifSUB)..
   pfa(r,fp,a,t) =e= (pf0(r,fp,a)/pfa0(r,fp,a))*pf(r,fp,a,t)
                  *     (1 + fctts(r,fp,a,t) + fcttx(r,fp,a,t)) ;

pfyeq(r,fp,a,t)$(rs(r) and ts(t) and xfFlag(r,fp,a) and not ifSUB)..
   pfy(r,fp,a,t) =e= (pf0(r,fp,a)/pfy0(r,fp,a))*pf(r,fp,a,t)*(1 - kappaf(r,fp,a,t)) ;

*  -------------------------------------------------------------------------------------------------
*
*     Section 8 -- Allocation of global saving
*
*  -------------------------------------------------------------------------------------------------

*  Aggregate capital stock -- (E_kb (2402), KAPSVCES (1521)) (To be verified)
*  Non-normalized level of the capital stock

kstockeq(r,t)$(rs(r) and ts(t))..
   krat(r,t)*kstock(r,t) =e= (xft0(r,cap)/kstock0(r))*xft(r,cap,t) ;

*  End of period stock of capital -- (E_ke (2367), KEND (1581))

kapEndeq(r,t)$(rs(r) and ts(t))..
   kapEnd(r,t) =e= (1 - depr(r,t))*kstock(r,t)*kstock0(r)/kapEnd0(r) + xi(r,t)*xi0(r)/kapend0(r) ;

*  Aggregate capital rate of return after tax --
*     (E_rental (2392), KAPRENTAL (1533) (to be verified))

arenteq(r,t)$(rs(r) and ts(t))..
   arent(r,t) =e= sum(a, (1-kappaf(r,cap,a,t))*pf(r,cap,a,t)*xf(r,cap,a,t)
               *                 (pf0(r,cap,a)*xf0(r,cap,a)/(arent0(r)*kstock0(r))))
               /  kstock(r,t) ;

*  Net rate of return to capital -- (E_rorc (2397), RORCURRENT (1601))

rorceq(r,t)$(rs(r) and ts(t))..
   rorc(r,t) =e= (arent0(r)/(rorc0(r)*pi0(r)))
              *      arent(r,t)/pi(r,t) - fdepr(r,t)/rorc0(r) ;

*  Expected rate of return -- (E_rore (2430), ROREXPECTED (1620))

roreeq(r,t)$(rs(r) and ts(t))..
   rore(r,t) =e= ((rorc0(r)/rore0(r))*((kstock0(r)/kapEnd0(r))**RoRFlex(r,t)))
              *   rorc(r,t)*(kstock(r,t)/kapEnd(r,t))**RoRFlex(r,t) ;

*  Determination of capital flow -- (E_qinv (2459), RORGLOBAL (1669)) (to be verified)
*  Determines savf for all regions in the case of capFlex, for r-1 regions in all other cases

savfeq(r,t)$(rs(r) and ts(t))..
   0 =e= ((risk(r,t)*rore0(r)/rorg0)*rore(r,t) - rorg(t))
      $(RoRFlag eq capFlex)

      +  (xi0(r)*xi(r,t) - depr(r,t)*kstock(r,t)*kstock0(r) - chiInv(r,t)*xigbl(t)*xiGbl0)
      $(RoRFlag eq capShrFix and not rres(r))

      +  (savf(r,t) - piGbl0*piGbl(t)*savfBar(r,t))
      $(RoRFlag eq capFix and not rres(r))

      +  (savf(r,t) - chif(r,t)*regY(r,t)*regY0(r))
      $(RoRFlag eq capSFix and not rres(r))

*     Add constraint for residual region when RoRFlag ne capFlex
      + (sum(rp,savf(rp,t)))
      $(rres(r) and not (RoRFlag eq capFlex))
      ;

*  Determination of RoRg -- (E_globalcgds (2488), GLOBALINV (1682)) (to be verified)
*  Determines RoRg as an average for all cases save capFlex

rorgeq(t)$ts(t)..
   0 =e= (rorg(t)*rorg0
      -     (sum(r,rore0(r)*rore(r,t)*(pi(r,t)*pi0(r)*(xi(r,t)*xi0(r)
      -        depr(r,t)*kstock(r,t)*kstock0(r))))
      /      sum(s, pi0(s)*pi(s,t)*(xi0(s)*xi(s,t)
      -        depr(s,t)*kstock(s,t)*kstock0(s)))))
      $(RoRFlag ne capFlex)

*     Add constraint for the case when RoRFlag eq capFlex
      +  (sum(r,savf(r,t)))
      $(RoRFlag eq capFlex)
      ;

*  Determines nominal foreign savings as a share of regional income for
*  all cases except capSFix when chif is exogenous (except for rres)

chifeq(r,t)$(ts(t) and ((RoRFlag ne capSFix and not rres(r)) or rres(r)))..
   savf(r,t) =e= chif(r,t)*regY(r,t)*regY0(r) ;

* Nominal gross investment

yieq(r,t)$(rs(r) and ts(t))..
   yi(r,t) =e= rsav(r,t)*rsav0(r)/yi0(r) + savf(r,t)/yi0(r)
            +  pi(r,t)*depr(r,t)*kstock(r,t)*(pi0(r)*kstock0(r)/yi0(r))
            +  (walras(t)/yi0(r))$rres(r) ;

*  Global net investment -- GLOBINV (1682) (to be verified)

xigbleq(t)$ts(t)..
   xigbl(t) =e= sum(r, xi(r,t)*xi0(r)/xigbl0 - depr(r,t)*kstock(r,t)*kstock0(r)/xigbl0) ;

*  Price of global investment -- PRICGDS (1701) (to be verified)

pigbleq(t)$ts(t)..
   pigbl(t)*xigbl(t) =e= sum(r, (pi0(r)*pi(r,t))*(xi0(r)*xi(r,t)
                      -    depr(r,t)*kstock(r,t)*kstock0(r))/(pigbl0*xigbl0)) ;

*  Price of savings -- SAVEPRICE (1721) (to be verified)

*  Calculate adjustment factor to make global savings and investment price line up

chiSaveeq(t)$ts(t)..
   chiSave(t) =e= sum((rp,t0), invwgt(rp,t)*pi(rp,t)/pi(rp,t0))
                 /  sum((rp,t0), savwgt(rp,t)*psave(rp,t)/psave(rp,t0)) ;

*  Price of savings equals investment price multiplied by adjustment factor

psaveeq(r,t)$(rs(r) and ts(t))..
   psave(r,t) =e= chiSave(t)*(psave(r,t0)/pi(r,t0))*pi(r,t) ;

*  Model prices

$macro M_QABS(r,tp,tq) \
   (sum((i,fd), (pa0(r,i,fd)*xa0(r,i,fd))*pa(r,i,fd,tp)*xa(r,i,fd,tq)))

pabseq(r,t)$(rs(r) and ts(t))..
   pabs(r,t) =e= (pabs(r,tLag)/pabs0(r))
              *   sqrt((M_QABS(r,t,tLag)/M_QABS(r,tLag,tLag))
              *        (M_QABS(r,t,t)/M_QABS(r,tLag,t))) ;

$macro M_QMUV(tp,tq) \
   (sum((s,j,d)$(rmuv(s) and imuv(j)), (pefob0(s,j,d)*xw0(s,j,d)) \
                                       *M_PEFOB(s,j,d,tp)*xw(s,j,d,tq)))

pmuveq(t)$ts(t)..
   pmuv(t) =e= pmuv(tLag)
            *     sqrt((M_QMUV(t,tLag)/M_QMUV(tLag,tLag))
            *          (M_QMUV(t,t)/M_QMUV(tLag,t))) ;

*  Regional index of factor prices

$macro M_QFACTR(r,tp,tq) \
   (sum((fp,a), (pf0(r,fp,a)*xf0(r,fp,a))*pf(r,fp,a,tp)*xf(r,fp,a,tq)))

pfacteq(r,t)$ts(t)..
   pfact(r,t) =e= pfact(r,tLag)
               *   sqrt((M_QFACTR(r,t,tLag)/M_QFACTR(r,tLag,tLag))
               *        (M_QFACTR(r,t,t)/M_QFACTR(r,tLag,t))) ;

$macro M_QFACTW(tp,tq) \
   (sum((r,fp,a), (pf0(r,fp,a)*xf0(r,fp,a))*pf(r,fp,a,tp)*xf(r,fp,a,tq)))

pwfacteq(t)$ts(t)..
   pwfact(t) =e= pwfact(tLag)
              *   sqrt((M_QFACTW(t,tLag)/M_QFACTW(tLag,tLag))
              *        (M_QFACTW(t,t)/M_QFACTW(tLag,t))) ;

pnumeq(t)$ts(t)..
   pnum(t) =e= pwfact(t) ;

objeq..
   obj =e= sum((r,h,t)$ts(t), ev(r,h,t)*ev0(r,h)/obj0) ;

* --------------------------------------------------------------------------------------------------
*
*     Closure equations
*
* --------------------------------------------------------------------------------------------------

dintxeq(r,i,aa,t)$(rs(r) and ts(t) and intxFlag(r,i,aa))..
   dintx(r,i,aa,t) =e= dintx0(r,i,aa) + dtxshft(r,i,aa,t) + rtxshft(r,aa,t) ;

mintxeq(r,i,aa,t)$(rs(r) and ts(t) and intxFlag(r,i,aa))..
   mintx(r,i,aa,t) =e= mintx0(r,i,aa) + mtxshft(r,i,aa,t) + rtxshft(r,aa,t) ;

ytaxshreq(r,gy,t)$(rs(r) and ts(t))..
   ytaxshr(r,gy,t) =e= (ytax0(r,gy)*ytax(r,gy,t))/(regY0(r)*regY(r,t)) ;

$macro M_QGDP(tp,tq)  \
      (sum((i,fd), (pa0(r,i,fd)*xa0(r,i,fd))*pa(r,i,fd,tp)*xa(r,i,fd,tq)) \
   + sum((i,d),  (pefob0(r,i,d)*xw0(r,i,d))*M_PEFOB(r,i,d,tp)*xw(r,i,d,tq)) \
   - sum((i,s),  (pmcif0(s,i,r)*xw0(s,i,r))*M_PMCIF(s,i,r,tp)*xw(s,i,r,tq)))

gdpmpeq(r,t)$(rs(r) and ts(t))..
   gdpmp(r,t) =e= M_QGDP(t,t)/gdpmp0(r) ;

*  Real GDP at market price -- using Fisher indexing

rgdpmpeq(r,t)$(rs(r) and ts(t))..
   rgdpmp(r,t) =e= rgdpmp(r,tLag)
                *    sqrt((gdpmp(r,t)/gdpmp(r,tLag))*(M_QGDP(tLag,t)/M_QGDP(t,tLag))) ;

pgdpmpeq(r,t)$(rs(r) and ts(t))..
   pgdpmp(r,t) =e= gdpmp(r,t)/rgdpmp(r,t) ;

*  Equivalent variation (E(p0,u))

eveq(r,h,t)$(rs(r) and ts(t))..
   0 =e= (sum(i$xaFlag(r,i,h), alphaa(r,i,h,t)*(uh(r,h,t)**(bh(r,i,t)*eh(r,i,t)))
      *   (pa0(r,i,h)*pa(r,i,h,t0)*Pop(r,t)/(ev0(r,h)*ev(r,h,t)))**bh(r,i,t)) - 1)
      $(%utility% eq CDE)

      +  (uh(r,h,t)*yc0(r)*yc(r,t0) - ev0(r,h)*ev(r,h,t))
      $(%utility% eq CD)
      ;

*  Compensating variation (E(p,u0))

cveq(r,h,t)$(rs(r) and ts(t) and (%utility% eq CDE))..
   sum(i$xaFlag(r,i,h), alphaa(r,i,h,t)*(uh(r,h,t0)**(bh(r,i,t)*eh(r,i,t)))
          * (pa0(r,i,h)*pa(r,i,h,t)*Pop(r,t)/(cv0(r,h)*cv(r,h,t)))**bh(r,i,t)) =e= 1 ;

* ------------------------------------------------------------------------------
*
*     Dynamic equations
*
* ------------------------------------------------------------------------------

*  Top level uniform productivity shifter -- AOWORLD (1240)

axpeq(r,a,t)$(rs(r) and ts(t) and xpFlag(r,a))..
   axp(r,a,t) =e= axp(r,a,t-1)*(1 + axpsec(a,t) + axpreg(r,t) + axpall(r,a,t)) ;

*  ND bundle shifter -- no equivalent (TBV)

lambdandeq(r,a,t)$(rs(r) and ts(t) and ndFlag(r,a))..
   lambdand(r,a,t) =e= lambdand(r,a,t-1)*(1 + andsec(a,t) + andreg(r,t) + andall(r,a,t)) ;

*  VA bundle shifter -- AVAWORLD (1251)

lambdavaeq(r,a,t)$(rs(r) and ts(t) and vaFlag(r,a))..
   lambdava(r,a,t) =e= lambdava(r,a,t-1)*(1 + avasec(a,t) + avareg(r,t) + avaall(r,a,t)) ;

*  Factor demand technical change -- AFEWORLD (1382)

lambdafeq(r,fp,a,t)$(rs(r) and ts(t) and xfFlag(r,fp,a))..
   lambdaf(r,fp,a,t) =e= lambdaf(r,fp,a,t-1)
      * (1 + afecom(fp,t) + afesec(a,t) + afefac(r,fp,t)
      + afereg(r,t)$afeFlag(r,fp) + afeall(r,fp,a,t)) ;

*  Intermediate augmenting technical change -- AFWORLD (1281) with adjustments

lambdaioeq(r,i,a,t)$(rs(r) and ts(t) and xaFlag(r,i,a))..
   lambdaio(r,i,a,t) =e= lambdaio(r,i,a,t-1)
      *(1 + aiocom(i,t) + aiosec(a,t) + aioreg(r,t) + aioall(r,i,a,t)) ;

*  Real GDP growth

glcaleq(r,t)$(rs(r) and ts(t) and years(t) gt FirstYear)..
   rgdpmp(r,t) =e= (1 + ggdppc(r,t))*rgdpmp(r,t-1)*(pop(r,t)/pop(r,t-1)) ;

*  Labor productivity

afealleq(r,l,a,t)$(ifCal eq 1 and rs(r) and ts(t) and years(t) gt FirstYear and xfFlag(r,l,a))..
   afeall(r,l,a,t) =e= piadd(r,l,a,t) + pimlt(r,l,a,t)*gl(r,t) ;

*  Other equations * NOT USED IN ANY MODEL

uedeq(r,i,j,h,t)$(rs(r) and ts(t) and xaFlag(r,i,h) ne 0 and xaFlag(r,j,h) and (%utility% eq CDE))..
   ued(r,i,j,t)
      =e= xcshr0(r,i,h)*xcshr(r,i,h,t)*(-bh(r,i,t)
       - (eh(r,i,t)*bh(r,i,t) - sum(jp, xcshr0(r,jp,h)*xcshr(r,jp,h,t)*eh(r,jp,t)*bh(r,jp,t)))
       /  sum(jp, xcshr0(r,jp,h)*xcshr(r,jp,h,t)*eh(r,jp,t))) + kron(i,j)*(bh(r,i,t) - 1) ;

incelaseq(r,i,h,t)$(rs(r) and ts(t) and xaFlag(r,i,h) and (%utility% eq CDE))..
   incelas(r,i,t)
      =e= (eh(r,i,t)*bh(r,i,t) - sum(jp, xcshr0(r,jp,h)*xcshr(r,jp,h,t)*eh(r,jp,t)*bh(r,jp,t)))
       /   sum(jp, xcshr0(r,jp,h)*xcshr(r,jp,h,t)*eh(r,jp,t))
       -  (bh(r,i,t) - 1) + sum(jp, xcshr0(r,jp,h)*xcshr(r,jp,h,t)*bh(r,jp,t)) ;

cedeq(r,i,j,h,t)$(rs(r) and ts(t) and xaFlag(r,i,h) ne 0 and xaFlag(r,j,h) and (%utility% eq CDE))..
   ced(r,i,j,t) =e= ued(r,i,j,t) + xcshr0(r,j,h)*xcshr(r,j,h,t) * incelas(r,i,t) ;

apeeq(r,i,j,h,t)$(rs(r) and ts(t) and xaFlag(r,i,h) ne 0 and xaFlag(r,j,h) and (%utility% eq CDE))..
   ape(r,i,j,t) =e= 1 - bh(r,j,t) - bh(r,i,t) + sum(jp, xcshr0(r,jp,h)*xcshr(r,jp,h,t)*bh(r,jp,t))
                 -  kron(i,j)*(1-bh(r,i,t))/(xcshr0(r,j,h)*xcshr(r,j,h,t)) ;

model gtap /
   axpeq.axp, lambdandeq.lambdand, lambdavaeq.lambdava,
*  GTAP-LU
   ndeq.nd, vaeq.va, pxeq.px, vaNLNDeq.vaNLND, vaLNDeq.vaLND,
   lambdaioeq.lambdaio, pndeq.pnd, xapeq.xa,
   xeq.x, xpeq.xp, ppeq.pp, peq.p, pseq.ps,
   lambdafeq.lambdaf, xfeq.xf, pvaeq.pva, pvaNLNDeq.pvaNLND, pvaLNDNDXeq.pvaLNDNDX, pvaLNDeq.pvaLND,
   yTaxeq.ytax, yTaxToteq.ytaxtot, yTaxIndeq.ytaxind,
   factYeq.factY, regYeq.regY,
   phiPeq.phiP, phieq.phi, yceq.yc, ygeq.yg, rsaveq.rsav, uheq.uh, ugeq.ug, useq.us, ueq.u,
   zconseq.zcons, xcshreq.xcshr, xaceq.xa, pconseq.pcons,
   xageq.xa, pgeq.pg, xgeq.xg, xaieq.xa, pieq.pi, yieq.yi,
   pdpeq.pdp, pmpeq.pmp,  paeq.pa, xdeq.xd, xmeq.xm,
   xmteq.xmt, xweq.xw, pmteq.pmt, pmeq.pm,
   xwaeq.xwa, pmaeq.pma, pdmaeq.pdma,
*  xdseq.xds, xeteq.xet, xseq.xs, peeq.pe, peteq.pet, pefobeq.pefob,
   xdseq.xds, xeteq.xet, xseq, peeq.pe, peteq.pet, pefobeq.pefob,
   xwmgeq.xwmg, xmgmeq.xmgm, pwmgeq.pwmg, xtmgeq.xtmg, ptmgeq.ptmg, xatmgeq.xa, pmcifeq.pmcif,
   pdeq.pd,
*  xfteq.xft, pfeq.pf, pfteq.pft, pfaeq.pfa, pfyeq.pfy, kstockeq.kstock,
   xfteq.xft, pfeq.pf, pfteq, pftNDXeq.pftndx, pfaeq.pfa, pfyeq.pfy, kstockeq.kstock,
   arenteq.arent, kapEndeq.kapEnd, rorceq.rorc, roreeq.rore, xieq.xi,
   savfeq, rorgeq.rorg, chifeq.chif,
   chiSaveeq.chiSave, psaveeq.psave, xigbleq.xigbl, pigbleq.pigbl,
   dintxeq.dintx, mintxeq.mintx, ytaxshreq.ytaxshr,
   gdpmpeq.gdpmp, rgdpmpeq.rgdpmp, pgdpmpeq.pgdpmp,
   pabseq.pabs, pmuveq.pmuv, pfacteq.pfact, pwfacteq.pwfact, pnumeq,
   eveq, cveq,
   objeq
/ ;

gtap.holdfixed = 1 ;
gtap.scaleopt  = 1 ;
gtap.tolinfrep = 1e-5 ;

*  Define dynamic models

model dynCal /
   gtap + glcaleq + afealleq.afeall
/ ;
dyncal.holdfixed = 1 ;
dyncal.scaleopt  = 1 ;
dyncal.tolinfrep = 1e-5 ;

model dynGTAP /
   gtap + glcaleq.ggdppc
/ ;
dynGTAP.holdfixed = 1 ;
dynGTAP.scaleopt  = 1 ;
dynGTAP.tolinfrep = 1e-5 ;

*  TFP-targeted baseline: GDP path exogenous, regional TFP endogenous
model dynTFP /
   gtap + glcaleq.avareg
/ ;
dynTFP.holdfixed = 1 ;
dynTFP.scaleopt  = 1 ;
dynTFP.tolinfrep = 1e-5 ;

*  Define sub model used to calibrate the top level utility function

model betaCal / phieq.phi, yceq.betap, ygeq.betag, rsaveq.betas / ;
*options limrow = 3, limcol = 3
betaCal.holdfixed = 1 ;

* ------------------------------------------------------------------------------
*
*  Declare post-simulation parameters
*
* ------------------------------------------------------------------------------

set nipa "National income and product accounts" /
   set.fd
   exp
   texp
   imp
/ ;

set fdn(nipa) ;
loop((fd,nipa)$sameas(fd,nipa),
   fdn(nipa) = yes ;
) ;
loop((tmg,nipa)$sameas(tmg,nipa),
   fdn(nipa) = no ;
) ;

display fdn ;

Parameters
   sam(r,is,js,t)
   macroVal(r,nipa,t)
   macroVol(r,nipa,t)
   macroPrc(r,nipa,t)
;
