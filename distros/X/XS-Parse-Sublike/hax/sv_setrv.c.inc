/* vi: set ft=c : */

#ifndef sv_setrv_noinc
#  define sv_setrv_noinc(sv, rv)  S_sv_setrv(aTHX_ sv, rv)
#  define sv_setrv_inc(sv, rv)    S_sv_setrv(aTHX_ sv, SvREFCNT_inc(rv))
#endif

static void S_sv_setrv(pTHX_ SV *sv, SV *rv)
{
  SV *tmp = newRV_noinc(rv);
  sv_setsv(sv, tmp);
  SvREFCNT_dec(tmp);
}
