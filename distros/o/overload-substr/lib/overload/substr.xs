/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk
 *
 * Much of this code inspired by http://search.cpan.org/~jjore/UNIVERSAL-ref-0.12/
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#include "../../ppport.h"

static int init_done = 0;

OP *(*real_pp_substr)(pTHX);

typedef struct {
  GV *substr_method;
  SV *offset;
  SV *length;
} overload_substr_ctx;

static int magic_get(pTHX_ SV *sv, MAGIC *mg)
{
  dSP;
  overload_substr_ctx *ctx = (void *)mg->mg_ptr;
  SV *result;
  int count;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(mg->mg_obj);
  XPUSHs(ctx->offset);
  if(ctx->length)
    XPUSHs(ctx->length);
  else
    XPUSHs(&PL_sv_undef);
  PUTBACK;

  count = call_sv((SV*)GvCV(ctx->substr_method), G_SCALAR);
  assert(count == 1);

  SPAGAIN;
  result = POPs;

  sv_setsv_nomg(sv, result);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return 1;
}

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  dSP;
  overload_substr_ctx *ctx = (void *)mg->mg_ptr;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(mg->mg_obj);
  XPUSHs(ctx->offset);
  if(ctx->length)
    XPUSHs(ctx->length);
  else
    XPUSHs(&PL_sv_undef);
  XPUSHs(sv);
  PUTBACK;

  call_sv((SV*)GvCV(ctx->substr_method), G_SCALAR|G_DISCARD);

  FREETMPS;
  LEAVE;

  return 1;
}

static int magic_free(pTHX_ SV *sv, MAGIC *mg)
{
  overload_substr_ctx *ctx = (void *)mg->mg_ptr;

  SvREFCNT_dec(ctx->substr_method);
  SvREFCNT_dec(ctx->offset);
  if(ctx->length)
    SvREFCNT_dec(ctx->length);

  Safefree(ctx);

  return 1;
}

static MGVTBL vtbl = {
  &magic_get,
  &magic_set,
  NULL, /* len   */
  NULL, /* clear */
  &magic_free,
};

PP(pp_overload_substr) {
  dSP; dTARG;
  const int num_args = PL_op->op_private & 7; /* Horrible; stolen from pp.c:pp_subst */
  SV *self = *(SP - num_args + 1);
  GV *substr_method;
  SV *result;

  if(!sv_isobject(self))
    return (*real_pp_substr)(aTHX);

  substr_method = gv_fetchmeth(SvSTASH(SvRV(self)), "(substr", 7, 0);

  if(!substr_method)
    return (*real_pp_substr)(aTHX);

#ifdef OPpSUBSTR_REPL_FIRST
  if(PL_op->op_private & OPpSUBSTR_REPL_FIRST) {
    /* This flag means that the replacement comes first, before num_args
     * Easiest is to push it as the 4th argument then call the method
     */
    SV *replacement = SP[-num_args];

    ENTER;
    SAVETMPS;

    PUSHMARK(SP-num_args);
    if(num_args < 3)
      XPUSHs(&PL_sv_undef);
    XPUSHs(replacement);
    PUTBACK;

    call_sv((SV*)GvCV(substr_method), G_SCALAR|G_DISCARD);

    FREETMPS;
    LEAVE;

    RETURN;
  }
#endif

  if(PL_op->op_flags & OPf_MOD || LVRET) {
    overload_substr_ctx *ctx;
    MAGIC *mg;

    Newx(ctx, 1, overload_substr_ctx);

    ctx->substr_method = (GV*)SvREFCNT_inc(substr_method);

    if(num_args == 3)
      ctx->length = SvREFCNT_inc(POPs);
    else
      ctx->length = NULL;

    ctx->offset = SvREFCNT_inc(POPs);
    POPs; /* self */

    result = sv_2mortal(newSVpvn("", 0));

    mg = sv_magicext(result, self, PERL_MAGIC_ext, &vtbl, (void *)ctx, 0);

    XPUSHs(result);
    RETURN;
  }

  ENTER;
  SAVETMPS;

  /* This piece of evil trickery "pushes" all the args we already have on the
   * stack, by simply claiming the MARK to be at the bottom of this op's args
   */
  PUSHMARK(SP-num_args);
  PUTBACK;

  call_sv((SV*)GvCV(substr_method), G_SCALAR);

  SPAGAIN;
  result = POPs;

  SvREFCNT_inc(result);

  FREETMPS;
  LEAVE;

  XPUSHs(result);

  RETURN;
}

MODULE = overload::substr       PACKAGE = overload::substr

BOOT:
if(!init_done++) {
  real_pp_substr = PL_ppaddr[OP_SUBSTR];
  PL_ppaddr[OP_SUBSTR] = &Perl_pp_overload_substr;
}
