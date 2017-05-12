#ifndef TM_TYPEMAP_FUNC_H_
#define TM_TYPEMAP_FUNC_H_

/**************************************************************/
/* INPUT */

/* T_SVREF */
SV *tm_input_svref(pTHX_ SV * const arg);

/* T_AVREF */
AV *tm_input_avref(pTHX_ SV * const arg);

/* T_HVREF */
HV *tm_input_hvref(pTHX_ SV * const arg);

/* T_CVREF */
CV *tm_input_cvref(pTHX_ SV * const arg);

/* T_PTRREF */
void *tm_input_ptrref(pTHX_ SV * const arg);

/* O_OBJECT - non-core */
void *tm_input_o_object(pTHX_ SV *const arg);

/**************************************************************/
/* OUTPUT */

/* T_SYSRET */
void tm_output_sysret(pTHX_ IV var, SV **arg);

#endif
