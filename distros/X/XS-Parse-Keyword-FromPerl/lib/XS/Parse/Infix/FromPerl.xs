/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"

#include "newSVop.c.inc"

struct XPIFPHookdata {
  /* Phase callbacks */
  CV *permitcv;
  CV *new_opcv;

  SV *hookdata;
};

static bool cb_permit(pTHX_ void *hookdata)
{
  struct XPIFPHookdata *data = hookdata;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  if(data->hookdata)
    XPUSHs(sv_mortalcopy(data->hookdata));
  else
    XPUSHs(&PL_sv_undef);
  PUTBACK;

  call_sv((SV *)data->permitcv, G_SCALAR);

  SPAGAIN;
  bool ret = SvTRUEx(POPs);

  FREETMPS;
  LEAVE;

  return ret;
}

static OP *cb_new_op(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  struct XPIFPHookdata *data = hookdata;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 5);
  mPUSHu(flags);
  PUSHs(sv_2mortal(newSVop(lhs)));
  PUSHs(sv_2mortal(newSVop(rhs)));
  PUSHs(&PL_sv_undef); /* parsedata; ignore for now */
  if(data->hookdata)
    PUSHs(sv_mortalcopy(data->hookdata));
  else
    PUSHs(&PL_sv_undef);
  PUTBACK;

  call_sv((SV *)data->new_opcv, G_SCALAR);

  SPAGAIN;
  OP *ret = SvOPo(POPs);

  PUTBACK;

  FREETMPS;
  LEAVE;

  return ret;
}

static void S_setup_constants(pTHX)
{
  HV *stash;
  AV *export;

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0))

  stash = gv_stashpvs("XS::Parse::Infix::FromPerl", TRUE);
  export = get_av("XS::Parse::Infix::FromPerl::EXPORT_OK", TRUE);

  DO_CONSTANT(XPI_CLS_NONE);
  DO_CONSTANT(XPI_CLS_PREDICATE);
  DO_CONSTANT(XPI_CLS_RELATION);
  DO_CONSTANT(XPI_CLS_EQUALITY);
  DO_CONSTANT(XPI_CLS_SMARTMATCH);
  DO_CONSTANT(XPI_CLS_MATCHRE);
  DO_CONSTANT(XPI_CLS_ISA);
  DO_CONSTANT(XPI_CLS_MATCH_MISC);
  DO_CONSTANT(XPI_CLS_ORDERING);
  DO_CONSTANT(XPI_CLS_LOW_MISC);
  DO_CONSTANT(XPI_CLS_LOGICAL_OR_LOW_MISC);
  DO_CONSTANT(XPI_CLS_LOGICAL_AND_LOW_MISC);
  DO_CONSTANT(XPI_CLS_ASSIGN_MISC);
  DO_CONSTANT(XPI_CLS_LOGICAL_OR_MISC);
  DO_CONSTANT(XPI_CLS_LOGICAL_AND_MISC);
  DO_CONSTANT(XPI_CLS_ADD_MISC);
  DO_CONSTANT(XPI_CLS_MUL_MISC);
  DO_CONSTANT(XPI_CLS_POW_MISC);
  DO_CONSTANT(XPI_CLS_HIGH_MISC);
}

MODULE = XS::Parse::Infix::FromPerl    PACKAGE = XS::Parse::Infix::FromPerl

void
register_xs_parse_infix(const char *name, ...)
  CODE:
    dKWARG(1);

    struct XSParseInfixHooks hooks = {0};
    struct XPIFPHookdata data = {0};
    SV *wrapper_func_namesv = NULL;
    SV *permit_hintkeysv = NULL;

    static const char *args[] = {
      "flags",
      "lhs_flags",
      "rhs_flags",
      "cls",
      "wrapper_func_name",
      "permit_hintkey",
      "permit",
      "new_op",
      /* TODO: parse? */
      "hookdata",
    };
    while(KWARG_NEXT(args))
      switch(kwarg) {
        case 0: /* flags */
        case 1: /* lhs_flags */
        case 2: /* rhs_flags */
          croak("TODO: flags not currently supported");

        case 3: /* cls */
          hooks.cls = SvUV(kwval);
          break;

        case 4: /* wrapper_func_name */
          wrapper_func_namesv = kwval;
          break;

        case 5: /* permit_hintkey */
          permit_hintkeysv = kwval;
          break;

        case 6: /* permit */
          if(!SvROK(kwval) || SvTYPE(SvRV(kwval)) != SVt_PVCV)
            croak("Expected 'permit' to be a CODE ref");
          data.permitcv = (CV *)SvREFCNT_inc((SV *)CV_FROM_REF(kwval));
          break;

        case 7: /* new_op */
          if(!SvROK(kwval) || SvTYPE(SvRV(kwval)) != SVt_PVCV)
            croak("Expected 'new_op' to be a CODE ref");
          data.new_opcv = (CV *)SvREFCNT_inc((SV *)CV_FROM_REF(kwval));
          break;

        case 8: /* hookdata */
          data.hookdata = newSVsv(kwval);
          break;
      }

    if(!permit_hintkeysv && !data.permitcv)
      croak("Require at least one of 'permit_hintkey' or 'permit'");

    struct XSParseInfixHooks *hooksptr;
    Newx(hooksptr, 1, struct XSParseInfixHooks);
    *hooksptr = hooks;
    if(wrapper_func_namesv)
      hooksptr->wrapper_func_name = savepv(SvPV_nolen(wrapper_func_namesv));
    if(permit_hintkeysv)
      hooksptr->permit_hintkey = savepv(SvPV_nolen(permit_hintkeysv));
    if(data.permitcv)
      hooksptr->permit = &cb_permit;
    if(data.new_opcv)
      hooksptr->new_op = &cb_new_op;

    struct XPIFPHookdata *dataptr;
    Newx(dataptr, 1, struct XPIFPHookdata);
    *dataptr = data;

    register_xs_parse_infix(savepv(name), hooksptr, dataptr);

BOOT:
  boot_xs_parse_infix(0);

  S_setup_constants(aTHX);
