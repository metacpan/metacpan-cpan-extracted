#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <blade.h>

static SV *callback_body_code = NULL;
static SV *callback_init_code = NULL;
static SV *callback_halt_code = NULL;

static SV *callback_data = NULL;
  
void register_blade_page_callbacks(SV *body_code, SV *init_code, SV *halt_code, SV *data) {

  if (callback_body_code != NULL) {

    if (callback_body_code != &PL_sv_undef)
      SvREFCNT_dec(callback_body_code);

    if (callback_init_code != &PL_sv_undef)
      SvREFCNT_dec(callback_init_code);

    if (callback_halt_code != &PL_sv_undef)
      SvREFCNT_dec(callback_halt_code);

    if (callback_data != &PL_sv_undef)
      SvREFCNT_dec(callback_data);

  }

  callback_body_code = body_code;
  callback_init_code = init_code;
  callback_halt_code = halt_code;

  callback_data = data;

  if (callback_body_code != &PL_sv_undef)
      SvREFCNT_inc(callback_body_code);

  if (callback_init_code != &PL_sv_undef)
      SvREFCNT_inc(callback_init_code);

  if (callback_halt_code != &PL_sv_undef)
      SvREFCNT_inc(callback_halt_code);

  if (callback_data != &PL_sv_undef)
      SvREFCNT_inc(callback_data);

}

void blade_page_body_wrapper(blade_env *blade, void *data) {

  SV *blade_sv;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  blade_sv = sv_newmortal();
  sv_setref_pv(blade_sv,"BLADEENV",blade);

  XPUSHs(blade_sv);
  XPUSHs(callback_data);

  PUTBACK;

  perl_call_sv(callback_body_code, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}

void blade_page_init_wrapper(blade_env *blade, void *data) {

  SV *blade_sv;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  blade_sv = sv_newmortal();
  sv_setref_pv(blade_sv,"BLADEENV",blade);

  XPUSHs(blade_sv);
  XPUSHs(callback_data);

  PUTBACK;

  perl_call_sv(callback_init_code, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}

void blade_page_halt_wrapper(blade_env *blade, void *data) {

  SV *blade_sv;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  blade_sv = sv_newmortal();
  sv_setref_pv(blade_sv,"BLADEENV",blade);

  XPUSHs(blade_sv);
  XPUSHs(callback_data);

  PUTBACK;

  perl_call_sv(callback_halt_code, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}
