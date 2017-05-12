#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <blade.h>

static SV *callback_start_code = NULL;
static SV *callback_end_code = NULL;
static SV *callback_init_code = NULL;

static SV *callback_data = NULL;
  
void register_blade_theme_simple_init_callbacks(SV *start_code, SV *end_code, SV *init_code, SV *data) {

  if (callback_start_code != NULL) {

    if (callback_start_code != &PL_sv_undef)
      SvREFCNT_dec(callback_start_code);

    if (callback_end_code != &PL_sv_undef)
      SvREFCNT_dec(callback_end_code);

    if (callback_init_code != &PL_sv_undef)
      SvREFCNT_dec(callback_init_code);

    if (callback_data != &PL_sv_undef)
      SvREFCNT_dec(callback_data);

  }

  callback_start_code = start_code;
  callback_end_code = end_code;
  callback_init_code = init_code;

  callback_data = data;

  if (callback_start_code != &PL_sv_undef)
      SvREFCNT_inc(callback_start_code);

  if (callback_end_code != &PL_sv_undef)
      SvREFCNT_inc(callback_end_code);

  if (callback_init_code != &PL_sv_undef)
      SvREFCNT_inc(callback_init_code);

  if (callback_data != &PL_sv_undef)
      SvREFCNT_inc(callback_data);

}

void blade_theme_simple_init_start_wrapper(blade_env *blade, CORBA_char *blar_title, CORBA_char *page_title, CORBA_char *head, void *data) {

  SV *blade_sv, *blar_title_sv, *page_title_sv, *head_sv;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  blade_sv = sv_newmortal();
  sv_setref_pv(blade_sv,"BLADEENV",blade);

  blar_title_sv = sv_newmortal();
  if (blar_title != NULL)
    sv_setpv(blar_title_sv, blar_title);
  else
    blar_title_sv = &PL_sv_undef;

  page_title_sv = sv_newmortal();
  if (page_title != NULL)
    sv_setpv(page_title_sv, page_title);
  else
    page_title_sv = &PL_sv_undef;

  head_sv = sv_newmortal();
  if (head != NULL)
    sv_setpv(head_sv, head);
  else
    head_sv = &PL_sv_undef;

  XPUSHs(blade_sv);
  XPUSHs(blar_title_sv);
  XPUSHs(page_title_sv);
  XPUSHs(head_sv);
  XPUSHs(callback_data);

  PUTBACK;

  perl_call_sv(callback_start_code, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}
void blade_theme_simple_init_end_wrapper(blade_env *blade, CORBA_char *blar_title, CORBA_char *page_title, void *data) {

  SV *blade_sv, *blar_title_sv, *page_title_sv;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  blade_sv = sv_newmortal();
  sv_setref_pv(blade_sv,"blade_envPtr",blade);

  blar_title_sv = sv_newmortal();
  if (blar_title != NULL)
    sv_setpv(blar_title_sv, blar_title);
  else
    blar_title_sv = &PL_sv_undef;

  page_title_sv = sv_newmortal();
  if (page_title != NULL)
    sv_setpv(page_title_sv, page_title);
  else
    page_title_sv = &PL_sv_undef;

  XPUSHs(blade_sv);
  XPUSHs(blar_title_sv);
  XPUSHs(page_title_sv);
  XPUSHs(callback_data);

  PUTBACK;

  perl_call_sv(callback_end_code, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}

void blade_theme_simple_init_init_wrapper(blade_env *blade, void *data) {

  SV *blade_sv;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  blade_sv = sv_newmortal();
  sv_setref_pv(blade_sv,"blade_envPtr",blade);

  XPUSHs(blade_sv);
  XPUSHs(callback_data);

  PUTBACK;

  perl_call_sv(callback_init_code, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}
