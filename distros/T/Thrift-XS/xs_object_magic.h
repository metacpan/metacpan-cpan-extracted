#ifndef __XS_OBJECT_MAGIC_H__
#define __XS_OBJECT_MAGIC_H__

#include "perl.h"

START_EXTERN_C

void xs_object_magic_attach_struct (pTHX_ SV *obj, void *ptr);
void *xs_object_magic_get_struct (pTHX_ SV *sv);
void *xs_object_magic_get_struct_rv (pTHX_ SV *sv);
void *xs_object_magic_get_struct_rv_pretty (pTHX_ SV *sv, const char *name);
MAGIC *xs_object_magic_get_struct_mg (pTHX_ SV *sv);

SV *xs_object_magic_create (pTHX_ void *ptr, HV *stash);

END_EXTERN_C

#endif

