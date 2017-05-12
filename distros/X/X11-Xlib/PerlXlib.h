/*
 * This header defines the "C API" for this module.  It might be safe to copy
 * this header to other dists and use these functions, but I'm not making API
 * promises yet.
 */

typedef Display* DisplayOrNull; /* Used by typemap for stricter conversion */
typedef Visual* VisualOrNull;
typedef int ScreenNumber; /* used by typemap to coerce X11::Xlib::Screen */

/* Methods to create/alter the magic Display* attached to X11::Xlib objects */

extern Display * PerlXlib_get_magic_dpy(SV *sv, Bool not_null);
extern SV * PerlXlib_set_magic_dpy(SV *sv, Display *dpy);
extern SV * PerlXlib_obj_for_display(Display *dpy, int create);

extern XID PerlXlib_sv_to_xid(SV *sv);

extern int PerlXlib_keysym_to_codepoint(KeySym keysym);
extern KeySym PerlXlib_codepoint_to_keysym(int codepoint);
extern SV * PerlXlib_keysym_to_sv(KeySym keysym, int symbolic);
extern KeySym PerlXlib_sv_to_keysym(SV *sv);

typedef void PerlXlib_struct_pack_fn(void*, HV*, Bool consume);

extern void* PerlXlib_get_struct_ptr(SV *sv, int lvalue, const char* pkg, int struct_size, PerlXlib_struct_pack_fn *packer);
extern void PerlXlib_install_error_handlers(Bool nonfatal, Bool fatal);

extern const char* PerlXlib_xevent_pkg_for_type(int type);

/* Pack and Unpack functions for structs */

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
