#include "xh_config.h"
#include "xh_core.h"

void
xh_param_assign_string(xh_char_t param[], SV *value)
{
    xh_char_t *str;

    if ( SvOK(value) ) {
        str = XH_CHAR_CAST SvPV_nolen(value);
        xh_str_copy(param, str, XH_PARAM_LEN);
    }
    else {
        *param = 0;
    }
}

void
xh_param_assign_int(xh_char_t *name, xh_int_t *param, SV *value)
{
    if ( !SvOK(value) )
        croak("Parameter '%s' is undefined", name);

    *param = SvIV(value);
}

xh_bool_t
xh_param_assign_bool(SV *value)
{
    if ( SvTRUE(value) )
        return TRUE;

    return FALSE;
}

void
xh_param_assign_pattern(xh_pattern_t *patt, SV *value)
{
    if (patt->expr != NULL) {
        SvREFCNT_dec(patt->expr);
        patt->expr = NULL;
    }

    if ( SvOK(value) && SvTRUE(value) ) {
        patt->enable = TRUE;
        if ( SvRXOK(value) || (SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) ) {
            patt->always = FALSE;
            patt->expr   = value;
            SvREFCNT_inc(value);
        }
        else {
            patt->always = TRUE;
        }
    }
    else {
        patt->enable = FALSE;
    }
}

void
xh_param_assign_filter(xh_pattern_t *patt, SV *value)
{
    if (patt->expr != NULL) {
        SvREFCNT_dec(patt->expr);
        patt->expr = NULL;
    }

    if ( SvOK(value) ) {
        patt->enable = TRUE;
        patt->always = FALSE;
        patt->expr   = value;
        SvREFCNT_inc(value);
    }
    else {
        patt->enable = FALSE;
    }
}

SV *
xh_param_assign_cb(char *name, SV *value)
{
    if ( !SvOK(value) )
        return NULL;

    if ( !SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVCV)
        croak("Parameter '%s' is not CODE reference", name);

    value = SvRV(value);

    SvREFCNT_inc(value);

    return value;
}
