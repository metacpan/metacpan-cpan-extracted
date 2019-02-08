#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"
#include <assert.h>
#include <stdlib.h>
#include "xs_object_magic.h"

#include <uv.h>

#if defined(DEBUG) && DEBUG > 0
 #define DEBUG_PRINT(fmt, args...) fprintf(stderr, "C -- %s:%d:%s(): " fmt, \
    __FILE__, __LINE__, __func__, ##args)
#else
 #define DEBUG_PRINT(fmt, args...) /* Don't do anything in release builds */
#endif

#include "p5uv_constants.h"
#include "p5uv_callbacks.h"
#include "p5uv_helpers.h"

#if defined(__MINGW32__) || defined(WIN32)
#include <io.h> /* we need _get_osfhandle() on windows */
#define _MAKE_SOCK(s, f) s = _get_osfhandle(f)
#else
#define _MAKE_SOCK(s,f) s = f
#endif

MODULE = UV             PACKAGE = UV            PREFIX = uv_

PROTOTYPES: ENABLE

BOOT:
{
    PERL_MATH_INT64_LOAD_OR_CROAK;
    constants_export_uv(aTHX);
    constants_export_uv_handle(aTHX);
    constants_export_uv_poll(aTHX);
    constants_export_uv_loop(aTHX);
}

const char* uv_err_name(int err)

uint64_t uv_hrtime()

const char* uv_strerror(int err)

unsigned int uv_version()

const char* uv_version_string()

MODULE = UV             PACKAGE = UV::Handle      PREFIX = p5uv_handle_

PROTOTYPES: ENABLE

void p5uv_handle__destruct(SV *self, int closed)
    PREINIT:
        uv_handle_t *handle;
    CODE:
        handle = (uv_handle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_handle_t in _destruct");
        if (closed) {
            p5uv_destroy_handle(aTHX_ handle);
            return;
        }
        if (!uv_is_closing(handle))
            uv_close(handle, handle_close_destroy_cb);

int p5uv_handle__active(SV *self)
    PREINIT:
        uv_handle_t *handle;
    CODE:
        handle = (uv_handle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_handle_t in active");
        RETVAL = uv_is_active(handle);
    OUTPUT:
    RETVAL

void p5uv_handle__close(SV *self)
    PREINIT:
        uv_handle_t *handle;
    CODE:
        handle = (uv_handle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_handle_t in _close");
        if (!handle) return;
        uv_close(handle, handle_close_cb);

void p5uv_handle__has_struct(SV *self)
    PPCODE:
        EXTEND(SP, 1);
        if(xs_object_magic_has_struct_rv(aTHX_ self))
            PUSHs(&PL_sv_yes);
        else
            PUSHs(&PL_sv_no);

int p5uv_handle_closing(SV *self)
    PREINIT:
        uv_handle_t *handle;
    CODE:
        handle = (uv_handle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_handle_t in closing");
        RETVAL = uv_is_closing(handle);
    OUTPUT:
    RETVAL

int p5uv_handle_has_ref(SV *self)
    PREINIT:
        uv_handle_t *handle;
    CODE:
        handle = (uv_handle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_handle_t in has_ref");
        RETVAL = uv_has_ref(handle);
    OUTPUT:
    RETVAL

void p5uv_handle_ref(SV *self)
    PREINIT:
        uv_handle_t *handle;
    CODE:
        handle = (uv_handle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_handle_t in ref");
        uv_ref(handle);

void p5uv_handle_unref(SV *self)
    PREINIT:
        uv_handle_t *handle;
    CODE:
        handle = (uv_handle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_handle_t in unref");
        uv_unref(handle);

MODULE = UV             PACKAGE = UV::Check      PREFIX = p5uv_check_

PROTOTYPES: ENABLE

void p5uv_check__init(SV *self, uv_loop_t *loop)
    INIT:
        uv_check_t *handle;
        int ret;
    CODE:
        if(!xs_object_magic_has_struct_rv(aTHX_ self)) {
            Newx(handle, 1, uv_check_t);
            if (!handle) {
                croak("Unable to allocate space for a handle");
            }
            if (NULL == loop) {
                loop = uv_default_loop();
            }
            ret = uv_check_init(loop, handle);
            if (0 != ret) {
                Safefree(handle);
                croak("Couldn't initialize handle (%i): %s", ret, uv_strerror(ret));
            }
            xs_object_magic_attach_struct(aTHX_ SvRV(self), handle);
            handle->data = SvREFCNT_inc(ST(0));
            return;
        }

int p5uv_check__start(SV *self)
    INIT:
        uv_check_t *handle;
    CODE:
        handle = (uv_check_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_check_t in _start");
        RETVAL = uv_check_start(handle, handle_check_cb);
    OUTPUT:
    RETVAL

int p5uv_check_stop(SV *self)
    INIT:
        uv_check_t *handle;
    CODE:
        handle = (uv_check_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_check_t in stop");
        RETVAL = uv_check_stop(handle);
    OUTPUT:
    RETVAL

MODULE = UV             PACKAGE = UV::Idle      PREFIX = p5uv_idle_

PROTOTYPES: ENABLE

void p5uv_idle__init(SV *self, uv_loop_t *loop)
    INIT:
        uv_idle_t *handle;
        int ret;
    CODE:
        if(!xs_object_magic_has_struct_rv(aTHX_ self)) {
            Newx(handle, 1, uv_idle_t);
            if (!handle) {
                croak("Unable to allocate space for an idle");
            }
            if (NULL == loop) {
                loop = uv_default_loop();
            }
            ret = uv_idle_init(loop, handle);
            if (0 != ret) {
                Safefree(handle);
                croak("Couldn't initialize handle (%i): %s", ret, uv_strerror(ret));
            }
            xs_object_magic_attach_struct(aTHX_ SvRV(self), handle);
            handle->data = SvREFCNT_inc(ST(0));
            return;
        }

int p5uv_idle__start(SV *self)
    INIT:
        uv_idle_t *handle;
    CODE:
        handle = (uv_idle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_idle_t in _start");
        RETVAL = uv_idle_start(handle, handle_idle_cb);
    OUTPUT:
    RETVAL

int p5uv_idle_stop(SV *self)
    INIT:
        uv_idle_t *handle;
    CODE:
        handle = (uv_idle_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_idle_t in stop");
        RETVAL = uv_idle_stop(handle);
    OUTPUT:
    RETVAL

MODULE = UV             PACKAGE = UV::Poll      PREFIX = p5uv_poll_

PROTOTYPES: ENABLE

void p5uv_poll__init(SV *self, int fd, uv_loop_t *loop)
    INIT:
        uv_poll_t *handle;
        int ret;
        uv_os_sock_t sock;
    CODE:
        if (xs_object_magic_has_struct_rv(aTHX_ self)) croak("Can't re-initialie Poll");
        Newx(handle, 1, uv_poll_t);
        if (!handle) croak("Unable to allocate space for a poll");

        if (NULL == loop) loop = uv_default_loop();
        _MAKE_SOCK(sock, fd);

        ret = uv_poll_init_socket(loop, handle, sock);

        if (0 != ret) {
            Safefree(handle);
            croak("Couldn't initialize handle (%i): %s", ret, uv_strerror(ret));
        }
        xs_object_magic_attach_struct(aTHX_ SvRV(self), handle);
        handle->data = SvREFCNT_inc(ST(0));

int p5uv_poll__start(SV *self, int events=UV_READABLE)
    INIT:
        uv_poll_t *handle;
    CODE:
        handle = (uv_poll_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_poll_t in _start");
        RETVAL = uv_poll_start(handle, events, handle_poll_cb);
    OUTPUT:
    RETVAL

int p5uv_poll_stop(SV *self)
    INIT:
        uv_poll_t *handle;
    CODE:
        handle = (uv_poll_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_poll_t in stop");
        RETVAL = uv_poll_stop(handle);
    OUTPUT:
    RETVAL


MODULE = UV             PACKAGE = UV::Prepare      PREFIX = p5uv_prepare_

PROTOTYPES: ENABLE

void p5uv_prepare__init(SV *self, uv_loop_t *loop)
    INIT:
        uv_prepare_t *handle;
        int ret;
    CODE:
        if(!xs_object_magic_has_struct_rv(aTHX_ self)) {
            Newx(handle, 1, uv_prepare_t);
            if (!handle) {
                croak("Unable to allocate space for a prepare");
            }
            if (NULL == loop) {
                loop = uv_default_loop();
            }
            ret = uv_prepare_init(loop, handle);
            if (0 != ret) {
                Safefree(handle);
                croak("Couldn't initialize handle (%i): %s", ret, uv_strerror(ret));
            }
            xs_object_magic_attach_struct(aTHX_ SvRV(self), handle);
            handle->data = SvREFCNT_inc(ST(0));
            return;
        }

int p5uv_prepare__start(SV *self)
    INIT:
        uv_prepare_t *handle;
    CODE:
        handle = (uv_prepare_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_prepare_t in _start");
        RETVAL = uv_prepare_start(handle, handle_prepare_cb);
    OUTPUT:
    RETVAL

int p5uv_prepare_stop(SV *self)
    INIT:
        uv_prepare_t *handle;
    CODE:
        handle = (uv_prepare_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_prepare_t in stop");
        RETVAL = uv_prepare_stop(handle);
    OUTPUT:
    RETVAL


MODULE = UV             PACKAGE = UV::Timer      PREFIX = p5uv_timer_

PROTOTYPES: ENABLE

void p5uv_timer__init(SV *self, uv_loop_t *loop)
    INIT:
        uv_timer_t *handle;
        int ret;
    CODE:
        if(!xs_object_magic_has_struct_rv(aTHX_ self)) {
            Newx(handle, 1, uv_timer_t);
            if (!handle) {
                croak("Unable to allocate space for a timer");
            }
            if (NULL == loop) {
                loop = uv_default_loop();
            }
            ret = uv_timer_init(loop, handle);
            if (0 != ret) {
                Safefree(handle);
                croak("Couldn't initialize handle (%i): %s", ret, uv_strerror(ret));
            }
            xs_object_magic_attach_struct(aTHX_ SvRV(self), handle);
            handle->data = SvREFCNT_inc(ST(0));
            return;
        }

uint64_t p5uv_timer__get_repeat(SV *self)
    INIT:
        uv_timer_t *handle;
    CODE:
        handle = (uv_timer_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_timer_t in get_repeat");
        RETVAL = uv_timer_get_repeat(handle);
    OUTPUT:
    RETVAL

void p5uv_timer__set_repeat(SV *self, uint64_t repeat)
    INIT:
        uv_timer_t *handle;
    CODE:
        handle = (uv_timer_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_timer_t in _set_repeat");
        uv_timer_set_repeat(handle, repeat);

int p5uv_timer__start(SV *self, uint64_t timeout, uint64_t repeat)
    INIT:
        uv_timer_t *handle;
    CODE:
        handle = (uv_timer_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_timer_t in _start");
        RETVAL = uv_timer_start(handle, handle_timer_cb, timeout, repeat);
    OUTPUT:
    RETVAL

int p5uv_timer_again(SV *self)
    INIT:
        uv_timer_t *handle;
    CODE:
        handle = (uv_timer_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_timer_t in again");
        RETVAL = uv_timer_again(handle);
    OUTPUT:
    RETVAL

int p5uv_timer_stop(SV *self)
    INIT:
        uv_timer_t *handle;
    CODE:
        handle = (uv_timer_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_timer_t in stop");
        RETVAL = uv_timer_stop(handle);
    OUTPUT:
    RETVAL


MODULE = UV             PACKAGE = UV::Loop      PREFIX = p5uv_loop_

PROTOTYPES: ENABLE

int p5uv_loop__close(SV *self, int is_default=0)
    PREINIT:
        uv_loop_t *loop;
        int res;
    CODE:
        RETVAL = 0;
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in _close");
        DEBUG_PRINT("Got the loop object. Is default? %i\n", is_default);

        /* drop out if we are without a loop */
        if (loop) {
            DEBUG_PRINT("Loop object is good\n");
            /* if the loop is alive, let's walk it and close everything */
            if (0 != uv_loop_alive(loop)) {
                DEBUG_PRINT("Loop is alive. We need to walk and close handles/requests.\n");
                uv_walk(loop, loop_walk_close_cb, NULL);
                DEBUG_PRINT("We need to run the loop so the handles/requests can close.\n");
                RETVAL = uv_run(loop, UV_RUN_DEFAULT);
                if (0 != RETVAL) {
                    DEBUG_PRINT("Loop run errored!\n");
                    croak("loop run error (%i): %s", RETVAL, uv_strerror(RETVAL));
                }
                DEBUG_PRINT("Loop run exited cleanly!\n");
            }
            DEBUG_PRINT("Loop about to close!\n");
            RETVAL = uv_loop_close(loop);
            if (0 == RETVAL) {
                DEBUG_PRINT("destroying the loop now!\n");
                if (loop->data) {
                    DEBUG_PRINT("It looks like we have loop data!\n");
                    loop->data = NULL;
                }
                DEBUG_PRINT("detaching struct from object!\n");
                res = xs_object_magic_detach_struct_rv(aTHX_ self, loop);
                if (0 != res) {
                    DEBUG_PRINT("detaching struct from object successful!\n");
                }
                if (0 == is_default) {
                    DEBUG_PRINT("freeing non-default loop's memory!\n");
                    Safefree(loop);
                }
            }
        }
    OUTPUT:
    RETVAL

void p5uv_loop__create(SV *self, int want_default)
    INIT:
        uv_loop_t *loop;
        int ret;
    CODE:
        DEBUG_PRINT("Requesting a default loop? %i\n", want_default);
        if(!xs_object_magic_has_struct_rv(aTHX_ self)) {
            if (want_default == 0) {
                Newx(loop, 1, uv_loop_t);
                if (NULL == loop) {
                    croak("Unable to allocate space for a new loop");
                }
                ret = uv_loop_init(loop);
                if (0 != ret) {
                    Safefree(loop);
                    croak("Error initializing loop (%i): %s", ret, uv_strerror(ret));
                }
            }
            else {
                DEBUG_PRINT("Getting the default loop!\n");
                loop = uv_default_loop();
                if (!loop) {
                    DEBUG_PRINT("Loop error when getting default loop!\n");
                    croak("Error getting a new default loop");
                }
            }
            DEBUG_PRINT("Attaching loop to object's magic!\n");
            xs_object_magic_attach_struct(aTHX_ SvRV(self), loop);
            DEBUG_PRINT("Saving a reference to the object in loop->data!\n");
            loop->data = SvREFCNT_inc(ST(0));
        }

void p5uv_loop__has_struct(SV *self)
    PPCODE:
        EXTEND(SP, 1);
        if(xs_object_magic_has_struct_rv(aTHX_ self))
            PUSHs(&PL_sv_yes);
        else
            PUSHs(&PL_sv_no);

void p5uv_loop__walk(SV *self)
    PREINIT:
        uv_loop_t *loop;
        SV **callback;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in _walk");
        callback = hv_fetchs((HV*)SvRV(self), "_on_walk", FALSE);
        if (callback && SvOK(*callback)) {
            uv_walk(loop, loop_walk_cb, *callback);
        }
        else {
            uv_walk(loop, loop_walk_cb, NULL);
        }

int p5uv_loop_alive(SV *self)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in alive");
        RETVAL = uv_loop_alive(loop);
    OUTPUT:
    RETVAL

int p5uv_loop_backend_fd(SV *self)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in backend_fd");
        RETVAL = uv_backend_fd(loop);
    OUTPUT:
    RETVAL

int p5uv_loop_backend_timeout(SV *self)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in backend_timeout");
        RETVAL = uv_backend_timeout(loop);
    OUTPUT:
    RETVAL

int p5uv_loop_configure(SV *self, uv_loop_option option, int value)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in configure");
        RETVAL = uv_loop_configure(loop, option, value);
    OUTPUT:
    RETVAL

uint64_t p5uv_loop_now(SV *self)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in now");
        RETVAL = uv_now(loop);
    OUTPUT:
    RETVAL

int p5uv_loop_run(SV *self, uv_run_mode mode=UV_RUN_DEFAULT)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in run");
        RETVAL = uv_run(loop, mode);
    OUTPUT:
    RETVAL

void p5uv_loop_stop(SV *self)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in stop");
        uv_stop(loop);

int p5uv_loop_update_time(SV *self)
    PREINIT:
        uv_loop_t *loop;
    CODE:
        loop = (uv_loop_t *)xs_object_magic_get_struct_rv_pretty(aTHX_ self, "uv_loop_t in update_time");
        uv_update_time(loop);
