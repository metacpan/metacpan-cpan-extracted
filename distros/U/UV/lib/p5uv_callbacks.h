#if !defined (P5UV_BASE_H)
#define P5UV_BASE_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"
#include "xs_object_magic.h"
#include <uv.h>
#include "p5uv_helpers.h"


/* helper functions and callbacks */
extern void handle_alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
extern void handle_check_cb(uv_check_t* handle);
extern void handle_close_cb(uv_handle_t* handle);
extern void handle_close_destroy_cb(uv_handle_t* handle);
extern void handle_idle_cb(uv_idle_t* handle);
extern void handle_poll_cb(uv_poll_t* handle, int status, int events);
extern void handle_prepare_cb(uv_prepare_t* handle);
extern void handle_timer_cb(uv_timer_t* handle);
extern void loop_walk_cb(uv_handle_t* handle, void* arg);
extern void loop_walk_close_cb(uv_handle_t* handle, void* arg);

/* HANDLE callbacks */
void handle_alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf)
{
    SV *self;
    SV **callback;

    dTHX;

    buf->base = malloc(suggested_size);
    buf->len = suggested_size;
    if (!handle || !handle->data) return;

    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) return;

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_alloc", FALSE);
    if (!callback || !SvOK(*callback)) return;

    /* provide info to the caller: invocant, suggested_size */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(SvREFCNT_inc(self))); /* invocant */
    mPUSHi(suggested_size);
    PUTBACK;

    call_sv(*callback, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

void handle_check_cb(uv_check_t* handle)
{
    SV *self;
    SV **callback;

    dTHX;

    if (!handle || !handle->data) return;
    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) return;

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_check", FALSE);
    if (!callback || !SvOK(*callback)) return;

    /* provide info to the caller: invocant */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(SvREFCNT_inc(self)); /* invocant */
    PUTBACK;

    call_sv(*callback, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

void handle_close_cb(uv_handle_t* handle)
{
    SV *self;
    SV **callback;

    dTHX;

    if (!handle || !handle->data) return;

    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) return;
    hv_stores((HV *)SvRV(self), "_closed", newSViv(1));

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_close", FALSE);
    if (!callback || !SvOK(*callback)) return;

    /* provide info to the caller: invocant */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(SvREFCNT_inc(self)); /* invocant */
    PUTBACK;

    call_sv(*callback, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

void handle_close_destroy_cb(uv_handle_t* handle)
{
    SV *self;
    SV **callback;

    dTHX;

    if (!handle) return;

    if (!handle->data) {
        p5uv_destroy_handle(aTHX_ handle);
        return;
    }

    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) {
        p5uv_destroy_handle(aTHX_ handle);
        return;
    }
    hv_stores((HV *)SvRV(self), "_closed", newSViv(1));

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_close", FALSE);
    if (!callback || !SvOK(*callback)) {
        p5uv_destroy_handle(aTHX_ handle);
        return;
    }

    /* provide info to the caller: invocant */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(SvREFCNT_inc(self)); /* invocant */
    PUTBACK;

    call_sv(*callback, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
    p5uv_destroy_handle(aTHX_ handle);
}

void handle_idle_cb(uv_idle_t* handle)
{
    SV *self;
    SV **callback;

    dTHX;

    if (!handle || !handle->data) return;
    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) return;

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_idle", FALSE);
    if (!callback || !SvOK(*callback)) return;

    /* provide info to the caller: invocant */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(SvREFCNT_inc(self)); /* invocant */
    PUTBACK;

    call_sv(*callback, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

void handle_poll_cb(uv_poll_t* handle, int status, int events)
{
    SV *self;
    SV **callback;

    dTHX;

    if (!handle || !handle->data) return;
    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) return;

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_poll", FALSE);
    if (!callback || !SvOK(*callback)) return;

    /* provide info to the caller: invocant, status, events */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(SvREFCNT_inc(self)); /* invocant */
    mPUSHi(status);
    mPUSHi(events);

    PUTBACK;
    call_sv(*callback, G_DISCARD|G_VOID);
    SPAGAIN;

    FREETMPS;
    LEAVE;
}

void handle_prepare_cb(uv_prepare_t* handle)
{
    SV *self;
    SV **callback;

    dTHX;

    if (!handle || !handle->data) return;
    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) return;

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_prepare", FALSE);
    if (!callback || !SvOK(*callback)) return;

    /* provide info to the caller: invocant */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(SvREFCNT_inc(self)); /* invocant */
    PUTBACK;

    call_sv(*callback, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

void handle_timer_cb(uv_timer_t* handle)
{
    SV *self;
    SV **callback;

    dTHX;

    if (!handle || !handle->data) return;
    self = (SV *)(handle->data);
    if (!self || !SvROK(self)) return;

    /* nothing else to do if we don't have a callback to call */
    callback = hv_fetchs((HV*)SvRV(self), "_on_timer", FALSE);
    if (!callback || !SvOK(*callback)) return;

    /* provide info to the caller: invocant */
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(SvREFCNT_inc(self)); /* invocant */
    PUTBACK;

    call_sv(*callback, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

void loop_walk_cb(uv_handle_t* handle, void* arg)
{
    SV *self;
    SV *cb;

    dTHX;

    if (!handle || !arg) return;
    cb = (SV *)arg;
    if (!cb || !SvOK(cb)) return;

    self = (SV *)(handle->data);

    /* provide info to the caller: invocant, suggested_size */
    dSP;
    ENTER;
    SAVETMPS;

    if (self && SvROK(self)) {
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(SvREFCNT_inc(self)); /* invocant */
        PUTBACK;
    }

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

void loop_walk_close_cb(uv_handle_t* handle, void* arg)
{
    SV *self;
    dTHX;
    /* don't attempt to close an already closing handle */
    if (!handle || uv_is_closing(handle)) return;
    if (!handle->data) return;
    self = (SV *)(handle->data);
    if (!self) return;

    uv_close(handle, handle_close_destroy_cb);
}

#endif
