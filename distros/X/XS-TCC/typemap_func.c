
#include <EXTERN.h>
#include <perl.h>

#include "typemap_func.h"

/**************************************************************/
/* INPUT */

/* T_SV - use macro code */

/* T_SVREF */
SV *
tm_input_svref(pTHX_ SV * const arg)
{
    SV *var;
    SvGETMAGIC(arg);
    if ( !SvROK(arg) )
        return NULL;
    var = SvRV(arg);
    return var;
}

/* T_AVREF */
AV *
tm_input_avref(pTHX_ SV * const arg)
{
    SvGETMAGIC(arg);
    if (LIKELY( SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV ))
        return (AV *)SvRV(arg);
    else
        return NULL;
}

/* T_HVREF */
HV *
tm_input_hvref(pTHX_ SV * const arg)
{
    SvGETMAGIC(arg);
    if (LIKELY( SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV ))
        return (HV *)SvRV(arg);
    else
        return NULL;
}

/* T_CVREF */
CV *
tm_input_cvref(pTHX_ SV * const arg)
{
    HV *st;
    GV *gvp;
    SvGETMAGIC(arg);
    return sv_2cv(arg, &st, &gvp, 0);
}

/* T_PTRREF */
void *
tm_input_ptrref(pTHX_ SV * const arg)
{
    if (SvROK(arg)) {
        IV tmp = SvIV((SV*)SvRV(arg));
        return INT2PTR(void *, tmp);
    }
    else
        return NULL;
}

/* O_OBJECT - non-core */
void *
tm_input_o_object(pTHX_ SV *const arg)
{
    if ( sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG) )
        return (void *)SvIV( (SV *)SvRV(arg) );
    else {
        warn( "input parameter is not a blessed SV reference" );
        return NULL;
    }
}




/**************************************************************/
/* OUTPUT */



/* T_SYSRET */
void
tm_output_sysret(pTHX_ IV var, SV **arg)
{
    if (var != -1) {
        if (var == 0)
            sv_setpvn(*arg, "0 but true", 10);
	else
            sv_setiv(*arg, var);
    }
    else
        *arg = &PL_sv_undef;
}

/* O_OBJECT - output not implemented as function */
