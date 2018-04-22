#if !defined (P5UV_HELPERS_H)
#define P5UV_HELPERS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "xs_object_magic.h"
#include <uv.h>

extern void p5uv_destroy_handle(pTHX_ uv_handle_t* handle);

void p5uv_destroy_handle(pTHX_ uv_handle_t * handle)
{
    SV *self;
    if (!handle) return;
    /* attempt to remove the two-way circular reference */
    if (handle->data) {
        self = (SV *)(handle->data);
        if (self && SvROK(self)) {
            xs_object_magic_detach_struct_rv(aTHX_ self, handle);
            self = NULL;
            SvREFCNT_dec((SV *)(handle->data));
        }
        handle->data = NULL;
    }
    uv_unref(handle);
    Safefree(handle);
}

#endif
