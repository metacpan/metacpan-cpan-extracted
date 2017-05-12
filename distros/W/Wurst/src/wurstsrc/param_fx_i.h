/*
 * 10 Jan 2002
 * rcsid = $Id: param_fx_i.h,v 1.1 2007/09/28 16:57:07 mmundry Exp $
 */

#ifndef PARAM_FX_I_H
#define PARAM_FX_I_H
struct FXParam;
struct FXParam *param_fx_read (const char *fname);
void            FXParam_destroy (struct FXParam *fx);
#endif  /* PARAM_FX_I_H */
