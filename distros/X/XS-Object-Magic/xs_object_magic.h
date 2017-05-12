#ifndef __XS_OBJECT_MAGIC_H__
#define __XS_OBJECT_MAGIC_H__

#include "perl.h"

START_EXTERN_C

void xs_object_magic_attach_struct (pTHX_ SV *obj, void *ptr);
int  xs_object_magic_detach_struct (pTHX_ SV *obj, void *ptr);
int  xs_object_magic_detach_struct_rv (pTHX_ SV *obj, void *ptr);
int xs_object_magic_has_struct (pTHX_ SV *sv);
int xs_object_magic_has_struct_rv (pTHX_ SV *sv);
void *xs_object_magic_get_struct (pTHX_ SV *sv);
void *xs_object_magic_get_struct_rv (pTHX_ SV *sv);
void *xs_object_magic_get_struct_rv_pretty (pTHX_ SV *sv, const char *name);
MAGIC *xs_object_magic_get_mg (pTHX_ SV *sv);

SV *xs_object_magic_create (pTHX_ void *ptr, HV *stash);

END_EXTERN_C

#endif

