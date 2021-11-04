#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#define NEED_newRV_noinc_GLOBAL
#define NEED_sv_pvn_force_flags_GLOBAL
#include "ppport.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xlibint.h>
#include <X11/extensions/XTest.h>
#ifdef HAVE_XCOMPOSITE
#include <X11/extensions/Xcomposite.h>
#endif
#ifdef HAVE_XFIXES
#include <X11/extensions/Xfixes.h>
#endif
#ifdef HAVE_XRENDER
#include <X11/extensions/Xrender.h>
#endif

#include "PerlXlib.h"
void PerlXlib_sanity_check_data_structures();

static SV* _cache_atom(HV *cache, Atom val, const char *name) {
    SV **ent, *sv;
    ent= hv_fetch(cache, name, strlen(name), 1);
    if (!ent) return NULL;
    /* Create a read-only dualvar */
    sv= *ent;
    if (SvOK(sv)) {
        /* If a user supplies the same value twice in the list, this could attempt to try
          * adding the item to the cache twice. */
        if (SvIV(sv) == val)
            return sv;
        else {
            sv_2mortal(sv);
            *ent= sv= newSV(0);
        }
    }
    SvUPGRADE(sv, SVt_PVMG);
    sv_setpvn(sv, name, strlen(name));
    SvIV_set(sv, val);
    SvIOK_on(sv);
    SvREADONLY_on(sv);
    /* add it to the hash by both name and value */
    if (hv_store(cache, (void*) &val, sizeof(val), sv, 0)) {
        SvREFCNT_inc(sv);
        return sv;
    }
    else
        return NULL;
}

/* This provides efficient detection of whether an attribute is being passed as
 * an integer, or something symbolic. */
static Bool is_an_integer(SV *sv) {
    size_t len, i;
    const char *str;

    if (SvIOK(sv) || SvUOK(sv) || (SvNOK(sv) && ((NV)(IV)SvNV(sv)) == SvNV(sv)))
        return 1;
    if (!SvOK(sv))
        return 0;
    str= SvPV(sv, len);
    for (i= 0; i < len; i++)
        if (!isDIGIT(str[i])) return 0;
    return len > 0;
}

MODULE = X11::Xlib                PACKAGE = X11::Xlib

void
_sanity_check_data_structures()
    PPCODE:
        PerlXlib_sanity_check_data_structures();

Bool
_is_an_integer(str=NULL)
    SV *str
    PROTOTYPE: ;$
    CODE:
        dUNDERBAR;
        if (!str) str= UNDERBAR;
        RETVAL= is_an_integer(str);
    OUTPUT:
        RETVAL

int
_prop_format_width(fmt)
    int fmt
    CODE:
        RETVAL= fmt == 8? sizeof(char) : fmt == 16? sizeof(short) : fmt == 32? sizeof(long) : 0;
    OUTPUT:
        RETVAL

void
_unpack_prop(fmt, buf, n)
    int fmt
    SV *buf
    size_t n
    ALIAS:
        _unpack_prop_signed = 0
        _unpack_prop_unsigned = 1
    INIT:
        const char *p;
        size_t len, step, i;
    PPCODE:
        /* As discovered by eslafgh in #6, X11 uses 32 to mean 'long' not 'whatever is 32 bits'
         * which is annoying to unpack, as perl unpack requires either 'q' or 'l' and would need
         * to 'use Config' to find out which.
         * It's simpler just to implement an unpack for it directly.
         */
        step= fmt == 8? sizeof(char) : fmt == 16? sizeof(short) : fmt == 32? sizeof(long) : 0;
        if (!step || ix < 0 || ix > 1)
            croak("Format must be 8, 16, or 32, and mode must be signed or unsigned");
        p= SvPV(buf, len);
        if (step * n > len)
            croak("Insufficient buffer (%d) to decode %d * %d bytes", (int) len, (int) n, (int) step);
        EXTEND(SP, n);
        switch (fmt+ix) {
        case  8: for (i= 0; i < n; i++) mPUSHi(((         char *)p)[i]); break;
        case  9: for (i= 0; i < n; i++) mPUSHu(((unsigned char *)p)[i]); break;
        case 16: for (i= 0; i < n; i++) mPUSHi(((         short*)p)[i]); break;
        case 17: for (i= 0; i < n; i++) mPUSHu(((unsigned short*)p)[i]); break;
        case 32: for (i= 0; i < n; i++) mPUSHi(((         long *)p)[i]); break;
        case 33: for (i= 0; i < n; i++) mPUSHu(((unsigned long *)p)[i]); break;
        }
        XSRETURN(n);

# Threading Functions (fn_thread) --------------------------------------------

int
XInitThreads()

void
XLockDisplay(dpy)
    Display *dpy

void
XUnlockDisplay(dpy)
    Display *dpy

# Connection Functions (fn_conn) ---------------------------------------------

void
XDisplayName(str_sv = NULL)
    SV * str_sv
    INIT:
        char *name;
        size_t unused;
    PPCODE:
        name= XDisplayName(str_sv && SvOK(str_sv)? SvPV(str_sv, unused) : NULL);
        XPUSHs(sv_2mortal(newSVpv( name, 0 )));

void
XOpenDisplay(connection_string = NULL)
    char * connection_string
    INIT:
        Display *dpy;
        SV *tmp, *self;
    PPCODE:
        if (SvTRUE(get_sv("X11::Xlib::_error_fatal_trapped", GV_ADD)))
            croak("Cannot call further Xlib functions after fatal Xlib error");
        dpy= XOpenDisplay(connection_string);
        self= PerlXlib_get_display_objref(dpy, PerlXlib_AUTOCREATE);
        if (SvROK(self)) {
            if (!hv_store((HV*) SvRV(self), "autoclose", 9, (tmp=newSViv(1)), 0)) {
                sv_2mortal(tmp);
                croak("Failed to set autoclose");
            }
        }
        PUSHs(self);

void
_pointer_value(obj)
    SV *obj
    INIT:
        Display *dpy;
        SV **fp= NULL;
    PPCODE:
        dpy= PerlXlib_display_objref_get_pointer(obj, PerlXlib_OR_NULL);
        if (!dpy && SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVHV) {
            /* in the case of a dead connection, the pointer value moves to a hash field */
            fp= hv_fetch((HV*)SvRV(obj), "_pointer_value", 14, 0);
        }
        PUSHs(dpy? sv_2mortal(newSVpvn((const char*)&dpy, sizeof(dpy)))
            : (fp && *fp && SvPOK(*fp))? *fp
            : &PL_sv_undef);

void
_set_pointer_value(obj, dpy_val)
    SV *obj
    SV *dpy_val
    PPCODE:
        if (SvOK(dpy_val) && (!SvPOK(dpy_val) || SvCUR(dpy_val) != sizeof(Display*)))
            croak("Invalid pointer value (should be scalar of %d bytes)", (int) sizeof(Display*));
        PerlXlib_objref_set_pointer(obj, SvOK(dpy_val)? (Display*)(void*)SvPVX(dpy_val) : NULL, "Display");

char *
XServerVendor(dpy)
    Display * dpy

int
XVendorRelease(dpy)
    Display * dpy

int
ConnectionNumber(dpy)
    Display * dpy

void
XSetCloseDownMode(dpy, close_mode)
    Display * dpy
    int close_mode
    CODE:
        XSetCloseDownMode(dpy, close_mode);

void
XCloseDisplay(dpy_sv)
    SV *dpy_sv
    INIT:
        Display *dpy;
    CODE:
        dpy= PerlXlib_display_objref_get_pointer(dpy_sv, PerlXlib_OR_DIE);
        XCloseDisplay(dpy);
        PerlXlib_objref_set_pointer(dpy_sv, NULL, NULL); /* mark as closed */
        hv_delete((HV*)SvRV(dpy_sv), "autoclose", 9, G_DISCARD);

# Atom Functions (fn_atom) ---------------------------------------------------

Atom
XInternAtom(dpy, atom_name, only_if_exists)
    Display *dpy
    char *atom_name
    Bool only_if_exists

void
XInternAtoms(dpy, atom_names, only_if_exists)
    Display *dpy
    AV *atom_names
    Bool only_if_exists
    INIT:
        char **name_array;
        Atom *atom_array;
        int n, i;
        SV **elem;
        AV *ret_av;
    PPCODE:
        n= av_len(atom_names)+1;
        Newx(name_array, n, char*);
        SAVEFREEPV(name_array);
        Newxz(atom_array, n, Atom);
        SAVEFREEPV(atom_array);
        for (i= 0; i < n; i++) {
            elem= av_fetch(atom_names, i, 0);
            if (!elem || !*elem || !SvPOK(*elem))
                croak("Atom name must be a string");
            name_array[i]= SvPV_nolen(*elem);
        }
        XInternAtoms(dpy, name_array, n, only_if_exists, atom_array);
        ret_av= newAV();
        PUSHs(sv_2mortal(newRV_noinc((SV*)ret_av)));
        for (i= 0; i < n; i++)
            av_store(ret_av, i, newSVuv(atom_array[i]));

void
XGetAtomName(dpy, atom)
    Display *dpy
    Atom atom
    INIT:
        char *name= NULL;
    PPCODE:
        name= XGetAtomName(dpy, atom);
        if (name) {
            PUSHs(sv_2mortal(newSVpv(name, 0)));
            XFree(name);
        }

void
XGetAtomNames(dpy, atoms)
    Display *dpy
    AV *atoms
    INIT:
        Atom *atom_array;
        char **name_array;
        int n, i;
        SV **elem;
        AV *ret_av;
    PPCODE:
        n= av_len(atoms)+1;
        Newx(atom_array, n, Atom);
        SAVEFREEPV(atom_array);
        Newxz(name_array, n, char*);
        SAVEFREEPV(name_array);
        for (i= 0; i < n; i++) {
            elem= av_fetch(atoms, i, 0);
            if (!elem || !*elem || !(SvIOK(*elem) || SvUOK(*elem)))
                croak("Atom values must be integers");
            atom_array[i]= SvIV(*elem);
        }
        XGetAtomNames(dpy, atom_array, n, name_array);
        ret_av= newAV();
        PUSHs(sv_2mortal(newRV_noinc((SV*)ret_av)));
        for (i= 0; i < n; i++) {
            av_store(ret_av, i, name_array[i]? newSVpv(name_array[i], 0) : newSV(0));
            if (name_array[i]) XFree(name_array[i]);
        }

void
_resolve_atoms(dpy_obj, ...)
    SV *dpy_obj
    ALIAS:
        X11::Xlib::Display::atom = 0
        X11::Xlib::Display::mkatom = 1
    INIT:
        Display *dpy= PerlXlib_display_objref_get_pointer(dpy_obj, PerlXlib_OR_DIE);
        size_t len, item0, n_name_lookup= 0, n_atom_lookup= 0;
        Atom  *atom_array,   atom_array_on_stack[20], atom;
        char **name_array,  *name_array_on_stack[20], *name;
        int   *atom_dest, *name_dest, link_array_on_stack[20], i, n_arg;
        SV  **ent, *sv;
        HV *cache= NULL;
    PPCODE:
        item0= 1;
        n_arg= items-item0;
        if (n_arg <= 20) {
            atom_array= atom_array_on_stack;
            atom_dest=  link_array_on_stack;
            name_array= name_array_on_stack;
            name_dest=  atom_dest + 20 - 1;
        } else {
            Newx(atom_array, n_arg, Atom);
            SAVEFREEPV(atom_array);
            Newx(atom_dest,  n_arg, int);
            SAVEFREEPV(atom_dest);
            Newx(name_array, n_arg, char*);
            SAVEFREEPV(name_array);
            name_dest= atom_dest + n_arg - 1;
        }
        if (SvTYPE(SvRV(dpy_obj)) == SVt_PVHV) {
            if (ent= hv_fetch((HV*) SvRV(dpy_obj), "atom_cache", 10, 1)) {
                if (SvROK(*ent) && SvTYPE(SvRV(*ent)) == SVt_PVHV)
                    cache= (HV*) SvRV(*ent);
                else
                    sv_setsv(*ent, sv_2mortal(newRV_noinc((SV*) (cache= newHV()))));
            }
        }
        if (!cache)
            croak("atom_cache is not a hashref");
        /* Inspect each parameter and decide whether it is an atom (number) or name.
          * Replace stack items with the value from cache, and put the unresolved ones
          * into arrays for laters processing. */
        for (i= item0; i < items; i++) {
            sv= ST(i);
            if (is_an_integer(sv)) {
                atom= SvIV(sv);
                ent= hv_fetch(cache, (void*) &atom, sizeof(atom), 0);
                if (ent && *ent && SvOK(*ent))
                    ST(i)= *ent;                   /* found in cache */
                else if (!atom)
                    ST(i)= &PL_sv_undef;           /* can't resolve */
                else {
                    atom_dest[n_atom_lookup]= i;   /* store result here after looking it up */
                    atom_array[n_atom_lookup++]= atom;
                }
            }
            else {
                name= SvPV(sv, len);
                ent= hv_fetch(cache, name, len, 0);
                if (ent && *ent && SvOK(*ent))
                    ST(i)= *ent;
                else if (!len)
                    ST(i)= &PL_sv_undef;
                else {
                    name_dest[-n_name_lookup]= i;
                    name_array[n_name_lookup++]= name;
                }
            }
        }
        if (n_name_lookup) {
            XInternAtoms(dpy, name_array, n_name_lookup, ix == 0? 1 : 0, atom_array + n_atom_lookup);
            for (i= 0; i < n_name_lookup; i++) {
                if (atom_array[n_atom_lookup + i]) {
                    sv= _cache_atom(cache, atom_array[n_atom_lookup + i], name_array[i]);
                    if (sv) ST(name_dest[-i])= sv;
                }
            }
        }
        if (n_atom_lookup) {
            XGetAtomNames(dpy, atom_array, n_atom_lookup, name_array + n_name_lookup);
            for (i= 0; i < n_atom_lookup; i++) {
                if (name_array[n_name_lookup + i]) {
                    sv= _cache_atom(cache, atom_array[i], name_array[n_name_lookup + i]);
                    if (sv) ST(atom_dest[i])= sv;
                }
            }
        }
        /* First arg was $self, so shift down all parameters by one for the return value */
        for (i= item0; i < items; i++) {
            ST(i-item0)= ST(i);
            ST(i)= &PL_sv_undef;
        }
        XSRETURN(items-item0);

# Event Functions (fn_event) -------------------------------------------------

int
XQLength(dpy)
    Display *dpy

int
XPending(dpy)
    Display *dpy

int
XEventsQueued(dpy, mode)
    Display *dpy
    int mode

void
XNextEvent(dpy, event_sv)
    Display * dpy
    SV *event_sv
    INIT:
        XEvent *event;
    CODE:
        event= (XEvent*) PerlXlib_get_struct_ptr(
            event_sv, 2,
            "X11::Xlib::XEvent", sizeof(XEvent),
            (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
        );
        XNextEvent(dpy, event);
        sv_bless(event_sv, gv_stashpv(PerlXlib_xevent_pkg_for_type(event->type), GV_ADD));

Bool
XCheckWindowEvent(dpy, wnd, event_mask, event_return)
    Display * dpy
    Window wnd
    int event_mask
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckWindowEvent(dpy, wnd, event_mask, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XCheckTypedWindowEvent(dpy, wnd, event_type, event_return)
    Display * dpy
    Window wnd
    int event_type
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckTypedWindowEvent(dpy, wnd, event_type, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XCheckMaskEvent(dpy, event_mask, event_return)
    Display * dpy
    int event_mask
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckMaskEvent(dpy, event_mask, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XCheckTypedEvent(dpy, event_type, event_return)
    Display * dpy
    int event_type
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckTypedEvent(dpy, event_type, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XSendEvent(dpy, wnd, propagate, event_mask, event_send)
    Display * dpy
    Window wnd
    Bool propagate
    long event_mask
    XEvent *event_send

void
XPutBackEvent(dpy, event)
    Display * dpy
    XEvent *event

void
XFlush(dpy)
    Display * dpy

void
XSync(dpy, discard=0)
    Display *  dpy
    int discard

void
XSelectInput(dpy, wnd, mask)
    Display * dpy
    Window wnd
    int mask

Bool
_wait_event(dpy, wnd, event_type, event_mask, event_return, max_wait_msec)
    Display * dpy
    Window wnd
    int event_type
    int event_mask
    SV *event_return
    int max_wait_msec
    INIT:
        XEvent event, *dest;
        int retried= 0;
        fd_set fds;
        int x11_fd;
        struct timeval tv;
    CODE:
        retry:
        RETVAL= wnd && event_type? XCheckTypedWindowEvent(dpy, wnd, event_type, &event)
              : wnd?               XCheckWindowEvent(dpy, wnd, event_mask, &event)
              : event_type?        XCheckTypedEvent(dpy, event_type, &event)
              :                    XCheckMaskEvent(dpy, event_mask, &event);
        if (!RETVAL && !retried) {
            x11_fd= ConnectionNumber(dpy);
            tv.tv_sec= max_wait_msec / 1000;
            tv.tv_usec= (max_wait_msec % 1000)*1000;
            FD_ZERO(&fds);
            FD_SET(x11_fd, &fds);
            if (select(x11_fd+1, &fds, NULL, &fds, &tv) > 0) {
                retried= 1;
                goto retry;
            }
        }
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 1,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

void
XGetErrorText(dpy, code)
    Display *dpy
    int code
    INIT:
        SV *ret;
        int len;
    PPCODE:
        ret= sv_2mortal(newSV(64));
        SvPOK_on(ret);
        XGetErrorText(dpy, code, SvPVX(ret), 64);
        len= strlen(SvPVX(ret));
        if (len >= 63) {
            /* Try again with larger buffer */
            SvGROW(ret, 1024);
            XGetErrorText(dpy, code, SvPVX(ret), 1024);
            len= strlen(SvPVX(ret));
        }
        SvCUR_set(ret, len);
        PUSHs(ret);

void
XGetErrorDatabaseText(dpy, name, message, default_string= NULL)
    Display *dpy
    char *name
    char *message
    SV *default_string
    INIT:
        SV *ret;
        char *def;
        size_t lim, len;
    PPCODE:
        if (default_string) {
            def= SvPV(default_string, lim);
            ++lim;
        } else {
            def= "";
            lim= 64;
        }
        if (lim < 64) lim= 64;
        ret= sv_2mortal(newSV(lim));
        SvPOK_on(ret);
        XGetErrorDatabaseText(dpy, name, message, def, SvPVX(ret), lim);
        len= strlen(SvPVX(ret));
        if (len >= lim-1) {
            /* Try again with larger buffer */
            SvGROW(ret, 1024);
            XGetErrorDatabaseText(dpy, name, message, def, SvPVX(ret), 1024);
            len= strlen(SvPVX(ret));
        }
        SvCUR_set(ret, len);
        PUSHs(ret);

void
_extension_for_opcode(dpy, opcode)
    Display *dpy
    int opcode
    INIT:
        _XExtension *ext;
    PPCODE:
        for (ext= dpy->ext_procs; ext && (ext->codes.major_opcode != opcode); ext= ext->next);
        if (ext)
            PUSHs(sv_2mortal(newSVpv(ext->name, 0)));

# Screen Functions (fn_screen) -----------------------------------------------

int
DefaultScreen(dpy)
    Display * dpy

int
ScreenCount(dpy)
    Display * dpy

Window
RootWindow(dpy, screen=DefaultScreen(dpy))
    Display *  dpy
    ScreenNumber screen
    CODE:
        RETVAL = RootWindow(dpy, screen);
    OUTPUT:
        RETVAL

Colormap
DefaultColormap(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DefaultDepth(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

GC
DefaultGC(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

Visual *
DefaultVisual(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayWidth(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayHeight(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayWidthMM(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayHeightMM(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

# Visual Functions (fn_vis) --------------------------------------------------

Bool
XMatchVisualInfo(dpy, screen, depth, class, vis_return)
    Display * dpy
    ScreenNumber screen
    int depth
    int class
    XVisualInfo *vis_return

void
XGetVisualInfo(dpy, vinfo_mask, vinfo_template)
    Display * dpy
    int vinfo_mask
    XVisualInfo *vinfo_template
    INIT:
        XVisualInfo *list;
        int n= 0, i;
    PPCODE:
        list= XGetVisualInfo(dpy, vinfo_mask, vinfo_template, &n);
        if (list) {
            EXTEND(SP, n);
            for (i= 0; i<n; i++) {
                PUSHs(sv_2mortal(
                    sv_setref_pvn(newSV(0), "X11::Xlib::XVisualInfo", (void*)(list+i), sizeof(XVisualInfo))
                ));
            }
            XFree(list);
        }

int
XVisualIDFromVisual(vis)
    Visual *vis

Colormap
XCreateColormap(dpy, wnd=RootWindow(dpy, DefaultScreen(dpy)), visual=DefaultVisual(dpy, DefaultScreen(dpy)), alloc=AllocNone)
    Display * dpy
    Window wnd
    Visual *visual
    int alloc

void
XFreeColormap(dpy, cmap)
    Display * dpy
    int cmap

# Pixmap Functions (fn_pix) --------------------------------------------------

Pixmap
XCreatePixmap(dpy, drw, width, height, depth)
    Display * dpy
    Drawable drw
    int width
    int height
    int depth

void
XFreePixmap(dpy, pix)
    Display * dpy
    Pixmap pix

Pixmap
XCreateBitmapFromData(dpy, drw, data, width, height)
    Display * dpy
    Drawable drw
    SV * data
    int width
    int height
    CODE:
        if (!SvPOK(data) || SvCUR(data) < ( (width * height + 7) / 8 ))
            croak( "'data' must be at least %d bytes long", ( (width * height + 7) / 8 ));
        RETVAL = XCreateBitmapFromData(dpy, drw, SvPVX(data), width, height);
    OUTPUT:
        RETVAL

Pixmap
XCreatePixmapFromBitmapData(dpy, drw, data, width, height, fg, bg, depth)
    Display * dpy
    Drawable drw
    SV * data
    int width
    int height
    long fg
    long bg
    int depth
    CODE:
        if (!SvPOK(data) || SvCUR(data) < ( (width * height + 7) / 8 ))
            croak( "'data' must be at least %d bytes long", ( (width * height + 7) / 8 ));
        RETVAL = XCreatePixmapFromBitmapData(dpy, drw, SvPVX(data), width, height, fg, bg, depth);
    OUTPUT:
        RETVAL

# Window Functions (fn_win) --------------------------------------------------

Window
XCreateWindow(dpy, parent, x, y, w, h, border= 0, depth= CopyFromParent, class= CopyFromParent, visual= CopyFromParent, attr_mask= 0, attrs= NULL)
    Display * dpy
    Window parent
    int x
    int y
    int w
    int h
    int border
    int depth
    int class
    VisualOrNull visual
    int attr_mask
    XSetWindowAttributes *attrs
    CODE:
        if (attr_mask && !attrs)
            croak("Attrs may only be NULL if attr_mask is 0");
        RETVAL = XCreateWindow(dpy, parent, x, y, w, h, border, depth, class, visual, attr_mask, attrs);
    OUTPUT:
        RETVAL

Window
XCreateSimpleWindow(dpy, parent, x, y, w, h, border_width= 0, border_color= 0, background_color= 0)
    Display * dpy
    Window parent
    int x
    int y
    int w
    int h
    int border_width
    int border_color
    int background_color

void
XDestroyWindow(dpy, wnd)
    Display * dpy
    Window wnd

void
XMapWindow(dpy, wnd)
    Display * dpy
    Window wnd

void
XUnmapWindow(dpy, wnd)
    Display * dpy
    Window wnd

void
XGetGeometry(dpy, wnd, root_out=NULL, x_out=NULL, y_out=NULL, width_out=NULL, height_out=NULL, border_out=NULL, depth_out=NULL)
    Display * dpy
    Window wnd
    SV *root_out
    SV *x_out
    SV *y_out
    SV *width_out
    SV *height_out
    SV *border_out
    SV *depth_out
    INIT:
        Window root;
        int x, y, ret;
        unsigned int w, h, bw, d;
    PPCODE:
        ret = XGetGeometry(dpy, wnd, &root, &x, &y, &w, &h, &bw, &d);
        if (items > 2) {
            /* C-style API */
            warn("C-style XGetGeometry is deprecated; use 2 arguments to return a list, instead");
            if (root_out)   sv_setuv(root_out, root);
            if (x_out)      sv_setiv(x_out, x);
            if (y_out)      sv_setiv(y_out, y);
            if (width_out)  sv_setuv(width_out, w);
            if (height_out) sv_setuv(height_out, h);
            if (border_out) sv_setuv(border_out, bw);
            if (depth_out)  sv_setuv(depth_out, d);
            PUSHs(sv_2mortal(newSViv(ret)));
        }
        /* perl-style API */
        else if (ret) {
            EXTEND(SP, 7);
            PUSHs(sv_2mortal(newSVuv(root)));
            PUSHs(sv_2mortal(newSViv(x)));
            PUSHs(sv_2mortal(newSViv(y)));
            PUSHs(sv_2mortal(newSVuv(w)));
            PUSHs(sv_2mortal(newSVuv(h)));
            PUSHs(sv_2mortal(newSVuv(bw)));
            PUSHs(sv_2mortal(newSVuv(d)));
        }

void
XListProperties(dpy, wnd)
    Display *dpy
    Window wnd
    INIT:
        int num_props= 0, i;
        AV *prop_av;
        Atom *atom_array;
    PPCODE:
        atom_array= XListProperties(dpy, wnd, &num_props);
        if (atom_array) {
            EXTEND(SP, num_props);
            for (i= 0; i < num_props; i++)
                PUSHs(sv_2mortal(newSVuv(atom_array[i])));
            XFree(atom_array);
        }

int
XGetWindowProperty(dpy, wnd, prop_atom, long_offset, long_length, delete, req_type, actual_type_out, actual_format_out, nitems_out, bytes_after_out, data_out)
    Display *dpy
    Window wnd
    Atom prop_atom
    long long_offset
    long long_length
    Bool delete
    Atom req_type
    SV *actual_type_out
    SV *actual_format_out
    SV *nitems_out
    SV *bytes_after_out
    SV *data_out
    INIT:
        Atom actual_type;
        int actual_format;
        unsigned long nitems, bytes_after;
        char *data= NULL;
    CODE:
        RETVAL = XGetWindowProperty(dpy, wnd, prop_atom, long_offset, long_length, delete, req_type,
            &actual_type, &actual_format, &nitems, &bytes_after, (unsigned char**)&data);
        if (RETVAL == Success) {
            if (actual_format == 8) {
                sv_setpvn(data_out, data, nitems*sizeof(char));
            } else if (actual_format == 16) {
                sv_setpvn(data_out, data, nitems*sizeof(short));
            } else if (actual_format == 32) {
                sv_setpvn(data_out, data, nitems*sizeof(long));
            } else if (actual_format == 0) {
                sv_setpvn(data_out, data, 0);
            } else {
                XFree(data);
                croak("Un-handled 'actual_format' value %d returned by XGetWindowProperty", actual_format);
            }
            XFree(data);
            sv_setuv(actual_type_out, actual_type);
            sv_setiv(actual_format_out, actual_format);
            sv_setiv(nitems_out, nitems);
            sv_setiv(bytes_after_out, bytes_after);
        }
    OUTPUT:
        RETVAL

void
XChangeProperty(dpy, wnd, prop_atom, type, format, mode, data, nelements)
    Display *dpy
    Window wnd
    Atom prop_atom
    Atom type
    int format
    int mode
    SV *data
    int nelements
    INIT:
        int bytelen= format == 8? nelements * sizeof(char)
            : format == 16? nelements * sizeof(short)
            : format == 32? nelements * sizeof(long)
            : -1;
        size_t svlen;
        char *buffer;
    CODE:
        if (bytelen < 0)
            croak("Un-handled 'format' value %d passed to XChangeProperty", format);
        buffer= SvPV(data, svlen);
        if (bytelen > svlen)
            croak("'nelements' (%d) exceeds length of data (%d)", (int) nelements, (int) svlen);
        XChangeProperty(dpy, wnd, prop_atom, type, format, mode, buffer, nelements);

void
XDeleteProperty(dpy, wnd, prop_atom)
    Display *dpy
    Window wnd
    Atom prop_atom

void
XGetWMProtocols(dpy, wnd)
    Display *dpy
    Window wnd
    INIT:
        Atom *protocols_array= NULL;
        int n= 0, i;
    PPCODE:
        if (XGetWMProtocols(dpy, wnd, &protocols_array, &n)) {
            EXTEND(SP, n);
            for (i= 0; i < n; i++)
                PUSHs(sv_2mortal(newSVuv(protocols_array[i])));
            XFree(protocols_array);
        }

Bool
XSetWMProtocols(dpy, wnd, proto_av)
    Display *dpy
    Window wnd
    AV *proto_av
    INIT:
        Atom *protocols_array= NULL;
        int n, i;
        SV **elem;
    CODE:
        n= av_len(proto_av)+1;
        Newx(protocols_array, n, Atom);
        SAVEFREEPV(protocols_array);
        for (i= 0; i < n; i++) {
            elem= av_fetch(proto_av, i, 0);
            if (!elem || !*elem || !(SvIOK(*elem) || SvUOK(*elem)))
                croak("Expected arrayref of integer Atoms");
            protocols_array[i]= SvUV(*elem);
        }
        RETVAL = XSetWMProtocols(dpy, wnd, protocols_array, n);
    OUTPUT:
        RETVAL

int
XGetWMSizeHints(dpy, wnd, hints_out, supplied_out, property)
    Display * dpy
    Window wnd
    XSizeHints *hints_out
    SV *supplied_out
    Atom property
    INIT:
        long supplied;
    CODE:
        RETVAL = XGetWMSizeHints(dpy, wnd, hints_out, &supplied, property);
        sv_setiv(supplied_out, supplied);
    OUTPUT:
        RETVAL

void
XSetWMSizeHints(dpy, wnd, szhints, property)
    Display * dpy
    Window wnd
    XSizeHints *szhints
    Atom property

int
XGetWMNormalHints(dpy, wnd, hints_out, supplied_out)
    Display * dpy
    Window wnd
    SV *hints_out
    SV *supplied_out
    INIT:
        long supplied;
        XSizeHints szhints, *dest;
    CODE:
        RETVAL = XGetWMNormalHints(dpy, wnd, &szhints, &supplied);
        if (RETVAL) {
            dest= (XSizeHints*) PerlXlib_get_struct_ptr(
                hints_out, 1,
                "X11::Xlib::XSizeHints", sizeof(XSizeHints),
                (PerlXlib_struct_pack_fn*) PerlXlib_XSizeHints_pack
            );
            memcpy(dest, &szhints, sizeof(szhints));
            sv_setiv(supplied_out, supplied);
        }
    OUTPUT:
        RETVAL

void
XSetWMNormalHints(dpy, wnd, szhints)
    Display *dpy
    Window wnd
    XSizeHints *szhints

int
XGetWindowAttributes(dpy, wnd, attrs_out)
    Display *dpy
    Window wnd
    SV *attrs_out
    INIT:
        XWindowAttributes attr, *dest;
    CODE:
        RETVAL = XGetWindowAttributes(dpy, wnd, &attr);
        if (RETVAL) {
            dest= (XWindowAttributes*) PerlXlib_get_struct_ptr(
                attrs_out, 1,
                "X11::Xlib::XWindowAttributes", sizeof(XWindowAttributes),
                (PerlXlib_struct_pack_fn*) PerlXlib_XWindowAttributes_pack
            );
            memcpy(dest, &attr, sizeof(attr));
        }
    OUTPUT:
        RETVAL

void
XChangeWindowAttributes(dpy, wnd, valuemask, attributes)
    Display *dpy
    Window wnd
    unsigned valuemask
    XSetWindowAttributes *attributes

void
XSetWindowBackground(dpy, wnd, background_pixel)
    Display *dpy
    Window wnd
    unsigned background_pixel

void
XSetWindowBackgroundPixmap(dpy, wnd, background_pixmap)
    Display *dpy
    Window wnd
    Pixmap background_pixmap

void
XSetWindowBorder(dpy, wnd, border_pixel)
    Display *dpy
    Window wnd
    unsigned border_pixel

void
XSetWindowBorderPixmap(dpy, wnd, border_pixmap)
    Display *dpy
    Window wnd
    Pixmap border_pixmap

void
XSetWindowColormap(dpy, wnd, colormap)
    Display *dpy
    Window wnd
    Colormap colormap

void
XDefineCursor(dpy, wnd, cursor = None)
    Display *dpy
    Window wnd
    Cursor cursor

void
XUndefineCursor(dpy, wnd)
    Display *dpy
    Window wnd

void
XReparentWindow(dpy, wnd, parent, x, y)
    Display *dpy
    Window wnd
    Window parent
    int x
    int y

void
XConfigureWindow(dpy, wnd, value_mask, values)
    Display *dpy
    Window wnd
    unsigned int value_mask
    XWindowChanges *values

void
XMoveWindow(dpy, wnd, x, y)
    Display *dpy
    Window wnd
    int x
    int y

void
XResizeWindow(dpy, wnd, width, height)
    Display *dpy
    Window wnd
    unsigned width
    unsigned height

void
XMoveResizeWindow(dpy, wnd, x, y, width, height)
    Display *dpy
    Window wnd
    int x
    int y
    unsigned width
    unsigned height

void
XSetWindowBorderWidth(dpy, wnd, width)
    Display *dpy
    Window wnd
    unsigned width

void
XQueryTree(dpy, wnd)
    Display *dpy
    Window wnd
    INIT:
        Window root, parent, *children;
        int nchildren, i;
    PPCODE:
        if (XQueryTree(dpy, wnd, &root, &parent, &children, &nchildren)) {
            PUSHs(sv_2mortal(newSViv(root)));
            PUSHs(sv_2mortal(newSViv(parent)));
            for (i= 0; i < nchildren; i++)
                XPUSHs(sv_2mortal(newSViv(children[i])));
            if (children) XFree(children);
        }

void
XRaiseWindow(dpy, wnd)
    Display *dpy
    Window wnd

void
XLowerWindow(dpy, wnd)
    Display *dpy
    Window wnd

void
XCirculateSubwindows(dpy, wnd, direction)
    Display *dpy
    Window wnd
    int direction

void
XRestackWindows(dpy, windows_av)
    Display *dpy
    AV* windows_av
    INIT:
        int n, i;
        Window *wndarray;
        SV **elem;
    PPCODE:
        n= av_len(windows_av)+1;
        Newx(wndarray, n, Window);
        SAVEFREEPV(wndarray);
        for (i= 0; i < n; i++) {
            elem= av_fetch(windows_av, i, 0);
            if (!elem) croak("can't load elem %d", i);
            wndarray[i]= PerlXlib_sv_to_xid(*elem);
        }
        XRestackWindows(dpy, wndarray, n);

void
XTranslateCoordinates(dpy, src_wnd, dest_wnd, src_x, src_y)
    Display *dpy
    Window src_wnd
    Window dest_wnd
    int src_x
    int src_y
    INIT:
        int dest_x, dest_y;
        Window child;
    PPCODE:
        if (XTranslateCoordinates(dpy, src_wnd, dest_wnd, src_x, src_y, &dest_x, &dest_y, &child)) {
            PUSHs(sv_2mortal(newSViv(dest_x)));
            PUSHs(sv_2mortal(newSViv(dest_y)));
            PUSHs(sv_2mortal(newSViv(child)));
        }

# XTest Functions (fn_xtest) -------------------------------------------------

int
XTestFakeMotionEvent(dpy, screen, x, y, EventSendDelay = 10)
    Display *  dpy
    int screen
    int x
    int y
    int EventSendDelay

int
XTestFakeButtonEvent(dpy, button, pressed, EventSendDelay = 10);
    Display *  dpy
    int button
    int pressed
    int EventSendDelay

int
XTestFakeKeyEvent(dpy, kc, pressed, EventSendDelay = 10)
    Display *  dpy
    unsigned char kc
    int pressed
    int EventSendDelay

# KeySym Utility Functions (fn_keysym) ---------------------------------------

char *
XKeysymToString(keysym)
    KeySym keysym
    CODE:
        RETVAL = XKeysymToString(keysym);
    OUTPUT:
        RETVAL

unsigned long
XStringToKeysym(string)
    char * string
    CODE:
        RETVAL = XStringToKeysym(string);
    OUTPUT:
        RETVAL

void
keysym_to_codepoint(keysym)
    KeySym keysym
    INIT:
        int codepoint;
    PPCODE:
        codepoint= PerlXlib_keysym_to_codepoint(keysym);
        if (codepoint >= 0) PUSHs(sv_2mortal(newSViv(codepoint)));
        else PUSHs(&PL_sv_undef);

void
codepoint_to_keysym(codepoint)
    int codepoint
    INIT:
        KeySym sym;
    PPCODE:
        sym= PerlXlib_codepoint_to_keysym(codepoint);
        if (sym > 0) PUSHs(sv_2mortal(newSViv(sym)));
        else PUSHs(&PL_sv_undef);

void
keysym_to_char(keysym)
    KeySym keysym
    INIT:
        int codepoint;
    PPCODE:
        codepoint= PerlXlib_keysym_to_codepoint(keysym);
        if (codepoint >= 0) PUSHs(sv_2mortal(newSVpvf("%c", codepoint)));
        else PUSHs(&PL_sv_undef);

void
char_to_keysym(str)
    SV *str
    INIT:
        int codepoint;
        KeySym sym;
        char *s;
        size_t len;
    PPCODE:
        s= SvPV(str, len);
        codepoint= NATIVE_TO_UNI(DO_UTF8(str)? utf8n_to_uvchr(s, len, &len, 0) : (s[0] & 0xFF));
        sym= PerlXlib_codepoint_to_keysym(codepoint);
        if (codepoint > 0 && sym > 0) PUSHs(sv_2mortal(newSViv(sym)));
        else PUSHs(&PL_sv_undef);

int
IsKeypadKey(keysym)
    unsigned long keysym

int
IsPrivateKeypadKey(keysym)
    unsigned long keysym

int
IsPFKey(keysym)
    unsigned long keysym

int
IsFunctionKey(keysym)
    unsigned long keysym

int
IsMiscFunctionKey(keysym)
    unsigned long keysym

int
IsModifierKey(keysym)
    unsigned long keysym

void
XConvertCase(ksym, lowercase, uppercase)
    KeySym ksym
    SV *lowercase
    SV *uppercase
    INIT:
        KeySym lc, uc;
    PPCODE:
        XConvertCase(ksym, &lc, &uc);
        sv_setiv(lowercase, lc);
        sv_setiv(uppercase, uc);

# Input Functions (fn_input) -------------------------------------------------

void
XSetInputFocus(dpy, focus, revert_to, time)
    Display *dpy
    Window focus
    int revert_to
    Time time

void
XQueryKeymap(dpy)
    Display *  dpy
    PREINIT:
        char keys_return[32];
        int i, j;
    PPCODE:
        XQueryKeymap(dpy, keys_return);
        for(i=0; i<32; i++) {
            for (j=0; j<8;j++) {
                if (keys_return[i] & (1 << j))
                    XPUSHs(sv_2mortal(newSViv(i * 8 + j)));
            }
        }

int
XGrabKeyboard(dpy, wnd, owner_events, pointer_mode, keyboard_mode, timestamp)
    Display *dpy
    Window wnd
    Bool owner_events
    int pointer_mode
    int keyboard_mode
    Time timestamp

void
XUngrabKeyboard(dpy, timestamp)
    Display *dpy
    Time timestamp

void
XGrabKey(dpy, keycode, modifiers, grab_window, owner_events, pointer_mode=GrabModeAsync, keyboard_mode=GrabModeAsync)
    Display *dpy
    int keycode
    unsigned modifiers
    Window grab_window
    Bool owner_events
    int pointer_mode
    int keyboard_mode

void
XUngrabKey(dpy, keycode, modifiers, grab_window)
    Display *dpy
    int keycode
    unsigned modifiers
    Window grab_window

void
XQueryPointer(dpy, wnd)
    Display *dpy
    Window wnd
    INIT:
        Window root, child;
        int root_x, root_y, win_x, win_y;
        unsigned mask;
    PPCODE:
        if (XQueryPointer(dpy, wnd, &root, &child, &root_x, &root_y, &win_x, &win_y, &mask)) {
            EXTEND(SP, 7);
            PUSHs(sv_2mortal(newSVuv(root)));
            PUSHs(sv_2mortal(newSVuv(child)));
            PUSHs(sv_2mortal(newSViv(root_x)));
            PUSHs(sv_2mortal(newSViv(root_y)));
            PUSHs(sv_2mortal(newSViv(win_x)));
            PUSHs(sv_2mortal(newSViv(win_y)));
            PUSHs(sv_2mortal(newSVuv(mask)));
        }

int
XGrabPointer(dpy, wnd, owner_events, event_mask, pointer_mode, keyboard_mode, confine_to, cursor, timestamp)
    Display *dpy
    Window wnd
    Bool owner_events
    unsigned int event_mask
    int pointer_mode
    int keyboard_mode
    Window confine_to
    Cursor cursor
    Time timestamp

void
XUngrabPointer(dpy, timestamp)
    Display *dpy
    Time timestamp

void
XGrabButton(dpy, button, modifiers, wnd, owner_events, event_mask, pointer_mode, keyboard_mode, confine_to, cursor)
    Display *dpy
    unsigned button
    unsigned modifiers
    Window wnd
    Bool owner_events
    unsigned event_mask
    int pointer_mode
    int keyboard_mode
    Window confine_to
    Cursor cursor

void
XUngrabButton(dpy, button, modifiers, wnd)
    Display *dpy
    unsigned button
    unsigned modifiers
    Window wnd

void
XAllowEvents(dpy, event_mode, timestamp)
    Display *dpy
    int event_mode
    Time timestamp

unsigned long
keyboard_leds(dpy)
    Display *dpy;
    PREINIT:
        XKeyboardState state;
    CODE:
        XGetKeyboardControl(dpy, &state);
        RETVAL = state.led_mask;
    OUTPUT:
        RETVAL

void
_auto_repeat(dpy)
    Display *dpy;
    PREINIT:
        XKeyboardState state;
        int i, j;
    CODE:
        XGetKeyboardControl(dpy, &state);
        for(i=0; i<32; i++) {
            for (j=0; j<8; j++) {
                if (state.auto_repeats[i] & (1 << j))
                    XPUSHs(sv_2mortal(newSViv(i * 8 + j)));
            }
        }

void
XBell(dpy, percent)
    Display *  dpy
    int percent

# Keyboard Mapping Functions (fn_keymap) -------------------------------------

void
XDisplayKeycodes(dpy, minkey_sv, maxkey_sv)
    Display *dpy
    SV *minkey_sv
    SV *maxkey_sv
    INIT:
        int minkey, maxkey;
    PPCODE:
        XDisplayKeycodes(dpy, &minkey, &maxkey);
        sv_setiv(minkey_sv, minkey);
        sv_setiv(maxkey_sv, maxkey);

void
XGetKeyboardMapping(dpy, fkeycode, count = 1)
    Display * dpy
    unsigned int fkeycode
    int count
    PREINIT:
        int creturn;
        KeySym * keysym;
        int i = 0;
    PPCODE:
        keysym = XGetKeyboardMapping(dpy, fkeycode, count, &creturn);
        EXTEND(SP, creturn * count -1);
        for (i=0; i < creturn * count; i++)
            XPUSHs(sv_2mortal(newSVuv(keysym[i])));
        XFree(keysym);

void
load_keymap(dpy, symbolic=2, minkey=0, maxkey=255)
    Display *dpy
    int symbolic
    int minkey
    int maxkey
    INIT:
        int xmin, xmax, i, j, nsym;
        KeySym *syms, sym;
        AV *tbl, *row;
        SV *sv;
    PPCODE:
        XDisplayKeycodes(dpy, &xmin, &xmax);
        if (xmin < minkey) xmin= minkey;
        if (xmax > maxkey) xmax= maxkey;
        syms= XGetKeyboardMapping(dpy, xmin, xmax-xmin+1, &nsym);
        if (!syms)
            croak("XGetKeyboardMapping failed");
        tbl= newAV();
        PUSHs(sv_2mortal(newRV_noinc((SV*) tbl)));
        av_extend(tbl, maxkey);
        for (i= minkey; i < xmin; i++)
            av_push(tbl, newSVsv(&PL_sv_undef));
        for (i= 0; i <= xmax-xmin; i++) {
            row= newAV();
            av_push(tbl, newRV_noinc((SV*) row));
            av_extend(row, nsym-1);
            for (j= 0; j < nsym; j++) {
                if (syms[i*nsym+j]) {
                    sv= PerlXlib_keysym_to_sv(syms[i*nsym+j], symbolic);
                    if (!sv) {
                        XFree(syms);
                        croak("Your keymap includes KeySym 0x%x that can't be un-ambiguously represented by a string", (unsigned) syms[i*nsym+j]);
                    }
                    av_store(row, j, sv);
                }
            }
        }
        XFree(syms);

void
save_keymap(dpy, kmap, minkey=0, maxkey=255)
    Display *dpy
    AV *kmap
    int minkey
    int maxkey
    INIT:
        int xmin, xmax, amin, nsym, i, j, n, m, codepoint, ival;
        size_t len;
        const char *name;
        char *endp;
        KeySym *syms, cursym;
        SV **elem;
        AV *row;
    PPCODE:
        m= av_len(kmap);
        if (minkey < 0 || maxkey > 255 || minkey > maxkey || m < 0)
            croak("require 0 <= min <= max <= 255 and non-zero length array");
        XDisplayKeycodes(dpy, &xmin, &xmax);
        if (xmin < minkey) xmin= minkey;
        if (xmax > maxkey) xmax= maxkey;
        /* If the length of the array is equal to maxkey-minkey, then assume the elements
         * are exactly min..max.  Else if the array is longer, assume the array starts at 0
         * and min..max are indexes into the array
         */
        amin= (m == maxkey - minkey)? minkey : 0;
        if (maxkey - amin > m && maxkey < 255)
            croak("max exceeds array length");
        if (xmax - amin > m)
            xmax= m - amin;
        /* Find the longest array in the bunch */
        nsym= 0;
        for (i= 0; i < xmax-xmin+1; i++) {
            elem= av_fetch(kmap, i + (xmin-amin), 0);
            if (!elem || !*elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVAV)
                croak("Expected arrayref of arrayrefs (defined for the range %d..%d)", xmin-amin, xmax-amin);
            n= av_len((AV*) SvRV(*elem))+1;
            if (nsym < n) nsym= n;
        }
        Newx(syms, nsym * (xmax-xmin+1), KeySym);
        SAVEFREEPV(syms); /* in case we croak before exiting */
        for (i= 0; i < xmax-xmin+1; i++) {
            row= (AV*) SvRV(*av_fetch(kmap, i + (xmin-amin), 0));
            for (j= 0, n= av_len(row)+1; j < nsym; j++) {
                cursym= NoSymbol;
                if (j < n) {
                    elem= av_fetch(row, j, 0);
                    if (elem && *elem && SvOK(*elem)) {
                        cursym= PerlXlib_sv_to_keysym(*elem);
                        if (cursym == NoSymbol)
                            croak("No such KeySym %s (slot %d of keycode %d)", name, j, i+xmin);
                    }
                }
                syms[ i * nsym + j ]= cursym;
            }
        }
        XChangeKeyboardMapping(dpy, xmin, nsym, syms, xmax-xmin+1);

void
XGetModifierMapping(dpy)
    Display *dpy
    INIT:
        XModifierKeymap *modmap;
        AV *tbl, *row;
        int i, j;
    PPCODE:
        modmap= XGetModifierMapping(dpy);
        tbl= newAV();
        av_extend(tbl, 8);
        for (i= 0; i < 8; i++) {
            row= newAV();
            av_extend(row, modmap->max_keypermod);
            for (j= 0; j < modmap->max_keypermod; j++) {
                av_push(row, newSViv(modmap->modifiermap[i * modmap->max_keypermod + j]));
            }
            av_push(tbl, newRV_noinc((SV*) row));
        }
        XFree(modmap);
        PUSHs(sv_2mortal(newRV_noinc((SV*) tbl)));

int
XSetModifierMapping(dpy, tbl)
    Display *dpy
    AV *tbl
    INIT:
        XModifierKeymap modmap;
        KeyCode keycodes[64];
        int i, n, j, code, minkey, maxkey;
        SV **elem;
        AV *row;
    CODE:
        memset(keycodes, 0, sizeof(keycodes));
        modmap.max_keypermod= 0;
        modmap.modifiermap= keycodes;
        XDisplayKeycodes(dpy, &minkey, &maxkey);
        /* Find the longest array.  Also validate. */
        if (av_len(tbl) != 7)
            croak("Expected arrayref of length 8");
        for (i= 0; i < 8; i++) {
            elem= av_fetch(tbl, i, 0);
            if (!elem || !*elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVAV)
                croak("Expected arrayref of arrayrefs");
            row= (AV*) SvRV(*elem);
            n= av_len(row)+1;
            if (n > 8)
                croak("There can be at most 8 keys per modifier");
            if (n > modmap.max_keypermod)
                modmap.max_keypermod= n;
            for (j= 0; j < n; j++) {
                elem= av_fetch(row, j, 0);
                if (elem && *elem && SvOK(*elem)) {
                    code= SvIV(*elem);
                    if (code != 0 && (code < minkey || code > maxkey))
                        croak("Keycode %d outside range of %d..%d", code, minkey, maxkey);
                    keycodes[i*8+j]= code;
                }
            }
        }
        /* If the number of modifiers is less than the max, shrink the table
         * rows to match.
         */
        if (modmap.max_keypermod < 8) {
            n= modmap.max_keypermod;
            if (n == 0)
                croak("Cowardly refusing to set an empty modifiermap");
            for (i= 1; i < 8; i++)
                for (j= 0; j < n; j++)
                    keycodes[i * n + j]= keycodes[i * 8 + j];
        }
        RETVAL= XSetModifierMapping(dpy, &modmap);
    OUTPUT:
        RETVAL

void
XLookupString(event, str_sv, keysym_sv= NULL)
    XEvent *event
    SV *str_sv
    SV *keysym_sv
    INIT:
        size_t len, maxlen;
        KeySym sym;
    PPCODE:
        if (event->type != KeyPress && event->type != KeyRelease)
            croak("Expected event of type KeyPress or KeyRelease");
        if (!event->xany.display)
            croak("event->display must be set");
        if (SvOK(str_sv))
            SvPV_force(str_sv, len);
        else {
            sv_setpvn(str_sv, "", 0);
            len= 0;
        }
        maxlen= len < 16? 16 : len;
        SvGROW(str_sv, maxlen);
        len= XLookupString((XKeyEvent*) event, SvPVX(str_sv), maxlen-1, &sym, NULL);
        /* If full buffer, try one more time with quadruple buffer space */
        if (len == maxlen-1) {
            maxlen <<= 2;
            SvGROW(str_sv, maxlen);
            len= XLookupString((XKeyEvent*) event, SvPVX(str_sv), maxlen-1, &sym, NULL);
        }
        SvPVX(str_sv)[len]= '\0';
        SvCUR_set(str_sv, len);
        if (keysym_sv)
            sv_setiv(keysym_sv, sym);

unsigned int
XKeysymToKeycode(dpy, keysym)
    Display * dpy
    unsigned long keysym
    CODE:
        RETVAL = XKeysymToKeycode(dpy, keysym);
    OUTPUT:
        RETVAL

void
XRefreshKeyboardMapping(event)
    XEvent *event
    PPCODE:
        if (event->type != MappingNotify)
            croak("Expected event of type MappingNotify");
        XRefreshKeyboardMapping((XMappingEvent*) event);

void
_error_names()
    INIT:
        HV* codes;
        char intbuf[sizeof(long)*3+2];
    PPCODE:
        codes= get_hv("X11::Xlib::_error_names", 0);
        if (!codes) {
            codes= get_hv("X11::Xlib::_error_names", GV_ADD);
#define E(name) if (!hv_store(codes, intbuf, snprintf(intbuf, sizeof(intbuf), "%d", name), newSVpv(#name,0), 0)) die("hv_store");
            E(BadAccess)
            E(BadAlloc)
            E(BadAtom)
            E(BadColor)
            E(BadCursor)
            E(BadDrawable)
            E(BadFont)
            E(BadGC)
            E(BadIDChoice)
            E(BadImplementation)
            E(BadLength)
            E(BadMatch)
            E(BadName)
            E(BadPixmap)
            E(BadRequest)
            E(BadValue)
            E(BadWindow)
#undef E
        }
        PUSHs(sv_2mortal((SV*)newRV_inc((SV*)codes)));

void
_install_error_handlers(nonfatal,fatal)
    Bool nonfatal
    Bool fatal
    CODE:
        PerlXlib_install_error_handlers(nonfatal, fatal);

# Xcomposite Extension () ----------------------------------------------------

#ifdef XCOMPOSITE_VERSION

void
XCompositeQueryExtension(dpy)
    Display *dpy
    INIT:
        int event_base, error_base;
    PPCODE:
        if (XCompositeQueryExtension(dpy, &event_base, &error_base)) {
            XPUSHs(sv_2mortal(newSViv(event_base)));
            XPUSHs(sv_2mortal(newSViv(error_base)));
        }

void
XCompositeQueryVersion(dpy)
    Display *dpy
    INIT:
        int major, minor;
    PPCODE:
        if (XCompositeQueryVersion(dpy, &major, &minor)) {
            XPUSHs(sv_2mortal(newSViv(major)));
            XPUSHs(sv_2mortal(newSViv(minor)));
        }

int
XCompositeVersion()

void
XCompositeRedirectWindow(dpy, wnd, update)
    Display *dpy
    Window wnd
    int update

void
XCompositeRedirectSubwindows(dpy, wnd, update)
    Display *dpy
    Window wnd
    int update

void
XCompositeUnredirectWindow(dpy, wnd, update)
    Display *dpy
    Window wnd
    int update

void
XCompositeUnredirectSubwindows(dpy, wnd, update)
    Display *dpy
    Window wnd
    int update

XserverRegion
XCompositeCreateRegionFromBorderClip(dpy, wnd)
    Display *dpy
    Window wnd

Pixmap
XCompositeNameWindowPixmap(dpy, wnd)
    Display *dpy
    Window wnd

Window
XCompositeGetOverlayWindow(dpy, wnd)
    Display *dpy
    Window wnd

void
XCompositeReleaseOverlayWindow(dpy, wnd)
    Display *dpy
    Window wnd

#else /* XCOMPOSITE_VERSION */

#define CompositeRedirectAutomatic 0
#define CompositeRedirectManual 1

#endif /* XCOMPOSITE_VERSION */

# Xfixes Extension () --------------------------------------------------------

#ifdef XFIXES_VERSION

void
XFixesQueryExtension(dpy)
    Display *dpy
    INIT:
        int event_base, error_base;
    PPCODE:
        if (XFixesQueryExtension(dpy, &event_base, &error_base)) {
            XPUSHs(sv_2mortal(newSViv(event_base)));
            XPUSHs(sv_2mortal(newSViv(error_base)));
        }

void
XFixesQueryVersion(dpy)
    Display *dpy
    INIT:
        int major, minor;
    PPCODE:
        if (XFixesQueryVersion(dpy, &major, &minor)) {
            XPUSHs(sv_2mortal(newSViv(major)));
            XPUSHs(sv_2mortal(newSViv(minor)));
        }

int
XFixesVersion()

#if XFIXES_MAJOR >= 2

XserverRegion
XFixesCreateRegion(dpy, rect_av)
    Display *dpy
    AV *rect_av
    INIT:
        XRectangle *rects, *rect;
        int nrects, i;
        SV **elem;
    CODE:
        nrects= av_len(rect_av)+1;
        if (nrects) {
            Newx(rects, nrects, XRectangle);
            SAVEFREEPV(rects);
            for (i= 0; i < nrects; i++) {
                elem= av_fetch(rect_av, i, 0);
                if (!elem) croak("Can't read array elem %d", i);
                rect= (XRectangle*) PerlXlib_get_struct_ptr(
                    *elem, 0,
                    "X11::Xlib::XRectangle", sizeof(XRectangle),
                    (PerlXlib_struct_pack_fn*) PerlXlib_XRectangle_pack
                );
                memcpy(rects+i, rect, sizeof(XRectangle));
            }
        } else {
            rects= NULL;
        }
        RETVAL = XFixesCreateRegion(dpy, rects, nrects);
    OUTPUT:
        RETVAL

void
XFixesDestroyRegion(dpy, region)
    Display *dpy
    XserverRegion region

void
XFixesSetWindowShapeRegion(dpy, wnd, shape_kind, x_off, y_off, region)
    Display *dpy
    Window wnd
    int shape_kind
    int x_off
    int y_off
    XserverRegion region

#endif  /* XFIXES_MAJOR >= 2 */
#endif  /* XFIXES_VERSION */

#ifndef SHAPE_MAJOR_VERSION
#define ShapeSet                        0
#define ShapeUnion                      1
#define ShapeIntersect                  2
#define ShapeSubtract                   3
#define ShapeInvert                     4
#define ShapeBounding                   0
#define ShapeClip                       1
#define ShapeInput                      2
#endif

# Xrender Extension () -------------------------------------------------------

#ifdef HAVE_XRENDER

void
XRenderQueryExtension(dpy)
    Display *dpy
    INIT:
        int event_base, error_base;
    PPCODE:
        if (XRenderQueryExtension(dpy, &event_base, &error_base)) {
            XPUSHs(sv_2mortal(newSViv(event_base)));
            XPUSHs(sv_2mortal(newSViv(error_base)));
        }

void
XRenderQueryVersion(dpy)
    Display *dpy
    INIT:
        int major, minor;
    PPCODE:
        if (XRenderQueryVersion(dpy, &major, &minor)) {
            XPUSHs(sv_2mortal(newSViv(major)));
            XPUSHs(sv_2mortal(newSViv(minor)));
        }

void
XRenderFindVisualFormat(dpy, vis)
    Display *dpy
    Visual *vis
    INIT:
        XRenderPictFormat *fmt;
    PPCODE:
        fmt= XRenderFindVisualFormat(dpy, vis);
        if (fmt) {
            PUSHs(sv_2mortal(
                sv_setref_pvn(newSV(0), "X11::Xlib::XRenderPictFormat", (char*)fmt, sizeof(XRenderPictFormat))
            ));
        }
        /* doesn't need freed? */

#else /* (not) HAVE_XRENDER */

#define PictFormatID        (1 << 0)
#define PictFormatType      (1 << 1)
#define PictFormatDepth     (1 << 2)
#define PictFormatRed       (1 << 3)
#define PictFormatRedMask   (1 << 4)
#define PictFormatGreen     (1 << 5)
#define PictFormatGreenMask (1 << 6)
#define PictFormatBlue      (1 << 7)
#define PictFormatBlueMask  (1 << 8)
#define PictFormatAlpha     (1 << 9)
#define PictFormatAlphaMask (1 << 10)
#define PictFormatColormap  (1 << 11)

#endif /* HAVE_XRENDER */

MODULE = X11::Xlib                PACKAGE = X11::Xlib::Opaque

void
display(self, dpy_sv= NULL)
    SV *self
    SV *dpy_sv
    PPCODE:
        if (dpy_sv)
            PerlXlib_objref_set_display(self, dpy_sv);
        else
            dpy_sv= PerlXlib_objref_get_display(self);
        PUSHs(sv_mortalcopy(dpy_sv));

void
pointer_int(self)
    SV *self
    INIT:
        void *opaque= PerlXlib_objref_get_pointer(self, NULL, PerlXlib_OR_NULL);
    PPCODE:
        PUSHs(sv_2mortal(newSVuv(PTR2UV(opaque))));

void
pointer_bytes(self)
    SV *self
    INIT:
        void *opaque= PerlXlib_objref_get_pointer(self, NULL, PerlXlib_OR_NULL);
    PPCODE:
        PUSHs(sv_2mortal(newSVpvn((void*) &opaque, sizeof(opaque))));

MODULE = X11::Xlib                PACKAGE = X11::Xlib::Visual

int
id(visual)
    Visual *visual
    CODE:
        RETVAL = XVisualIDFromVisual(visual);
    OUTPUT:
        RETVAL

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XEvent

# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XEvent
void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XEvent", sizeof(XEvent),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XEvent_pack
        );
        memset((void*) sptr, 0, sizeof(XEvent));

int
_sizeof(ignored)
    SV *ignored
    CODE:
        RETVAL = sizeof(XEvent);
    OUTPUT:
        RETVAL

void
_pack(e, fields, consume)
    XEvent *e
    HV *fields
    Bool consume
    INIT:
        const char *oldpkg, *newpkg;
    PPCODE:
        oldpkg= PerlXlib_xevent_pkg_for_type(e->type);
        PerlXlib_XEvent_pack(e, fields, consume);
        newpkg= PerlXlib_xevent_pkg_for_type(e->type);
        /* re-bless the object if the thing passed to us was actually an object */
        if (oldpkg != newpkg && sv_derived_from(ST(0), "X11::Xlib::XEvent"))
            sv_bless(ST(0), gv_stashpv(newpkg, GV_ADD));

void
_unpack(e, fields)
    XEvent *e
    HV *fields
    PPCODE:
        PerlXlib_XEvent_unpack(e, fields);

void
_above(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.above = c_value; } else { c_value= event->xconfigure.above; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.above = c_value; } else { c_value= event->xconfigurerequest.above; } break;
    default: croak("Can't access XEvent.above for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_atom(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case PropertyNotify:
      if (value) { event->xproperty.atom = c_value; } else { c_value= event->xproperty.atom; } break;
    default: croak("Can't access XEvent.atom for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_b(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ClientMessage:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(char)*20)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(char)*20), (long) SvCUR(value)); memcpy(event->xclient.data.b, SvPVX(value), sizeof(char)*20);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xclient.data.b, sizeof(char)*20))); } break;
    default: croak("Can't access XEvent.b for type=%d", event->type);
    }

void
_border_width(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.border_width = c_value; } else { c_value= event->xconfigure.border_width; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.border_width = c_value; } else { c_value= event->xconfigurerequest.border_width; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.border_width = c_value; } else { c_value= event->xcreatewindow.border_width; } break;
    default: croak("Can't access XEvent.border_width for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_button(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned int c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.button = c_value; } else { c_value= event->xbutton.button; } break;
    default: croak("Can't access XEvent.button for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_colormap(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Colormap c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ColormapNotify:
      if (value) { event->xcolormap.colormap = c_value; } else { c_value= event->xcolormap.colormap; } break;
    default: croak("Can't access XEvent.colormap for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_cookie(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned int c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    default: croak("Can't access XEvent.cookie for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_count(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case Expose:
      if (value) { event->xexpose.count = c_value; } else { c_value= event->xexpose.count; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.count = c_value; } else { c_value= event->xgraphicsexpose.count; } break;
    case MappingNotify:
      if (value) { event->xmapping.count = c_value; } else { c_value= event->xmapping.count; } break;
    default: croak("Can't access XEvent.count for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_detail(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.detail = c_value; } else { c_value= event->xconfigurerequest.detail; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.detail = c_value; } else { c_value= event->xcrossing.detail; } break;
    case FocusIn:
    case FocusOut:
      if (value) { event->xfocus.detail = c_value; } else { c_value= event->xfocus.detail; } break;
    default: croak("Can't access XEvent.detail for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
display(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    if (value) {
      if (event->type) event->xany.display= PerlXlib_display_objref_get_pointer(value, PerlXlib_OR_NULL); else event->xerror.display= PerlXlib_display_objref_get_pointer(value, PerlXlib_OR_NULL);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVsv(PerlXlib_get_display_objref((event->type? event->xany.display : event->xerror.display), PerlXlib_AUTOCREATE))));
    }

void
_drawable(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Drawable c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.drawable = c_value; } else { c_value= event->xgraphicsexpose.drawable; } break;
    case NoExpose:
      if (value) { event->xnoexpose.drawable = c_value; } else { c_value= event->xnoexpose.drawable; } break;
    default: croak("Can't access XEvent.drawable for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_error_code(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned char c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case 0:
      if (value) { event->xerror.error_code = c_value; } else { c_value= event->xerror.error_code; } break;
    default: croak("Can't access XEvent.error_code for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_event(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case CirculateNotify:
      if (value) { event->xcirculate.event = c_value; } else { c_value= event->xcirculate.event; } break;
    case ConfigureNotify:
      if (value) { event->xconfigure.event = c_value; } else { c_value= event->xconfigure.event; } break;
    case DestroyNotify:
      if (value) { event->xdestroywindow.event = c_value; } else { c_value= event->xdestroywindow.event; } break;
    case GravityNotify:
      if (value) { event->xgravity.event = c_value; } else { c_value= event->xgravity.event; } break;
    case MapNotify:
      if (value) { event->xmap.event = c_value; } else { c_value= event->xmap.event; } break;
    case ReparentNotify:
      if (value) { event->xreparent.event = c_value; } else { c_value= event->xreparent.event; } break;
    case UnmapNotify:
      if (value) { event->xunmap.event = c_value; } else { c_value= event->xunmap.event; } break;
    default: croak("Can't access XEvent.event for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_evtype(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case GenericEvent:
      if (value) { event->xgeneric.evtype = c_value; } else { c_value= event->xgeneric.evtype; } break;
    default: croak("Can't access XEvent.evtype for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_extension(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case GenericEvent:
      if (value) { event->xgeneric.extension = c_value; } else { c_value= event->xgeneric.extension; } break;
    default: croak("Can't access XEvent.extension for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_first_keycode(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case MappingNotify:
      if (value) { event->xmapping.first_keycode = c_value; } else { c_value= event->xmapping.first_keycode; } break;
    default: croak("Can't access XEvent.first_keycode for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_focus(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.focus = c_value; } else { c_value= event->xcrossing.focus; } break;
    default: croak("Can't access XEvent.focus for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_format(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ClientMessage:
      if (value) { event->xclient.format = c_value; } else { c_value= event->xclient.format; } break;
    default: croak("Can't access XEvent.format for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_from_configure(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case UnmapNotify:
      if (value) { event->xunmap.from_configure = c_value; } else { c_value= event->xunmap.from_configure; } break;
    default: croak("Can't access XEvent.from_configure for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_height(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.height = c_value; } else { c_value= event->xconfigure.height; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.height = c_value; } else { c_value= event->xconfigurerequest.height; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.height = c_value; } else { c_value= event->xcreatewindow.height; } break;
    case Expose:
      if (value) { event->xexpose.height = c_value; } else { c_value= event->xexpose.height; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.height = c_value; } else { c_value= event->xgraphicsexpose.height; } break;
    case ResizeRequest:
      if (value) { event->xresizerequest.height = c_value; } else { c_value= event->xresizerequest.height; } break;
    default: croak("Can't access XEvent.height for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_is_hint(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    char c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case MotionNotify:
      if (value) { event->xmotion.is_hint = c_value; } else { c_value= event->xmotion.is_hint; } break;
    default: croak("Can't access XEvent.is_hint for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_key_vector(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case KeymapNotify:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(char)*32)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(char)*32), (long) SvCUR(value)); memcpy(event->xkeymap.key_vector, SvPVX(value), sizeof(char)*32);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xkeymap.key_vector, sizeof(char)*32))); } break;
    default: croak("Can't access XEvent.key_vector for type=%d", event->type);
    }

void
_keycode(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned int c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.keycode = c_value; } else { c_value= event->xkey.keycode; } break;
    default: croak("Can't access XEvent.keycode for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_l(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ClientMessage:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(long)*5)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(long)*5), (long) SvCUR(value)); memcpy(event->xclient.data.l, SvPVX(value), sizeof(long)*5);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xclient.data.l, sizeof(long)*5))); } break;
    default: croak("Can't access XEvent.l for type=%d", event->type);
    }

void
_major_code(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.major_code = c_value; } else { c_value= event->xgraphicsexpose.major_code; } break;
    case NoExpose:
      if (value) { event->xnoexpose.major_code = c_value; } else { c_value= event->xnoexpose.major_code; } break;
    default: croak("Can't access XEvent.major_code for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_message_type(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ClientMessage:
      if (value) { event->xclient.message_type = c_value; } else { c_value= event->xclient.message_type; } break;
    default: croak("Can't access XEvent.message_type for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_minor_code(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case 0:
      if (value) { event->xerror.minor_code= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xerror.minor_code))); } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.minor_code= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xgraphicsexpose.minor_code))); } break;
    case NoExpose:
      if (value) { event->xnoexpose.minor_code= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xnoexpose.minor_code))); } break;
    default: croak("Can't access XEvent.minor_code for type=%d", event->type);
    }

void
_mode(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.mode = c_value; } else { c_value= event->xcrossing.mode; } break;
    case FocusIn:
    case FocusOut:
      if (value) { event->xfocus.mode = c_value; } else { c_value= event->xfocus.mode; } break;
    default: croak("Can't access XEvent.mode for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_new(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ColormapNotify:
      if (value) { event->xcolormap.new = c_value; } else { c_value= event->xcolormap.new; } break;
    default: croak("Can't access XEvent.new for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_override_redirect(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.override_redirect = c_value; } else { c_value= event->xconfigure.override_redirect; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.override_redirect = c_value; } else { c_value= event->xcreatewindow.override_redirect; } break;
    case MapNotify:
      if (value) { event->xmap.override_redirect = c_value; } else { c_value= event->xmap.override_redirect; } break;
    case ReparentNotify:
      if (value) { event->xreparent.override_redirect = c_value; } else { c_value= event->xreparent.override_redirect; } break;
    default: croak("Can't access XEvent.override_redirect for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_owner(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionRequest:
      if (value) { event->xselectionrequest.owner = c_value; } else { c_value= event->xselectionrequest.owner; } break;
    default: croak("Can't access XEvent.owner for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_pad(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    default: croak("Can't access XEvent.pad for type=%d", event->type);
    }

void
_parent(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case CirculateRequest:
      if (value) { event->xcirculaterequest.parent = c_value; } else { c_value= event->xcirculaterequest.parent; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.parent = c_value; } else { c_value= event->xconfigurerequest.parent; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.parent = c_value; } else { c_value= event->xcreatewindow.parent; } break;
    case MapRequest:
      if (value) { event->xmaprequest.parent = c_value; } else { c_value= event->xmaprequest.parent; } break;
    case ReparentNotify:
      if (value) { event->xreparent.parent = c_value; } else { c_value= event->xreparent.parent; } break;
    default: croak("Can't access XEvent.parent for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_place(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case CirculateNotify:
      if (value) { event->xcirculate.place = c_value; } else { c_value= event->xcirculate.place; } break;
    case CirculateRequest:
      if (value) { event->xcirculaterequest.place = c_value; } else { c_value= event->xcirculaterequest.place; } break;
    default: croak("Can't access XEvent.place for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_property(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.property = c_value; } else { c_value= event->xselection.property; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.property = c_value; } else { c_value= event->xselectionrequest.property; } break;
    default: croak("Can't access XEvent.property for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_request(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case MappingNotify:
      if (value) { event->xmapping.request = c_value; } else { c_value= event->xmapping.request; } break;
    default: croak("Can't access XEvent.request for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_request_code(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned char c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case 0:
      if (value) { event->xerror.request_code = c_value; } else { c_value= event->xerror.request_code; } break;
    default: croak("Can't access XEvent.request_code for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_requestor(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.requestor = c_value; } else { c_value= event->xselection.requestor; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.requestor = c_value; } else { c_value= event->xselectionrequest.requestor; } break;
    default: croak("Can't access XEvent.requestor for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_resourceid(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    XID c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case 0:
      if (value) { event->xerror.resourceid = c_value; } else { c_value= event->xerror.resourceid; } break;
    default: croak("Can't access XEvent.resourceid for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_root(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.root = c_value; } else { c_value= event->xbutton.root; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.root = c_value; } else { c_value= event->xcrossing.root; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.root = c_value; } else { c_value= event->xkey.root; } break;
    case MotionNotify:
      if (value) { event->xmotion.root = c_value; } else { c_value= event->xmotion.root; } break;
    default: croak("Can't access XEvent.root for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_s(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ClientMessage:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(short)*10)  croak("Expected scalar of length %ld but got %ld", (long)(sizeof(short)*10), (long) SvCUR(value)); memcpy(event->xclient.data.s, SvPVX(value), sizeof(short)*10);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xclient.data.s, sizeof(short)*10))); } break;
    default: croak("Can't access XEvent.s for type=%d", event->type);
    }

void
_same_screen(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.same_screen = c_value; } else { c_value= event->xbutton.same_screen; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.same_screen = c_value; } else { c_value= event->xcrossing.same_screen; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.same_screen = c_value; } else { c_value= event->xkey.same_screen; } break;
    case MotionNotify:
      if (value) { event->xmotion.same_screen = c_value; } else { c_value= event->xmotion.same_screen; } break;
    default: croak("Can't access XEvent.same_screen for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_selection(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.selection = c_value; } else { c_value= event->xselection.selection; } break;
    case SelectionClear:
      if (value) { event->xselectionclear.selection = c_value; } else { c_value= event->xselectionclear.selection; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.selection = c_value; } else { c_value= event->xselectionrequest.selection; } break;
    default: croak("Can't access XEvent.selection for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
send_event(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    if (!event->type) croak("Can't access XEvent.send_event for type=%d", event->type);
    if (value) {
      event->xany.send_event= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(event->xany.send_event)));
    }

void
serial(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    if (value) {
      if (event->type) event->xany.serial= SvUV(value); else event->xerror.serial= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv((event->type? event->xany.serial : event->xerror.serial))));
    }

void
_state(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xbutton.state))); } break;
    case ColormapNotify:
      if (value) { event->xcolormap.state= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xcolormap.state))); } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xcrossing.state))); } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xkey.state))); } break;
    case MotionNotify:
      if (value) { event->xmotion.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xmotion.state))); } break;
    case PropertyNotify:
      if (value) { event->xproperty.state= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xproperty.state))); } break;
    case VisibilityNotify:
      if (value) { event->xvisibility.state= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xvisibility.state))); } break;
    default: croak("Can't access XEvent.state for type=%d", event->type);
    }

void
_subwindow(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.subwindow = c_value; } else { c_value= event->xbutton.subwindow; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.subwindow = c_value; } else { c_value= event->xcrossing.subwindow; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.subwindow = c_value; } else { c_value= event->xkey.subwindow; } break;
    case MotionNotify:
      if (value) { event->xmotion.subwindow = c_value; } else { c_value= event->xmotion.subwindow; } break;
    default: croak("Can't access XEvent.subwindow for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_target(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.target = c_value; } else { c_value= event->xselection.target; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.target = c_value; } else { c_value= event->xselectionrequest.target; } break;
    default: croak("Can't access XEvent.target for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_time(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Time c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.time = c_value; } else { c_value= event->xbutton.time; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.time = c_value; } else { c_value= event->xcrossing.time; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.time = c_value; } else { c_value= event->xkey.time; } break;
    case MotionNotify:
      if (value) { event->xmotion.time = c_value; } else { c_value= event->xmotion.time; } break;
    case PropertyNotify:
      if (value) { event->xproperty.time = c_value; } else { c_value= event->xproperty.time; } break;
    case SelectionNotify:
      if (value) { event->xselection.time = c_value; } else { c_value= event->xselection.time; } break;
    case SelectionClear:
      if (value) { event->xselectionclear.time = c_value; } else { c_value= event->xselectionclear.time; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.time = c_value; } else { c_value= event->xselectionrequest.time; } break;
    default: croak("Can't access XEvent.time for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
type(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    const char *oldpkg, *newpkg;
  PPCODE:
    if (value) {
      if (event->type != SvIV(value)) {
        oldpkg= PerlXlib_xevent_pkg_for_type(event->type);
        event->type= SvIV(value);
        newpkg= PerlXlib_xevent_pkg_for_type(event->type);
        if (oldpkg != newpkg) {
          /* re-initialize all fields in the area that changed */
          memset( ((char*)(void*)event) + sizeof(XAnyEvent), 0, sizeof(XEvent)-sizeof(XAnyEvent) );
          /* re-bless the object if the thing passed to us was actually an object */
          if (sv_derived_from(ST(0), "X11::Xlib::XEvent"))
            sv_bless(ST(0), gv_stashpv(newpkg, GV_ADD));
        }
      }
    }
    PUSHs(sv_2mortal(newSViv(event->type)));

void
_value_mask(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned long c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.value_mask = c_value; } else { c_value= event->xconfigurerequest.value_mask; } break;
    default: croak("Can't access XEvent.value_mask for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_width(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.width = c_value; } else { c_value= event->xconfigure.width; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.width = c_value; } else { c_value= event->xconfigurerequest.width; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.width = c_value; } else { c_value= event->xcreatewindow.width; } break;
    case Expose:
      if (value) { event->xexpose.width = c_value; } else { c_value= event->xexpose.width; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.width = c_value; } else { c_value= event->xgraphicsexpose.width; } break;
    case ResizeRequest:
      if (value) { event->xresizerequest.width = c_value; } else { c_value= event->xresizerequest.width; } break;
    default: croak("Can't access XEvent.width for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_window(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.window = c_value; } else { c_value= event->xbutton.window; } break;
    case CirculateNotify:
      if (value) { event->xcirculate.window = c_value; } else { c_value= event->xcirculate.window; } break;
    case CirculateRequest:
      if (value) { event->xcirculaterequest.window = c_value; } else { c_value= event->xcirculaterequest.window; } break;
    case ClientMessage:
      if (value) { event->xclient.window = c_value; } else { c_value= event->xclient.window; } break;
    case ColormapNotify:
      if (value) { event->xcolormap.window = c_value; } else { c_value= event->xcolormap.window; } break;
    case ConfigureNotify:
      if (value) { event->xconfigure.window = c_value; } else { c_value= event->xconfigure.window; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.window = c_value; } else { c_value= event->xconfigurerequest.window; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.window = c_value; } else { c_value= event->xcreatewindow.window; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.window = c_value; } else { c_value= event->xcrossing.window; } break;
    case DestroyNotify:
      if (value) { event->xdestroywindow.window = c_value; } else { c_value= event->xdestroywindow.window; } break;
    case Expose:
      if (value) { event->xexpose.window = c_value; } else { c_value= event->xexpose.window; } break;
    case FocusIn:
    case FocusOut:
      if (value) { event->xfocus.window = c_value; } else { c_value= event->xfocus.window; } break;
    case GravityNotify:
      if (value) { event->xgravity.window = c_value; } else { c_value= event->xgravity.window; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.window = c_value; } else { c_value= event->xkey.window; } break;
    case KeymapNotify:
      if (value) { event->xkeymap.window = c_value; } else { c_value= event->xkeymap.window; } break;
    case MapNotify:
      if (value) { event->xmap.window = c_value; } else { c_value= event->xmap.window; } break;
    case MappingNotify:
      if (value) { event->xmapping.window = c_value; } else { c_value= event->xmapping.window; } break;
    case MapRequest:
      if (value) { event->xmaprequest.window = c_value; } else { c_value= event->xmaprequest.window; } break;
    case MotionNotify:
      if (value) { event->xmotion.window = c_value; } else { c_value= event->xmotion.window; } break;
    case PropertyNotify:
      if (value) { event->xproperty.window = c_value; } else { c_value= event->xproperty.window; } break;
    case ReparentNotify:
      if (value) { event->xreparent.window = c_value; } else { c_value= event->xreparent.window; } break;
    case ResizeRequest:
      if (value) { event->xresizerequest.window = c_value; } else { c_value= event->xresizerequest.window; } break;
    case SelectionClear:
      if (value) { event->xselectionclear.window = c_value; } else { c_value= event->xselectionclear.window; } break;
    case UnmapNotify:
      if (value) { event->xunmap.window = c_value; } else { c_value= event->xunmap.window; } break;
    case VisibilityNotify:
      if (value) { event->xvisibility.window = c_value; } else { c_value= event->xvisibility.window; } break;
    default: croak("Can't access XEvent.window for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_x(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.x = c_value; } else { c_value= event->xbutton.x; } break;
    case ConfigureNotify:
      if (value) { event->xconfigure.x = c_value; } else { c_value= event->xconfigure.x; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.x = c_value; } else { c_value= event->xconfigurerequest.x; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.x = c_value; } else { c_value= event->xcreatewindow.x; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.x = c_value; } else { c_value= event->xcrossing.x; } break;
    case Expose:
      if (value) { event->xexpose.x = c_value; } else { c_value= event->xexpose.x; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.x = c_value; } else { c_value= event->xgraphicsexpose.x; } break;
    case GravityNotify:
      if (value) { event->xgravity.x = c_value; } else { c_value= event->xgravity.x; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.x = c_value; } else { c_value= event->xkey.x; } break;
    case MotionNotify:
      if (value) { event->xmotion.x = c_value; } else { c_value= event->xmotion.x; } break;
    case ReparentNotify:
      if (value) { event->xreparent.x = c_value; } else { c_value= event->xreparent.x; } break;
    default: croak("Can't access XEvent.x for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_x_root(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.x_root = c_value; } else { c_value= event->xbutton.x_root; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.x_root = c_value; } else { c_value= event->xcrossing.x_root; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.x_root = c_value; } else { c_value= event->xkey.x_root; } break;
    case MotionNotify:
      if (value) { event->xmotion.x_root = c_value; } else { c_value= event->xmotion.x_root; } break;
    default: croak("Can't access XEvent.x_root for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_y(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.y = c_value; } else { c_value= event->xbutton.y; } break;
    case ConfigureNotify:
      if (value) { event->xconfigure.y = c_value; } else { c_value= event->xconfigure.y; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.y = c_value; } else { c_value= event->xconfigurerequest.y; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.y = c_value; } else { c_value= event->xcreatewindow.y; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.y = c_value; } else { c_value= event->xcrossing.y; } break;
    case Expose:
      if (value) { event->xexpose.y = c_value; } else { c_value= event->xexpose.y; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.y = c_value; } else { c_value= event->xgraphicsexpose.y; } break;
    case GravityNotify:
      if (value) { event->xgravity.y = c_value; } else { c_value= event->xgravity.y; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.y = c_value; } else { c_value= event->xkey.y; } break;
    case MotionNotify:
      if (value) { event->xmotion.y = c_value; } else { c_value= event->xmotion.y; } break;
    case ReparentNotify:
      if (value) { event->xreparent.y = c_value; } else { c_value= event->xreparent.y; } break;
    default: croak("Can't access XEvent.y for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_y_root(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.y_root = c_value; } else { c_value= event->xbutton.y_root; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.y_root = c_value; } else { c_value= event->xcrossing.y_root; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.y_root = c_value; } else { c_value= event->xkey.y_root; } break;
    case MotionNotify:
      if (value) { event->xmotion.y_root = c_value; } else { c_value= event->xmotion.y_root; } break;
    default: croak("Can't access XEvent.y_root for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

# END GENERATED X11_Xlib_XEvent
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XVisualInfo

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XVisualInfo

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XVisualInfo);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XVisualInfo", sizeof(XVisualInfo),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XVisualInfo_pack
        );
        memset((void*) sptr, 0, sizeof(XVisualInfo));

void
_pack(s, fields, consume=0)
    XVisualInfo *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XVisualInfo_pack(s, fields, consume);

void
_unpack(s, fields)
    XVisualInfo *s
    HV *fields
    PPCODE:
        PerlXlib_XVisualInfo_unpack_obj(s, fields, ST(0));

void
bits_per_rgb(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->bits_per_rgb= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->bits_per_rgb)));
    }

void
blue_mask(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->blue_mask= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->blue_mask)));
    }

void
class(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->class= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->class)));
    }

void
colormap_size(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->colormap_size= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->colormap_size)));
    }

void
depth(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->depth= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->depth)));
    }

void
green_mask(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->green_mask= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->green_mask)));
    }

void
red_mask(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->red_mask= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->red_mask)));
    }

void
screen(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->screen= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->screen)));
    }

void
visual(self, value=NULL)
    SV *self
    SV *value
  INIT:
    XVisualInfo *s= ( XVisualInfo * ) PerlXlib_get_struct_ptr(
           self, 0, "X11::Xlib::XVisualInfo", sizeof(XVisualInfo),
           (PerlXlib_struct_pack_fn*) &PerlXlib_XVisualInfo_pack
         );
         SV *dpy_sv= PerlXlib_objref_get_display(self);
         Display *dpy= PerlXlib_display_objref_get_pointer(dpy_sv, PerlXlib_OR_NULL);
  PPCODE:
    if (value) {
      s->visual= (Visual *) PerlXlib_objref_get_pointer(value, "Visual", PerlXlib_OR_NULL);
      PUSHs(value);
    } else {
      PUSHs(sv_mortalcopy(PerlXlib_get_objref(s->visual, PerlXlib_AUTOCREATE, "Visual", SVt_PVMG, "X11::Xlib::Visual", dpy)));
    }

void
visualid(self, value=NULL)
    XVisualInfo *self
    SV *value
  INIT:
    XVisualInfo *s= self;
  PPCODE:
    if (value) {
      s->visualid= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->visualid)));
    }

# END GENERATED X11_Xlib_XVisualInfo
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XWindowChanges

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XWindowChanges

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XWindowChanges);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XWindowChanges", sizeof(XWindowChanges),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XWindowChanges_pack
        );
        memset((void*) sptr, 0, sizeof(XWindowChanges));

void
_pack(s, fields, consume=0)
    XWindowChanges *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XWindowChanges_pack(s, fields, consume);

void
_unpack(s, fields)
    XWindowChanges *s
    HV *fields
    PPCODE:
        PerlXlib_XWindowChanges_unpack_obj(s, fields, ST(0));

void
border_width(self, value=NULL)
    XWindowChanges *self
    SV *value
  INIT:
    XWindowChanges *s= self;
  PPCODE:
    if (value) {
      s->border_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->border_width)));
    }

void
height(self, value=NULL)
    XWindowChanges *self
    SV *value
  INIT:
    XWindowChanges *s= self;
  PPCODE:
    if (value) {
      s->height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->height)));
    }

void
sibling(self, value=NULL)
    XWindowChanges *self
    SV *value
  INIT:
    XWindowChanges *s= self;
  PPCODE:
    if (value) {
      s->sibling= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->sibling)));
    }

void
stack_mode(self, value=NULL)
    XWindowChanges *self
    SV *value
  INIT:
    XWindowChanges *s= self;
  PPCODE:
    if (value) {
      s->stack_mode= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->stack_mode)));
    }

void
width(self, value=NULL)
    XWindowChanges *self
    SV *value
  INIT:
    XWindowChanges *s= self;
  PPCODE:
    if (value) {
      s->width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->width)));
    }

void
x(self, value=NULL)
    XWindowChanges *self
    SV *value
  INIT:
    XWindowChanges *s= self;
  PPCODE:
    if (value) {
      s->x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->x)));
    }

void
y(self, value=NULL)
    XWindowChanges *self
    SV *value
  INIT:
    XWindowChanges *s= self;
  PPCODE:
    if (value) {
      s->y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->y)));
    }

# END GENERATED X11_Xlib_XWindowChanges
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XWindowAttributes

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XWindowAttributes

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XWindowAttributes);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XWindowAttributes", sizeof(XWindowAttributes),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XWindowAttributes_pack
        );
        memset((void*) sptr, 0, sizeof(XWindowAttributes));

void
_pack(s, fields, consume=0)
    XWindowAttributes *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XWindowAttributes_pack(s, fields, consume);

void
_unpack(s, fields)
    XWindowAttributes *s
    HV *fields
    PPCODE:
        PerlXlib_XWindowAttributes_unpack_obj(s, fields, ST(0));

void
all_event_masks(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->all_event_masks= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->all_event_masks)));
    }

void
backing_pixel(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->backing_pixel= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->backing_pixel)));
    }

void
backing_planes(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->backing_planes= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->backing_planes)));
    }

void
backing_store(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->backing_store= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->backing_store)));
    }

void
bit_gravity(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->bit_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->bit_gravity)));
    }

void
border_width(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->border_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->border_width)));
    }

void
class(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->class= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->class)));
    }

void
colormap(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->colormap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->colormap)));
    }

void
depth(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->depth= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->depth)));
    }

void
do_not_propagate_mask(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->do_not_propagate_mask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->do_not_propagate_mask)));
    }

void
height(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->height)));
    }

void
map_installed(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->map_installed= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->map_installed)));
    }

void
map_state(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->map_state= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->map_state)));
    }

void
override_redirect(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->override_redirect= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->override_redirect)));
    }

void
root(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->root= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->root)));
    }

void
save_under(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->save_under= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->save_under)));
    }

void
screen(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->screen= PerlXlib_screen_objref_get_pointer(value, PerlXlib_OR_NULL);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVsv(PerlXlib_get_screen_objref(s->screen, PerlXlib_OR_UNDEF))));
    }

void
visual(self, value=NULL)
    SV *self
    SV *value
  INIT:
    XWindowAttributes *s= ( XWindowAttributes * ) PerlXlib_get_struct_ptr(
           self, 0, "X11::Xlib::XWindowAttributes", sizeof(XWindowAttributes),
           (PerlXlib_struct_pack_fn*) &PerlXlib_XWindowAttributes_pack
         );
         SV *dpy_sv= PerlXlib_objref_get_display(self);
         Display *dpy= PerlXlib_display_objref_get_pointer(dpy_sv, PerlXlib_OR_NULL);
  PPCODE:
    if (value) {
      s->visual= (Visual *) PerlXlib_objref_get_pointer(value, "Visual", PerlXlib_OR_NULL);
      PUSHs(value);
    } else {
      PUSHs(sv_mortalcopy(PerlXlib_get_objref(s->visual, PerlXlib_AUTOCREATE, "Visual", SVt_PVMG, "X11::Xlib::Visual", dpy)));
    }

void
width(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->width)));
    }

void
win_gravity(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->win_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->win_gravity)));
    }

void
x(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->x)));
    }

void
y(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->y)));
    }

void
your_event_mask(self, value=NULL)
    XWindowAttributes *self
    SV *value
  INIT:
    XWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->your_event_mask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->your_event_mask)));
    }

# END GENERATED X11_Xlib_XWindowAttributes
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XSetWindowAttributes

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XSetWindowAttributes

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XSetWindowAttributes);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XSetWindowAttributes", sizeof(XSetWindowAttributes),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XSetWindowAttributes_pack
        );
        memset((void*) sptr, 0, sizeof(XSetWindowAttributes));

void
_pack(s, fields, consume=0)
    XSetWindowAttributes *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XSetWindowAttributes_pack(s, fields, consume);

void
_unpack(s, fields)
    XSetWindowAttributes *s
    HV *fields
    PPCODE:
        PerlXlib_XSetWindowAttributes_unpack_obj(s, fields, ST(0));

void
background_pixel(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->background_pixel= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->background_pixel)));
    }

void
background_pixmap(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->background_pixmap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->background_pixmap)));
    }

void
backing_pixel(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->backing_pixel= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->backing_pixel)));
    }

void
backing_planes(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->backing_planes= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->backing_planes)));
    }

void
backing_store(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->backing_store= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->backing_store)));
    }

void
bit_gravity(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->bit_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->bit_gravity)));
    }

void
border_pixel(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->border_pixel= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->border_pixel)));
    }

void
border_pixmap(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->border_pixmap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->border_pixmap)));
    }

void
colormap(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->colormap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->colormap)));
    }

void
cursor(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->cursor= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->cursor)));
    }

void
do_not_propagate_mask(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->do_not_propagate_mask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->do_not_propagate_mask)));
    }

void
event_mask(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->event_mask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->event_mask)));
    }

void
override_redirect(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->override_redirect= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->override_redirect)));
    }

void
save_under(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->save_under= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->save_under)));
    }

void
win_gravity(self, value=NULL)
    XSetWindowAttributes *self
    SV *value
  INIT:
    XSetWindowAttributes *s= self;
  PPCODE:
    if (value) {
      s->win_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->win_gravity)));
    }

# END GENERATED X11_Xlib_XSetWindowAttributes
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XSizeHints

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XSizeHints

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XSizeHints);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XSizeHints", sizeof(XSizeHints),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XSizeHints_pack
        );
        memset((void*) sptr, 0, sizeof(XSizeHints));

void
_pack(s, fields, consume=0)
    XSizeHints *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XSizeHints_pack(s, fields, consume);

void
_unpack(s, fields)
    XSizeHints *s
    HV *fields
    PPCODE:
        PerlXlib_XSizeHints_unpack_obj(s, fields, ST(0));

void
base_height(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->base_height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->base_height)));
    }

void
base_width(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->base_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->base_width)));
    }

void
flags(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->flags= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->flags)));
    }

void
height(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->height)));
    }

void
height_inc(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->height_inc= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->height_inc)));
    }

void
max_aspect_x(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->max_aspect.x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_aspect.x)));
    }

void
max_aspect_y(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->max_aspect.y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_aspect.y)));
    }

void
max_height(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->max_height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_height)));
    }

void
max_width(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->max_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_width)));
    }

void
min_aspect_x(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->min_aspect.x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_aspect.x)));
    }

void
min_aspect_y(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->min_aspect.y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_aspect.y)));
    }

void
min_height(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->min_height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_height)));
    }

void
min_width(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->min_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_width)));
    }

void
width(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->width)));
    }

void
width_inc(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->width_inc= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->width_inc)));
    }

void
win_gravity(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->win_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->win_gravity)));
    }

void
x(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->x)));
    }

void
y(self, value=NULL)
    XSizeHints *self
    SV *value
  INIT:
    XSizeHints *s= self;
  PPCODE:
    if (value) {
      s->y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->y)));
    }

# END GENERATED X11_Xlib_XSizeHints
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XRectangle

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XRectangle

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XRectangle);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XRectangle", sizeof(XRectangle),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XRectangle_pack
        );
        memset((void*) sptr, 0, sizeof(XRectangle));

void
_pack(s, fields, consume=0)
    XRectangle *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XRectangle_pack(s, fields, consume);

void
_unpack(s, fields)
    XRectangle *s
    HV *fields
    PPCODE:
        PerlXlib_XRectangle_unpack_obj(s, fields, ST(0));

void
height(self, value=NULL)
    XRectangle *self
    SV *value
  INIT:
    XRectangle *s= self;
  PPCODE:
    if (value) {
      s->height= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->height)));
    }

void
width(self, value=NULL)
    XRectangle *self
    SV *value
  INIT:
    XRectangle *s= self;
  PPCODE:
    if (value) {
      s->width= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->width)));
    }

void
x(self, value=NULL)
    XRectangle *self
    SV *value
  INIT:
    XRectangle *s= self;
  PPCODE:
    if (value) {
      s->x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->x)));
    }

void
y(self, value=NULL)
    XRectangle *self
    SV *value
  INIT:
    XRectangle *s= self;
  PPCODE:
    if (value) {
      s->y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->y)));
    }

# END GENERATED X11_Xlib_XRectangle
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XRenderPictFormat

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XRenderPictFormat

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XRenderPictFormat);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XRenderPictFormat", sizeof(XRenderPictFormat),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XRenderPictFormat_pack
        );
        memset((void*) sptr, 0, sizeof(XRenderPictFormat));

void
_pack(s, fields, consume=0)
    XRenderPictFormat *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XRenderPictFormat_pack(s, fields, consume);

void
_unpack(s, fields)
    XRenderPictFormat *s
    HV *fields
    PPCODE:
        PerlXlib_XRenderPictFormat_unpack_obj(s, fields, ST(0));

void
colormap(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->colormap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->colormap)));
    }

void
depth(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->depth= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->depth)));
    }

void
direct_alpha(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.alpha= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.alpha)));
    }

void
direct_alphaMask(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.alphaMask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.alphaMask)));
    }

void
direct_blue(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.blue= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.blue)));
    }

void
direct_blueMask(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.blueMask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.blueMask)));
    }

void
direct_green(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.green= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.green)));
    }

void
direct_greenMask(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.greenMask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.greenMask)));
    }

void
direct_red(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.red= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.red)));
    }

void
direct_redMask(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->direct.redMask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->direct.redMask)));
    }

void
id(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->id= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->id)));
    }

void
type(self, value=NULL)
    XRenderPictFormat *self
    SV *value
  INIT:
    XRenderPictFormat *s= self;
  PPCODE:
    if (value) {
      s->type= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->type)));
    }

# END GENERATED X11_Xlib_XRenderPictFormat
# ----------------------------------------------------------------------------

BOOT:
# BEGIN GENERATED BOOT CONSTANTS
  HV* stash= gv_stashpvn("X11::Xlib", 9, 1);
  newCONSTSUB(stash, "None", newSViv(None));
  newCONSTSUB(stash, "ButtonPress", newSViv(ButtonPress));
  newCONSTSUB(stash, "ButtonRelease", newSViv(ButtonRelease));
  newCONSTSUB(stash, "CirculateNotify", newSViv(CirculateNotify));
  newCONSTSUB(stash, "ClientMessage", newSViv(ClientMessage));
  newCONSTSUB(stash, "ColormapNotify", newSViv(ColormapNotify));
  newCONSTSUB(stash, "ConfigureNotify", newSViv(ConfigureNotify));
  newCONSTSUB(stash, "CreateNotify", newSViv(CreateNotify));
  newCONSTSUB(stash, "DestroyNotify", newSViv(DestroyNotify));
  newCONSTSUB(stash, "EnterNotify", newSViv(EnterNotify));
  newCONSTSUB(stash, "Expose", newSViv(Expose));
  newCONSTSUB(stash, "FocusIn", newSViv(FocusIn));
  newCONSTSUB(stash, "FocusOut", newSViv(FocusOut));
  newCONSTSUB(stash, "GraphicsExpose", newSViv(GraphicsExpose));
  newCONSTSUB(stash, "GravityNotify", newSViv(GravityNotify));
  newCONSTSUB(stash, "KeyPress", newSViv(KeyPress));
  newCONSTSUB(stash, "KeyRelease", newSViv(KeyRelease));
  newCONSTSUB(stash, "KeymapNotify", newSViv(KeymapNotify));
  newCONSTSUB(stash, "LeaveNotify", newSViv(LeaveNotify));
  newCONSTSUB(stash, "MapNotify", newSViv(MapNotify));
  newCONSTSUB(stash, "MappingNotify", newSViv(MappingNotify));
  newCONSTSUB(stash, "MapRequest", newSViv(MapRequest));
  newCONSTSUB(stash, "MotionNotify", newSViv(MotionNotify));
  newCONSTSUB(stash, "NoExpose", newSViv(NoExpose));
  newCONSTSUB(stash, "PropertyNotify", newSViv(PropertyNotify));
  newCONSTSUB(stash, "ReparentNotify", newSViv(ReparentNotify));
  newCONSTSUB(stash, "ResizeRequest", newSViv(ResizeRequest));
  newCONSTSUB(stash, "SelectionClear", newSViv(SelectionClear));
  newCONSTSUB(stash, "SelectionNotify", newSViv(SelectionNotify));
  newCONSTSUB(stash, "SelectionRequest", newSViv(SelectionRequest));
  newCONSTSUB(stash, "UnmapNotify", newSViv(UnmapNotify));
  newCONSTSUB(stash, "VisibilityNotify", newSViv(VisibilityNotify));
  newCONSTSUB(stash, "NoEventMask", newSViv(NoEventMask));
  newCONSTSUB(stash, "KeyPressMask", newSViv(KeyPressMask));
  newCONSTSUB(stash, "KeyReleaseMask", newSViv(KeyReleaseMask));
  newCONSTSUB(stash, "ButtonPressMask", newSViv(ButtonPressMask));
  newCONSTSUB(stash, "ButtonReleaseMask", newSViv(ButtonReleaseMask));
  newCONSTSUB(stash, "EnterWindowMask", newSViv(EnterWindowMask));
  newCONSTSUB(stash, "LeaveWindowMask", newSViv(LeaveWindowMask));
  newCONSTSUB(stash, "PointerMotionMask", newSViv(PointerMotionMask));
  newCONSTSUB(stash, "PointerMotionHintMask", newSViv(PointerMotionHintMask));
  newCONSTSUB(stash, "Button1MotionMask", newSViv(Button1MotionMask));
  newCONSTSUB(stash, "Button2MotionMask", newSViv(Button2MotionMask));
  newCONSTSUB(stash, "Button3MotionMask", newSViv(Button3MotionMask));
  newCONSTSUB(stash, "Button4MotionMask", newSViv(Button4MotionMask));
  newCONSTSUB(stash, "Button5MotionMask", newSViv(Button5MotionMask));
  newCONSTSUB(stash, "ButtonMotionMask", newSViv(ButtonMotionMask));
  newCONSTSUB(stash, "KeymapStateMask", newSViv(KeymapStateMask));
  newCONSTSUB(stash, "ExposureMask", newSViv(ExposureMask));
  newCONSTSUB(stash, "VisibilityChangeMask", newSViv(VisibilityChangeMask));
  newCONSTSUB(stash, "StructureNotifyMask", newSViv(StructureNotifyMask));
  newCONSTSUB(stash, "ResizeRedirectMask", newSViv(ResizeRedirectMask));
  newCONSTSUB(stash, "SubstructureNotifyMask", newSViv(SubstructureNotifyMask));
  newCONSTSUB(stash, "SubstructureRedirectMask", newSViv(SubstructureRedirectMask));
  newCONSTSUB(stash, "FocusChangeMask", newSViv(FocusChangeMask));
  newCONSTSUB(stash, "PropertyChangeMask", newSViv(PropertyChangeMask));
  newCONSTSUB(stash, "ColormapChangeMask", newSViv(ColormapChangeMask));
  newCONSTSUB(stash, "OwnerGrabButtonMask", newSViv(OwnerGrabButtonMask));
  newCONSTSUB(stash, "AnyModifier", newSViv(AnyModifier));
  newCONSTSUB(stash, "AnyKey", newSViv(AnyKey));
  newCONSTSUB(stash, "NoSymbol", newSViv(NoSymbol));
  newCONSTSUB(stash, "XK_VoidSymbol", newSViv(XK_VoidSymbol));
  newCONSTSUB(stash, "ShiftMask", newSViv(ShiftMask));
  newCONSTSUB(stash, "LockMask", newSViv(LockMask));
  newCONSTSUB(stash, "ControlMask", newSViv(ControlMask));
  newCONSTSUB(stash, "Mod1Mask", newSViv(Mod1Mask));
  newCONSTSUB(stash, "Mod2Mask", newSViv(Mod2Mask));
  newCONSTSUB(stash, "Mod3Mask", newSViv(Mod3Mask));
  newCONSTSUB(stash, "Mod4Mask", newSViv(Mod4Mask));
  newCONSTSUB(stash, "Mod5Mask", newSViv(Mod5Mask));
  newCONSTSUB(stash, "Button1Mask", newSViv(Button1Mask));
  newCONSTSUB(stash, "Button2Mask", newSViv(Button2Mask));
  newCONSTSUB(stash, "Button3Mask", newSViv(Button3Mask));
  newCONSTSUB(stash, "Button4Mask", newSViv(Button4Mask));
  newCONSTSUB(stash, "Button5Mask", newSViv(Button5Mask));
  newCONSTSUB(stash, "GrabModeSync", newSViv(GrabModeSync));
  newCONSTSUB(stash, "GrabModeAsync", newSViv(GrabModeAsync));
  newCONSTSUB(stash, "AsyncPointer", newSViv(AsyncPointer));
  newCONSTSUB(stash, "SyncPointer", newSViv(SyncPointer));
  newCONSTSUB(stash, "ReplayPointer", newSViv(ReplayPointer));
  newCONSTSUB(stash, "AsyncKeyboard", newSViv(AsyncKeyboard));
  newCONSTSUB(stash, "SyncKeyboard", newSViv(SyncKeyboard));
  newCONSTSUB(stash, "ReplayKeyboard", newSViv(ReplayKeyboard));
  newCONSTSUB(stash, "SyncBoth", newSViv(SyncBoth));
  newCONSTSUB(stash, "AsyncBoth", newSViv(AsyncBoth));
  newCONSTSUB(stash, "PointerRoot", newSViv(PointerRoot));
  newCONSTSUB(stash, "RevertToParent", newSViv(RevertToParent));
  newCONSTSUB(stash, "RevertToPointerRoot", newSViv(RevertToPointerRoot));
  newCONSTSUB(stash, "RevertToNone", newSViv(RevertToNone));
  newCONSTSUB(stash, "Success", newSViv(Success));
  newCONSTSUB(stash, "BadAccess", newSViv(BadAccess));
  newCONSTSUB(stash, "BadAlloc", newSViv(BadAlloc));
  newCONSTSUB(stash, "BadAtom", newSViv(BadAtom));
  newCONSTSUB(stash, "BadColor", newSViv(BadColor));
  newCONSTSUB(stash, "BadCursor", newSViv(BadCursor));
  newCONSTSUB(stash, "BadDrawable", newSViv(BadDrawable));
  newCONSTSUB(stash, "BadFont", newSViv(BadFont));
  newCONSTSUB(stash, "BadGC", newSViv(BadGC));
  newCONSTSUB(stash, "BadIDChoice", newSViv(BadIDChoice));
  newCONSTSUB(stash, "BadImplementation", newSViv(BadImplementation));
  newCONSTSUB(stash, "BadLength", newSViv(BadLength));
  newCONSTSUB(stash, "BadMatch", newSViv(BadMatch));
  newCONSTSUB(stash, "BadName", newSViv(BadName));
  newCONSTSUB(stash, "BadPixmap", newSViv(BadPixmap));
  newCONSTSUB(stash, "BadRequest", newSViv(BadRequest));
  newCONSTSUB(stash, "BadValue", newSViv(BadValue));
  newCONSTSUB(stash, "BadWindow", newSViv(BadWindow));
  newCONSTSUB(stash, "VisualIDMask", newSViv(VisualIDMask));
  newCONSTSUB(stash, "VisualScreenMask", newSViv(VisualScreenMask));
  newCONSTSUB(stash, "VisualDepthMask", newSViv(VisualDepthMask));
  newCONSTSUB(stash, "VisualClassMask", newSViv(VisualClassMask));
  newCONSTSUB(stash, "VisualRedMaskMask", newSViv(VisualRedMaskMask));
  newCONSTSUB(stash, "VisualGreenMaskMask", newSViv(VisualGreenMaskMask));
  newCONSTSUB(stash, "VisualBlueMaskMask", newSViv(VisualBlueMaskMask));
  newCONSTSUB(stash, "VisualColormapSizeMask", newSViv(VisualColormapSizeMask));
  newCONSTSUB(stash, "VisualBitsPerRGBMask", newSViv(VisualBitsPerRGBMask));
  newCONSTSUB(stash, "VisualAllMask", newSViv(VisualAllMask));
  newCONSTSUB(stash, "AllocAll", newSViv(AllocAll));
  newCONSTSUB(stash, "AllocNone", newSViv(AllocNone));
  newCONSTSUB(stash, "AnyPropertyType", newSViv(AnyPropertyType));
  newCONSTSUB(stash, "PropModeReplace", newSViv(PropModeReplace));
  newCONSTSUB(stash, "PropModeAppend", newSViv(PropModeAppend));
  newCONSTSUB(stash, "PropModePrepend", newSViv(PropModePrepend));
  newCONSTSUB(stash, "Above", newSViv(Above));
  newCONSTSUB(stash, "Below", newSViv(Below));
  newCONSTSUB(stash, "BottomIf", newSViv(BottomIf));
  newCONSTSUB(stash, "CopyFromParent", newSViv(CopyFromParent));
  newCONSTSUB(stash, "InputOutput", newSViv(InputOutput));
  newCONSTSUB(stash, "InputOnly", newSViv(InputOnly));
  newCONSTSUB(stash, "Opposite", newSViv(Opposite));
  newCONSTSUB(stash, "TopIf", newSViv(TopIf));
  newCONSTSUB(stash, "LowerHighest", newSViv(LowerHighest));
  newCONSTSUB(stash, "RaiseLowest", newSViv(RaiseLowest));
  newCONSTSUB(stash, "ForgetGravity", newSViv(ForgetGravity));
  newCONSTSUB(stash, "UnmapGravity", newSViv(UnmapGravity));
  newCONSTSUB(stash, "EastGravity", newSViv(EastGravity));
  newCONSTSUB(stash, "NorthWestGravity", newSViv(NorthWestGravity));
  newCONSTSUB(stash, "SouthWestGravity", newSViv(SouthWestGravity));
  newCONSTSUB(stash, "NorthGravity", newSViv(NorthGravity));
  newCONSTSUB(stash, "SouthGravity", newSViv(SouthGravity));
  newCONSTSUB(stash, "NorthEastGravity", newSViv(NorthEastGravity));
  newCONSTSUB(stash, "SouthEastGravity", newSViv(SouthEastGravity));
  newCONSTSUB(stash, "WestGravity", newSViv(WestGravity));
  newCONSTSUB(stash, "StaticGravity", newSViv(StaticGravity));
  newCONSTSUB(stash, "CenterGravity", newSViv(CenterGravity));
  newCONSTSUB(stash, "CWBackPixmap", newSViv(CWBackPixmap));
  newCONSTSUB(stash, "CWBackPixel", newSViv(CWBackPixel));
  newCONSTSUB(stash, "CWBackingStore", newSViv(CWBackingStore));
  newCONSTSUB(stash, "CWBackingPlanes", newSViv(CWBackingPlanes));
  newCONSTSUB(stash, "CWBackingPixel", newSViv(CWBackingPixel));
  newCONSTSUB(stash, "CWBorderWidth", newSViv(CWBorderWidth));
  newCONSTSUB(stash, "CWBorderPixmap", newSViv(CWBorderPixmap));
  newCONSTSUB(stash, "CWBorderPixel", newSViv(CWBorderPixel));
  newCONSTSUB(stash, "CWBitGravity", newSViv(CWBitGravity));
  newCONSTSUB(stash, "CWColormap", newSViv(CWColormap));
  newCONSTSUB(stash, "CWCursor", newSViv(CWCursor));
  newCONSTSUB(stash, "CWDontPropagate", newSViv(CWDontPropagate));
  newCONSTSUB(stash, "CWEventMask", newSViv(CWEventMask));
  newCONSTSUB(stash, "CWHeight", newSViv(CWHeight));
  newCONSTSUB(stash, "CWOverrideRedirect", newSViv(CWOverrideRedirect));
  newCONSTSUB(stash, "CWSaveUnder", newSViv(CWSaveUnder));
  newCONSTSUB(stash, "CWSibling", newSViv(CWSibling));
  newCONSTSUB(stash, "CWStackMode", newSViv(CWStackMode));
  newCONSTSUB(stash, "CWWidth", newSViv(CWWidth));
  newCONSTSUB(stash, "CWWinGravity", newSViv(CWWinGravity));
  newCONSTSUB(stash, "CWX", newSViv(CWX));
  newCONSTSUB(stash, "CWY", newSViv(CWY));
  newCONSTSUB(stash, "USPosition", newSViv(USPosition));
  newCONSTSUB(stash, "USSize", newSViv(USSize));
  newCONSTSUB(stash, "PPosition", newSViv(PPosition));
  newCONSTSUB(stash, "PSize", newSViv(PSize));
  newCONSTSUB(stash, "PMinSize", newSViv(PMinSize));
  newCONSTSUB(stash, "PMaxSize", newSViv(PMaxSize));
  newCONSTSUB(stash, "PResizeInc", newSViv(PResizeInc));
  newCONSTSUB(stash, "PAspect", newSViv(PAspect));
  newCONSTSUB(stash, "PBaseSize", newSViv(PBaseSize));
  newCONSTSUB(stash, "PWinGravity", newSViv(PWinGravity));
  newCONSTSUB(stash, "CompositeRedirectAutomatic", newSViv(CompositeRedirectAutomatic));
  newCONSTSUB(stash, "CompositeRedirectManual", newSViv(CompositeRedirectManual));
  newCONSTSUB(stash, "ShapeSet", newSViv(ShapeSet));
  newCONSTSUB(stash, "ShapeUnion", newSViv(ShapeUnion));
  newCONSTSUB(stash, "ShapeIntersect", newSViv(ShapeIntersect));
  newCONSTSUB(stash, "ShapeSubtract", newSViv(ShapeSubtract));
  newCONSTSUB(stash, "ShapeInvert", newSViv(ShapeInvert));
  newCONSTSUB(stash, "ShapeBounding", newSViv(ShapeBounding));
  newCONSTSUB(stash, "ShapeClip", newSViv(ShapeClip));
  newCONSTSUB(stash, "ShapeInput", newSViv(ShapeInput));
# END GENERATED BOOT CONSTANTS
#
