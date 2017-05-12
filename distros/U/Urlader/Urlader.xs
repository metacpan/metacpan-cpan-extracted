#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HLOG 18 /* up to 22, but gives diminishing improvements */
#define VERY_FAST 0
#define ULTRA_FAST 0

#include "liblzf/lzf_c_best.c"

#include "urlib.h"
#include "urlib.c"

MODULE = Urlader		PACKAGE = Urlader		PREFIX = u_

PROTOTYPES: ENABLE

BOOT:
{
  HV *stash = gv_stashpv ("Urlader", 1);

  static const struct {
    const char *name;
    IV iv;
  } *civ, const_iv[] = {
#   define const_iv(name) { # name, (IV) name },
    const_iv (T_NULL)
    const_iv (T_META)
    const_iv (T_ENV)
    const_iv (T_ARG)
    const_iv (T_DIR)
    const_iv (T_FILE)
    const_iv (T_NUM)
    const_iv (F_LZF)
    const_iv (F_EXEC)
    const_iv (F_NULL)
  };

  for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
    newCONSTSUB (stash, (char *)civ[-1].name, newSViv (civ[-1].iv));

  newCONSTSUB (stash, "URLADER"        , newSVpv (URLADER        , 0));
  newCONSTSUB (stash, "URLADER_VERSION", newSVpv (URLADER_VERSION, 0));
  newCONSTSUB (stash, "TAIL_MAGIC"     , newSVpv (TAIL_MAGIC     , 0));
}

const char *
getenv (const char *name)

SV *
lzf_compress (SV *in, int min_improve = 2)
	CODE:
{
        STRLEN in_len;
        char *in_data = SvPVbyte (in, in_len);
        STRLEN out_len = in_len - min_improve;
        SV *out = sv_newmortal ();

        RETVAL = &PL_sv_no;
        if (in_len)
          {
            sv_grow (out, out_len);
            out_len = lzf_compress_best (in_data, in_len, SvPVX (out), out_len);

            if (out_len)
	      {
                SvPOK_only (out);
                SvCUR_set (out, out_len);
                SvSetSV (in, out);
                RETVAL = &PL_sv_yes;
              }
          }
}
	OUTPUT:
        RETVAL

void
_set_datadir ()
	CODE:
        u_set_datadir ();

void
_set_exe_info (const char *id, const char *ver)
	CODE:
        strcpy (exe_id , id);
        strcpy (exe_ver, ver);
        u_set_exe_info ();

SV *
lock (SV *path, SV *excl, SV *dowait)
	CODE:
{
        u_handle h = u_lock (SvPVbyte_nolen (path), SvTRUE (excl), SvTRUE (dowait));

        RETVAL = &PL_sv_undef;
        if (u_valid (h))
          RETVAL = sv_setref_iv (NEWSV (0, 0), "Urlader::lock", (IV)h);
}
	OUTPUT:
        RETVAL

MODULE = Urlader		PACKAGE = Urlader::lock

void
DESTROY (SV *self)
	CODE:
        u_close ((u_handle)SvIV (SvRV (self)));


