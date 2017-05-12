#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <blade.h>

static SV *callback_code = NULL;
static SV *callback_data = NULL;
  
void register_blade_obj_simple_init_callback(SV *code, SV *data) {

  if (callback_code != NULL) {

    if (callback_code != &PL_sv_undef)
      SvREFCNT_dec(callback_code);

    if (callback_data != &PL_sv_undef)
      SvREFCNT_dec(callback_data);

  }

  callback_code = code;
  callback_data = data;

  if (callback_code != &PL_sv_undef)
    SvREFCNT_inc(callback_code);
  if (callback_data != &PL_sv_undef)
    SvREFCNT_inc(callback_data);

}

void blade_obj_simple_init_wrapper(blade_env *blade, CORBA_char *name, CORBA_char *args, void *data) {

  SV *blade_sv, *name_sv, *args_sv;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  blade_sv = sv_newmortal();
  sv_setref_pv(blade_sv,"BLADEENV",blade);

  name_sv = sv_newmortal();
  if (name != NULL)
    sv_setpv(name_sv, name);
  else
    name_sv = &PL_sv_undef;

  args_sv = sv_newmortal();
  if (args != NULL)
    sv_setpv(args_sv, args);
  else
    args_sv = &PL_sv_undef;
      
  XPUSHs(blade_sv);
  XPUSHs(name_sv);
  XPUSHs(args_sv);
  XPUSHs(callback_data);

  PUTBACK;

  if (callback_code != &PL_sv_undef)
    perl_call_sv(callback_code, G_DISCARD);

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}
