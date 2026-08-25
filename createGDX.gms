$setargs ifSaveData filename

* --------------------------------------------------------------------------------------------------
*
*  Create an input database based on model results
*
* --------------------------------------------------------------------------------------------------

*  Production

VDFB(i, a, r) = pd.l(r,i,tsim)*xd.l(r,i,a,tsim)*pd0(r,i)*xd0(r,i,a)/inscale ;
VDFP(i, a, r) = pdp.l(r,i,a,tsim)*xd.l(r,i,a,tsim)*pdp0(r,i,a)*xd0(r,i,a)/inscale ;
VMFB(i, a, r) = pmt.l(r,i,tsim)*xm.l(r,i,a,tsim)*pmt0(r,i)*xm0(r,i,a)/inscale ;
VMFP(i, a, r) = pmp.l(r,i,a,tsim)*xm.l(r,i,a,tsim)*pmp0(r,i,a)*xm0(r,i,a)/inscale ;

loop(h,
   VDPB(i, r) = pd.l(r,i,tsim)*xd.l(r,i,h,tsim)*pd0(r,i)*xd0(r,i,h)/inscale ;
   VDPP(i, r) = pdp.l(r,i,h,tsim)*xd.l(r,i,h,tsim)*pdp0(r,i,h)*xd0(r,i,h)/inscale ;
   VMPB(i, r) = pmt.l(r,i,tsim)*xm.l(r,i,h,tsim)*pmt0(r,i)*xm0(r,i,h)/inscale ;
   VMPP(i, r) = pmp.l(r,i,h,tsim)*xm.l(r,i,h,tsim)*pmp0(r,i,h)*xm0(r,i,h)/inscale ;
) ;

loop(gov,
   VDGB(i, r) = pd.l(r,i,tsim)*xd.l(r,i,gov,tsim)*pd0(r,i)*xd0(r,i,gov)/inscale ;
   VDGP(i, r) = pdp.l(r,i,gov,tsim)*xd.l(r,i,gov,tsim)*pdp0(r,i,gov)*xd0(r,i,gov)/inscale ;
   VMGB(i, r) = pmt.l(r,i,tsim)*xm.l(r,i,gov,tsim)*pmt0(r,i)*xm0(r,i,gov)/inscale ;
   VMGP(i, r) = pmp.l(r,i,gov,tsim)*xm.l(r,i,gov,tsim)*pmp0(r,i,gov)*xm0(r,i,gov)/inscale ;
) ;

loop(inv,
   VDIB(i, r) = pd.l(r,i,tsim)*xd.l(r,i,inv,tsim)*pd0(r,i)*xd0(r,i,inv)/inscale ;
   VDIP(i, r) = pdp.l(r,i,inv,tsim)*xd.l(r,i,inv,tsim)*pdp0(r,i,inv)*xd0(r,i,inv)/inscale ;
   VMIB(i, r) = pmt.l(r,i,tsim)*xm.l(r,i,inv,tsim)*pmt0(r,i)*xm0(r,i,inv)/inscale ;
   VMIP(i, r) = pmp.l(r,i,inv,tsim)*xm.l(r,i,inv,tsim)*pmp0(r,i,inv)*xm0(r,i,inv)/inscale ;
) ;

evfb(fp, a, r) = pf.l(r,fp,a,tsim)*xf.l(r,fp,a,tsim)*pf0(r,fp,a)*xf0(r,fp,a)/inscale ;
evfp(fp, a, r) = pfa.l(r,fp,a,tsim)*xf.l(r,fp,a,tsim)*pfa0(r,fp,a)*xf0(r,fp,a)/inscale ;
evos(fp, a, r) = pfy.l(r,fp,a,tsim)*xf.l(r,fp,a,tsim)*pfy0(r,fp,a)*xf0(r,fp,a)/inscale ;

vxsb(i, s, d) = pe.l(s,i,d,tsim)*xw.l(s,i,d,tsim)*pe0(s,i,d)*xw0(s,i,d)/inscale ;
vfob(i, s, d) = peFOB.l(s,i,d,tsim)*xw.l(s,i,d,tsim)*peFOB0(s,i,d)*xw0(s,i,d)/inscale ;
vcif(i, s, d) = pmCIF.l(s,i,d,tsim)*xw.l(s,i,d,tsim)*pmCIF0(s,i,d)*xw0(s,i,d)/inscale ;
vmsb(i, s, d) = pm.l(s,i,d,tsim)*xw.l(s,i,d,tsim)*pm0(s,i,d)*xw0(s,i,d)/inscale ;

loop(tmg,
   vst(i, r) = pa.l(r,i,tmg,tsim)*xa.l(r,i,tmg,tsim)*pa0(r,i,tmg)*xa0(r,i,tmg)/inscale ;
) ;

vtwr(m, i, s, d) = ptmg.l(m,tsim)*xmgm.l(m,s,i,d,tsim)*ptmg0(m)*xmgm0(m,s,i,d)/inscale ;

save(r) = rsav.l(r,tsim)*rsav0(r)/inscale ;

vdep(r) = depr(r,tsim)*pi.l(r,tsim)*kstock.l(r,tsim)*pi0(r)*kstock0(r)/inscale ;

vkb(r) = kstock.l(r,tsim)*kstock0(r)/inscale ;

maks(i, a, r) = p.l(r,a,i,tsim)*x.l(r,a,i,tsim)*p0(r,a,i)*x0(r,a,i)/inscale ;
makb(i, a, r) = pp.l(r,a,i,tsim)*x.l(r,a,i,tsim)*pp0(r,a,i)*x0(r,a,i)/inscale ;
ptax(i, a, r) = makb(i, a, r) - maks(i, a, r) ;

pop0(r) = pop.l(r,tsim) ;

if(%ifSaveData%,
   execute_unload "%fileName%",
      acts, comm, marg, reg, endw, endwf, endwm, endws,
      l, cap, lnd, nrs, rres, rmuv, imuv,
      vdfb, vdfp, vmfb, vmfp,
      vdpb, vdpp, vmpb, vmpp,
      vdgb, vdgp, vmgb, vmgp,
      vdib, vdip, vmib, vmip,
      evfb, evfp, evos,
      vxsb, vfob, vcif, vmsb, vst, vtwr,
      save, vdep, vkb, pop0=pop, maks, makb, ptax
   ;
) ;
