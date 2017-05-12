package autobless;
$VERSION = '1.0.1';

use base pragmatic;
bootstrap xsub;

use xsub q{
  static bool active = FALSE;

  static void filter(SV *rv) {
    SV *sv;
    if (!SvROK(rv) || SvREADONLY(sv = SvRV(rv)) || SvOBJECT(sv))
       return;
    sv_bless(rv, gv_stashpv(sv_reftype(sv, TRUE), TRUE));
  }

  static OP *(*old_pp_srefgen)(pTHX) = NULL;
  static OP *(*old_pp_refgen)(pTHX) = NULL;

  static OP *new_pp_srefgen(pTHX) {
    OP *op;
    op = old_pp_srefgen(aTHX);
    filter(*(SV **)PL_stack_sp);
    return op;
  }

  static OP *new_pp_refgen(pTHX) {
    register SV **mark = (GIMME == G_ARRAY) ?
      PL_stack_base + *PL_markstack_ptr :
      PL_stack_sp - 1;
    OP *op = old_pp_refgen(aTHX);
    while (++mark <= PL_stack_sp)
      filter(*(SV **)mark);
    return op;
  }
};

use xsub enable => q($), q{
  if (active)
    return &PL_sv_yes;

  old_pp_srefgen = PL_ppaddr[OP_SREFGEN];
  PL_ppaddr[OP_SREFGEN] = new_pp_srefgen;
  old_pp_refgen = PL_ppaddr[OP_REFGEN];
  PL_ppaddr[OP_REFGEN] = new_pp_refgen;

  active = TRUE;
  return &PL_sv_yes;
};

use xsub disable => q($), q{
  if (!active)
    return &PL_sv_yes;

  active = FALSE;

  if (PL_ppaddr[OP_REFGEN] == new_pp_refgen) {
    PL_ppaddr[OP_REFGEN] = old_pp_refgen;
  } else {
    Perl_warn(aTHX_ "PL_ppaddr[OP_REFGEN] apparently hijacked at %s line %d\n",
     __FILE__, __LINE__);
  }

  if (PL_ppaddr[OP_SREFGEN] == new_pp_srefgen) {
    PL_ppaddr[OP_SREFGEN] = old_pp_srefgen;
  } else {
    Perl_warn(aTHX_ "PL_ppaddr[OP_SREFGEN] apparently hijacked at %s line %d\n",
      __FILE__, __LINE__);
  }
  return &PL_sv_no;
};

1
