/*
 * This header defines the "C API" for this module.  It might be safe to copy
 * this header to other dists and use these functions, but I'm not making API
 * promises yet.
 */

typedef Display* DisplayOrNull; /* Used by typemap for stricter conversion */
typedef Visual* VisualOrNull;
typedef int ScreenNumber; /* used by typemap to coerce X11::Xlib::Screen */

/* Functions to create/alter the magic Display* attached to X11::Xlib objects */

extern Display * PerlXlib_get_magic_dpy(SV *sv, Bool not_null);
extern SV * PerlXlib_set_magic_dpy(SV *sv, Display *dpy);
extern SV * PerlXlib_obj_for_display(Display *dpy, int create);

/* un-pack an XID from a wrapped X11::Xlib::XID or subclass */
extern XID PerlXlib_sv_to_xid(SV *sv);

/* Functions to wrap/unwrap opaque X11 pointers to/from objects */
extern void * PerlXlib_sv_to_display_innerptr(SV *sv, bool not_null);
extern SV * PerlXlib_obj_for_display_innerptr(Display *dpy, void *thing, const char *thing_class, int svtype, bool create);
extern void * PerlXlib_get_magic_dpy_innerptr(SV *sv, Bool not_null);
extern SV * PerlXlib_set_magic_dpy_innerptr(SV *sv, void *innerptr);
/* but Screen* is special */
extern Screen * PerlXlib_sv_to_screen(SV *sv, bool not_null);
extern SV * PerlXlib_obj_for_screen(Screen *screen);

/* generically attach Display to any pointer-based object */
extern SV * PerlXlib_get_displayobj_of_opaque(void *thing);
extern void PerlXlib_set_displayobj_of_opaque(void *thing, SV *dpy_sv);

/* Functions to pack/unpack structs into blessed scalars */
typedef void PerlXlib_struct_pack_fn(void*, HV*, Bool consume);
extern void* PerlXlib_get_struct_ptr(SV *sv, int lvalue, const char* pkg, int struct_size, PerlXlib_struct_pack_fn *packer);
extern const char* PerlXlib_xevent_pkg_for_type(int type);
extern void PerlXlib_XEvent_pack(XEvent *s, HV *fields, Bool consume);
extern void PerlXlib_XEvent_unpack(XEvent *s, HV *fields);
extern void PerlXlib_XVisualInfo_pack(XVisualInfo *s, HV *fields, Bool consume);
extern void PerlXlib_XVisualInfo_unpack(XVisualInfo *s, HV *fields);
extern void PerlXlib_XWindowAttributes_pack(XWindowAttributes *s, HV *fields, Bool consume);
extern void PerlXlib_XWindowAttributes_unpack(XWindowAttributes *s, HV *fields);
extern void PerlXlib_XSetWindowAttributes_pack(XSetWindowAttributes *s, HV *fields, Bool consume);
extern void PerlXlib_XSetWindowAttributes_unpack(XSetWindowAttributes *s, HV *fields);
extern void PerlXlib_XWindowChanges_pack(XWindowChanges *s, HV *fields, Bool consume);
extern void PerlXlib_XWindowChanges_unpack(XWindowChanges *s, HV *fields);
extern void PerlXlib_XSizeHints_pack(XSizeHints *s, HV *fields, Bool consume);
extern void PerlXlib_XSizeHints_unpack(XSizeHints *s, HV *fields);
extern void PerlXlib_XRectangle_pack(XRectangle *s, HV *fields, Bool consume);
extern void PerlXlib_XRectangle_unpack(XRectangle *s, HV *fields);
#ifndef HAVE_XRENDER
/* Copied from X11/extensions/Xrender.h because I decided it was better to define the struct
   than to have the perl interface change depending on whether it found a header file or not.
   (imagine, installing this module when Xrender.h was not found but then installing a
    dependent module after Xrender.h was installed)
*/
typedef XID PictFormat;
typedef struct {
    short   red;
    short   redMask;
    short   green;
    short   greenMask;
    short   blue;
    short   blueMask;
    short   alpha;
    short   alphaMask;
} XRenderDirectFormat;
typedef struct {
    PictFormat          id;
    int                 type;
    int                 depth;
    XRenderDirectFormat direct;
    Colormap            colormap;
} XRenderPictFormat;
#endif
extern void PerlXlib_XRenderPictFormat_pack(XRenderPictFormat *s, HV *fields, Bool consume);
extern void PerlXlib_XRenderPictFormat_unpack(XRenderPictFormat *s, HV *fields);

/* Keysym/unicode utility functions */
extern int PerlXlib_keysym_to_codepoint(KeySym keysym);
extern KeySym PerlXlib_codepoint_to_keysym(int codepoint);
extern SV * PerlXlib_keysym_to_sv(KeySym keysym, int symbolic);
extern KeySym PerlXlib_sv_to_keysym(SV *sv);

extern void PerlXlib_install_error_handlers(Bool nonfatal, Bool fatal);
